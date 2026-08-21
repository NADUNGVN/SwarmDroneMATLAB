function net = initQueuedNetworkState(P, V, leader, cfg)

N = cfg.swarm.N;

net.Pij = zeros(N,N,3);
net.Vij = zeros(N,N,3);

net.valid = false(N,N);

% Generation timestamp of latest accepted packet
net.genTime = -inf(N,N);

% Packet queues
net.queue = cell(N,N);


% ============================================================
% Initial neighbor information
% Treat t = 0 state as already available.
% ============================================================

for i = 1:N
    for j = 1:N

        net.queue{i,j} = {};

        if cfg.swarm.A(i,j) ~= 0

            net.Pij(i,j,:) = P(j,:);
            net.Vij(i,j,:) = V(j,:);

            net.valid(i,j) = true;
            net.genTime(i,j) = 0;

        end
    end
end


% ============================================================
% Leader pinning
% ============================================================

net.leaderPos = zeros(N,3);
net.leaderVel = zeros(N,3);
net.leaderAcc = zeros(N,3);

net.leaderValid = false(N,1);
net.leaderGenTime = -inf(N,1);

net.leaderQueue = cell(N,1);


for i = 1:N

    net.leaderQueue{i} = {};

    if i >= 2 && cfg.swarm.pin(i)

        net.leaderPos(i,:) = leader.pos';
        net.leaderVel(i,:) = leader.vel';
        net.leaderAcc(i,:) = leader.acc';

        net.leaderValid(i) = true;
        net.leaderGenTime(i) = 0;

    end

end


% ============================================================
% Network statistics
% ============================================================

% Broadcast accounting (EXP07C). Counts unique
% (timestep, physical sender, payload class) DATA transmissions. Purely
% passive: it is written but never read by any decision, so enabling it
% cannot change a run. tests/test_lock_regression proves that.
net.broadcastCount = 0;

net.txCount = 0;
net.rxCount = 0;
net.dropCount = 0;
net.staleDiscardCount = 0;

end