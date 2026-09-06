function R=exp23amSemanticSentinelRegistry()
%EXP23AMSEMANTICSENTINELREGISTRY Frozen local-only sentinel repair.

P=exp23alRoutedAccountingRegistry();
R=struct();
R.version='EXP23AM-SEMANTIC-LOCAL-SENTINEL-v1';
R.frozenDate='2026-09-06';
R.stage='routed-management-semantic-sentinel-confirmation';
R.parentRun='2026-09-06_071620';
R.parentStatus='INTEGER_ACCOUNTED_ROUTING_PRIMITIVE_DIAGNOSTIC_INVALID';
R.parentGatesPassed=9; R.parentGatesTotal=10;
R.parentFailedGate='semantic_routes_reproduced_and_accounted';
R.scientificParentRun=P.parentRun;
R.scientificParentStatus=P.parentStatus;
R.diagnosticWitnessSeed=P.diagnosticWitnessSeed;
R.semanticLinkErasureProbability=P.semanticLinkErasureProbability;
R.maximumLogicalPacketFailure=P.maximumLogicalPacketFailure;
R.maxRepetitionsPerHop=P.maxRepetitionsPerHop;
R.phyRateBps=P.phyRateBps; R.safeGuardSec=P.safeGuardSec;
R.repairedSimulatorVersion=P.repairedSimulatorVersion;
R.undefinedRouteHashSentinel='NaN';
R.expectedSemanticRows=P.expectedSemanticRows;
R.expectedLocalOnlyRows=1;
R.requiredValidationContracts=7;
R.developmentOnly=true; R.confirmatoryEvidence=false;
R.managementRelayingValidated=false;
R.repeatedOnlineRenewalValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
