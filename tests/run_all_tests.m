%% RUN_ALL_TESTS Run the whole test suite in dependency order.
%
% One command, one verdict. The reproducibility entry point
% (experiments/run_simulation_v1_validation.m) calls this first and
% refuses to go further if anything here fails, so the suite has to be
% callable as a unit rather than eight files a person remembers to run.
%
% Order matters only in one respect: test_lock_regression is the
% expensive one and the one that would catch a change to a locked
% result, so it runs early enough that a failure is seen before the rest
% of the suite has spent several minutes.
%
% Each test script raises an error on failure. They are caught here so
% that one failure does not hide the state of the others, and the run
% still ends with a non-zero exit through the final error().
%
% ISOLATION
%
% Each test runs through runScriptIsolated, NOT evalin('base', ...). A
% test script's variables would otherwise land in the same workspace as
% this runner's own, and that is not hypothetical: test_mismatch_semantics
% assigns t0 = generateExternalForceTrace(...), which collided with the
% t0 = tic used to time each test. toc(t0) then raised, and the suite
% aborted after the seventh test having printed no failure and no summary,
% so two tests silently never ran. See utils/runScriptIsolated.m.

startup;

suite = {
    'test_rotation'
    'test_formation_error'
    'test_setpoint_interface'
    'test_lock_regression'
    'test_causal_invariants'
    'test_blackout_semantics'
    'test_mismatch_semantics'
    'test_estimator_semantics'
    'test_exp10_infrastructure'
};

nTest = numel(suite);

passed = false(nTest,1);
message = cell(nTest,1);
elapsed = zeros(nTest,1);

tAll = tic;

fprintf('\n');
fprintf('############################################################\n');
fprintf('# TEST SUITE  (%d files)\n', nTest);
fprintf('############################################################\n');

for k = 1:nTest

    name = suite{k};

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('[%d/%d] %s\n', k, nTest, name);
    fprintf('------------------------------------------------------------\n');

    t0 = tic;

    try
        runScriptIsolated(name);
        passed(k)  = true;
        message{k} = '';
    catch err
        passed(k)  = false;
        message{k} = err.message;
        fprintf(2, 'FAILED: %s -- %s\n', name, err.message);
    end

    elapsed(k) = toc(t0);

end


%% ============================================================
% Summary
% ============================================================

fprintf('\n');
fprintf('############################################################\n');
fprintf('# TEST SUITE SUMMARY\n');
fprintf('############################################################\n\n');

for k = 1:nTest
    if passed(k)
        fprintf('  [PASS ] %-28s %6.1f s\n', suite{k}, elapsed(k));
    else
        fprintf('  [FAIL ] %-28s %6.1f s  %s\n', ...
            suite{k}, elapsed(k), message{k});
    end
end

fprintf('\n  %d of %d passed in %.1f min\n', ...
    nnz(passed), nTest, toc(tAll)/60);

testsAllPassed = all(passed);

if ~testsAllPassed
    error('run_all_tests: %d of %d test files FAILED.', ...
        nnz(~passed), nTest);
end

fprintf('\n  TEST SUITE: ALL PASS\n');
