function net = updateNetworkState( ...
    net, P, V, leader, cfg)

N = cfg.swarm.N;
pLoss = cfg.net.packetLoss;

% ============================================================
% Neighbor-to-neighbor communication
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end

        net.txCount = net.txCount + 1;

        success = rand >= pLoss;

        if success

            net.Pij(i,j,:) = P(j,:);
            net.Vij(i,j,:) = V(j,:);

            net.age(i,j) = 0;
            net.valid(i,j) = true;

            net.rxCount = net.rxCount + 1;

        end

    end

end


% ============================================================
% Leader packets to pinned followers
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end

    net.txCount = net.txCount + 1;

    success = rand >= pLoss;

    if success

        net.leaderPos(i,:) = leader.pos';
        net.leaderVel(i,:) = leader.vel';
        net.leaderAcc(i,:) = leader.acc';

        net.leaderAge(i) = 0;
        net.leaderValid(i) = true;

        net.rxCount = net.rxCount + 1;

    end

end

end