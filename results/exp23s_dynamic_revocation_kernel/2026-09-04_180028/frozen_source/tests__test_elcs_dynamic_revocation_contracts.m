% TEST_ELCS_DYNAMIC_REVOCATION_CONTRACTS Scripted revocation lifecycle.
startup;
fprintf('\n============================================================\n');
fprintf('test_elcs_dynamic_revocation_contracts\n');
fprintf('============================================================\n\n');

checks=0;
[C,T]=fixture();
O=simulateElcsWitnessScheduling(C,T);
assert(strcmp(O.version,'ELCS-W-COHERENCE-REVOCATION-v3') && ...
    O.selfRevocationCount==1 && O.revokeAttempts==1 && ...
    O.revokeBytes==24 && O.finalVersion(3)==2);
fprintf('    ok   local violation emits one charged version-incrementing REVOKE\n');
checks=checks+1;

assert(~any(O.debug.active(8:22,3)) && ...
    all(O.debug.suppressed(8:22,3)) && ...
    O.debug.reacquired(23,3) && O.debug.active(23,3) && ...
    O.reacquisitionLatencyFrames(3)==15);
fprintf('    ok   sender stays silent through old fence then reacquires freshly\n');
checks=checks+1;

assert(O.scheduledCollisionFrames==0 && ...
    ~any(O.debug.scheduledCollision,'all'));
fprintf('    ok   scripted edge additions/removals and violation remain safe\n');
checks=checks+1;

lost=T; lost.revokeDeliveryU(8,:,3)=0;
lost.hashExact=elcsWitnessTraceHash(lost);
L=simulateElcsWitnessScheduling(C,lost);
assert(L.revokeRecipientErasure>0 && ...
    isequal(L.debug.suppressed(:,3),O.debug.suppressed(:,3)) && ...
    isequal(L.debug.reacquired(:,3),O.debug.reacquired(:,3)) && ...
    L.scheduledCollisionFrames==0 && ...
    L.revokeWitnessClears<O.revokeWitnessClears);
fprintf('    ok   permanent asymmetric REVOKE loss cannot shorten local silence\n');
checks=checks+1;

blocked=T; blocked.certificateDeliveryU(15:end,3,5)=0;
blocked.hashExact=elcsWitnessTraceHash(blocked);
Q=simulateElcsWitnessScheduling(C,blocked);
assert(Q.finalSuppressed(3) && Q.reacquisitionCount==0 && ...
    ~any(Q.debug.active(8:end,3)) && Q.scheduledCollisionFrames==0);
fprintf('    ok   missing reacquisition RESPONSE remains fail-silent\n');
checks=checks+1;

D=coherenceRevokeCacheDecision(1,1,2,true);
stale=coherenceRevokeCacheDecision(2,1,2,true);
future=coherenceRevokeCacheDecision(1,2,3,true);
mismatch=coherenceRevokeCacheDecision(1,1,3,true);
unauth=coherenceRevokeCacheDecision(1,1,2,false);
assert(D.accept && ~D.createsValidity && ~stale.accept && ...
    ~future.accept && ~mismatch.accept && ~unauth.accept);
fprintf('    ok   stale, future, malformed and unauthenticated REVOKEs are inert\n');
checks=checks+1;

assert(O.controlAttempts==O.claimAttempts+O.certificateAttempts+ ...
    O.revokeAttempts && O.controlBytes==O.claimBytes+ ...
    O.certificateBytes+O.revokeBytes && ...
    O.managementRecipientSuccess+O.managementRecipientErasure+ ...
    O.managementRecipientCollision==O.managementRecipientAttempts && ...
    O.revokeRecipientSuccess+O.revokeRecipientErasure+ ...
    O.revokeRecipientCollision==O.revokeRecipientAttempts && ...
    O.controlAttemptBoundRatio<=1 && O.controlByteBoundRatio<=1);
fprintf('    ok   REVOKE attempt, byte, recipient and absolute bounds close\n');
checks=checks+1;

S=C; S.dynamicRevocationEnabled=false;
base=generateElcsWitnessTrace(40291,S);
a=simulateElcsWitnessScheduling(S,base);
b=simulateElcsWitnessScheduling(S,base);
assert(isequaln(a,b) && a.selfRevocationCount==0 && ...
    a.revokeAttempts==0 && a.revokeBytes==0);
fprintf('    ok   static mode remains deterministic with zero revocation effort\n');
checks=checks+1;

fprintf('\ntest_elcs_dynamic_revocation_contracts: PASS (%d checks)\n',checks);


function [C,T]=fixture()

N=5; F=45;
C=elcsWitnessKernelConfig(N,F);
neighbor=false(N); neighbor(2,1)=true; neighbor(4,3)=true;
potential=false(N); potential(1,2)=true; potential(2,1)=true;
potential(3,4)=true; potential(4,3)=true;
potential(2,4)=true; potential(4,2)=true;
C.neighborGraph=neighbor;
management=false(N); management(1,2)=true; management(2,1)=true;
management(5,1)=true; management(1,5)=true;
management(5,2)=true; management(2,5)=true;
management(5,3)=true; management(3,5)=true;
management(5,4)=true; management(4,5)=true;
C.managementReach=management;
C.interferenceMatrix=potential;
C.conflictGraph=buildSenderConflictGraph(neighbor,potential);
C.cumulativeReceiptRetry=true;
C.coherenceLeaseEnabled=true;
C.coherenceLeaseAdmissible=true;
C.coherenceHorizonFrames=C.leaseFrames;
C.coherenceRevokeBytes=24;
C.dynamicRevocationEnabled=true;
T=generateElcsWitnessTrace(40291,C);
T.revokeDeliveryU=ones(F,N,N);
T.selfRevoke=false(F,N); T.selfRevoke(8,3)=true;
T.reacquireEligible=false(F,N); T.reacquireEligible(15,3)=true;
actual=false(F,N,N);
baseline=false(N); baseline(1,2)=true; baseline(2,1)=true;
baseline(3,4)=true; baseline(4,3)=true;
for frame=1:F, actual(frame,:,:)=baseline; end
actual(4:12,2,4)=true; actual(4:12,4,2)=true;
actual(9:14,2,3)=true; actual(9:14,3,2)=true;
T.actualInterference=actual;
T.hashExact=elcsWitnessTraceHash(T);

end
