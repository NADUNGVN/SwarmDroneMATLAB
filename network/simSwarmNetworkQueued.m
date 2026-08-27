function out = simSwarmNetworkQueued(cfg)

% The generator is pinned explicitly. Parallel-pool workers default to a
% different generator than the client, so rng(seed) alone would make
% parfor results differ from the equivalent serial loop.
rng(cfg.net.seed, 'twister');

dt = cfg.swarm.dt;

t = (0:dt:cfg.swarm.T)';
K = numel(t);

N = cfg.swarm.N;

%% ============================================================
% Common random numbers (legacy default OFF)
%
% With cfg.net.useTrace true, channel outcomes come from a
% pre-drawn realisation indexed by (link, timestep) instead of from
% inline rand/randn. Every method then meets the same channel at the
% same instant, which sharing a seed alone does not achieve.
%
% Default false reproduces the locked behaviour exactly.
% ============================================================

if ~isfield(cfg.net,'useTrace')
    cfg.net.useTrace = false;
end

if cfg.net.useTrace
    netTrace = generateNetworkTrace(cfg);
else
    netTrace = [];
end

% ============================================================
% Transmission phase
%
% cfg.net.phaseOffset is the LEGACY flag. It is retained, and its
% default retained, because every locked experiment sets it explicitly
% and tests/test_lock_regression checks that it defaults off. It never
% did anything: the block below used to compute a per-link offset
% matrix that was never read by the transmission decision, so every
% locked result ran on ONE GLOBAL CLOCK regardless of the flag. That
% is recorded rather than quietly repaired, because "phase OFF" is
% what the locked results are, and it is what the flag delivered.
%
% cfg.net.phaseOffsetEnabled is the real thing, added for EXP10 and
% default OFF so no locked path changes. When it is on, each
% (physical sender, payload class) gets its own offset inside one
% period, drawn by utils/generatePhaseTrace, and the senders stop
% firing in lockstep.
% ============================================================

if ~isfield(cfg.net,'phaseOffset')
    cfg.net.phaseOffset = false;
end

if ~isfield(cfg.net,'phaseOffsetEnabled')
    cfg.net.phaseOffsetEnabled = false;
end


P = cfg.swarm.initialPositions;
V = cfg.swarm.initialVelocities;


Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);

LeaderPos = zeros(K,3);

AoILog = zeros(K,1);

% Passive cumulative transmission log. Written but never read by the
% simulator, so it cannot influence any result. Used only to measure
% traffic inside a fault window, which a run total cannot resolve.
TxCountLog = zeros(K,1);

% Passive cumulative broadcast log, same contract as TxCountLog: written
% every step, never read by the simulation. Added for EXP11, which needs
% every communication count restricted to a time window rather than the
% whole run - the first 8 s are warm-up and must not enter any metric, and
% a scalar total cannot be windowed after the fact.

BroadcastCountLog = zeros(K,1);

% 6-DOF follower state, created lazily on the first integration call.
sixState = [];

% Synthetic estimator state, created lazily. Empty when inert.
estState = [];



leader = leaderReference(0);

net = initQueuedNetworkState( ...
    P,V,leader,cfg);


% Initial state at t=0 is considered already transmitted.
%
% Per-sender transmission schedule. Entry j is the neighbour-state
% payload class of physical sender j; entry N+1 is the leader payload
% class. With phase disabled every offset is zero, so every entry of
% nextTx is cfg.net.commPeriod and stays in step for the whole run,
% which is exactly the single global clock the locked experiments ran
% on.
if cfg.net.phaseOffsetEnabled
    phaseTrace = generatePhaseTrace(cfg);
    phaseU = phaseTrace.u;
else
    phaseTrace = [];
    phaseU = zeros(N+1,1);
end

% Period in force at t = 0. commPeriodAt returns cfg.net.commPeriod and
% segment 0 unless a caller attached cfg.net.periodSchedule, so for every
% locked experiment and for all five fixed periodic EXP11 methods this is
% the constant period and periodSeg stays 0 for the whole run - no
% re-anchoring is ever triggered and the schedule is the locked one.
%
% Only Oracle-periodic supplies a schedule. Its phase offset is expressed
% as a FRACTION of the period in force, so the offset is re-scaled when the
% period changes rather than being frozen at its t = 0 value; a phase offset
% larger than the current period would otherwise silently skip a slot.
[periodNow, periodSeg] = commPeriodAt(cfg, 0);

phaseOffsetSec = phaseU * periodNow;

nextTx = phaseOffsetSec + periodNow;

% Passive: how many times each sender's clock fired. Written, never
% read by the simulation.
senderFireCount = zeros(N+1,1);

% Passive audit trail for the EXP11 oracle gate: every instant at which the
% transmission period actually changed, and the period it changed to. Empty
% for every fixed-period run, which is itself the evidence that the fixed
% periodic methods did not adapt.
periodSwitchTimes  = [];
periodSwitchValues = [];


for k = 1:K

    tk = t(k);


    leader = leaderReference(tk);


    % ========================================================
    % Physical leader
    % ========================================================

    P(1,:) = leader.pos';
    V(1,:) = leader.vel';

    % Synthetic swarm-state estimate, once per outer step. PHat/VHat feed
    % the policy self-state, the trigger and the transmitted payload; the
    % TRUE P/V stay what the dynamics integrate and what safety is
    % measured on. Inert when cfg.estimator is absent.
    [PHat, VHat, estState] = applyEstimator(P, V, estState, cfg, tk);

    % CRN slot. Identical to k unless the physical-time trace mode is on.
    kTrace = traceIndex(cfg, tk, k);



    % ========================================================
    % Packet generation
    % ========================================================

    % Period schedule. segNow is 0 on every static-period path, so the
    % re-anchoring branch below is dead code for the locked experiments
    % and for the fixed periodic methods, and nextTx keeps accumulating on
    % one uninterrupted grid straight through every channel switch.
    [pNow, segNow, segStartNow] = commPeriodAt(cfg, tk);

    if segNow ~= periodSeg

        % A period boundary was crossed. Restart the transmission grid at
        % the segment start, keeping each sender's phase fraction. See
        % commPeriodAt for why the grid is re-anchored instead of carried
        % over.
        nextTx = segStartNow + phaseU * pNow;

        if pNow ~= periodNow
            periodSwitchTimes(end+1)  = tk;      %#ok<AGROW>
            periodSwitchValues(end+1) = pNow;    %#ok<AGROW>
            periodNow = pNow;
        end

        periodSeg = segNow;

    end

    fireMask = tk >= nextTx - 1e-12;

    if any(fireMask)

        net = enqueueNetworkPackets( ...
            net,PHat,VHat,leader,tk,cfg,netTrace,kTrace,fireMask);

        nextTx(fireMask) = ...
            nextTx(fireMask) + ...
            pNow;

        senderFireCount(fireMask) = senderFireCount(fireMask) + 1;

    end


    % ========================================================
    % Deliver packets whose arrival time has passed
    % ========================================================

    net = deliverNetworkPackets( ...
        net,tk,cfg);


    % ========================================================
    % Formation controller
    % ========================================================

    accCmd = distributedFormationPolicy( ...
        PHat,VHat,leader,cfg,net);


    % ========================================================
    % Logging
    % ========================================================

    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;

    LeaderPos(k,:) = leader.pos';


    % ========================================================
    % AoI
    % ========================================================

    ages = [];


    for i = 1:N

        for j = 1:N

            if cfg.swarm.A(i,j)

                age = ...
                    tk - net.genTime(i,j) ...
                    + 0.5*dt;

                ages(end+1) = age; %#ok<AGROW>

            end

        end


        if cfg.swarm.pin(i)

            age = ...
                tk - net.leaderGenTime(i) ...
                + 0.5*dt;

            ages(end+1) = age; %#ok<AGROW>

        end

    end


    AoILog(k) = mean(ages);


    TxCountLog(k) = net.txCount;
    BroadcastCountLog(k) = net.broadcastCount;


    if k == K
        break;
    end


    % ========================================================
    % Double-integrator followers
    % ========================================================

    % Follower integration. cfg.sixdof.enable off (default) reproduces the
    % locked semi-implicit Euler exactly; on, each follower is a 6-DOF
    % quadrotor driven through the analytic command-consistent reference.
    [P, V, sixState] = integrateFollowers(P, V, accCmd, sixState, cfg, tk);


end


out.t = t;

out.P = Plog;
out.V = Vlog;
out.A = Alog;

out.LeaderPos = LeaderPos;

out.meanAoI = AoILog;
out.dropCount = net.dropCount;
out.staleDiscardCount = ...
    net.staleDiscardCount;

% ============================================================
% Network statistics
% ============================================================

out.txCount    = net.txCount;
out.txCountLog = TxCountLog;

% 6-DOF bookkeeping. Empty when cfg.sixdof.enable is off.
out.six = sixState;

% Synthetic estimator bookkeeping. Empty when inert.
out.est = estState;

% ============================================================
% Realization provenance
%
% The hash of the realization this run actually consumed, reported so
% that "every method met the same channel" is an audited fact rather
% than an assertion re-derived by the experiment script. NaN means the
% run used no trace of that kind.
% ============================================================

if ~isempty(netTrace)
    out.traceHash      = netTrace.hash;
    out.traceHashExact = netTrace.hashExact;
else
    out.traceHash      = NaN;
    out.traceHashExact = NaN;
end

% The periodic path has no reverse channel at all.
out.ackTraceHash      = NaN;
out.ackTraceHashExact = NaN;

if ~isempty(phaseTrace)
    out.phaseHash = phaseTrace.hash;
else
    out.phaseHash = NaN;
end

out.senderFireCount = senderFireCount;

out.periodSwitchTimes  = periodSwitchTimes;
out.periodSwitchValues = periodSwitchValues;

% Broadcast accounting (EXP07C): unique (timestep, sender, payload
% class) DATA transmissions. Passive counter, never read by the sim.
out.broadcastCount = net.broadcastCount;
out.broadcastCountLog = BroadcastCountLog;
out.rxCount = net.rxCount;
out.dropCount = net.dropCount;

out.staleDiscardCount = ...
    net.staleDiscardCount;


% Packet Delivery Ratio:
% packets that were NOT dropped by the channel
out.PDR = ...
    1 - net.dropCount / max(net.txCount,1);


% Packets that actually arrived before simulation ended
out.arrivalRatio = ...
    net.rxCount / max(net.txCount,1);

% ============================================================
% Out-of-order / effective communication statistics
% ============================================================

out.staleDiscardRatio = ...
    net.staleDiscardCount / ...
    max(net.rxCount,1);


out.effectiveUpdateRatio = ...
    (net.rxCount - net.staleDiscardCount) / ...
    max(net.txCount,1);

end