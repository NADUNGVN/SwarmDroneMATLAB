% TEST_EXP23D_WITNESS_FRONTIER_CONTRACTS Frozen registry checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23d_witness_frontier_contracts\n');
fprintf('============================================================\n\n');

checks=0;
R=exp23dWitnessFrontierRegistry();
assert(numel(R.seeds)==30 && numel(R.cells)==2 && ...
    numel(R.arms)==3 && R.expectedRuns==180);
assert(isempty(intersect(R.seeds,R.pilotSeeds)));
assert(strcmp(R.parentDecision,'ELCS_W_CLOSED_LOOP_VALID'));
fprintf('    ok   registry freezes 180 fresh rows disjoint from calibration\n');
checks=checks+1;

D=8*96/250e3;
for k=1:numel(R.cells)
    N=5;
    if contains(R.cells(k).id,'n10'), N=10; end
    assert(abs(R.cells(k).costMatchRateHz- ...
        R.cells(k).parentElcsWCost/(N*D))<1e-12);
    assert(R.cells(k).lowerCostRateHz<R.cells(k).costMatchRateHz);
end
assert(R.cells(1).boundaryFactor==0.9875 && ...
    R.cells(2).boundaryFactor==0.9866);
fprintf('    ok   parent-cost rates and finite-horizon boundary factors close\n');
checks=checks+1;

assert(R.requiredCostImprovement==0.01 && R.epsilonRmse==0.01 && ...
    R.strictMargin==0.01);
assert(~R.policyOptimizationAllowed && ~R.robustnessClaimPermitted && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted);
fprintf('    ok   dominance margins and non-promotion scope are frozen\n');
checks=checks+1;

fprintf('\ntest_exp23d_witness_frontier_contracts: PASS (%d checks)\n',checks);
