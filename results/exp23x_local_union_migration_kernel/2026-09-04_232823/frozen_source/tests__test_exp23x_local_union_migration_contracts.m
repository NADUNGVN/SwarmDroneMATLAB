% TEST_EXP23X_LOCAL_UNION_MIGRATION_CONTRACTS Registry preflight.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23x_local_union_migration_contracts\n');
fprintf('============================================================\n\n');

R=exp23xLocalUnionMigrationRegistry(); checks=0;
assert(R.expectedRuns==3000 && numel(R.seeds)==100 && ...
    isequal(R.swarmSizes,[5 10 20]) && numel(R.cases)==10 && ...
    R.requiredValidationContracts==21);
fprintf('    ok   3000-row three-size randomized matrix is frozen\n');
checks=checks+1;

assert(nnz(strcmp({R.cases.kind},'valid'))==3 && ...
    any(strcmp({R.cases.kind},'response-blackout')) && ...
    any(strcmp({R.cases.kind},'incomplete-union')) && ...
    any(strcmp({R.cases.kind},'missing-witness')) && ...
    any(strcmp({R.cases.kind},'over-mtu')));
fprintf('    ok   valid, erasure and fail-silent cases are all retained\n');
checks=checks+1;

assert(~R.freshSeedEvidence && ~R.policyOptimizationAllowed && ...
    ~R.closedLoopClaimPermitted && ~R.submissionClaimPermitted);
fprintf('    ok   kernel falsification cannot promote performance claims\n');
checks=checks+1;

fprintf('\ntest_exp23x_local_union_migration_contracts: PASS (%d checks)\n',checks);
