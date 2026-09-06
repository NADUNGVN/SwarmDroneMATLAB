function [row,out]=runExp21ACell(cfg,method,label,meta,trace,details)
%RUNEXP21ACELL Execute and flatten one EXP21A trajectory.

[base,out]=runExp14Cell(cfg,method,label,meta,trace);
row=exp21aEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
row.originalMacType=cfg.exp20a.originalMacType;
row.armKind=details.kind;
row.route=details.route;
row.accessDesign=details.accessDesign;
row.ackDesign=details.ackDesign;
row.schedulerMode=details.schedulerMode;
row.PERIODIC_RATE_HZ=details.periodicRateHz;
row.DISTRIBUTED_FLAG=details.distributedFlag;
row.IDEAL_FLAG=details.idealFlag;
row.cellRole=cfg.exp21a.role;
row.controlReach=cfg.exp21a.controlReachName;
row.EXP21_TRACE_HASH_EXACT=trace.exp21HashExact;

S=out.serviceScheduler;
row.SERVICE_DECISIONS=S.decisionCount;
row.RECEIVER_TRUTH_READS=S.receiverTruthReadCount;
row.FUTURE_RANDOM_READS=S.futureRandomReadCount;
row.MECHANISM_ACTIVATIONS=S.mechanismActivationCount;
row.SERVICE_DECISION_LOG_VALID=double( ...
    numel(out.netLogs.serviceDecisions)==S.decisionCount);
row.ZMAC_OWNER_ATTEMPTS=S.zmacOwnerAttemptCount;
row.ZMAC_CONTENTION_ATTEMPTS=S.zmacContentionAttemptCount;
row.RESERVATION_EPOCHS=S.reservationEpochCount;
row.CONTROL_FRAMES=S.reservationControlFrames;
row.CONTROL_REQUEST_FRAMES=S.reservationRequestFrames;
row.CONTROL_RESPONSE_FRAMES=S.reservationResponseFrames;
row.CONTROL_COMMIT_FRAMES=S.reservationCommitFrames;
row.CONTROL_RECIPIENT_ATTEMPTS= ...
    S.reservationControlRecipientAttempts;
row.CONTROL_RECIPIENT_SUCCESS= ...
    S.reservationControlRecipientSuccess;
row.CONTROL_RECIPIENT_LOSS=S.reservationControlRecipientLoss;
row.CONTROL_ACCOUNTING_CLOSE=double( ...
    row.CONTROL_RECIPIENT_SUCCESS+row.CONTROL_RECIPIENT_LOSS== ...
    row.CONTROL_RECIPIENT_ATTEMPTS);
row.CONTROL_AIRTIME=S.reservationControlAirtime;
row.CONTROL_OVERHEAD_FRACTION=row.CONTROL_AIRTIME/ ...
    max(cfg.swarm.T,eps);
row.PUBLIC_FEEDBACK_COUNT=S.publicFeedbackCount;
row.PUBLIC_FEEDBACK_AIRTIME=S.publicFeedbackAirtime;
row.CHARGED_OFFERED_UTIL=row.OFFERED_UTIL+ ...
    row.PUBLIC_FEEDBACK_AIRTIME/max(cfg.swarm.T,eps)+ ...
    row.CONTROL_OVERHEAD_FRACTION;
row.RESERVATION_NACKS=S.reservationNackCount;
row.RESERVATION_MIGRATIONS=S.reservationMigrationCount;
row.RESERVATION_SCHEDULE_CHANGES=S.reservationScheduleChanges;
row.SCHEDULE_CONFLICT_FRACTION=S.reservationConflictSamples/ ...
    max(S.reservationScheduleSamples,1);
row.FIRST_CONVERGENCE_SEC=S.reservationFirstConvergenceTime;
row.CONVERGED_BY_2SEC=double(isfinite(row.FIRST_CONVERGENCE_SEC) && ...
    row.FIRST_CONVERGENCE_SEC<=2+1e-12);
row.CHURN_APPLIED=double(S.reservationChurnApplied);
row.CHURN_RECOVERY_SEC=S.reservationRecoveryTime;
if cfg.exp21a.churnEnabled
    row.RECOVERED_BY_2SEC=double(isfinite(row.CHURN_RECOVERY_SEC) && ...
        row.CHURN_RECOVERY_SEC<=2+1e-12);
end
assigned=S.reservationAssignedSlot(any(out.topology,1)');
row.FINAL_ASSIGNED_NODES=nnz(assigned>0);
row.FINAL_FULL_UNIQUE=double(~isempty(assigned) && all(assigned>0) && ...
    numel(unique(assigned))==numel(assigned));
row.MAX_ABS_CLOCK_OFFSET_SEC=max(abs(S.reservationClockOffsetSec));
row.MAX_ABS_CLOCK_DRIFT_PPM=max(abs(S.reservationClockDriftPpm));
row.LOCAL_SCHEDULE_ONLY=double(S.receiverTruthReadCount==0 && ...
    S.futureRandomReadCount==0);

active=any(out.topology,1)';
nodeGoodput=out.netStats.perNodeDataFramesDeliveredAny(active)/ ...
    max(cfg.swarm.T,eps);
row.MEAN_NODE_GOODPUT_HZ=mean(nodeGoodput);
row.MIN_NODE_GOODPUT_HZ=min(nodeGoodput);
row.ENDOGENOUS_COLLISION_FRAMES=max(0, ...
    row.COLLISION_FRAMES-row.BACKGROUND_COLLISION_FRAMES);

end
