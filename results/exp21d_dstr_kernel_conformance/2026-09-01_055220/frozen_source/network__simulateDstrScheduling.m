function out=simulateDstrScheduling(cfg,trace)
%SIMULATEDSTRSCHEDULING Rule-mapped D-STR scheduling kernel.
%
% This is an isolated protocol kernel.  It models synchronized logical
% superframes, five contending management slots, periodic beacon slots,
% locally observed three-state reception records, and source-mapped D-STR
% transitions.  It contains no controller or receiver-truth policy input.

C=validateConfig(cfg);
T=validateTrace(trace,C);
N=C.N;
F=C.maxFrames;
M=C.maxDataSlots;

STATE_START=uint8(0);
STATE_ASSIGNMENT=uint8(1);
STATE_RESOLVED=uint8(2);

state=repmat(STATE_START,N,1);
assigned=zeros(N,1);
state(1)=STATE_RESOLVED;
assigned(1)=1;
localDataSlots=repmat(C.initialDataSlots,N,1);
failedAllocation=zeros(N,1);
failedResolved=zeros(N,1);
needGrow=false(N,1);
growIncrement=ones(N,1);
shrinkCandidate=zeros(N,1);
shrinkBackoff=zeros(N,1);
shrinkFailures=zeros(N,1);
silentCount=zeros(N,M);
failedShrinkAge=zeros(N,M);

% Payload records are the completed local observations from the preceding
% superframe.  A delivered beacon updates only the receiver's local inbox.
payloadRecord=zeros(N,M,'uint8');
latestRecord=zeros(N,N,M,'uint8'); % receiver, reporter, transmission slot
discovered=false(N,N);
latestFrameLength=repmat(C.initialDataSlots,N,N);
pendingSlot=zeros(N,1);
pendingFrame=zeros(N,1);

active=true(N,1);
churnApplied=false;
churnFrameObserved=nan;
firstResolutionFrame=nan;
firstConvergenceFrame=nan;
recoveryFrame=nan;

totalDataAttempts=0;
totalDataRecipientAttempts=0;
totalDataRecipientSuccess=0;
totalDataRecipientErasure=0;
totalDataRecipientCollision=0;
totalManagementAttempts=0;
totalManagementRecipientAttempts=0;
totalManagementRecipientSuccess=0;
totalManagementRecipientErasure=0;
totalManagementRecipientCollision=0;
dataCollisionFrames=0;
managementCollisionSlots=0;
busyDataSlots=0;
busyManagementSlots=0;
growRequests=0;
growNacks=0;
growthEvents=0;
shrinkRequests=0;
shrinkObjects=0;
shrinkNacks=0;
shrinkEvents=0;
falseResolvedNodeFrames=0;
conflictFrames=0;
maxFrameDisagreement=0;
maxAssignedSlot=1;
deliveryWitnessValid=true;

frameLog=repmat(emptyFrameRow(),F,1);

for frame=1:F
    cached=failedShrinkAge>0;
    failedShrinkAge(cached)=failedShrinkAge(cached)+1;
    failedShrinkAge(failedShrinkAge>C.failedShrinkTimeout)=0;
    if C.churnEnabled && ~churnApplied && frame==C.churnFrame
        node=C.churnNode;
        state(node)=STATE_START;
        assigned(node)=0;
        failedAllocation(node)=0;
        failedResolved(node)=0;
        needGrow(node)=false;
        shrinkCandidate(node)=0;
        shrinkBackoff(node)=0;
        shrinkFailures(node)=0;
        failedShrinkAge(node,:)=0;
        pendingSlot(node)=0;
        pendingFrame(node)=0;
        discovered(node,:)=false;
        latestRecord(node,:,:)=0;
        payloadRecord(node,:)=0;
        churnApplied=true;
        churnFrameObserved=frame;
    end

    inboxFresh=false(N,N);
    heardAny=false(N,1);
    dataObs=zeros(N,M,'uint8');

    % ---------------------------------------------------------------
    % TG: grow request, followed by TGn energy-NACK consensus.
    % ---------------------------------------------------------------
    txTG=find(active & state==STATE_ASSIGNMENT & needGrow);
    tgPayload=zeros(N,1);
    tgPayload(txTG)=growIncrement(txTG);
    [obsTG,decodedTG,aTG]=managementSlot(txTG,1,frame,C,T);
    deliveryWitnessValid=deliveryWitnessValid && aTG.witnessValid;
    [totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots]=accumulateManagement(aTG, ...
        totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots);
    growRequests=growRequests+numel(txTG);

    txTGn=find(active & obsTG==2);
    [obsTGn,~,aTGn]=managementSlot(txTGn,2,frame,C,T);
    deliveryWitnessValid=deliveryWitnessValid && aTGn.witnessValid;
    [totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots]=accumulateManagement(aTGn, ...
        totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots);
    growNacks=growNacks+numel(txTGn);

    oldLengths=localDataSlots;
    for node=1:N
        if ~active(node), continue; end
        applyMargin=0;
        if any(txTGn==node) || obsTGn(node)>0 || obsTG(node)==2
            applyMargin=C.growthMargin;
        elseif any(txTG==node)
            applyMargin=tgPayload(node);
        elseif decodedTG(node)>0
            applyMargin=tgPayload(decodedTG(node));
        end
        if applyMargin>0
            localDataSlots(node)=min(M,localDataSlots(node)+applyMargin);
            needGrow(node)=false;
            failedAllocation(node)=0;
            silentCount(node,:)=0;
            shrinkCandidate(node)=0;
            shrinkBackoff(node)=0;
        end
    end
    if any(localDataSlots~=oldLengths), growthEvents=growthEvents+1; end

    % ---------------------------------------------------------------
    % TS/TSo/TSn: conservative shrink negotiation.  Growth preempts it.
    % ---------------------------------------------------------------
    txTS=zeros(0,1);
    tsPayload=zeros(N,1);
    if C.enableShrink
        % A node suppresses shrink only when its own local frame grew.  A
        % remote TG/TGn exchange outside its reach is not global knowledge.
        eligible=find(active & state==STATE_RESOLVED & ...
            shrinkCandidate>0 & localDataSlots==oldLengths);
        for node=reshape(eligible,1,[])
            if shrinkBackoff(node)>0
                shrinkBackoff(node)=shrinkBackoff(node)-1;
            else
                txTS(end+1,1)=node; %#ok<AGROW>
                tsPayload(node)=shrinkCandidate(node);
            end
        end
    end
    [obsTS,decodedTS,aTS]=managementSlot(txTS,3,frame,C,T);
    deliveryWitnessValid=deliveryWitnessValid && aTS.witnessValid;
    [totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots]=accumulateManagement(aTS, ...
        totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots);
    shrinkRequests=shrinkRequests+numel(txTS);

    txTSo=false(N,1);
    for node=1:N
        if active(node) && state(node)==STATE_ASSIGNMENT
            % Assignment nodes object irrespective of whether TS decoded.
            txTSo(node)=true;
            continue;
        end
        proposer=decodedTS(node);
        if proposer<=0, continue; end
        proposed=tsPayload(proposer);
        if assigned(node)==proposed
            txTSo(node)=true;
        end
    end
    [obsTSo,~,aTSo]=managementSlot(find(txTSo),4,frame,C,T);
    deliveryWitnessValid=deliveryWitnessValid && aTSo.witnessValid;
    [totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots]=accumulateManagement(aTSo, ...
        totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots);
    shrinkObjects=shrinkObjects+nnz(txTSo);

    txTSn=find(active & obsTS==2);
    [obsTSn,~,aTSn]=managementSlot(txTSn,5,frame,C,T);
    deliveryWitnessValid=deliveryWitnessValid && aTSn.witnessValid;
    [totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots]=accumulateManagement(aTSn, ...
        totalManagementAttempts,totalManagementRecipientAttempts, ...
        totalManagementRecipientSuccess,totalManagementRecipientErasure, ...
        totalManagementRecipientCollision,busyManagementSlots, ...
        managementCollisionSlots);
    shrinkNacks=shrinkNacks+numel(txTSn);

    applyShrink=false(N,1);
    if isscalar(txTS)
        proposer=txTS(1);
        proposed=tsPayload(proposer);
        for node=1:N
            knowsProposal=(node==proposer) || decodedTS(node)==proposer;
            objectKnown=txTSo(node) || obsTSo(node)>0;
            nackKnown=any(txTSn==node) || obsTSn(node)>0 || obsTS(node)==2;
            applyShrink(node)=active(node) && knowsProposal && ...
                ~objectKnown && ~nackKnown && proposed>0 && ...
                proposed<=localDataSlots(node);
        end
        if any(applyShrink)
            for node=find(applyShrink)'
                localDataSlots(node)=localDataSlots(node)-1;
                if assigned(node)>proposed
                    assigned(node)=assigned(node)-1;
                end
                if pendingSlot(node)>proposed
                    pendingSlot(node)=pendingSlot(node)-1;
                end
                payloadRecord(node,proposed:M-1)= ...
                    payloadRecord(node,proposed+1:M);
                payloadRecord(node,M)=0;
                latestRecord(node,:,proposed:M-1)= ...
                    latestRecord(node,:,proposed+1:M);
                latestRecord(node,:,M)=0;
                silentCount(node,proposed:M-1)= ...
                    silentCount(node,proposed+1:M);
                silentCount(node,M)=0;
                failedShrinkAge(node,proposed:M-1)= ...
                    failedShrinkAge(node,proposed+1:M);
                failedShrinkAge(node,M)=0;
            end
            shrinkEvents=shrinkEvents+1;
            shrinkCandidate(applyShrink)=0;
            shrinkBackoff(applyShrink)=0;
            shrinkFailures(applyShrink)=0;
        end
    end

    % Each TS proposer reacts only to energy it observes in TSo/TSn.  An
    % objection resets ST and populates the source-defined failed_shrink
    % cache; a NACK-only outcome uses truncated exponential backoff.
    for proposer=reshape(txTS,1,[])
        proposed=tsPayload(proposer);
        objectObserved=obsTSo(proposer)>0;
        successApplied=isscalar(txTS) && applyShrink(proposer);
        if objectObserved
            if proposed>0 && proposed<=M
                failedShrinkAge(proposer,proposed)=1;
                silentCount(proposer,proposed)=0;
            end
            shrinkCandidate(proposer)=0;
            shrinkBackoff(proposer)=0;
            shrinkFailures(proposer)=0;
        elseif ~successApplied
            shrinkFailures(proposer)=shrinkFailures(proposer)+1;
            width=max(1,2^min(shrinkFailures(proposer),6)-1);
            shrinkBackoff(proposer)=floor(T.choiceU(frame,proposer)*width);
        end
    end

    % ---------------------------------------------------------------
    % Periodic data/safety beacon slots.  Frames carry the prior local
    % reception record and current local superframe size.
    % ---------------------------------------------------------------
    txSlotThis=zeros(N,1);
    for node=find(active & state~=STATE_START & assigned>0)'
        if assigned(node)<=localDataSlots(node)
            txSlotThis(node)=assigned(node);
        end
    end
    maxSlotsThis=max(localDataSlots(active));
    maxAssignedSlot=max(maxAssignedSlot,max([0;txSlotThis]));
    for dataSlot=1:maxSlotsThis
        tx=find(txSlotThis==dataSlot);
        if isempty(tx), continue; end
        busyDataSlots=busyDataSlots+1;
        totalDataAttempts=totalDataAttempts+numel(tx);
        [obs,decoded,aData]=dataSlotDelivery(tx,frame,C,T);
        deliveryWitnessValid=deliveryWitnessValid && aData.witnessValid;
        dataObs(:,dataSlot)=obs;
        totalDataRecipientAttempts=totalDataRecipientAttempts+ ...
            aData.recipientAttempts;
        totalDataRecipientSuccess=totalDataRecipientSuccess+ ...
            aData.recipientSuccess;
        totalDataRecipientErasure=totalDataRecipientErasure+ ...
            aData.recipientErasure;
        totalDataRecipientCollision=totalDataRecipientCollision+ ...
            aData.recipientCollision;
        if aData.collision
            dataCollisionFrames=dataCollisionFrames+numel(tx);
        end
        for receiver=1:N
            sender=decoded(receiver);
            if sender<=0, continue; end
            latestRecord(receiver,sender,:)=reshape( ...
                payloadRecord(sender,:),1,1,M);
            latestFrameLength(receiver,sender)=localDataSlots(sender);
            inboxFresh(receiver,sender)=true;
            discovered(receiver,sender)=true;
            heardAny(receiver)=true;
        end
    end

    % Start nodes adopt metadata only from locally decoded beacons.
    for node=find(active & state==STATE_START & heardAny)'
        reporters=find(inboxFresh(node,:));
        if ~isempty(reporters)
            localDataSlots(node)=max(latestFrameLength(node,reporters));
            state(node)=STATE_ASSIGNMENT;
        end
    end

    % Evaluate the previous transmission using only newly delivered records
    % from already discovered reporters.  Missing known reports cause a wait,
    % not a fabricated positive or negative acknowledgment.
    for node=find(active & state~=STATE_START & pendingSlot>0)'
        slot=pendingSlot(node);
        known=find(discovered(node,:));
        known(known==node)=[];
        freshKnown=known(inboxFresh(node,known));
        negative=false;
        positive=false;
        if ~isempty(freshKnown)
            values=zeros(numel(freshKnown),1);
            for q=1:numel(freshKnown)
                values(q)=latestRecord(node,freshKnown(q),slot);
            end
            negative=any(values~=1);
            positive=numel(freshKnown)==numel(known) && all(values==1);
        end
        if state(node)==STATE_ASSIGNMENT
            if positive
                state(node)=STATE_RESOLVED;
                failedAllocation(node)=0;
            elseif negative
                assigned(node)=0;
                failedAllocation(node)=failedAllocation(node)+1;
                if failedAllocation(node)>=C.collisionThreshold
                    needGrow(node)=true;
                    growIncrement(node)=C.growthMargin;
                end
            end
        elseif state(node)==STATE_RESOLVED && negative
            failedResolved(node)=failedResolved(node)+1;
            if T.retentionU(frame,node)>C.retentionProbability
                state(node)=STATE_ASSIGNMENT;
                assigned(node)=0;
                failedResolved(node)=0;
            end
        elseif state(node)==STATE_RESOLVED && positive
            failedResolved(node)=0;
        end
    end

    % Current transmission becomes the pending attempt if its slot claim is
    % still active after evaluating older evidence.
    pendingSlot(:)=0;
    pendingFrame(:)=0;
    for node=find(active & assigned>0 & txSlotThis>0)'
        if assigned(node)==txSlotThis(node)
            pendingSlot(node)=txSlotThis(node);
            pendingFrame(node)=frame;
        end
    end

    % Assignment nodes without a slot make one causal random local choice.
    for node=find(active & state==STATE_ASSIGNMENT & assigned==0)'
        unavailable=false(1,localDataSlots(node));
        ownRecord=double(payloadRecord(node,1:localDataSlots(node)));
        unavailable=unavailable | ownRecord==1;
        reporters=find(discovered(node,:));
        for reporter=reshape(reporters,1,[])
            rec=reshape(latestRecord(node,reporter,1:localDataSlots(node)),1,[]);
            unavailable=unavailable | rec==1;
        end
        available=find(~unavailable);
        if isempty(available)
            needGrow(node)=true;
            growIncrement(node)=1;
        elseif failedAllocation(node)>=C.collisionThreshold
            needGrow(node)=true;
            growIncrement(node)=C.growthMargin;
        else
            u=T.choiceU(frame,node);
            index=min(numel(available),floor(u*numel(available))+1);
            assigned(node)=available(index);
        end
    end

    % Local silence tracking and source-defined shrink ordering.
    for node=1:N
        if ~active(node), continue; end
        if state(node)~=STATE_RESOLVED
            silentCount(node,:)=0;
            shrinkCandidate(node)=0;
            shrinkBackoff(node)=0;
            continue;
        end
        for dataSlot=1:localDataSlots(node)
            usedBySelf=assigned(node)==dataSlot;
            if dataObs(node,dataSlot)==0 && ~usedBySelf
                silentCount(node,dataSlot)=silentCount(node,dataSlot)+1;
            else
                silentCount(node,dataSlot)=0;
            end
        end
        silentCount(node,localDataSlots(node)+1:end)=0;
    end
    if C.enableShrink
        newEligible=find(active & state==STATE_RESOLVED & ...
            shrinkCandidate==0);
        for node=reshape(newEligible,1,[])
            candidates=find(silentCount(node,1:localDataSlots(node))>= ...
                C.shrinkThreshold & ...
                failedShrinkAge(node,1:localDataSlots(node))==0);
            if isempty(candidates), continue; end
            shrinkCandidate(node)=candidates(end);
            % The node's own local slot index supplies the ordered backoff;
            % global occupancy is physical truth and cannot be read here.
            shrinkBackoff(node)=max(assigned(node)-1,0);
        end
    end

    payloadRecord=dataObs;

    [collisionFree,falseResolved]=physicalScheduleState( ...
        active,state,assigned,localDataSlots,C);
    fullResolved=all(state(active)==STATE_RESOLVED & assigned(active)>0);
    agree=max(localDataSlots(active))==min(localDataSlots(active));
    used=unique(assigned(active & assigned>0));
    noUnused=agree && isequal(reshape(used,1,[]), ...
        1:max(localDataSlots(active)));
    converged=fullResolved && collisionFree && noUnused;
    if fullResolved && collisionFree && isnan(firstResolutionFrame)
        firstResolutionFrame=frame;
    end
    if converged && isnan(firstConvergenceFrame)
        firstConvergenceFrame=frame;
    end
    if churnApplied && fullResolved && collisionFree && isnan(recoveryFrame)
        recoveryFrame=frame-churnFrameObserved;
    end
    conflictFrames=conflictFrames+double(~collisionFree);
    falseResolvedNodeFrames=falseResolvedNodeFrames+falseResolved;
    maxFrameDisagreement=max(maxFrameDisagreement, ...
        max(localDataSlots(active))-min(localDataSlots(active)));

    frameLog(frame)=makeFrameRow(frame,state,assigned,localDataSlots, ...
        collisionFree,fullResolved,converged,falseResolved, ...
        numel(txTG),numel(txTGn),numel(txTS),nnz(txTSo),numel(txTSn), ...
        numel(find(txSlotThis>0)));
end

frameAirtime=8*C.frameBytes/C.phyRateBps;
totalAttemptFrames=totalDataAttempts+totalManagementAttempts;
totalBusySlots=busyDataSlots+busyManagementSlots;
totalLogicalSlots=sum(5+[frameLog.maxLocalDataSlots]);
elapsedSec=totalLogicalSlots*(frameAirtime+C.guardSec);

out=struct();
out.version='DSTR-KERNEL-v1';
out.N=N;
out.maxFrames=F;
out.state=state;
out.assignedSlot=assigned;
out.localDataSlots=localDataSlots;
out.firstResolutionFrame=firstResolutionFrame;
out.firstConvergenceFrame=firstConvergenceFrame;
out.firstConvergenceFrame=firstConvergenceFrame;
out.churnApplied=churnApplied;
out.recoveryFrame=recoveryFrame;
out.finalAllResolved=all(state(active)==STATE_RESOLVED);
out.finalCollisionFree=physicalScheduleState( ...
    active,state,assigned,localDataSlots,C);
out.finalFrameAgreement=max(localDataSlots)==min(localDataSlots);
out.finalDataSlots=max(localDataSlots);
out.maxFrameDisagreement=maxFrameDisagreement;
out.maxAssignedSlot=maxAssignedSlot;
out.conflictFrameFraction=conflictFrames/F;
out.falseResolvedNodeFrames=falseResolvedNodeFrames;
out.dataAttempts=totalDataAttempts;
out.dataRecipientAttempts=totalDataRecipientAttempts;
out.dataRecipientSuccess=totalDataRecipientSuccess;
out.dataRecipientErasure=totalDataRecipientErasure;
out.dataRecipientCollision=totalDataRecipientCollision;
out.dataCollisionFrames=dataCollisionFrames;
out.managementAttempts=totalManagementAttempts;
out.managementRecipientAttempts=totalManagementRecipientAttempts;
out.managementRecipientSuccess=totalManagementRecipientSuccess;
out.managementRecipientErasure=totalManagementRecipientErasure;
out.managementRecipientCollision=totalManagementRecipientCollision;
out.managementCollisionSlots=managementCollisionSlots;
out.growRequests=growRequests;
out.growNacks=growNacks;
out.growthEvents=growthEvents;
out.shrinkRequests=shrinkRequests;
out.shrinkObjects=shrinkObjects;
out.shrinkNacks=shrinkNacks;
out.shrinkEvents=shrinkEvents;
out.frameAirtimeSec=frameAirtime;
out.guardSec=C.guardSec;
out.elapsedSec=elapsedSec;
out.offeredAirtimeSec=totalAttemptFrames*frameAirtime;
out.busyAirtimeSec=totalBusySlots*frameAirtime;
out.offeredUtilization=out.offeredAirtimeSec/elapsedSec;
out.channelUtilization=out.busyAirtimeSec/elapsedSec;
out.accountingCloses= ...
    totalDataRecipientAttempts==totalDataRecipientSuccess+ ...
    totalDataRecipientErasure+totalDataRecipientCollision && ...
    totalManagementRecipientAttempts==totalManagementRecipientSuccess+ ...
    totalManagementRecipientErasure+totalManagementRecipientCollision;
out.deliveryWitnessValid=deliveryWitnessValid;
out.futureRandomReads=0;
out.receiverTruthDecisionReads=0;
out.frameLog=frameLog;
out.configHash=realizationHash(configVector(C));
out.traceHash=realizationHash([T.choiceU(:);T.retentionU(:); ...
    T.dataDeliveryU(:);T.managementDeliveryU(:)]);
out.realizationHash=realizationHash([double(state);assigned;localDataSlots; ...
    frameTableVector(frameLog);totalDataAttempts;totalManagementAttempts]);

end


function [obs,decoded,a]=managementSlot(tx,slotIndex,frame,C,T)

[obs,decoded,a]=slotDelivery(tx,C.managementReach,C.interferenceMatrix, ...
    squeeze(T.managementDeliveryU(frame,slotIndex,:,:)), ...
    C.managementErasureProbability);
a.txCount=numel(tx);

end


function [obs,decoded,a]=dataSlotDelivery(tx,frame,C,T)

[obs,decoded,a]=slotDelivery(tx,C.neighborGraph,C.interferenceMatrix, ...
    squeeze(T.dataDeliveryU(frame,:,:)),C.dataErasureProbability);

end


function [obs,decoded,a]=slotDelivery(tx,reach,interference,draws,pLoss)

N=size(reach,1);
obs=zeros(N,1,'uint8');
decoded=zeros(N,1);
a=struct('recipientAttempts',0,'recipientSuccess',0, ...
    'recipientErasure',0,'recipientCollision',0,'collision',false, ...
    'busy',~isempty(tx),'witnessValid',true);
if isempty(tx), return; end
tx=tx(:)';
txMask=false(N,1); txMask(tx)=true;
for sender=tx
    a.recipientAttempts=a.recipientAttempts+nnz(reach(:,sender) & ~txMask);
end
for receiver=1:N
    if txMask(receiver), continue; end
    intended=tx(reach(receiver,tx));
    detectable=tx(interference(receiver,tx) | reach(receiver,tx));
    if isempty(detectable), continue; end
    if isscalar(intended)
        sender=intended(1);
        other=detectable(detectable~=sender);
        if isempty(other)
            if draws(receiver,sender)>pLoss
                obs(receiver)=uint8(1);
                decoded(receiver)=sender;
                a.recipientSuccess=a.recipientSuccess+1;
                a.witnessValid=a.witnessValid && ...
                    isscalar(intended) && isscalar(detectable);
            else
                obs(receiver)=uint8(2);
                a.recipientErasure=a.recipientErasure+1;
            end
            continue;
        end
    end
    obs(receiver)=uint8(2);
    if ~isempty(intended)
        a.recipientCollision=a.recipientCollision+numel(intended);
        a.collision=true;
        a.witnessValid=a.witnessValid && numel(detectable)>=2;
    end
end

end


function varargout=accumulateManagement(a,varargin)

if numel(varargin)~=7 || ~isfield(a,'txCount')
    error('simulateDstrScheduling: invalid management accumulator call.');
end
v=cell2mat(varargin);
v(1)=v(1)+a.txCount;
v(2)=v(2)+a.recipientAttempts;
v(3)=v(3)+a.recipientSuccess;
v(4)=v(4)+a.recipientErasure;
v(5)=v(5)+a.recipientCollision;
v(6)=v(6)+double(a.busy);
v(7)=v(7)+double(a.collision);
varargout=num2cell(v);

end


function [collisionFree,falseResolved]=physicalScheduleState( ...
    active,state,assigned,localDataSlots,C)

STATE_RESOLVED=uint8(2);
collisionFree=true;
falseResolved=0;
for sender=find(active & assigned>0)'
    senderOk=true;
    receivers=find(C.neighborGraph(:,sender));
    for receiver=reshape(receivers,1,[])
        interferers=find(active & assigned==assigned(sender) & ...
            (C.interferenceMatrix(receiver,:)' | C.neighborGraph(receiver,:)'));
        interferers(interferers==sender)=[];
        if ~isempty(interferers) || assigned(sender)>localDataSlots(sender)
            senderOk=false;
            collisionFree=false;
            break;
        end
    end
    if state(sender)==STATE_RESOLVED && ~senderOk
        falseResolved=falseResolved+1;
    end
end

end


function row=emptyFrameRow()

row=struct('frame',0,'resolvedNodes',0,'assignedNodes',0, ...
    'minLocalDataSlots',0,'maxLocalDataSlots',0,'collisionFree',false, ...
    'fullResolved',false,'converged',false,'falseResolvedNodes',0, ...
    'tgAttempts',0,'tgnAttempts',0,'tsAttempts',0,'tsoAttempts',0, ...
    'tsnAttempts',0,'dataAttempts',0,'stateHash',0,'assignmentHash',0);

end


function row=makeFrameRow(frame,state,assigned,lengths,collisionFree, ...
    fullResolved,converged,falseResolved,tg,tgn,ts,tso,tsn,data)

row=emptyFrameRow();
row.frame=frame;
row.resolvedNodes=nnz(state==2);
row.assignedNodes=nnz(assigned>0);
row.minLocalDataSlots=min(lengths);
row.maxLocalDataSlots=max(lengths);
row.collisionFree=collisionFree;
row.fullResolved=fullResolved;
row.converged=converged;
row.falseResolvedNodes=falseResolved;
row.tgAttempts=tg;
row.tgnAttempts=tgn;
row.tsAttempts=ts;
row.tsoAttempts=tso;
row.tsnAttempts=tsn;
row.dataAttempts=data;
row.stateHash=realizationHash(double(state));
row.assignmentHash=realizationHash([assigned;lengths]);

end


function v=frameTableVector(rows)

v=zeros(numel(rows),8);
for k=1:numel(rows)
    v(k,:)=[rows(k).resolvedNodes rows(k).assignedNodes ...
        rows(k).minLocalDataSlots rows(k).maxLocalDataSlots ...
        rows(k).collisionFree rows(k).fullResolved ...
        rows(k).stateHash rows(k).assignmentHash];
end
v=v(:);

end


function C=validateConfig(cfg)

required={'N','maxFrames','initialDataSlots','maxDataSlots', ...
    'collisionThreshold','growthMargin','shrinkThreshold', ...
    'retentionProbability','frameBytes','phyRateBps','guardSec', ...
    'neighborGraph','managementReach','interferenceMatrix', ...
    'dataErasureProbability','managementErasureProbability', ...
    'failedShrinkTimeout','enableShrink','churnEnabled','churnFrame', ...
    'churnNode'};
for k=1:numel(required)
    if ~isfield(cfg,required{k})
        error('simulateDstrScheduling: cfg lacks %s.',required{k});
    end
end
C=cfg;
integerPositive(C.N,'N');
integerPositive(C.maxFrames,'maxFrames');
integerPositive(C.initialDataSlots,'initialDataSlots');
integerPositive(C.maxDataSlots,'maxDataSlots');
integerPositive(C.collisionThreshold,'collisionThreshold');
integerPositive(C.growthMargin,'growthMargin');
integerPositive(C.shrinkThreshold,'shrinkThreshold');
integerPositive(C.failedShrinkTimeout,'failedShrinkTimeout');
integerPositive(C.frameBytes,'frameBytes');
positiveScalar(C.phyRateBps,'phyRateBps');
nonnegativeScalar(C.guardSec,'guardSec');
probability(C.retentionProbability,'retentionProbability');
probability(C.dataErasureProbability,'dataErasureProbability');
probability(C.managementErasureProbability, ...
    'managementErasureProbability');
if C.initialDataSlots>C.maxDataSlots
    error('simulateDstrScheduling: initialDataSlots exceeds maxDataSlots.');
end
for name={'neighborGraph','managementReach','interferenceMatrix'}
    x=C.(name{1});
    if ~isequal(size(x),[C.N C.N]) || any(~ismember(x(:),[0 1]))
        error('simulateDstrScheduling: %s must be binary N-by-N.',name{1});
    end
    C.(name{1})=logical(x);
end
if ~isscalar(C.enableShrink) || ~ismember(C.enableShrink,[0 1]) || ...
        ~isscalar(C.churnEnabled) || ~ismember(C.churnEnabled,[0 1])
    error('simulateDstrScheduling: enableShrink/churnEnabled must be logical.');
end
C.enableShrink=logical(C.enableShrink);
C.churnEnabled=logical(C.churnEnabled);
integerPositive(C.churnFrame,'churnFrame');
integerPositive(C.churnNode,'churnNode');
if C.churnNode>C.N || C.churnFrame>C.maxFrames
    error('simulateDstrScheduling: churn target lies outside the run.');
end

end


function T=validateTrace(trace,C)

required={'choiceU','retentionU','dataDeliveryU','managementDeliveryU'};
for k=1:numel(required)
    if ~isfield(trace,required{k})
        error('simulateDstrScheduling: trace lacks %s.',required{k});
    end
end
T=trace;
if ~isequal(size(T.choiceU),[C.maxFrames C.N]) || ...
        ~isequal(size(T.retentionU),[C.maxFrames C.N]) || ...
        ~isequal(size(T.dataDeliveryU),[C.maxFrames C.N C.N]) || ...
        ~isequal(size(T.managementDeliveryU),[C.maxFrames 5 C.N C.N])
    error('simulateDstrScheduling: trace dimensions do not match cfg.');
end
for name=required
    x=T.(name{1});
    if any(~isfinite(x(:)) | x(:)<0 | x(:)>=1)
        error('simulateDstrScheduling: %s must lie in [0,1).',name{1});
    end
end

end


function x=configVector(C)

x=[C.N C.maxFrames C.initialDataSlots C.maxDataSlots ...
    C.collisionThreshold C.growthMargin C.shrinkThreshold ...
    C.retentionProbability C.frameBytes C.phyRateBps C.guardSec ...
    C.dataErasureProbability C.managementErasureProbability ...
    C.failedShrinkTimeout C.enableShrink C.churnEnabled C.churnFrame ...
    C.churnNode ...
    double(C.neighborGraph(:)') ...
    double(C.managementReach(:)') double(C.interferenceMatrix(:)')];

end


function positiveScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x<=0
    error('simulateDstrScheduling: %s must be positive finite.',name);
end

end


function nonnegativeScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x<0
    error('simulateDstrScheduling: %s must be nonnegative finite.',name);
end

end


function integerPositive(x,name)

positiveScalar(x,name);
if x~=round(x)
    error('simulateDstrScheduling: %s must be an integer.',name);
end

end


function probability(x,name)

if ~isscalar(x) || ~isfinite(x) || x<0 || x>1
    error('simulateDstrScheduling: %s must lie in [0,1].',name);
end

end
