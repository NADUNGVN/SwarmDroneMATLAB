function R=exp23yMigrationContinuousRegistry()
%EXP23YMIGRATIONCONTINUOUSREGISTRY Common-PHY migration validation matrix.

R=struct();
R.version='EXP23Y-MIGRATION-COMMON-PHY-v1';
R.frozenDate='2026-09-04';
R.stage='local-union-migration-common-phy-validation';
R.parentKernelRun='2026-09-04_232823';
R.parentKernelStatus='LOCAL_UNION_MIGRATION_KERNEL_VALID';
R.seeds=(16085001:16085050)';
R.swarmSizes=[5 10 20];
R.cases=struct( ...
    'id',{'zero-loss-valid','iid20-valid','iid40-valid', ...
        'revoke-blackout','response-blackout','incomplete-union'}, ...
    'kind',{'valid','valid','valid','revoke-blackout', ...
        'response-blackout','incomplete-union'}, ...
    'erasureProbability',{0,0.2,0.4,0.2,0.2,0.2});
R.clockArms=struct('id',{'zero-clock','affine-clock'}, ...
    'impaired',{false,true});
R.maxFrames=60; R.transitionFrame=8;
R.newGraphActivationFrame=9; R.eligibleFrame=12;
R.lockProofRepeatFrames=20; R.phyRateBps=250e3;
R.dataBytes=64; R.claimBytes=28; R.certificateHeaderBytes=16;
R.certificateEntryBytes=10; R.revokeBytes=24;
R.maxControlPacketBytes=96;
R.maxOffsetSec=0.25e-3; R.maxDriftPpm=40;
R.clockLeadTimeSec=0.01; R.clockResetHorizonSec=30;
B=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.clockResetHorizonSec);
R.safeGuardSec=B.safeGuardSec;
R.requiredValidationContracts=18;
R.freshSeedEvidence=false;
R.closedLoopClaimPermitted=false;
R.submissionClaimPermitted=false;
R.expectedRuns=numel(R.seeds)*numel(R.swarmSizes)* ...
    numel(R.cases)*numel(R.clockArms);

end
