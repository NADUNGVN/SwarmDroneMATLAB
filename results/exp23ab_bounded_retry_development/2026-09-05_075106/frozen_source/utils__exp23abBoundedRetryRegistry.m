function R=exp23abBoundedRetryRegistry()
%EXP23ABBOUNDEDRETRYREGISTRY Frozen bounded-retry development matrix.

R=struct();
R.version='EXP23AB-BOUNDED-RETRY-DEVELOPMENT-v1';
R.frozenDate='2026-09-05';
R.stage='bounded-retry-development';
R.parentRun='2026-09-05_073757';
R.parentStatus='PROTECTED_EMERGENCY_DATA_DEVELOPMENT_FEASIBLE';
R.parentPassedGates=19;
R.parentTotalGates=19;
R.seeds=(16088001:16088020)';
R.smokeSeed=16088999;
R.bootstrapReplicates=10000;
R.bootstrapSeedBase=16088900;
R.cell='n10-ring2-zero-loss';
R.eventTimeSec=6;
R.geometryHorizonSec=6;
R.interferenceRadius=0.585;
R.positionErrorBound=0.05;
R.velocityErrorBound=0.01;
R.transitionNode=10;
R.transitionVelocity=[0.05 0.10];
R.maxDataSlots=10;
R.emergencySlot=10;
R.eligibilityDelayFrames=3;
R.lockProofRepeatFrames=20;
R.claimDenseRetryFrames=6;
R.claimMaxBackoffFrames=8;
R.claimRetryAttemptLimit=10;
R.maxRetryUnionFailureProbability=1e-3;
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
ids={'periodic-iid20', ...
    'migration-dense-iid20-emergency', ...
    'migration-backoff-iid20-emergency', ...
    'migration-dense-iid20-emergency-response-blackout', ...
    'migration-backoff-iid20-emergency-response-blackout', ...
    'migration-backoff-iid20-emergency-revoke-blackout'};
R.arms=struct( ...
    'id',ids, ...
    'kind',{'periodic','migration','migration','migration','migration', ...
        'migration'}, ...
    'condition',{'iid20','iid20','iid20','iid20','iid20','iid20'}, ...
    'dataLoss',{.2,.2,.2,.2,.2,.2}, ...
    'controlLoss',{0,.2,.2,.2,.2,.2}, ...
    'revokeBlackout',{false,false,false,false,false,true}, ...
    'responseBlackout',{false,false,false,true,true,false}, ...
    'emergencyFallback',{false,true,true,true,true,true}, ...
    'claimBackoffEnabled',{false,false,true,false,true,true}, ...
    'claimDenseRetryFrames',{0,0,6,0,6,6}, ...
    'claimMaxBackoffFrames',{0,0,8,0,8,8}, ...
    'claimRetryAttemptLimit',{0,0,10,0,10,10});
R.requiredValidationContracts=24;
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.developmentOnly=true;
R.geometryCoupledToPlant=false;
R.freshSeedEvidence=false;
R.submissionClaimPermitted=false;

end
