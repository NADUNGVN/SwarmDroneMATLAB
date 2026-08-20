function net = deliverNetworkPackets(net, tk, cfg)

N = cfg.swarm.N;

tol = 1e-12;


% ============================================================
% Neighbor packets
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end


        q = net.queue{i,j};

        if isempty(q)
            continue;
        end


        % ============================================================
        % Find packets that have arrived
        % ============================================================
        
        arrivalTimes = cellfun( ...
            @(pkt) pkt.arrivalTime, q);
        
        genTimes = cellfun( ...
            @(pkt) pkt.genTime, q);
        
        dueIdx = find( ...
            arrivalTimes <= tk + tol);
        
        
        if isempty(dueIdx)
            continue;
        end
        
        
        % ============================================================
        % IMPORTANT:
        % Process packets according to actual arrival order,
        % NOT generation/insertion order.
        %
        % This is required to correctly model out-of-order delivery.
        % ============================================================
        
        sortData = [
            arrivalTimes(dueIdx)' ...
            genTimes(dueIdx)'
        ];
        
        [~,order] = sortrows(sortData,[1 2]);
        
        dueIdxOrdered = ...
            dueIdx(order);
        
        
        keep = true(size(q));
        
        
        for m = 1:numel(dueIdxOrdered)
        
            n = dueIdxOrdered(m);
        
            pkt = q{n};
        
            keep(n) = false;
        
        
            net.rxCount = ...
                net.rxCount + 1;
        
        
            % --------------------------------------------------------
            % Accept only information newer than currently stored
            % --------------------------------------------------------
        
            if pkt.genTime > net.genTime(i,j)
        
                net.Pij(i,j,:) = pkt.pos;
                net.Vij(i,j,:) = pkt.vel;
        
                net.genTime(i,j) = ...
                    pkt.genTime;
        
                net.valid(i,j) = true;
        
            else
        
                % Packet arrived, but its information is older than
                % the state already stored at the receiver.
                net.staleDiscardCount = ...
                    net.staleDiscardCount + 1;
        
            end
        
        end
        
        
        net.queue{i,j} = q(keep);

    end

end


% ============================================================
% Leader packets
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    q = net.leaderQueue{i};

    if isempty(q)
        continue;
    end
    
    
    arrivalTimes = cellfun( ...
        @(pkt) pkt.arrivalTime, q);
    
    genTimes = cellfun( ...
        @(pkt) pkt.genTime, q);
    
    dueIdx = find( ...
        arrivalTimes <= tk + tol);
    
    
    if isempty(dueIdx)
        continue;
    end
    
    
    sortData = [
        arrivalTimes(dueIdx)' ...
        genTimes(dueIdx)'
    ];
    
    [~,order] = sortrows(sortData,[1 2]);
    
    dueIdxOrdered = ...
        dueIdx(order);
    
    
    keep = true(size(q));
    
    
    for m = 1:numel(dueIdxOrdered)
    
        n = dueIdxOrdered(m);
    
        pkt = q{n};
    
        keep(n) = false;
    
    
        net.rxCount = ...
            net.rxCount + 1;
    
    
        if pkt.genTime > ...
                net.leaderGenTime(i)
    
            net.leaderPos(i,:) = pkt.pos;
            net.leaderVel(i,:) = pkt.vel;
            net.leaderAcc(i,:) = pkt.acc;
    
            net.leaderGenTime(i) = ...
                pkt.genTime;
    
            net.leaderValid(i) = true;
    
        else
    
            net.staleDiscardCount = ...
                net.staleDiscardCount + 1;
    
        end
    
    end
    
    
    net.leaderQueue{i} = q(keep);

end

end