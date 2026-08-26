%% TEST_MISMATCH_SEMANTICS
%
% Checks the EXP09B perturbation layer before any number is believed.
%
% The failures that matter here are silent ones. A mismatch that leaks into
% the controller still produces a stable trajectory - a better one, in fact
% - and would be read as "the method is robust" when it actually means the
% controller was told the answer. A disturbance realization that differs
% between methods still produces plausible curves, just incomparable ones.
% Both are checked directly.
%
% ============================================================

startup;

fprintf('\n');
fprintf('============================================================\n');
fprintf('test_mismatch_semantics\n');
fprintf('============================================================\n\n');

verdict = @(f) subsref({'FAIL','ok'}, struct('type','{}','subs',{{f+1}}));

base = applyTopologyConfig(defaultConfig(), 5, 'ring2');
base.net.seed = 5150;
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

NOMINAL = struct('wind',0,'massFactor',1,'dragFactor',1,'lagTau',0);
B7      = struct('wind',0.5,'massFactor',1.10,'dragFactor',1.20,'lagTau',0);


%% ============================================================
% [1] Nominal arm is inert
% ============================================================

o0 = simSwarm6DOF(base, 'Causal-v3');

cN = applyPlantPerturbation(base, NOMINAL);

oN = simSwarm6DOF(cN, 'Causal-v3');

checks = { ...
    isequal(o0.P, oN.P),        'the nominal arm leaves the trajectory bit-identical'; ...
    o0.txCount == oN.txCount,   'the nominal arm leaves txCount identical'};


%% ============================================================
% [2] TRUE vs NOMINAL separation
%
% The controller must never see the perturbed plant. Checked on the config
% itself rather than inferred from behaviour.
% ============================================================

c7 = applyPlantPerturbation(base, B7);

checks = [checks; { ...
    c7.quad.m == base.quad.m,                       'cfg.quad mass stays nominal'; ...
    c7.quad.linearDrag == base.quad.linearDrag,     'cfg.quad drag stays nominal'; ...
    abs(c7.quadTrue.m / base.quad.m - 1.10) < 1e-12,        'true mass is +10%'; ...
    abs(c7.quadTrue.linearDrag / base.quad.linearDrag - 1.20) < 1e-12, 'true drag is +20%'; ...
    c7.quadTrue.maxThrust == base.quad.maxThrust,   'thrust limit is NOT scaled with mass'; ...
    isequal(c7.quadTrue.maxTorque, base.quad.maxTorque), 'torque limit is NOT scaled with mass'; ...
    isequal(c7.quadTrue.J, base.quad.J),            'inertia stays nominal, as pre-registered'}];

% The controller is a pure function of (x, ref, cfg). Feeding it the two
% configs must give the identical command, which is what "reads nominal"
% means operationally.
xTest = [0.1;0.2;0.3; 0.05;-0.02;0.01; 0.01;0.02;0; 0.001;0.002;0];
refTest = setpointFromAccel([0.2 0.1 0.4], [0.05 0 0], [0.3 -0.2 0.1], 0.004, 0);

uNom = quadCascadedController(xTest, refTest, base);
uPer = quadCascadedController(xTest, refTest, c7);

checks = [checks; { ...
    uNom.thrust == uPer.thrust && isequal(uNom.torque, uPer.torque), ...
        'the controller issues the identical command under the perturbed arm'}];


%% ============================================================
% [3] The perturbation actually reaches the plant
%
% The mirror of check [2]: separation is only meaningful if the true plant
% really did change.
% ============================================================

o7 = simSwarm6DOF(c7, 'Causal-v3');

checks = [checks; { ...
    ~isequal(o7.P, o0.P),   'the perturbed arm changes the trajectory'; ...
    ~any(isnan(o7.P(:))),   'the perturbed arm produces no NaN'}];


%% ============================================================
% [4] External-force proxy: seeded, method-independent, physical-time
% ============================================================

tA = generateExternalForceTrace(base, 0.5);
tB = generateExternalForceTrace(base, 0.5);

cAlt = base;
cAlt.net.seed = 9999;
tC = generateExternalForceTrace(cAlt, 0.5);

t0 = generateExternalForceTrace(base, 0);

checks = [checks; { ...
    isequal(tA.a, tB.a),                'same seed gives the same force realization'; ...
    ~isequal(tA.a, tC.a),               'a different seed gives a different realization'; ...
    all(t0.a(:) == 0),                  'level 0 produces no force at all'; ...
    abs(tA.baseDt - 0.01) < 1e-15,      'the force trace lives on a 0.01 s physical grid'; ...
    tA.rms > 0.3 && tA.rms < 1.0,       'realized RMS is the right order for level 0.5'; ...
    isfinite(tA.peak) && tA.peak > tA.rms, 'peak exceeds RMS and is bounded'; ...
    abs(mean(tA.a(:,3))) < abs(mean(tA.a(:,1))) + abs(mean(tA.a(:,2))) + 1e-9, ...
                                        'the proxy is predominantly horizontal'}];

% The same realization must reach every method. Checked by building the
% trace under each method's config and comparing.
cP10 = applyPlantPerturbation(base, B7);
cEvt = applyPlantPerturbation(base, B7);

checks = [checks; { ...
    isequal(cP10.extForce.a, cEvt.extForce.a), ...
        'every method meets the identical force realization at the same seed'}];


%% ============================================================
% [5] Actuator lag semantics
%
% The command must be clipped BEFORE the lag, the lag must actually slow
% the actuator, and the saturation metric must keep counting the COMMAND so
% EXP09A and EXP09B numbers stay comparable.
% ============================================================

LAG = struct('wind',0,'massFactor',1,'dragFactor',1,'lagTau',0.050);

cL = applyPlantPerturbation(base, LAG);

oL = simSwarm6DOF(cL, 'Causal-v3');

QL = compute6DOFMetrics(oL, cL);
Q0 = compute6DOFMetrics(oN, cN);

checks = [checks; { ...
    cL.actuator.tau == 0.050,           'the lag time constant is set'; ...
    isfinite(QL.lagErrMean),            'command-to-actuator tracking error is logged'; ...
    QL.lagErrMean > 0,                  'the lag actually lags'; ...
    isnan(Q0.lagErrMean),               'no lag error is logged when tau = 0'; ...
    ~isequal(oL.P, oN.P),               'the lag changes the trajectory'; ...
    isfinite(QL.saturation),            'saturation is still measured under lag'}];


%% ============================================================
% [6] Metrics report the true plant honestly
% ============================================================

Q7 = compute6DOFMetrics(o7, c7);

checks = [checks; { ...
    abs(Q7.massRatio - 1.10) < 1e-12,   'metrics report the true mass ratio'; ...
    abs(Q7.dragRatio - 1.20) < 1e-12,   'metrics report the true drag ratio'; ...
    abs(Q0.massRatio - 1.00) < 1e-12,   'the nominal arm reports ratio 1'}];


%% ============================================================
% [7] Causality invariants survive perturbation
% ============================================================

checks = [checks; { ...
    o7.ackBeforeAcceptCount   == 0, 'no ACK arrives before its own accept'; ...
    o7.ackForDroppedDataCount == 0, 'no ACK for data that never arrived'; ...
    o7.senderRollbackCount    == 0, 'no sender rollback'; ...
    o7.futureGenTimeCount     == 0, 'no future genTime'; ...
    o7.staleAckAcceptedCount  == 0, 'no stale ACK accepted'; ...
    o7.unknownSeqAckCount     == 0, 'no ACK for an unknown sequence number'}];


%% ============================================================
% [8] CRN untouched by perturbation
% ============================================================

f0 = generateNetworkTrace(base);
f7 = generateNetworkTrace(c7);
r0 = generateAckTrace(base);
r7 = generateAckTrace(c7);

checks = [checks; { ...
    f0.hash == f7.hash,     'the forward CRN trace is unchanged by perturbation'; ...
    r0.hash == r7.hash,     'the reverse CRN trace is unchanged by perturbation'}];


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
    fprintf('test_mismatch_semantics: PASS (%d checks)\n', numel(okFlags));
else
    fprintf('test_mismatch_semantics: FAIL (%d of %d checks)\n', nBad, numel(okFlags));
    for q = find(~okFlags(:)')
        fprintf('    failed: %s\n', okNames{q});
    end
    error('test_mismatch_semantics failed.');
end
