%% TEST_EXP21B_CONTINUOUS_TIMING_CONTRACTS Adversarial timing cases.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp21b_continuous_timing_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);
D=3.072e-3;
theta=0.25e-3;

%% Zero-clock equivalence and physical slot duration.
c=baseCfg(3,D,0,0.030);
z=simulateContinuousLocalTdma(c);
expected=(0:D:0.030-D+1e-12)';
checks(end+1,:)={z.collisionFrames==0 && ...
    max(abs(z.startTime-expected))<1e-12, ...
    'zero offset/drift reproduces exact nominal half-open intervals'};
checks(end+1,:)={abs(z.slotDurationSec-D)<1e-15 && ...
    abs(z.frameDurationSec-3*D)<1e-15, ...
    'ownership slot uses DATA airtime rather than the 1-ms MAC quantum'};

%% Offset witness below and at the sufficient bound.
c=baseCfg(2,D,0,0.050);
c.clockOffsetSec=[-theta;theta];
bad=simulateContinuousLocalTdma(c);
B=continuousTdmaGuardBound(theta,0,c.horizonSec);
c.guardTimeSec=B.safeGuardSec;
safe=simulateContinuousLocalTdma(c);
checks(end+1,:)={bad.collisionFrames>0 && ...
    bad.temporalOverlapPairs>0, ...
    'opposing residual offsets collide with zero guard'};
checks(end+1,:)={abs(B.safeGuardSec-2*theta)<1e-15 && ...
    safe.collisionFrames==0, ...
    'half-open intervals are collision-free at the offset guard bound'};

%% Drift accumulation and synchronization.
c=baseCfg(2,D,0,12);
c.clockDriftPpm=[-40;40];
driftBad=simulateContinuousLocalTdma(c);
B12=continuousTdmaGuardBound(0,40,12);
c.guardTimeSec=B12.safeGuardSec;
driftSafe=simulateContinuousLocalTdma(c);
checks(end+1,:)={driftBad.collisionFrames>0 && ...
    driftSafe.collisionFrames==0, ...
    'opposing drift collides late without guard and is safe at G_safe'};

c=baseCfg(2,D,0,12);
c.clockDriftPpm=[-40;40];
c.syncPeriodSec=0.5;
B05=continuousTdmaGuardBound(0,40,0.5);
c.guardTimeSec=B05.safeGuardSec;
syncSafe=simulateContinuousLocalTdma(c);
checks(end+1,:)={B05.safeGuardSec<B12.safeGuardSec && ...
    syncSafe.collisionFrames==0, ...
    'periodic synchronization reduces required guard and prevents overlap'};

%% Receiver-specific collision semantics.
c=baseCfg(2,D,0,0.020);
c.assignedSlot=[1;1];
c.topology=eye(2)>0;
c.interferenceMatrix=eye(2)>0;
sparse=simulateContinuousLocalTdma(c);
c.interferenceMatrix=true(2);
full=simulateContinuousLocalTdma(c);
checks(end+1,:)={sparse.temporalOverlapPairs>0 && ...
    sparse.collisionFrames==0 && full.collisionFrames>0, ...
    'positive temporal overlap corrupts only declared interfering receivers'};

%% Clock equation, deterministic replay, and accounting.
repeat=simulateContinuousLocalTdma(c);
checks(end+1,:)={repeat.realizationHash==full.realizationHash && ...
    repeat.configHash==full.configHash, ...
    'identical explicit clock inputs are bit-identical'};
checks(end+1,:)={full.maxClockEquationResidual<1e-12 && ...
    full.busyTimeSec<=full.offeredAirtimeSec+1e-12 && ...
    abs(full.channelUtilization- ...
    full.busyTimeSec/full.horizonSec)<1e-15, ...
    'clock equation and offered/busy interval accounting close'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error(['test_exp21b_continuous_timing_contracts: %d of %d ' ...
        'checks failed.'],nnz(~flags),numel(flags));
end
fprintf('\ntest_exp21b_continuous_timing_contracts: PASS (%d checks)\n', ...
    numel(flags));


function c=baseCfg(N,D,G,H)

c=struct();
c.N=N;
c.horizonSec=H;
c.dataAirtimeSec=D;
c.guardTimeSec=G;
c.frameSlots=N;
c.assignedSlot=(1:N)';
c.clockOffsetSec=zeros(N,1);
c.clockDriftPpm=zeros(N,1);
c.syncPeriodSec=inf;
c.topology=true(N)-eye(N)>0;
c.interferenceMatrix=true(N);
c.epochLeadTimeSec=0;

end
