function R=exp23aaEmergencyDataRegistry()
%EXP23AAEMERGENCYDATAREGISTRY Protected fallback development matrix.

R=struct();
R.version='EXP23AA-PROTECTED-EMERGENCY-DATA-DEVELOPMENT-v1';
R.frozenDate='2026-09-05';
R.stage='protected-emergency-data-development';
R.parentRun='2026-09-05_072640';
R.parentStatus='LOCAL_MIGRATION_GRAPH_INPUT_CLOSED_LOOP_INVALID';
R.parentPassedGates=15;
R.parentTotalGates=16;
R.seeds=(16087001:16087020)';
R.bootstrapReplicates=10000;
R.bootstrapSeedBase=16087900;
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
    'id',{'periodic-iid20','migration-iid20-no-emergency', ...
        'migration-iid20-emergency', ...
        'migration-iid20-emergency-revoke-blackout', ...
        'migration-iid20-emergency-response-blackout', ...
        'migration-iid20-no-emergency-response-blackout'}, ...
    'kind',{'periodic','migration','migration','migration', ...
        'migration','migration'}, ...
    'condition',{'iid20','iid20','iid20','iid20','iid20','iid20'}, ...
    'dataLoss',{.2,.2,.2,.2,.2,.2}, ...
    'controlLoss',{0,.2,.2,.2,.2,.2}, ...
    'revokeBlackout',{false,false,false,true,false,false}, ...
    'responseBlackout',{false,false,false,false,true,true}, ...
    'emergencyFallback',{false,false,true,true,true,false});
R.requiredValidationContracts=18;
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.developmentOnly=true;
R.geometryCoupledToPlant=false;
R.freshSeedEvidence=false;
R.submissionClaimPermitted=false;

end
