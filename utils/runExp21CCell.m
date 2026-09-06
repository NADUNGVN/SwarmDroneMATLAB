function [row,out]=runExp21CCell(cfg,method,label,meta,trace,details)
%RUNEXP21CCELL Execute and flatten one timing-integration trajectory.

[base,out]=runExp21ACell(cfg,method,label,meta,trace,details);
row=exp21cEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
S=out.serviceScheduler;
row.EXP21C_TRACE_HASH_EXACT=trace.exp21cHashExact;
row.CONTINUOUS_START_OPPORTUNITIES=S.continuousStartOpportunities;
row.CONTINUOUS_START_ATTEMPTS=S.continuousStartAttempts;
row.CONTINUOUS_GUARD_SEC=S.continuousGuardTime;
row.CONTINUOUS_SLOT_SEC=S.continuousSlotDuration;
row.CONTINUOUS_SYNC_SEC=S.continuousSyncPeriod;
row.CONTINUOUS_MAX_CLOCK_RESIDUAL= ...
    S.continuousMaxClockEquationResidual;
row.CONTINUOUS_MAX_OFFSET_BOUND_SEC=S.config.clockOffsetMaxSec;
row.CONTINUOUS_MAX_DRIFT_BOUND_PPM=S.config.clockDriftMaxPpm;
row.CONTINUOUS_REALIZED_MAX_DRIFT_PPM=max(abs(S.continuousClockDriftPpm));
row.CONTINUOUS_EXACT_AIRTIME=double(S.config.continuousExactAirtime);

end
