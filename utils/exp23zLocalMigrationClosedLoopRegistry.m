function R=exp23zLocalMigrationClosedLoopRegistry()
%EXP23ZLOCALMIGRATIONCLOSEDLOOPREGISTRY Development integration matrix.

R=struct();
R.version='EXP23Z-LOCAL-MIGRATION-GRAPH-INPUT-CLOSED-LOOP-v1';
R.frozenDate='2026-09-05';
R.stage='local-migration-graph-input-closed-loop-development';
R.parentKernelRun='2026-09-04_232823';
R.parentCommonPhyRun='2026-09-04_233744';
R.parentKernelStatus='LOCAL_UNION_MIGRATION_KERNEL_VALID';
R.parentCommonPhyStatus='LOCAL_MIGRATION_COMMON_PHY_VALID';
R.seeds=(16086001:16086020)';
R.bootstrapReplicates=10000;
R.bootstrapSeedBase=16086900;
R.cell='n10-ring2-zero-loss';
R.eventTimeSec=6;
R.geometryHorizonSec=6;
R.interferenceRadius=0.585;
R.positionErrorBound=0.05;
R.velocityErrorBound=0.01;
R.transitionNode=10;
R.transitionVelocity=[0.05 0.10];
R.maxDataSlots=9;
R.eligibilityDelayFrames=3;
R.lockProofRepeatFrames=20;
R.claimBytes=28;
R.certificateHeaderBytes=16;
R.certificateEntryBytes=10;
R.revokeBytes=24;
R.maxControlPacketBytes=96;
R.maxOffsetSec=0.25e-3;
R.maxDriftPpm=40;
R.clockLeadTimeSec=0.00073003;
R.safeGuardSec=0.0015;
R.periodicRateHz=1/0.12;
R.arms=struct( ...
    'id',{'periodic-zero','migration-zero','periodic-iid20', ...
        'migration-iid20','migration-iid20-revoke-blackout', ...
        'migration-iid20-response-blackout'}, ...
    'kind',{'periodic','migration','periodic','migration', ...
        'migration','migration'}, ...
    'condition',{'zero','zero','iid20','iid20','iid20','iid20'}, ...
    'dataLoss',{0,0,.2,.2,.2,.2}, ...
    'controlLoss',{0,0,0,.2,.2,.2}, ...
    'revokeBlackout',{false,false,false,false,true,false}, ...
    'responseBlackout',{false,false,false,false,false,true});
R.requiredValidationContracts=16;
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.developmentOnly=true;
R.geometryCoupledToPlant=false;
R.freshSeedEvidence=false;
R.submissionClaimPermitted=false;

end
