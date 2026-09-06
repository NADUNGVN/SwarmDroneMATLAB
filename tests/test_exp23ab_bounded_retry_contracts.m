%% TEST_EXP23AB_BOUNDED_RETRY_CONTRACTS

R=exp23abBoundedRetryRegistry();
assert(R.expectedRuns==120 && R.requiredValidationContracts==24);
assert(R.claimDenseRetryFrames==6 && R.claimMaxBackoffFrames==8 && ...
    R.claimRetryAttemptLimit==10);
assert(~R.freshSeedEvidence && ~R.submissionClaimPermitted && ...
    ~R.geometryCoupledToPlant);

smoke=R;
smoke.arms=R.arms([2 3 4 5]);
rows=runExp23zLocalMigrationClosedLoopSeed(R.smokeSeed,smoke);
dense=rows(1); normal=rows(2); denseBlackout=rows(3); backoff=rows(4);
assert(dense.reacquired==1 && normal.reacquired==1 && ...
    dense.SAFEFAIL==0 && normal.SAFEFAIL==0);
assert(backoff.responseBlackout==1 && backoff.finalSuppressed==1 && ...
    backoff.retryBudgetExhausted==1 && backoff.claimAttempts==10);
assert(backoff.controlAttempts<denseBlackout.controlAttempts && ...
    backoff.controlAirtime<denseBlackout.controlAirtime && ...
    backoff.TOTAL_COST<denseBlackout.TOTAL_COST);
assert(abs(backoff.RMSE-denseBlackout.RMSE)<1e-15 && ...
    abs(backoff.MINSEP-denseBlackout.MINSEP)<1e-15 && ...
    backoff.SAFEFAIL==denseBlackout.SAFEFAIL && backoff.SAFEFAIL==0);
assert(backoff.retryUnionFailureBound<R.maxRetryUnionFailureProbability);
assert(backoff.COLLISION_FRAMES==0 && backoff.dataOutcomeMismatches==0);

fprintf('test_exp23ab_bounded_retry_contracts: PASS\n');
