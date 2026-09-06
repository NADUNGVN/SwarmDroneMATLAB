function R=exp23arRoutedPlantClosedLoopRegistry()
%EXP23ARROUTEDPLANTCLOSEDLOOPREGISTRY Frozen routed plant development.

I=exp23aiIntegerAccountingRegistry(); A=exp23aqRoutedStateMachineConfirmationRegistry();
R=I;
R.version='EXP23AR-ROUTED-PLANT-CLOSED-LOOP-v1';
R.frozenDate='2026-09-06';
R.stage='routed-common-phy-data-plant-closed-loop-development';
R.experimentName='exp23ar_routed_plant_closed_loop';
R.planFile='docs/EXP23AR_ROUTED_PLANT_CLOSED_LOOP_PLAN.md';
R.registryFile='utils/exp23arRoutedPlantClosedLoopRegistry.m';
R.testFile='tests/test_exp23ar_routed_plant_closed_loop_contracts.m';
R.entryFile='experiments/exp23ar_routed_plant_closed_loop.m';
R.parentRoutedRun='2026-09-06_081945';
R.parentRoutedStatus=A.validStatus;
R.parentRoutedGatesPassed=19; R.parentRoutedGatesTotal=19;
R.smokeSeed=16096301;
R.seeds=(16096401:16096420)';
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.routeSeedOffset=4100000;
R.arms=struct( ...
    'id',{'periodic-iid20','routed-iid20-emergency', ...
        'routed-response-blackout-emergency', ...
        'routed-response-blackout-no-emergency', ...
        'routed-prepare-blackout-emergency', ...
        'routed-commit-blackout-emergency'}, ...
    'kind',{'periodic','routed','routed','routed','routed','routed'}, ...
    'fault',{'none','none','response-blackout','response-blackout', ...
        'prepare-blackout','commit-blackout'}, ...
    'emergency',{false,true,true,false,true,true});
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.repetitionsPerHop=A.repetitionsPerHop;
R.linkErasureProbability=A.linkErasureProbability;
R.prepareAttempts=A.prepareAttempts;
R.claimAttempts=A.claimAttempts;
R.evidencePrefixAttempts=A.evidencePrefixAttempts;
R.commitAttempts=A.commitAttempts;
R.transactionFrames=A.maxFrames;
R.transactionFailureUpperBound=A.transactionFailureUpperBound;
R.conservativeTransactionTimeSec=A.conservativeTransactionTimeSec;
R.postRequestTimeBudgetSec=A.postRequestTimeBudgetSec;
R.routedTraceVersion=A.traceVersion;
R.routedKernelVersion=A.kernelVersion;
R.routedContinuousVersion=A.continuousVersion;
R.missionEmbeddingVersion='RECEIVER-LIFTED-ROUTED-CLOSURE-MISSION-v1';
R.minimumEmpiricalNormalCompletionRate=.95;
R.requiredValidationContracts=27;
R.developmentOnly=true;
R.managementRelayingValidated=true;
R.closedLoopManagementRelayingValidated=false;
R.repeatedOnlineRenewalValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
