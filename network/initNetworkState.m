function net = initNetworkState(P, V, leader, cfg)

N = cfg.swarm.N;

net.Pij = zeros(N,N,3);
net.Vij = zeros(N,N,3);
net.age = zeros(N,N);

net.valid = false(N,N);

% ============================================================
% Initially assume every existing communication link has
% one valid state packet.
% ============================================================

for i = 1:N
    for j = 1:N

        if cfg.swarm.A(i,j) ~= 0

            net.Pij(i,j,:) = P(j,:);
            net.Vij(i,j,:) = V(j,:);

            net.age(i,j) = 0;
            net.valid(i,j) = true;

        end
    end
end


% ============================================================
% Leader broadcast / pinning
% ============================================================

net.leaderPos = zeros(N,3);
net.leaderVel = zeros(N,3);
net.leaderAcc = zeros(N,3);

net.leaderAge = zeros(N,1);
net.leaderValid = false(N,1);

for i = 2:N

    if cfg.swarm.pin(i)

        net.leaderPos(i,:) = leader.pos';
        net.leaderVel(i,:) = leader.vel';
        net.leaderAcc(i,:) = leader.acc';

        net.leaderAge(i) = 0;
        net.leaderValid(i) = true;

    end
end


% Counters
net.txCount = 0;
net.rxCount = 0;

end