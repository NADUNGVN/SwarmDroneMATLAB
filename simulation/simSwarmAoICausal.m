function out = simSwarmAoICausal(cfg)
%SIMSWARMAOICAUSAL AoI-aware swarm with an explicit, causal ACK protocol (v2).
%
%   out = simSwarmAoICausal(cfg)
%
% In its default legacy mode this uses the same formation controller,
% network model and trigger policy as simSwarmAoIAware. The difference is
% confined to how the transmitter learns what the receiver holds:
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
%       Failed the rate-ordering gate: once suppression removed the hard
%       triggers, all traffic ran through the AoI branch and its 0.10 s
%       cooldown pinned the rate at ~9 Hz in every network.
%   v3  cfg.causal.innovationPriority. Separates new information from
%       refresh, so aoiMinInterTx governs repetition only. No parameter
%       value changed.
%   Gate 4 cfg.causal.policyMode='control-aware'. Uses the same causal ACK
%       protocol but derives link events from a formation-degradation budget.

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

% Reverse-channel common random numbers. Default off preserves the
% RandStream behaviour the earlier results were produced with.
if ~isfield(cfg.ack,'useTrace')
    cfg.ack.useTrace = false;
end


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

% v3: separate genuine new information from refresh traffic. Default
% false keeps v2 semantics exactly reproducible.
if ~isfield(cfg.causal,'innovationPriority')
    cfg.causal.innovationPriority = false;
end

% Gate 4 adds an isolated theorem-derived policy mode. Keeping the default
% on the historical path is a reproducibility contract: merely updating the
% repository must not change any Causal-v1/v2/v3 result.
if ~isfield(cfg.causal,'policyMode')
    cfg.causal.policyMode = 'legacy-v3';
end

policyMode = lower(char(cfg.causal.policyMode));
if ~ismember(policyMode,{'legacy-v3','control-aware'})
    error('simSwarmAoICausal:UnknownPolicyMode', ...
        'Unknown cfg.causal.policyMode "%s".',cfg.causal.policyMode);
end


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
% Gate-4 control-aware policy configuration
% ============================================================

if strcmp(policyMode,'control-aware')
    if ~cfg.causal.useAckFeedback
        error('simSwarmAoICausal:ControlAwareNeedsAck', ...
            ['Control-aware possible-receiver-set mode requires cumulative ' ...
             'ACK feedback. The no-ACK arm is a separate ablation.']);
    end
    if ~isfield(cfg,'controlAware') || ...
            ~isfield(cfg.controlAware,'epsilonPosition')
        error('simSwarmAoICausal:MissingControlBudget', ...
            ['Control-aware mode requires the declared sweep parameter ' ...
             'cfg.controlAware.epsilonPosition [m].']);
    end
    if ~isfield(cfg.controlAware,'minInterTx')
        cfg.controlAware.minInterTx = cfg.aoiEvent.minInterTx;
    end
    if ~isfield(cfg.controlAware,'retryInterval')
        % Inherit the already documented 0.10 s refresh interval for the
        % first Gate-4 implementation. It is a declared liveness parameter,
        % not a value selected against a baseline.
        cfg.controlAware.retryInterval = cfg.aoiEvent.aoiMinInterTx;
    end
    cfg.controlAware.budget = tcnsControlAwareBudget( ...
        cfg,cfg.controlAware.epsilonPosition);
end


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
DesiredOffsetsLog = zeros(K,N,3);
DisturbanceAccelerationLog = zeros(K,N,3);

LeaderPos = zeros(K,3);
LeaderVel = zeros(K,3);

MeanAoILog = zeros(K,1);

% Passive cumulative transmission log. Written but never read by the
% simulator, so it cannot influence any result. Used only to measure
% traffic inside a fault window, which a run total cannot resolve.
TxCountLog = zeros(K,1);

% Passive cumulative broadcast log, same contract as TxCountLog: written
% every step, never read by the simulation. Added for EXP11, which needs
% every communication count restricted to a time window rather than the
% whole run - the first 8 s are warm-up and must not enter any metric, and
% a scalar total cannot be windowed after the fact.

BroadcastCountLog = zeros(K,1);

% 6-DOF follower state, created lazily on the first integration call.
sixState = [];

% Synthetic estimator state, created lazily. Empty when inert.
estState = [];

% Passive cumulative ACK log, same contract as TxCountLog: written,
% never read by the simulation. Needed to measure reverse-channel
% traffic inside a blackout window.
AckCountLog = zeros(K,1);


NeighborAoILog = nan(K,N,N);
LeaderAoILog   = nan(K,N);

% Transmitter-side belief, logged for diagnostics only. Never read back
% into the control or trigger path.
EstAoILog = nan(K,N,N);

% Gate-2 diagnostic instrumentation. This is deliberately default-off and
% passive: none of these arrays is ever read by the simulator. When enabled,
% they expose the receiver's actual zero-order-hold state after all DATA due
% at tk has been delivered and immediately before formation control is
% evaluated. That timestamp convention is essential for checking an exact
% sampled staleness bound rather than reconstructing receiver state later.
logReceiverState = isfield(cfg,'tcns') && ...
    isfield(cfg.tcns,'logReceiverState') && cfg.tcns.logReceiverState;
logCausalSetBound = isfield(cfg,'tcns') && ...
    isfield(cfg.tcns,'logCausalSetBound') && cfg.tcns.logCausalSetBound;

if logReceiverState
    ReceiverNeighborPositionLog = nan(K,N,N,3);
    ReceiverNeighborVelocityLog = nan(K,N,N,3);
    ReceiverNeighborGenTimeLog = nan(K,N,N);
    ReceiverLeaderPositionLog = nan(K,N,3);
    ReceiverLeaderVelocityLog = nan(K,N,3);
    ReceiverLeaderAccelerationLog = nan(K,N,3);
    ReceiverLeaderGenTimeLog = nan(K,N);
end

if logCausalSetBound
    SenderSetPositionBoundLog = nan(K,N,N);
    SenderSetVelocityBoundLog = nan(K,N,N);
    SenderSetCandidateCountLog = nan(K,N,N);
    SenderLeaderSetPositionBoundLog = nan(K,N);
    SenderLeaderSetVelocityBoundLog = nan(K,N);
    SenderLeaderSetAccelerationBoundLog = nan(K,N);
    SenderLeaderSetCandidateCountLog = nan(K,N);
end


%% ============================================================
% Common random numbers (legacy default OFF)
% ============================================================

if ~isfield(cfg.net,'useTrace')
    cfg.net.useTrace = false;
end

if cfg.net.useTrace
    netTrace = generateNetworkTrace(cfg);
else
    netTrace = [];
end

% The reverse trace depends only on seed, N and horizon, never on the
% ACK impairment settings, so every impairment cell for one scenario
% and seed shares a single reverse realisation.
if cfg.ack.useTrace
    ackTrace = generateAckTrace(cfg);
else
    ackTrace = [];
end


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
% v3 branch counters and protocol invariants
% ============================================================

net.hardInnovationCount   = 0;
net.adaptiveNewInfoCount  = 0;
net.refreshCount          = 0;

net.refreshCooldownBlockedCount = 0;
net.refreshInFlightBlockedCount = 0;

net.newInfoBypassWithoutInnovationCount   = 0;
net.refreshWhileUsefulPacketInFlightCount = 0;

% Gate-4 counters are separate from the historical trigger composition.
% They remain zero in legacy mode and are never read by the simulator.
net.controlAwareCheckCount = 0;
net.controlAwareViolationCount = 0;
net.controlAwareNewInformationCount = 0;
net.controlAwareRecoveryCount = 0;
net.controlAwareRetryCount = 0;
net.controlAwareUsefulInFlightSuppressedCount = 0;
net.controlAwareRefractoryBlockedCount = 0;
net.controlAwareRiskSum = 0;
net.controlAwareRiskMax = 0;
net.controlAwareStepRiskMax = 0;
net.controlAwareStepViolationCount = 0;

ControlAwareViolationCountLog = zeros(K,1);
ControlAwareNewInformationCountLog = zeros(K,1);
ControlAwareRecoveryCountLog = zeros(K,1);
ControlAwareRetryCountLog = zeros(K,1);
ControlAwareUsefulInFlightSuppressedCountLog = zeros(K,1);
ControlAwareStepRiskMaxLog = zeros(K,1);
ControlAwareStepViolationCountLog = zeros(K,1);

% Largest observed gap ending in a transmission. In legacy mode maxSilence
% supplies a hard backstop; control-aware links may remain quiet indefinitely
% while their controller contribution stays within budget.
net.maxInterTxGap = 0;


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

    currentOffsets = tcnsFormationOffsetsAt(cfg,tk);
    controlCfg = cfg;
    controlCfg.swarm.offsets = currentOffsets;

    P(1,:) = leader.pos';
    V(1,:) = leader.vel';

    % Synthetic swarm-state estimate, once per outer step. PHat/VHat feed
    % the policy self-state, the trigger and the transmitted payload; the
    % TRUE P/V stay what the dynamics integrate and what safety is
    % measured on. Inert when cfg.estimator is absent.
    [PHat, VHat, estState] = applyEstimator(P, V, estState, cfg, tk);

    % CRN slot. Identical to k unless the physical-time trace mode is on.
    kTrace = traceIndex(cfg, tk, k);



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

    net = deliverDataWithAck(net, tk, cfg, ackTrace, kTrace);


    %% --------------------------------------------------------
    % STEP 3
    %
    % Trigger evaluation using transmitter belief only.
    % ---------------------------------------------------------

    [net, txState] = enqueueCausalAoIPackets( ...
        net, txState, PHat, VHat, leader, tk, cfg, netTrace, kTrace);


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

    net = deliverDataWithAck(net, tk, cfg, ackTrace, kTrace);


    %% --------------------------------------------------------
    % Formation control
    % ---------------------------------------------------------

    accCmd = distributedFormationPolicy(PHat, VHat, leader, controlCfg, net);


    %% --------------------------------------------------------
    % Logging
    % ---------------------------------------------------------

    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;
    DesiredOffsetsLog(k,:,:) = reshape(currentOffsets,1,N,3);
    DisturbanceAccelerationLog(k,:,:) = reshape( ...
        tcnsFollowerDisturbanceAt(cfg,tk),1,N,3);

    LeaderPos(k,:) = leader.pos';
    LeaderVel(k,:) = leader.vel';

    if logReceiverState
        ReceiverNeighborPositionLog(k,:,:,:) = ...
            reshape(net.Pij,[1 N N 3]);
        ReceiverNeighborVelocityLog(k,:,:,:) = ...
            reshape(net.Vij,[1 N N 3]);
        ReceiverNeighborGenTimeLog(k,:,:) = ...
            reshape(net.genTime,[1 N N]);
        ReceiverLeaderPositionLog(k,:,:) = ...
            reshape(net.leaderPos,[1 N 3]);
        ReceiverLeaderVelocityLog(k,:,:) = ...
            reshape(net.leaderVel,[1 N 3]);
        ReceiverLeaderAccelerationLog(k,:,:) = ...
            reshape(net.leaderAcc,[1 N 3]);
        ReceiverLeaderGenTimeLog(k,:) = ...
            reshape(net.leaderGenTime,[1 N]);
    end


    % Causal transmitter information-set envelope. It uses only local
    % current state, cumulatively ACK-confirmed payload memory, and sent
    % outstanding payload records. In particular, it never reads receiver
    % registers or the outstanding record's simulation-only drop flag.
    if logCausalSetBound
        for i = 1:N
            for j = 1:N
                if cfg.swarm.A(i,j)==0
                    continue;
                end
                setBound = causalReceiverStateSetBound( ...
                    PHat(j,:),VHat(j,:), ...
                    reshape(txState.ackPos(i,j,:),1,3), ...
                    reshape(txState.ackVel(i,j,:),1,3), ...
                    txState.outstanding{i,j});
                SenderSetPositionBoundLog(k,i,j) = setBound.position;
                SenderSetVelocityBoundLog(k,i,j) = setBound.velocity;
                SenderSetCandidateCountLog(k,i,j) = ...
                    setBound.candidateCount;
            end
        end

        for i = 2:N
            if ~cfg.swarm.pin(i)
                continue;
            end
            setBound = causalReceiverStateSetBound( ...
                leader.pos',leader.vel',txState.leaderAckPos(i,:), ...
                txState.leaderAckVel(i,:),txState.leaderOutstanding{i}, ...
                leader.acc',txState.leaderAckAcc(i,:));
            SenderLeaderSetPositionBoundLog(k,i) = setBound.position;
            SenderLeaderSetVelocityBoundLog(k,i) = setBound.velocity;
            SenderLeaderSetAccelerationBoundLog(k,i) = ...
                setBound.acceleration;
            SenderLeaderSetCandidateCountLog(k,i) = ...
                setBound.candidateCount;
        end
    end


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


    TxCountLog(k)  = net.txCount;
    BroadcastCountLog(k) = net.broadcastCount;
    AckCountLog(k) = net.ackTxCount;
    ControlAwareViolationCountLog(k) = net.controlAwareViolationCount;
    ControlAwareNewInformationCountLog(k) = ...
        net.controlAwareNewInformationCount;
    ControlAwareRecoveryCountLog(k) = net.controlAwareRecoveryCount;
    ControlAwareRetryCountLog(k) = net.controlAwareRetryCount;
    ControlAwareUsefulInFlightSuppressedCountLog(k) = ...
        net.controlAwareUsefulInFlightSuppressedCount;
    ControlAwareStepRiskMaxLog(k) = net.controlAwareStepRiskMax;
    ControlAwareStepViolationCountLog(k) = ...
        net.controlAwareStepViolationCount;


    if k == K
        break;
    end


    %% --------------------------------------------------------
    % Double-integrator followers
    % ---------------------------------------------------------

    % Follower integration. cfg.sixdof.enable off (default) reproduces the
    % locked semi-implicit Euler exactly; on, each follower is a 6-DOF
    % quadrotor driven through the analytic command-consistent reference.
    [P, V, sixState] = integrateFollowers(P, V, accCmd, sixState, cfg, tk);


end


%% ============================================================
% Trajectory outputs
% ============================================================

out.t = t;

out.P = Plog;
out.V = Vlog;
out.A = Alog;
out.desiredOffsets = DesiredOffsetsLog;
out.appliedFollowerDisturbance = DisturbanceAccelerationLog;

out.LeaderPos = LeaderPos;
out.LeaderVel = LeaderVel;

out.meanAoI     = MeanAoILog;
out.neighborAoI = NeighborAoILog;
out.leaderAoI   = LeaderAoILog;

out.estimatedAoI = EstAoILog;

if logReceiverState
    out.receiverNeighborPosition = ReceiverNeighborPositionLog;
    out.receiverNeighborVelocity = ReceiverNeighborVelocityLog;
    out.receiverNeighborGenTime = ReceiverNeighborGenTimeLog;
    out.receiverLeaderPosition = ReceiverLeaderPositionLog;
    out.receiverLeaderVelocity = ReceiverLeaderVelocityLog;
    out.receiverLeaderAcceleration = ReceiverLeaderAccelerationLog;
    out.receiverLeaderGenTime = ReceiverLeaderGenTimeLog;
end


if logCausalSetBound
    out.senderSetPositionBound = SenderSetPositionBoundLog;
    out.senderSetVelocityBound = SenderSetVelocityBoundLog;
    out.senderSetCandidateCount = SenderSetCandidateCountLog;
    out.senderLeaderSetPositionBound = SenderLeaderSetPositionBoundLog;
    out.senderLeaderSetVelocityBound = SenderLeaderSetVelocityBoundLog;
    out.senderLeaderSetAccelerationBound = ...
        SenderLeaderSetAccelerationBoundLog;
    out.senderLeaderSetCandidateCount = SenderLeaderSetCandidateCountLog;
end


%% ============================================================
% Forward-channel statistics
% ============================================================

out.txCount           = net.txCount;
out.txCountLog        = TxCountLog;

% 6-DOF bookkeeping. Empty when cfg.sixdof.enable is off.
out.six = sixState;

% Synthetic estimator bookkeeping. Empty when inert.
out.est = estState;
out.ackCountLog       = AckCountLog;

% Broadcast accounting (EXP07C): unique (timestep, sender, payload
% class) DATA transmissions. Passive counter, never read by the sim.
out.broadcastCount = net.broadcastCount;
out.broadcastCountLog = BroadcastCountLog;
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

out.newInfoBypassWithoutInnovationCount = ...
    net.newInfoBypassWithoutInnovationCount;

out.refreshWhileUsefulPacketInFlightCount = ...
    net.refreshWhileUsefulPacketInFlightCount;


%% ============================================================
% Gate-4 control-aware policy diagnostics
% ============================================================

out.controlAwareActive = strcmp(policyMode,'control-aware');
out.controlAwareCheckCount = net.controlAwareCheckCount;
out.controlAwareViolationCount = net.controlAwareViolationCount;
out.controlAwareNewInformationCount = net.controlAwareNewInformationCount;
out.controlAwareRecoveryCount = net.controlAwareRecoveryCount;
out.controlAwareRetryCount = net.controlAwareRetryCount;
out.controlAwareUsefulInFlightSuppressedCount = ...
    net.controlAwareUsefulInFlightSuppressedCount;
out.controlAwareRefractoryBlockedCount = ...
    net.controlAwareRefractoryBlockedCount;
out.controlAwareViolationCountLog = ControlAwareViolationCountLog;
out.controlAwareNewInformationCountLog = ...
    ControlAwareNewInformationCountLog;
out.controlAwareRecoveryCountLog = ControlAwareRecoveryCountLog;
out.controlAwareRetryCountLog = ControlAwareRetryCountLog;
out.controlAwareUsefulInFlightSuppressedCountLog = ...
    ControlAwareUsefulInFlightSuppressedCountLog;
out.controlAwareStepRiskMax = ControlAwareStepRiskMaxLog;
out.controlAwareStepViolationCount = ControlAwareStepViolationCountLog;
out.controlAwareViolationRatio = net.controlAwareViolationCount / ...
    max(net.controlAwareCheckCount,1);
out.controlAwareMeanNormalizedRisk = net.controlAwareRiskSum / ...
    max(net.controlAwareCheckCount,1);
out.controlAwareMaxNormalizedRisk = net.controlAwareRiskMax;

if out.controlAwareActive
    out.controlAwareConfig = rmfield(cfg.controlAware,'budget');
    out.controlAwareBudget = cfg.controlAware.budget;
else
    out.controlAwareConfig = struct();
    out.controlAwareBudget = struct();
end


%% ============================================================
% v3 branch composition
%
% refreshCooldownBlockedCount must be > 0 in v3, otherwise
% aoiMinInterTx has become dead code and the run is not valid.
% ============================================================

out.hardInnovationCount  = net.hardInnovationCount;
out.adaptiveNewInfoCount = net.adaptiveNewInfoCount;
out.refreshCount         = net.refreshCount;

out.maxInterTxGap = net.maxInterTxGap;

out.refreshCooldownBlockedCount = net.refreshCooldownBlockedCount;
out.refreshInFlightBlockedCount = net.refreshInFlightBlockedCount;

out.hardInnovationRatio  = net.hardInnovationCount  / max(net.txCount,1);
out.adaptiveNewInfoRatio = net.adaptiveNewInfoCount / max(net.txCount,1);
out.refreshRatio         = net.refreshCount         / max(net.txCount,1);

out.invariantViolations = ...
    net.ackBeforeAcceptCount ...
    + net.ackForDroppedDataCount ...
    + net.senderRollbackCount ...
    + net.futureGenTimeCount ...
    + net.staleAckAcceptedCount ...
    + net.unknownSeqAckCount ...
    + net.seqGenTimeMismatchCount ...
    + net.newInfoBypassWithoutInnovationCount ...
    + net.refreshWhileUsefulPacketInFlightCount;


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

if ~isempty(netTrace)
    out.traceHash      = netTrace.hash;
    out.traceHashExact = netTrace.hashExact;
else
    out.traceHash      = NaN;
    out.traceHashExact = NaN;
end

if ~isempty(ackTrace)
    out.ackTraceHash      = ackTrace.hash;
    out.ackTraceHashExact = ackTrace.hashExact;
else
    out.ackTraceHash      = NaN;
    out.ackTraceHashExact = NaN;
end

% Causal-v3 is event driven and has no periodic clock, so the EXP10
% transmission-phase realization does not apply to it. Reported as NaN
% rather than omitted, so a hash table has one column per trace type
% for every method.
out.phaseHash = NaN;

out.ackRateTotal      = net.ackTxCount / max(missionTime,eps);
out.ackRatePerChannel = out.ackRateTotal / max(nChannels,1);

end
