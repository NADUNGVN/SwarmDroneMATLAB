% TEST_EXP23Y_MIGRATION_CONTINUOUS_CONTRACTS Registry preflight.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23y_migration_continuous_contracts\n');
fprintf('============================================================\n\n');

R=exp23yMigrationContinuousRegistry(); checks=0;
assert(R.expectedRuns==1800 && numel(R.seeds)==50 && ...
    isequal(R.swarmSizes,[5 10 20]) && numel(R.cases)==6 && ...
    numel(R.clockArms)==2 && R.requiredValidationContracts==18);
fprintf('    ok   1800-row size/case/clock matrix is frozen\n'); checks=checks+1;

B=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.clockResetHorizonSec);
assert(abs(R.safeGuardSec-B.safeGuardSec)<1e-15 && ...
    R.clockResetHorizonSec==30 && R.lockProofRepeatFrames==20);
fprintf('    ok   affine guard and causal proof window are analytical\n');
checks=checks+1;

assert(~R.freshSeedEvidence && ~R.closedLoopClaimPermitted && ...
    ~R.submissionClaimPermitted);
fprintf('    ok   timing integration cannot promote closed-loop claims\n');
checks=checks+1;

fprintf('\ntest_exp23y_migration_continuous_contracts: PASS (%d checks)\n',checks);
