function [net, txState] = enqueueCausalAoIPackets( ...
    net, txState, P, V, leader, tk, cfg)
%ENQUEUECAUSALAOIPACKETS Causal AoI-aware transmission decision.
%
%   [net, txState] = enqueueCausalAoIPackets(net, txState, P, V, leader, tk, cfg)
%
% Same trigger policy as the ideal method: aoiAwareTriggerPolicy is called
% unchanged. The single difference is the information fed into it.
%
%   ideal   receiverAoI = tk - net.genTime(i,j) + 0.5*dt      (oracle)
%   causal  receiverAoI = tk - txState.ackGenTime(i,j) + 0.5*dt
%
% txState.ackGenTime only advances when an ACK arrives, so the causal
% estimate is an UPPER BOUND on true AoI: it does not reset when a packet
% lands but its ACK is still in flight. The transmitter is therefore
% pessimistic about staleness and transmits at least as often as the ideal
% method would. That bias is a consequence of causality, not a tuning choice.
%
% This function must never read net.genTime, net.leaderGenTime, net.Pij,
% net.Vij, net.leaderPos, net.leaderVel or net.valid. tests/test_causal_invariants
% enforces that statically.

N = cfg.swarm.N;

dt = cfg.swarm.dt;


%% ============================================================
% Neighbour links
%
% Receiver i, transmitter j.
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end

        net.triggerCheckCount = net.triggerCheckCount + 1;

        currentPos = P(j,:);
        currentVel = V(j,:);

        lastAckedPos = squeeze(txState.ackPos(i,j,:))';
        lastAckedVel = squeeze(txState.ackVel(i,j,:))';

        timeSinceLastTx = tk - txState.lastTxTime(i,j);

        % Transmitter-side ESTIMATE. No receiver register is consulted.
        estimatedAoI = tk - txState.ackGenTime(i,j) + 0.5*dt;

        [sendPacket, reason, triggerInfo] = aoiAwareTriggerPolicy( ...
            currentPos, ...
            currentVel, ...
            lastAckedPos, ...
            lastAckedVel, ...
            estimatedAoI, ...
            timeSinceLastTx, ...
            cfg);

        net = accumulateAdaptiveStats(net, triggerInfo);

        if ~sendPacket
            net = accountSuppression(net, triggerInfo);
            continue;
        end

        net = incrementTriggerReason(net, reason);

        [net, txState] = transmit( ...
            net, txState, i, j, tk, currentPos, currentVel, [], cfg, false);

    end

end


%% ============================================================
% Leader links
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end

    net.triggerCheckCount = net.triggerCheckCount + 1;

    currentPos = leader.pos';
    currentVel = leader.vel';

    lastAckedPos = txState.leaderAckPos(i,:);
    lastAckedVel = txState.leaderAckVel(i,:);

    timeSinceLastTx = tk - txState.leaderLastTxTime(i);

    estimatedAoI = tk - txState.leaderAckGenTime(i) + 0.5*dt;

    [sendPacket, reason, triggerInfo] = aoiAwareTriggerPolicy( ...
        currentPos, ...
        currentVel, ...
        lastAckedPos, ...
        lastAckedVel, ...
        estimatedAoI, ...
        timeSinceLastTx, ...
        cfg);

    net = accumulateAdaptiveStats(net, triggerInfo);

    if ~sendPacket
        net = accountSuppression(net, triggerInfo);
        continue;
    end

    net = incrementTriggerReason(net, reason);

    [net, txState] = transmit( ...
        net, txState, i, 1, tk, currentPos, currentVel, leader.acc', cfg, true);

end

end


%% ============================================================
% LOCAL FUNCTION
%
% One transmission attempt: record it, draw loss, draw delay, queue.
% Ordering matches the ideal implementation so the DATA RNG stream is
% consumed identically.
% ============================================================

function [net, txState] = transmit( ...
    net, txState, i, j, tk, currentPos, currentVel, leaderAcc, cfg, isLeaderLink)

net.txCount = net.txCount + 1;


%% ------------------------------------------------------------
% Sequence number and pending record
%
% Recorded BEFORE the loss draw, so a dropped packet is still known
% to the transmitter. That is what makes "ACK for dropped data"
% detectable rather than merely unlikely.
% ------------------------------------------------------------

rec.genTime = tk;
rec.pos     = currentPos;
rec.vel     = currentVel;
rec.dropped = false;

if isLeaderLink
    rec.seq = txState.leaderNextSeq(i);
    txState.leaderNextSeq(i) = rec.seq + 1;
    txState.leaderLastTxTime(i) = tk;
else
    rec.seq = txState.nextSeq(i,j);
    txState.nextSeq(i,j) = rec.seq + 1;
    txState.lastTxTime(i,j) = tk;
end


%% ------------------------------------------------------------
% Channel loss
% ------------------------------------------------------------

dropped = rand < cfg.net.packetLoss;

if dropped

    net.dropCount = net.dropCount + 1;

    rec.dropped = true;

    txState = pushPending(txState, i, j, rec, isLeaderLink);

    return;

end


txState = pushPending(txState, i, j, rec, isLeaderLink);


%% ------------------------------------------------------------
% Delay and jitter
% ------------------------------------------------------------

packetDelay = cfg.net.delay;

if cfg.net.jitterStd > 0
    packetDelay = packetDelay + cfg.net.jitterStd * randn;
end

packetDelay = max(packetDelay, 0);


pkt.genTime     = tk;
pkt.arrivalTime = tk + packetDelay;
pkt.pos         = currentPos;
pkt.vel         = currentVel;


if isLeaderLink

    pkt.acc = leaderAcc;

    q = net.leaderQueue{i};
    q{end+1} = pkt;
    net.leaderQueue{i} = q;

else

    q = net.queue{i,j};
    q{end+1} = pkt;
    net.queue{i,j} = q;

end

end


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function txState = pushPending(txState, i, j, rec, isLeaderLink)

if isLeaderLink
    q = txState.leaderPending{i};
    if isempty(q)
        q = rec;
    else
        q(end+1) = rec;
    end
    txState.leaderPending{i} = q;
else
    q = txState.pending{i,j};
    if isempty(q)
        q = rec;
    else
        q(end+1) = rec;
    end
    txState.pending{i,j} = q;
end

end


function net = accumulateAdaptiveStats(net, triggerInfo)

net.adaptiveScaleSum = ...
    net.adaptiveScaleSum + triggerInfo.adaptiveScale;

net.adaptiveScaleCount = ...
    net.adaptiveScaleCount + 1;

net.adaptiveScaleMinObserved = ...
    min(net.adaptiveScaleMinObserved, triggerInfo.adaptiveScale);

end


function net = accountSuppression(net, triggerInfo)

net.suppressedCount = net.suppressedCount + 1;

if triggerInfo.refractoryBlocked
    net.refractoryBlockedCount = net.refractoryBlockedCount + 1;
end

if triggerInfo.aoiCooldownBlocked
    net.aoiCooldownBlockedCount = net.aoiCooldownBlockedCount + 1;
end

end


function net = incrementTriggerReason(net, reason)

switch reason
    case 1
        net.positionTriggerCount = net.positionTriggerCount + 1;
    case 2
        net.velocityTriggerCount = net.velocityTriggerCount + 1;
    case 3
        net.aoiTriggerCount = net.aoiTriggerCount + 1;
    case 4
        net.timeoutTriggerCount = net.timeoutTriggerCount + 1;
end

end
