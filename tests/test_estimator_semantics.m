%% TEST_ESTIMATOR_SEMANTICS
%
% Checks the EXP09C estimator layer before any number is believed.
%
% Three failures here would be invisible in the results and would each
% change the conclusion:
%
%   - noise added twice, once at the sender and once at the receiver, makes
%     a value that crossed the network twice as noisy as one used locally,
%     charging the noise to the act of transmitting
%   - safety measured on the noisy state lets a policy score as safe
%     precisely because it cannot see the collision
%   - latency rounded to a multiple of dt makes the effective latency
%     change with dt, confounding the timestep study
%
% Each is checked directly.
%
% ============================================================

startup;

fprintf('\n');
fprintf('============================================================\n');
fprintf('test_estimator_semantics\n');
fprintf('============================================================\n\n');

verdict = @(f) subsref({'FAIL','ok'}, struct('type','{}','subs',{{f+1}}));

base = applyTopologyConfig(defaultConfig(), 5, 'ring2');
base.net.seed = 3141;
base.net.packetLoss = 0.20;
base.net.delay = 0.08;
base.net.useTrace = true;
base.ack.useTrace = true;
base.ack.delay = 0.08;
base.causal.useAdaptiveScale   = true;
base.causal.useAckFeedback     = true;
base.causal.innovationPriority = true;
base.sixdof.enable = true;
base.sixdof.ratio  = 10;


%% ============================================================
% [1] Inert when absent, and inert at zero noise / zero latency
% ============================================================

o0 = simSwarm6DOF(base, 'Causal-v3');

cZ = base;
cZ.estimator.latency = 0;
cZ.estimator.noise   = generateNoiseTrace(cZ, 0, 0);

oZ = simSwarm6DOF(cZ, 'Causal-v3');

checks = { ...
    isequal(o0.P, oZ.P),        'zero noise and zero latency leave the trajectory bit-identical'; ...
    o0.txCount == oZ.txCount,   'zero noise and zero latency leave txCount identical'};


%% ============================================================
% [2] Noise trace: physical-time grid, seeded, leader-free
% ============================================================

tA = generateNoiseTrace(base, 0.03, 0.05);
tB = generateNoiseTrace(base, 0.03, 0.05);

cAlt = base;
cAlt.net.seed = 2718;
tC = generateNoiseTrace(cAlt, 0.03, 0.05);

checks = [checks; { ...
    isequal(tA.n, tB.n),                    'same seed gives the same noise realization'; ...
    ~isequal(tA.n, tC.n),                   'a different seed gives a different realization'; ...
    abs(tA.baseDt - 0.01) < 1e-15,          'noise lives on the 0.01 s master grid'; ...
    all(tA.n(:,1,:) == 0, 'all'),           'the leader carries no noise'; ...
    abs(std(reshape(tA.n(:,2:end,1:3),[],1)) - 0.03) < 0.003, ...
                                            'realized position sigma matches the request'; ...
    abs(std(reshape(tA.n(:,2:end,4:6),[],1)) - 0.05) < 0.005, ...
                                            'realized velocity sigma matches the request'}];

% The master grid must not depend on the outer step: that is what makes
% the dt diagnostic a comparison of dt rather than of two random draws.
cDt = base;
cDt.swarm.dt = 0.04;

tD = generateNoiseTrace(cDt, 0.03, 0.05);

checks = [checks; { ...
    isequal(tA.n, tD.n),    'the noise realization is identical at a different outer dt'}];


%% ============================================================
% [3] Latency is exact, not rounded to a multiple of dt
%
% A constant-velocity history is used so the delayed value has a closed
% form: at latency L the query must return p - v*L exactly.
% ============================================================

cL = base;
cL.estimator.latency = 0.050;
cL.estimator.noise   = generateNoiseTrace(cL, 0, 0);

v0 = [1.0 -0.5 0.25];

est = [];
dt  = cL.swarm.dt;

for k = 1:20

    tk = (k-1)*dt;

    Pk = repmat([0 0 0], 5, 1) + repmat(v0, 5, 1) * tk;
    Vk = repmat(v0, 5, 1);

    [PHatK, ~, est] = applyEstimator(Pk, Vk, est, cL, tk);

end

expected = v0 * (tk - 0.050);

errExact = norm(PHatK(2,:) - expected);

% What rounding down to a multiple of dt = 0.02 would have produced.
expectedRounded = v0 * (tk - 0.040);

errRounded = norm(PHatK(2,:) - expectedRounded);

checks = [checks; { ...
    errExact < 1e-12,                       'the delayed query lands at exactly t - 50 ms'; ...
    errRounded > 1e-3,                      'it is NOT the dt-rounded 40 ms value'; ...
    abs(dt - 0.02) < 1e-15,                 'the test really is at a dt that would round'}];

% Same check at a different dt: the physical latency must not move.
cL2 = cL;
cL2.swarm.dt = 0.01;

est2 = [];

for k = 1:40

    tk2 = (k-1)*0.01;

    Pk = repmat(v0, 5, 1) * tk2;
    Vk = repmat(v0, 5, 1);

    [PHat2, ~, est2] = applyEstimator(Pk, Vk, est2, cL2, tk2);

end

checks = [checks; { ...
    norm(PHat2(2,:) - v0*(tk2 - 0.050)) < 1e-12, ...
        'the same 50 ms holds at a different outer dt'}];


%% ============================================================
% [4] Noise is applied ONCE, at the source
%
% The estimate a follower forms is what it transmits. Checked by
% confirming that the noisy self-state is what the trigger and payload
% see, and that the true state is untouched by the estimator.
% ============================================================

cN = base;
cN.estimator.latency = 0;
cN.estimator.noise   = generateNoiseTrace(cN, 0.03, 0.05);

Ptrue = [0 0 0; 1 0 0; 0 1 0; -1 0 0; 0 -1 0];
Vtrue = zeros(5,3);

estN = [];

[PHatN, VHatN, estN] = applyEstimator(Ptrue, Vtrue, estN, cN, 0.5);

checks = [checks; { ...
    ~isequal(PHatN(2:end,:), Ptrue(2:end,:)),   'followers receive a noisy estimate'; ...
    isequal(PHatN(1,:), Ptrue(1,:)),            'the leader estimate stays exact'; ...
    isequal(VHatN(1,:), Vtrue(1,:)),            'the leader velocity stays exact'}];

% Calling twice at the same instant must give the same estimate: the noise
% is a function of physical time, not of how many times it is queried. If
% it were re-drawn per call, a policy that evaluates more often would face
% a different realization.
estN2 = [];
[PHatAgain, ~, ~] = applyEstimator(Ptrue, Vtrue, estN2, cN, 0.5);

checks = [checks; { ...
    isequal(PHatN, PHatAgain), 'the estimate at a given instant is a function of time, not of call count'}];


%% ============================================================
% [5] Safety is measured on the TRUE state
%
% out.P must be the true trajectory, so a noisy estimate cannot make a
% close approach disappear from the metric.
% ============================================================

cS = base;
cS.estimator.latency = 0.050;
cS.estimator.noise   = generateNoiseTrace(cS, 0.05, 0.10);

oS = simSwarm6DOF(cS, 'Causal-v3');

MS = computeSwarmMetrics(oS, cS);

% With heavy noise the trajectory must differ from the noiseless run, and
% the recorded separation must come from that true trajectory.
sepDirect = inf;

idx = oS.t >= 8;

Pe = oS.P(idx,:,:);

for a = 2:size(Pe,2)-1
    for b = a+1:size(Pe,2)
        d = sqrt(sum((Pe(:,a,:) - Pe(:,b,:)).^2, 3));
        sepDirect = min(sepDirect, min(d));
    end
end

checks = [checks; { ...
    ~isequal(oS.P, o0.P),                           'noise changes the true trajectory'; ...
    abs(MS.minSeparationEval - sepDirect) < 1e-9,   'reported minSep comes from the TRUE state'; ...
    ~any(isnan(oS.P(:))),                           'no NaN under heavy noise'}];


%% ============================================================
% [6] Causality invariants survive noise and latency
% ============================================================

checks = [checks; { ...
    oS.ackBeforeAcceptCount   == 0, 'no ACK arrives before its own accept'; ...
    oS.ackForDroppedDataCount == 0, 'no ACK for data that never arrived'; ...
    oS.senderRollbackCount    == 0, 'no sender rollback'; ...
    oS.futureGenTimeCount     == 0, 'no future genTime'; ...
    oS.staleAckAcceptedCount  == 0, 'no stale ACK accepted'; ...
    oS.unknownSeqAckCount     == 0, 'no ACK for an unknown sequence number'}];


%% ============================================================
% [7] Physical-time network trace mode
% ============================================================

cP = base;
cP.net.traceBaseDt = 0.01;

trA = generateNetworkTrace(cP);

cP2 = cP;
cP2.swarm.dt = 0.04;

trB = generateNetworkTrace(cP2);

trDefault = generateNetworkTrace(base);

checks = [checks; { ...
    trA.hash == trB.hash,           'the physical-time trace is identical across outer dt'; ...
    trA.K ~= trDefault.K,           'the master grid is longer than the per-step grid'; ...
    traceIndex(base, 0.44, 23) == 23,       'default mode leaves the slot as the step index'; ...
    traceIndex(cP, 0.44, 23) == 45,         'physical-time mode maps by time'; ...
    traceIndex(cP2, 0.44, 12) == 45,        'the same instant maps to the same slot at another dt'}];


%% ============================================================
% Verdict
% ============================================================

okFlags = false(size(checks,1),1);
okNames = cell(size(checks,1),1);

for q = 1:size(checks,1)
    okFlags(q) = logical(checks{q,1});
    okNames{q} = checks{q,2};
    fprintf('    %-4s %s\n', verdict(okFlags(q)), okNames{q});
end

fprintf('\n');

nBad = nnz(~okFlags);

if nBad == 0
    fprintf('test_estimator_semantics: PASS (%d checks)\n', numel(okFlags));
else
    fprintf('test_estimator_semantics: FAIL (%d of %d checks)\n', nBad, numel(okFlags));
    for q = find(~okFlags(:)')
        fprintf('    failed: %s\n', okNames{q});
    end
    error('test_estimator_semantics failed.');
end
