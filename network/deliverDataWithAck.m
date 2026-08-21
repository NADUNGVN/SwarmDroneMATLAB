function net = deliverDataWithAck(net, tk, cfg)
%DELIVERDATAWITHACK Deliver DATA packets and emit an ACK for each acceptance.
%
%   net = deliverDataWithAck(net, tk, cfg)
%
% Thin wrapper around the locked deliverNetworkPackets. It records which
% links advanced their accepted-generation timestamp during this delivery and
% pushes one ACK per acceptance onto the reverse queue.
%
% Reusing deliverNetworkPackets rather than copying it is deliberate: this
% project already has one silently drifted duplicate of a policy function
% (ablationTriggerPolicy vs aoiAwareTriggerPolicy, missing a clamp), and the
% forward delivery path must stay byte-identical to the locked experiments.
%
% ACK generation is receiver-side, so reading net.genTime here is legitimate:
% the receiver is the node that decides to acknowledge. The transmitter never
% sees any of this except through an ACK that actually arrives.

N = cfg.swarm.N;

tol = 1e-12;


%% ============================================================
% What the receivers held before this delivery
% ============================================================

genTimeBefore = net.genTime;

leaderGenTimeBefore = net.leaderGenTime;


%% ============================================================
% Forward delivery (unchanged, locked implementation)
% ============================================================

net = deliverNetworkPackets(net, tk, cfg);


%% ============================================================
% Neighbour links: one ACK per acceptance
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end

        acceptedGenTime = net.genTime(i,j);

        if acceptedGenTime <= genTimeBefore(i,j) + tol
            continue;
        end

        % A receiver can never accept a packet stamped in the future.
        if acceptedGenTime > tk + tol
            net.futureGenTimeCount = net.futureGenTimeCount + 1;
        end

        net = pushAck(net, i, j, acceptedGenTime, tk, cfg, false);

    end

end


%% ============================================================
% Leader links
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end

    acceptedGenTime = net.leaderGenTime(i);

    if acceptedGenTime <= leaderGenTimeBefore(i) + tol
        continue;
    end

    if acceptedGenTime > tk + tol
        net.futureGenTimeCount = net.futureGenTimeCount + 1;
    end

    net = pushAck(net, i, 1, acceptedGenTime, tk, cfg, true);

end

end


%% ============================================================
% LOCAL FUNCTION
%
% Build one ACK and place it on the reverse queue, subject to the
% reverse channel's own loss, delay and jitter.
% ============================================================

function net = pushAck(net, i, j, acceptedGenTime, tk, cfg, isLeaderLink)

net.ackTxCount = net.ackTxCount + 1;


%% ------------------------------------------------------------
% Reverse-channel loss
% ------------------------------------------------------------

if rand(net.ackStream) < cfg.ack.loss

    net.ackDropCount = net.ackDropCount + 1;

    return;

end


%% ------------------------------------------------------------
% Reverse-channel delay
%
% Floored at one timestep: the receiver only decides at its own
% sampling instant, so a same-timestep ACK is not physical. This
% floor is what prevents the oracle from being reintroduced.
% ------------------------------------------------------------

ackDelay = cfg.ack.delay;

if cfg.ack.jitterStd > 0
    ackDelay = ackDelay + cfg.ack.jitterStd * randn(net.ackStream);
end

ackDelay = max(ackDelay, cfg.swarm.dt);


ack.ackedGenTime = acceptedGenTime;
ack.acceptTime   = tk;
ack.arrivalTime  = tk + ackDelay;


%% ------------------------------------------------------------
% Queue on the reverse path
% ------------------------------------------------------------

if isLeaderLink

    q = net.leaderAckQueue{i};
    q{end+1} = ack;
    net.leaderAckQueue{i} = q;

else

    q = net.ackQueue{i,j};
    q{end+1} = ack;
    net.ackQueue{i,j} = q;

end

end
