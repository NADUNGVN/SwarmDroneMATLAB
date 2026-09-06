% TEST_ELCS_BACKGROUND_LOAD_CONTRACTS Shared occupancy on ELCS-W replay.
startup;
fprintf('\n============================================================\n');
fprintf('test_elcs_background_load_contracts\n');
fprintf('============================================================\n\n');

checks=0;
loadProbability=0.15;
R=exp23cWitnessClosedLoopRegistry();
base=applyExp21dClosedLoopCell(R.cells(1).id,16065000);
base.mac.backgroundLoad=loadProbability;
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
arm=R.arms(strcmp({R.arms.id},R.clockArm));
offset=(2*reshape(trace.exp21cClockOffsetU(1,:),[],1)-1)*R.maxOffsetSec;
drift=(2*reshape(trace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
spec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'leadTimeSec',R.clockLeadTimeSec);
T0=generateElcsWitnessTrace(base.net.seed,C);
[T,B]=applySharedBackgroundToElcsWitnessTrace( ...
    T0,C,trace,spec,loadProbability);
assert(T.hashExact~=T0.hashExact && B.totalPotentialAttemptHits>0);
assert(B.sharedTraceHashExact==trace.hashExact && ...
    B.backgroundLoad==loadProbability);
fprintf('    ok   one absolute occupancy field reaches control and DATA traces\n');
checks=checks+1;

Z=applySharedBackgroundToElcsWitnessTrace(T0,C,trace,spec,0);
assert(Z.hashExact==T0.hashExact);
fprintf('    ok   zero load preserves the original ELCS-W trace bit-exactly\n');
checks=checks+1;

native=buildElcsWitnessContinuousSchedule(C,T,base.swarm.T);
native.backgroundOverlay=B;
native.hashExact=realizationHash([native.hashExact;B.hashExact]);
[cfg,method,label,details]=applyExp23cWitnessClockArm( ...
    base,arm,native,trace,R);
meta=struct('stage','contract','scenario','n5', ...
    'scenarioLabel','N5','family','ELCS-W background load', ...
    'arm','candidate','pointIndex',1,'parameterValue',loadProbability);
[row,out]=runExp23cWitnessClosedLoopCell( ...
    cfg,method,label,meta,trace,details);
K=floor(base.swarm.T/base.mac.slotTime);
expected=nnz(trace.backgroundU(1:K)<loadProbability)*base.mac.slotTime;
assert(abs(row.BACKGROUND_BUSY_TIME-expected)<1e-9);
assert(row.ELCSW_BACKGROUND_TRACE_HASH_EXACT==row.TRACE_HASH_EXACT);
assert(row.ELCSW_DATA_OUTCOME_MISMATCHES==0 && ...
    row.ELCSW_MANAGEMENT_ACCOUNTING_CLOSE==1);
assert(row.CHANNEL_UTIL<=row.OFFERED_UTIL+ ...
    row.BACKGROUND_BUSY_TIME/base.swarm.T+1e-9);
fprintf('    ok   replay charges exact background time and preserves accounting\n');
checks=checks+1;

M1=applyMarkovBackgroundStateTrace(trace,0.004,0.02);
M2=applyMarkovBackgroundStateTrace(trace,0.004,0.02);
assert(M1.hashExact==M2.hashExact && ...
    M1.backgroundStateHashExact==M2.backgroundStateHashExact);
runs=1+nnz(diff(M1.measuredBackgroundActive)~=0);
assert(any(M1.measuredBackgroundActive) && runs<numel(M1.backgroundU)/10);
fprintf('    ok   Markov occupancy is deterministic, stationary and burst-correlated\n');
checks=checks+1;

fprintf('\ntest_elcs_background_load_contracts: PASS (%d checks)\n',checks);
