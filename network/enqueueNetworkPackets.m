function net = enqueueNetworkPackets( ...
    net, P, V, leader, tk, cfg, netTrace, k, fireMask)
%ENQUEUENETWORKPACKETS Periodic packet generation.
%
% netTrace and k are optional. When a trace is supplied the channel
% outcome is read from it at (k,i,j) instead of drawn inline, so every
% method sees the same realisation. Omitting them reproduces the
% original behaviour exactly.
%
% fireMask is optional and (N+1) x 1 logical:
%
%   fireMask(j)     physical sender j transmits its neighbour-state
%                   payload on this step
%   fireMask(N+1)   the leader payload class transmits on this step
%
% It exists for the EXP10 transmission-phase model: with independent
% phase per sender the swarm no longer transmits in lockstep, so the
% caller decides per sender rather than globally. Omitted, or all true,
% is the locked behaviour in which every sender fires on one clock, and
% tests/test_lock_regression proves bit-identity through that path.
%
% The mask is per SENDER, never per directed link: one radio
% transmission from node j reaches all of its listeners at the same
% instant, and splitting it per receiver would fabricate a difference
% between the periodic baselines and the event-triggered methods out of
% pure accounting.

if nargin < 7
    netTrace = [];
end

if nargin < 8
    k = 0;
end

N = cfg.swarm.N;

if nargin < 9 || isempty(fireMask)
    fireMask = true(N+1,1);
end


%% ============================================================
% Channel parameters in force at this instant
%
% netParamsAt returns the static cfg.net loss / delay / jitter verbatim
% unless a caller has attached cfg.net.regime, so this is the locked
% static channel on every pre-EXP11 path. EXP11 attaches a
% piecewise-constant schedule; the lookup is hoisted here because the
% regime cannot change inside one outer tick, so one lookup per step is
% both correct and cheaper than one per link.
% ============================================================

np = netParamsAt(cfg, tk);


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

        % Transmission phase: this sender's clock has not fired.
        if ~fireMask(j)
            continue;
        end

        % Blackout: the sender's radio is off, or the receiver's is.
        % Nothing leaves the antenna, so nothing is counted as sent.
        if nodeIsDark(cfg, j, tk) || nodeIsDark(cfg, i, tk)
            continue;
        end


        % Inert, and kept verbatim because it is part of the locked
        % EXP08C code path. It re-tests node 1, which is never selected
        % for a blackout (generateBlackoutRealization draws from 2:N
        % only, because blacking out the leader removes the formation's
        % only absolute reference and is a different experiment). The
        % condition is therefore false in every realization ever run,
        % and the receiver half duplicates the check two lines above.
        % Recorded here so a reader does not conclude that a leader
        % blackout is modelled.
        if nodeIsDark(cfg, 1, tk) || nodeIsDark(cfg, i, tk)
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
        if drawLoss(netTrace,k,i,j,false) < np.packetLoss

            net.dropCount = net.dropCount + 1;
            continue;

        end


        % Network delay
        delay = np.delay;

        if np.jitterStd > 0

            delay = delay + ...
                np.jitterStd * drawJitter(netTrace,k,i,j,false);

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

if fireMask(N+1)

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


    if drawLoss(netTrace,k,i,1,true) < np.packetLoss

        net.dropCount = net.dropCount + 1;
        continue;

    end


    delay = np.delay;

    if np.jitterStd > 0

        delay = delay + ...
            np.jitterStd * drawJitter(netTrace,k,i,1,true);

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
