function [net, txState] = initAckChannelState(net, P, V, leader, cfg)
%INITACKCHANNELSTATE Reverse ACK channel and causal transmitter memory (v2).
%
%   [net, txState] = initAckChannelState(net, P, V, leader, cfg)
%
% Causal-AoI-v2 keeps DUAL transmitter memory, which is what distinguishes
% it from v1:
%
%   sentPos / sentVel / sentGenTime / sentSeq
%       the last state actually PUT ON THE WIRE. State-change innovation is
%       measured against this, so the transmitter never re-sends an
%       innovation that is already in flight. This is the in-flight
%       suppression mechanism, and it needs no retransmission timer.
%
%   ackedGenTime / ackedSeq
%       the newest state the receiver has CONFIRMED. Used only to estimate
%       receiver freshness (AoI), never for innovation.
%
% v1 used the acked state for both, so during one round trip the innovation
% never appeared to shrink and the transmitter kept resending it. At
% Stressed that pushed hard position triggers from 61% to 98% of all
% transmissions and collapsed the AoI branch to 0.3%.
%
% Loss recovery still works without an RTO: a dropped packet leaves
% ackedGenTime frozen, so the estimated AoI grows, the adaptive threshold
% sharpens and the AoI branch fires. maxSilence remains the backstop.

N = cfg.swarm.N;


%% ============================================================
% Reverse channel queues
% ============================================================

net.ackQueue = cell(N,N);

for i = 1:N
    for j = 1:N
        net.ackQueue{i,j} = {};
    end
end

net.leaderAckQueue = cell(N,1);

for i = 1:N
    net.leaderAckQueue{i} = {};
end


%% ============================================================
% Receiver-side sequence state
%
% acceptedSeq is written by deliverNetworkPackets straight from the
% packet header, so the sequence number travels with the packet like
% a real header field. lastAckSeqSent is what the receiver has
% already acknowledged, which is what makes an ACK cumulative.
% ============================================================

net.acceptedSeq = zeros(N,N);

net.leaderAcceptedSeq = zeros(N,1);

net.lastAckSeqSent = zeros(N,N);

net.leaderLastAckSeqSent = zeros(N,1);


%% ============================================================
% Protocol accounting
% ============================================================

net.ackTxCount   = 0;
net.ackRxCount   = 0;
net.ackDropCount = 0;

net.ackUpdateCount = 0;

% One cumulative ACK can confirm several packets at once.
net.ackCoveredCount = 0;

% Late or superseded ACKs. Discarding these is correct behaviour.
net.staleAckDiscardedCount = 0;

% Transmissions avoided because the innovation was already in flight.
net.suppressedInFlightCount = 0;

% Outstanding-packet statistics.
net.outstandingSum   = 0;
net.outstandingCount = 0;
net.outstandingMax   = 0;


%% ============================================================
% The six causality invariants
% ============================================================

net.ackBeforeAcceptCount   = 0;
net.ackForDroppedDataCount = 0;
net.senderRollbackCount    = 0;
net.futureGenTimeCount     = 0;
net.staleAckAcceptedCount  = 0;
net.unknownSeqAckCount     = 0;

% v2 additions: sequence-level consistency.
net.seqGenTimeMismatchCount = 0;   % ACK seq and genTime disagree
net.duplicateAckCount       = 0;   % same seq acknowledged twice


%% ============================================================
% Transmitter memory: what was SENT
% ============================================================

txState.sentPos     = nan(N,N,3);
txState.sentVel     = nan(N,N,3);
txState.sentGenTime = nan(N,N);
txState.sentSeq     = zeros(N,N);

txState.lastTxTime = zeros(N,N);
txState.nextSeq    = ones(N,N);


%% ============================================================
% Transmitter memory: what was ACKNOWLEDGED
% ============================================================

txState.ackPos     = nan(N,N,3);
txState.ackVel     = nan(N,N,3);
txState.ackGenTime = nan(N,N);
txState.ackSeq     = zeros(N,N);

txState.outstanding = cell(N,N);


for i = 1:N
    for j = 1:N

        txState.outstanding{i,j} = emptyOutstanding();

        if cfg.swarm.A(i,j) ~= 0

            % The t = 0 state is common knowledge, as in every other
            % simulator here. Seeded locally, never from net.
            txState.sentPos(i,j,:) = P(j,:);
            txState.sentVel(i,j,:) = V(j,:);
            txState.sentGenTime(i,j) = 0;

            txState.ackPos(i,j,:) = P(j,:);
            txState.ackVel(i,j,:) = V(j,:);
            txState.ackGenTime(i,j) = 0;

        end

    end
end


%% ============================================================
% Leader links
% ============================================================

txState.leaderSentPos     = nan(N,3);
txState.leaderSentVel     = nan(N,3);
txState.leaderSentGenTime = nan(N,1);
txState.leaderSentSeq     = zeros(N,1);

txState.leaderLastTxTime = zeros(N,1);
txState.leaderNextSeq    = ones(N,1);

txState.leaderAckPos     = nan(N,3);
txState.leaderAckVel     = nan(N,3);
txState.leaderAckGenTime = nan(N,1);
txState.leaderAckSeq     = zeros(N,1);

txState.leaderOutstanding = cell(N,1);


for i = 1:N

    txState.leaderOutstanding{i} = emptyOutstanding();

    if i >= 2 && cfg.swarm.pin(i)

        txState.leaderSentPos(i,:) = leader.pos';
        txState.leaderSentVel(i,:) = leader.vel';
        txState.leaderSentGenTime(i) = 0;

        txState.leaderAckPos(i,:) = leader.pos';
        txState.leaderAckVel(i,:) = leader.vel';
        txState.leaderAckGenTime(i) = 0;

    end

end

end


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function q = emptyOutstanding()

q = struct( ...
    'genTime', {}, ...
    'seq',     {}, ...
    'pos',     {}, ...
    'vel',     {}, ...
    'dropped', {});

end
