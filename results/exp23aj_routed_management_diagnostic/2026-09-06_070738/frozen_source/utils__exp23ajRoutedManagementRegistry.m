function R=exp23ajRoutedManagementRegistry()
%EXP23AJROUTEDMANAGEMENTREGISTRY Frozen multi-hop routing diagnostic.

P=exp23aiIntegerAccountingRegistry();
R=struct();
R.version='EXP23AJ-ROUTED-MANAGEMENT-DIAGNOSTIC-v1';
R.frozenDate='2026-09-06';
R.stage='routed-management-development-diagnostic';
R.parentRun='2026-09-06_003132';
R.parentStatus='INTEGER_ACCOUNTED_RADIAL_CLOSURE_FRESH_VALID';
R.parentGatesPassed=28; R.parentGatesTotal=28;
R.parentRegistryVersion=P.version;
R.diagnosticWitnessSeed=P.diagnosticWitnessSeed;
R.swarmSizes=[5 10 20];
R.topology='ring2-with-symmetric-leader-pins';
R.interferenceModes={'spatial-reuse-lower-bound', ...
    'complete-interference-upper-bound'};
R.linkErasureProbability=[.05 .2 .3];
R.maximumLogicalPacketFailure=1e-3;
R.maxRepetitionsPerHop=20;
R.maxHopsFactor=1;
R.phyRateBps=P.phyRateBps;
R.safeGuardSec=P.safeGuardSec;
R.maximumPacketBytes=P.maxControlPacketBytes;
R.monteCarloLoss=.2;
R.monteCarloRepetitionsPerHop=2;
R.monteCarloTrials=10000;
R.monteCarloSeeds=(16094501:16094506)';
R.monteCarloStandardErrorMultiplier=5;
R.requiredValidationContracts=17;
R.expectedStructuralRows=sum(R.swarmSizes)* ...
    numel(R.interferenceModes)*numel(R.linkErasureProbability);
R.expectedMonteCarloRows=numel(R.swarmSizes)* ...
    numel(R.interferenceModes);
R.expectedSemanticRows=25;
R.developmentOnly=true;
R.confirmatoryEvidence=false;
R.managementRelayingValidated=false;
R.repeatedOnlineRenewalValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
