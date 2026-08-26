%% TEST_SETPOINT_INTERFACE
%
% Checks the 6-DOF interface before any EXP09A number is believed.
%
% The dangerous failures here are quiet ones: an interface that freezes the
% position reference still produces a stable, plausible-looking trajectory,
% just a worse one, and the gap would be read as "6-DOF is harder" instead
% of "the interface is wrong". So the reference algebra is checked directly
% rather than inferred from tracking error.
%
% Results accumulate in plain arrays. A local function in a script does NOT
% share the script workspace, so a helper that sets a pass flag updates its
% own copy and every run reports PASS.
%
% ============================================================

startup;

fprintf('\n');
fprintf('============================================================\n');
fprintf('test_setpoint_interface\n');
fprintf('============================================================\n\n');

verdict = @(f) subsref({'FAIL','ok'}, struct('type','{}','subs',{{f+1}}));

cfg = defaultConfig();

dt    = cfg.swarm.dt;
ratio = 10;
dtIn  = dt / ratio;


%% ============================================================
% [1] Reference algebra
% ============================================================

pk = [1.0; -2.0; 0.5];
vk = [0.3;  0.1; -0.2];
ac = [0.7; -0.4;  0.9];

r0  = setpointFromAccel(pk, vk, ac, 0,  0);
rh  = setpointFromAccel(pk, vk, ac, dt/2, 0);
r1  = setpointFromAccel(pk, vk, ac, dt, 0);

checks = { ...
    isequal(r0.pos, pk),                        'at tau = 0 the reference is the outer sample position'; ...
    isequal(r0.vel, vk),                        'at tau = 0 the reference is the outer sample velocity'; ...
    isequal(r0.acc, ac),                        'the held acceleration passes through unchanged'; ...
    norm(r1.vel - (vk + ac*dt)) < 1e-14,        'velocity reference is the exact integral of the command'; ...
    norm(r1.pos - (pk + vk*dt + 0.5*ac*dt^2)) < 1e-14, ...
                                                'position reference is the exact double integral'; ...
    norm(rh.pos - pk) > 1e-6,                   'the position reference MOVES within the interval'};


%% ============================================================
% [2] The reference is NOT the locked semi-implicit Euler update
%
% Stated as a positive check, because the difference is a modelling fact
% that must not be papered over. Semi-implicit Euler lands at
% pk + vk*dt + dt^2*a; the analytic reference lands at
% pk + vk*dt + 0.5*dt^2*a. They differ by 0.5*dt^2*a per step.
% ============================================================

vEuler = vk + dt*ac;
pEuler = pk + dt*vEuler;

gap = norm(pEuler - r1.pos);

checks = [checks; { ...
    abs(gap - norm(0.5*dt^2*ac)) < 1e-14, ...
        'analytic reference differs from semi-implicit Euler by exactly 0.5*dt^2*a'; ...
    gap > 0, ...
        'the two are NOT bit-identical, and the code does not claim they are'}];


%% ============================================================
% [3] Tracking: ep and ev stay small and do NOT grow with tau
%
% A frozen reference shows up here as ep growing monotonically across the
% interval, because it would be measuring the drone's own displacement.
% ============================================================

x = zeros(12,1);
x(1:3) = pk;
x(4:6) = vk;

epNorm = zeros(ratio,1);
evNorm = zeros(ratio,1);

for m = 1:ratio

    tau = (m-1)*dtIn;

    ref = setpointFromAccel(pk, vk, ac, tau, 0);

    epNorm(m) = norm(ref.pos - x(1:3));
    evNorm(m) = norm(ref.vel - x(4:6));

    u = quadCascadedController(x, ref, cfg);

    k1 = quad6dofDynamics(x,             u, cfg.quad);
    k2 = quad6dofDynamics(x + dtIn/2*k1, u, cfg.quad);
    k3 = quad6dofDynamics(x + dtIn/2*k2, u, cfg.quad);
    k4 = quad6dofDynamics(x + dtIn*k3,   u, cfg.quad);

    x = x + (dtIn/6)*(k1 + 2*k2 + 2*k3 + k4);

end

drift = norm(vk)*dt;

checks = [checks; { ...
    epNorm(1) < 1e-12,          'tracking error starts at zero'; ...
    max(epNorm) < 0.2*drift,    'position error stays far below the drift a frozen reference would show'; ...
    max(evNorm) < 0.5,          'velocity error stays bounded'; ...
    all(isfinite(x)),           'the inner loop produces finite state'}];


%% ============================================================
% [4] Timing hierarchy
% ============================================================

checks = [checks; { ...
    abs(ratio*dtIn - dt) < 1e-15,   'inner steps tile the outer step exactly'; ...
    ratio == 10,                    'the ratio is 10 : 1'; ...
    abs(dt - 0.02) < 1e-15,         'outer step is 50 Hz'; ...
    abs(dtIn - 0.002) < 1e-15,      'inner step is 500 Hz'}];


%% ============================================================
% [5] sixdof disabled is bit-identical to the locked simulator
% ============================================================

base = applyTopologyConfig(defaultConfig(), 5, 'ring2');
base.net.seed = 777;
base.net.packetLoss = 0.20;
base.net.delay = 0.08;
base.net.useTrace = true;
base.ack.useTrace = true;
base.ack.delay = 0.08;
base.causal.useAdaptiveScale   = true;
base.causal.useAckFeedback     = true;
base.causal.innovationPriority = true;

oLocked = simSwarmAoICausal(base);

cOff = base;
cOff.sixdof.enable = false;
cOff.sixdof.ratio  = ratio;

oOff = simSwarm6DOF(cOff, 'Causal-v3');

checks = [checks; { ...
    isequal(oLocked.P, oOff.P),                 'sixdof off reproduces the locked trajectory bit-identically'; ...
    oLocked.txCount == oOff.txCount,            'sixdof off reproduces txCount'; ...
    isempty(oOff.six) || ~isfield(oOff.six,'x'),'sixdof off allocates no 6-DOF state'}];


%% ============================================================
% [6] Periodic schedule is exact under 6-DOF
%
% P10 and P20 must fire on their own clock regardless of the dynamics. If
% 6-DOF changed the schedule, every DI-versus-6DOF comparison would be
% confounded at the source.
% ============================================================

cOn = base;
cOn.sixdof.enable = true;
cOn.sixdof.ratio  = ratio;

p10di = simSwarm6DOF(setfield(cOff, 'net', setfield(cOff.net,'commPeriod',0.10)), 'P10'); %#ok<SFLD>
p106d = simSwarm6DOF(setfield(cOn,  'net', setfield(cOn.net, 'commPeriod',0.10)), 'P10'); %#ok<SFLD>

p20di = simSwarm6DOF(setfield(cOff, 'net', setfield(cOff.net,'commPeriod',0.05)), 'P20'); %#ok<SFLD>
p206d = simSwarm6DOF(setfield(cOn,  'net', setfield(cOn.net, 'commPeriod',0.05)), 'P20'); %#ok<SFLD>

checks = [checks; { ...
    p10di.txCount == p106d.txCount,     'P10 transmits exactly as often under 6-DOF'; ...
    p20di.txCount == p206d.txCount,     'P20 transmits exactly as often under 6-DOF'; ...
    p206d.txCount > p106d.txCount,      'P20 still transmits more often than P10'}];


%% ============================================================
% [7] CRN traces are identical between DI and 6-DOF
%
% The trace is drawn from the seed alone, so it must not depend on the
% dynamics. If it did, the comparator and the 6-DOF run would face
% different channels and no delta would be interpretable.
% ============================================================

fwdDI = generateNetworkTrace(cOff);
fwd6D = generateNetworkTrace(cOn);

revDI = generateAckTrace(cOff);
rev6D = generateAckTrace(cOn);

checks = [checks; { ...
    fwdDI.hash == fwd6D.hash,   'forward CRN trace hash is identical for DI and 6-DOF'; ...
    revDI.hash == rev6D.hash,   'reverse CRN trace hash is identical for DI and 6-DOF'; ...
    fwdDI.hash ~= revDI.hash,   'forward and reverse traces remain independent'}];


%% ============================================================
% [8] 6-DOF actually runs, and the metrics come out
% ============================================================

o6 = simSwarm6DOF(cOn, 'Causal-v3');

Q = compute6DOFMetrics(o6, cOn);

checks = [checks; { ...
    Q.sixdof,                       '6-DOF metrics are produced'; ...
    ~Q.diverged,                    'the Clean-ish reference run does not diverge'; ...
    isfinite(Q.saturation),         'saturation is finite'; ...
    numel(Q.perDronePeakSat) == 4,  'per-drone peak saturation covers every follower'; ...
    isfinite(Q.controlEffort),      'control effort is finite'; ...
    ~any(isnan(o6.P(:))),           'no NaN in the 6-DOF trajectory'}];


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
    fprintf('test_setpoint_interface: PASS (%d checks)\n', numel(okFlags));
else
    fprintf('test_setpoint_interface: FAIL (%d of %d checks)\n', nBad, numel(okFlags));
    for q = find(~okFlags(:)')
        fprintf('    failed: %s\n', okNames{q});
    end
    error('test_setpoint_interface failed.');
end
