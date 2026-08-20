function out = simSwarmNetworkQueued(cfg)

% The generator is pinned explicitly. Parallel-pool workers default to a
% different generator than the client, so rng(seed) alone would make
% parfor results differ from the equivalent serial loop.
rng(cfg.net.seed, 'twister');

dt = cfg.swarm.dt;

t = (0:dt:cfg.swarm.T)';
K = numel(t);

N = cfg.swarm.N;


P = cfg.swarm.initialPositions;
V = cfg.swarm.initialVelocities;


Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);

LeaderPos = zeros(K,3);

AoILog = zeros(K,1);


leader = leaderReference(0);

net = initQueuedNetworkState( ...
    P,V,leader,cfg);


% Initial state at t=0 is considered already transmitted.
nextCommTime = cfg.net.commPeriod;


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
            net,P,V,leader,tk,cfg);

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

out.txCount = net.txCount;
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