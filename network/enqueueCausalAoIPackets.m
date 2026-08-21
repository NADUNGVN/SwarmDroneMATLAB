function [net, txState] = enqueueCausalAoIPackets( ...
    net, txState, P, V, leader, tk, cfg, netTrace, k)
%ENQUEUECAUSALAOIPACKETS Causal AoI-aware transmission decision (v2).
%
%   [net, txState] = enqueueCausalAoIPackets(net, txState, P, V, leader, tk, cfg)
%
% The trigger policy itself (aoiAwareTriggerPolicy) is reused unchanged, so
% the only variables that differ from the ideal method are what the sender
% knows and which memory each decision consults.
%
% DUAL MEMORY, the defining change in v2:
%
%   innovation   ||p(t) - sentPos||   measured against the last state PUT
%                                     ON THE WIRE. Once a packet carrying
%                                     the current state is in flight, the
%                                     innovation is zero and the trigger
%                                     stops firing on it. That is in-flight
%                                     suppression, achieved without any
%                                     retransmission timer.
%
%   freshness    tk - ackGenTime      measured against the last CONFIRMED
%                                     state, and used only for the AoI
%                                     branch and the adaptive threshold.
%
% v1 used the acked state for both. During a round trip the innovation
% therefore never appeared to shrink, so the transmitter kept re-sending
% state the receiver was already about to have.
%
% Loss recovery needs no timer: a dropped packet leaves ackGenTime frozen,
% the estimated AoI grows past the threshold, the adaptive scale sharpens
% and the AoI branch fires. maxSilence remains the final backstop.
%
% Optional ablation switches:
%
%   cfg.causal.useAckFeedback   false -> freshness estimated OPEN LOOP from
%                                        sentGenTime, i.e. the transmitter
%                                        assumes every packet landed
%   cfg.causal.useAdaptiveScale false -> adaptive threshold pinned to
%                                        scaleBase
%
% This function must never read net.genTime, net.leaderGenTime, net.Pij,
% net.Vij, net.leaderPos, net.leaderVel or net.valid.
% tests/test_causal_invariants enforces that statically.

if nargin < 8
    netTrace = [];
end

if nargin < 9
    k = 0;
end

N = cfg.swarm.N;

dt = cfg.swarm.dt;


% Broadcast accounting (EXP07C). Passive; see initQueuedNetworkState.
senderFired = false(N,1);

leaderFired = false;

useAck      = cfg.causal.useAckFeedback;
useV3       = cfg.causal.innovationPriority;
triggerCfg  = cfg;

if ~cfg.causal.useAdaptiveScale
    % Pinning the floor to the base value makes adaptiveScale constant
    % inside the unchanged policy, so no separate code path is needed.
    triggerCfg.aoiEvent.aoiStateScaleMin = cfg.aoiEvent.aoiStateScaleBase;
end


%% ============================================================
% Neighbour links: receiver i, transmitter j
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end

        net.triggerCheckCount = net.triggerCheckCount + 1;

        currentPos = P(j,:);
        currentVel = V(j,:);

        % Innovation reference: what is already on the wire.
        sentPos = squeeze(txState.sentPos(i,j,:))';
        sentVel = squeeze(txState.sentVel(i,j,:))';

        % Freshness reference: what the receiver has confirmed.
        if useAck
            freshGenTime = txState.ackGenTime(i,j);
        else
            freshGenTime = txState.sentGenTime(i,j);
        end

        estimatedAoI = tk - freshGenTime + 0.5*dt;

        timeSinceLastTx = tk - txState.lastTxTime(i,j);

        nOutstanding = numel(txState.outstanding{i,j});

        if useV3
            [sendPacket, reason, triggerInfo] = causalInnovationTriggerPolicy( ...
                currentPos, currentVel, sentPos, sentVel, ...
                estimatedAoI, timeSinceLastTx, nOutstanding, triggerCfg);
            net = accountV3Branch(net, triggerInfo, ...
                cfg, currentPos, currentVel, sentPos, sentVel, nOutstanding);
        else
            [sendPacket, reason, triggerInfo] = aoiAwareTriggerPolicy( ...
                currentPos, ...
                currentVel, ...
                sentPos, ...
                sentVel, ...
                estimatedAoI, ...
                timeSinceLastTx, ...
                triggerCfg);
        end

        net = accumulateAdaptiveStats(net, triggerInfo);

        net = accountOutstanding(net, nOutstanding);

        if ~sendPacket

            net = accountSuppression(net, triggerInfo);

            % Measure what the dual memory bought: would v1 have fired
            % here, comparing against the ACKED state instead?
            ackPos = squeeze(txState.ackPos(i,j,:))';
            ackVel = squeeze(txState.ackVel(i,j,:))';

            if norm(currentPos - ackPos) >= cfg.aoiEvent.posThreshold ...
                    || norm(currentVel - ackVel) >= cfg.aoiEvent.velThreshold
                net.suppressedInFlightCount = net.suppressedInFlightCount + 1;
            end

            continue;

        end

        net = incrementTriggerReason(net, reason, useV3);

        senderFired(j) = true;

        [net, txState] = transmit( ...
            net, txState, i, j, tk, currentPos, currentVel, [], cfg, false, ...
            netTrace, k);

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

    sentPos = txState.leaderSentPos(i,:);
    sentVel = txState.leaderSentVel(i,:);

    if useAck
        freshGenTime = txState.leaderAckGenTime(i);
    else
        freshGenTime = txState.leaderSentGenTime(i);
    end

    estimatedAoI = tk - freshGenTime + 0.5*dt;

    timeSinceLastTx = tk - txState.leaderLastTxTime(i);

    nOutstanding = numel(txState.leaderOutstanding{i});

    if useV3
        [sendPacket, reason, triggerInfo] = causalInnovationTriggerPolicy( ...
            currentPos, currentVel, sentPos, sentVel, ...
            estimatedAoI, timeSinceLastTx, nOutstanding, triggerCfg);
        net = accountV3Branch(net, triggerInfo, ...
            cfg, currentPos, currentVel, sentPos, sentVel, nOutstanding);
    else
        [sendPacket, reason, triggerInfo] = aoiAwareTriggerPolicy( ...
            currentPos, ...
            currentVel, ...
            sentPos, ...
            sentVel, ...
            estimatedAoI, ...
            timeSinceLastTx, ...
            triggerCfg);
    end

    net = accumulateAdaptiveStats(net, triggerInfo);

    net = accountOutstanding(net, nOutstanding);

    if ~sendPacket

        net = accountSuppression(net, triggerInfo);

        ackPos = txState.leaderAckPos(i,:);
        ackVel = txState.leaderAckVel(i,:);

        if norm(currentPos - ackPos) >= cfg.aoiEvent.posThreshold ...
                || norm(currentVel - ackVel) >= cfg.aoiEvent.velThreshold
            net.suppressedInFlightCount = net.suppressedInFlightCount + 1;
        end

        continue;

    end

    net = incrementTriggerReason(net, reason, useV3);

    leaderFired = true;

    [net, txState] = transmit( ...
        net, txState, i, 1, tk, currentPos, currentVel, leader.acc', cfg, true, ...
        netTrace, k);

end


net.broadcastCount = net.broadcastCount + nnz(senderFired) + leaderFired;

end


%% ============================================================
% LOCAL FUNCTION
%
% One transmission: assign a sequence number, record it as sent and
% outstanding, publish it on the wire table, draw loss, draw delay,
% queue the packet.
% ============================================================

function [net, txState] = transmit( ...
    net, txState, i, j, tk, currentPos, currentVel, leaderAcc, cfg, isLeaderLink, ...
    netTrace, k)

net.txCount = net.txCount + 1;


% Liveness diagnostic. maxSilence guarantees no link stays quiet longer
% than 0.50 s, so the largest observed gap is a direct test of that
% guarantee and of the absence of deadlock. Recorded, never consulted.
if isLeaderLink
    prevTx = txState.leaderLastTxTime(i);
else
    prevTx = txState.lastTxTime(i,j);
end

net.maxInterTxGap = max(net.maxInterTxGap, tk - prevTx);


if isLeaderLink
    seq = txState.leaderSentSeq(i) + 1;
    txState.leaderSentSeq(i)     = seq;
    txState.leaderSentPos(i,:)   = currentPos;
    txState.leaderSentVel(i,:)   = currentVel;
    txState.leaderSentGenTime(i) = tk;
    txState.leaderLastTxTime(i)  = tk;
else
    seq = txState.sentSeq(i,j) + 1;
    txState.sentSeq(i,j)     = seq;
    txState.sentPos(i,j,:)   = currentPos;
    txState.sentVel(i,j,:)   = currentVel;
    txState.sentGenTime(i,j) = tk;
    txState.lastTxTime(i,j)  = tk;
end


rec.genTime = tk;
rec.seq     = seq;
rec.pos     = currentPos;
rec.vel     = currentVel;
rec.dropped = false;


%% ------------------------------------------------------------
% Channel loss
%
% The outstanding record is kept even when the packet is dropped, so
% "ACK for dropped data" is detectable rather than merely unlikely.
% ------------------------------------------------------------

% Delivery-layer link failure. The outstanding record is still kept,
% exactly as for a channel drop, so the sender remains unaware and
% recovery still runs through maxSilence.
if linkIsDown(cfg, i, j, tk)

    net.dropCount = net.dropCount + 1;

    rec.dropped = true;

    txState = pushOutstanding(txState, i, j, rec, isLeaderLink);

    return;

end


if drawLoss(netTrace,k,i,j,isLeaderLink) < cfg.net.packetLoss

    net.dropCount = net.dropCount + 1;

    rec.dropped = true;

    txState = pushOutstanding(txState, i, j, rec, isLeaderLink);

    return;

end


txState = pushOutstanding(txState, i, j, rec, isLeaderLink);


%% ------------------------------------------------------------
% Delay and jitter
% ------------------------------------------------------------

packetDelay = cfg.net.delay;

if cfg.net.jitterStd > 0
    packetDelay = packetDelay + ...
        cfg.net.jitterStd * drawJitter(netTrace,k,i,j,isLeaderLink);
end

packetDelay = max(packetDelay, 0);


% seq is a header field: it travels with the packet.
pkt.genTime     = tk;
pkt.seq         = seq;
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

function txState = pushOutstanding(txState, i, j, rec, isLeaderLink)

if isLeaderLink
    q = txState.leaderOutstanding{i};
    if isempty(q), q = rec; else, q(end+1) = rec; end
    txState.leaderOutstanding{i} = q;
else
    q = txState.outstanding{i,j};
    if isempty(q), q = rec; else, q(end+1) = rec; end
    txState.outstanding{i,j} = q;
end

end


function net = accountOutstanding(net, n)

net.outstandingSum   = net.outstandingSum + n;
net.outstandingCount = net.outstandingCount + 1;
net.outstandingMax   = max(net.outstandingMax, n);

end


function net = accumulateAdaptiveStats(net, triggerInfo)

net.adaptiveScaleSum   = net.adaptiveScaleSum + triggerInfo.adaptiveScale;
net.adaptiveScaleCount = net.adaptiveScaleCount + 1;

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


function net = incrementTriggerReason(net, reason, useV3)

if useV3
    % v3 branch codes: 1/2 hard, 3 adaptive new info, 4 refresh, 5 timeout.
    switch reason
        case 1
            net.positionTriggerCount = net.positionTriggerCount + 1;
            net.hardInnovationCount  = net.hardInnovationCount + 1;
        case 2
            net.velocityTriggerCount = net.velocityTriggerCount + 1;
            net.hardInnovationCount  = net.hardInnovationCount + 1;
        case 3
            net.aoiTriggerCount        = net.aoiTriggerCount + 1;
            net.adaptiveNewInfoCount   = net.adaptiveNewInfoCount + 1;
        case 4
            net.refreshCount = net.refreshCount + 1;
        case 5
            net.timeoutTriggerCount = net.timeoutTriggerCount + 1;
    end
    return;
end

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


function net = accountV3Branch(net, info, cfg, cp, cv, sp, sv, nOutstanding)
%ACCOUNTV3BRANCH Branch bookkeeping and the two v3 protocol invariants.

if info.refreshCooldownBlocked
    net.refreshCooldownBlockedCount = net.refreshCooldownBlockedCount + 1;
end

if info.refreshInFlightBlocked
    net.refreshInFlightBlockedCount = net.refreshInFlightBlockedCount + 1;
end

% INVARIANT: a branch that claims to carry new information must actually
% have innovation against the last SENT state. Checked independently of
% the policy rather than trusting its own flags.
if info.branch >= 1 && info.branch <= 3

    dp = norm(cp(:) - sp(:));
    dv = norm(cv(:) - sv(:));

    floorP = cfg.aoiEvent.aoiStateScaleMin * cfg.aoiEvent.posThreshold;
    floorV = cfg.aoiEvent.aoiStateScaleMin * cfg.aoiEvent.velThreshold;

    if dp < floorP && dv < floorV
        net.newInfoBypassWithoutInnovationCount = ...
            net.newInfoBypassWithoutInnovationCount + 1;
    end

end

% INVARIANT: the refresh branch must never fire while a packet is still
% outstanding, otherwise it is duplicating something already in flight.
if info.branch == 4 && nOutstanding > 0
    net.refreshWhileUsefulPacketInFlightCount = ...
        net.refreshWhileUsefulPacketInFlightCount + 1;
end

end


%% ============================================================
% LOCAL FUNCTIONS
%
% Read the pre-drawn outcome when a trace is present, otherwise fall
% back to the inline draw the locked experiments used.
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
