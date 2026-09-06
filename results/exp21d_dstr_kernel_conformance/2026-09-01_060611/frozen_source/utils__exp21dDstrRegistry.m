function R=exp21dDstrRegistry()
%EXP21DDSTRREGISTRY Frozen prior-art kernel conformance matrix.

R.version='EXP21D-DSTR-KERNEL-CONFORMANCE-v2';
R.frozenDate='2026-09-01';
R.stage='prior-art-kernel-conformance';
R.policyOptimizationAllowed=false;
R.closedLoopClaimPermitted=false;
R.submissionClaimPermitted=false;
R.primarySource='arXiv:2511.12888v1';
R.reproductionKind='rule-mapped-no-author-code';
R.logicalSlotAlignment=true;
R.continuousClockClaimPermitted=false;
R.seeds=(16034001:16034100)';
R.N=[5 10];
R.conditions=struct( ...
    'id',{'native','beacon-loss','restricted-management','churn-rejoin'}, ...
    'label',{'Native hex safety graph','Beacon loss 0.05', ...
        'Local-only management','State-loss and rejoin'}, ...
    'scope',{'source-native','boundary','boundary','boundary'});
R.maxFrames=200;
R.initialDataSlots=10;
R.maxDataSlots=64;
R.collisionThreshold=3;
R.growthMargin=3;
R.shrinkThreshold=5;
R.failedShrinkTimeout=10;
R.shrinkBackoffExponentCap=6;
R.retentionProbability=0.75;
R.frameBytes=512;
R.phyRateBps=1e6;
R.guardSec=0.540022e-3;
R.beaconLossProbability=0.05;
R.managementLossProbability=0;
R.churnFrame=60;
R.churnNode=2;
R.traceSeedOffset=21092026;
R.formationSpacingM=10;
R.safetyRadiusM=10;
R.dataPhysicalLayer='binary-neighborhood-conflict-abstraction';
R.expectedRuns=numel(R.seeds)*numel(R.N)*numel(R.conditions);
R.requiredContractChecks=15;

end
