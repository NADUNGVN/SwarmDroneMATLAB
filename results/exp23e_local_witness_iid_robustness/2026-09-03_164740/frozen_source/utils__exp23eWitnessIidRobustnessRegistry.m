function R=exp23eWitnessIidRobustnessRegistry()
%EXP23EWITNESSIIDROBUSTNESSREGISTRY Frozen 5% IID loss screen.

F=exp23dWitnessFrontierRegistry();
R.version='EXP23E-ELCS-W-IID-LOSS-ROBUSTNESS-v1';
R.frozenDate='2026-09-03';
R.stage='local-witness-iid-loss-robustness-falsification';
R.policyOptimizationAllowed=false;
R.robustnessClaimPermitted=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16063001:16063030)';
R.cells=F.cells;
R.parentFrontierRun='2026-09-03_163244';
R.parentFrontierDecision='ELCS_W_SHARP_PERIODIC_FRONTIER_SURVIVES';
R.conditions=struct( ...
    'id',{'clean','claim-iid5','response-iid5','data-iid5','joint-iid5'}, ...
    'label',{'Clean','CLAIM IID loss 5%','RESPONSE IID loss 5%', ...
        'DATA IID loss 5%','CLAIM/RESPONSE/DATA IID loss 5%'}, ...
    'claimLoss',{0,0.05,0,0,0.05}, ...
    'responseLoss',{0,0,0.05,0,0.05}, ...
    'dataLoss',{0,0,0,0.05,0.05});
R.arms=struct( ...
    'id',{'periodic-exp23d-lower','elcs-w-affine'}, ...
    'label',{'Periodic static TDMA / EXP23D lower-cost boundary', ...
        'ELCS-W local witness / affine clock'}, ...
    'family',{'periodic-static','candidate-elcs-w'});
R.periodicArm=R.arms(1).id;
R.elcsWArm=R.arms(2).id;
R.maxOffsetSec=F.maxOffsetSec;
R.maxDriftPpm=F.maxDriftPpm;
R.clockHorizonSec=F.clockHorizonSec;
R.clockLeadTimeSec=F.clockLeadTimeSec;
R.missionSafeGuardSec=F.missionSafeGuardSec;
R.elcsMaxFrames=F.elcsMaxFrames;
R.epsilonRmse=0.01;
R.requiredCostImprovement=0.01;
R.bootstrapSeedBase=16063900;
R.requiredIntegrityContracts=19;
R.expectedRuns=numel(R.seeds)*numel(R.cells)* ...
    numel(R.conditions)*numel(R.arms);

end
