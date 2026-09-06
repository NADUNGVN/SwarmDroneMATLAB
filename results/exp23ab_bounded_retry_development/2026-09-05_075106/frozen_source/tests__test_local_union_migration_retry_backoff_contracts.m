%% TEST_LOCAL_UNION_MIGRATION_RETRY_BACKOFF_CONTRACTS

startup;
C=struct('maxFrames',40,'eligibleFrame',5, ...
    'claimBackoffEnabled',true,'claimDenseRetryFrames',6, ...
    'claimMaxBackoffFrames',8,'claimRetryAttemptLimit',10);
[due,P]=localUnionMigrationClaimSchedule(C);
expected=[5 6 7 8 9 10 12 16 24 32]';
assert(isequal(find(due),expected));
assert(P.enabled && P.opportunityCount==10 && ...
    P.lastOpportunityFrame==32 && P.attemptLimit==10);
B=localUnionMigrationRetryCertificate(CertificateConfig(C),9);
assert(B.entryFailureUpperBound>0 && B.unionFailureUpperBound<1e-3 && ...
    B.allEntriesSuccessLowerBound>0.999 && ...
    B.claimOpportunityCount==10);

plain=rmfield(C,{'claimBackoffEnabled','claimDenseRetryFrames', ...
    'claimMaxBackoffFrames','claimRetryAttemptLimit'});
[allDue,D]=localUnionMigrationClaimSchedule(plain);
assert(isequal(find(allDue),(5:40)') && ~D.enabled);

[M,K,T]=fixture();
blackout=T;
blackout.responseDeliveryU(K.eligibleFrame:end,M.transitionNode,:)=0;
blackout.hashExact=localUnionMigrationTraceHash(blackout);
dense=simulateLocalUnionGraphMigration(M,K,blackout);
Kb=K; Kb.claimBackoffEnabled=true; Kb.claimDenseRetryFrames=6;
Kb.claimMaxBackoffFrames=8; Kb.claimRetryAttemptLimit=10;
backoff=simulateLocalUnionGraphMigration(M,Kb,blackout);
assert(~dense.reacquired && ~backoff.reacquired && ...
    dense.finalSuppressed && backoff.finalSuppressed);
assert(backoff.retryBudgetExhausted==1 && ...
    backoff.claimAttempts==10 && ...
    backoff.claimAttempts<dense.claimAttempts && ...
    backoff.responseAttempts<dense.responseAttempts && ...
    backoff.controlAttempts<dense.controlAttempts);
assert(backoff.scheduledCollisionFrames==0 && ...
    backoff.unsafeReuseFrames==0 && ...
    backoff.controlAttemptBoundRatio<=1 && ...
    backoff.controlByteBoundRatio<=1 && ...
    isequal(find(backoff.debug.claimTx), ...
        find(backoff.debug.claimOpportunity)));

nominal=simulateLocalUnionGraphMigration(M,Kb,T);
assert(nominal.reacquired && nominal.firstReacquiredFrame==K.eligibleFrame && ...
    nominal.claimAttempts==1 && nominal.scheduledCollisionFrames==0);

fprintf('test_local_union_migration_retry_backoff_contracts: PASS\n');


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
C=struct('maxFrames',40,'transitionFrame',8,'eligibleFrame',12, ...
    'newGraphActivationFrame',9,'lockProofRepeatFrames',12, ...
    'phyRateBps',250e3, ...
    'claimErasureProbability',0.2,'lockProofErasureProbability',0.2, ...
    'responseErasureProbability',0.2,'revokeErasureProbability',0.2);
T=generateLocalUnionMigrationTrace(16088000,M,C);
T.claimDeliveryU(:)=1; T.lockProofDeliveryU(:)=1;
T.responseDeliveryU(:)=1; T.revokeDeliveryU(:)=1;
T.hashExact=localUnionMigrationTraceHash(T);

end


function C=CertificateConfig(C)

C.lockProofRepeatFrames=20;
C.claimErasureProbability=.2;
C.lockProofErasureProbability=.2;
C.responseErasureProbability=.2;

end
