function R=exp22gTargetedFrontierRegistry()
%EXP22GTARGETEDFRONTIERREGISTRY Frozen interpolation-closure matrix.

base=exp21dClosedLoopRegistry();
R.version='EXP22G-TARGETED-PERIODIC-FRONTIER-CLOSURE-v1';
R.frozenDate='2026-09-01';
R.stage='candidate-targeted-frontier-falsification';
R.policyOptimizationAllowed=false;
R.robustnessContinuationPermitted=false;
R.submissionClaimPermitted=false;
R.seeds=(16048001:16048030)';
R.cells=base.cells;
R.cells(1).parentElcsCost=0.350788266666666;
R.cells(2).parentElcsCost=0.376951466666665;
D=8*96/250e3;
for k=1:numel(R.cells)
    N=5;
    if contains(R.cells(k).id,'n10'), N=10; end
    R.cells(k).costMatchRateHz=R.cells(k).parentElcsCost/(N*D);
    R.cells(k).lowerCostRateHz=0.98*R.cells(k).costMatchRateHz;
end
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
    'id',{'periodic-cost-match','periodic-cost-minus2pct', ...
        'elcs-f-mission-affine'}, ...
    'label',{'Periodic static TDMA / ELCS cost match', ...
        'Periodic static TDMA / 2% below ELCS cost', ...
        'ELCS-F / mission affine clock'}, ...
    'family',{'periodic-static','periodic-static','candidate-elcs'}, ...
    'rateRule',{'cost-match','cost-minus2pct','candidate'});
R.elcsArm=R.arms(end).id;
R.lowerCostArm=R.arms(2).id;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
