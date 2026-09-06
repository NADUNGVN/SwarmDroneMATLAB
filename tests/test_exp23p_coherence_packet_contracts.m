% TEST_EXP23P_COHERENCE_PACKET_CONTRACTS Frozen packet-matrix checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23p_coherence_packet_contracts\n');
fprintf('============================================================\n\n');

checks=0;
P=exp23pCoherencePacketRegistry();
O=exp23oBroadcastCoherenceRegistry();
assert(numel(P.seeds)==50 && P.expectedRuns==1800 && ...
    numel(P.conditions)==3 && numel(P.conditionsNetwork)==6 && ...
    isempty(intersect(P.seeds,O.seeds)));
fprintf('    ok   1800-row packet matrix uses disjoint fresh seeds\n');
checks=checks+1;

assert(strcmp(P.parentBroadcastStatus,'BROADCAST_COHERENCE_KERNEL_VALID'));
ids=string({P.conditionsNetwork.id});
assert(isequal(ids,["zero" "claim-iid5" "response-iid5" ...
    "joint-control-iid5" "iid-occupancy15" ...
    "directed-response-blackout"]));
fprintf('    ok   nominal, loss, occupancy and blackout cells are frozen\n');
checks=checks+1;

assert(P.claimBytes==24 && P.certificateEntryBytes==8);
assert(~P.policyOptimizationAllowed && ~P.newMethodPromotionAllowed && ...
    ~P.submissionClaimPermitted);
fprintf('    ok   packet extension is applied only by coherence binding\n');
checks=checks+1;

fprintf('\ntest_exp23p_coherence_packet_contracts: PASS (%d checks)\n',checks);
