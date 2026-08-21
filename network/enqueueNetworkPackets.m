function net = enqueueNetworkPackets( ...
    net, P, V, leader, tk, cfg, netTrace, k)
%ENQUEUENETWORKPACKETS Periodic packet generation.
%
% netTrace and k are optional. When a trace is supplied the channel
% outcome is read from it at (k,i,j) instead of drawn inline, so every
% method sees the same realisation. Omitting them reproduces the
% original behaviour exactly.

if nargin < 7
    netTrace = [];
end

if nargin < 8
    k = 0;
end

N = cfg.swarm.N;


% ============================================================
% Broadcast accounting
%
% One radio transmission from node j reaches every neighbour that is
% listening, so under broadcast accounting the unicast links from the
% same sender in the same timestep collapse to one. The leader payload
% carries acceleration as well, so it is a separate payload class even
% when the physical sender is the same node.
%
% Recorded only; nothing here is read by any decision.
% ============================================================

senderFired = false(N,1);

leaderFired = false;


% ============================================================
% Neighbor packets
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end

        net.txCount = net.txCount + 1;

        senderFired(j) = true;


        % Delivery-layer link failure. Counted as a transmission that
        % was lost, because the sender cannot know the link is dead.
        if linkIsDown(cfg, i, j, tk)
            net.dropCount = net.dropCount + 1;
            continue;
        end


        % Packet loss
        if drawLoss(netTrace,k,i,j,false) < cfg.net.packetLoss

            net.dropCount = net.dropCount + 1;
            continue;

        end


        % Network delay
        delay = cfg.net.delay;

        if cfg.net.jitterStd > 0

            delay = delay + ...
                cfg.net.jitterStd * drawJitter(netTrace,k,i,j,false);

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

    leaderFired = true;


    if linkIsDown(cfg, i, 1, tk)
        net.dropCount = net.dropCount + 1;
        continue;
    end


    if drawLoss(netTrace,k,i,1,true) < cfg.net.packetLoss

        net.dropCount = net.dropCount + 1;
        continue;

    end


    delay = cfg.net.delay;

    if cfg.net.jitterStd > 0

        delay = delay + ...
            cfg.net.jitterStd * drawJitter(netTrace,k,i,1,true);

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


net.broadcastCount = net.broadcastCount + nnz(senderFired) + leaderFired;

end


%% ============================================================
% LOCAL FUNCTIONS
%
% Read the pre-drawn outcome when a trace is present, otherwise fall
% back to the inline draw that the locked experiments used.
% ============================================================

function u = drawLoss(netTrace,k,i,j,isLeader)

if isempty(netTrace)
    u = rand;
elseif isLeader
    u = netTrace.leaderLossU(k,i);
else
    u = netTrace.lossU(k,i,j);
end

end


function z = drawJitter(netTrace,k,i,j,isLeader)

if isempty(netTrace)
    z = randn;
elseif isLeader
    z = netTrace.leaderJitterZ(k,i);
else
    z = netTrace.jitterZ(k,i,j);
end

end


%% ============================================================
% LOCAL FUNCTION
%
% Delivery-layer link failure. Returns true when link (i,j) is dead
% at time tk. The transmitter is never told: it still transmits, the
% packet is still counted, and it is then lost. cfg.swarm.A is not
% touched anywhere.
% ============================================================

function isDown = linkIsDown(cfg, i, j, tk)

isDown = false;

if ~isfield(cfg,'fault') || isempty(cfg.fault)
    return;
end

if ~cfg.fault.down(i,j)
    return;
end

isDown = (tk >= cfg.fault.tStart) && (tk <= cfg.fault.tEnd);

end
