function net = enqueueNetworkPackets( ...
    net, P, V, leader, tk, cfg)

N = cfg.swarm.N;


% ============================================================
% Neighbor packets
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end

        net.txCount = net.txCount + 1;


        % Packet loss
        if rand < cfg.net.packetLoss

            net.dropCount = net.dropCount + 1;
            continue;

        end


        % Network delay
        delay = cfg.net.delay;

        if cfg.net.jitterStd > 0

            delay = delay + ...
                cfg.net.jitterStd * randn;

        end

        delay = max(delay,0);


        pkt.genTime = tk;
        pkt.arrivalTime = tk + delay;

        pkt.pos = P(j,:);
        pkt.vel = V(j,:);


        q = net.queue{i,j};

        q{end+1} = pkt;

        net.queue{i,j} = q;

    end

end


% ============================================================
% Leader packets
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    net.txCount = net.txCount + 1;


    if rand < cfg.net.packetLoss

        net.dropCount = net.dropCount + 1;
        continue;

    end


    delay = cfg.net.delay;

    if cfg.net.jitterStd > 0

        delay = delay + ...
            cfg.net.jitterStd * randn;

    end

    delay = max(delay,0);


    pkt.genTime = tk;
    pkt.arrivalTime = tk + delay;

    pkt.pos = leader.pos';
    pkt.vel = leader.vel';
    pkt.acc = leader.acc';


    q = net.leaderQueue{i};

    q{end+1} = pkt;

    net.leaderQueue{i} = q;

end

end