function R=exp23afOnlineClosureRegistry()
%EXP23AFONLINECLOSUREREGISTRY Frozen online plant/tube development matrix.

R=struct();
R.version='EXP23AF-ONLINE-SWEPT-RECEIVER-CLOSURE-v1';
R.frozenDate='2026-09-05';
R.stage='online-causal-plant-tube-closure-development';
R.parentCommonPhyRun='2026-09-05_092152';
R.parentCommonPhyStatus='RECEIVER_LIFTED_CLOSURE_COMMON_PHY_VALID';
R.parentRetryRun='2026-09-05_075106';
R.parentRetryStatus='BOUNDED_RETRY_DEVELOPMENT_FEASIBLE';
R.smokeSeed=16094001;
R.seeds=(16094101:16094120)';
R.cell='n10-ring2-zero-loss'; R.N=10; R.formationScale=2;
R.missionSec=10.5; R.evalStartSec=5.5; R.requestTimeSec=6;
R.commandNode=2; R.commandTarget=[1.3 .1 0]; R.commandRampSec=2;
R.interferenceRadius=.97;
R.defaultPairTrackingRadius=.11;
R.leaderPairTrackingRadius=.21;
R.commandPairTrackingRadius=.18;
R.maxDataSlots=15; R.emergencySlots=(11:15)';
R.prepareDenseRetryFrames=4; R.prepareMaxBackoffFrames=4;
R.prepareRetryAttemptLimit=8; R.claimEligibilityDelayFrames=2;
R.lockProofRepeatFrames=12; R.claimBackoffEnabled=true;
R.claimDenseRetryFrames=6; R.claimMaxBackoffFrames=8;
R.claimRetryAttemptLimit=10; R.commitRetryAttemptLimit=6;
R.transactionVersion=3; R.phyRateBps=250e3;
R.dataBytes=96; R.controlLoss=.2; R.dataLoss=.2;
R.prepareHeaderBytes=32; R.affectedEntryBytes=4;
R.claimBytes=72; R.quietBytes=24; R.lockProofBytes=28;
R.certificateHeaderBytes=16; R.certificateEntryBytes=10;
R.commitBytes=28; R.revokeBytes=24; R.maxControlPacketBytes=96;
R.maxOffsetSec=.25e-3; R.maxDriftPpm=40;
R.clockLeadTimeSec=.01; R.clockResetHorizonSec=30;
B=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.clockResetHorizonSec);
R.safeGuardSec=B.safeGuardSec; R.periodicRateHz=1/.12;
R.arms=struct( ...
    'id',{'periodic-iid20','closure-iid20-emergency', ...
        'closure-response-blackout-emergency', ...
        'closure-response-blackout-no-emergency', ...
        'closure-prepare-blackout-emergency', ...
        'closure-commit-blackout-emergency'}, ...
    'kind',{'periodic','closure','closure','closure','closure','closure'}, ...
    'fault',{'none','none','response-blackout','response-blackout', ...
        'prepare-blackout','commit-blackout'}, ...
    'emergency',{false,true,true,false,true,true});
R.requiredValidationContracts=24;
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.developmentOnly=true; R.geometryCoupledToOnlinePlant=true;
R.managementRelayingValidated=false; R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false; R.submissionClaimPermitted=false;

end
