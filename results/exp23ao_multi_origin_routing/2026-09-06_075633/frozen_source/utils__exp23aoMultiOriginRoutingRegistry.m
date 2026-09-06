function R=exp23aoMultiOriginRoutingRegistry()
%EXP23AOMULTIORIGINROUTINGREGISTRY Frozen bundle/retry diagnostic.

P=exp23aiIntegerAccountingRegistry();
R=struct();
R.version='EXP23AO-MULTI-ORIGIN-ROUTED-CONTROL-v1';
R.frozenDate='2026-09-06';
R.stage='multi-origin-routing-and-cross-layer-retry-development';
R.experimentName='exp23ao_multi_origin_routing';
R.planFile='docs/EXP23AO_MULTI_ORIGIN_ROUTING_PLAN.md';
R.registryFile='utils/exp23aoMultiOriginRoutingRegistry.m';
R.testFile='tests/test_exp23ao_multi_origin_routing_contracts.m';
R.entryFile='experiments/exp23ao_multi_origin_routing.m';
R.validStatus='MULTI_ORIGIN_ROUTED_CONTROL_DIAGNOSTIC_VALID';
R.invalidStatus='MULTI_ORIGIN_ROUTED_CONTROL_DIAGNOSTIC_INVALID';
R.parentRun='2026-09-06_072949';
R.parentStatus='FULL_DETECTABILITY_ROUTING_PRIMITIVE_DIAGNOSTIC_VALID';
R.parentGatesPassed=19; R.parentGatesTotal=19;
R.diagnosticWitnessSeed=P.diagnosticWitnessSeed;
R.bundles=struct('id',{'prepare','quiescent','evidence', ...
    'response','commit'},'kinds',{{'prepare'},{'quiescent'}, ...
    {'claim','lock-proof'},{'response'},{'commit'}});
R.expectedLogicalPackets=[1 3 10 10 1];
R.expectedRoutedPackets=[1 3 10 9 1];
R.uniformRepetitionGrid=(1:7)';
R.selectedUniformRepetitions=4;
R.linkErasureProbability=.2;
R.maximumTransactionFailure=1e-3;
R.postRequestTimeBudgetSec=P.missionSec-P.requestTimeSec;
R.prepareAttemptRange=(2:7)';
R.claimAttemptRange=(3:15)';
R.commitAttemptRange=(2:6)';
R.claimEligibilityDelayFrames=P.claimEligibilityDelayFrames;
R.selectedPrepareAttempts=3;
R.selectedClaimAttempts=4;
R.selectedEvidencePrefixAttempts=2;
R.selectedCommitAttempts=2;
R.selectedMaximumFrames=11;
R.phyRateBps=P.phyRateBps; R.safeGuardSec=P.safeGuardSec;
R.dataBytes=P.dataBytes; R.maxDataSlots=P.maxDataSlots;
R.maxControlPacketBytes=P.maxControlPacketBytes;
R.monteCarloTrials=5000;
R.monteCarloSeeds=(16094901:16094905)';
R.monteCarloStandardErrorMultiplier=5;
R.expectedBundleRows=numel(R.bundles);
R.expectedFrontierRows=numel(R.uniformRepetitionGrid);
R.expectedMonteCarloRows=numel(R.bundles);
R.requiredValidationContracts=16;
R.scheduleVersion='MULTI-ORIGIN-ROUTED-CONTROL-SCHEDULE-v1';
R.replayVersion='MULTI-ORIGIN-ROUTED-CONTROL-REPLAY-v1';
R.reliabilityVersion='MULTI-ORIGIN-ROUTED-RELIABILITY-v1';
R.transactionCertificateVersion= ...
    'RECEIVER-LIFTED-ROUTED-RELIABILITY-v1';
R.developmentOnly=true; R.confirmatoryEvidence=false;
R.multiOriginRoutingValidated=false;
R.managementRelayingValidated=false;
R.closedLoopManagementRelayingValidated=false;
R.repeatedOnlineRenewalValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
