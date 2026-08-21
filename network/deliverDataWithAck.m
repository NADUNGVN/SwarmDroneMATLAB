function net = deliverDataWithAck(net, tk, cfg)
%DELIVERDATAWITHACK Deliver DATA and emit one CUMULATIVE ACK per link per tick.
%
%   net = deliverDataWithAck(net, tk, cfg)
%
% Thin wrapper around the locked deliverNetworkPackets. Reusing it rather
% than copying keeps the forward path byte-identical to the locked
% experiments; this project already carries one silently drifted duplicate
% of a policy function, and that is not a mistake worth repeating.
%
% The sequence number is carried in the packet header and recorded by
% deliverNetworkPackets, so nothing here consults a side table.
%
% ACK semantics (v2): CUMULATIVE. A receiver emits at most one ACK per link
% per sampling tick, naming the NEWEST packet it has accepted. If several
% packets landed in the same tick, the single ACK confirms all of them.
%
% That matters well beyond saving ACK traffic. Under jitter a burst can
% arrive out of order within one tick; a per-packet ACK scheme would then
% put several ACKs on the reverse path whose relative order carries no
% useful information. A cumulative ACK is order-insensitive by construction.
%
% Reading net.genTime here is legitimate: ACK generation is receiver-side,
% and the receiver is the node deciding what to acknowledge. The transmitter
% learns none of it except through an ACK that actually arrives.

N = cfg.swarm.N;

tol = 1e-12;


genTimeBefore = net.genTime;

leaderGenTimeBefore = net.leaderGenTime;


%% ============================================================
% Forward delivery (unchanged, locked implementation)
% ============================================================

net = deliverNetworkPackets(net, tk, cfg);


%% ============================================================
% Neighbour links
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

        if acceptedGenTime > tk + tol
            net.futureGenTimeCount = net.futureGenTimeCount + 1;
        end

        % The sequence number came in the packet header and was stored
        % by deliverNetworkPackets. No side-channel lookup.
        seq = net.acceptedSeq(i,j);

        % Cumulative: this one ACK retires everything the receiver has
        % accepted since it last acknowledged.
        covered = seq - net.lastAckSeqSent(i,j);

        net.lastAckSeqSent(i,j) = seq;

        net.ackCoveredCount = net.ackCoveredCount + max(covered,0);

        net = pushAck(net, i, j, acceptedGenTime, seq, tk, cfg, false);

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

    seq = net.leaderAcceptedSeq(i);

    covered = seq - net.leaderLastAckSeqSent(i);

    net.leaderLastAckSeqSent(i) = seq;

    net.ackCoveredCount = net.ackCoveredCount + max(covered,0);

    net = pushAck(net, i, 1, acceptedGenTime, seq, tk, cfg, true);

end

end


%% ============================================================
% LOCAL FUNCTION
%
% Place one ACK on the reverse path, subject to its own loss,
% delay and jitter.
% ============================================================

function net = pushAck(net, i, j, acceptedGenTime, seq, tk, cfg, isLeaderLink)

net.ackTxCount = net.ackTxCount + 1;


if rand(net.ackStream) < cfg.ack.loss

    net.ackDropCount = net.ackDropCount + 1;

    return;

end


ackDelay = cfg.ack.delay;

if cfg.ack.jitterStd > 0
    ackDelay = ackDelay + cfg.ack.jitterStd * randn(net.ackStream);
end

% Floored at one timestep: the receiver only decides at its own sampling
% instant, so a same-tick ACK is not physical. This floor is what keeps
% the oracle from creeping back in.
ackDelay = max(ackDelay, cfg.swarm.dt);


ack.ackedGenTime = acceptedGenTime;
ack.ackedSeq     = seq;
ack.acceptTime   = tk;
ack.arrivalTime  = tk + ackDelay;


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
