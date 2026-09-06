% TEST_EXP23U_DYNAMIC_CLOSED_LOOP_ENVELOPE_CONTRACTS Matrix preflight.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23u_dynamic_closed_loop_envelope_contracts\n');
fprintf('============================================================\n\n');

checks=0; R=exp23uDynamicClosedLoopEnvelopeRegistry();
T=exp23tStaticCoherenceClosedLoopRegistry();
assert(R.expectedRuns==360 && numel(R.seeds)==60 && ...
    numel(R.arms)==6 && R.requiredValidationContracts==21 && ...
    all(~ismember(R.seeds,T.seeds)));
fprintf('    ok   360-row dynamic envelope uses fresh disjoint seeds\n');
checks=checks+1;

assert(strcmp(R.parentStaticStatus,'STATIC_COHERENCE_COMMON_PHY_SURVIVES') && ...
    strcmp(R.parentDynamicKernelStatus, ...
    'DYNAMIC_COHERENCE_REVOCATION_KERNEL_VALID') && ...
    R.arms(3).eventTimeSec==3 && R.arms(5).eventTimeSec==8 && ...
    R.reacquireEligibilityDelaySec==0.5);
fprintf('    ok   parent evidence and early/late timing are frozen\n');
checks=checks+1;

assert(~R.policyOptimizationAllowed && ~R.broadRobustnessClaimPermitted && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted);
fprintf('    ok   operating-envelope outcome cannot tune or promote\n');
checks=checks+1;

fprintf('\ntest_exp23u_dynamic_closed_loop_envelope_contracts: PASS (%d checks)\n',checks);
