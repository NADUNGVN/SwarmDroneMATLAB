function R=exp21dClosedLoopRegistry()
%EXP21DCLOSEDLOOPREGISTRY Frozen D-STR closed-loop integration matrix.

R.version='EXP21D-CLOSED-LOOP-INTEGRATION-v3';
R.frozenDate='2026-09-01';
R.stage='prior-art-integration-falsification';
R.policyOptimizationAllowed=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.boundaryContinuationPermitted=false;
R.seeds=(16036201:16036230)';
R.cells=struct( ...
    'id',{'n5-6dof-zero-loss','n10-ring2-zero-loss'}, ...
    'label',{'N5 6-DOF zero-loss','N10 ring2 zero-loss'}, ...
    'exp21cCell',{'n5-stressed','n10-moderate'});
R.arms=struct( ...
    'id',{'periodic-static-tdma-p8p333','dstr-native','dstr-oracle-warm'}, ...
    'label',{'Periodic static TDMA 8.333 Hz', ...
        'D-STR native acquisition','D-STR oracle-warm'}, ...
    'kind',{'ideal-service-reference','prior-art-native', ...
        'oracle-cost-decomposition'}, ...
    'schedulerMode',{'continuous-local-static-tdma', ...
        'continuous-dstr-replay','continuous-dstr-replay'}, ...
    'periodicRateHz',{1/0.12,50,50}, ...
    'idealFlag',{1,0,1});
R.periodicArm='periodic-static-tdma-p8p333';
R.nativeArm='dstr-native';
R.warmArm='dstr-oracle-warm';
R.warmAssignment='deterministic-centralized-greedy-conflict-coloring';
R.maxFrames=1200;
R.initialDataSlots=10;
R.maxDataSlots=64;
R.collisionThreshold=3;
R.growthMargin=3;
R.shrinkThreshold=5;
R.failedShrinkTimeout=30;
R.shrinkBackoffExponentCap=6;
R.retentionProbability=0.75;
R.traceSeedOffset=21092026;
B=continuousTdmaGuardBound(0.25e-3,40,0.5);
R.safeGuardSec=B.safeGuardSec;
R.requiredIntegrationContracts=14;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
