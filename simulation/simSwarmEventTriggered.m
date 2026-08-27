function out = simSwarmEventTriggered(cfg)

% ============================================================
% SIMSWARMEVENTTRIGGERED
%
% Distributed swarm simulation with event-triggered
% communication.
%
% Unlike periodic communication, transmission decisions are
% evaluated at every simulation timestep.
%
% Existing queued-network infrastructure is reused for:
%
%   - packet loss
%   - communication delay
%   - jitter
%   - out-of-order packet rejection
%   - AoI
%
% ============================================================


%% ============================================================
% Initialization
% ============================================================

% The generator is pinned explicitly. Parallel-pool workers default to a
% different generator than the client, so rng(seed) alone would make
% parfor results differ from the equivalent serial loop.
rng(cfg.net.seed, 'twister');


dt = cfg.swarm.dt;

t = ...
    (0:dt:cfg.swarm.T)';

K = numel(t);

N = cfg.swarm.N;


%% ============================================================
% Common random numbers (legacy default OFF)
% ============================================================

if ~isfield(cfg.net,'useTrace')
    cfg.net.useTrace = false;
end

if cfg.net.useTrace
    netTrace = generateNetworkTrace(cfg);
else
    netTrace = [];
end


P = ...
    cfg.swarm.initialPositions;

V = ...
    cfg.swarm.initialVelocities;


%% ============================================================
% Logging
% ============================================================

Plog = zeros(K,N,3);

Vlog = zeros(K,N,3);

Alog = zeros(K,N,3);

LeaderPos = zeros(K,3);

LeaderVel = zeros(K,3);

AoILog = zeros(K,1);

% Passive cumulative transmission log. Written but never read by the
% simulator, so it cannot influence any result. Used only to measure
% traffic inside a fault window, which a run total cannot resolve.
TxCountLog = zeros(K,1);

% 6-DOF follower state, created lazily on the first integration call.
sixState = [];

% Synthetic estimator state, created lazily. Empty when inert.
estState = [];



%% ============================================================
% Initial network state
% ============================================================

leader = ...
    leaderReference(0);


net = ...
    initQueuedNetworkState( ...
    P,V,leader,cfg);


% Transmitter-side event-trigger memory.
%
% It will be initialized automatically on the first call to:
%
% enqueueTriggeredNetworkPackets()
txState = [];


%% ============================================================
% Simulation loop
% ============================================================

for k = 1:K

    tk = t(k);



    %% --------------------------------------------------------
    % Leader reference
    % ---------------------------------------------------------

    leader = ...
        leaderReference(tk);


    %% --------------------------------------------------------
    % Physical leader
    %
    % Same ideal-leader assumption used by EXP02-EXP04.
    % ---------------------------------------------------------

    P(1,:) = ...
        leader.pos';

    V(1,:) = ...
        leader.vel';

    % Synthetic swarm-state estimate, once per outer step. PHat/VHat feed
    % the policy self-state, the trigger and the transmitted payload; the
    % TRUE P/V stay what the dynamics integrate and what safety is
    % measured on. Inert when cfg.estimator is absent.
    [PHat, VHat, estState] = applyEstimator(P, V, estState, cfg, tk);

    % CRN slot. Identical to k unless the physical-time trace mode is on.
    kTrace = traceIndex(cfg, tk, k);




    %% --------------------------------------------------------
    % Event-triggered packet generation
    %
    % Trigger conditions are evaluated every simulation
    % timestep.
    % ---------------------------------------------------------

    [net,txState] = ...
        enqueueTriggeredNetworkPackets( ...
        net, ...
        txState, ...
        PHat, ...
        VHat, ...
        leader, ...
        tk, ...
        cfg, ...
        netTrace, ...
        kTrace);


    %% --------------------------------------------------------
    % Deliver packets whose arrival time has been reached
    % ---------------------------------------------------------

    net = ...
        deliverNetworkPackets( ...
        net,tk,cfg);


    %% --------------------------------------------------------
    % Distributed formation controller
    %
    % Controller uses latest received states stored in net.
    % ---------------------------------------------------------

    accCmd = ...
        distributedFormationPolicy( ...
        PHat,VHat,leader,cfg,net);


    %% --------------------------------------------------------
    % Logging
    % ---------------------------------------------------------

    Plog(k,:,:) = ...
        P;

    Vlog(k,:,:) = ...
        V;

    Alog(k,:,:) = ...
        accCmd;


    LeaderPos(k,:) = ...
        leader.pos';

    LeaderVel(k,:) = ...
        leader.vel';


    %% --------------------------------------------------------
    % Age of Information
    %
    % AoI is based on generation timestamp of the latest
    % ACCEPTED packet at each receiver.
    %
    % Midpoint correction:
    %
    %   + 0.5*dt
    %
    % maintains consistency with EXP03/EXP04.
    % ---------------------------------------------------------

    ages = [];


    for i = 1:N

        for j = 1:N

            if cfg.swarm.A(i,j)

                age = ...
                    tk ...
                    - net.genTime(i,j) ...
                    + 0.5*dt;


                ages(end+1) = ...
                    age; %#ok<AGROW>

            end

        end


        if cfg.swarm.pin(i)

            age = ...
                tk ...
                - net.leaderGenTime(i) ...
                + 0.5*dt;


            ages(end+1) = ...
                age; %#ok<AGROW>

        end

    end


    if isempty(ages)

        AoILog(k) = NaN;

    else

        AoILog(k) = ...
            mean(ages);

    end


    %% --------------------------------------------------------
    % End of simulation
    % ---------------------------------------------------------

    TxCountLog(k) = net.txCount;


    if k == K
        break;
    end


    %% --------------------------------------------------------
    % Double-integrator follower dynamics
    % ---------------------------------------------------------

    % Follower integration. cfg.sixdof.enable off (default) reproduces the
    % locked semi-implicit Euler exactly; on, each follower is a 6-DOF
    % quadrotor driven through the analytic command-consistent reference.
    [P, V, sixState] = integrateFollowers(P, V, accCmd, sixState, cfg, tk);


end


%% ============================================================
% Standard simulation outputs
% ============================================================

out.t = t;

out.P = Plog;

out.V = Vlog;

out.A = Alog;

out.LeaderPos = ...
    LeaderPos;

out.LeaderVel = ...
    LeaderVel;

out.meanAoI = ...
    AoILog;


%% ============================================================
% Network statistics
% ============================================================

out.txCount = ...
    net.txCount;

out.txCountLog = TxCountLog;

% 6-DOF bookkeeping. Empty when cfg.sixdof.enable is off.
out.six = sixState;

% Synthetic estimator bookkeeping. Empty when inert.
out.est = estState;

% ============================================================
% Realization provenance
%
% The hash of the realization this run actually consumed. NaN means the
% run used no trace of that kind: the state-event method has no reverse
% channel, and it has no periodic clock for a transmission phase to
% apply to, so cfg.net.phaseOffsetEnabled is inert here by construction
% rather than by a switch.
% ============================================================

if ~isempty(netTrace)
    out.traceHash = netTrace.hash;
else
    out.traceHash = NaN;
end

out.ackTraceHash = NaN;
out.phaseHash    = NaN;

% Broadcast accounting (EXP07C): unique (timestep, sender, payload
% class) DATA transmissions. Passive counter, never read by the sim.
out.broadcastCount = net.broadcastCount;

out.rxCount = ...
    net.rxCount;

out.dropCount = ...
    net.dropCount;

out.staleDiscardCount = ...
    net.staleDiscardCount;


%% ------------------------------------------------------------
% PDR
% ------------------------------------------------------------

out.PDR = ...
    1 ...
    - net.dropCount ...
    / max(net.txCount,1);


%% ------------------------------------------------------------
% Arrival ratio
%
% Packets reaching receiver before simulation ends.
% ------------------------------------------------------------

out.arrivalRatio = ...
    net.rxCount ...
    / max(net.txCount,1);


%% ------------------------------------------------------------
% Stale/out-of-order ratio
% ------------------------------------------------------------

out.staleDiscardRatio = ...
    net.staleDiscardCount ...
    / max(net.rxCount,1);


%% ------------------------------------------------------------
% Effective information update ratio
% ------------------------------------------------------------

out.effectiveUpdateRatio = ...
    (net.rxCount ...
    - net.staleDiscardCount) ...
    / max(net.txCount,1);


%% ============================================================
% Event-trigger statistics
% ============================================================

if isfield(net,'triggerCheckCount')

    out.triggerCheckCount = ...
        net.triggerCheckCount;

else

    out.triggerCheckCount = 0;

end


if isfield(net,'suppressedCount')

    out.suppressedCount = ...
        net.suppressedCount;

else

    out.suppressedCount = 0;

end


if isfield(net,'positionTriggerCount')

    out.positionTriggerCount = ...
        net.positionTriggerCount;

else

    out.positionTriggerCount = 0;

end


if isfield(net,'velocityTriggerCount')

    out.velocityTriggerCount = ...
        net.velocityTriggerCount;

else

    out.velocityTriggerCount = 0;

end


if isfield(net,'timeoutTriggerCount')

    out.timeoutTriggerCount = ...
        net.timeoutTriggerCount;

else

    out.timeoutTriggerCount = 0;

end


%% ------------------------------------------------------------
% Fraction of communication opportunities suppressed
% ------------------------------------------------------------

out.suppressionRatio = ...
    out.suppressedCount ...
    / max(out.triggerCheckCount,1);


%% ------------------------------------------------------------
% Trigger composition
% ------------------------------------------------------------

out.positionTriggerRatio = ...
    out.positionTriggerCount ...
    / max(out.txCount,1);


out.velocityTriggerRatio = ...
    out.velocityTriggerCount ...
    / max(out.txCount,1);


out.timeoutTriggerRatio = ...
    out.timeoutTriggerCount ...
    / max(out.txCount,1);


end