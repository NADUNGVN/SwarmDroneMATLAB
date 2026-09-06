% TEST_EXP23O_BROADCAST_COHERENCE_CONTRACTS Frozen receiver-lift scope.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23o_broadcast_coherence_contracts\n');
fprintf('============================================================\n\n');

checks=0;
O=exp23oBroadcastCoherenceRegistry();
L=exp23lCoherenceGeometryRegistry();
M=exp23mCoherenceGeometryRegistry();
assert(numel(O.seeds)==100 && O.expectedRuns==600 && ...
    isempty(intersect(O.seeds,L.seeds)) && ...
    isempty(intersect(O.seeds,M.seeds)));
fprintf('    ok   600-row receiver-lift study uses disjoint fresh seeds\n');
checks=checks+1;

assert(O.dataNeighborRadius==1.5 && ...
    strcmp(O.parentGeometryStatus,'COHERENCE_GEOMETRY_KERNEL_VALID'));
assert(isequal(O.horizonsSec,M.horizonsSec) && ...
    O.interferenceRadius==M.interferenceRadius && ...
    O.maxControlPacketBytes==M.maxControlPacketBytes);
fprintf('    ok   receiver lift is the only mathematical-model extension\n');
checks=checks+1;

assert(~O.policyOptimizationAllowed && ~O.newMethodPromotionAllowed && ...
    ~O.submissionClaimPermitted);
fprintf('    ok   kernel pass cannot promote performance or submission claims\n');
checks=checks+1;

fprintf('\ntest_exp23o_broadcast_coherence_contracts: PASS (%d checks)\n',checks);
