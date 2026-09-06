function R=exp21bTimingRegistry()
%EXP21BTIMINGREGISTRY Frozen continuous-time MAC validity matrix.

R.version='EXP21B-CONTINUOUS-TIME-MAC-VALIDITY-v1';
R.frozenDate='2026-09-01';
R.stage='model-validity';
R.policyOptimizationAllowed=false;
R.formationPerformanceClaimPermitted=false;
R.seeds=(16031001:16031100)';
R.N=[5 10];
R.maxOffsetSec=0.25e-3;
R.maxDriftPpm=40;
R.dataBytes=96;
R.phyRateBps=250e3;
R.dataAirtimeSec=8*R.dataBytes/R.phyRateBps;
R.horizonSec=12;
R.syncPeriodsSec=[0.5 inf];
R.guardFactors=[0 0.75 1.0 1.25];
R.expectedRuns=numel(R.seeds)*numel(R.N)* ...
    numel(R.syncPeriodsSec)*numel(R.guardFactors);
R.clockSeedOffset=21092026;
R.tolerance=1e-11;

end
