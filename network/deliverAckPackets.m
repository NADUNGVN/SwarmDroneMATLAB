function [net, txState] = deliverAckPackets(net, txState, tk, cfg)
%DELIVERACKPACKETS Apply arrived ACKs and enforce causality (v2).
%
%   [net, txState] = deliverAckPackets(net, txState, tk, cfg)
%
% The only function permitted to advance txState.ackGenTime / ackSeq /
% ackPos / ackVel. Everything the transmitter believes about the receiver
% enters here, from an ACK that actually arrived.
%
% v2 matches outstanding packets by SEQUENCE NUMBER, with genTime kept as an
% independent consistency check: a header whose seq and genTime disagree
% indicates a corrupted or fabricated ACK and is counted, never applied.
%
% ACKs are cumulative, so one ACK retires every outstanding packet up to and
% including the acknowledged sequence number.
%
% With cfg.ack.assertInvariants true, any violation raises immediately
% instead of being counted and ignored.

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

        [net, txState] = drainAckQueue(net, txState, i, j, tk, cfg, false);

    end

end


%% ============================================================
% Leader links
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end

    [net, txState] = drainAckQueue(net, txState, i, 1, tk, cfg, true);

end

end


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function [net, txState] = drainAckQueue(net, txState, i, j, tk, cfg, isLeaderLink)

tol = 1e-10;

if isLeaderLink
    q = net.leaderAckQueue{i};
else
    q = net.ackQueue{i,j};
end

if isempty(q)
    return;
end

arrivalTimes = cellfun(@(a) a.arrivalTime, q);

% Blackout: node j is the ACK's destination, and its radio is off. An
% ACK already in flight when the outage began arrives to a dead antenna
% and is lost. Holding it back to be applied after the node returns
% would let the transmitter learn something it never actually heard.
if nodeIsDark(cfg, j, tk)

    due = arrivalTimes <= tk + tol;

    if any(due)

        net.ackDropCount = net.ackDropCount + nnz(due);

        if isLeaderLink
            net.leaderAckQueue{i} = q(~due);
        else
            net.ackQueue{i,j} = q(~due);
        end

    end

    return;

end

dueIdx = find(arrivalTimes <= tk + tol);

if isempty(dueIdx)
    return;
end

% Process in arrival order, so an ACK overtaken under jitter is seen
% as the late arrival it is.
[~, order] = sort(arrivalTimes(dueIdx));

dueIdx = dueIdx(order);

keep = true(size(q));

for m = 1:numel(dueIdx)

    n = dueIdx(m);

    keep(n) = false;

    [net, txState] = applyAck(net, txState, q{n}, i, j, tk, cfg, isLeaderLink);

end

if isLeaderLink
    net.leaderAckQueue{i} = q(keep);
else
    net.ackQueue{i,j} = q(keep);
end

end


%% ============================================================
% LOCAL FUNCTION
%
% Validate one ACK against every invariant, then apply it.
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
        'arrived %.6f, created %.6f', ack.arrivalTime, ack.acceptTime);

end


%% ------------------------------------------------------------
% INVARIANT 2: no timestamp may come from the future.
% ------------------------------------------------------------

if ack.ackedGenTime > tk + tol

    net.futureGenTimeCount = net.futureGenTimeCount + 1;

    reportViolation(cfg, 'futureGenTime', ...
        'at t=%.6f acknowledges genTime %.6f', tk, ack.ackedGenTime);

end


%% ------------------------------------------------------------
% Current transmitter belief
% ------------------------------------------------------------

if isLeaderLink
    outst      = txState.leaderOutstanding{i};
    currentGen = txState.leaderAckGenTime(i);
    currentSeq = txState.leaderAckSeq(i);
else
    outst      = txState.outstanding{i,j};
    currentGen = txState.ackGenTime(i,j);
    currentSeq = txState.ackSeq(i,j);
end


%% ------------------------------------------------------------
% Match by SEQUENCE NUMBER.
% ------------------------------------------------------------

idx = [];

if ~isempty(outst) && ~isnan(ack.ackedSeq)
    idx = find([outst.seq] == ack.ackedSeq, 1, 'last');
end


%% ------------------------------------------------------------
% INVARIANT 3: the ACK must name a packet the sender actually sent.
%
% A cumulative ACK for something already retired is a normal late
% duplicate, not a violation.
% ------------------------------------------------------------

if isempty(idx)

    if ack.ackedSeq > currentSeq

        net.unknownSeqAckCount = net.unknownSeqAckCount + 1;

        reportViolation(cfg, 'unknownSeqAck', ...
            'seq %g on link (%d,%d) matches no outstanding packet', ...
            ack.ackedSeq, i, j);

    else

        net.duplicateAckCount = net.duplicateAckCount + 1;

        net.staleAckDiscardedCount = net.staleAckDiscardedCount + 1;

    end

    return;

end


%% ------------------------------------------------------------
% CONSISTENCY: seq and genTime must describe the same packet.
%
% Matching on seq alone would accept a header whose two identifiers
% disagree; checking both is what makes the sequence number load
% bearing rather than decorative.
% ------------------------------------------------------------

if abs(outst(idx).genTime - ack.ackedGenTime) > tol

    net.seqGenTimeMismatchCount = net.seqGenTimeMismatchCount + 1;

    reportViolation(cfg, 'seqGenTimeMismatch', ...
        'seq %g carries genTime %.6f but sender recorded %.6f', ...
        ack.ackedSeq, ack.ackedGenTime, outst(idx).genTime);

    return;

end


%% ------------------------------------------------------------
% INVARIANT 4: the channel cannot acknowledge a packet it dropped.
% ------------------------------------------------------------

if outst(idx).dropped

    net.ackForDroppedDataCount = net.ackForDroppedDataCount + 1;

    reportViolation(cfg, 'ackForDroppedData', ...
        'seq %g on link (%d,%d) was dropped in flight', ack.ackedSeq, i, j);

end


%% ------------------------------------------------------------
% INVARIANT 5: never roll back to older information.
% ------------------------------------------------------------

if ack.ackedGenTime <= currentGen + tol

    net.staleAckDiscardedCount = net.staleAckDiscardedCount + 1;

    return;

end


%% ------------------------------------------------------------
% Apply. Cumulative: retire everything up to this sequence number.
% ------------------------------------------------------------

if isLeaderLink

    txState.leaderAckPos(i,:)   = outst(idx).pos;
    txState.leaderAckVel(i,:)   = outst(idx).vel;
    txState.leaderAckGenTime(i) = ack.ackedGenTime;
    txState.leaderAckSeq(i)     = ack.ackedSeq;

    txState.leaderOutstanding{i} = outst([outst.seq] > ack.ackedSeq);

    newGen = txState.leaderAckGenTime(i);

else

    txState.ackPos(i,j,:)   = outst(idx).pos;
    txState.ackVel(i,j,:)   = outst(idx).vel;
    txState.ackGenTime(i,j) = ack.ackedGenTime;
    txState.ackSeq(i,j)     = ack.ackedSeq;

    txState.outstanding{i,j} = outst([outst.seq] > ack.ackedSeq);

    newGen = txState.ackGenTime(i,j);

end

net.ackUpdateCount = net.ackUpdateCount + 1;


%% ------------------------------------------------------------
% INVARIANT 6: post-conditions on the update just applied.
% ------------------------------------------------------------

if newGen < currentGen - tol

    net.senderRollbackCount = net.senderRollbackCount + 1;

    reportViolation(cfg, 'senderRollback', ...
        'ackGenTime moved %.6f -> %.6f on link (%d,%d)', ...
        currentGen, newGen, i, j);

end

if newGen <= currentGen + tol

    net.staleAckAcceptedCount = net.staleAckAcceptedCount + 1;

    reportViolation(cfg, 'staleAckAccepted', ...
        'update did not advance belief: %.6f -> %.6f on link (%d,%d)', ...
        currentGen, newGen, i, j);

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


%% ============================================================
% LOCAL FUNCTION
%
% Node communication blackout. True when node n has its radio off at
% time tk. See utils/generateBlackoutRealization.m.
% ============================================================

function dark = nodeIsDark(cfg, n, tk)

dark = false;

if ~isfield(cfg,'blackout') || isempty(cfg.blackout)
    return;
end

if ~cfg.blackout.node(n)
    return;
end

dark = (tk >= cfg.blackout.tStart) && (tk <= cfg.blackout.tEnd);

end
