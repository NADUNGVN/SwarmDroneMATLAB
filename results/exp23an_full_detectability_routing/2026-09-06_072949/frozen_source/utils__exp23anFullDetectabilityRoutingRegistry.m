function R=exp23anFullDetectabilityRoutingRegistry()
%EXP23ANFULLDETECTABILITYROUTINGREGISTRY Fresh detectability repair.

P=exp23ajRoutedManagementRegistry();
R=P;
R.version='EXP23AN-FULL-DETECTABILITY-ROUTING-v1';
R.frozenDate='2026-09-06';
R.stage='full-direct-reach-detectability-routing-confirmation';
R.experimentName='exp23an_full_detectability_routing';
R.testScript='test_exp23an_full_detectability_routing_contracts';
R.planFile='docs/EXP23AN_FULL_DETECTABILITY_ROUTING_PLAN.md';
R.registryFile='utils/exp23anFullDetectabilityRoutingRegistry.m';
R.testFile='tests/test_exp23an_full_detectability_routing_contracts.m';
R.entryFile='experiments/exp23an_full_detectability_routing.m';
R.validStatus='FULL_DETECTABILITY_ROUTING_PRIMITIVE_DIAGNOSTIC_VALID';
R.invalidStatus='FULL_DETECTABILITY_ROUTING_PRIMITIVE_DIAGNOSTIC_INVALID';
R.detectabilityRepair=true;
R.repairedSimulatorVersion='REPEATED-HOP-MANAGEMENT-FLOOD-REPLAY-v3';
R.supersededPrimitiveRun='2026-09-06_071938';
R.supersededPrimitiveStatus= ...
    'INTEGER_ACCOUNTED_ROUTING_PRIMITIVE_DIAGNOSTIC_VALID';
R.expectedDetectabilityAuditRows=94;
R.expectedLegacyInvalidStructuralRoutes=30;
R.expectedLegacyInvalidSemanticRoutes=5;
R.monteCarloSeeds=(16094801:16094806)';
R.requiredValidationContracts=19;
R.managementRelayingValidated=false;
R.repeatedOnlineRenewalValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
