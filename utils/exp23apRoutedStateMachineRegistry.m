function R=exp23apRoutedStateMachineRegistry()
%EXP23APROUTEDSTATEMACHINEREGISTRY Frozen routed-kernel diagnostic.

P=exp23aoMultiOriginRoutingRegistry(); I=exp23aiIntegerAccountingRegistry();
R=struct();
R.version='EXP23AP-ROUTED-STATE-MACHINE-COMMON-PHY-v1';
R.frozenDate='2026-09-06';
R.stage='routed-management-state-machine-and-continuous-phy-development';
R.experimentName='exp23ap_routed_state_machine_common_phy';
R.planFile='docs/EXP23AP_ROUTED_STATE_MACHINE_COMMON_PHY_PLAN.md';
R.registryFile='utils/exp23apRoutedStateMachineRegistry.m';
R.testFile='tests/test_exp23ap_routed_state_machine_contracts.m';
R.testScript='test_exp23ap_routed_state_machine_contracts';
R.entryFile='experiments/exp23ap_routed_state_machine_common_phy.m';
R.validStatus='ROUTED_MANAGEMENT_STATE_MACHINE_DIAGNOSTIC_VALID';
R.invalidStatus='ROUTED_MANAGEMENT_STATE_MACHINE_DIAGNOSTIC_INVALID';
R.parentRun='2026-09-06_075633';
R.parentStatus=P.validStatus; R.parentGatesPassed=16; R.parentGatesTotal=16;
R.diagnosticWitnessSeed=P.diagnosticWitnessSeed;
R.repetitionsPerHop=P.selectedUniformRepetitions;
R.linkErasureProbability=P.linkErasureProbability;
R.prepareAttempts=P.selectedPrepareAttempts;
R.claimAttempts=P.selectedClaimAttempts;
R.evidencePrefixAttempts=P.selectedEvidencePrefixAttempts;
R.commitAttempts=P.selectedCommitAttempts;
R.maxFrames=P.selectedMaximumFrames;
R.transactionFailureUpperBound=0.00090955439743163613;
R.conservativeTransactionTimeSec=5.0346184407376295;
R.postRequestTimeBudgetSec=P.postRequestTimeBudgetSec;
R.phyRateBps=P.phyRateBps; R.safeGuardSec=P.safeGuardSec;
R.dataBytes=P.dataBytes; R.maxDataSlots=P.maxDataSlots;
R.safeClockMaxOffsetSec=I.maxOffsetSec;
R.safeClockMaxDriftPpm=I.maxDriftPpm;
R.clockLeadTimeSec=I.clockLeadTimeSec;
R.normalSeeds=(16095201:16095700)';
R.normalTrials=numel(R.normalSeeds);
R.monteCarloStandardErrorMultiplier=5;
R.faultSeed=16095701;
R.faults={'prepare-blackout','response-blackout','commit-blackout'};
R.expectedFaultRows=numel(R.faults);
R.expectedBundleEnvelopeRows=5;
R.requiredValidationContracts=18;
R.traceVersion='RECEIVER-LIFTED-ROUTED-CLOSURE-TRACE-v1';
R.kernelVersion='RECEIVER-LIFTED-ROUTED-CLOSURE-KERNEL-v1';
R.continuousVersion= ...
    'RECEIVER-LIFTED-ROUTED-CLOSURE-CONTINUOUS-v1';
R.developmentOnly=true; R.confirmatoryEvidence=false;
R.managementRelayingValidated=false;
R.closedLoopManagementRelayingValidated=false;
R.repeatedOnlineRenewalValidated=false; R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false; R.submissionClaimPermitted=false;

end
