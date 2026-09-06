% TEST_EXP23M_COHERENCE_STIMULUS_CONTRACTS Repair-scope checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23m_coherence_stimulus_contracts\n');
fprintf('============================================================\n\n');

checks=0;
L=exp23lCoherenceGeometryRegistry();
M=exp23mCoherenceGeometryRegistry();
assert(numel(M.seeds)==100 && isempty(intersect(L.seeds,M.seeds)) && ...
    M.expectedRuns==600 && numel(M.conditions)==3);
fprintf('    ok   repair uses 600 rows and disjoint fresh seeds\n');
checks=checks+1;

assert(strcmp(M.parentInvalidStatus,'COHERENCE_GEOMETRY_KERNEL_INVALID'));
assert(isinf(M.conditions(1).managementRadius) && ...
    M.conditions(1).speedScale==0 && ...
    M.conditions(2).managementRadius==1.5 && ...
    M.conditions(3).managementRadius==1.5);
fprintf('    ok   only the missing static/wide positive-control regime is added\n');
checks=checks+1;

assert(isequal(M.horizonsSec,L.horizonsSec) && ...
    M.interferenceRadius==L.interferenceRadius && ...
    M.accelerationBound==L.accelerationBound && ...
    M.maxControlPacketBytes==L.maxControlPacketBytes);
assert(~M.policyOptimizationAllowed && ~M.newMethodPromotionAllowed && ...
    ~M.submissionClaimPermitted);
fprintf('    ok   geometry rules, bounds and non-promotion scope remain fixed\n');
checks=checks+1;

fprintf('\ntest_exp23m_coherence_stimulus_contracts: PASS (%d checks)\n',checks);
