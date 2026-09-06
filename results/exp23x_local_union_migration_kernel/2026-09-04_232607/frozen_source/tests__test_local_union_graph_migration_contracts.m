% TEST_LOCAL_UNION_GRAPH_MIGRATION_CONTRACTS Selector unit contracts.
startup;
fprintf('\n============================================================\n');
fprintf('test_local_union_graph_migration_contracts\n');
fprintf('============================================================\n\n');

[oldGraph,newGraph,slot,node,reach,C]=fixture(); checks=0;
M=buildLocalUnionGraphMigration(oldGraph,newGraph,slot,node,reach,C);
assert(M.admissible && M.localOnly && M.oldColoringProper && ...
    M.candidateUnionColoringProper && M.addedEdgeCount==1 && ...
    M.removedEdgeCount==1 && M.slotChanged && M.oldSlot(node)==1 && ...
    M.newSlot==3 && M.unionWitnessMap.allCovered);
fprintf('    ok   added/removed incident edges force a proper union-safe slot\n');
checks=checks+1;

assert(newGraph(3,node) && slot(3)==slot(node) && ...
    M.candidateSlot(3)~=M.candidateSlot(node));
fprintf('    ok   selector repairs an adversarial old-slot collision\n');
checks=checks+1;

again=buildLocalUnionGraphMigration(oldGraph,newGraph,slot,node,reach,C);
assert(isequaln(M,again) && M.hashExact==again.hashExact);
fprintf('    ok   selector and witness assignment are deterministic\n');
checks=checks+1;

nonlocal=newGraph; nonlocal(1,3)=true; nonlocal(3,1)=true;
Q=buildLocalUnionGraphMigration(oldGraph,nonlocal,slot,node,reach,C);
assert(~Q.admissible && strcmp(Q.reason,'nonlocal_graph_change'));
fprintf('    ok   simultaneous nonlocal change is rejected explicitly\n');
checks=checks+1;

noReach=false(size(reach));
Q=buildLocalUnionGraphMigration(oldGraph,newGraph,slot,node,noReach,C);
assert(~Q.admissible && strcmp(Q.reason,'union_witness_uncovered'));
fprintf('    ok   missing union witness coverage fails silent\n');
checks=checks+1;

small=C; small.maxControlPacketBytes=25;
Q=buildLocalUnionGraphMigration(oldGraph,newGraph,slot,node,reach,small);
assert(~Q.admissible && strcmp(Q.reason,'migration_response_exceeds_mtu'));
fprintf('    ok   over-MTU CLAIM/RESPONSE configuration is rejected\n');
checks=checks+1;

fprintf('\ntest_local_union_graph_migration_contracts: PASS (%d checks)\n',checks);


function [G0,G1,slot,node,reach,C]=fixture()

N=5; node=5; G0=false(N);
edges=[1 2;2 3;3 4;4 5];
for k=1:size(edges,1)
    a=edges(k,1); b=edges(k,2); G0(a,b)=true; G0(b,a)=true;
end
G1=G0; G1(4,5)=false; G1(5,4)=false;
G1(3,5)=true; G1(5,3)=true;
slot=[1;2;1;2;1]; reach=true(N); reach(1:N+1:end)=false;
C=struct('maxDataSlots',N,'claimBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'maxControlPacketBytes',96,'revokeBytes',24);

end
