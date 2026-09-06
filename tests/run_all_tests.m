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
    'test_formation_theory_certificate'
    'test_tcns_gate1_model_mapping'
    'test_tcns_gate2_staleness_bound'
    'test_tcns_gate3_robustness_bound'
    'test_tcns_gate4_control_aware_policy'
    'test_probabilistic_safety_certificate'
    'test_standalone_ack_value_certificate'
    'test_setpoint_interface'
    'test_lock_regression'
    'test_causal_invariants'
    'test_shared_medium_infrastructure'
    'test_ack_value_instrumentation'
    'test_ack_branch_replay'
    'test_causal_broadcast_policy'
    'test_shared_medium_end_to_end'
    'test_exp13_policy_contracts'
    'test_shared_medium_channel_models'
    'test_exp14_infrastructure'
    'test_mac_aware_policy'
    'test_context_aware_policy'
    'test_exp14d_factorial_contracts'
    'test_exp14e_holdout_contracts'
    'test_exp14f_shadow_contracts'
    'test_exp14g_contracts'
    'test_exp14h_contracts'
    'test_exp14i_contracts'
    'test_exp16_contracts'
    'test_exp16_analysis_contracts'
    'test_exp17_contracts'
    'test_exp17_analysis_contracts'
    'test_exp18_contracts'
    'test_exp18_analysis_contracts'
    'test_exp18a2_contracts'
    'test_exp18a3_contracts'
    'test_exp18a3_analysis_contracts'
    'test_exp18a4_contracts'
    'test_exp18a4_analysis_contracts'
    'test_exp18b_contracts'
    'test_exp18b_analysis_contracts'
    'test_exp18b_scientific_audit_contracts'
    'test_service_scheduler_contracts'
    'test_exp19a_contracts'
    'test_exp19a_analysis_contracts'
    'test_exp19a_end_to_end'
    'test_exp19a_posthoc_contracts'
    'test_exp20a_delta_contracts'
    'test_exp20a_formation_contracts'
    'test_exp20a_analysis_contracts'
    'test_exp21a_contracts'
    'test_exp21a_analysis_contracts'
    'test_exp21b_continuous_timing_contracts'
    'test_exp21c_closed_loop_timing_contracts'
    'test_exp21d_dstr_kernel_contracts'
    'test_exp21d_closed_loop_integration_contracts'
    'test_exp21d_boundary_contracts'
    'test_exp21d_clock_composition_contracts'
    'test_local_union_graph_migration_kernel_contracts'
    'test_local_union_migration_continuous_contracts'
    'test_local_migration_emergency_data_contracts'
    'test_local_union_migration_retry_backoff_contracts'
    'test_exp23ab_bounded_retry_contracts'
    'test_elcs_kernel_contracts'
    'test_elcs_continuous_integration_contracts'
    'test_exp18b_contracts'
    'test_exp18b_analysis_contracts'
    'test_exp15_trace_contracts'
    'test_blackout_semantics'
    'test_mismatch_semantics'
    'test_estimator_semantics'
    'test_exp10_infrastructure'
    'test_exp11_regime_semantics'
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
