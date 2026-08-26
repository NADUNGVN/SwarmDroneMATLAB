%% TEST_BLACKOUT_SEMANTICS
%
% Checks the EXP08C node blackout does what it claims and nothing more.
%
% "The node went quiet" is easy to fake in ways that look right in
% aggregate: dropping only DATA, or only one direction, or quietly editing
% the adjacency. Each of those still produces a plausible degradation
% curve, so each is checked directly rather than inferred from a metric.
%
% Results accumulate in plain arrays. A local function in a script does
% NOT share the script workspace, so a helper that sets a `pass` flag
% updates its own copy and every run reports PASS regardless - which would
% hide exactly the assertions this file exists to make.
%
% ============================================================

startup;

fprintf('\n');
fprintf('============================================================\n');
fprintf('test_blackout_semantics\n');
fprintf('============================================================\n\n');

okFlags = false(0,1);
okNames = {};

verdict = @(f) subsref({'FAIL','ok'}, struct('type','{}','subs',{{f+1}}));


base = applyTopologyConfig(defaultConfig(), 10, 'ring2');
base.net.seed = 4242;
base.net.packetLoss = 0.20;
base.net.delay = 0.08;
base.net.useTrace = true;
base.ack.useTrace = true;
base.ack.delay = 0.08;
base.ack.assertInvariants = true;
base.causal.useAdaptiveScale   = true;
base.causal.useAckFeedback     = true;
base.causal.innovationPriority = true;


%% ============================================================
% [1] Inert when absent
% ============================================================

fprintf('[1] Fault disabled is inert\n');

o1 = simSwarmAoICausal(base);

c2 = base;
c2.blackout = generateBlackoutRealization(c2, 0, 0);

o2 = simSwarmAoICausal(c2);

checks = { ...
    isequal(o1.P, o2.P),          'nNodes = 0 leaves the trajectory bit-identical'; ...
    o1.txCount == o2.txCount,     'nNodes = 0 leaves txCount identical'};


%% ============================================================
% [2] Realization is seeded and method independent
% ============================================================

a = generateBlackoutRealization(base, 2, 5);
b = generateBlackoutRealization(base, 2, 5);

cAlt = base;
cAlt.net.seed = 9191;

d = generateBlackoutRealization(cAlt, 2, 5);

checks = [checks; { ...
    isequal(a.nodes, b.nodes),                    'same seed gives the same nodes'; ...
    a.tStart == b.tStart && a.tEnd == b.tEnd,     'same seed gives the same timing'; ...
    ~isequal(a.nodes, d.nodes),                   'a different seed gives different nodes'; ...
    ~a.node(1),                                   'the leader is never blacked out'; ...
    numel(a.nodes) == 2,                          'the requested number of nodes is selected'}];


%% ============================================================
% [3] The adjacency is never touched
% ============================================================

c3 = base;
c3.blackout = generateBlackoutRealization(c3, 2, 5);

before = c3.swarm.A;

o3 = simSwarmAoICausal(c3);

checks = [checks; { ...
    isequal(before, c3.swarm.A),   'cfg.swarm.A is unchanged by the run'; ...
    nnz(c3.swarm.A) == nnz(before),'edge count is unchanged'}];


%% ============================================================
% [4] DATA and ACK are blocked in BOTH directions
%
% A packet already in flight when the outage begins is still delivered:
% it left a working antenna before the radio went off, and discarding it
% would model a fault reaching backwards in time. So the window opens one
% propagation delay plus one timestep after tStart, and only after that
% must the ages grow monotonically.
% ============================================================

dark = c3.blackout.nodes(1);

guard = c3.net.delay + c3.swarm.dt;

settled = o3.t >= c3.blackout.tStart + guard & o3.t <= c3.blackout.tEnd;
inWin   = o3.t >= c3.blackout.tStart & o3.t <= c3.blackout.tEnd;

outNbr = find(c3.swarm.A(:, dark) ~= 0);   % receivers fed BY the dark node
inNbr  = find(c3.swarm.A(dark, :) ~= 0);   % transmitters feeding the dark node

ageOut = max(o3.neighborAoI(settled, outNbr, dark), [], 2);
ageIn  = max(o3.neighborAoI(settled, dark, inNbr), [], 3);

ageOut = ageOut(isfinite(ageOut));
ageIn  = ageIn(isfinite(ageIn));

dTx  = o3.txCountLog(find(inWin,1,'last'))  - o3.txCountLog(find(inWin,1,'first'));
dAck = o3.ackCountLog(find(inWin,1,'last')) - o3.ackCountLog(find(inWin,1,'first'));

checks = [checks; { ...
    ~isempty(outNbr) && ~isempty(inNbr),        'the dark node has neighbours to test against'; ...
    all(diff(ageOut) >= -1e-9),                 'no DATA left the dark node during the outage'; ...
    all(diff(ageIn)  >= -1e-9),                 'no DATA reached the dark node during the outage'; ...
    dTx  >= 0,                                  'DATA log is monotonic across the outage'; ...
    dAck >= 0,                                  'ACK log is monotonic across the outage'}];


%% ============================================================
% [5] Dynamics and controller keep running
% ============================================================

moved = any(abs(diff(o3.P(inWin, dark, :), 1, 1)) > 0, 'all');

checks = [checks; { ...
    moved,                              'the dark node keeps moving during the outage'; ...
    ~any(isnan(o3.P), 'all'),           'no NaN anywhere in the trajectory'}];


%% ============================================================
% [6] Causality invariants
% ============================================================

checks = [checks; { ...
    o3.ackBeforeAcceptCount   == 0, 'no ACK arrives before its own accept'; ...
    o3.ackForDroppedDataCount == 0, 'no ACK for data that never arrived'; ...
    o3.senderRollbackCount    == 0, 'no sender rollback'; ...
    o3.futureGenTimeCount     == 0, 'no future genTime'; ...
    o3.staleAckAcceptedCount  == 0, 'no stale ACK accepted'; ...
    o3.unknownSeqAckCount     == 0, 'no ACK for an unknown sequence number'}];


%% ============================================================
% [7] Connectivity classification
% ============================================================

full = generateBlackoutRealization(base, 0, 0);

checks = [checks; { ...
    full.connected,                       'the nominal graph is connected'; ...
    isfield(a,'isolatedFollowers'),       'isolated-follower count is reported'; ...
    isfield(a,'disconnectedDuration'),    'disconnected duration is reported'}];


%% ============================================================
% Verdict
% ============================================================

for q = 1:size(checks,1)
    okFlags(q,1) = logical(checks{q,1});
    okNames{q}   = checks{q,2};
    fprintf('    %-4s %s\n', verdict(okFlags(q)), okNames{q});
end

fprintf('\n');

nBad = nnz(~okFlags);

if nBad == 0
    fprintf('test_blackout_semantics: PASS (%d checks)\n', numel(okFlags));
else
    fprintf('test_blackout_semantics: FAIL (%d of %d checks)\n', nBad, numel(okFlags));
    for q = find(~okFlags(:)')
        fprintf('    failed: %s\n', okNames{q});
    end
    error('test_blackout_semantics failed.');
end
