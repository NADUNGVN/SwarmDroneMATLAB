function R=exp23adClosureKernelRegistry()
%EXP23ADCLOSUREKERNELREGISTRY Frozen receiver-lift closure kernel matrix.

R=struct();
R.version='EXP23AD-RECEIVER-LIFTED-CLOSURE-KERNEL-v1';
R.frozenDate='2026-09-05';
R.stage='receiver-lifted-closure-kernel-falsification';
R.parentRun='2026-09-05_080210';
R.parentStatus='ONE_SENDER_LOCALITY_REJECTED_BY_RECEIVER_LIFT';
R.nodeCounts=[5 10 20];
R.seeds=(16091001:16091100)';
R.conditions={'nominal-zero','iid20','prepare-blackout', ...
    'quiescent-blackout','response-blackout','commit-blackout', ...
    'revoke-blackout','incomplete-union'};
R.maxPhysicalChanges=4;
R.maxFrames=60;
R.prepareFrame=5;
R.transactionVersion=2;
R.prepareDenseRetryFrames=4;
R.prepareMaxBackoffFrames=4;
R.prepareRetryAttemptLimit=8;
R.claimEligibilityDelayFrames=2;
R.lockProofRepeatFrames=12;
R.claimBackoffEnabled=true;
R.claimDenseRetryFrames=6;
R.claimMaxBackoffFrames=8;
R.claimRetryAttemptLimit=10;
R.commitRetryAttemptLimit=6;
R.phyRateBps=250e3;
R.controlErasureProbability=.2;
R.maxDataSlotsFactor=1;
R.maxAffectedNodesFactor=1;
R.prepareHeaderBytes=32;
R.affectedEntryBytes=4;
R.claimBytes=72;
R.quietBytes=24;
R.lockProofBytes=28;
R.certificateHeaderBytes=16;
R.certificateEntryBytes=10;
R.commitBytes=28;
R.revokeBytes=24;
R.maxControlPacketBytes=96;
R.minAggregateIidCompletionWilsonLower=.95;
R.requiredValidationContracts=24;
R.expectedRuns=numel(R.nodeCounts)*numel(R.seeds)*numel(R.conditions);
R.developmentOnly=true;
R.closedLoopClaimPermitted=false;
R.submissionClaimPermitted=false;

end
