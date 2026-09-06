function R=exp23iCumulativeClosedLoopRegistry()
%EXP23ICUMULATIVECLOSEDLOOPREGISTRY Frozen targeted closed-loop repair test.

F=exp23fWitnessBackgroundRobustnessRegistry();
R.version='EXP23I-ELCS-W-CUMULATIVE-CLOSED-LOOP-TARGET-v1';
R.frozenDate='2026-09-04';
R.stage='cumulative-receipt-targeted-closed-loop-falsification';
R.policyOptimizationAllowed=false;
R.broadRobustnessClaimPermitted=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16072001:16072060)';
R.parentNegativeRun='2026-09-04_154603';
R.parentNegativeDecision= ...
    'ELCS_W_BACKGROUND_EPSILON_DOMINATED_RETURN_TO_DESIGN';
R.parentKernelRun='2026-09-04_161234';
R.parentKernelDecision='ELCS_W_CUMULATIVE_KERNEL_VALID';
R.cells=F.cells(contains({F.cells.id},'n5'));
R.conditions=F.conditions(strcmp({F.conditions.id},'iid-load15'));
R.arms=struct( ...
    'id',{'periodic-exp23d-lower','elcs-w-legacy', ...
        'elcs-w-cumulative'}, ...
    'label',{'Periodic static TDMA / EXP23D lower-cost boundary', ...
        'ELCS-W legacy same-frame/new-sequence retry', ...
        'ELCS-W cumulative same-sequence receipt retry'}, ...
    'family',{'periodic-static','candidate-elcs-w', ...
        'candidate-elcs-w'}, ...
    'cumulativeReceiptRetry',{false,false,true});
R.periodicArm=R.arms(1).id;
R.legacyArm=R.arms(2).id;
R.cumulativeArm=R.arms(3).id;
R.maxOffsetSec=F.maxOffsetSec;
R.maxDriftPpm=F.maxDriftPpm;
R.clockHorizonSec=F.clockHorizonSec;
R.clockLeadTimeSec=F.clockLeadTimeSec;
R.missionSafeGuardSec=F.missionSafeGuardSec;
R.elcsMaxFrames=F.elcsMaxFrames;
R.epsilonRmse=F.epsilonRmse;
R.requiredCostImprovement=F.requiredCostImprovement;
R.requiredManagementReduction=0.15;
R.bootstrapReplicates=10000;
R.bootstrapSeedBase=16072900;
R.realizedFractionPairTolerance=1e-12;
R.requiredIntegrityContracts=18;
R.expectedRuns=numel(R.seeds)*numel(R.cells)* ...
    numel(R.conditions)*numel(R.arms);

end
