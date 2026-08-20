function out = simSwarmAoIAblation(cfg)

% ============================================================
% SIMSWARMAOIABLATION
%
% EXP05C ablation simulator.
%
% Used for:
%
%   A2 = fixed AoI-state coupling + attempted-state memory
%   A3 = adaptive AoI-state coupling + attempted-state memory
%
% Full method A4 continues using:
%
%   simSwarmAoIAware
%
% so the locked EXP05B implementation is NOT modified.
%
%
% cfg.ablation.useAdaptiveScale
%
%   false -> A2
%            fixed AoI-assisted state threshold
%
%   true  -> A3
%            AoI-dependent adaptive state threshold
%
%
% IMPORTANT:
%
% This simulator intentionally uses LAST TRANSMISSION ATTEMPT
% as the state-event reference.
%
% Therefore:
%
%   dropped packet
%       -> transmitter state memory IS reset
%
% This isolates the contribution of accepted-state / ACK
% feedback when compared against A4.
%
% ============================================================


%% ============================================================
% Defaults
% ============================================================

if ~isfield(cfg,'ablation')
    cfg.ablation = struct();
end

if ~isfield(cfg.ablation,'useAdaptiveScale')
    cfg.ablation.useAdaptiveScale = false;
end


if ~isfield(cfg,'aoiEvent')
    cfg.aoiEvent = struct();
end

if ~isfield(cfg.aoiEvent,'posThreshold')
    cfg.aoiEvent.posThreshold = 0.05;
end

if ~isfield(cfg.aoiEvent,'velThreshold')
    cfg.aoiEvent.velThreshold = 0.10;
end

if ~isfield(cfg.aoiEvent,'aoiThreshold')
    cfg.aoiEvent.aoiThreshold = 0.12;
end

if ~isfield(cfg.aoiEvent,'maxSilence')
    cfg.aoiEvent.maxSilence = 0.50;
end

if ~isfield(cfg.aoiEvent,'minInterTx')
    cfg.aoiEvent.minInterTx = cfg.swarm.dt;
end

if ~isfield(cfg.aoiEvent,'aoiMinInterTx')
    cfg.aoiEvent.aoiMinInterTx = 0.10;
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


%% ============================================================
% RNG
% ============================================================

% The generator is pinned explicitly. Parallel-pool workers default to a
% different generator than the client, so rng(seed) alone would make
% parfor results differ from the equivalent serial loop.
rng(cfg.net.seed, 'twister');


%% ============================================================
% Simulation parameters
% ============================================================

dt = cfg.swarm.dt;

t = (0:dt:cfg.swarm.T)';

K = numel(t);

N = cfg.swarm.N;


%% ============================================================
% Initial states
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
% Initial leader/network
% ============================================================

leader = leaderReference(0);


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

net.positionTriggerCount = 0;

net.velocityTriggerCount = 0;

net.aoiTriggerCount = 0;

net.timeoutTriggerCount = 0;


%% ============================================================
% Last ATTEMPTED-transmission memory
% ============================================================

txState = initializeAttemptMemory( ...
    P, ...
    V, ...
    leader, ...
    cfg);


%% ============================================================
% Main simulation
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
    % Deliver packets already due
    % ---------------------------------------------------------

    net = deliverNetworkPackets( ...
        net, ...
        tk, ...
        cfg);


    %% --------------------------------------------------------
    % Communication trigger
    % ---------------------------------------------------------

    [net,txState] = enqueueAblationPackets( ...
        net, ...
        txState, ...
        P, ...
        V, ...
        leader, ...
        tk, ...
        cfg);


    %% --------------------------------------------------------
    % Deliver zero-delay newly generated packets
    % ---------------------------------------------------------

    net = deliverNetworkPackets( ...
        net, ...
        tk, ...
        cfg);


    %% --------------------------------------------------------
    % Formation control
    % ---------------------------------------------------------

    accCmd = distributedFormationPolicy( ...
        P, ...
        V, ...
        leader, ...
        cfg, ...
        net);


    %% --------------------------------------------------------
    % Logs
    % ---------------------------------------------------------

    Plog(k,:,:) = P;

    Vlog(k,:,:) = V;

    Alog(k,:,:) = accCmd;

    LeaderPos(k,:) = leader.pos';

    LeaderVel(k,:) = leader.vel';


    %% --------------------------------------------------------
    % Mean AoI
    % ---------------------------------------------------------

    ageSamples = [];


    for i = 1:N

        for j = 1:N

            if cfg.swarm.A(i,j) == 0
                continue;
            end


            ageSamples(end+1) = ...
                tk ...
                - net.genTime(i,j) ...
                + 0.5*dt; %#ok<AGROW>

        end


        if cfg.swarm.pin(i)

            ageSamples(end+1) = ...
                tk ...
                - net.leaderGenTime(i) ...
                + 0.5*dt; %#ok<AGROW>

        end

    end


    MeanAoILog(k) = ...
        mean(ageSamples);


    %% --------------------------------------------------------
    % End
    % ---------------------------------------------------------

    if k == K
        break;
    end


    %% --------------------------------------------------------
    % Double-integrator followers
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
% Outputs
% ============================================================

out.t = t;

out.P = Plog;

out.V = Vlog;

out.A = Alog;

out.LeaderPos = LeaderPos;

out.LeaderVel = LeaderVel;

out.meanAoI = MeanAoILog;


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
    (net.rxCount-net.staleDiscardCount) ...
    / max(net.txCount,1);


out.triggerCheckCount = ...
    net.triggerCheckCount;


out.suppressedCount = ...
    net.suppressedCount;


out.positionTriggerCount = ...
    net.positionTriggerCount;


out.velocityTriggerCount = ...
    net.velocityTriggerCount;


out.aoiTriggerCount = ...
    net.aoiTriggerCount;


out.timeoutTriggerCount = ...
    net.timeoutTriggerCount;


out.suppressionRatio = ...
    net.suppressedCount ...
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
% Communication rate
% ============================================================

missionTime = ...
    t(end)-t(1);


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
% Packet generation
% ============================================================

function [net,txState] = enqueueAblationPackets( ...
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


        currentPos = P(j,:);

        currentVel = V(j,:);


        lastPos = ...
            squeeze(txState.lastPos(i,j,:))';


        lastVel = ...
            squeeze(txState.lastVel(i,j,:))';


        timeSinceLastTx = ...
            tk ...
            - txState.lastTxTime(i,j);


        receiverAoI = ...
            tk ...
            - net.genTime(i,j) ...
            + 0.5*dt;


        [sendPacket,reason] = ...
            ablationTriggerPolicy( ...
            currentPos, ...
            currentVel, ...
            lastPos, ...
            lastVel, ...
            receiverAoI, ...
            timeSinceLastTx, ...
            cfg);


        if ~sendPacket

            net.suppressedCount = ...
                net.suppressedCount + 1;

            continue;

        end


        net = incrementReason( ...
            net, ...
            reason);


        %% ----------------------------------------------------
        % Transmission attempt
        % -----------------------------------------------------

        net.txCount = ...
            net.txCount + 1;


        %% ----------------------------------------------------
        % IMPORTANT ABLATION:
        %
        % memory updated on ATTEMPT regardless of success
        % -----------------------------------------------------

        txState.lastPos(i,j,:) = ...
            currentPos;


        txState.lastVel(i,j,:) = ...
            currentVel;


        txState.lastTxTime(i,j) = ...
            tk;


        %% ----------------------------------------------------
        % Loss
        % -----------------------------------------------------

        if rand < cfg.net.packetLoss

            net.dropCount = ...
                net.dropCount + 1;

            continue;

        end


        %% ----------------------------------------------------
        % Delay
        % -----------------------------------------------------

        packetDelay = cfg.net.delay;


        if cfg.net.jitterStd > 0

            packetDelay = ...
                packetDelay ...
                + cfg.net.jitterStd*randn;

        end


        packetDelay = ...
            max(packetDelay,0);


        %% ----------------------------------------------------
        % Packet
        % -----------------------------------------------------

        pkt.genTime = tk;

        pkt.arrivalTime = ...
            tk + packetDelay;

        pkt.pos = currentPos;

        pkt.vel = currentVel;


        q = net.queue{i,j};

        q{end+1} = pkt;

        net.queue{i,j} = q;

    end

end


%% ============================================================
% Leader links
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    net.triggerCheckCount = ...
        net.triggerCheckCount + 1;


    currentPos = leader.pos';

    currentVel = leader.vel';


    lastPos = ...
        txState.leaderLastPos(i,:);


    lastVel = ...
        txState.leaderLastVel(i,:);


    timeSinceLastTx = ...
        tk ...
        - txState.leaderLastTxTime(i);


    receiverAoI = ...
        tk ...
        - net.leaderGenTime(i) ...
        + 0.5*dt;


    [sendPacket,reason] = ...
        ablationTriggerPolicy( ...
        currentPos, ...
        currentVel, ...
        lastPos, ...
        lastVel, ...
        receiverAoI, ...
        timeSinceLastTx, ...
        cfg);


    if ~sendPacket

        net.suppressedCount = ...
            net.suppressedCount + 1;

        continue;

    end


    net = incrementReason( ...
        net, ...
        reason);


    net.txCount = ...
        net.txCount + 1;


    %% --------------------------------------------------------
    % Attempt memory
    % ---------------------------------------------------------

    txState.leaderLastPos(i,:) = ...
        currentPos;


    txState.leaderLastVel(i,:) = ...
        currentVel;


    txState.leaderLastTxTime(i) = ...
        tk;


    %% --------------------------------------------------------
    % Loss
    % ---------------------------------------------------------

    if rand < cfg.net.packetLoss

        net.dropCount = ...
            net.dropCount + 1;

        continue;

    end


    %% --------------------------------------------------------
    % Delay
    % ---------------------------------------------------------

    packetDelay = cfg.net.delay;


    if cfg.net.jitterStd > 0

        packetDelay = ...
            packetDelay ...
            + cfg.net.jitterStd*randn;

    end


    packetDelay = ...
        max(packetDelay,0);


    %% --------------------------------------------------------
    % Packet
    % ---------------------------------------------------------

    pkt.genTime = tk;

    pkt.arrivalTime = ...
        tk + packetDelay;

    pkt.pos = leader.pos';

    pkt.vel = leader.vel';

    pkt.acc = leader.acc';


    q = net.leaderQueue{i};

    q{end+1} = pkt;

    net.leaderQueue{i} = q;

end

end


%% ============================================================
% Trigger policy
% ============================================================

function [sendPacket,reason] = ablationTriggerPolicy( ...
    currentPos, ...
    currentVel, ...
    lastPos, ...
    lastVel, ...
    receiverAoI, ...
    timeSinceLastTx, ...
    cfg)

epsP = ...
    cfg.aoiEvent.posThreshold;


epsV = ...
    cfg.aoiEvent.velThreshold;


aoiThreshold = ...
    cfg.aoiEvent.aoiThreshold;


maxSilence = ...
    cfg.aoiEvent.maxSilence;


minInterTx = ...
    cfg.aoiEvent.minInterTx;


aoiMinInterTx = ...
    cfg.aoiEvent.aoiMinInterTx;


scaleBase = ...
    cfg.aoiEvent.aoiStateScaleBase;


scaleMin = ...
    cfg.aoiEvent.aoiStateScaleMin;


adaptRange = ...
    cfg.aoiEvent.aoiAdaptRange;


%% ============================================================
% State change
% ============================================================

dp = ...
    norm(currentPos(:)-lastPos(:));


dv = ...
    norm(currentVel(:)-lastVel(:));


%% ============================================================
% Hard state events
% ============================================================

posTrigger = ...
    dp >= epsP;


velTrigger = ...
    dv >= epsV;


%% ============================================================
% A2 / A3 sensitivity
% ============================================================

if cfg.ablation.useAdaptiveScale

    % --------------------------------------------------------
    % A3:
    % adaptive AoI-dependent threshold
    % ---------------------------------------------------------

    if receiverAoI <= aoiThreshold

        normalizedExcess = 0;

    else

        normalizedExcess = ...
            ( ...
            receiverAoI ...
            / max(aoiThreshold,eps) ...
            - 1 ...
            ) ...
            / max(adaptRange,eps);

    end


    normalizedExcess = ...
        min(max(normalizedExcess,0),1);


    scale = ...
        scaleBase ...
        - ...
        (scaleBase-scaleMin) ...
        * normalizedExcess;

else

    % --------------------------------------------------------
    % A2:
    % fixed AoI-state coupling
    % ---------------------------------------------------------

    scale = scaleBase;

end


%% ============================================================
% AoI-assisted event
% ============================================================

aoiStateRelevant = ...
    dp >= scale*epsP ...
    || ...
    dv >= scale*epsV;


aoiTrigger = ...
    receiverAoI >= aoiThreshold ...
    && ...
    aoiStateRelevant ...
    && ...
    timeSinceLastTx >= aoiMinInterTx;


%% ============================================================
% Timeout
% ============================================================

timeoutTrigger = ...
    timeSinceLastTx >= maxSilence;


%% ============================================================
% Global refractory
% ============================================================

if timeSinceLastTx < minInterTx

    sendPacket = false;

    reason = 0;

    return;

end


%% ============================================================
% Final decision
% ============================================================

sendPacket = ...
    posTrigger ...
    || velTrigger ...
    || aoiTrigger ...
    || timeoutTrigger;


%% ============================================================
% Reason priority
% ============================================================

if posTrigger

    reason = 1;

elseif velTrigger

    reason = 2;

elseif aoiTrigger

    reason = 3;

elseif timeoutTrigger

    reason = 4;

else

    reason = 0;

end

end


%% ============================================================
% Initialize ATTEMPT memory
% ============================================================

function txState = initializeAttemptMemory( ...
    P, ...
    V, ...
    leader, ...
    cfg)

N = cfg.swarm.N;


txState.lastPos = ...
    nan(N,N,3);


txState.lastVel = ...
    nan(N,N,3);


txState.lastTxTime = ...
    zeros(N,N);


for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end


        txState.lastPos(i,j,:) = ...
            P(j,:);


        txState.lastVel(i,j,:) = ...
            V(j,:);

    end

end


txState.leaderLastPos = ...
    nan(N,3);


txState.leaderLastVel = ...
    nan(N,3);


txState.leaderLastTxTime = ...
    zeros(N,1);


for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    txState.leaderLastPos(i,:) = ...
        leader.pos';


    txState.leaderLastVel(i,:) = ...
        leader.vel';

end

end


%% ============================================================
% Trigger counter
% ============================================================

function net = incrementReason(net,reason)

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