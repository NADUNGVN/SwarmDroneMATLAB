function R=exp23akRoutedAccountingRegistry()
%EXP23AKROUTEDACCOUNTINGREGISTRY Frozen exact routed-accounting repair.

P=exp23ajRoutedManagementRegistry();
R=struct();
R.version='EXP23AK-ROUTED-INTEGER-ACCOUNTING-v1';
R.frozenDate='2026-09-06';
R.stage='routed-management-integer-accounting-confirmation';
R.experimentName='exp23ak_routed_accounting_confirmation';
R.testScript='test_exp23ak_routed_accounting_contracts';
R.planFile='docs/EXP23AK_ROUTED_INTEGER_ACCOUNTING_PLAN.md';
R.registryFile='utils/exp23akRoutedAccountingRegistry.m';
R.testFile='tests/test_exp23ak_routed_accounting_contracts.m';
R.entryFile='experiments/exp23ak_routed_accounting_confirmation.m';
R.parentRun='2026-09-06_070738';
R.parentStatus='ROUTED_MANAGEMENT_PRIMITIVE_DIAGNOSTIC_INVALID';
R.parentGatesPassed=15; R.parentGatesTotal=17;
R.parentFailedGates={'integer_bytes_and_derived_airtime', ...
    'semantic_routes_reliable_and_accounted'};
R.parentRegistryVersion=P.version;
R.repairedSimulatorVersion='REPEATED-HOP-MANAGEMENT-FLOOD-REPLAY-v2';
R.swarmSizes=P.swarmSizes;
R.interferenceModes=P.interferenceModes;
R.linkErasureProbability=P.linkErasureProbability;
R.maximumLogicalPacketFailure=P.maximumLogicalPacketFailure;
R.maxRepetitionsPerHop=P.maxRepetitionsPerHop;
R.phyRateBps=P.phyRateBps; R.safeGuardSec=P.safeGuardSec;
R.maximumPacketBytes=P.maximumPacketBytes;
R.packetBytes=[24 28 32 40 48 56 72 96];
R.diagnosticWitnessSeed=P.diagnosticWitnessSeed;
R.semanticLinkErasureProbability=.2;
R.randomReplayRepetitionsPerHop=1;
R.randomReplayTrialsPerCell=2000;
R.randomReplaySeeds=(16094601:16094618)';
R.expectedStructuralRows=P.expectedStructuralRows;
R.expectedSemanticRows=P.expectedSemanticRows;
R.expectedRandomCells=numel(R.swarmSizes)* ...
    numel(R.interferenceModes)*numel(R.linkErasureProbability);
R.expectedRandomRows=R.expectedRandomCells*R.randomReplayTrialsPerCell;
R.requiredValidationContracts=10;
R.developmentOnly=true; R.confirmatoryEvidence=false;
R.managementRelayingValidated=false;
R.repeatedOnlineRenewalValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
