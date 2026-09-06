function [row,out]=runExp22dElcsClosedLoopCell( ...
    cfg,method,label,meta,trace,details)
%RUNEXP22DELCSCLOSEDLOOPCELL Execute and flatten one ELCS-F trajectory.

[base,out]=runExp21CCell(cfg,method,label,meta,trace,details);
row=exp22dElcsClosedLoopEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
S=out.serviceScheduler;
Q=S.config.dstrSchedule;
K=Q.kernel;
row.ELCS_SCHEDULE_HASH_EXACT=Q.hashExact;
row.ELCS_KERNEL_TRACE_HASH_EXACT=Q.kernelTraceHash;
row.ELCS_KERNEL_CONFIG_HASH=Q.kernelConfigHash;
row.ELCS_KERNEL_REALIZATION_HASH=K.realizationHash;
row.ELCS_SCHEDULE_STATE_HASH=K.scheduleStateHash;
row.ELCS_LOGICAL_OPPORTUNITY_HASH_EXACT=Q.logicalOpportunityHashExact;
row.ELCS_FINAL_ALL_CERTIFIED=double(K.finalAllCertified);
row.ELCS_FIRST_ALL_CERTIFIED_FRAME=K.firstAllCertifiedFrame;
row.ELCS_STATUS_ATTEMPTS=K.statusAttempts;
row.ELCS_DISCOVERY_STATUS_ATTEMPTS=K.discoveryStatusAttempts;
row.ELCS_REQUEST_STATUS_ATTEMPTS=K.requestStatusAttempts;
row.ELCS_GRANT_ATTEMPTS=K.grantAttempts;
row.ELCS_GRANT_WITHOUT_DECODED_REQUEST=K.grantWithoutDecodedRequest;
row.ELCS_CONTROL_ATTEMPT_BOUND=Q.controlAttemptBound;
row.ELCS_CONTROL_BOUND_RATIO=K.controlAttempts/Q.controlAttemptBound;
row.ELCS_FALSE_VALID_EDGE_FRAMES=K.falseValidEdgeFrames;
row.ELCS_OWNER_LOCK_VIOLATIONS=K.ownerLockViolations;
row.ELCS_SCHEDULED_COLLISION_FRAMES=K.scheduledCollisionFrames;
row.ELCS_SCHEDULED_OPPORTUNITIES=nnz(Q.dataKind=="scheduled");
row.ELCS_FALLBACK_OPPORTUNITIES=nnz(Q.dataKind=="fallback");
row.ELCS_EXPECTED_DATA_COLLISION_FRAMES= ...
    Q.expectedCompletedDataCollisionFrames;
row.ELCS_EXPECTED_DATA_RECIPIENT_SUCCESS= ...
    Q.expectedCompletedDataRecipientSuccess;
row.ELCS_EXPECTED_DATA_RECIPIENT_ERASURE= ...
    Q.expectedCompletedDataRecipientErasure;
row.ELCS_EXPECTED_DATA_RECIPIENT_COLLISION= ...
    Q.expectedCompletedDataRecipientCollision;
row.ELCS_OBSERVED_DATA_RECIPIENT_SUCCESS= ...
    S.dstrDataRecipientSuccessObserved;
row.ELCS_OBSERVED_DATA_RECIPIENT_ERASURE= ...
    S.dstrDataRecipientErasureObserved;
row.ELCS_OBSERVED_DATA_RECIPIENT_COLLISION= ...
    S.dstrDataRecipientCollisionObserved;
row.ELCS_DATA_OUTCOME_MISMATCHES=S.dstrDataOutcomeMismatchCount;
row.ELCS_DATA_OPPORTUNITIES=S.dstrDataOpportunities;
row.ELCS_DATA_ATTEMPTS=S.dstrDataAttempts;
row.ELCS_DATA_SKIPPED_NO_QUEUE=S.dstrDataSkippedNoQueue;
row.ELCS_DATA_COLLISION_WITNESS_MATCH=double( ...
    row.ENDOGENOUS_COLLISION_FRAMES== ...
    Q.expectedCompletedDataCollisionFrames);
row.ELCS_MANAGEMENT_BUSY_SLOTS=S.dstrManagementBusySlots;
row.ELCS_EXPECTED_MANAGEMENT_ATTEMPTS=Q.expectedManagementAttempts;
row.ELCS_EXPECTED_MANAGEMENT_RECIPIENT_ATTEMPTS= ...
    Q.expectedManagementRecipientAttempts;
row.ELCS_EXPECTED_MANAGEMENT_RECIPIENT_SUCCESS= ...
    Q.expectedManagementRecipientSuccess;
row.ELCS_EXPECTED_MANAGEMENT_RECIPIENT_ERASURE= ...
    Q.expectedManagementRecipientErasure;
row.ELCS_EXPECTED_MANAGEMENT_RECIPIENT_COLLISION= ...
    Q.expectedManagementRecipientCollision;
row.ELCS_MANAGEMENT_ATTEMPTS=S.dstrManagementAttempts;
row.ELCS_MANAGEMENT_AIRTIME=S.dstrManagementAirtime;
row.ELCS_MANAGEMENT_RECIPIENT_ATTEMPTS= ...
    S.dstrManagementRecipientAttempts;
row.ELCS_MANAGEMENT_RECIPIENT_SUCCESS= ...
    S.dstrManagementRecipientSuccess;
row.ELCS_MANAGEMENT_RECIPIENT_ERASURE= ...
    S.dstrManagementRecipientErasure;
row.ELCS_MANAGEMENT_RECIPIENT_COLLISION= ...
    S.dstrManagementRecipientCollision;
row.ELCS_MANAGEMENT_ACCOUNTING_CLOSE=double( ...
    S.dstrManagementRecipientSuccess+ ...
    S.dstrManagementRecipientErasure+ ...
    S.dstrManagementRecipientCollision== ...
    S.dstrManagementRecipientAttempts);
row.ELCS_CROSS_PLANE_OVERLAPS=S.dstrCrossPlaneOverlapCount;
row.ELCS_LAST_DATA_TIME=S.dstrLastConsumedDataTime;
row.ELCS_LAST_CONTROL_TIME=S.dstrLastConsumedControlTime;
row.ELCS_CLOCK_APPLIED=Q.clockApplied;
row.ELCS_CLOCK_BASE_SCHEDULE_HASH_EXACT=Q.baseScheduleHashExact;
row.ELCS_CLOCK_MAX_OFFSET_BOUND_SEC=Q.clockMaxOffsetSec;
row.ELCS_CLOCK_MAX_DRIFT_BOUND_PPM=Q.clockMaxDriftPpm;
row.ELCS_CLOCK_REALIZED_MAX_OFFSET_SEC=max(abs(Q.clockOffsetSec));
row.ELCS_CLOCK_REALIZED_MAX_DRIFT_PPM=max(abs(Q.clockDriftPpm));
row.ELCS_CLOCK_LEAD_SEC=Q.clockLeadTimeSec;
row.ELCS_CLOCK_SAFE_GUARD_SEC=Q.clockSafeGuardSec;
row.ELCS_CLOCK_NOMINAL_CUTOFF_SEC=Q.clockNominalCutoffSec;
row.ELCS_CLOCK_TIMING_CONFLICT_FREE=Q.clockTimingConflictFree;
row.ELCS_CLOCK_MIN_INTERGROUP_GAP_SEC=Q.clockMinimumIntergroupGapSec;
row.ELCS_CLOCK_MAX_INTRAGROUP_SKEW_SEC=Q.clockMaximumIntragroupSkewSec;
row.ELCS_CLOCK_EQUATION_MAX_RESIDUAL_SEC= ...
    Q.clockEquationMaxResidualSec;

end
