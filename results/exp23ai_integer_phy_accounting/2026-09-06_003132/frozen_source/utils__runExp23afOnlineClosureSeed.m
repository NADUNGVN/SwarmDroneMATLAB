function [rows,context]=runExp23afOnlineClosureSeed(seedValue,R)
%RUNEXP23AFONLINECLOSURESEED Execute one paired online closure seed.

base=baseConfig(seedValue,R); N=R.N;
neighbor=logical(base.swarm.A);
management=true(N); management(1:N+1:end)=false;
pairBound=pairBounds(R,N); packet=packetConfig(R,N);
frameDuration=registeredFrameDuration(R,N);
maxFrames=floor(R.missionSec/frameDuration);
prepareFrame=ceil(R.requestTimeSec/frameDuration)+1;
C=kernelConfig(R,maxFrames,prepareFrame);
P=struct('guardSec',R.safeGuardSec,'dataBytes',R.dataBytes, ...
    'horizonSec',R.missionSec);

nominal=base.swarm.offsets; proposedNominal=nominal;
proposedNominal(R.commandNode,:)=R.commandTarget;
G0=buildCausalSweptReceiverClosure(nominal,proposedNominal, ...
    pairBound,R.interferenceRadius,neighbor,management, ...
    R.commandNode,packet);
if ~G0.migration.admissible
    error('runExp23afOnlineClosureSeed: provisional geometry invalid.');
end
sharedTrace=generateSharedMediumTrace(base);
probeTrace=closureTrace(seedValue,G0.migration,C,'none');
Qprobe=physicalSchedule(G0,C,probeTrace,P,sharedTrace,R,true);
probeCfg=replayConfig(base,Qprobe,G0,R,NaN);
probe=simSwarmSharedMedium(probeCfg,'periodic',sharedTrace);
decisionIndex=find(probe.t>=R.requestTimeSec-1e-12,1);
observed=squeeze(probe.PHat(decisionIndex,:,:))- ...
    probe.LeaderPos(decisionIndex,:);
proposed=observed;
proposed(R.commandNode,:)=observed(R.commandNode,:)+ ...
    R.commandTarget-base.swarm.offsets(R.commandNode,:);
G=buildCausalSweptReceiverClosure(observed,proposed,pairBound, ...
    R.interferenceRadius,neighbor,management,R.commandNode,packet);
if ~G.migration.admissible||G.migration.changedSlotCount<1
    error(['runExp23afOnlineClosureSeed: online closure not stimulated ' ...
        '(reason=%s, edges=%d, slots=%d, affected=%d, ' ...
        'd26=%.4f->%.4f).'], ...
        G.migration.reason,G.migration.changedEdgeCount, ...
        G.migration.changedSlotCount,G.migration.affectedCount, ...
        norm(observed(2,:)-observed(6,:)), ...
        norm(proposed(2,:)-proposed(6,:)));
end
reliability=[];
if isfield(R,'evidencePrefixClaimAttempts')
    reliability=receiverLiftedClosureReliabilityCertificate( ...
        G.migration,C,R.evidencePrefixClaimAttempts);
end
probePrefix=prefixHash(Qprobe,C.prepareFrame);
context=struct('baseOffsets',base.swarm.offsets, ...
    'observedRelativePosition',observed,'proposedRelativePosition',proposed, ...
    'neighborGraph',neighbor,'managementReach',management, ...
    'pairwiseTrackingRadius',pairBound,'packetConfig',packet, ...
    'geometry',G,'frameDurationSec',frameDuration, ...
    'prepareFrame',prepareFrame,'probePrefixHash',probePrefix, ...
    'reliabilityCertificate',reliability);

rows=repmat(exp23afOnlineClosureEmptyRow(),numel(R.arms),1);
for armIndex=1:numel(R.arms)
    arm=R.arms(armIndex); cfg=base;
    if strcmp(arm.kind,'periodic')
        cfg=periodicConfig(cfg,R);
        cfg.swarm.offsetTransitions=struct('timeSec',R.requestTimeSec, ...
            'endTimeSec',R.requestTimeSec+R.commandRampSec, ...
            'node',R.commandNode,'newOffset',R.commandTarget);
        out=simSwarmSharedMedium(cfg,'periodic',sharedTrace);
        row=baseRow(seedValue,arm,sharedTrace,out,cfg,R);
        rows(armIndex)=row; continue;
    end

    T=closureTrace(seedValue,G.migration,C,arm.fault);
    Q=physicalSchedule(G,C,T,P,sharedTrace,R,arm.emergency);
    K=Q.kernel; motionStart=NaN;
    if K.motionAuthorized
        motionStart=Q.frameStartTime(K.graphActivationFrame);
    end
    cfg=replayConfig(cfg,Q,G,R,motionStart);
    out=simSwarmSharedMedium(cfg,'periodic',sharedTrace);
    metrics=computeSharedMediumMetrics(out,cfg);
    physical=compute6DOFMetrics(out,cfg);
    scheduler=out.serviceScheduler;
    finalDecision=squeeze(out.PHat(decisionIndex,:,:))- ...
        out.LeaderPos(decisionIndex,:);
    decisionDifference=max(abs(finalDecision-observed),[],'all');
    [capsuleRatio,physicalSubset,senderSubset,nSamples,deviationClass, ...
        criticalRatio,criticalChecks,radialRatio,omittedMargin, ...
        radialPremise,radialCertified,radialClass]= ...
        onlineOracles(out,G,pairBound,R,motionStart);
    emergency=Q.dataKind=="emergency";
    nodeOpportunities=zeros(N,1);
    if isfield(Q,'emergencyData')
        nodeOpportunities=Q.emergencyData.nodeOpportunities;
    end
    affected=G.migration.affectedNodes;
    row=baseRow(seedValue,arm,sharedTrace,out,cfg,R);
    row.decisionStateHash=realizationHash(observed(:));
    row.finalDecisionStateHash=realizationHash(finalDecision(:));
    row.decisionStateMaxDifference=decisionDifference;
    row.geometryHash=G.hashExact; row.selectorHash=G.migration.hashExact;
    row.kernelTraceHash=T.hashExact; row.kernelStateHash=K.stateHashExact;
    row.kernelVersionHash=realizationHash(K.version);
    row.scheduleHash=Q.hashExact;
    row.prefixScheduleHash=prefixHash(Q,C.prepareFrame);
    row.probePrefixScheduleHash=probePrefix;
    row.prefixStateExact=double(decisionDifference<1e-15&& ...
        row.prefixScheduleHash==probePrefix);
    row.graphAdmissible=G.migration.admissible;
    row.changedSenderEdges=G.migration.changedEdgeCount;
    row.nonincidentSenderEdges=nnz( ...
        G.migration.changedEdgeA~=R.commandNode& ...
        G.migration.changedEdgeB~=R.commandNode);
    row.affectedCount=G.migration.affectedCount;
    row.changedSlotCount=G.migration.changedSlotCount;
    row.candidateProper=G.migration.candidateUnionColoringProper;
    row.prepareBytes=G.migration.prepareBytes;
    row.maxResponseBytes=G.migration.maxResponseBytes;
    row.protectedSlotFree=double(~any(ismember( ...
        R.emergencySlots,G.migration.oldSlot))&&~any(ismember( ...
        R.emergencySlots,G.migration.candidateSlot)));
    row.barrierClosed=K.barrierClosed; row.motionAuthorized=K.motionAuthorized;
    row.graphActivationFrame=K.graphActivationFrame;
    row.commitReady=K.commitReady;
    row.allReactivated=K.allAffectedReactivated;
    row.reactivatedCount=K.reactivatedCount;
    row.finalSuppressedCount=K.finalSuppressedCount;
    row.prepareBudgetExhausted=K.prepareBudgetExhausted;
    row.commitBudgetExhausted=K.commitBudgetExhausted;
    row.kernelActualSubsetOld=K.actualSubsetOld;
    row.kernelActualSubsetUnion=K.actualSubsetUnion;
    row.kernelFinalColoringProper=K.finalActiveColoringProper;
    row.prematureActivationFrames=K.prematureActivationFrames;
    row.controlAttemptBoundRatio=K.controlAttemptBoundRatio;
    row.controlByteBoundRatio=K.controlByteBoundRatio;
    row.prepareAttempts=K.attempts.prepare;
    row.quietAttempts=K.attempts.quiet;
    row.claimAttempts=K.attempts.claim;
    row.responseAttempts=K.attempts.response;
    row.commitAttempts=K.attempts.commit;
    row.motionStartSec=motionStart;
    row.motionLatencySec=motionStart-R.requestTimeSec;
    row.motionGateExact=motionGateExact(out,base,R,motionStart,K);
    row.capsuleMaximumRatio=capsuleRatio;
    row.capsuleBoundSatisfied=double(capsuleRatio<=1+1e-12);
    row.criticalCapsuleMaximumRatio=criticalRatio;
    row.criticalCapsuleBoundSatisfied=double(criticalRatio<=1+1e-12);
    row.criticalCapsulePairChecks=criticalChecks;
    row.criticalRadialMaximumRatio=radialRatio;
    row.criticalRadialBoundSatisfied=double(radialRatio<=1+1e-12);
    row.minimumOmittedEdgeMargin=omittedMargin;
    row.radialConstructionPremise=radialPremise;
    row.radialTheoremCertified=radialCertified;
    if ~isempty(reliability)
        row.reliabilityCertificateHash=reliability.hashExact;
        row.transactionHorizonFeasible=reliability.horizonFeasible;
        row.transactionFailureUpperBound= ...
            reliability.unionFailureUpperBound;
        row.completionProbabilityLowerBound= ...
            reliability.completionProbabilityLowerBound;
        row.prepareFailureUpperBound= ...
            reliability.prepareFailureUpperBound;
        row.evidenceFailureUpperBound= ...
            reliability.evidenceFailureUpperBound;
        row.responseFailureUpperBound= ...
            reliability.responseFailureUpperBound;
        row.commitFailureUpperBound= ...
            reliability.commitFailureUpperBound;
    end
    row.maxCommandPairDeviation=deviationClass(1);
    row.maxLeaderPairDeviation=deviationClass(2);
    row.maxOtherPairDeviation=deviationClass(3);
    row.maxCommandPairRadialContraction=radialClass(1);
    row.maxLeaderPairRadialContraction=radialClass(2);
    row.maxOtherPairRadialContraction=radialClass(3);
    row.actualPhysicalSubset=physicalSubset;
    row.actualSenderSubset=senderSubset;
    row.actualSubsetCheckSamples=nSamples;
    row.emergencyEnabled=double(arm.emergency);
    row.emergencyParallelMode=double(arm.emergency&& ...
        strcmp(Q.emergencyData.mode,'parallel'));
    [mappingExact,suppressedDemand]=emergencyMapping(Q,G,R,arm.emergency);
    row.emergencyMappingExact=mappingExact;
    row.emergencySuppressedDemand=suppressedDemand;
    row.emergencyOpportunities=nnz(emergency);
    row.emergencyMinimumNodeOpportunities=min(nodeOpportunities(affected));
    row.emergencyMaximumNodeOpportunities=max(nodeOpportunities(affected));
    row.emergencyRecipientSuccess=nnz(Q.dataSuccessMask(emergency,:));
    row.emergencyRecipientErasure=nnz(Q.dataErasureMask(emergency,:));
    row.emergencyRecipientCollision=nnz(Q.dataCollisionMask(emergency,:));
    row.kernelCollisionFrames=K.scheduledCollisionFrames;
    row.expectedCollisionRecipients=Q.expectedCompletedDataRecipientCollision;
    row.observedCollisionFrames=metrics.collisionFrames;
    row.dataOutcomeMismatches=scheduler.dstrDataOutcomeMismatchCount;
    row.dataSkippedNoQueue=scheduler.dstrDataSkippedNoQueue;
    row.crossPlaneOverlaps=scheduler.dstrCrossPlaneOverlapCount;
    row.expectedDataSuccess=Q.expectedCompletedDataRecipientSuccess;
    row.observedDataSuccess=scheduler.dstrDataRecipientSuccessObserved;
    row.expectedDataErasure=Q.expectedCompletedDataRecipientErasure;
    row.observedDataErasure=scheduler.dstrDataRecipientErasureObserved;
    row.controlAttempts=scheduler.dstrManagementAttempts;
    row.expectedControlAttempts=Q.expectedManagementAttempts;
    row.controlBytes=sum(Q.controlAttemptBytes);
    row.observedControlBytes=scheduler.dstrManagementBytes;
    row.expectedControlBytes=Q.expectedManagementBytes;
    row.controlAirtime=scheduler.dstrManagementAirtime;
    row.expectedControlAirtime=Q.expectedManagementAirtime;
    row.clockConflictFree=Q.clockTimingConflictFree;
    row.clockResidual=Q.clockEquationMaxResidualSec;
    row.futureRandomReads=scheduler.futureRandomReadCount;
    row.receiverTruthReads=scheduler.receiverTruthReadCount;
    row.RMSE=metrics.formationRMSE;
    row.MISSION_RMSE=missionRmse(out,base,R);
    row.MINSEP=metrics.minSeparationEval;
    row.SAFEFAIL=double(metrics.safeFailure||physical.diverged);
    row.DIVERGED=double(physical.diverged);
    row.DATA_AIRTIME=metrics.dataAirtime;
    row.MANAGEMENT_AIRTIME=metrics.managementAirtime;
    row.TOTAL_COST=metrics.offeredAirtimeUtilization;
    rows(armIndex)=row;
end

end


function [exact,demand]=emergencyMapping(Q,G,R,enabled)

emergency=Q.dataKind=="emergency";
affected=reshape(G.migration.affectedNodes,[],1);
demand=0; exact=true;
for frame=1:numel(Q.frameStartTime)
    suppressed=logical(Q.kernel.debug.suppressed(frame,affected));
    expectedNodes=affected(suppressed);
    expectedSlots=R.emergencySlots(find(suppressed));
    selected=find(emergency&Q.dataFrame==frame);
    demand=demand+numel(expectedNodes);
    exact=exact&&numel(selected)==numel(expectedNodes)&& ...
        isequal(Q.dataNode(selected),expectedNodes)&& ...
        isequal(Q.dataSlot(selected),expectedSlots);
end
if ~enabled
    exact=~any(emergency);
end
exact=double(exact);

end


function cfg=baseConfig(seedValue,R)

cfg=applyExp21dClosedLoopCell(R.cell,seedValue);
cfg.swarm.offsets=R.formationScale*cfg.swarm.offsets;
cfg.swarm.initialPositions=cfg.swarm.offsets;
cfg.swarm.initialVelocities=zeros(R.N,3);
cfg.swarm.T=R.missionSec; cfg.shared.evalStart=R.evalStartSec;
cfg.mac.lossModel='iid'; cfg.mac.residualLoss=R.dataLoss;
cfg.mac.dataResidualLoss=R.dataLoss; cfg.mac.ackResidualLoss=0;
cfg.mac.backgroundLoad=0; cfg.shared.feedbackMode='none';
cfg.mac=sharedMediumConfig(cfg);

end


function E=pairBounds(R,N)

E=R.defaultPairTrackingRadius*(ones(N)-eye(N));
E(1,:)=R.leaderPairTrackingRadius; E(:,1)=R.leaderPairTrackingRadius;
E(R.commandNode,:)=R.commandPairTrackingRadius;
E(:,R.commandNode)=R.commandPairTrackingRadius;
E(1:N+1:end)=0;

end


function packet=packetConfig(R,N)

packet=struct('maxDataSlots',R.maxDataSlots,'maxAffectedNodes',N, ...
    'prepareHeaderBytes',R.prepareHeaderBytes, ...
    'affectedEntryBytes',R.affectedEntryBytes,'claimBytes',R.claimBytes, ...
    'quietBytes',R.quietBytes,'lockProofBytes',R.lockProofBytes, ...
    'certificateHeaderBytes',R.certificateHeaderBytes, ...
    'certificateEntryBytes',R.certificateEntryBytes, ...
    'commitBytes',R.commitBytes, ...
    'maxControlPacketBytes',R.maxControlPacketBytes, ...
    'revokeBytes',R.revokeBytes,'retiringSlot',(1:N)');

end


function C=kernelConfig(R,maxFrames,prepareFrame)

C=struct('maxFrames',maxFrames,'prepareFrame',prepareFrame, ...
    'transactionVersion',R.transactionVersion, ...
    'prepareDenseRetryFrames',R.prepareDenseRetryFrames, ...
    'prepareMaxBackoffFrames',R.prepareMaxBackoffFrames, ...
    'prepareRetryAttemptLimit',R.prepareRetryAttemptLimit, ...
    'claimEligibilityDelayFrames',R.claimEligibilityDelayFrames, ...
    'lockProofRepeatFrames',R.lockProofRepeatFrames, ...
    'claimBackoffEnabled',R.claimBackoffEnabled, ...
    'claimDenseRetryFrames',R.claimDenseRetryFrames, ...
    'claimMaxBackoffFrames',R.claimMaxBackoffFrames, ...
    'claimRetryAttemptLimit',R.claimRetryAttemptLimit, ...
    'commitRetryAttemptLimit',R.commitRetryAttemptLimit, ...
    'phyRateBps',R.phyRateBps, ...
    'prepareErasureProbability',R.controlLoss, ...
    'quietErasureProbability',R.controlLoss, ...
    'claimErasureProbability',R.controlLoss, ...
    'lockProofErasureProbability',R.controlLoss, ...
    'responseErasureProbability',R.controlLoss, ...
    'commitErasureProbability',R.controlLoss, ...
    'revokeErasureProbability',R.controlLoss,'piggybackRevoke',true);

end


function T=closureTrace(seedValue,M,C,fault)

T=generateReceiverLiftedClosureTrace(seedValue,M,C);
remote=M.affectedNodes(M.affectedNodes~=M.initiator);
switch char(fault)
    case 'none'
    case 'prepare-blackout'
        T.prepareDeliveryU(:,remote(1),M.initiator)=0;
    case 'response-blackout'
        T.responseDigest(:)=0;
    case 'commit-blackout'
        for node=reshape(remote,1,[])
            T.commitDeliveryU(:,node,M.initiator)=0;
        end
    otherwise
        error('runExp23afOnlineClosureSeed: unknown fault.');
end
T.hashExact=receiverLiftedClosureTraceHash(T);

end


function Q=physicalSchedule(G,C,T,P,sharedTrace,R,emergency)

Q=buildReceiverLiftedClosureContinuousSchedule(G.migration,C,T,P);
if emergency
    Q=addReceiverClosureEmergencyData(Q,G.migration,R.emergencySlots);
end
N=G.N; K=Q.kernel;
physical=repmat(reshape(G.oldPhysicalGraph| ...
    G.migration.dataNeighborGraph,1,N,N),C.maxFrames,1,1);
if isfinite(K.graphActivationFrame)
    physical(K.graphActivationFrame:end,:,:)=repmat(reshape( ...
        G.proposedPhysicalGraph|G.migration.dataNeighborGraph,1,N,N), ...
        C.maxFrames-K.graphActivationFrame+1,1,1);
end
Q=bindReplayDataOutcomes(Q,G.migration.dataNeighborGraph,physical);
offset=(2*reshape(sharedTrace.exp21cClockOffsetU(1,:),[],1)-1)* ...
    R.maxOffsetSec;
drift=(2*reshape(sharedTrace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
spec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'maxOffsetSec',R.maxOffsetSec,'maxDriftPpm',R.maxDriftPpm, ...
    'leadTimeSec',R.clockLeadTimeSec,'safeGuardSec',R.safeGuardSec);
Q=applyDstrAffineClockSchedule(Q,spec);
Q=applySharedDataLossToReplaySchedule(Q,sharedTrace,R.dataLoss);

end


function cfg=replayConfig(cfg,Q,G,R,motionStart)

cfg.net.commPeriod=1/50; cfg.mac.type='tdma'; cfg.mac.pAccess=1;
cfg.mac.maxRetries=0; cfg.mac.interferenceMatrix= ...
    G.oldPhysicalGraph|G.migration.dataNeighborGraph;
if isfinite(Q.kernel.graphActivationFrame)
    cfg.mac.interferenceTransitions=struct('timeSec', ...
        Q.frameStartTime(Q.kernel.graphActivationFrame), ...
        'newMatrix',G.proposedPhysicalGraph| ...
        G.migration.dataNeighborGraph);
end
if isfinite(motionStart)
    cfg.swarm.offsetTransitions=struct('timeSec',motionStart, ...
        'endTimeSec',motionStart+R.commandRampSec, ...
        'node',R.commandNode,'newOffset',R.commandTarget);
elseif isfield(cfg.swarm,'offsetTransitions')
    cfg.swarm=rmfield(cfg.swarm,'offsetTransitions');
end
cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-elcs-replay','logDecisions',true, ...
    'tieBreak','fifo-node','clockOffsetMaxSec',R.maxOffsetSec, ...
    'clockDriftMaxPpm',R.maxDriftPpm, ...
    'continuousGuardTime',R.safeGuardSec, ...
    'continuousSyncPeriod',inf, ...
    'continuousEpochLeadTime',R.clockLeadTimeSec, ...
    'continuousExactAirtime',true,'dstrSchedule',Q);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);

end


function cfg=periodicConfig(cfg,R)

cfg.net.commPeriod=1/R.periodicRateHz;
cfg.mac.type='tdma'; cfg.mac.pAccess=1; cfg.mac.maxRetries=0;
cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-local-static-tdma','logDecisions',true, ...
    'tieBreak','fifo-node','reservationFrameSlots',R.N, ...
    'clockOffsetMaxSec',R.maxOffsetSec, ...
    'clockDriftMaxPpm',R.maxDriftPpm, ...
    'continuousGuardTime',R.safeGuardSec, ...
    'continuousSyncPeriod',inf, ...
    'continuousEpochLeadTime',R.clockLeadTimeSec, ...
    'continuousExactAirtime',true);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);

end


function row=baseRow(seedValue,arm,trace,out,cfg,R)

M=computeSharedMediumMetrics(out,cfg); D=compute6DOFMetrics(out,cfg);
row=exp23afOnlineClosureEmptyRow(); row.seed=seedValue;
row.arm=arm.id; row.kind=arm.kind; row.fault=arm.fault;
row.traceHash=trace.hashExact; row.RMSE=M.formationRMSE;
row.MISSION_RMSE=missionRmse(out,cfg,R); row.MINSEP=M.minSeparationEval;
row.SAFEFAIL=double(M.safeFailure||D.diverged);
row.DIVERGED=double(D.diverged); row.DATA_AIRTIME=M.dataAirtime;
row.MANAGEMENT_AIRTIME=M.managementAirtime;
row.TOTAL_COST=M.offeredAirtimeUtilization;

end


function value=missionRmse(out,cfg,R)

K=numel(out.t); desired=repmat(reshape(cfg.swarm.offsets, ...
    1,R.N,3),K,1,1);
for k=1:K
    alpha=min(1,max(0,(out.t(k)-R.requestTimeSec)/R.commandRampSec));
    desired(k,R.commandNode,:)=reshape((1-alpha)* ...
        cfg.swarm.offsets(R.commandNode,:)+alpha*R.commandTarget,1,1,3);
end
error=sqrt(sum((out.P-(out.P(:,1,:)+desired)).^2,3));
index=out.t>=R.requestTimeSec; value=sqrt(mean( ...
    error(index,2:R.N).^2,'all'));

end


function exact=motionGateExact(out,base,R,motionStart,K)

logged=squeeze(out.desiredOffsets(:,R.commandNode,:));
before=true(size(out.t));
if isfinite(motionStart), before=out.t<motionStart-1e-12; end
held=max(abs(logged(before,:)-base.swarm.offsets(R.commandNode,:)), ...
    [],'all')<1e-12;
if K.motionAuthorized
    moved=any(vecnorm(logged(~before,:)- ...
        base.swarm.offsets(R.commandNode,:),2,2)>1e-12);
    exact=held&&moved;
else
    exact=held&&all(abs(logged- ...
        base.swarm.offsets(R.commandNode,:))<1e-12,'all');
end
exact=double(exact);

end


function [ratio,physicalSubset,senderSubset,nSamples,deviationClass, ...
        criticalRatio,criticalChecks,radialRatio,omittedMargin, ...
        radialPremise,radialCertified,radialClass]= ...
        onlineOracles(out,G,pairBound,R,motionStart)

ratio=0; physicalSubset=true; senderSubset=true; nSamples=0;
criticalRatio=0; criticalChecks=0;
radialRatio=0; omittedMargin=inf;
radialPremise=true; radialCertified=true;
deviationClass=zeros(3,1);
radialClass=zeros(3,1);
start=find(out.t>=R.requestTimeSec-1e-12,1);
for k=start:numel(out.t)
    if isfinite(motionStart)
        alpha=min(1,max(0,(out.t(k)-motionStart)/R.commandRampSec));
    else
        alpha=0;
    end
    nominal=(1-alpha)*G.observedRelativePosition+ ...
        alpha*G.proposedRelativePosition;
    actual=squeeze(out.P(k,:,:))-out.LeaderPos(k,:);
    activated=isfinite(motionStart)&&out.t(k)>=motionStart-1e-12;
    certificate=G.oldPhysicalGraph;
    senderCertificate=G.migration.oldGraph;
    if activated
        certificate=G.proposedPhysicalGraph;
        senderCertificate=G.migration.unionGraph;
    end
    radial=evaluateSweptRadialContractionContract( ...
        nominal,actual,certificate,pairBound,R.interferenceRadius);
    radialRatio=max(radialRatio,radial.maximumRadialContractionRatio);
    omittedMargin=min(omittedMargin,radial.minimumOmittedPairMargin);
    radialPremise=radialPremise&&radial.constructionPremiseSatisfied;
    radialCertified=radialCertified&&radial.theoremCertified;
    physical=false(R.N);
    for i=1:R.N
        for j=i+1:R.N
            deviation=norm((actual(i,:)-actual(j,:))- ...
                (nominal(i,:)-nominal(j,:)));
            ratio=max(ratio,deviation/pairBound(i,j));
            if ~certificate(i,j)
                criticalRatio=max( ...
                    criticalRatio,deviation/pairBound(i,j));
                criticalChecks=criticalChecks+1;
            end
            if any([i j]==R.commandNode)
                category=1;
            elseif any([i j]==1)
                category=2;
            else
                category=3;
            end
            deviationClass(category)=max( ...
                deviationClass(category),deviation);
            if ~certificate(i,j)
                inward=max(0,norm(nominal(i,:)-nominal(j,:))- ...
                    norm(actual(i,:)-actual(j,:)));
                radialClass(category)=max(radialClass(category),inward);
            end
            edge=norm(actual(i,:)-actual(j,:))<=R.interferenceRadius;
            physical(i,j)=edge; physical(j,i)=edge;
        end
    end
    physicalSubset=physicalSubset&&radial.actualPhysicalSubset&& ...
        ~any(triu(physical&~certificate,1),'all');
    sender=buildSenderConflictGraph(G.migration.dataNeighborGraph,physical);
    senderSubset=senderSubset&& ...
        ~any(triu(sender&~senderCertificate,1),'all');
    nSamples=nSamples+1;
end
physicalSubset=double(physicalSubset); senderSubset=double(senderSubset);
radialPremise=double(radialPremise); radialCertified=double(radialCertified);

end


function h=prefixHash(Q,prepareFrame)

data=Q.dataFrame<prepareFrame; control=Q.controlFrame<prepareFrame;
h=realizationHash([Q.dataFrame(data);Q.dataSlot(data);Q.dataNode(data); ...
    reshape(double(Q.dataSuccessMask(data,:)),[],1); ...
    reshape(double(Q.dataErasureMask(data,:)),[],1); ...
    reshape(double(Q.dataCollisionMask(data,:)),[],1); ...
    Q.controlFrame(control); ...
    double(Q.controlSlot(control));Q.controlNode(control)]);

end


function duration=registeredFrameDuration(R,N)

control=8*R.maxControlPacketBytes/R.phyRateBps+R.safeGuardSec;
data=8*R.dataBytes/R.phyRateBps+R.safeGuardSec;
duration=(2*N+1)*control+R.maxDataSlots*data;

end
