% TEST_LOCAL_UNION_GRAPH_MIGRATION_KERNEL_CONTRACTS Packet lifecycle tests.
startup;
fprintf('\n============================================================\n');
fprintf('test_local_union_graph_migration_kernel_contracts\n');
fprintf('============================================================\n\n');

[M,C,T]=fixture(); checks=0;
O=simulateLocalUnionGraphMigration(M,C,T);
assert(O.reacquired && O.firstReacquiredFrame==C.eligibleFrame && ...
    O.finalSlot==M.newSlot && O.slotChanged && O.actualSubsetUnion && ...
    O.scheduledCollisionFrames==0 && O.unsafeReuseFrames==0);
fprintf('    ok   fresh union receipts activate the changed slot safely\n');
checks=checks+1;

delayed=T; delayed.responseDeliveryU(C.eligibleFrame:C.eligibleFrame+3, ...
    M.transitionNode,:)=0; delayed.hashExact=localUnionMigrationTraceHash(delayed);
D=simulateLocalUnionGraphMigration(M,C,delayed);
assert(D.reacquired && D.firstReacquiredFrame>C.eligibleFrame && ...
    D.scheduledCollisionFrames==0 && D.controlAttempts>O.controlAttempts);
fprintf('    ok   erased RESPONSE delays cumulative closure without unsafe reuse\n');
checks=checks+1;

blocked=T; blocked.responseDeliveryU(C.eligibleFrame:end, ...
    M.transitionNode,:)=0; blocked.hashExact=localUnionMigrationTraceHash(blocked);
B=simulateLocalUnionGraphMigration(M,C,blocked);
assert(~B.reacquired && B.finalSuppressed && B.transactionOpen && ...
    B.scheduledCollisionFrames==0 && B.acceptedResponseEntries< ...
    B.requiredResponseEntries);
fprintf('    ok   permanent RESPONSE blackout remains fail-silent\n');
checks=checks+1;

lost=T; lost.revokeDeliveryU(C.transitionFrame,:,M.transitionNode)=0;
lost.hashExact=localUnionMigrationTraceHash(lost);
L=simulateLocalUnionGraphMigration(M,C,lost);
assert(isequal(L.debug.suppressed,O.debug.suppressed) && ...
    isequal(L.debug.reacquired,O.debug.reacquired) && ...
    L.finalSlot==O.finalSlot && L.scheduledCollisionFrames==0 && ...
    L.recipientErasure>O.recipientErasure);
fprintf('    ok   REVOKE loss cannot change local silence or migration\n');
checks=checks+1;

stale=T; stale.responseVersion(C.eligibleFrame:end,:)=1;
stale.hashExact=localUnionMigrationTraceHash(stale);
S=simulateLocalUnionGraphMigration(M,C,stale);
assert(~S.reacquired && S.finalSuppressed && ...
    S.acceptedResponseEntries==0);
fprintf('    ok   stale response version cannot complete migration\n');
checks=checks+1;

concurrent=T; concurrent.selfRevoke(C.transitionFrame,2)=true;
concurrent.hashExact=localUnionMigrationTraceHash(concurrent);
Q=simulateLocalUnionGraphMigration(M,C,concurrent);
assert(Q.unsupportedConcurrentMigration && ~Q.reacquired && ...
    Q.finalSuppressed);
fprintf('    ok   concurrent migration is rejected as unsupported\n');
checks=checks+1;

outside=T; outside.actualGraph(C.newGraphActivationFrame:end,1,3)=true;
outside.actualGraph(C.newGraphActivationFrame:end,3,1)=true;
outside.hashExact=localUnionMigrationTraceHash(outside);
Q=simulateLocalUnionGraphMigration(M,C,outside);
assert(~Q.actualSubsetUnion);
fprintf('    ok   independent actual-graph oracle rejects incomplete union\n');
checks=checks+1;

assert(O.controlAttempts==O.claimAttempts+O.lockProofAttempts+ ...
    O.responseAttempts+O.revokeAttempts && ...
    O.controlBytes==O.claimBytes+O.lockProofBytes+ ...
    O.responseBytes+O.revokeBytes && ...
    O.recipientSuccess+O.recipientErasure==O.recipientAttempts && ...
    O.recipientCollision==0 && O.controlAttemptBoundRatio<=1 && ...
    O.controlByteBoundRatio<=1 && ...
    abs(O.controlAirtimeSec-O.controlBytes*8/C.phyRateBps)<1e-15 && ...
    O.futureRandomReads==0 && O.receiverTruthReads==0);
fprintf('    ok   control bytes, recipients, airtime and bounds close\n');
checks=checks+1;

fprintf('\ntest_local_union_graph_migration_kernel_contracts: PASS (%d checks)\n', ...
    checks);


function [M,C,T]=fixture()

N=5; node=5; G0=false(N); edges=[1 2;2 3;3 4;4 5];
for k=1:size(edges,1)
    a=edges(k,1); b=edges(k,2); G0(a,b)=true; G0(b,a)=true;
end
G1=G0; G1(4,5)=false; G1(5,4)=false;
G1(3,5)=true; G1(5,3)=true;
slot=[1;2;1;2;1]; reach=true(N); reach(1:N+1:end)=false;
packet=struct('maxDataSlots',N,'claimBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'maxControlPacketBytes',96,'revokeBytes',24);
M=buildLocalUnionGraphMigration(G0,G1,slot,node,reach,packet);
C=struct('maxFrames',30,'transitionFrame',8,'eligibleFrame',12, ...
    'newGraphActivationFrame',9,'phyRateBps',250e3, ...
    'claimErasureProbability',0.2,'lockProofErasureProbability',0.2, ...
    'responseErasureProbability',0.2,'revokeErasureProbability',0.2);
T=generateLocalUnionMigrationTrace(16084000,M,C);
T.claimDeliveryU(:)=1; T.lockProofDeliveryU(:)=1;
T.responseDeliveryU(:)=1; T.revokeDeliveryU(:)=1;
T.hashExact=localUnionMigrationTraceHash(T);

end
