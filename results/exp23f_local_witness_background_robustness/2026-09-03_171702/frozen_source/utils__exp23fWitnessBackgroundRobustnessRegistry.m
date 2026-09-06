function R=exp23fWitnessBackgroundRobustnessRegistry()
%EXP23FWITNESSBACKGROUNDROBUSTNESSREGISTRY Frozen occupancy/burst screen.

F=exp23dWitnessFrontierRegistry();
R.version='EXP23F-ELCS-W-BACKGROUND-OCCUPANCY-ROBUSTNESS-v1';
R.frozenDate='2026-09-03';
R.stage='local-witness-background-load-robustness-falsification';
R.policyOptimizationAllowed=false;
R.broadRobustnessClaimPermitted=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16067001:16067030)';
R.pilotSeed=16065901;
R.cells=F.cells;
R.parentIidRun='2026-09-03_164740';
R.parentIidDecision='ELCS_W_IID5_ROBUSTNESS_SCREEN_SURVIVES';
pOff=0.02;
R.conditions=struct( ...
    'id',{'clean','iid-load15','markov-load15','markov-load30'}, ...
    'label',{'Clean occupancy','IID occupancy 15%', ...
        'Markov occupancy 15% / 50 ms mean burst', ...
        'Markov occupancy 30% / 50 ms mean burst'}, ...
    'model',{'iid','iid','markov','markov'}, ...
    'targetLoad',{0,0.15,0.15,0.30}, ...
    'offToOn',{0,0,0.15*pOff/(1-0.15),0.30*pOff/(1-0.30)}, ...
    'onToOff',{0,0,pOff,pOff});
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
R.bootstrapSeedBase=16067900;
R.requiredIntegrityContracts=20;
R.expectedRuns=numel(R.seeds)*numel(R.cells)* ...
    numel(R.conditions)*numel(R.arms);

end
