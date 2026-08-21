function [net, txState] = deliverAckPackets(net, txState, tk, cfg)
%DELIVERACKPACKETS Apply ACKs that have arrived, and enforce causality.
%
%   [net, txState] = deliverAckPackets(net, txState, tk, cfg)
%
% This is the ONLY function that may advance txState.ackPos / ackVel /
% ackGenTime. Everything the transmitter believes about the receiver enters
% through here, from an ACK packet that actually arrived.
%
% Every one of the six causality invariants is checked here. With
% cfg.ack.assertInvariants true a violation raises immediately rather than
% being counted and ignored.

N = cfg.swarm.N;

tol = 1e-10;


%% ============================================================
% Neighbour links
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end

        q = net.ackQueue{i,j};

        if isempty(q)
            continue;
        end

        arrivalTimes = cellfun(@(a) a.arrivalTime, q);

        dueIdx = find(arrivalTimes <= tk + tol);

        if isempty(dueIdx)
            continue;
        end

        % Process in arrival order so an out-of-order ACK is seen as such.
        [~, order] = sort(arrivalTimes(dueIdx));

        dueIdx = dueIdx(order);

        keep = true(size(q));

        for m = 1:numel(dueIdx)

            n = dueIdx(m);

            keep(n) = false;

            [net, txState] = applyAck( ...
                net, txState, q{n}, i, j, tk, cfg, false);

        end

        net.ackQueue{i,j} = q(keep);

    end

end


%% ============================================================
% Leader links
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end

    q = net.leaderAckQueue{i};

    if isempty(q)
        continue;
    end

    arrivalTimes = cellfun(@(a) a.arrivalTime, q);

    dueIdx = find(arrivalTimes <= tk + tol);

    if isempty(dueIdx)
        continue;
    end

    [~, order] = sort(arrivalTimes(dueIdx));

    dueIdx = dueIdx(order);

    keep = true(size(q));

    for m = 1:numel(dueIdx)

        n = dueIdx(m);

        keep(n) = false;

        [net, txState] = applyAck( ...
            net, txState, q{n}, i, 1, tk, cfg, true);

    end

    net.leaderAckQueue{i} = q(keep);

end

end


%% ============================================================
% LOCAL FUNCTION
%
% Validate one ACK against all six invariants, then apply it.
% ============================================================

function [net, txState] = applyAck(net, txState, ack, i, j, tk, cfg, isLeaderLink)

tol = 1e-10;

net.ackRxCount = net.ackRxCount + 1;


%% ------------------------------------------------------------
% INVARIANT 1: an ACK cannot arrive before it was created.
% ------------------------------------------------------------

if ack.arrivalTime < ack.acceptTime - tol

    net.ackBeforeAcceptCount = net.ackBeforeAcceptCount + 1;

    reportViolation(cfg, 'ackBeforeAccept', ...
        'ACK arrived at %.6f but was created at %.6f', ...
        ack.arrivalTime, ack.acceptTime);

end


%% ------------------------------------------------------------
% INVARIANT 2: no timestamp may come from the future.
% ------------------------------------------------------------

if ack.ackedGenTime > tk + tol

    net.futureGenTimeCount = net.futureGenTimeCount + 1;

    reportViolation(cfg, 'futureGenTime', ...
        'ACK at t=%.6f acknowledges genTime %.6f', tk, ack.ackedGenTime);

end


%% ------------------------------------------------------------
% Locate the attempt this ACK refers to.
% ------------------------------------------------------------

if isLeaderLink
    pend = txState.leaderPending{i};
    currentAckGenTime = txState.leaderAckGenTime(i);
else
    pend = txState.pending{i,j};
    currentAckGenTime = txState.ackGenTime(i,j);
end


idx = [];

if ~isempty(pend)
    genTimes = [pend.genTime];
    idx = find(abs(genTimes - ack.ackedGenTime) <= tol, 1, 'last');
end


%% ------------------------------------------------------------
% INVARIANT 3: the ACK must match an attempt the sender actually made.
%
% A stale ACK whose attempt was already pruned is NOT a violation, so
% only flag when the acknowledged time is newer than what we hold.
% ------------------------------------------------------------

if isempty(idx)

    if ack.ackedGenTime > currentAckGenTime + tol

        net.unknownSeqAckCount = net.unknownSeqAckCount + 1;

        reportViolation(cfg, 'unknownSeqAck', ...
            'ACK for genTime %.6f on link (%d,%d) matches no attempt', ...
            ack.ackedGenTime, i, j);

    else

        % Late duplicate for something already superseded. Expected.
        net.staleAckDiscardedCount = net.staleAckDiscardedCount + 1;

    end

    return;

end


%% ------------------------------------------------------------
% INVARIANT 4: the channel cannot acknowledge a packet it dropped.
% ------------------------------------------------------------

if pend(idx).dropped

    net.ackForDroppedDataCount = net.ackForDroppedDataCount + 1;

    reportViolation(cfg, 'ackForDroppedData', ...
        'ACK for dropped packet genTime %.6f on link (%d,%d)', ...
        ack.ackedGenTime, i, j);

end


%% ------------------------------------------------------------
% INVARIANT 5: the sender never rolls back to older information.
%
% A superseded ACK is discarded, not applied.
% ------------------------------------------------------------

if ack.ackedGenTime <= currentAckGenTime + tol

    net.staleAckDiscardedCount = net.staleAckDiscardedCount + 1;

    return;

end


%% ------------------------------------------------------------
% Apply: this is the only place transmitter belief advances.
% ------------------------------------------------------------

if isLeaderLink

    txState.leaderAckPos(i,:) = pend(idx).pos;
    txState.leaderAckVel(i,:) = pend(idx).vel;
    txState.leaderAckGenTime(i) = ack.ackedGenTime;

    keep = [pend.genTime] > ack.ackedGenTime + tol;
    txState.leaderPending{i} = pend(keep);

    newAckGenTime = txState.leaderAckGenTime(i);

else

    txState.ackPos(i,j,:) = pend(idx).pos;
    txState.ackVel(i,j,:) = pend(idx).vel;
    txState.ackGenTime(i,j) = ack.ackedGenTime;

    keep = [pend.genTime] > ack.ackedGenTime + tol;
    txState.pending{i,j} = pend(keep);

    newAckGenTime = txState.ackGenTime(i,j);

end

net.ackUpdateCount = net.ackUpdateCount + 1;


%% ------------------------------------------------------------
% INVARIANT 6: post-conditions on the update just applied.
%
% Checked after the write rather than before it, so these catch a
% bug in the update itself and not merely a bad input.
% ------------------------------------------------------------

if newAckGenTime < currentAckGenTime - tol

    net.senderRollbackCount = net.senderRollbackCount + 1;

    reportViolation(cfg, 'senderRollback', ...
        'ackGenTime moved %.6f -> %.6f on link (%d,%d)', ...
        currentAckGenTime, newAckGenTime, i, j);

end


if newAckGenTime <= currentAckGenTime + tol

    net.staleAckAcceptedCount = net.staleAckAcceptedCount + 1;

    reportViolation(cfg, 'staleAckAccepted', ...
        'update did not advance belief: %.6f -> %.6f on link (%d,%d)', ...
        currentAckGenTime, newAckGenTime, i, j);

end

end


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function reportViolation(cfg, name, fmt, varargin)

if isfield(cfg,'ack') && isfield(cfg.ack,'assertInvariants') ...
        && cfg.ack.assertInvariants

    error('causalAck:%s', ...
        ['CAUSALITY VIOLATION [%s]: ' fmt], name, varargin{:});

end

end
