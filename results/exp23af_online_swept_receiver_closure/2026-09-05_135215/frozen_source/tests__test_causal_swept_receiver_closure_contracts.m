%% TEST_CAUSAL_SWEPT_RECEIVER_CLOSURE_CONTRACTS
startup;

N=5; p0=[0 0;1 0;0 1;-1 0;0 -1]; p1=p0;
p1(5,:)=[.65 0]; neighbor=false(N); neighbor(5,1)=true;
reach=true(N); reach(1:N+1:end)=false;
packet=struct('maxDataSlots',N,'maxAffectedNodes',N, ...
    'prepareHeaderBytes',32,'affectedEntryBytes',4,'claimBytes',72, ...
    'quietBytes',24,'lockProofBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'commitBytes',28,'maxControlPacketBytes',96,'revokeBytes',24);
G=buildCausalSweptReceiverClosure(p0,p1,.01,.4,neighbor,reach,5,packet);
assert(G.causalStateOnly&&G.publicCommandOnly&& ...
    G.futureActualReads==0&&G.futureRandomReads==0);
assert(all(G.oldPhysicalGraph<=G.proposedPhysicalGraph,'all'));
assert(G.migration.admissible&&G.migration.changedEdgeCount>0&& ...
    any(G.migration.changedEdgeA~=5&G.migration.changedEdgeB~=5));

packet.retiringSlot=(1:N)';
Gfixed=buildCausalSweptReceiverClosure( ...
    p0,p1,.01,.4,neighbor,reach,5,packet);
assert(isequal(Gfixed.migration.oldSlot,(1:N)'));

% Interior closest approach must be included even when both endpoints are
% outside the radio radius.
B=buildSweptBroadcastConflictSupergraph( ...
    [-1 0;0 0],[1 0;0 0],0,.25,false(2));
assert(B.potentialInterferenceGraph(1,2)&& ...
    abs(B.closestProgress(1,2)-.5)<1e-12);

pairBound=[0 .1;.1 0];
Bpair=buildSweptBroadcastConflictSupergraph( ...
    [-1 0;0 0],[-.3 0;0 0],pairBound,.25,false(2));
assert(Bpair.potentialInterferenceGraph(1,2)&& ...
    strcmp(Bpair.trackingRadiusMode,'pairwise-relative'));

fprintf('test_causal_swept_receiver_closure_contracts: PASS\n');
