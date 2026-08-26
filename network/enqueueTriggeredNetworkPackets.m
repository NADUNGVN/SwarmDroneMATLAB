function [net, txState] = enqueueTriggeredNetworkPackets( ...
    net, ...
    txState, ...
    P, ...
    V, ...
    leader, ...
    tk, ...
    cfg, ...
    netTrace, ...
    k)

% netTrace and k are optional. With a trace supplied the channel outcome
% is read at (k,i,j) rather than drawn inline, so every method meets the
% same realisation. Omitting them reproduces the original behaviour.

if nargin < 8
    netTrace = [];
end

if nargin < 9
    k = 0;
end

% ============================================================
% ENQUEUETRIGGEREDNETWORKPACKETS
%
% Event-triggered packet generation for distributed swarm
% communication.
%
% This function:
%
%   1. Evaluates event-trigger condition for every active link.
%   2. Generates a packet only when trigger condition is met.
%   3. Applies packet loss.
%   4. Applies fixed delay + Gaussian jitter.
%   5. Adds surviving packets to the existing network queues.
%   6. Updates last-transmitted state.
%
% IMPORTANT:
%
% Last-transmitted state is updated when a packet transmission
% is ATTEMPTED, even if the packet is subsequently dropped.
%
% This models a transmitter without receiver ACK feedback.
%
% ============================================================

N = cfg.swarm.N;


% Broadcast accounting (EXP07C). Passive; see initQueuedNetworkState.
senderFired = false(N,1);

leaderFired = false;


%% ============================================================
% Initialize transmitter-side memory if needed
% ============================================================

if isempty(txState) || ...
        ~isfield(txState,'lastPos')

    txState = initializeTxState( ...
        P, ...
        V, ...
        leader, ...
        cfg);

end


%% ============================================================
% Initialize event statistics if missing
% ============================================================

if ~isfield(net,'triggerCheckCount')

    net.triggerCheckCount = 0;

end

if ~isfield(net,'suppressedCount')

    net.suppressedCount = 0;

end

if ~isfield(net,'positionTriggerCount')

    net.positionTriggerCount = 0;

end

if ~isfield(net,'velocityTriggerCount')

    net.velocityTriggerCount = 0;

end

if ~isfield(net,'timeoutTriggerCount')

    net.timeoutTriggerCount = 0;

end


%% ============================================================
% Neighbor-to-neighbor communication
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end


        %% ----------------------------------------------------
        % Event-trigger evaluation
        % -----------------------------------------------------

        net.triggerCheckCount = ...
            net.triggerCheckCount + 1;


        currentPos = ...
            P(j,:);

        currentVel = ...
            V(j,:);


        lastPos = ...
            squeeze( ...
            txState.lastPos(i,j,:))';

        lastVel = ...
            squeeze( ...
            txState.lastVel(i,j,:))';


        timeSinceLastTx = ...
            tk - ...
            txState.lastTxTime(i,j);


        [sendPacket,reason] = ...
            eventTriggerPolicy( ...
            currentPos, ...
            currentVel, ...
            lastPos, ...
            lastVel, ...
            timeSinceLastTx, ...
            cfg);


        %% ----------------------------------------------------
        % No trigger
        % -----------------------------------------------------

        if ~sendPacket

            net.suppressedCount = ...
                net.suppressedCount + 1;

            continue;

        end


        %% ----------------------------------------------------
        % Trigger-reason statistics
        % -----------------------------------------------------

        switch reason

            case 1

                net.positionTriggerCount = ...
                    net.positionTriggerCount + 1;

            case 2

                net.velocityTriggerCount = ...
                    net.velocityTriggerCount + 1;

            case 3

                net.timeoutTriggerCount = ...
                    net.timeoutTriggerCount + 1;

        end


        %% ----------------------------------------------------
        % Transmission attempt
        % -----------------------------------------------------

        if nodeIsDark(cfg, j, tk) || nodeIsDark(cfg, i, tk)
            continue;
        end


        net.txCount = ...
            net.txCount + 1;

        senderFired(j) = true;


        if linkIsDown(cfg, i, j, tk)
            net.dropCount = net.dropCount + 1;
            continue;
        end


        % Update transmitter memory immediately.
        %
        % This occurs even if the channel later drops
        % the packet.
        txState.lastPos(i,j,:) = ...
            currentPos;

        txState.lastVel(i,j,:) = ...
            currentVel;

        txState.lastTxTime(i,j) = ...
            tk;


        %% ----------------------------------------------------
        % Packet loss
        % -----------------------------------------------------

        if drawLoss(netTrace,k,i,j,false) < cfg.net.packetLoss

            net.dropCount = ...
                net.dropCount + 1;

            continue;

        end


        %% ----------------------------------------------------
        % Communication delay
        % -----------------------------------------------------

        delay = ...
            cfg.net.delay;


        if cfg.net.jitterStd > 0

            delay = ...
                delay ...
                + cfg.net.jitterStd ...
                * drawJitter(netTrace,k,i,j,false);

        end


        % Negative latency is physically invalid.
        delay = ...
            max(delay,0);


        %% ----------------------------------------------------
        % Create packet
        % -----------------------------------------------------

        pkt.genTime = ...
            tk;

        pkt.arrivalTime = ...
            tk + delay;

        pkt.pos = ...
            currentPos;

        pkt.vel = ...
            currentVel;


        %% ----------------------------------------------------
        % Enqueue packet
        % -----------------------------------------------------

        q = ...
            net.queue{i,j};

        q{end+1} = ...
            pkt;

        net.queue{i,j} = ...
            q;

    end

end


%% ============================================================
% Leader-to-pinned-follower communication
% ============================================================

for i = 2:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    %% --------------------------------------------------------
    % Event-trigger evaluation
    % ---------------------------------------------------------

    net.triggerCheckCount = ...
        net.triggerCheckCount + 1;


    currentPos = ...
        leader.pos';

    currentVel = ...
        leader.vel';


    lastPos = ...
        txState.leaderLastPos(i,:);

    lastVel = ...
        txState.leaderLastVel(i,:);


    timeSinceLastTx = ...
        tk ...
        - txState.leaderLastTxTime(i);


    [sendPacket,reason] = ...
        eventTriggerPolicy( ...
        currentPos, ...
        currentVel, ...
        lastPos, ...
        lastVel, ...
        timeSinceLastTx, ...
        cfg);


    %% --------------------------------------------------------
    % No trigger
    % ---------------------------------------------------------

    if ~sendPacket

        net.suppressedCount = ...
            net.suppressedCount + 1;

        continue;

    end


    %% --------------------------------------------------------
    % Trigger reason
    % ---------------------------------------------------------

    switch reason

        case 1

            net.positionTriggerCount = ...
                net.positionTriggerCount + 1;

        case 2

            net.velocityTriggerCount = ...
                net.velocityTriggerCount + 1;

        case 3

            net.timeoutTriggerCount = ...
                net.timeoutTriggerCount + 1;

    end


    %% --------------------------------------------------------
    % Transmission attempt
    % ---------------------------------------------------------

    if nodeIsDark(cfg, 1, tk) || nodeIsDark(cfg, i, tk)
        continue;
    end


    net.txCount = ...
        net.txCount + 1;

    leaderFired = true;


    if linkIsDown(cfg, i, 1, tk)
        net.dropCount = net.dropCount + 1;
        continue;
    end


    txState.leaderLastPos(i,:) = ...
        currentPos;

    txState.leaderLastVel(i,:) = ...
        currentVel;

    txState.leaderLastTxTime(i) = ...
        tk;


    %% --------------------------------------------------------
    % Packet loss
    % ---------------------------------------------------------

    if drawLoss(netTrace,k,i,1,true) < cfg.net.packetLoss

        net.dropCount = ...
            net.dropCount + 1;

        continue;

    end


    %% --------------------------------------------------------
    % Communication delay
    % ---------------------------------------------------------

    delay = ...
        cfg.net.delay;


    if cfg.net.jitterStd > 0

        delay = ...
            delay ...
            + cfg.net.jitterStd ...
            * drawJitter(netTrace,k,i,1,true);

    end


    delay = ...
        max(delay,0);


    %% --------------------------------------------------------
    % Leader packet
    % ---------------------------------------------------------

    pkt.genTime = ...
        tk;

    pkt.arrivalTime = ...
        tk + delay;

    pkt.pos = ...
        leader.pos';

    pkt.vel = ...
        leader.vel';

    pkt.acc = ...
        leader.acc';


    %% --------------------------------------------------------
    % Enqueue
    % ---------------------------------------------------------

    q = ...
        net.leaderQueue{i};

    q{end+1} = ...
        pkt;

    net.leaderQueue{i} = ...
        q;

end


net.broadcastCount = net.broadcastCount + nnz(senderFired) + leaderFired;

end


%% ============================================================
% Local helper:
% Initialize transmitter-side event-trigger memory
% ============================================================

function txState = initializeTxState( ...
    P, ...
    V, ...
    leader, ...
    cfg)

N = ...
    cfg.swarm.N;


%% ============================================================
% Neighbor memory
% ============================================================

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

        % Initial state at t = 0 is already available
        % through initQueuedNetworkState().
        txState.lastTxTime(i,j) = ...
            0;

    end

end


%% ============================================================
% Leader memory
% ============================================================

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

    txState.leaderLastTxTime(i) = ...
        0;

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


%% ============================================================
% LOCAL FUNCTION
%
% Node communication blackout. Returns true when node n has its radio
% off at time tk. A dark node cannot send DATA, receive DATA, send ACK
% or receive ACK; its dynamics and controller are untouched, and
% cfg.swarm.A is never modified.
%
% Unlike a dead link, the node knows its own radio is off, so it does
% not transmit and nothing is counted as sent.
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
