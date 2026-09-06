function [row,out]=runExp21dClosedLoopCell( ...
    cfg,method,label,meta,trace,details)
%RUNEXP21DCLOSEDLOOPCELL Execute and flatten one integration trajectory.

[base,out]=runExp21CCell(cfg,method,label,meta,trace,details);
row=exp21dClosedLoopEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
S=out.serviceScheduler;
scheduledDstr=strcmp(S.config.mode,'continuous-dstr-replay');
warm=contains(string(meta.arm),'warm');
native=scheduledDstr && ~warm;
row.DSTR_NATIVE_FLAG=double(native);
row.DSTR_WARM_FLAG=double(warm);
if scheduledDstr
    Q=S.config.dstrSchedule;
    K=Q.kernel;
    row.DSTR_SCHEDULE_HASH_EXACT=Q.hashExact;
    row.DSTR_KERNEL_TRACE_HASH_EXACT=Q.kernelTraceHash;
    row.DSTR_KERNEL_CONFIG_HASH=Q.kernelConfigHash;
    row.DSTR_SCHEDULED_DATA_ATTEMPTS=numel(Q.dataStartTime);
    row.DSTR_EXPECTED_DATA_COLLISION_FRAMES= ...
        Q.expectedCompletedDataCollisionFrames;
    row.DSTR_EXPECTED_DATA_RECIPIENT_SUCCESS= ...
        Q.expectedCompletedDataRecipientSuccess;
    row.DSTR_EXPECTED_DATA_RECIPIENT_ERASURE= ...
        Q.expectedCompletedDataRecipientErasure;
    row.DSTR_EXPECTED_DATA_RECIPIENT_COLLISION= ...
        Q.expectedCompletedDataRecipientCollision;
    row.DSTR_OBSERVED_DATA_RECIPIENT_SUCCESS= ...
        S.dstrDataRecipientSuccessObserved;
    row.DSTR_OBSERVED_DATA_RECIPIENT_ERASURE= ...
        S.dstrDataRecipientErasureObserved;
    row.DSTR_OBSERVED_DATA_RECIPIENT_COLLISION= ...
        S.dstrDataRecipientCollisionObserved;
    row.DSTR_DATA_OUTCOME_MISMATCHES=S.dstrDataOutcomeMismatchCount;
    row.DSTR_DATA_OPPORTUNITIES=S.dstrDataOpportunities;
    row.DSTR_DATA_ATTEMPTS=S.dstrDataAttempts;
    row.DSTR_DATA_SKIPPED_NO_QUEUE=S.dstrDataSkippedNoQueue;
    row.DSTR_DATA_COLLISION_WITNESS_MATCH=double( ...
        row.ENDOGENOUS_COLLISION_FRAMES== ...
        Q.expectedCompletedDataCollisionFrames);
    row.DSTR_MANAGEMENT_BUSY_SLOTS=S.dstrManagementBusySlots;
    row.DSTR_MANAGEMENT_ATTEMPTS=S.dstrManagementAttempts;
    row.DSTR_MANAGEMENT_AIRTIME=S.dstrManagementAirtime;
    row.DSTR_MANAGEMENT_RECIPIENT_ATTEMPTS= ...
        S.dstrManagementRecipientAttempts;
    row.DSTR_MANAGEMENT_RECIPIENT_SUCCESS= ...
        S.dstrManagementRecipientSuccess;
    row.DSTR_MANAGEMENT_RECIPIENT_ERASURE= ...
        S.dstrManagementRecipientErasure;
    row.DSTR_MANAGEMENT_RECIPIENT_COLLISION= ...
        S.dstrManagementRecipientCollision;
    row.DSTR_MANAGEMENT_COLLISION_SLOTS= ...
        S.dstrManagementCollisionSlots;
    row.DSTR_MANAGEMENT_ACCOUNTING_CLOSE=double( ...
        S.dstrManagementRecipientSuccess+ ...
        S.dstrManagementRecipientErasure+ ...
        S.dstrManagementRecipientCollision== ...
        S.dstrManagementRecipientAttempts);
    row.DSTR_CROSS_PLANE_OVERLAPS=S.dstrCrossPlaneOverlapCount;
    row.DSTR_FIRST_CONVERGENCE_SEC=S.reservationFirstConvergenceTime;
    row.DSTR_KERNEL_FIRST_RESOLUTION_FRAME=K.firstResolutionFrame;
    row.DSTR_KERNEL_FIRST_CONVERGENCE_FRAME=K.firstConvergenceFrame;
    row.DSTR_KERNEL_FINAL_RESOLVED=double(K.finalAllResolved);
    row.DSTR_KERNEL_FINAL_COLLISION_FREE=double(K.finalCollisionFree);
    row.DSTR_KERNEL_FINAL_FRAME_AGREEMENT=double(K.finalFrameAgreement);
    row.DSTR_KERNEL_FINAL_DATA_SLOTS=K.finalDataSlots;
    row.DSTR_KERNEL_MAX_FRAME_DISAGREEMENT=K.maxFrameDisagreement;
    row.DSTR_KERNEL_FALSE_RESOLVED_NODE_FRAMES=K.falseResolvedNodeFrames;
    row.DSTR_KERNEL_RECOVERY_FRAME=K.recoveryFrame;
    row.DSTR_LAST_DATA_TIME=S.dstrLastConsumedDataTime;
    row.DSTR_LAST_CONTROL_TIME=S.dstrLastConsumedControlTime;
end

end
