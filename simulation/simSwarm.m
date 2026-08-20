function out = simSwarm(cfg)

dt = cfg.swarm.dt;
t  = (0:dt:cfg.swarm.T)';
K  = numel(t);

N = cfg.swarm.N;

P = cfg.swarm.initialPositions;
V = cfg.swarm.initialVelocities;

Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);

LeaderPos = zeros(K,3);
LeaderVel = zeros(K,3);
LeaderAcc = zeros(K,3);

for k = 1:K

    tk = t(k);

    leader = leaderReference(tk);

    % --------------------------------------------------------
    % Force agent 1 to be exact leader in EXP02 baseline.
    % --------------------------------------------------------

    P(1,:) = leader.pos';
    V(1,:) = leader.vel';

    accCmd = distributedFormationPolicy( ...
        P, V, leader, cfg);

    % --------------------------------------------------------
    % Logging
    % --------------------------------------------------------

    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;

    LeaderPos(k,:) = leader.pos';
    LeaderVel(k,:) = leader.vel';
    LeaderAcc(k,:) = leader.acc';

    if k == K
        break;
    end


    % --------------------------------------------------------
    % Double-integrator followers
    %
    % p_dot = v
    % v_dot = a
    % --------------------------------------------------------

    for i = 2:N

        V(i,:) = V(i,:) + dt * accCmd(i,:);

        P(i,:) = P(i,:) + dt * V(i,:);

    end

end


out.t = t;

out.P = Plog;
out.V = Vlog;
out.A = Alog;

out.LeaderPos = LeaderPos;
out.LeaderVel = LeaderVel;
out.LeaderAcc = LeaderAcc;

end