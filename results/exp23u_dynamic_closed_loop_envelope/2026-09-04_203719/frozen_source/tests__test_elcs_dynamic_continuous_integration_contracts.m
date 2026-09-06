% TEST_ELCS_DYNAMIC_CONTINUOUS_INTEGRATION_CONTRACTS REVOKE PHY mapping.
startup;
fprintf('\n============================================================\n');
fprintf('test_elcs_dynamic_continuous_integration_contracts\n');
fprintf('============================================================\n\n');

checks=0; [C,T]=fixture();
Q=buildElcsWitnessContinuousSchedule(C,T,2.0); K=Q.kernel;
revoke=Q.controlKind=="revoke";
assert(K.revokeAttempts==1 && nnz(revoke)==1 && ...
    all(Q.controlAttemptBytes(revoke)==24) && ...
    Q.expectedManagementAttempts==numel(Q.controlStartTime) && abs( ...
    Q.expectedManagementAirtime-sum(Q.controlAttemptAirtimeSec))<1e-12 && ...
    abs(sum(Q.controlAttemptAirtimeSec(revoke))-24*8/C.phyRateBps)<1e-15);
fprintf('    ok   one REVOKE maps to its CLAIM minislot with exact 24-byte airtime\n');
checks=checks+1;

spec=struct('clockOffsetSec',linspace(-0.2e-3,0.2e-3,C.N)', ...
    'clockDriftPpm',linspace(-30,30,C.N)', ...
    'maxOffsetSec',0.25e-3,'maxDriftPpm',40, ...
    'leadTimeSec',0.25e-3,'safeGuardSec',C.guardSec);
A=applyDstrAffineClockSchedule(Q,spec);
assert(nnz(A.controlKind=="revoke")==1 && ...
    all(A.controlAttemptBytes(A.controlKind=="revoke")==24) && ...
    A.clockTimingConflictFree==1 && ...
    A.expectedManagementAttempts==Q.expectedManagementAttempts && ...
    abs(A.expectedManagementAirtime-Q.expectedManagementAirtime)<1e-12);
fprintf('    ok   affine clock map preserves REVOKE kind, bytes and accounting\n');
checks=checks+1;

background=struct('backgroundU',zeros(4000,1),'slotTime',1e-3);
background.hashExact=realizationHash(background.backgroundU);
clock=struct('clockOffsetSec',zeros(C.N,1), ...
    'clockDriftPpm',zeros(C.N,1),'leadTimeSec',0);
[blocked,B]=applySharedBackgroundToElcsWitnessTrace( ...
    T,C,background,clock,1);
assert(B.revokeAttemptHits==1 && ...
    blocked.revokeDeliveryU(8,1,3)==0 && ...
    blocked.hashExact==elcsWitnessTraceHash(blocked));
fprintf('    ok   shared occupancy overlays the actual REVOKE interval exactly\n');
checks=checks+1;

assert(K.scheduledCollisionFrames==0 && ...
    K.futureRandomReads==0 && K.receiverTruthDecisionReads==0);
fprintf('    ok   dynamic continuous schedule remains safe and causal\n');
checks=checks+1;

fprintf('\ntest_elcs_dynamic_continuous_integration_contracts: PASS (%d checks)\n',checks);


function [C,T]=fixture()

N=5; F=70;
C=elcsWitnessKernelConfig(N,F);
neighbor=false(N); neighbor(2,1)=true; neighbor(4,3)=true;
potential=false(N); potential(1,2)=true; potential(2,1)=true;
potential(3,4)=true; potential(4,3)=true;
potential(2,4)=true; potential(4,2)=true;
management=false(N); management(1,2)=true; management(2,1)=true;
for node=[1 2 3 4]
    management(5,node)=true; management(node,5)=true;
end
C.neighborGraph=neighbor; C.managementReach=management;
C.interferenceMatrix=potential;
C.conflictGraph=buildSenderConflictGraph(neighbor,potential);
C.cumulativeReceiptRetry=true;
C.coherenceLeaseEnabled=true; C.coherenceLeaseAdmissible=true;
C.coherenceHorizonFrames=C.leaseFrames;
C.dynamicRevocationEnabled=true; C.coherenceRevokeBytes=24;
bound=continuousTdmaGuardBound(0.25e-3,40,3);
C.guardSec=bound.safeGuardSec;
T=generateElcsWitnessTrace(41291,C);
T.revokeDeliveryU=ones(F,N,N);
T.selfRevoke=false(F,N); T.selfRevoke(8,3)=true;
T.reacquireEligible=false(F,N); T.reacquireEligible(15,3)=true;
actual=repmat(reshape(potential,1,N,N),F,1,1);
actual(9:14,2,3)=true; actual(9:14,3,2)=true;
T.actualInterference=actual;
T.hashExact=elcsWitnessTraceHash(T);

end
