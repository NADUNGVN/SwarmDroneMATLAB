function R=exp23aeClosureCommonPhyRegistry()
%EXP23AECLOSURECOMMONPHYREGISTRY Frozen common-PHY closure matrix.

R=struct();
R.version='EXP23AE-RECEIVER-LIFTED-CLOSURE-COMMON-PHY-v1';
R.frozenDate='2026-09-05';
R.stage='receiver-lifted-closure-common-phy-validation';
R.parentKernelRun='2026-09-05_081510';
R.parentKernelStatus='RECEIVER_LIFTED_CLOSURE_KERNEL_VALID';
R.seeds=(16092001:16092050)';
R.swarmSizes=[5 10 20];
R.conditions={'nominal-zero','iid20','prepare-blackout', ...
    'quiescent-blackout','response-blackout','commit-blackout', ...
    'incomplete-union'};
R.clockArms=struct('id',{'zero-clock','affine-clock'}, ...
    'impaired',{false,true});

R.maxPhysicalChanges=4;
R.maxFrames=60; R.prepareFrame=5; R.transactionVersion=2;
R.prepareDenseRetryFrames=4; R.prepareMaxBackoffFrames=4;
R.prepareRetryAttemptLimit=8; R.claimEligibilityDelayFrames=2;
R.lockProofRepeatFrames=12; R.claimBackoffEnabled=true;
R.claimDenseRetryFrames=6; R.claimMaxBackoffFrames=8;
R.claimRetryAttemptLimit=10; R.commitRetryAttemptLimit=6;
R.phyRateBps=250e3; R.controlErasureProbability=.2;

R.dataBytes=96; R.maxDataSlotsFactor=1;
R.maxAffectedNodesFactor=1; R.prepareHeaderBytes=32;
R.affectedEntryBytes=4; R.claimBytes=72; R.quietBytes=24;
R.lockProofBytes=28; R.certificateHeaderBytes=16;
R.certificateEntryBytes=10; R.commitBytes=28; R.revokeBytes=24;
R.maxControlPacketBytes=96;

R.maxOffsetSec=.25e-3; R.maxDriftPpm=40;
R.clockLeadTimeSec=.01; R.clockResetHorizonSec=30;
B=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.clockResetHorizonSec);
R.safeGuardSec=B.safeGuardSec;
R.minAggregateIidCompletionWilsonLower=.95;
R.requiredValidationContracts=22;
R.expectedRuns=numel(R.seeds)*numel(R.swarmSizes)* ...
    numel(R.conditions)*numel(R.clockArms);
R.freshSeedEvidence=false;
R.closedLoopClaimPermitted=false;
R.onlinePlantCouplingPermitted=false;
R.submissionClaimPermitted=false;

end
