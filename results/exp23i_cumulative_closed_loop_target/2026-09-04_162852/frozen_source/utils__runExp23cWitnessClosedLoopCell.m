function [row,out]=runExp23cWitnessClosedLoopCell( ...
    cfg,method,label,meta,trace,details)
%RUNEXP23CWITNESSCLOSEDLOOPCELL Execute and flatten one ELCS-W trajectory.

[base,out]=runExp21CCell(cfg,method,label,meta,trace,details);
row=exp23cWitnessClosedLoopEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
S=out.serviceScheduler; Q=S.config.dstrSchedule; K=Q.kernel;
W=K.witnessMap;
row.ELCSW_SCHEDULE_HASH_EXACT=Q.hashExact;
row.ELCSW_KERNEL_TRACE_HASH_EXACT=Q.kernelTraceHash;
row.ELCSW_KERNEL_CONFIG_HASH=Q.kernelConfigHash;
row.ELCSW_SCHEDULE_STATE_HASH=K.scheduleStateHash;
row.ELCSW_LOGICAL_OPPORTUNITY_HASH_EXACT=Q.logicalOpportunityHashExact;
row.ELCSW_WITNESS_MAP_HASH=W.hashExact;
row.ELCSW_CONFLICT_EDGES=W.edgeCount;
neighbor=logical(cfg.swarm.A);
conflict=buildSenderConflictGraph( ...
    neighbor,logical(cfg.mac.interferenceMatrix));
row.ELCSW_HIDDEN_CONFLICT_EDGES=nnz(triu(conflict & ~neighbor,1));
row.ELCSW_MAX_WITNESS_LOAD=max(W.responseEntryLoad);
row.ELCSW_ALL_EDGES_COVERED=double(W.allCovered);
row.ELCSW_FINAL_ALL_CERTIFIED=double(K.finalAllCertified);
row.ELCSW_FIRST_ALL_CERTIFIED_FRAME=K.firstAllCertifiedFrame;
row.ELCSW_PHYSICAL_FRAME_COUNT=Q.physicalFrameCount;
row.ELCSW_PHYSICAL_FINAL_ALL_CERTIFIED=double( ...
    Q.physicalFinalAllCertified);
row.ELCSW_PHYSICAL_UNCERTIFIED_NODE_FRAMES= ...
    Q.physicalUncertifiedNodeFrames;
row.ELCSW_PHYSICAL_RETRY_CLAIM_ATTEMPTS= ...
    Q.physicalRetryClaimAttempts;
row.ELCSW_PHYSICAL_FALLBACK_COLLISION_FRAMES= ...
    Q.physicalFallbackCollisionFrames;
row.ELCSW_FALSE_VALID_EDGE_FRAMES=K.falseValidEdgeFrames;
row.ELCSW_SCHEDULED_COLLISION_FRAMES=K.scheduledCollisionFrames;
row.ELCSW_FALLBACK_COLLISION_FRAMES=K.fallbackCollisionFrames;
row.ELCSW_RETRY_CLAIM_ATTEMPTS=K.retryClaimAttempts;
row.ELCSW_CLAIM_ATTEMPTS=K.claimAttempts;
row.ELCSW_CLAIM_TRANSACTION_STARTS=K.claimTransactionStarts;
row.ELCSW_CUMULATIVE_RECEIPT_RETRY=K.cumulativeReceiptRetry;
row.ELCSW_FINAL_OPEN_CLAIM_TRANSACTIONS=K.finalOpenClaimTransactions;
row.ELCSW_RESPONSE_ATTEMPTS=K.certificateAttempts;
row.ELCSW_CONTROL_ATTEMPTS=K.controlAttempts;
row.ELCSW_CLAIM_BYTES=K.claimBytes;
row.ELCSW_RESPONSE_BYTES=K.certificateBytes;
row.ELCSW_CONTROL_BYTES=K.controlBytes;
row.ELCSW_NOMINAL_ATTEMPT_BOUND=K.nominalControlAttemptBound;
row.ELCSW_NOMINAL_BYTE_BOUND=K.nominalControlByteBound;
row.ELCSW_ABSOLUTE_ATTEMPT_BOUND=K.controlAttemptBound;
row.ELCSW_ABSOLUTE_BYTE_BOUND=K.controlByteBound;
row.ELCSW_ATTEMPT_BOUND_RATIO=K.controlAttemptBoundRatio;
row.ELCSW_BYTE_BOUND_RATIO=K.controlByteBoundRatio;
row.ELCSW_CERTIFICATE_ENTRIES=K.certificateEntriesAttempted;
row.ELCSW_RESPONSE_ENTRIES=K.responseEntriesAttempted;
row.ELCSW_LOCAL_CERTIFICATE_ENTRIES=K.localCertificateEntries;
row.ELCSW_CERTIFICATE_WITHOUT_FRESH_CLAIMS= ...
    K.certificateWithoutFreshClaims;
row.ELCSW_SCHEDULED_OPPORTUNITIES=nnz(Q.dataKind=="scheduled");
row.ELCSW_FALLBACK_OPPORTUNITIES=nnz(Q.dataKind=="fallback");
row.ELCSW_EXPECTED_DATA_COLLISION_FRAMES= ...
    Q.expectedCompletedDataCollisionFrames;
row.ELCSW_EXPECTED_DATA_RECIPIENT_SUCCESS= ...
    Q.expectedCompletedDataRecipientSuccess;
row.ELCSW_EXPECTED_DATA_RECIPIENT_ERASURE= ...
    Q.expectedCompletedDataRecipientErasure;
row.ELCSW_EXPECTED_DATA_RECIPIENT_COLLISION= ...
    Q.expectedCompletedDataRecipientCollision;
row.ELCSW_OBSERVED_DATA_RECIPIENT_SUCCESS= ...
    S.dstrDataRecipientSuccessObserved;
row.ELCSW_OBSERVED_DATA_RECIPIENT_ERASURE= ...
    S.dstrDataRecipientErasureObserved;
row.ELCSW_OBSERVED_DATA_RECIPIENT_COLLISION= ...
    S.dstrDataRecipientCollisionObserved;
row.ELCSW_DATA_OUTCOME_MISMATCHES=S.dstrDataOutcomeMismatchCount;
row.ELCSW_DATA_OPPORTUNITIES=S.dstrDataOpportunities;
row.ELCSW_DATA_ATTEMPTS=S.dstrDataAttempts;
row.ELCSW_DATA_SKIPPED_NO_QUEUE=S.dstrDataSkippedNoQueue;
row.ELCSW_DATA_COLLISION_WITNESS_MATCH=double( ...
    row.ENDOGENOUS_COLLISION_FRAMES== ...
    Q.expectedCompletedDataCollisionFrames);
row.ELCSW_EXPECTED_MANAGEMENT_ATTEMPTS=Q.expectedManagementAttempts;
row.ELCSW_EXPECTED_MANAGEMENT_AIRTIME=Q.expectedManagementAirtime;
row.ELCSW_EXPECTED_MANAGEMENT_RECIPIENT_ATTEMPTS= ...
    Q.expectedManagementRecipientAttempts;
row.ELCSW_EXPECTED_MANAGEMENT_RECIPIENT_SUCCESS= ...
    Q.expectedManagementRecipientSuccess;
row.ELCSW_EXPECTED_MANAGEMENT_RECIPIENT_ERASURE= ...
    Q.expectedManagementRecipientErasure;
row.ELCSW_EXPECTED_MANAGEMENT_RECIPIENT_COLLISION= ...
    Q.expectedManagementRecipientCollision;
row.ELCSW_MANAGEMENT_ATTEMPTS=S.dstrManagementAttempts;
row.ELCSW_MANAGEMENT_AIRTIME=S.dstrManagementAirtime;
row.ELCSW_MANAGEMENT_RECIPIENT_ATTEMPTS= ...
    S.dstrManagementRecipientAttempts;
row.ELCSW_MANAGEMENT_RECIPIENT_SUCCESS=S.dstrManagementRecipientSuccess;
row.ELCSW_MANAGEMENT_RECIPIENT_ERASURE=S.dstrManagementRecipientErasure;
row.ELCSW_MANAGEMENT_RECIPIENT_COLLISION= ...
    S.dstrManagementRecipientCollision;
row.ELCSW_MANAGEMENT_ACCOUNTING_CLOSE=double( ...
    S.dstrManagementRecipientSuccess+S.dstrManagementRecipientErasure+ ...
    S.dstrManagementRecipientCollision==S.dstrManagementRecipientAttempts);
row.ELCSW_PHYSICAL_CONTROL_BYTES=sum(Q.controlAttemptBytes);
row.ELCSW_CONTROL_BYTES_AIRTIME=row.ELCSW_PHYSICAL_CONTROL_BYTES*8/ ...
    cfg.mac.phyRateBps;
row.ELCSW_CROSS_PLANE_OVERLAPS=S.dstrCrossPlaneOverlapCount;
row.ELCSW_LAST_DATA_TIME=S.dstrLastConsumedDataTime;
row.ELCSW_LAST_CONTROL_TIME=S.dstrLastConsumedControlTime;
row.ELCSW_CLOCK_APPLIED=Q.clockApplied;
row.ELCSW_CLOCK_BASE_SCHEDULE_HASH_EXACT=Q.baseScheduleHashExact;
row.ELCSW_CLOCK_MAX_OFFSET_BOUND_SEC=Q.clockMaxOffsetSec;
row.ELCSW_CLOCK_MAX_DRIFT_BOUND_PPM=Q.clockMaxDriftPpm;
row.ELCSW_CLOCK_REALIZED_MAX_OFFSET_SEC=max(abs(Q.clockOffsetSec));
row.ELCSW_CLOCK_REALIZED_MAX_DRIFT_PPM=max(abs(Q.clockDriftPpm));
row.ELCSW_CLOCK_LEAD_SEC=Q.clockLeadTimeSec;
row.ELCSW_CLOCK_SAFE_GUARD_SEC=Q.clockSafeGuardSec;
row.ELCSW_CLOCK_NOMINAL_CUTOFF_SEC=Q.clockNominalCutoffSec;
row.ELCSW_CLOCK_TIMING_CONFLICT_FREE=Q.clockTimingConflictFree;
row.ELCSW_CLOCK_MIN_INTERGROUP_GAP_SEC=Q.clockMinimumIntergroupGapSec;
row.ELCSW_CLOCK_MAX_INTRAGROUP_SKEW_SEC=Q.clockMaximumIntragroupSkewSec;
row.ELCSW_CLOCK_EQUATION_MAX_RESIDUAL_SEC=Q.clockEquationMaxResidualSec;
if isfield(Q,'dataLossOverlayApplied')
    row.ELCSW_DATA_LOSS_OVERLAY_APPLIED=Q.dataLossOverlayApplied;
    row.ELCSW_DATA_LOSS_OVERLAY_PROBABILITY= ...
        Q.dataLossOverlayProbability;
    row.ELCSW_DATA_LOSS_OVERLAY_TRACE_HASH_EXACT= ...
        Q.dataLossOverlayTraceHashExact;
    row.ELCSW_DATA_LOSS_OVERLAY_ERASURES= ...
        Q.dataLossOverlayErasureCount;
end
if isfield(Q,'backgroundOverlay')
    row.ELCSW_BACKGROUND_OVERLAY_APPLIED=1;
    row.ELCSW_BACKGROUND_LOAD=Q.backgroundOverlay.backgroundLoad;
    row.ELCSW_BACKGROUND_TRACE_HASH_EXACT= ...
        Q.backgroundOverlay.sharedTraceHashExact;
    row.ELCSW_BACKGROUND_POTENTIAL_HITS= ...
        Q.backgroundOverlay.totalPotentialAttemptHits;
end

end
