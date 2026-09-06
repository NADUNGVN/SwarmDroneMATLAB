% TEST_EXP23R_COHERENCE_PACKET_REPAIR_CONTRACTS Frozen repair-matrix checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23r_coherence_packet_repair_contracts\n');
fprintf('============================================================\n\n');

checks=0; R=exp23rCoherencePacketRepairRegistry();
P=exp23pCoherencePacketRegistry(); Q=exp23qBroadcastGraphRepairRegistry();
assert(numel(R.seeds)==50 && R.expectedRuns==1800 && ...
    all(~ismember(R.seeds,P.seeds)) && all(~ismember(R.seeds,Q.seeds)));
fprintf('    ok   1800-row repair matrix uses fresh disjoint seeds\n'); checks=checks+1;

assert(strcmp(R.parentGraphStatus, ...
    'BROADCAST_DETECTABILITY_GRAPH_REPAIR_VALID') && ...
    strcmp(R.parentPacketInvalidStatus, ...
    'COHERENCE_ELCS_W_PACKET_KERNEL_INVALID'));
fprintf('    ok   valid graph repair and invalid packet parent are explicit\n'); checks=checks+1;

assert(R.requiredValidationContracts==20 && ...
    ~R.policyOptimizationAllowed && ~R.newMethodPromotionAllowed && ...
    ~R.submissionClaimPermitted);
fprintf('    ok   all packet gates remain frozen without promotion\n'); checks=checks+1;

fprintf('\ntest_exp23r_coherence_packet_repair_contracts: PASS (%d checks)\n',checks);
