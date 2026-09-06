function R=exp23dWitnessFrontierRegistry()
%EXP23DWITNESSFRONTIERREGISTRY Frozen ELCS-W periodic frontier test.

base=exp21dClosedLoopRegistry();
R.version='EXP23D-ELCS-W-SHARP-PERIODIC-FRONTIER-v1';
R.frozenDate='2026-09-03';
R.stage='local-witness-sharp-frontier-falsification';
R.policyOptimizationAllowed=false;
R.robustnessClaimPermitted=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16061001:16061030)';
R.pilotSeeds=(16059801:16059810)';
R.parentRun='2026-09-03_161908';
R.parentDecision='ELCS_W_CLOSED_LOOP_VALID';
R.cells=base.cells;
parentCost=[0.290453333333331 0.309759999999997];
boundaryFactor=[0.9875 0.9866];
D=8*96/250e3;
for k=1:numel(R.cells)
    N=5;
    if contains(R.cells(k).id,'n10'), N=10; end
    R.cells(k).parentElcsWCost=parentCost(k);
    R.cells(k).costMatchRateHz=parentCost(k)/(N*D);
    R.cells(k).boundaryFactor=boundaryFactor(k);
    R.cells(k).lowerCostRateHz= ...
        boundaryFactor(k)*R.cells(k).costMatchRateHz;
end
R.boundarySelectionRule=[ ...
    'largest retained pilot-tested rate factor whose measured finite-' ...
    'horizon airtime is at least 1% below the EXP23C parent mean; ' ...
    'selection uses cost only, never pilot RMSE'];
R.maxOffsetSec=0.25e-3;
R.maxDriftPpm=40;
R.clockHorizonSec=12;
B=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.clockHorizonSec);
R.clockLeadTimeSec=B.maxBoundaryErrorSec;
R.missionSafeGuardSec=B.safeGuardSec;
R.elcsMaxFrames=400;
R.strictMargin=0.01;
R.epsilonRmse=0.01;
R.requiredCostImprovement=0.01;
R.arms=struct( ...
    'id',{'periodic-cost-match','periodic-cost-minus1pct', ...
        'elcs-w-mission-affine'}, ...
    'label',{'Periodic static TDMA / ELCS-W cost match', ...
        'Periodic static TDMA / measured cost at least 1% lower', ...
        'ELCS-W local witness / mission affine clock'}, ...
    'family',{'periodic-static','periodic-static','candidate-elcs-w'}, ...
    'rateRule',{'cost-match','cost-minus1pct','candidate'});
R.elcsWArm=R.arms(end).id;
R.lowerCostArm=R.arms(2).id;
R.bootstrapSeedBase=16061900;
R.requiredIntegrityContracts=15;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
