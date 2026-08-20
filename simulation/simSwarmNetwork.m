function out = simSwarmNetwork(cfg)

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

net = initNetworkState(P,V,leader,cfg);


% ============================================================
% Communication scheduler
% ============================================================

nextCommTime = 0;


for k = 1:K

    tk = t(k);

    leader = leaderReference(tk);


    % ========================================================
    % Ideal physical leader
    % ========================================================

    P(1,:) = leader.pos';
    V(1,:) = leader.vel';


    % ========================================================
    % Communication event
    % ========================================================

    if tk >= nextCommTime - 1e-12

        net = updateNetworkState( ...
            net,P,V,leader,cfg);

        nextCommTime = ...
            nextCommTime + cfg.net.commPeriod;

    end


    % ========================================================
    % Swarm control uses received/stale states
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


    % Mean AoI over active links
    ages = [];

    for i = 1:N
    
        for j = 1:N
    
            if cfg.swarm.A(i,j)
    
                % Average AoI over the upcoming integration interval.
                %
                % age(t + dt/2) = age(t) + dt/2
                ages(end+1) = ...
                    net.age(i,j) + 0.5*dt; %#ok<AGROW>
    
            end
    
        end
    
        if cfg.swarm.pin(i)
    
            ages(end+1) = ...
                net.leaderAge(i) + 0.5*dt; %#ok<AGROW>
    
        end
    
    end
    
    AoILog(k) = mean(ages);


    % ============================================================
    % Advance Age of Information continuously
    % ============================================================
    
    for i = 1:N
    
        for j = 1:N
    
            if cfg.swarm.A(i,j)
                net.age(i,j) = net.age(i,j) + dt;
            end
    
        end
    
        if cfg.swarm.pin(i)
            net.leaderAge(i) = net.leaderAge(i) + dt;
        end
    
    end


    % ========================================================
    % Double integrator
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

out.PDR = ...
    net.rxCount / max(net.txCount,1);

out.txCount = net.txCount;
out.rxCount = net.rxCount;

end