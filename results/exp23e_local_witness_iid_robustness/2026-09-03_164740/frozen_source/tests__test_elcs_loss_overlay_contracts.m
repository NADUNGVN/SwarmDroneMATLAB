% TEST_ELCS_LOSS_OVERLAY_CONTRACTS Shared absolute DATA-loss overlay.
startup;
fprintf('\n============================================================\n');
fprintf('test_elcs_loss_overlay_contracts\n');
fprintf('============================================================\n\n');

checks=0;
R=exp23cWitnessClosedLoopRegistry();
base=applyExp21dClosedLoopCell(R.cells(1).id,16060000);
base.mac.residualLoss=0.05;
base.mac.dataResidualLoss=0.05;
base.mac.ackResidualLoss=0;
base.mac=sharedMediumConfig(base);
trace=generateSharedMediumTrace(base);
C=elcsWitnessKernelConfig(base.swarm.N,R.maxFrames);
C.guardSec=R.missionSafeGuardSec;
C.dataBytes=base.mac.dataBytes;
C.phyRateBps=base.mac.phyRateBps;
C.neighborGraph=logical(base.swarm.A);
C.managementReach=C.neighborGraph;
C.interferenceMatrix=logical(base.mac.interferenceMatrix);
C.conflictGraph=buildSenderConflictGraph( ...
    C.neighborGraph,C.interferenceMatrix);
T=generateElcsWitnessTrace(base.net.seed,C);
native=buildElcsWitnessContinuousSchedule(C,T,base.swarm.T);
arm=R.arms(strcmp({R.arms.id},R.clockArm));
[cfg,method,label,details,Q]=applyExp23cWitnessClockArm( ...
    base,arm,native,trace,R);

Z=applySharedDataLossToReplaySchedule(Q,trace,0);
assert(isequal(Z.dataSuccessMask,Q.dataSuccessMask));
assert(isequal(Z.dataErasureMask,Q.dataErasureMask));
assert(Z.dataLossOverlayErasureCount==0 && ...
    Z.dataLossOverlayTraceHashExact==trace.hashExact);
fprintf('    ok   zero-probability overlay preserves every replay outcome\n');
checks=checks+1;

L=applySharedDataLossToReplaySchedule(Q,trace,1);
eligible=nnz(Q.dataSuccessMask);
assert(L.dataLossOverlayErasureCount==eligible);
assert(nnz(L.dataSuccessMask)==0 && ...
    isequal(L.dataCollisionMask,Q.dataCollisionMask));
assert(L.expectedDataRecipientErasure== ...
    Q.expectedDataRecipientErasure+eligible);
fprintf('    ok   unit-probability overlay erases successes, never collisions\n');
checks=checks+1;

Q=applySharedDataLossToReplaySchedule(Q,trace,0.05);
cfg.shared.serviceScheduler.dstrSchedule=Q;
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
meta=struct('stage','contract','scenario','n5', ...
    'scenarioLabel','N5','family','ELCS-W loss overlay', ...
    'arm','candidate','pointIndex',1,'parameterValue',0.05);
[row,out]=runExp23cWitnessClosedLoopCell( ...
    cfg,method,label,meta,trace,details);
assert(row.ELCSW_DATA_OUTCOME_MISMATCHES==0);
assert(row.ELCSW_OBSERVED_DATA_RECIPIENT_ERASURE== ...
    row.ELCSW_EXPECTED_DATA_RECIPIENT_ERASURE);
assert(row.ELCSW_DATA_LOSS_OVERLAY_ERASURES>0);
assert(row.ELCSW_DATA_LOSS_OVERLAY_TRACE_HASH_EXACT== ...
    row.TRACE_HASH_EXACT);
fprintf('    ok   closed-loop replay exactly consumes shared-trace erasures\n');
checks=checks+1;

fprintf('\ntest_elcs_loss_overlay_contracts: PASS (%d checks)\n',checks);
