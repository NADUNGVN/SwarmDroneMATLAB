%% TEST_RECEIVER_LIFTED_DEPENDENCY_MIGRATION_CONTRACTS

startup;
N=5; neighbor=false(N); neighbor(5,1)=true;
I0=false(N); I1=I0; I1(5,3)=true; I1(3,5)=true;
F0=buildSenderConflictGraph(neighbor,I0);
F1=buildSenderConflictGraph(neighbor,I1);
assert(F1(1,3) && ~F0(1,3));
oldSlot=elcsWitnessPriorityColor(F0);
reach=true(N); reach(1:N+1:end)=false;
C=config(N);
M=buildReceiverLiftedDependencyMigration(F0,F1,oldSlot,5,reach,C);
assert(M.admissible && M.changedEdgeCount==1 && ...
    isequal(M.changedEdgeA,1) && isequal(M.changedEdgeB,3));
assert(isequal(M.affectedNodes,[1;3;5]) && M.affectedCount==3 && ...
    M.changedEdgeEndpointMask(1) && M.changedEdgeEndpointMask(3) && ...
    ~M.changedEdgeEndpointMask(5));
assert(M.outsideSubgraphUnchanged && M.candidateUnionColoringProper && ...
    M.changedSlotCount>=1 && M.prepareCovered && ...
    M.quiescentAckCovered && M.payloadAdmissible);
[a,b]=find(triu(M.unionGraph,1));
assert(all(M.candidateSlot(a)~=M.candidateSlot(b)));
assert(all(M.candidateSlot(M.outsideNodes)==oldSlot(M.outsideNodes)));

broken=reach; broken(1,5)=false;
Q=buildReceiverLiftedDependencyMigration(F0,F1,oldSlot,5,broken,C);
assert(~Q.admissible && strcmp(Q.reason,'prepare_path_missing'));

small=C; small.maxDataSlots=1;
try
    buildReceiverLiftedDependencyMigration(F0,F1,oldSlot,5,reach,small);
    error('expected old-slot range rejection');
catch err
    assert(contains(err.message,'oldSlot exceeds slots'));
end

tiny=C; tiny.maxAffectedNodes=2;
Q=buildReceiverLiftedDependencyMigration(F0,F1,oldSlot,5,reach,tiny);
assert(~Q.admissible && strcmp(Q.reason,'affected_set_above_bound'));

mtu=C; mtu.maxControlPacketBytes=47;
Q=buildReceiverLiftedDependencyMigration(F0,F1,oldSlot,5,reach,mtu);
assert(~Q.admissible && strcmp(Q.reason,'control_payload_exceeds_mtu'));

same=buildReceiverLiftedDependencyMigration(F0,F0,oldSlot,5,reach,C);
assert(~same.admissible && strcmp(same.reason,'no_sender_graph_change'));

fprintf('test_receiver_lifted_dependency_migration_contracts: PASS\n');


function C=config(N)

C=struct('maxDataSlots',N,'maxAffectedNodes',N, ...
    'prepareHeaderBytes',32,'affectedEntryBytes',4,'claimBytes',72, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'maxControlPacketBytes',96,'revokeBytes',24);

end
