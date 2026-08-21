function out = simSwarmAoICausal(cfg)
%SIMSWARMAOICAUSAL AoI-aware swarm with an explicit, causal ACK protocol (v2).
%
%   out = simSwarmAoICausal(cfg)
%
% Same formation controller, same network model and the same trigger policy
% as simSwarmAoIAware. The difference is confined to how the transmitter
% learns what the receiver holds:
%
%   simSwarmAoIAware   reads net.genTime directly, inside the same timestep,
%                      with no reverse packet, no delay and no loss
%
%   this file           learns only from ACK packets that traverse a reverse
%                      channel with its own delay, jitter and loss
%
% The trigger policy itself (aoiAwareTriggerPolicy) is reused unchanged, so
% the difference between the two simulators isolates exactly one variable:
% what the sender is allowed to know.
%
% Loop order per timestep:
%
%   1  deliver ACKs that arrived         (transmitter belief updates)
%   2  deliver DATA due now, emit ACKs   (receiver state updates)
%   3  evaluate trigger, transmit DATA
%   4  formation control, log, integrate
%
% There is no second synchronisation pass. The ideal implementation performs
% one (its STEP 5) which lets a zero-delay packet be generated, delivered and
% acknowledged inside a single timestep; that is the sharpest acausality in
% the original and it is absent here by construction.
%
% Required config beyond the AoI-aware set:
%
%   cfg.ack.loss              reverse-channel packet loss
%   cfg.ack.delay             reverse-channel delay [s], floored at cfg.swarm.dt
%   cfg.ack.jitterStd         reverse-channel jitter [s]
%   cfg.ack.seedOffset        offset for the independent ACK RNG stream
%   cfg.ack.assertInvariants  raise on any causality violation
%
% Ablation switches (defaults give the full method, A4c):
%
%   cfg.causal.useAckFeedback    false -> freshness estimated open loop
%   cfg.causal.useAdaptiveScale  false -> adaptive threshold pinned to base
%
% Version history:
%   v1  single memory: innovation and freshness both from the acked state.
%       Under a round trip the innovation never shrank, so the transmitter
%       re-sent state already in flight. At Stressed that drove hard
%       position triggers to 98% of transmissions and collapsed the AoI
%       branch to 0.3%, breaching the 20 Hz ceiling at 26.19 Hz.
%   v2  dual memory plus real sequence numbers and cumulative ACKs.

rng(cfg.net.seed, 'twister');


%% ============================================================
% Defaults for the ACK channel
%
% Symmetric with the forward channel unless overridden: the reverse
% path uses the same physical medium.
% ============================================================

if ~isfield(cfg,'ack')
    cfg.ack = struct();
end

if ~isfield(cfg.ack,'loss'),             cfg.ack.loss = 0.0;                 end
if ~isfield(cfg.ack,'delay'),            cfg.ack.delay = cfg.net.delay;      end
if ~isfield(cfg.ack,'jitterStd'),        cfg.ack.jitterStd = 0.0;            end
if ~isfield(cfg.ack,'seedOffset'),       cfg.ack.seedOffset = 987654;        end
if ~isfield(cfg.ack,'assertInvariants'), cfg.ack.assertInvariants = false;   end


%% ============================================================
% Ablation switches
%
% Defaults select the full method. Each switch removes exactly one
% mechanism, so the arms differ by one thing at a time.
% ============================================================

if ~isfield(cfg,'causal')
    cfg.causal = struct();
end

if ~isfield(cfg.causal,'useAckFeedback'),   cfg.causal.useAckFeedback = true;   end
if ~isfield(cfg.causal,'useAdaptiveScale'), cfg.causal.useAdaptiveScale = true; end


%% ============================================================
% Defaults for the AoI trigger
%
% Identical values to simSwarmAoIAblation so the two agree; the ideal
% simulator carries a different set, which is a latent inconsistency
% recorded as B8 in docs/RESEARCH_REVIEW.md.
% ============================================================

if ~isfield(cfg,'aoiEvent')
    cfg.aoiEvent = struct();
end

if ~isfield(cfg.aoiEvent,'posThreshold'),      cfg.aoiEvent.posThreshold = 0.05;      end
if ~isfield(cfg.aoiEvent,'velThreshold'),      cfg.aoiEvent.velThreshold = 0.10;      end
if ~isfield(cfg.aoiEvent,'aoiThreshold'),      cfg.aoiEvent.aoiThreshold = 0.12;      end
if ~isfield(cfg.aoiEvent,'maxSilence'),        cfg.aoiEvent.maxSilence = 0.50;        end
if ~isfield(cfg.aoiEvent,'minInterTx'),        cfg.aoiEvent.minInterTx = cfg.swarm.dt; end
if ~isfield(cfg.aoiEvent,'aoiMinInterTx'),     cfg.aoiEvent.aoiMinInterTx = 0.10;     end
if ~isfield(cfg.aoiEvent,'aoiStateScaleBase'), cfg.aoiEvent.aoiStateScaleBase = 0.50; end
if ~isfield(cfg.aoiEvent,'aoiStateScaleMin'),  cfg.aoiEvent.aoiStateScaleMin = 0.20;  end
if ~isfield(cfg.aoiEvent,'aoiAdaptRange'),     cfg.aoiEvent.aoiAdaptRange = 1.00;     end


%% ============================================================
% Setup
% ============================================================

dt = cfg.swarm.dt;

t = (0:dt:cfg.swarm.T)';

K = numel(t);

N = cfg.swarm.N;

P = cfg.swarm.initialPositions;
V = cfg.swarm.initialVelocities;


Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);

LeaderPos = zeros(K,3);
LeaderVel = zeros(K,3);

MeanAoILog = zeros(K,1);

NeighborAoILog = nan(K,N,N);
LeaderAoILog   = nan(K,N);

% Transmitter-side belief, logged for diagnostics only. Never read back
% into the control or trigger path.
EstAoILog = nan(K,N,N);


leader = leaderReference(0);

net = initQueuedNetworkState(P, V, leader, cfg);


%% ============================================================
% Trigger and adaptive-scale counters
% ============================================================

net.triggerCheckCount        = 0;
net.suppressedCount          = 0;
net.refractoryBlockedCount   = 0;
net.aoiCooldownBlockedCount  = 0;
net.positionTriggerCount     = 0;
net.velocityTriggerCount     = 0;
net.aoiTriggerCount          = 0;
net.timeoutTriggerCount      = 0;

net.adaptiveScaleSum         = 0;
net.adaptiveScaleCount       = 0;
net.adaptiveScaleMinObserved = inf;


%% ============================================================
% Reverse ACK channel
%
% An independent RandStream so that adding the ACK channel does not
% perturb the DATA loss/jitter sequence. Ideal and causal runs at the
% same seed therefore see the same forward-channel realisation.
% ============================================================

net.ackStream = RandStream('mt19937ar', ...
    'Seed', mod(cfg.net.seed + cfg.ack.seedOffset, 2^32));

[net, txState] = initAckChannelState(net, P, V, leader, cfg);


%% ============================================================
% Simulation loop
% ============================================================

for k = 1:K

    tk = t(k);

    leader = leaderReference(tk);

    P(1,:) = leader.pos';
    V(1,:) = leader.vel';


    %% --------------------------------------------------------
    % STEP 1
    %
    % Apply ACKs that have arrived. This is the only way the
    % transmitter learns anything about the receiver.
    % ---------------------------------------------------------

    [net, txState] = deliverAckPackets(net, txState, tk, cfg);


    %% --------------------------------------------------------
    % STEP 2
    %
    % Deliver DATA due now; each acceptance emits an ACK onto the
    % reverse queue, arriving no earlier than tk + dt.
    % ---------------------------------------------------------

    net = deliverDataWithAck(net, tk, cfg);


    %% --------------------------------------------------------
    % STEP 3
    %
    % Trigger evaluation using transmitter belief only.
    % ---------------------------------------------------------

    [net, txState] = enqueueCausalAoIPackets( ...
        net, txState, P, V, leader, tk, cfg);


    %% --------------------------------------------------------
    % STEP 4
    %
    % Deliver packets generated this step that are already due,
    % i.e. zero-delay links. This mirrors the ideal simulator's
    % STEP 4 and keeps the FORWARD path byte-for-byte comparable.
    %
    % Omitting it would silently add one timestep of delay to the
    % data channel, which is a modelling change, not a causality
    % fix. The acausal part of the ideal simulator is its STEP 5
    % (a second transmitter sync in the same timestep); that is
    % what stays absent here.
    %
    % ACKs emitted by this delivery still arrive no earlier than
    % tk + dt, so causality is preserved.
    % ---------------------------------------------------------

    net = deliverDataWithAck(net, tk, cfg);


    %% --------------------------------------------------------
    % Formation control
    % ---------------------------------------------------------

    accCmd = distributedFormationPolicy(P, V, leader, cfg, net);


    %% --------------------------------------------------------
    % Logging
    % ---------------------------------------------------------

    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;

    LeaderPos(k,:) = leader.pos';
    LeaderVel(k,:) = leader.vel';


    %% --------------------------------------------------------
    % AoI logging
    %
    % True AoI is the omniscient-observer metric, kept identical to
    % the ideal simulator so the numbers stay comparable. Estimated
    % AoI is logged alongside it to quantify the gap causality opens.
    % ---------------------------------------------------------

    ageSamples = [];

    for i = 1:N

        for j = 1:N

            if cfg.swarm.A(i,j) == 0
                continue;
            end

            age = tk - net.genTime(i,j) + 0.5*dt;

            NeighborAoILog(k,i,j) = age;

            if cfg.causal.useAckFeedback
                EstAoILog(k,i,j) = tk - txState.ackGenTime(i,j) + 0.5*dt;
            else
                EstAoILog(k,i,j) = tk - txState.sentGenTime(i,j) + 0.5*dt;
            end

            ageSamples(end+1) = age; %#ok<AGROW>

        end

        if cfg.swarm.pin(i)

            age = tk - net.leaderGenTime(i) + 0.5*dt;

            LeaderAoILog(k,i) = age;

            ageSamples(end+1) = age; %#ok<AGROW>

        end

    end

    if isempty(ageSamples)
        MeanAoILog(k) = NaN;
    else
        MeanAoILog(k) = mean(ageSamples);
    end


    if k == K
        break;
    end


    %% --------------------------------------------------------
    % Double-integrator followers
    % ---------------------------------------------------------

    for i = 2:N

        V(i,:) = V(i,:) + dt*accCmd(i,:);

        P(i,:) = P(i,:) + dt*V(i,:);

    end

end


%% ============================================================
% Trajectory outputs
% ============================================================

out.t = t;

out.P = Plog;
out.V = Vlog;
out.A = Alog;

out.LeaderPos = LeaderPos;
out.LeaderVel = LeaderVel;

out.meanAoI     = MeanAoILog;
out.neighborAoI = NeighborAoILog;
out.leaderAoI   = LeaderAoILog;

out.estimatedAoI = EstAoILog;


%% ============================================================
% Forward-channel statistics
% ============================================================

out.txCount           = net.txCount;
out.rxCount           = net.rxCount;
out.dropCount         = net.dropCount;
out.staleDiscardCount = net.staleDiscardCount;

out.PDR = 1 - net.dropCount / max(net.txCount,1);

out.arrivalRatio = net.rxCount / max(net.txCount,1);

out.staleDiscardRatio = ...
    net.staleDiscardCount / max(net.rxCount,1);

out.effectiveUpdateRatio = ...
    (net.rxCount - net.staleDiscardCount) / max(net.txCount,1);


%% ============================================================
% Reverse-channel statistics
% ============================================================

out.ackTxCount   = net.ackTxCount;
out.ackRxCount   = net.ackRxCount;
out.ackDropCount = net.ackDropCount;

out.ackUpdateCount = net.ackUpdateCount;

out.staleAckDiscardedCount = net.staleAckDiscardedCount;

out.ackDeliveryRatio = net.ackRxCount / max(net.ackTxCount,1);

out.ackCoveredCount = net.ackCoveredCount;

% Packets confirmed per ACK. Above 1 means cumulative ACKs are
% genuinely retiring more than one packet at a time.
out.ackCumulativeGain = ...
    net.ackCoveredCount / max(net.ackUpdateCount,1);

out.duplicateAckCount = net.duplicateAckCount;

%% ============================================================
% In-flight suppression and outstanding packets
% ============================================================

% Occasions where v1's single-memory rule would have transmitted but
% v2 correctly stayed silent because the innovation was already on
% the wire. This is the mechanism the version change was made for.
out.suppressedInFlightCount = net.suppressedInFlightCount;

out.suppressedInFlightRatio = ...
    net.suppressedInFlightCount / max(net.triggerCheckCount,1);

out.meanOutstanding = ...
    net.outstandingSum / max(net.outstandingCount,1);

out.maxOutstanding = net.outstandingMax;


%% ============================================================
% Causality invariants
%
% Every one of these must be exactly zero for the run to be valid.
% ============================================================

out.ackBeforeAcceptCount   = net.ackBeforeAcceptCount;
out.ackForDroppedDataCount = net.ackForDroppedDataCount;
out.senderRollbackCount    = net.senderRollbackCount;
out.futureGenTimeCount     = net.futureGenTimeCount;
out.staleAckAcceptedCount  = net.staleAckAcceptedCount;
out.unknownSeqAckCount     = net.unknownSeqAckCount;

out.seqGenTimeMismatchCount = net.seqGenTimeMismatchCount;

out.invariantViolations = ...
    net.ackBeforeAcceptCount ...
    + net.ackForDroppedDataCount ...
    + net.senderRollbackCount ...
    + net.futureGenTimeCount ...
    + net.staleAckAcceptedCount ...
    + net.unknownSeqAckCount ...
    + net.seqGenTimeMismatchCount;


%% ============================================================
% Trigger statistics
% ============================================================

out.triggerCheckCount       = net.triggerCheckCount;
out.suppressedCount         = net.suppressedCount;
out.refractoryBlockedCount  = net.refractoryBlockedCount;
out.aoiCooldownBlockedCount = net.aoiCooldownBlockedCount;

out.positionTriggerCount = net.positionTriggerCount;
out.velocityTriggerCount = net.velocityTriggerCount;
out.aoiTriggerCount      = net.aoiTriggerCount;
out.timeoutTriggerCount  = net.timeoutTriggerCount;

out.suppressionRatio = ...
    net.suppressedCount / max(net.triggerCheckCount,1);

out.positionTriggerRatio = net.positionTriggerCount / max(net.txCount,1);
out.velocityTriggerRatio = net.velocityTriggerCount / max(net.txCount,1);
out.aoiTriggerRatio      = net.aoiTriggerCount      / max(net.txCount,1);
out.timeoutTriggerRatio  = net.timeoutTriggerCount  / max(net.txCount,1);


if net.adaptiveScaleCount > 0
    out.meanAdaptiveScale = net.adaptiveScaleSum / net.adaptiveScaleCount;
    out.minAdaptiveScale  = net.adaptiveScaleMinObserved;
else
    out.meanAdaptiveScale = cfg.aoiEvent.aoiStateScaleBase;
    out.minAdaptiveScale  = cfg.aoiEvent.aoiStateScaleBase;
end


%% ============================================================
% Communication rate
% ============================================================

missionTime = t(end) - t(1);

nChannels = nnz(cfg.swarm.A) + sum(cfg.swarm.pin);

out.txRateTotal      = net.txCount / max(missionTime,eps);
out.txRatePerChannel = out.txRateTotal / max(nChannels,1);

out.ackRateTotal      = net.ackTxCount / max(missionTime,eps);
out.ackRatePerChannel = out.ackRateTotal / max(nChannels,1);

end
