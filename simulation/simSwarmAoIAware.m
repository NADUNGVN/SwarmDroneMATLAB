function out = simSwarmAoIAware(cfg)

% ============================================================
% SIMSWARMAOIAWARE
%
% Adaptive AoI-aware event-triggered swarm simulation.
%
% IMPORTANT:
%
% State-change error is now measured relative to the latest
% SUCCESSFULLY ACCEPTED receiver state:
%
%   e_p = p_current - p_lastAccepted
%   e_v = v_current - v_lastAccepted
%
% NOT relative to the latest transmission attempt.
%
% Therefore:
%
%   packet transmitted + dropped
%       -> reference state is NOT reset
%
%   packet transmitted + delayed
%       -> reference state is NOT reset until accepted
%
%   stale/out-of-order packet
%       -> reference state is NOT reset
%
%   packet successfully accepted
%       -> reference state is updated
%
% This is consistent with the receiver-AoI feedback assumption
% already used by the AoI-aware trigger.
%
% ============================================================


%% ============================================================
% AoI-aware defaults
% ============================================================

if ~isfield(cfg,'aoiEvent')
    cfg.aoiEvent = struct();
end

if ~isfield(cfg.aoiEvent,'posThreshold')
    cfg.aoiEvent.posThreshold = 0.04;
end

if ~isfield(cfg.aoiEvent,'velThreshold')
    cfg.aoiEvent.velThreshold = 0.08;
end

if ~isfield(cfg.aoiEvent,'aoiThreshold')
    cfg.aoiEvent.aoiThreshold = 0.16;
end

if ~isfield(cfg.aoiEvent,'maxSilence')
    cfg.aoiEvent.maxSilence = 0.50;
end

if ~isfield(cfg.aoiEvent,'minInterTx')
    cfg.aoiEvent.minInterTx = cfg.swarm.dt;
end

if ~isfield(cfg.aoiEvent,'aoiStateScaleBase')
    cfg.aoiEvent.aoiStateScaleBase = 0.50;
end

if ~isfield(cfg.aoiEvent,'aoiStateScaleMin')
    cfg.aoiEvent.aoiStateScaleMin = 0.20;
end

if ~isfield(cfg.aoiEvent,'aoiAdaptRange')
    cfg.aoiEvent.aoiAdaptRange = 1.00;
end

if ~isfield(cfg.aoiEvent,'aoiMinInterTx')
    cfg.aoiEvent.aoiMinInterTx = 0.10;
end


%% ============================================================
% Random generator
% ============================================================

rng(cfg.net.seed);


%% ============================================================
% Simulation parameters
% ============================================================

dt = cfg.swarm.dt;

t = (0:dt:cfg.swarm.T)';

K = numel(t);

N = cfg.swarm.N;


%% ============================================================
% Initial swarm state
% ============================================================

P = cfg.swarm.initialPositions;

V = cfg.swarm.initialVelocities;


%% ============================================================
% Logs
% ============================================================

Plog = zeros(K,N,3);

Vlog = zeros(K,N,3);

Alog = zeros(K,N,3);

LeaderPos = zeros(K,3);

LeaderVel = zeros(K,3);

MeanAoILog = zeros(K,1);


%% ============================================================
% Link-level AoI logs
% ============================================================

NeighborAoILog = nan(K,N,N);

LeaderAoILog = nan(K,N);


%% ============================================================
% Initial leader
% ============================================================

leader = leaderReference(0);


%% ============================================================
% Network initialization
% ============================================================

net = initQueuedNetworkState( ...
    P, ...
    V, ...
    leader, ...
    cfg);


%% ============================================================
% Trigger statistics
% ============================================================

net.triggerCheckCount = 0;

net.suppressedCount = 0;

net.refractoryBlockedCount = 0;

net.aoiCooldownBlockedCount = 0;

net.positionTriggerCount = 0;

net.velocityTriggerCount = 0;

net.aoiTriggerCount = 0;

net.timeoutTriggerCount = 0;


%% ============================================================
% Adaptive-scale diagnostics
% ============================================================

net.adaptiveScaleSum = 0;

net.adaptiveScaleCount = 0;

net.adaptiveScaleMinObserved = inf;


%% ============================================================
% ACK / accepted-state diagnostics
% ============================================================

net.ackUpdateCount = 0;

net.ackSyncMissCount = 0;


%% ============================================================
% Transmitter memory
%
% IMPORTANT:
%
% ackPos / ackVel represent the state corresponding to the
% newest packet SUCCESSFULLY ACCEPTED by each receiver.
%
% lastTxTime is still the most recent transmission ATTEMPT
% and is used only for rate limiting / cooldown.
%
% pending contains attempted packets so that when
% net.genTime advances we can identify exactly which state
% was successfully accepted.
% ============================================================

txState = initializeAoITxState( ...
    P, ...
    V, ...
    leader, ...
    cfg, ...
    net);


%% ============================================================
% Simulation loop
% ============================================================

for k = 1:K

    tk = t(k);


    %% --------------------------------------------------------
    % Leader
    % ---------------------------------------------------------

    leader = leaderReference(tk);

    P(1,:) = leader.pos';

    V(1,:) = leader.vel';


    %% --------------------------------------------------------
    % STEP 1
    %
    % Deliver packets already due at current time.
    % ---------------------------------------------------------

    net = deliverNetworkPackets( ...
        net, ...
        tk, ...
        cfg);


    %% --------------------------------------------------------
    % STEP 2
    %
    % Synchronize transmitter feedback memory with packets
    % actually ACCEPTED by receivers.
    %
    % This occurs BEFORE trigger evaluation so state-change
    % error uses the freshest acknowledged state.
    % ---------------------------------------------------------

    [txState,net] = syncAcceptedStateMemory( ...
        txState, ...
        net, ...
        cfg);


    %% --------------------------------------------------------
    % STEP 3
    %
    % Evaluate adaptive AoI-aware trigger.
    % ---------------------------------------------------------

    [net,txState] = enqueueAoIAwarePackets( ...
        net, ...
        txState, ...
        P, ...
        V, ...
        leader, ...
        tk, ...
        cfg);


    %% --------------------------------------------------------
    % STEP 4
    %
    % Deliver newly generated zero-delay packets immediately.
    % ---------------------------------------------------------

    net = deliverNetworkPackets( ...
        net, ...
        tk, ...
        cfg);


    %% --------------------------------------------------------
    % STEP 5
    %
    % Synchronize again.
    %
    % Necessary for zero-delay packets accepted during this
    % same simulation timestep.
    % ---------------------------------------------------------

    [txState,net] = syncAcceptedStateMemory( ...
        txState, ...
        net, ...
        cfg);


    %% --------------------------------------------------------
    % Formation controller
    % ---------------------------------------------------------

    accCmd = distributedFormationPolicy( ...
        P, ...
        V, ...
        leader, ...
        cfg, ...
        net);


    %% --------------------------------------------------------
    % State logging
    % ---------------------------------------------------------

    Plog(k,:,:) = P;

    Vlog(k,:,:) = V;

    Alog(k,:,:) = accCmd;

    LeaderPos(k,:) = leader.pos';

    LeaderVel(k,:) = leader.vel';


    %% --------------------------------------------------------
    % AoI logging
    % ---------------------------------------------------------

    ageSamples = [];


    for i = 1:N

        for j = 1:N

            if cfg.swarm.A(i,j) == 0
                continue;
            end


            age = ...
                tk ...
                - net.genTime(i,j) ...
                + 0.5*dt;


            NeighborAoILog(k,i,j) = age;


            ageSamples(end+1) = ...
                age; %#ok<AGROW>

        end


        if cfg.swarm.pin(i)

            age = ...
                tk ...
                - net.leaderGenTime(i) ...
                + 0.5*dt;


            LeaderAoILog(k,i) = age;


            ageSamples(end+1) = ...
                age; %#ok<AGROW>

        end

    end


    if isempty(ageSamples)

        MeanAoILog(k) = NaN;

    else

        MeanAoILog(k) = mean(ageSamples);

    end


    %% --------------------------------------------------------
    % Final sample
    % ---------------------------------------------------------

    if k == K
        break;
    end


    %% --------------------------------------------------------
    % Double-integrator follower dynamics
    % ---------------------------------------------------------

    for i = 2:N

        V(i,:) = ...
            V(i,:) ...
            + dt*accCmd(i,:);


        P(i,:) = ...
            P(i,:) ...
            + dt*V(i,:);

    end

end


%% ============================================================
% Standard outputs
% ============================================================

out.t = t;

out.P = Plog;

out.V = Vlog;

out.A = Alog;

out.LeaderPos = LeaderPos;

out.LeaderVel = LeaderVel;

out.meanAoI = MeanAoILog;


%% ============================================================
% Link-level AoI
% ============================================================

out.neighborAoI = NeighborAoILog;

out.leaderAoI = LeaderAoILog;


%% ============================================================
% Network statistics
% ============================================================

out.txCount = net.txCount;

out.rxCount = net.rxCount;

out.dropCount = net.dropCount;

out.staleDiscardCount = ...
    net.staleDiscardCount;


out.PDR = ...
    1 ...
    - net.dropCount ...
    / max(net.txCount,1);


out.arrivalRatio = ...
    net.rxCount ...
    / max(net.txCount,1);


out.staleDiscardRatio = ...
    net.staleDiscardCount ...
    / max(net.rxCount,1);


out.effectiveUpdateRatio = ...
    ( ...
    net.rxCount ...
    - net.staleDiscardCount ...
    ) ...
    / max(net.txCount,1);


%% ============================================================
% ACK statistics
% ============================================================

out.ackUpdateCount = ...
    net.ackUpdateCount;


out.ackSyncMissCount = ...
    net.ackSyncMissCount;


%% ============================================================
% Trigger statistics
% ============================================================

out.triggerCheckCount = ...
    net.triggerCheckCount;


out.suppressedCount = ...
    net.suppressedCount;


out.refractoryBlockedCount = ...
    net.refractoryBlockedCount;


out.aoiCooldownBlockedCount = ...
    net.aoiCooldownBlockedCount;


out.positionTriggerCount = ...
    net.positionTriggerCount;


out.velocityTriggerCount = ...
    net.velocityTriggerCount;


out.aoiTriggerCount = ...
    net.aoiTriggerCount;


out.timeoutTriggerCount = ...
    net.timeoutTriggerCount;


%% ------------------------------------------------------------
% Trigger ratios
% ------------------------------------------------------------

out.suppressionRatio = ...
    net.suppressedCount ...
    / max(net.triggerCheckCount,1);


out.refractoryBlockedRatio = ...
    net.refractoryBlockedCount ...
    / max(net.triggerCheckCount,1);


out.aoiCooldownBlockedRatio = ...
    net.aoiCooldownBlockedCount ...
    / max(net.triggerCheckCount,1);


out.positionTriggerRatio = ...
    net.positionTriggerCount ...
    / max(net.txCount,1);


out.velocityTriggerRatio = ...
    net.velocityTriggerCount ...
    / max(net.txCount,1);


out.aoiTriggerRatio = ...
    net.aoiTriggerCount ...
    / max(net.txCount,1);


out.timeoutTriggerRatio = ...
    net.timeoutTriggerCount ...
    / max(net.txCount,1);


%% ============================================================
% Adaptive threshold diagnostics
% ============================================================

if net.adaptiveScaleCount > 0

    out.meanAdaptiveScale = ...
        net.adaptiveScaleSum ...
        / net.adaptiveScaleCount;


    out.minAdaptiveScale = ...
        net.adaptiveScaleMinObserved;

else

    out.meanAdaptiveScale = ...
        cfg.aoiEvent.aoiStateScaleBase;


    out.minAdaptiveScale = ...
        cfg.aoiEvent.aoiStateScaleBase;

end


%% ============================================================
% Transmission rate
% ============================================================

missionTime = ...
    t(end) ...
    - t(1);


nChannels = ...
    nnz(cfg.swarm.A) ...
    + sum(cfg.swarm.pin);


out.txRateTotal = ...
    out.txCount ...
    / max(missionTime,eps);


out.txRatePerChannel = ...
    out.txRateTotal ...
    / max(nChannels,1);


end


%% ============================================================
% LOCAL FUNCTION
%
% Generate AoI-aware packets.
%
% State-change reference:
%
%   txState.ackPos
%   txState.ackVel
%
% These are updated only after successful receiver acceptance.
% ============================================================

function [net,txState] = enqueueAoIAwarePackets( ...
    net, ...
    txState, ...
    P, ...
    V, ...
    leader, ...
    tk, ...
    cfg)

N = cfg.swarm.N;

dt = cfg.swarm.dt;


%% ============================================================
% Neighbor links
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end


        net.triggerCheckCount = ...
            net.triggerCheckCount + 1;


        %% ----------------------------------------------------
        % Current transmitter state
        % -----------------------------------------------------

        currentPos = P(j,:);

        currentVel = V(j,:);


        %% ----------------------------------------------------
        % Latest SUCCESSFULLY ACCEPTED receiver state
        % -----------------------------------------------------

        lastAcceptedPos = ...
            squeeze( ...
            txState.ackPos(i,j,:))';


        lastAcceptedVel = ...
            squeeze( ...
            txState.ackVel(i,j,:))';


        %% ----------------------------------------------------
        % Time since most recent ATTEMPT
        %
        % Used only for rate limiting / cooldown.
        % -----------------------------------------------------

        timeSinceLastTx = ...
            tk ...
            - txState.lastTxTime(i,j);


        %% ----------------------------------------------------
        % Receiver AoI
        % -----------------------------------------------------

        receiverAoI = ...
            tk ...
            - net.genTime(i,j) ...
            + 0.5*dt;


        %% ----------------------------------------------------
        % Trigger
        % -----------------------------------------------------

        [sendPacket,reason,triggerInfo] = ...
            aoiAwareTriggerPolicy( ...
            currentPos, ...
            currentVel, ...
            lastAcceptedPos, ...
            lastAcceptedVel, ...
            receiverAoI, ...
            timeSinceLastTx, ...
            cfg);


        %% ----------------------------------------------------
        % Adaptive diagnostics
        % -----------------------------------------------------

        net.adaptiveScaleSum = ...
            net.adaptiveScaleSum ...
            + triggerInfo.adaptiveScale;


        net.adaptiveScaleCount = ...
            net.adaptiveScaleCount + 1;


        net.adaptiveScaleMinObserved = ...
            min( ...
            net.adaptiveScaleMinObserved, ...
            triggerInfo.adaptiveScale);


        %% ----------------------------------------------------
        % No transmission
        % -----------------------------------------------------

        if ~sendPacket

            net.suppressedCount = ...
                net.suppressedCount + 1;


            if triggerInfo.refractoryBlocked

                net.refractoryBlockedCount = ...
                    net.refractoryBlockedCount + 1;

            end


            if triggerInfo.aoiCooldownBlocked

                net.aoiCooldownBlockedCount = ...
                    net.aoiCooldownBlockedCount + 1;

            end


            continue;

        end


        %% ----------------------------------------------------
        % Trigger reason
        % -----------------------------------------------------

        net = incrementTriggerReason( ...
            net, ...
            reason);


        %% ----------------------------------------------------
        % Transmission attempt
        % -----------------------------------------------------

        net.txCount = ...
            net.txCount + 1;


        txState.lastTxTime(i,j) = ...
            tk;


        %% ----------------------------------------------------
        % Store attempted packet in ACK history
        %
        % IMPORTANT:
        %
        % ackPos / ackVel are NOT changed here.
        % -----------------------------------------------------

        txState = storePendingNeighborPacket( ...
            txState, ...
            i, ...
            j, ...
            tk, ...
            currentPos, ...
            currentVel);


        %% ----------------------------------------------------
        % Packet loss
        % -----------------------------------------------------

        if rand < cfg.net.packetLoss

            net.dropCount = ...
                net.dropCount + 1;

            continue;

        end


        %% ----------------------------------------------------
        % Delay + jitter
        % -----------------------------------------------------

        packetDelay = ...
            cfg.net.delay;


        if cfg.net.jitterStd > 0

            packetDelay = ...
                packetDelay ...
                + cfg.net.jitterStd ...
                * randn;

        end


        packetDelay = ...
            max(packetDelay,0);


        %% ----------------------------------------------------
        % Packet
        % -----------------------------------------------------

        pkt.genTime = tk;

        pkt.arrivalTime = ...
            tk ...
            + packetDelay;

        pkt.pos = currentPos;

        pkt.vel = currentVel;


        %% ----------------------------------------------------
        % Queue
        % -----------------------------------------------------

        q = net.queue{i,j};

        q{end+1} = pkt;

        net.queue{i,j} = q;

    end

end


%% ============================================================
% Leader-to-pinned-follower links
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    net.triggerCheckCount = ...
        net.triggerCheckCount + 1;


    %% --------------------------------------------------------
    % Current leader state
    % ---------------------------------------------------------

    currentPos = leader.pos';

    currentVel = leader.vel';


    %% --------------------------------------------------------
    % Latest SUCCESSFULLY ACCEPTED leader state
    % ---------------------------------------------------------

    lastAcceptedPos = ...
        txState.leaderAckPos(i,:);


    lastAcceptedVel = ...
        txState.leaderAckVel(i,:);


    %% --------------------------------------------------------
    % Time since latest attempt
    % ---------------------------------------------------------

    timeSinceLastTx = ...
        tk ...
        - txState.leaderLastTxTime(i);


    %% --------------------------------------------------------
    % Receiver AoI
    % ---------------------------------------------------------

    receiverAoI = ...
        tk ...
        - net.leaderGenTime(i) ...
        + 0.5*dt;


    %% --------------------------------------------------------
    % Trigger
    % ---------------------------------------------------------

    [sendPacket,reason,triggerInfo] = ...
        aoiAwareTriggerPolicy( ...
        currentPos, ...
        currentVel, ...
        lastAcceptedPos, ...
        lastAcceptedVel, ...
        receiverAoI, ...
        timeSinceLastTx, ...
        cfg);


    %% --------------------------------------------------------
    % Adaptive diagnostics
    % ---------------------------------------------------------

    net.adaptiveScaleSum = ...
        net.adaptiveScaleSum ...
        + triggerInfo.adaptiveScale;


    net.adaptiveScaleCount = ...
        net.adaptiveScaleCount + 1;


    net.adaptiveScaleMinObserved = ...
        min( ...
        net.adaptiveScaleMinObserved, ...
        triggerInfo.adaptiveScale);


    %% --------------------------------------------------------
    % No transmission
    % ---------------------------------------------------------

    if ~sendPacket

        net.suppressedCount = ...
            net.suppressedCount + 1;


        if triggerInfo.refractoryBlocked

            net.refractoryBlockedCount = ...
                net.refractoryBlockedCount + 1;

        end


        if triggerInfo.aoiCooldownBlocked

            net.aoiCooldownBlockedCount = ...
                net.aoiCooldownBlockedCount + 1;

        end


        continue;

    end


    %% --------------------------------------------------------
    % Trigger reason
    % ---------------------------------------------------------

    net = incrementTriggerReason( ...
        net, ...
        reason);


    %% --------------------------------------------------------
    % Transmission attempt
    % ---------------------------------------------------------

    net.txCount = ...
        net.txCount + 1;


    txState.leaderLastTxTime(i) = ...
        tk;


    %% --------------------------------------------------------
    % Store attempt for future ACK matching
    % ---------------------------------------------------------

    txState = storePendingLeaderPacket( ...
        txState, ...
        i, ...
        tk, ...
        currentPos, ...
        currentVel);


    %% --------------------------------------------------------
    % Packet loss
    % ---------------------------------------------------------

    if rand < cfg.net.packetLoss

        net.dropCount = ...
            net.dropCount + 1;

        continue;

    end


    %% --------------------------------------------------------
    % Delay + jitter
    % ---------------------------------------------------------

    packetDelay = ...
        cfg.net.delay;


    if cfg.net.jitterStd > 0

        packetDelay = ...
            packetDelay ...
            + cfg.net.jitterStd ...
            * randn;

    end


    packetDelay = ...
        max(packetDelay,0);


    %% --------------------------------------------------------
    % Leader packet
    % ---------------------------------------------------------

    pkt.genTime = tk;

    pkt.arrivalTime = ...
        tk ...
        + packetDelay;

    pkt.pos = leader.pos';

    pkt.vel = leader.vel';

    pkt.acc = leader.acc';


    %% --------------------------------------------------------
    % Queue
    % ---------------------------------------------------------

    q = net.leaderQueue{i};

    q{end+1} = pkt;

    net.leaderQueue{i} = q;

end

end


%% ============================================================
% LOCAL FUNCTION
%
% Initialize ACK-based transmitter memory.
% ============================================================

function txState = initializeAoITxState( ...
    P, ...
    V, ...
    leader, ...
    cfg, ...
    net)

N = cfg.swarm.N;


%% ============================================================
% Neighbor ACK memory
% ============================================================

txState.ackPos = ...
    nan(N,N,3);


txState.ackVel = ...
    nan(N,N,3);


txState.ackGenTime = ...
    nan(N,N);


txState.lastTxTime = ...
    zeros(N,N);


txState.pending = ...
    cell(N,N);


for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end


        txState.ackPos(i,j,:) = ...
            P(j,:);


        txState.ackVel(i,j,:) = ...
            V(j,:);


        txState.ackGenTime(i,j) = ...
            net.genTime(i,j);


        txState.lastTxTime(i,j) = ...
            0;


        txState.pending{i,j} = ...
            struct( ...
            'genTime',{}, ...
            'pos',{}, ...
            'vel',{});

    end

end


%% ============================================================
% Leader ACK memory
% ============================================================

txState.leaderAckPos = ...
    nan(N,3);


txState.leaderAckVel = ...
    nan(N,3);


txState.leaderAckGenTime = ...
    nan(N,1);


txState.leaderLastTxTime = ...
    zeros(N,1);


txState.leaderPending = ...
    cell(N,1);


for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    txState.leaderAckPos(i,:) = ...
        leader.pos';


    txState.leaderAckVel(i,:) = ...
        leader.vel';


    txState.leaderAckGenTime(i) = ...
        net.leaderGenTime(i);


    txState.leaderLastTxTime(i) = ...
        0;


    txState.leaderPending{i} = ...
        struct( ...
        'genTime',{}, ...
        'pos',{}, ...
        'vel',{});

end

end


%% ============================================================
% LOCAL FUNCTION
%
% Store attempted neighbor packet.
%
% This does NOT mean the packet was successfully received.
% ============================================================

function txState = storePendingNeighborPacket( ...
    txState, ...
    i, ...
    j, ...
    genTime, ...
    pos, ...
    vel)

rec.genTime = ...
    genTime;


rec.pos = ...
    pos;


rec.vel = ...
    vel;


q = ...
    txState.pending{i,j};


if isempty(q)

    q = rec;

else

    q(end+1) = rec;

end


txState.pending{i,j} = ...
    q;

end


%% ============================================================
% LOCAL FUNCTION
%
% Store attempted leader packet.
% ============================================================

function txState = storePendingLeaderPacket( ...
    txState, ...
    i, ...
    genTime, ...
    pos, ...
    vel)

rec.genTime = ...
    genTime;


rec.pos = ...
    pos;


rec.vel = ...
    vel;


q = ...
    txState.leaderPending{i};


if isempty(q)

    q = rec;

else

    q(end+1) = rec;

end


txState.leaderPending{i} = ...
    q;

end


%% ============================================================
% LOCAL FUNCTION
%
% Synchronize ACK memory with receiver acceptance timestamps.
%
% net.genTime / net.leaderGenTime change ONLY when the receiver
% accepts a newer packet.
%
% Therefore:
%
%   accepted genTime advances
%       -> find corresponding attempted packet
%       -> update ackPos / ackVel
%
% Dropped and stale packets never advance ACK memory.
% ============================================================

function [txState,net] = syncAcceptedStateMemory( ...
    txState, ...
    net, ...
    cfg)

N = cfg.swarm.N;

tol = 1e-10;


%% ============================================================
% Neighbor links
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end


        receiverGenTime = ...
            net.genTime(i,j);


        previousAckGenTime = ...
            txState.ackGenTime(i,j);


        %% ----------------------------------------------------
        % No newer accepted packet
        % -----------------------------------------------------

        if ...
                receiverGenTime ...
                <= previousAckGenTime + tol

            continue;

        end


        %% ----------------------------------------------------
        % Find the attempted packet matching the accepted
        % generation timestamp.
        % -----------------------------------------------------

        q = ...
            txState.pending{i,j};


        if isempty(q)

            net.ackSyncMissCount = ...
                net.ackSyncMissCount + 1;

            continue;

        end


        genTimes = ...
            [q.genTime];


        idx = ...
            find( ...
            abs(genTimes - receiverGenTime) ...
            <= tol, ...
            1, ...
            'last');


        if isempty(idx)

            net.ackSyncMissCount = ...
                net.ackSyncMissCount + 1;

            continue;

        end


        %% ----------------------------------------------------
        % Successful receiver acceptance
        % -----------------------------------------------------

        txState.ackPos(i,j,:) = ...
            q(idx).pos;


        txState.ackVel(i,j,:) = ...
            q(idx).vel;


        txState.ackGenTime(i,j) = ...
            receiverGenTime;


        net.ackUpdateCount = ...
            net.ackUpdateCount + 1;


        %% ----------------------------------------------------
        % Remove:
        %
        %   accepted packet
        %   dropped older attempts
        %   stale older attempts
        %
        % Keep only attempts newer than accepted genTime.
        % -----------------------------------------------------

        keep = ...
            genTimes ...
            > receiverGenTime + tol;


        txState.pending{i,j} = ...
            q(keep);

    end

end


%% ============================================================
% Leader links
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    receiverGenTime = ...
        net.leaderGenTime(i);


    previousAckGenTime = ...
        txState.leaderAckGenTime(i);


    %% --------------------------------------------------------
    % No newer accepted leader packet
    % ---------------------------------------------------------

    if ...
            receiverGenTime ...
            <= previousAckGenTime + tol

        continue;

    end


    q = ...
        txState.leaderPending{i};


    if isempty(q)

        net.ackSyncMissCount = ...
            net.ackSyncMissCount + 1;

        continue;

    end


    genTimes = ...
        [q.genTime];


    idx = ...
        find( ...
        abs(genTimes - receiverGenTime) ...
        <= tol, ...
        1, ...
        'last');


    if isempty(idx)

        net.ackSyncMissCount = ...
            net.ackSyncMissCount + 1;

        continue;

    end


    %% --------------------------------------------------------
    % Successful acceptance
    % ---------------------------------------------------------

    txState.leaderAckPos(i,:) = ...
        q(idx).pos;


    txState.leaderAckVel(i,:) = ...
        q(idx).vel;


    txState.leaderAckGenTime(i) = ...
        receiverGenTime;


    net.ackUpdateCount = ...
        net.ackUpdateCount + 1;


    %% --------------------------------------------------------
    % Prune old attempts
    % ---------------------------------------------------------

    keep = ...
        genTimes ...
        > receiverGenTime + tol;


    txState.leaderPending{i} = ...
        q(keep);

end

end


%% ============================================================
% LOCAL FUNCTION
% Trigger-reason counter
% ============================================================

function net = incrementTriggerReason( ...
    net, ...
    reason)

switch reason

    case 1

        net.positionTriggerCount = ...
            net.positionTriggerCount + 1;


    case 2

        net.velocityTriggerCount = ...
            net.velocityTriggerCount + 1;


    case 3

        net.aoiTriggerCount = ...
            net.aoiTriggerCount + 1;


    case 4

        net.timeoutTriggerCount = ...
            net.timeoutTriggerCount + 1;

end

end