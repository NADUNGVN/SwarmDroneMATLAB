function rows=runExp23zLocalMigrationClosedLoopSeed(seedValue,R)
%RUNEXP23ZLOCALMIGRATIONCLOSEDLOOPSEED Execute one paired development seed.

base=applyExp21dClosedLoopCell(R.cell,seedValue);
N=base.swarm.N;
neighbor=logical(base.swarm.A);
management=logical((double(neighbor)+eye(N))^2);
management(1:N+1:end)=false;
packet=struct('maxDataSlots',R.maxDataSlots, ...
    'claimBytes',R.claimBytes, ...
    'certificateHeaderBytes',R.certificateHeaderBytes, ...
    'certificateEntryBytes',R.certificateEntryBytes, ...
    'maxControlPacketBytes',R.maxControlPacketBytes, ...
    'revokeBytes',R.revokeBytes);

p0=base.swarm.offsets(:,1:2);
v0=zeros(N,2); v0(R.transitionNode,:)=R.transitionVelocity;
p1=p0; p1(R.transitionNode,:)=p1(R.transitionNode,:)+ ...
    R.geometryHorizonSec*R.transitionVelocity;
state0=struct('p',p0,'v',v0, ...
    'positionError',R.positionErrorBound*ones(N,1), ...
    'velocityError',R.velocityErrorBound*ones(N,1), ...
    'accelerationBound',zeros(N,1));
state1=state0; state1.p=p1;
geometry=buildCausalLocalUnionGeometryMigration(state0,state1, ...
    R.geometryHorizonSec,R.interferenceRadius,neighbor,management, ...
    R.transitionNode,packet);
if ~geometry.migration.admissible || ~geometry.migration.slotChanged
    error('runExp23zLocalMigrationClosedLoopSeed: invalid geometry fixture.');
end

rate=base.mac.phyRateBps; dataBytes=base.mac.dataBytes;
controlSlot=8*R.maxControlPacketBytes/rate+R.safeGuardSec;
dataSlot=8*dataBytes/rate+R.safeGuardSec;
frameDuration=2*N*controlSlot+R.maxDataSlots*dataSlot;
maxFrames=floor(base.swarm.T/frameDuration);
transitionFrame=ceil(R.eventTimeSec/frameDuration)+1;
eligibleFrame=transitionFrame+R.eligibilityDelayFrames;
if eligibleFrame+R.lockProofRepeatFrames>maxFrames
    error('runExp23zLocalMigrationClosedLoopSeed: mission too short.');
end

rows=repmat(exp23zLocalMigrationClosedLoopEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    localBase=base;
    localBase.mac.interferenceMatrix=geometry.oldPhysicalGraph | neighbor;
    localBase.mac.interferenceTransitions=struct( ...
        'timeSec',(transitionFrame-1)*frameDuration, ...
        'newMatrix',geometry.unionPhysicalGraph | neighbor);
    localBase.mac.lossModel='iid';
    localBase.mac.residualLoss=arm.dataLoss;
    localBase.mac.dataResidualLoss=arm.dataLoss;
    localBase.mac.ackResidualLoss=0;
    localBase.mac.backgroundLoad=0;
    localBase.mac=sharedMediumConfig(localBase);
    trace=generateSharedMediumTrace(localBase);
    scheduleHash=NaN; kernelTraceHash=NaN; kernelStateHash=NaN;
    suppressionHash=NaN; reacquisitionHash=NaN;
    eventHash=realizationHash([transitionFrame;frameDuration; ...
        double(localBase.mac.interferenceMatrix(:)); ...
        double(localBase.mac.interferenceTransitions.newMatrix(:))]);
    expectedControlAttempts=0; expectedControlAirtime=0;
    expectedSuccess=NaN; expectedErasure=NaN; expectedCollision=NaN;
    reacquired=NaN; firstReacquired=NaN; finalSuppressed=NaN;
    graphAdmissible=NaN; graphLocalOnly=NaN; graphAdded=NaN;
    graphRemoved=NaN; oldSlot=NaN; newSlot=NaN;
    clockConflictFree=NaN; clockResidual=NaN;
    if strcmp(arm.kind,'periodic')
        cfg=periodicConfig(localBase,R,N);
    else
        C=struct('maxFrames',maxFrames, ...
            'transitionFrame',transitionFrame, ...
            'eligibleFrame',eligibleFrame, ...
            'newGraphActivationFrame',transitionFrame+1, ...
            'lockProofRepeatFrames',R.lockProofRepeatFrames, ...
            'phyRateBps',rate, ...
            'claimErasureProbability',arm.controlLoss, ...
            'lockProofErasureProbability',arm.controlLoss, ...
            'responseErasureProbability',arm.controlLoss, ...
            'revokeErasureProbability',arm.controlLoss);
        T=generateLocalUnionMigrationTrace(seedValue,geometry.migration,C);
        if arm.controlLoss==0
            T.claimDeliveryU(:)=1; T.lockProofDeliveryU(:)=1;
            T.responseDeliveryU(:)=1; T.revokeDeliveryU(:)=1;
        end
        if arm.revokeBlackout
            T.revokeDeliveryU(transitionFrame,:,R.transitionNode)=0;
        end
        if arm.responseBlackout
            T.responseDeliveryU(eligibleFrame:end,R.transitionNode,:)=0;
        end
        T.hashExact=localUnionMigrationTraceHash(T);
        P=struct('guardSec',R.safeGuardSec,'dataBytes',dataBytes, ...
            'horizonSec',base.swarm.T);
        Q=buildLocalUnionMigrationContinuousSchedule( ...
            geometry.migration,C,T,P);
        physical=repmat(reshape(geometry.oldPhysicalGraph|neighbor, ...
            1,N,N),maxFrames,1,1);
        physical(transitionFrame:end,:,:)=repmat(reshape( ...
            geometry.unionPhysicalGraph|neighbor,1,N,N), ...
            maxFrames-transitionFrame+1,1,1);
        Q=bindReplayDataOutcomes(Q,neighbor,physical);
        offset=(2*reshape(trace.exp21cClockOffsetU(1,:),[],1)-1)* ...
            R.maxOffsetSec;
        drift=(2*reshape(trace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
        spec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
            'maxOffsetSec',R.maxOffsetSec,'maxDriftPpm',R.maxDriftPpm, ...
            'leadTimeSec',R.clockLeadTimeSec, ...
            'safeGuardSec',R.safeGuardSec);
        Q=applyDstrAffineClockSchedule(Q,spec);
        if arm.dataLoss>0
            Q=applySharedDataLossToReplaySchedule(Q,trace,arm.dataLoss);
        end
        cfg=migrationConfig(localBase,Q,R);
        K=Q.kernel;
        scheduleHash=Q.hashExact; kernelTraceHash=Q.kernelTraceHash;
        kernelStateHash=K.stateHashExact;
        suppressionHash=realizationHash(double( ...
            K.debug.suppressed(:,R.transitionNode)));
        reacquisitionHash=realizationHash(double(K.debug.reacquired));
        expectedControlAttempts=Q.expectedManagementAttempts;
        expectedControlAirtime=Q.expectedManagementAirtime;
        expectedSuccess=Q.expectedCompletedDataRecipientSuccess;
        expectedErasure=Q.expectedCompletedDataRecipientErasure;
        expectedCollision=Q.expectedCompletedDataRecipientCollision;
        reacquired=K.reacquired; firstReacquired=K.firstReacquiredFrame;
        finalSuppressed=K.finalSuppressed;
        graphAdmissible=geometry.migration.admissible;
        graphLocalOnly=geometry.migration.localOnly;
        graphAdded=geometry.migration.addedEdgeCount;
        graphRemoved=geometry.migration.removedEdgeCount;
        oldSlot=geometry.migration.oldSlot(R.transitionNode);
        newSlot=geometry.migration.newSlot;
        clockConflictFree=Q.clockTimingConflictFree;
        clockResidual=Q.clockEquationMaxResidualSec;
    end
    out=simSwarmSharedMedium(cfg,'periodic',trace);
    M=computeSharedMediumMetrics(out,cfg);
    D=compute6DOFMetrics(out,cfg);
    S=out.serviceScheduler;
    row=exp23zLocalMigrationClosedLoopEmptyRow();
    row.seed=seedValue; row.arm=arm.id; row.kind=arm.kind;
    row.condition=arm.condition; row.dataLoss=arm.dataLoss;
    row.controlLoss=arm.controlLoss; row.traceHash=trace.hashExact;
    row.geometryHash=geometry.hashExact;
    row.selectorHash=geometry.migration.hashExact;
    row.scheduleHash=scheduleHash; row.kernelTraceHash=kernelTraceHash;
    row.kernelStateHash=kernelStateHash;
    row.interferenceEventHash=eventHash;
    row.RMSE=M.formationRMSE; row.MINSEP=M.minSeparationEval;
    row.SAFEFAIL=double(M.safeFailure||D.diverged);
    row.DIVERGED=double(D.diverged);
    row.DATA_AIRTIME=M.dataAirtime;
    row.MANAGEMENT_AIRTIME=M.managementAirtime;
    row.TOTAL_COST=(M.dataAirtime+M.ackAirtime+M.managementAirtime)/ ...
        cfg.swarm.T;
    row.DATA_ATTEMPTS=M.dataFramesAttempted;
    row.DATA_RECIPIENT_SUCCESS=M.dataRecipientSuccess;
    row.DATA_RECIPIENT_LOSS=M.dataRecipientLoss;
    row.COLLISION_FRAMES=M.collisionFrames;
    row.BACKGROUND_COLLISION_FRAMES=M.backgroundCollisionFrames;
    row.graphAdmissible=graphAdmissible; row.graphLocalOnly=graphLocalOnly;
    row.graphAddedEdges=graphAdded; row.graphRemovedEdges=graphRemoved;
    row.oldSlot=oldSlot; row.newSlot=newSlot;
    row.eventFrame=transitionFrame; row.eligibleFrame=eligibleFrame;
    row.reacquired=reacquired; row.firstReacquiredFrame=firstReacquired;
    row.finalSuppressed=finalSuppressed;
    row.controlAttempts=S.dstrManagementAttempts;
    row.controlBytes=NaN;
    if strcmp(arm.kind,'migration'), row.controlBytes=sum(Q.controlAttemptBytes); end
    row.controlAirtime=S.dstrManagementAirtime;
    row.expectedControlAttempts=expectedControlAttempts;
    row.expectedControlAirtime=expectedControlAirtime;
    row.expectedDataSuccess=expectedSuccess;
    row.expectedDataErasure=expectedErasure;
    row.expectedDataCollision=expectedCollision;
    row.observedDataSuccess=S.dstrDataRecipientSuccessObserved;
    row.observedDataErasure=S.dstrDataRecipientErasureObserved;
    row.observedDataCollision=S.dstrDataRecipientCollisionObserved;
    row.dataOutcomeMismatches=S.dstrDataOutcomeMismatchCount;
    row.dataSkippedNoQueue=S.dstrDataSkippedNoQueue;
    row.crossPlaneOverlaps=S.dstrCrossPlaneOverlapCount;
    row.clockConflictFree=clockConflictFree;
    row.clockResidual=clockResidual;
    row.futureRandomReads=S.futureRandomReadCount;
    row.receiverTruthReads=S.receiverTruthReadCount;
    row.suppressionHash=suppressionHash;
    row.reacquisitionHash=reacquisitionHash;
    row.revokeBlackout=double(arm.revokeBlackout);
    row.responseBlackout=double(arm.responseBlackout);
    row.geometryCoupledToPlant=double(R.geometryCoupledToPlant);
    rows(k)=row;
end

end


function cfg=periodicConfig(base,R,N)

cfg=base; cfg.net.commPeriod=1/R.periodicRateHz;
cfg.mac.type='tdma'; cfg.mac.pAccess=1; cfg.mac.maxRetries=0;
cfg.shared.feedbackMode='none';
cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-local-static-tdma','logDecisions',true, ...
    'tieBreak','fifo-node','reservationFrameSlots',N, ...
    'clockOffsetMaxSec',R.maxOffsetSec, ...
    'clockDriftMaxPpm',R.maxDriftPpm, ...
    'continuousGuardTime',R.safeGuardSec, ...
    'continuousSyncPeriod',inf, ...
    'continuousEpochLeadTime',R.clockLeadTimeSec, ...
    'continuousExactAirtime',true);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);

end


function cfg=migrationConfig(base,Q,R)

cfg=base; cfg.net.commPeriod=1/50;
cfg.mac.type='tdma'; cfg.mac.pAccess=1; cfg.mac.maxRetries=0;
cfg.shared.feedbackMode='none';
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
