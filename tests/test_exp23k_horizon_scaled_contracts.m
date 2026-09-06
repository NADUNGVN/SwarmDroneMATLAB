% TEST_EXP23K_HORIZON_SCALED_CONTRACTS Frozen development checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23k_horizon_scaled_contracts\n');
fprintf('============================================================\n\n');

checks=0;
R=exp23kHorizonScaledRegistry();
assert(R.renewalScaleFactor==9 && R.baselineRenewalPeriodFrames==13 && ...
    R.renewalPeriodFrames==117 && R.leaseFrames==124);
assert(R.leaseFrames-R.refreshLeadFrames-R.leaseFenceFrames== ...
    R.renewalPeriodFrames);
fprintf('    ok   9x renewal horizon and exact lease slack are frozen\n');
checks=checks+1;

I=exp23iCumulativeClosedLoopRegistry();
assert(isequal(R.seeds,I.seeds) && R.expectedRuns==60 && ...
    strcmp(R.sourceRun,'2026-09-04_162852'));
fprintf('    ok   probe explicitly reuses all 60 development seeds\n');
checks=checks+1;

assert(R.requiredManagementReduction==0.75 && ...
    R.requiredPeriodicCostAdvantage==0.01 && ...
    R.allowedRmseInflation==0.01);
assert(~R.policyOptimizationAllowed && ~R.newMethodPromotionAllowed && ...
    ~R.broadRobustnessClaimPermitted && ~R.submissionClaimPermitted);
fprintf('    ok   feasibility thresholds and non-promotion scope are frozen\n');
checks=checks+1;

fprintf('\ntest_exp23k_horizon_scaled_contracts: PASS (%d checks)\n',checks);
