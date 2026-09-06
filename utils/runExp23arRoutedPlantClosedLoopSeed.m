function [rows,context]=runExp23arRoutedPlantClosedLoopSeed(seedValue,R)
%RUNEXP23ARROUTEDPLANTCLOSEDLOOPSEED Routed management plus plant replay.

% Reuse the already validated causal online-geometry constructor.  Its
% returned context depends only on the state available at requestTimeSec;
% the direct-management rows produced internally are deliberately discarded.
I=exp23aiIntegerAccountingRegistry();
[~,parentContext]=runExp23afOnlineClosureSeed(seedValue,I);
G=parentContext.geometry; M=G.migration; N=R.N;
base=baseConfig(seedValue,R); sharedTrace=generateSharedMediumTrace(base);
C=transactionConfig(R); route=routeConfig(parentContext,G,R);
certificate=receiverLiftedRoutedClosureReliabilityCertificate( ...
    M,C,R.evidencePrefixAttempts,route);

probeTrace=routedTrace(seedValue,R,M,C,route,'none');
probeQ=missionSchedule(G,C,probeTrace,route,sharedTrace,R,true);
probeCfg=replayConfig(base,probeQ,G,R,NaN);
probe=simSwarmSharedMedium(probeCfg,'periodic',sharedTrace);
decisionIndex=find(probe.t>=R.requestTimeSec-1e-12,1);
probeDecision=squeeze(probe.PHat(decisionIndex,:,:))- ...
    probe.LeaderPos(decisionIndex,:);
probePrefix=prefixHash(probeQ,R.requestTimeSec);

context=parentContext;
context.transactionConfig=C; context.routeConfig=route;
context.reliabilityCertificate=certificate;
context.probeDecisionState=probeDecision;
context.probePrefixScheduleHash=probePrefix;

rows=repmat(exp23arRoutedPlantClosedLoopEmptyRow(),numel(R.arms),1);
for armIndex=1:numel(R.arms)
    arm=R.arms(armIndex); cfg=base;
    if strcmp(arm.kind,'periodic')
        cfg=periodicConfig(cfg,R);
        cfg.swarm.offsetTransitions=struct('timeSec',R.requestTimeSec, ...
            'endTimeSec',R.requestTimeSec+R.commandRampSec, ...
            'node',R.commandNode,'newOffset',R.commandTarget);
        out=simSwarmSharedMedium(cfg,'periodic',sharedTrace);
        rows(armIndex)=baseRow(seedValue,arm,sharedTrace,out,cfg,R);
        continue;
    end

    trace=routedTrace(seedValue,R,M,C,route,arm.fault);
    Q=missionSchedule(G,C,trace,route,sharedTrace,R,arm.emergency);
    K=Q.kernel;
    motionStart=activationTime(Q,K,R);
    cfg=replayConfig(cfg,Q,G,R,motionStart);
    out=simSwarmSharedMedium(cfg,'periodic',sharedTrace);
    metrics=computeSharedMediumMetrics(out,cfg);
    physical=compute6DOFMetrics(out,cfg);
    scheduler=out.serviceScheduler;
    finalDecision=squeeze(out.PHat(decisionIndex,:,:))- ...
        out.LeaderPos(decisionIndex,:);
    decisionDifference=max(abs(finalDecision-probeDecision),[],'all');
    [physicalSubset,senderSubset,radialRatio,omittedMargin, ...
        radialPremise,radialCertified]=onlineOracles( ...
        out,G,parentContext.pairwiseTrackingRadius,R,motionStart);

    row=baseRow(seedValue,arm,sharedTrace,out,cfg,R);
    row.emergencyEnabled=double(arm.emergency);
    row.routeTraceHash=trace.hashExact;
    row.decisionStateHash=realizationHash(probeDecision(:));
    row.finalDecisionStateHash=realizationHash(finalDecision(:));
    row.decisionStateMaxDifference=decisionDifference;
    row.prefixScheduleHash=prefixHash(Q,R.requestTimeSec);
    row.probePrefixScheduleHash=probePrefix;
    row.prefixStateExact=double(decisionDifference<1e-15&& ...
        row.prefixScheduleHash==probePrefix);
    row.geometryHash=G.hashExact; row.selectorHash=M.hashExact;
    row.graphAdmissible=M.admissible;
    row.changedSenderEdges=M.changedEdgeCount;
    row.nonincidentSenderEdges=nnz( ...
        M.changedEdgeA~=R.commandNode&M.changedEdgeB~=R.commandNode);
    row.affectedCount=M.affectedCount;
    row.changedSlotCount=M.changedSlotCount;
    row.candidateProper=M.candidateUnionColoringProper;
    row.barrierClosed=K.barrierClosed;
    row.motionAuthorized=K.motionAuthorized;
    row.commitReady=K.commitReady;
    row.allAffectedReactivated=K.allAffectedReactivated;
    row.reactivatedCount=K.reactivatedCount;
    row.finalSuppressedCount=K.finalSuppressedCount;
    row.prepareBudgetExhausted=K.prepareBudgetExhausted;
    row.commitBudgetExhausted=K.commitBudgetExhausted;
    row.graphActivationFrame=K.graphActivationFrame;
    row.motionStartSec=motionStart;
    row.motionLatencySec=motionStart-R.requestTimeSec;
    row.motionGateExact=motionGateExact(out,base,R,motionStart,K);
    row.kernelStateHash=K.stateHashExact;
    row.kernelVersionHash=realizationHash(K.version);
    row.continuousVersionHash=realizationHash(R.routedContinuousVersion);
    row.missionVersionHash=realizationHash(R.missionEmbeddingVersion);
    row.physicalControlAttempts=K.physicalControlAttempts;
    row.expectedControlAttempts=Q.expectedManagementAttempts;
    row.observedControlAttempts=scheduler.dstrManagementAttempts;
    row.physicalControlBytes=K.physicalControlBytes;
    row.expectedControlBytes=Q.expectedManagementBytes;
    row.observedControlBytes=scheduler.dstrManagementBytes;
    row.expectedControlAirtime=Q.expectedManagementAirtime;
    row.observedControlAirtime=scheduler.dstrManagementAirtime;
    row.integerManagementAccountingExact=double( ...
        K.physicalControlAttempts==Q.expectedManagementAttempts&& ...
        scheduler.dstrManagementAttempts==Q.expectedManagementAttempts&& ...
        K.physicalControlBytes==Q.expectedManagementBytes&& ...
        scheduler.dstrManagementBytes==Q.expectedManagementBytes&& ...
        scheduler.dstrManagementAirtime==Q.expectedManagementAirtime);
    row.routeCollisionRecipients=K.routeCollisionRecipients;
    row.crossPacketStateWrites=K.crossPacketStateWrites;
    row.forbiddenReads=K.futureRandomReads+K.receiverTruthDecisionReads+ ...
        scheduler.futureRandomReadCount+scheduler.receiverTruthReadCount;
    row.scheduledCollisionFrames=K.scheduledCollisionFrames;
    row.prematureActivationFrames=K.prematureActivationFrames;
    row.transactionDurationSec=transactionDuration(Q,R);
    row.transactionFailureUpperBound=certificate.unionFailureUpperBound;
    row.completionProbabilityLowerBound= ...
        certificate.completionProbabilityLowerBound;
    row.transactionMissionEmbeddingExact= ...
        Q.transactionMissionEmbeddingExact;
    row.controlDataNonOverlap=double(noOverlap(Q));
    row.clockConflictFree=Q.clockTimingConflictFree;
    row.clockResidual=Q.clockEquationMaxResidualSec;
    row.dataOutcomeMismatches=scheduler.dstrDataOutcomeMismatchCount;
    row.dataSkippedNoQueue=scheduler.dstrDataSkippedNoQueue;
    row.crossPlaneOverlaps=scheduler.dstrCrossPlaneOverlapCount;
    row.expectedDataSuccess=Q.expectedCompletedDataRecipientSuccess;
    row.observedDataSuccess=scheduler.dstrDataRecipientSuccessObserved;
    row.expectedDataErasure=Q.expectedCompletedDataRecipientErasure;
    row.observedDataErasure=scheduler.dstrDataRecipientErasureObserved;
    row.expectedDataCollision=Q.expectedCompletedDataRecipientCollision;
    row.observedCollisionFrames=metrics.collisionFrames;
    row.emergencyParallelMode=double(arm.emergency&& ...
        strcmp(Q.emergencyData.mode,'parallel'));
    row.emergencyMappingExact=Q.emergencyData.mappingExact;
    row.emergencySuppressedDemand=Q.emergencyData.suppressedDemand;
    row.emergencyOpportunities=Q.emergencyData.opportunities;
    affected=M.affectedNodes;
    row.emergencyMinimumNodeOpportunities=min( ...
        Q.emergencyData.nodeOpportunities(affected));
    row.emergencyMaximumInterOpportunitySec= ...
        emergencyMaximumGap(Q,affected);
    transactionFrames=Q.missionFrameKind=="transaction";
    row.transactionMaximumFrameDurationSec=max( ...
        Q.frameEndTime(transactionFrames)-Q.frameStartTime(transactionFrames));
    row.radialConstructionPremise=radialPremise;
    row.radialTheoremCertified=radialCertified;
    row.actualPhysicalSubset=physicalSubset;
    row.actualSenderSubset=senderSubset;
    row.criticalRadialMaximumRatio=radialRatio;
    row.minimumOmittedEdgeMargin=omittedMargin;
    row.SAFEFAIL=double(metrics.safeFailure||physical.diverged);
    row.DIVERGED=double(physical.diverged);
    rows(armIndex)=row;
end

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


function C=transactionConfig(R)

C=struct('maxFrames',R.transactionFrames,'prepareFrame',1, ...
    'transactionVersion',R.transactionVersion, ...
    'prepareDenseRetryFrames',R.prepareAttempts, ...
    'prepareMaxBackoffFrames',1, ...
    'prepareRetryAttemptLimit',R.prepareAttempts, ...
    'claimEligibilityDelayFrames',R.claimEligibilityDelayFrames, ...
    'lockProofRepeatFrames',R.evidencePrefixAttempts, ...
    'claimBackoffEnabled',true, ...
    'claimDenseRetryFrames',R.claimAttempts, ...
    'claimMaxBackoffFrames',1, ...
    'claimRetryAttemptLimit',R.claimAttempts, ...
    'commitRetryAttemptLimit',R.commitAttempts, ...
    'phyRateBps',R.phyRateBps);

end


function route=routeConfig(context,G,R)

route=struct('directReach',logical(context.neighborGraph), ...
    'physicalInterference',G.oldPhysicalGraph|G.proposedPhysicalGraph, ...
    'linkErasureProbability',R.linkErasureProbability, ...
    'repetitionsPerHop',R.repetitionsPerHop, ...
    'safeGuardSec',R.safeGuardSec);

end


function T=routedTrace(seedValue,R,M,C,route,fault)

T=generateReceiverLiftedRoutedClosureTrace( ...
    seedValue+R.routeSeedOffset,M,C,route);
switch char(fault)
    case 'none'
    case 'prepare-blackout'
        T.linkUniform.prepare(:)=0;
    case 'response-blackout'
        T.linkUniform.response(:)=0;
    case 'commit-blackout'
        T.linkUniform.commit(:)=0;
    otherwise
        error('runExp23arRoutedPlantClosedLoopSeed: unknown fault.');
end
T.hashExact=receiverLiftedRoutedClosureTraceHash(T);

end


function Q=missionSchedule(G,C,T,route,sharedTrace,R,emergency)

M=G.migration;
Ptxn=struct('guardSec',R.safeGuardSec,'dataBytes',R.dataBytes, ...
    'horizonSec',R.postRequestTimeBudgetSec);
native=buildReceiverLiftedRoutedClosureContinuousSchedule( ...
    M,C,T,Ptxn,route);
P=struct('missionSec',R.missionSec,'requestTimeSec',R.requestTimeSec, ...
    'emergencyEnabled',logical(emergency), ...
    'emergencySlots',R.emergencySlots);
Q=embedReceiverLiftedRoutedClosureMissionSchedule(native,M,P);
F=numel(Q.frameStartTime); N=M.N;
oldPhysical=G.oldPhysicalGraph|M.dataNeighborGraph;
newPhysical=G.proposedPhysicalGraph|M.dataNeighborGraph;
physical=repmat(reshape(oldPhysical,1,N,N),F,1,1);
for frame=find(Q.missionGraphActivated)'
    physical(frame,:,:)=reshape(newPhysical,1,N,N);
end
Q=bindReplayDataOutcomes(Q,M.dataNeighborGraph,physical);
offset=(2*reshape(sharedTrace.exp21cClockOffsetU(1,:),[],1)-1)* ...
    R.maxOffsetSec;
drift=(2*reshape(sharedTrace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
clock=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'maxOffsetSec',R.maxOffsetSec,'maxDriftPpm',R.maxDriftPpm, ...
    'leadTimeSec',R.clockLeadTimeSec,'safeGuardSec',R.safeGuardSec);
Q=applyDstrAffineClockSchedule(Q,clock);
Q=applySharedDataLossToReplaySchedule(Q,sharedTrace,R.dataLoss);

end


function cfg=replayConfig(cfg,Q,G,R,motionStart)

cfg.net.commPeriod=1/50; cfg.mac.type='tdma'; cfg.mac.pAccess=1;
cfg.mac.maxRetries=0;
cfg.mac.interferenceMatrix=G.oldPhysicalGraph|G.migration.dataNeighborGraph;
if isfinite(motionStart)
    cfg.mac.interferenceTransitions=struct('timeSec',motionStart, ...
        'newMatrix',G.proposedPhysicalGraph|G.migration.dataNeighborGraph);
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
row=exp23arRoutedPlantClosedLoopEmptyRow();
row.seed=seedValue; row.arm=arm.id; row.kind=arm.kind;
row.fault=arm.fault; row.sharedTraceHash=trace.hashExact;
row.RMSE=M.formationRMSE; row.MISSION_RMSE=missionRmse(out,cfg,R);
row.MINSEP=M.minSeparationEval;
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
index=out.t>=R.requestTimeSec;
value=sqrt(mean(error(index,2:R.N).^2,'all'));

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


function time=activationTime(Q,K,R)

time=NaN;
if ~K.motionAuthorized, return; end
nativeFrame=K.graphActivationFrame;
missionFrame=find(Q.missionTransactionFrame==nativeFrame,1);
if isempty(missionFrame)
    time=R.requestTimeSec+transactionDuration(Q,R);
else
    time=Q.frameStartTime(missionFrame);
end

end


function duration=transactionDuration(Q,R)

frames=Q.missionFrameKind=="transaction";
duration=max(Q.frameEndTime(frames))-R.requestTimeSec;

end


function [physicalSubset,senderSubset,radialRatio,omittedMargin, ...
        radialPremise,radialCertified]=onlineOracles( ...
        out,G,pairBound,R,motionStart)

physicalSubset=true; senderSubset=true; radialRatio=0;
omittedMargin=inf; radialPremise=true; radialCertified=true;
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
            edge=norm(actual(i,:)-actual(j,:))<=R.interferenceRadius;
            physical(i,j)=edge; physical(j,i)=edge;
        end
    end
    physicalSubset=physicalSubset&&radial.actualPhysicalSubset&& ...
        ~any(triu(physical&~certificate,1),'all');
    sender=buildSenderConflictGraph(G.migration.dataNeighborGraph,physical);
    senderSubset=senderSubset&& ...
        ~any(triu(sender&~senderCertificate,1),'all');
end
physicalSubset=double(physicalSubset); senderSubset=double(senderSubset);
radialPremise=double(radialPremise); radialCertified=double(radialCertified);

end


function h=prefixHash(Q,requestTime)

data=Q.dataStartTime<requestTime-1e-12;
control=Q.controlStartTime<requestTime-1e-12;
h=realizationHash([Q.dataStartTime(data);Q.dataFrame(data); ...
    Q.dataSlot(data);Q.dataNode(data); ...
    reshape(double(Q.dataSuccessMask(data,:)),[],1); ...
    reshape(double(Q.dataErasureMask(data,:)),[],1); ...
    reshape(double(Q.dataCollisionMask(data,:)),[],1); ...
    Q.controlStartTime(control);Q.controlFrame(control); ...
    double(Q.controlSlot(control));Q.controlNode(control)]);

end


function exact=noOverlap(Q)

exact=true;
for frame=1:numel(Q.frameStartTime)
    control=Q.controlFrame==frame; data=Q.dataFrame==frame;
    if any(control)&&any(data)&&max(Q.controlStartTime(control)+ ...
            Q.controlAttemptAirtimeSec(control))> ...
            min(Q.dataStartTime(data))+1e-12
        exact=false; return;
    end
end

end


function gap=emergencyMaximumGap(Q,affected)

gap=0;
for node=reshape(affected,1,[])
    starts=sort(Q.dataStartTime(Q.dataKind=="emergency"&Q.dataNode==node));
    if numel(starts)>1, gap=max(gap,max(diff(starts))); end
end
if gap==0, gap=NaN; end

end
