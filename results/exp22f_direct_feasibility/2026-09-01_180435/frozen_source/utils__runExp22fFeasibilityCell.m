function [row,out]=runExp22fFeasibilityCell( ...
    cfg,method,label,meta,trace,details,family)
%RUNEXP22FFEASIBILITYCELL Execute and flatten one direct-feasibility row.

[base,out]=runExp21CCell(cfg,method,label,meta,trace,details);
row=exp22fFeasibilityEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
row.ENGINE_FAMILY=char(family);
S=out.serviceScheduler;
managementAirtime=0;
row.TOTAL_MANAGEMENT_ATTEMPTS=0;
row.REPLAY_FLAG=double(any(strcmp(S.config.mode, ...
    {'continuous-dstr-replay','continuous-elcs-replay'})));
if row.REPLAY_FLAG
    Q=S.config.dstrSchedule;
    managementAirtime=S.dstrManagementAirtime;
    row.TOTAL_MANAGEMENT_ATTEMPTS=S.dstrManagementAttempts;
    row.REPLAY_SCHEDULE_HASH_EXACT=Q.hashExact;
    row.REPLAY_KERNEL_TRACE_HASH_EXACT=Q.kernelTraceHash;
    row.REPLAY_KERNEL_CONFIG_HASH=Q.kernelConfigHash;
    row.REPLAY_LOGICAL_OPPORTUNITY_HASH_EXACT=Q.logicalOpportunityHashExact;
    row.REPLAY_DATA_OPPORTUNITIES=S.dstrDataOpportunities;
    row.REPLAY_DATA_ATTEMPTS=S.dstrDataAttempts;
    row.REPLAY_DATA_SKIPPED_NO_QUEUE=S.dstrDataSkippedNoQueue;
    row.REPLAY_DATA_OUTCOME_MISMATCHES=S.dstrDataOutcomeMismatchCount;
    row.REPLAY_EXPECTED_COLLISION_FRAMES= ...
        Q.expectedCompletedDataCollisionFrames;
    row.REPLAY_COLLISION_WITNESS_MATCH=double( ...
        row.ENDOGENOUS_COLLISION_FRAMES== ...
        Q.expectedCompletedDataCollisionFrames);
    row.REPLAY_EXPECTED_RECIPIENT_SUCCESS= ...
        Q.expectedCompletedDataRecipientSuccess;
    row.REPLAY_EXPECTED_RECIPIENT_ERASURE= ...
        Q.expectedCompletedDataRecipientErasure;
    row.REPLAY_EXPECTED_RECIPIENT_COLLISION= ...
        Q.expectedCompletedDataRecipientCollision;
    row.REPLAY_OBSERVED_RECIPIENT_SUCCESS= ...
        S.dstrDataRecipientSuccessObserved;
    row.REPLAY_OBSERVED_RECIPIENT_ERASURE= ...
        S.dstrDataRecipientErasureObserved;
    row.REPLAY_OBSERVED_RECIPIENT_COLLISION= ...
        S.dstrDataRecipientCollisionObserved;
    row.REPLAY_MANAGEMENT_ACCOUNTING_CLOSE=double( ...
        S.dstrManagementRecipientSuccess+ ...
        S.dstrManagementRecipientErasure+ ...
        S.dstrManagementRecipientCollision== ...
        S.dstrManagementRecipientAttempts);
    row.REPLAY_CROSS_PLANE_OVERLAPS=S.dstrCrossPlaneOverlapCount;
    row.REPLAY_CLOCK_TIMING_SAFE=Q.clockTimingConflictFree;
    row.REPLAY_CLOCK_MIN_GAP_SEC=Q.clockMinimumIntergroupGapSec;
    row.REPLAY_CLOCK_RESIDUAL_SEC=Q.clockEquationMaxResidualSec;
    if strcmp(family,'candidate-elcs')
        K=Q.kernel;
        row.ELCS_FINAL_ALL_CERTIFIED=double(K.finalAllCertified);
        row.ELCS_FALSE_VALID_EDGE_FRAMES=K.falseValidEdgeFrames;
        row.ELCS_OWNER_LOCK_VIOLATIONS=K.ownerLockViolations;
        row.ELCS_SCHEDULED_COLLISION_FRAMES=K.scheduledCollisionFrames;
    elseif strcmp(family,'prior-art-dstr')
        K=Q.kernel;
        row.DSTR_FINAL_RESOLVED=double(K.finalAllResolved);
        row.DSTR_FINAL_COLLISION_FREE=double(K.finalCollisionFree);
    end
end
row.TOTAL_MANAGEMENT_AIRTIME=managementAirtime;
row.TOTAL_MANAGEMENT_UTIL=managementAirtime/cfg.swarm.T;
row.TOTAL_OFFERED_UTIL=(row.DATA_AIRTIME+row.ACK_AIRTIME+ ...
    managementAirtime)/cfg.swarm.T;

end
