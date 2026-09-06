function R=exp23ahPhaseReservedClosureRegistry()
%EXP23AHPHASERESERVEDCLOSUREREGISTRY Frozen reliable radial closure matrix.

R=exp23agRadialClosureRegistry();
R.version='EXP23AH-PHASE-RESERVED-RADIAL-CLOSURE-v1';
R.frozenDate='2026-09-05';
R.stage='phase-reserved-transaction-reliability-development';
R.parentFreshRadialRun='2026-09-05_142942';
R.parentFreshRadialStatus='ONLINE_RADIAL_RECEIVER_CLOSURE_FRESH_INVALID';
R.parentFreshRadialGatesPassed=22;
R.parentFreshRadialGatesTotal=25;
R.radialValidationSeeds=(16094201:16094250)';
R.parentPhaseDiagnosticRun='2026-09-06_000317';
R.parentPhaseDiagnosticStatus='PHASE_RESERVED_FIXTURE_SUPPORTED';
R.seeds=(16094301:16094350)';
R.requestTimeSec=4; R.evalStartSec=3.5; R.missionSec=10.5;
R.prepareDenseRetryFrames=7;
R.prepareRetryAttemptLimit=7;
R.lockProofRepeatFrames=15;
R.claimDenseRetryFrames=15;
R.claimRetryAttemptLimit=15;
R.commitRetryAttemptLimit=6;
R.evidencePrefixClaimAttempts=8;
R.leaderPairTrackingRadius=.23;
R.closureKernelVersion='RECEIVER-LIFTED-CLOSURE-KERNEL-v2';
R.persistentQuietAdvertising=true;
R.maxTransactionFailureProbability=1e-3;
R.minimumEmpiricalNormalCompletionRate=.95;
R.requiredValidationContracts=27;
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.registeredFreshRadialSeeds=false;
R.registeredPhaseReservedSeeds=true;
R.freshPhaseReservedEvidence=false;
R.freshRadialContractEvidence=true;
R.repeatedOnlineRenewalValidated=false;
R.managementRelayingValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
