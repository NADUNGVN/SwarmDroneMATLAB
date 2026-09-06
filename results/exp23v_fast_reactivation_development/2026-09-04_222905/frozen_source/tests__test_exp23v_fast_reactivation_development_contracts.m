% TEST_EXP23V_FAST_REACTIVATION_DEVELOPMENT_CONTRACTS Probe preflight.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23v_fast_reactivation_development_contracts\n');
fprintf('============================================================\n\n');

checks=0; R=exp23vFastReactivationDevelopmentRegistry();
assert(R.expectedRuns==180 && numel(R.seeds)==60 && ...
    R.requiredValidationContracts==18 && ~R.freshSeedEvidence);
fprintf('    ok   180-row probe deliberately reuses EXP23U paired seeds\n');
checks=checks+1;

assert(all([R.arms.fastReactivation]) && ...
    isequal([R.arms.eventTimeSec],[3 8 3]) && ...
    R.arms(3).responseBlackout);
fprintf('    ok   early, late and RESPONSE-blackout fast arms are frozen\n');
checks=checks+1;

assert(~R.policyOptimizationAllowed && ~R.newMethodPromotionAllowed && ...
    ~R.submissionClaimPermitted);
fprintf('    ok   same-seed mechanism probe cannot promote\n'); checks=checks+1;

fprintf('\ntest_exp23v_fast_reactivation_development_contracts: PASS (%d checks)\n',checks);
