% TEST_EXP23Q_BROADCAST_GRAPH_REPAIR_CONTRACTS Preflight contracts.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23q_broadcast_graph_repair_contracts\n');
fprintf('============================================================\n\n');

checks=0; R=exp23qBroadcastGraphRepairRegistry();
P=exp23pCoherencePacketRegistry();
assert(R.expectedRuns==600 && R.requiredValidationContracts==19 && ...
    all(~ismember(R.seeds,P.seeds)));
fprintf('    ok   fresh 600-row registry is disjoint from EXP23P\n'); checks=checks+1;

base=generateExp23mCoherenceBase(R.seeds(1),R.nodeCounts(1),R);
a=runExp23qBroadcastGraphRepairCell(base,R.conditions(1),1,R);
b=runExp23qBroadcastGraphRepairCell(base,R.conditions(1),1,R);
assert(isequaln(a,b) && a.actualSubsetViolations==0 && ...
    a.sameColorConflictViolations==0 && ...
    a.directDeliveryCollisionViolations==0);
fprintf('    ok   independent receiver oracle is deterministic and safe\n'); checks=checks+1;

state=struct('p',[-1.4 0;1.4 0;0 0],'v',zeros(3,2), ...
    'positionError',0,'velocityError',0,'accelerationBound',0);
neighbor=false(3); neighbor(3,1)=true; neighbor(3,2)=true;
B=buildReachableBroadcastConflictSupergraph(state,1,1,neighbor,false(3));
assert(strcmp(B.version,'REACHABLE-BROADCAST-CONFLICT-SUPERGRAPH-v2') && ...
    B.senderConflictGraph(1,2));
fprintf('    ok   repaired v2 graph covers intended-link detectability\n'); checks=checks+1;

fprintf('\ntest_exp23q_broadcast_graph_repair_contracts: PASS (%d checks)\n',checks);
