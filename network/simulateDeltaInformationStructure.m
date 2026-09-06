function out=simulateDeltaInformationStructure(cfg,arm,seedValue)
%SIMULATEDELTAINFORMATIONSTRUCTURE Clean-room DELTA information panel.
%
% This is an independent implementation from the published protocol
% description. It does not copy the authors' GPLv3 reference source. The
% public arm follows the native persistent binary-anomaly/common-gateway
% information structure. The private arm is an explicitly labelled extension
% in which ACK/NACK announcements reach each node through a separate delayed,
% lossy path.

arguments
    cfg struct
    arm (1,:) char
    seedValue (1,1) double {mustBeInteger,mustBeNonnegative}
end

C=normalizeConfig(cfg);
arm=lower(strtrim(arm));
valid={'delta-public','delta-private-delayed','zero-wait', ...
    'max-age-first','round-robin'};
if ~any(strcmp(arm,valid))
    error('simulateDeltaInformationStructure: unknown arm "%s".',arm);
end

D=absoluteDraws(C,seedValue);
N=C.N;
L=C.burnIn+C.slots;

% Persistent anomaly epochs distinguish source uncertainty from gateway truth.
sourceEpoch=zeros(N,1);
gatewayEpoch=zeros(N,1);
sourcePending=false(N,1);
pendingSince=zeros(N,1);
gatewayAoII=zeros(N,1);

% One local DELTA view per node. Columns are observers, rows are sources.
psi=zeros(N,N);
phase=zeros(N,1);          % 0: ZW/BT, 1: CE, 2: CR
collider=false(N,1);       % each node knows only its own membership
% The public reference initializes this memory to zero. If hot-start ends in
% CR, that boundary state can make the computed retry probability nearly zero;
% retaining it is required for aggregate fidelity to the upstream protocol.
collisionSteps=zeros(N,N);
collisionSequence=zeros(N,1);

% Feedback ring: each bucket contains scalar events for one observer.
ringSize=C.feedbackDelayMax+1;
feedbackRing=cell(ringSize,N);
for b=1:ringSize
    for n=1:N
        feedbackRing{b,n}=emptyFeedback();
    end
end

sumAoII=0;
sumMaxAoII=0;
measuredSlots=0;
attempts=0;
successes=0;
collisions=0;
erasures=0;
feedbackGenerated=0;
feedbackDelivered=0;
feedbackDropped=0;
phaseDivergenceSlots=0;
futureFeedbackReads=0;
maxFeedbackDepth=0;

for slot=1:L
    % Local clocks advance before the current decision, as in the source model.
    if slot>1
        psi=psi+1;
    end

    if strcmp(arm,'delta-private-delayed')
        bucket=mod(slot-1,ringSize)+1;
        for observer=1:N
            events=feedbackRing{bucket,observer};
            for q=1:numel(events)
                if events(q).dueSlot~=slot
                    error('simulateDeltaInformationStructure: feedback ring alias.');
                end
                [psi(:,observer),phase(observer),collider(observer), ...
                    collisionSequence(observer),sourcePending(observer)] = ...
                    applyFeedback(events(q),psi(:,observer),phase(observer), ...
                    collider(observer),collisionSequence(observer), ...
                    sourcePending(observer),observer,sourceEpoch(observer));
                feedbackDelivered=feedbackDelivered+1;
            end
            feedbackRing{bucket,observer}=emptyFeedback();
        end
    end

    tx=false(N,1);
    switch arm
        case 'delta-public'
            [tx,psi(:,1),collisionSteps(:,1),~] = ...
                deltaDecision(sourcePending,pendingSince,slot,psi(:,1), ...
                phase(1),collider,collisionSteps(:,1), ...
                collisionSequence(1),C,D.accessU(slot,:)');
            psi=repmat(psi(:,1),1,N);
            collisionSteps=repmat(collisionSteps(:,1),1,N);
            phase(:)=phase(1);
            collisionSequence(:)=collisionSequence(1);
        case 'delta-private-delayed'
            for observer=1:N
                localColliders=false(N,1);
                localColliders(observer)=collider(observer);
                [candidate,psi(:,observer),collisionSteps(:,observer)] = ...
                    deltaDecision(sourcePending,pendingSince,slot, ...
                    psi(:,observer),phase(observer),localColliders, ...
                    collisionSteps(:,observer),collisionSequence(observer), ...
                    C,D.accessU(slot,:)');
                tx(observer)=candidate(observer);
                % In collision-exit, an empty collider set is itself public
                % evidence that resolution ended; no ACK/NACK is generated.
                if phase(observer)==1 && ~candidate(observer)
                    phase(observer)=0;
                    collisionSequence(observer)=0;
                end
            end
            if any(phase~=phase(1))
                phaseDivergenceSlots=phaseDivergenceSlots+1;
            end

        case 'zero-wait'
            tx=sourcePending & (D.accessU(slot,:)'<C.zeroWaitProbability);

        case 'max-age-first'
            [~,owner]=max(psi(:,1));
            tx(owner)=true;

        case 'round-robin'
            owner=mod(slot-1,N)+1;
            tx(owner)=true;
    end

    txNodes=find(tx);
    nTx=numel(txNodes);
    if strcmp(arm,'delta-public') && phase(1)==1 && nTx==0
        phase(:)=0;
        collisionSequence(:)=0;
    end
    attempts=attempts+nTx;
    outcome=0; % 0 silence, 1 ACK, 2 NACK
    successNode=0;
    if nTx==1
        if D.channelU(slot)>C.epsilon
            outcome=1;
            successNode=txNodes(1);
            successes=successes+1;
            gatewayEpoch(successNode)=sourceEpoch(successNode);
            gatewayAoII(successNode)=0;
        else
            outcome=2;
            erasures=erasures+1;
        end
    elseif nTx>1
        outcome=2;
        collisions=collisions+1;
    end

    if strcmp(arm,'delta-public')
        event=makeFeedback(slot,outcome,txNodes,successNode,slot);
        for observer=1:N
            [psi(:,observer),phase(observer),collider(observer), ...
                collisionSequence(observer),sourcePending(observer)] = ...
                applyFeedback(event,psi(:,observer),phase(observer), ...
                collider(observer),collisionSequence(observer), ...
                sourcePending(observer),observer,sourceEpoch(observer));
        end
        feedbackGenerated=feedbackGenerated+double(nTx>0);
        feedbackDelivered=feedbackDelivered+N*double(nTx>0);

    elseif strcmp(arm,'delta-private-delayed') && nTx>0
        for observer=1:N
            feedbackGenerated=feedbackGenerated+1;
            if D.feedbackLossU(slot,observer)<C.feedbackLoss
                feedbackDropped=feedbackDropped+1;
                continue;
            end
            delay=C.feedbackDelayMin+floor(D.feedbackDelayU(slot,observer)* ...
                (C.feedbackDelayMax-C.feedbackDelayMin+1));
            delay=min(delay,C.feedbackDelayMax);
            due=slot+delay;
            if due<=L
                event=makeFeedback(slot,outcome,txNodes,successNode,due);
                b=mod(due-1,ringSize)+1;
                feedbackRing{b,observer}(end+1,1)=event;
                maxFeedbackDepth=max(maxFeedbackDepth, ...
                    numel(feedbackRing{b,observer}));
            end
        end
    elseif successNode>0
        % Scheduled/random-access comparators use immediate reliable outcome
        % knowledge, matching their common-gateway reference interpretation.
        sourcePending(successNode)=false;
        psi(successNode,:)=0;
    end

    % True gateway AoII grows while a source epoch is not yet known.
    unknown=gatewayEpoch<sourceEpoch;
    gatewayAoII(unknown)=gatewayAoII(unknown)+1;
    gatewayAoII(~unknown)=0;

    % New anomaly epochs occur at the end of the slot and persist until the
    % source learns that its current epoch was accepted.
    newAnomaly=(D.anomalyU(slot,:)'<C.lambda) & ~sourcePending;
    sourceEpoch(newAnomaly)=sourceEpoch(newAnomaly)+1;
    sourcePending(newAnomaly)=true;
    pendingSince(newAnomaly)=slot+1;

    if slot>C.burnIn
        sumAoII=sumAoII+sum(gatewayAoII);
        sumMaxAoII=sumMaxAoII+max(gatewayAoII);
        measuredSlots=measuredSlots+1;
    end
end

out=struct();
out.arm=arm;
out.seed=seedValue;
out.N=N;
out.rho=C.rho;
out.lambda=C.lambda;
out.epsilon=C.epsilon;
out.slots=C.slots;
out.burnIn=C.burnIn;
out.MEAN_AOII=sumAoII/max(measuredSlots*N,1);
out.MEAN_MAX_AOII=sumMaxAoII/max(measuredSlots,1);
out.ATTEMPTS=attempts;
out.ATTEMPT_RATE=attempts/max(L,1);
out.SUCCESSES=successes;
out.SUCCESS_RATE=successes/max(L,1);
out.COLLISIONS=collisions;
out.COLLISION_SLOT_RATE=collisions/max(L,1);
out.ERASURES=erasures;
out.FEEDBACK_GENERATED=feedbackGenerated;
out.FEEDBACK_DELIVERED=feedbackDelivered;
out.FEEDBACK_DROPPED=feedbackDropped;
out.FEEDBACK_EVENT_RATE=feedbackGenerated/max(L,1);
out.PHASE_DIVERGENCE_FRACTION=phaseDivergenceSlots/max(L,1);
out.MAX_FEEDBACK_QUEUE=maxFeedbackDepth;
out.FUTURE_FEEDBACK_READS=futureFeedbackReads;
out.DRAW_HASH_EXACT=D.hashExact;

end


function C=normalizeConfig(cfg)

required={'N','rho','epsilon','slots','burnIn','feedbackLoss', ...
    'feedbackDelaySlots'};
if ~all(isfield(cfg,required))
    error('simulateDeltaInformationStructure: incomplete cfg.');
end
C=cfg;
C.lambda=C.rho/C.N;
C.feedbackDelayMin=C.feedbackDelaySlots(1);
C.feedbackDelayMax=C.feedbackDelaySlots(2);
C.K=2.5*C.N;
C.hotStart=100;
C.zeroWaitProbability=0.17;
if C.N<2 || C.slots<1 || C.burnIn<0 || C.rho<=0 || C.rho>=1 || ...
        C.epsilon<0 || C.epsilon>=1 || C.feedbackLoss<0 || ...
        C.feedbackLoss>=1 || C.feedbackDelayMin<1 || ...
        C.feedbackDelayMax<C.feedbackDelayMin
    error('simulateDeltaInformationStructure: invalid cfg value.');
end

end


function D=absoluteDraws(C,seedValue)

L=C.burnIn+C.slots;
s=RandStream('mt19937ar','Seed',seedValue);
D.anomalyU=rand(s,L,C.N);
D.accessU=rand(s,L,C.N);
D.channelU=rand(s,L,1);
D.feedbackLossU=rand(s,L,C.N);
D.feedbackDelayU=rand(s,L,C.N);
D.hashExact=realizationHash([D.anomalyU(:);D.accessU(:); ...
    D.channelU(:);D.feedbackLossU(:);D.feedbackDelayU(:)]);

end


function [tx,psi,collisionSteps,pCR]=deltaDecision( ...
    sourcePending,pendingSince,slot,psi,phase,collider,collisionSteps, ...
    collisionSequence,C,accessU)

N=C.N;
tx=false(N,1);
pCR=NaN;
if slot<C.hotStart
    tentative=accessU<1/N;
    if nnz(tentative)==1
        tx=tentative;
    end
    return;
end

if phase==0
    if max(psi)<=1
        collisionSteps(:)=1;
        tx=sourcePending;
        return;
    end

    localAge=max(slot-pendingSince+1,0);
    beliefHighest=zeros(N,1);
    threshold=exp(C.K*log(1-C.lambda));
    for n=1:N
        if ~sourcePending(n)
            continue;
        end
        beliefHighest(n)=1;
        for j=1:N
            if j~=n && psi(j)>=localAge(n)
                beliefHighest(n)=beliefHighest(n)* ...
                    (1-C.lambda)^(psi(j)-localAge(n)+1);
            end
        end
    end
    tx=beliefHighest>threshold;
    if sum(psi)<=C.K
        collisionSteps(:)=max(1,floor(C.K/N));
        psi(:)=0;
    else
        [newAge,collisionSteps]=truncateBelief(psi,C.K);
        psi=min(psi,max(newAge)+1);
    end
elseif phase==1
    tx=collider;
else
    activeProbability=1-(1-C.lambda)^max(collisionSteps);
    pCR=crProbability(activeProbability,C.epsilon, ...
        max(1,N-collisionSequence));
    tx=collider & (accessU<pCR);
end

end


function [newAge,steps]=truncateBelief(psi,K)

maxAge=max(psi);
newAge=psi;
while sum(psi)-sum(newAge)<K && maxAge>0
    maxAge=maxAge-1;
    newAge=min(psi,maxAge);
end
steps=max(psi-newAge,1);

end


function p=crProbability(lambda,epsilon,N)

if N<=1
    p=1;
    return;
end
low=1e-4;
high=1-1e-4;
while high-low>1e-4
    p=(low+high)/2;
    value=N*lambda*(1-lambda)^(N-1)*epsilon/(p^2);
    for c=2:N
        probability=nchoosek(N,c)*lambda^c*(1-lambda)^(N-c);
        value=value+probability*(1-c*p)/(c*p^2*(1-p)^c);
    end
    if value>0
        low=p;
    else
        high=p;
    end
end
p=(low+high)/2;

end


function e=makeFeedback(origin,outcome,txNodes,successNode,due)

e=struct('originSlot',origin,'dueSlot',due,'outcome',outcome, ...
    'txNodes',reshape(txNodes,1,[]),'successNode',successNode);

end


function [psi,phase,ownCollider,collisionSequence,ownPending]= ...
    applyFeedback(e,psi,phase,ownCollider,collisionSequence, ...
    ownPending,observer,ownEpoch)

if e.outcome==0
    return;
end
if e.outcome==1
    if e.successNode>0
        psi(e.successNode)=0;
    end
    if e.successNode==observer && ownEpoch>0
        ownPending=false;
        ownCollider=false;
    end
    if phase==1
        phase=0;
        collisionSequence=0;
    elseif phase==2
        phase=1;
        collisionSequence=0;
    end
else
    if any(e.txNodes==observer)
        ownCollider=true;
    end
    if phase==1
        collisionSequence=collisionSequence+1;
    end
    phase=2;
end

end


function e=emptyFeedback()

e=struct('originSlot',{},'dueSlot',{},'outcome',{}, ...
    'txNodes',{},'successNode',{});

end
