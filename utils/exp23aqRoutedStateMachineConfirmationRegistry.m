function R=exp23aqRoutedStateMachineConfirmationRegistry()
%EXP23AQROUTEDSTATEMACHINECONFIRMATIONREGISTRY Fresh gate confirmation.

R=exp23apRoutedStateMachineRegistry();
R.version='EXP23AQ-ROUTED-STATE-MACHINE-CONFIRMATION-v1';
R.frozenDate='2026-09-06';
R.stage='routed-management-state-machine-fresh-gate-confirmation';
R.experimentName='exp23aq_routed_state_machine_confirmation';
R.planFile='docs/EXP23AQ_ROUTED_STATE_MACHINE_CONFIRMATION_PLAN.md';
R.registryFile='utils/exp23aqRoutedStateMachineConfirmationRegistry.m';
R.testFile='tests/test_exp23aq_routed_state_machine_confirmation_contracts.m';
R.testScript='test_exp23aq_routed_state_machine_confirmation_contracts';
R.entryFile='experiments/exp23aq_routed_state_machine_confirmation.m';
R.validStatus='ROUTED_MANAGEMENT_STATE_MACHINE_CONFIRMATION_VALID';
R.invalidStatus='ROUTED_MANAGEMENT_STATE_MACHINE_CONFIRMATION_INVALID';
R.supersededRun='2026-09-06_081712';
R.supersededStatus='SUPERSEDED_BY_CONTINUOUS_VERSION_IDENTITY_AUDIT';
R.supersededReasonCode='CONTINUOUS_VERSION_HASH_NOT_ASSERTED';
R.normalSeeds=(16095702:16096201)';
R.normalTrials=numel(R.normalSeeds); R.faultSeed=16096202;
R.requiredValidationContracts=19;

end
