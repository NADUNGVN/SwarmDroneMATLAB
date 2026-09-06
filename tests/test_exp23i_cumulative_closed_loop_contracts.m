% TEST_EXP23I_CUMULATIVE_CLOSED_LOOP_CONTRACTS Frozen target checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23i_cumulative_closed_loop_contracts\n');
fprintf('============================================================\n\n');

checks=0;
R=exp23iCumulativeClosedLoopRegistry();
G=exp23gWitnessBackgroundGateRepairRegistry();
H=exp23hCumulativeReceiptRegistry();
assert(numel(R.seeds)==60 && numel(R.cells)==1 && ...
    numel(R.conditions)==1 && numel(R.arms)==3 && ...
    R.expectedRuns==180);
assert(isempty(intersect(R.seeds,G.seeds)) && ...
    isempty(intersect(R.seeds,H.seeds)));
fprintf('    ok   180-row target uses 60 disjoint fresh seeds\n');
checks=checks+1;

assert(contains(R.cells.id,'n5') && ...
    strcmp(R.conditions.id,'iid-load15') && ...
    abs(R.conditions.targetLoad-0.15)<1e-12);
assert(strcmp(R.parentNegativeDecision, ...
    'ELCS_W_BACKGROUND_EPSILON_DOMINATED_RETURN_TO_DESIGN'));
assert(strcmp(R.parentKernelDecision,'ELCS_W_CUMULATIVE_KERNEL_VALID'));
fprintf('    ok   target is exactly the valid EXP23G failure cell\n');
checks=checks+1;

assert(~R.arms(2).cumulativeReceiptRetry && ...
    R.arms(3).cumulativeReceiptRetry);
assert(R.requiredManagementReduction==0.15 && ...
    R.epsilonRmse==0.01 && R.requiredCostImprovement==0.01);
fprintf('    ok   single redesign toggle and decision margins are frozen\n');
checks=checks+1;

assert(~R.policyOptimizationAllowed && ...
    ~R.broadRobustnessClaimPermitted && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted);
fprintf('    ok   target pass cannot promote the method or submission claim\n');
checks=checks+1;

fprintf('\ntest_exp23i_cumulative_closed_loop_contracts: PASS (%d checks)\n',checks);
