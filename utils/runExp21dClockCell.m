function [row,out]=runExp21dClockCell( ...
    cfg,method,label,meta,trace,details)
%RUNEXP21DCLOCKCELL Execute and flatten one affine-clock trajectory.

[base,out]=runExp21dClosedLoopCell( ...
    cfg,method,label,meta,trace,details);
row=exp21dClockEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
Q=out.serviceScheduler.config.dstrSchedule;
row.CLOCK_APPLIED=Q.clockApplied;
row.CLOCK_BASE_SCHEDULE_HASH_EXACT=Q.baseScheduleHashExact;
row.CLOCK_LOGICAL_OPPORTUNITY_HASH_EXACT= ...
    Q.logicalOpportunityHashExact;
row.CLOCK_MAX_OFFSET_BOUND_SEC=Q.clockMaxOffsetSec;
row.CLOCK_MAX_DRIFT_BOUND_PPM=Q.clockMaxDriftPpm;
row.CLOCK_REALIZED_MAX_OFFSET_SEC=max(abs(Q.clockOffsetSec));
row.CLOCK_REALIZED_MAX_DRIFT_PPM=max(abs(Q.clockDriftPpm));
row.CLOCK_LEAD_SEC=Q.clockLeadTimeSec;
row.CLOCK_SAFE_GUARD_SEC=Q.clockSafeGuardSec;
row.CLOCK_NOMINAL_CUTOFF_SEC=Q.clockNominalCutoffSec;
row.CLOCK_TIMING_CONFLICT_FREE=Q.clockTimingConflictFree;
row.CLOCK_MIN_INTERGROUP_GAP_SEC=Q.clockMinimumIntergroupGapSec;
row.CLOCK_MAX_INTRAGROUP_SKEW_SEC=Q.clockMaximumIntragroupSkewSec;
row.CLOCK_EQUATION_MAX_RESIDUAL_SEC= ...
    Q.clockEquationMaxResidualSec;

end
