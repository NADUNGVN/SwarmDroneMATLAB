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

% Per-link phase offset for periodic transmission (legacy default OFF).
% Without it every channel fires on one global clock forever, which
% flatters no method in particular but is not how real nodes behave.
if ~isfield(cfg.net,'phaseOffset')
    cfg.net.phaseOffset = false;
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



leader = leaderReference(0);

net = initQueuedNetworkState( ...
    P,V,leader,cfg);


% Initial state at t=0 is considered already transmitted.
%
% With phaseOffset enabled each link gets its own deterministic offset
% inside one period, so the swarm does not transmit in lockstep.
if cfg.net.phaseOffset
    linkPhase = mod((0:N*N-1)' * cfg.net.commPeriod / max(N*N,1), ...
        cfg.net.commPeriod);
    linkPhase = reshape(linkPhase, N, N);
    nextCommTime = cfg.net.commPeriod;
else
    linkPhase = zeros(N,N);
    nextCommTime = cfg.net.commPeriod;
end


for k = 1:K

    tk = t(k);

    leader = leaderReference(tk);


    % ========================================================
    % Physical leader
    % ========================================================

    P(1,:) = leader.pos';
    V(1,:) = leader.vel';


    % ========================================================
    % Packet generation
    % ========================================================

    if tk >= nextCommTime - 1e-12

        net = enqueueNetworkPackets( ...
            net,P,V,leader,tk,cfg,netTrace,k);

        nextCommTime = ...
            nextCommTime + ...
            cfg.net.commPeriod;

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
        P,V,leader,cfg,net);


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


    if k == K
        break;
    end


    % ========================================================
    % Double-integrator followers
    % ========================================================

    for i = 2:N

        V(i,:) = ...
            V(i,:) + dt*accCmd(i,:);

        P(i,:) = ...
            P(i,:) + dt*V(i,:);

    end


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

% Broadcast accounting (EXP07C): unique (timestep, sender, payload
% class) DATA transmissions. Passive counter, never read by the sim.
out.broadcastCount = net.broadcastCount;
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