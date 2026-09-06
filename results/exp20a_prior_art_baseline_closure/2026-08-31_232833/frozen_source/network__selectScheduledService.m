function [net,candidates]=selectScheduledService( ...
    net,slot,tk,hasFrame,backgroundActive,mac,trace)
%SELECTSCHEDULEDSERVICE Coordinated service and EXP20 prior-art projections.
%
% EXP19 modes select one collision-free sender. EXP20 modes retain the source
% mechanism's information structure: DTSA may disagree under private local
% views, age-gain and Z-MAC-like modes may contend, and DELTA projections use
% public or private freshness. No mode reads a future trace entry.

N=net.N;
candidates=false(N,1);
S=net.serviceScheduler;
if ~S.config.enabled || backgroundActive || ~isempty(net.active)
    return;
end
eligible=find(hasFrame(:));
if isempty(eligible)
    return;
end

if any(strcmp(S.config.mode,{'delta-public','delta-private'}))
    S=updateDeltaOutcome(S,net);
    if strcmp(S.config.mode,'delta-public') && ...
            S.deltaFeedbackBlockSlots>0
        S.deltaFeedbackBlockSlots=S.deltaFeedbackBlockSlots-1;
        S.publicFeedbackCount=S.publicFeedbackCount+1;
        S.publicFeedbackAirtime=S.publicFeedbackAirtime+mac.slotTime;
        net.serviceScheduler=S;
        return;
    end
end

fifoNode=fifoChoice(net,eligible);
weights=nan(size(eligible));
selected=0;
switch S.config.mode
    case 'round-robin'
        owner=S.roundRobinCursor;
        S.roundRobinCursor=mod(owner,N)+1;
        if hasFrame(owner), selected=owner; end

    case 'deficit-maxweight'
        weights=S.virtualDeficit(eligible);
        selected=weightedChoice(net,eligible,weights);

    case 'urgency-maxweight'
        weights=urgencyWeights(net,eligible,tk,S.config);
        selected=weightedChoice(net,eligible,weights);
        S.receiverTruthReadCount=S.receiverTruthReadCount+numel(eligible);

    case 'dtsa-common'
        weights=dtsaWeights(S.commonPos,S.commonVel,eligible,mac.slotTime);
        selected=dtsaChoice(net,eligible,weights,S.config.dtsaTieMargin);
        S.receiverTruthReadCount=S.receiverTruthReadCount+N;
        S.dtsaDecisionCount=S.dtsaDecisionCount+1;

    case 'dtsa-private'
        choices=zeros(N,1);
        for observer=1:N
            [P,V]=privateView(net,S,observer,hasFrame);
            localWeights=dtsaWeights(P,V,eligible,mac.slotTime);
            choices(observer)=dtsaChoice( ...
                net,eligible,localWeights,S.config.dtsaTieMargin);
        end
        candidates=hasFrame(:) & choices==(1:N)';
        S.dtsaDecisionCount=S.dtsaDecisionCount+1;
        S.dtsaDisagreementCount=S.dtsaDisagreementCount+ ...
            double(numel(unique(choices(choices>0)))>1);

    case 'age-gain-thinning'
        weights=ageGainWeights(net,eligible);
        active=weights>=S.config.ageGainThreshold-1e-12;
        S.ageGainEligibleCount=S.ageGainEligibleCount+nnz(active);
        draws=reshape(trace.accessU(slot,eligible),[],1);
        candidates(eligible)=active & draws<=mac.pAccess;

    case 'zmac-like'
        owner=mod(slot-1,N)+1;
        highContention=mean(net.localBusyEWMA)>= ...
            S.config.zmacHighContentionThreshold;
        if hasFrame(owner)
            candidates(owner)=true;
            S.zmacOwnerAttemptCount=S.zmacOwnerAttemptCount+1;
        end
        if ~highContention
            contenders=eligible(eligible~=owner);
            if ~isempty(contenders)
                draws=reshape(trace.accessU(slot,contenders),[],1);
                admitted=contenders(draws<=mac.pAccess);
                candidates(admitted)=true;
                S.zmacContentionAttemptCount=S.zmacContentionAttemptCount+ ...
                    numel(admitted);
            end
        end

    case {'delta-public','delta-private'}
        public=strcmp(S.config.mode,'delta-public');
        weights=deltaRiskWeights(net,eligible,tk,S.config,public);
        if public
            S.receiverTruthReadCount=S.receiverTruthReadCount+numel(eligible);
        end
        if S.deltaPhase==2
            active=S.deltaColliders(eligible);
            p=1/max(nnz(S.deltaColliders),1);
            draws=reshape(trace.accessU(slot,eligible),[],1);
            candidates(eligible)=active & draws<=p;
        elseif S.deltaPhase==1
            candidates(eligible)=S.deltaColliders(eligible);
            if ~any(candidates)
                S.deltaPhase=0;
            end
        else
            active=weights>=S.config.deltaRiskThreshold-1e-12;
            draws=reshape(trace.accessU(slot,eligible),[],1);
            if public
                p=min(1,1/max(nnz(active),1));
                candidates(eligible)=active & draws<=p;
            else
                probabilities=min(1,mac.pAccess*max(weights,0));
                candidates(eligible)=active & draws<=probabilities;
            end
        end

    otherwise
        error('selectScheduledService: unsupported coordinated mode.');
end

if selected>0
    candidates(selected)=true;
end
if ~any(candidates)
    net.serviceScheduler=S;
    return;
end

selected=find(candidates,1,'first');
S.decisionCount=S.decisionCount+1;
S.mechanismActivationCount=S.mechanismActivationCount+1;
if S.config.oracle && numel(eligible)>=2
    S.fifoComparableDecisionCount=S.fifoComparableDecisionCount+1;
    if selected~=fifoNode
        S.priorityDiffersFifoCount=S.priorityDiffersFifoCount+1;
    end
end
if any(strcmp(S.config.mode,{'delta-public','delta-private'}))
    S.deltaLastCandidates=candidates;
end
if S.config.logDecisions
    f=net.queues{selected}(1);
    d=struct('ordinal',S.decisionCount,'time',tk,'slot',slot, ...
        'mode',S.config.mode,'eligibleNodes',reshape(eligible,1,[]), ...
        'weights',reshape(weights,1,[]),'selectedNode',selected, ...
        'fifoNode',fifoNode,'differsFromFifo',selected~=fifoNode, ...
        'selectedFrameId',f.id,'selectedFrameGenTime',f.genTime, ...
        'futureRandomRead',false);
    net.logs.serviceDecisions(end+1,1)=d;
end
net.serviceScheduler=S;

end


function S=updateDeltaOutcome(S,net)

attempted=net.stats.dataFramesAttempted;
if attempted<=S.deltaLastAttempted
    return;
end
delivered=net.stats.dataFramesDeliveredAny;
collisions=net.stats.collisionFrames;
perNode=net.stats.perNodeDataFramesDeliveredAny;
deliveredNodes=find(perNode>S.deltaLastPerNodeDelivered);
successful=delivered>S.deltaLastDelivered;

if successful
    S.deltaColliders(deliveredNodes)=false;
    if S.deltaPhase==2
        S.deltaPhase=1;
    elseif S.deltaPhase==1
        S.deltaPhase=0;
        S.deltaCollisionSequence=0;
    end
else
    S.deltaColliders=S.deltaColliders | S.deltaLastCandidates;
    if S.deltaPhase==1
        S.deltaCollisionSequence=S.deltaCollisionSequence+1;
    end
    S.deltaPhase=2;
end
if strcmp(S.config.mode,'delta-public')
    S.deltaFeedbackBlockSlots=S.config.publicFeedbackSlots;
end
S.deltaLastAttempted=attempted;
S.deltaLastDelivered=delivered;
S.deltaLastCollisions=collisions;
S.deltaLastPerNodeDelivered=perNode;

end


function [P,V]=privateView(net,S,observer,hasFrame)

N=net.N;
P=S.initialPos;
V=S.initialVel;
known=find(net.topology(observer,:));
if ~isempty(known)
    P(known,:)=reshape(net.Pij(observer,known,:),numel(known),3);
    V(known,:)=reshape(net.Vij(observer,known,:),numel(known),3);
end
if hasFrame(observer)
    f=net.queues{observer}(1);
    P(observer,:)=f.pos;
    V(observer,:)=f.vel;
else
    P(observer,:)=S.commonPos(observer,:);
    V(observer,:)=S.commonVel(observer,:);
end

end


function weights=dtsaWeights(P,V,eligible,slotTime)

N=size(P,1);
weights=zeros(numel(eligible),1);
for q=1:numel(eligible)
    k=eligible(q);
    if norm(V(k,:))<=1e-12
        continue;
    end
    value=0;
    for j=1:N
        if j==k
            continue;
        end
        dv=V(j,:)-V(k,:);
        dp=P(k,:)-P(j,:);
        speed=norm(dv);
        distance=norm(dp);
        if speed<=1e-12 || distance<=1e-12
            continue;
        end
        cosine=max(-1,min(1,dot(dv,dp)/(speed*distance)));
        alpha=acos(cosine);
        value=value+(speed*slotTime/distance)*((pi-alpha)/pi);
    end
    weights(q)=value;
end

end


function node=dtsaChoice(net,eligible,weights,margin)

best=max(weights);
if best<=1e-15
    node=fifoChoice(net,eligible);
    return;
end
relative=(best-weights)/best;
ties=eligible(relative<=margin+1e-12);
node=fifoChoice(net,ties);

end


function weights=ageGainWeights(net,eligible)

weights=zeros(numel(eligible),1);
for q=1:numel(eligible)
    sender=eligible(q);
    f=net.queues{sender}(1);
    receivers=find(f.dataReceiverMask);
    if isempty(receivers)
        continue;
    end
    weights(q)=max(f.genTime-net.ackedGenTime(receivers,sender));
end

end


function weights=deltaRiskWeights(net,eligible,tk,C,public)

weights=zeros(numel(eligible),1);
for q=1:numel(eligible)
    sender=eligible(q);
    f=net.queues{sender}(1);
    receivers=find(f.dataReceiverMask);
    if isempty(receivers)
        continue;
    end
    if public
        ages=tk-net.acceptedGenTime(receivers,sender);
        cachedPos=reshape(net.Pij(receivers,sender,:),numel(receivers),3);
        cachedVel=reshape(net.Vij(receivers,sender,:),numel(receivers),3);
        innovation=max([max(vecnorm(cachedPos-f.pos,2,2))/C.posThreshold; ...
            max(vecnorm(cachedVel-f.vel,2,2))/C.velThreshold]);
    else
        ages=tk-net.ackedGenTime(receivers,sender);
        innovation=max(f.genTime-net.ackedGenTime(receivers,sender))/ ...
            C.aoiThreshold;
    end
    ageScore=max(ages)/C.aoiThreshold;
    queueScore=max(tk-f.enqueueTime,0)/C.aoiThreshold;
    weights(q)=max([innovation;ageScore;queueScore]);
end

end


function node=fifoChoice(net,eligible)

times=zeros(numel(eligible),1);
for k=1:numel(eligible)
    times(k)=net.queues{eligible(k)}(1).enqueueTime;
end
[~,order]=sortrows([times(:) eligible(:)],[1 2]);
node=eligible(order(1));

end


function node=weightedChoice(net,eligible,weights)

best=max(weights);
ties=eligible(abs(weights-best)<=1e-12);
node=fifoChoice(net,ties);

end


function weights=urgencyWeights(net,eligible,tk,C)

weights=zeros(numel(eligible),1);
for k=1:numel(eligible)
    sender=eligible(k);
    frame=net.queues{sender}(1);
    receivers=find(frame.dataReceiverMask);
    posInnovation=0;
    velInnovation=0;
    trueAge=0;
    if ~isempty(receivers)
        cachedPos=reshape(net.Pij(receivers,sender,:),numel(receivers),3);
        cachedVel=reshape(net.Vij(receivers,sender,:),numel(receivers),3);
        posInnovation=max(vecnorm(cachedPos-frame.pos,2,2));
        velInnovation=max(vecnorm(cachedVel-frame.vel,2,2));
        trueAge=max(tk-net.acceptedGenTime(receivers,sender));
    end
    queueAge=max(tk-frame.enqueueTime,0);
    silence=max(tk-net.serviceScheduler.lastServiceTime(sender),0);
    components=[posInnovation/C.posThreshold; ...
        velInnovation/C.velThreshold; trueAge/C.aoiThreshold; ...
        queueAge/C.aoiThreshold; silence/C.maxSilence];
    weights(k)=max(components);
end

end

