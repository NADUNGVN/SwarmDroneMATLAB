function net = deliverDataWithAck(net, tk, cfg, ackTrace, k)
%DELIVERDATAWITHACK Deliver DATA and emit one CUMULATIVE ACK per link per tick.
%
%   net = deliverDataWithAck(net, tk, cfg, ackTrace, k)
%
% ackTrace and k are optional. When a reverse trace is supplied the ACK
% loss and jitter outcomes are read from it at (k,i,j) instead of drawn
% from net.ackStream, so every ACK impairment cell for a given scenario and
% seed sits on the same reverse realisation. Omitting them reproduces the
% original RandStream behaviour exactly.
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

if nargin < 4
    ackTrace = [];
end

if nargin < 5
    k = 0;
end

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

        net = pushAck(net, i, j, acceptedGenTime, seq, tk, cfg, false, ...
            ackTrace, k);

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

    net = pushAck(net, i, 1, acceptedGenTime, seq, tk, cfg, true, ...
        ackTrace, k);

end

end


%% ============================================================
% LOCAL FUNCTION
%
% Place one ACK on the reverse path, subject to its own loss,
% delay and jitter.
% ============================================================

function net = pushAck(net, i, j, acceptedGenTime, seq, tk, cfg, isLeaderLink, ...
    ackTrace, k)

% Blackout: node i cannot send an ACK, or node j cannot receive one.
% The radio is off, so nothing is transmitted and nothing is counted.
% The data sender simply never hears back, which is exactly what it
% would experience in the field.
if nodeIsDark(cfg, i, tk) || nodeIsDark(cfg, j, tk)
    return;
end


%% ------------------------------------------------------------
% Reverse-channel parameters in force at this instant
%
% Static cfg.ack values unless a caller attached cfg.ack.regime, so every
% pre-EXP11 path is unchanged. Resolved at the instant the ACK is
% generated: an ACK created just before a switch travels under the
% conditions that existed when it was sent.
% ------------------------------------------------------------

ap = ackParamsAt(cfg, tk);


net.ackTxCount = net.ackTxCount + 1;


if drawAckLoss(net, ackTrace, k, i, j, isLeaderLink) < ap.loss

    net.ackDropCount = net.ackDropCount + 1;

    return;

end


ackDelay = ap.delay;

if ap.jitterStd > 0
    ackDelay = ackDelay + ...
        ap.jitterStd * drawAckJitter(net, ackTrace, k, i, j, isLeaderLink);
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


%% ============================================================
% LOCAL FUNCTIONS
%
% Read the pre-drawn reverse outcome when a trace is present,
% otherwise fall back to the dedicated RandStream. The stream is
% deliberately NOT consumed in trace mode: drawing from it as well
% would make the realisation depend on how many ACKs a particular
% impairment cell happened to generate, which is the coupling the
% trace exists to remove.
% ============================================================

function u = drawAckLoss(net, ackTrace, k, i, j, isLeaderLink)

if isempty(ackTrace)
    u = rand(net.ackStream);
elseif isLeaderLink
    u = ackTrace.leaderLossU(k,i);
else
    u = ackTrace.lossU(k,i,j);
end

end


function z = drawAckJitter(net, ackTrace, k, i, j, isLeaderLink)

if isempty(ackTrace)
    z = randn(net.ackStream);
elseif isLeaderLink
    z = ackTrace.leaderJitterZ(k,i);
else
    z = ackTrace.jitterZ(k,i,j);
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
