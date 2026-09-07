function out = simSwarmNetworkQueued(cfg)

% The generator is pinned explicitly. Parallel-pool workers default to a
% different generator than the client, so rng(seed) alone would make
% parfor results differ from the equivalent serial loop.
rng(cfg.net.seed, 'twister');

dt = cfg.swarm.dt;

t = (0:dt:cfg.swarm.T)';
K = numel(t);

N = cfg.swarm.N;

% Development-only TCNS branch-at-decision instrumentation. Both features
% default off and are isolated from every historical periodic path.
logPeriodicSenderFire = isfield(cfg,'tcns') && ...
    isfield(cfg.tcns,'logPeriodicSenderFire') && ...
    logical(cfg.tcns.logPeriodicSenderFire);
forcedTransmission = localForcedTransmissionConfig(cfg,t,N);

%% ============================================================
% Common random numbers (legacy default OFF)
%
% With cfg.net.useTrace true, channel outcomes come from a
% pre-drawn realisation indexed by (link, timestep) instead of from
% inline rand/randn. Every method then meets the same channel at the
% same instant, which sharing a seed alone does not achieve.
%
% Default false reproduces the locked behaviour exactly.
% ============================================================

if ~isfield(cfg.net,'useTrace')
    cfg.net.useTrace = false;
end

if cfg.net.useTrace
    netTrace = generateNetworkTrace(cfg);
else
    netTrace = [];
end

% ============================================================
% Transmission phase
%
% cfg.net.phaseOffset is the LEGACY flag. It is retained, and its
% default retained, because every locked experiment sets it explicitly
% and tests/test_lock_regression checks that it defaults off. It never
% did anything: the block below used to compute a per-link offset
% matrix that was never read by the transmission decision, so every
% locked result ran on ONE GLOBAL CLOCK regardless of the flag. That
% is recorded rather than quietly repaired, because "phase OFF" is
% what the locked results are, and it is what the flag delivered.
%
% cfg.net.phaseOffsetEnabled is the real thing, added for EXP10 and
% default OFF so no locked path changes. When it is on, each
% (physical sender, payload class) gets its own offset inside one
% period, drawn by utils/generatePhaseTrace, and the senders stop
% firing in lockstep.
% ============================================================

if ~isfield(cfg.net,'phaseOffset')
    cfg.net.phaseOffset = false;
end

if ~isfield(cfg.net,'phaseOffsetEnabled')
    cfg.net.phaseOffsetEnabled = false;
end


P = cfg.swarm.initialPositions;
V = cfg.swarm.initialVelocities;


Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);
DesiredOffsetsLog = zeros(K,N,3);
DisturbanceAccelerationLog = zeros(K,N,3);

LeaderPos = zeros(K,3);

AoILog = zeros(K,1);

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

% Optional passive receiver-memory log for theory/mechanism diagnostics.
% The flag defaults off, preserving the historical output footprint.  None
% of these arrays is read by the simulator or by a transmission decision.
logReceiverState = isfield(cfg,'tcns') && ...
    isfield(cfg.tcns,'logReceiverState') && ...
    logical(cfg.tcns.logReceiverState);
if logReceiverState
    ReceiverNeighborPositionLog = nan(K,N,N,3);
    ReceiverNeighborVelocityLog = nan(K,N,N,3);
    ReceiverNeighborGenTimeLog = nan(K,N,N);
    ReceiverLeaderPositionLog = nan(K,N,3);
    ReceiverLeaderVelocityLog = nan(K,N,3);
    ReceiverLeaderAccelerationLog = nan(K,N,3);
    ReceiverLeaderGenTimeLog = nan(K,N);
end

% 6-DOF follower state, created lazily on the first integration call.
sixState = [];

% Synthetic estimator state, created lazily. Empty when inert.
estState = [];



leader = leaderReference(0);

net = initQueuedNetworkState( ...
    P,V,leader,cfg);


% Initial state at t=0 is considered already transmitted.
%
% Per-sender transmission schedule. Entry j is the neighbour-state
% payload class of physical sender j; entry N+1 is the leader payload
% class. With phase disabled every offset is zero, so every entry of
% nextTx is cfg.net.commPeriod and stays in step for the whole run,
% which is exactly the single global clock the locked experiments ran
% on.
if cfg.net.phaseOffsetEnabled
    phaseTrace = generatePhaseTrace(cfg);
    phaseU = phaseTrace.u;
else
    phaseTrace = [];
    phaseU = zeros(N+1,1);
end

% Period in force at t = 0. commPeriodAt returns cfg.net.commPeriod and
% segment 0 unless a caller attached cfg.net.periodSchedule, so for every
% locked experiment and for all five fixed periodic EXP11 methods this is
% the constant period and periodSeg stays 0 for the whole run - no
% re-anchoring is ever triggered and the schedule is the locked one.
%
% Only Oracle-periodic supplies a schedule. Its phase offset is expressed
% as a FRACTION of the period in force, so the offset is re-scaled when the
% period changes rather than being frozen at its t = 0 value; a phase offset
% larger than the current period would otherwise silently skip a slot.
[periodNow, periodSeg] = commPeriodAt(cfg, 0);

phaseOffsetSec = phaseU * periodNow;

nextTx = phaseOffsetSec + periodNow;

% Passive: how many times each sender's clock fired. Written, never
% read by the simulation.
senderFireCount = zeros(N+1,1);

if logPeriodicSenderFire
    PeriodicSenderFireLog = false(K,N+1);
end

% Passive audit trail for the EXP11 oracle gate: every instant at which the
% transmission period actually changed, and the period it changed to. Empty
% for every fixed-period run, which is itself the evidence that the fixed
% periodic methods did not adapt.
periodSwitchTimes  = [];
periodSwitchValues = [];


for k = 1:K

    tk = t(k);


    leader = leaderReference(tk);

    currentOffsets = tcnsFormationOffsetsAt(cfg,tk);
    controlCfg = cfg;
    controlCfg.swarm.offsets = currentOffsets;


    % ========================================================
    % Physical leader
    % ========================================================

    P(1,:) = leader.pos';
    V(1,:) = leader.vel';

    % Synthetic swarm-state estimate, once per outer step. PHat/VHat feed
    % the policy self-state, the trigger and the transmitted payload; the
    % TRUE P/V stay what the dynamics integrate and what safety is
    % measured on. Inert when cfg.estimator is absent.
    [PHat, VHat, estState] = applyEstimator(P, V, estState, cfg, tk);

    % CRN slot. Identical to k unless the physical-time trace mode is on.
    kTrace = traceIndex(cfg, tk, k);



    % ========================================================
    % Packet generation
    % ========================================================

    % Period schedule. segNow is 0 on every static-period path, so the
    % re-anchoring branch below is dead code for the locked experiments
    % and for the fixed periodic methods, and nextTx keeps accumulating on
    % one uninterrupted grid straight through every channel switch.
    [pNow, segNow, segStartNow] = commPeriodAt(cfg, tk);

    if segNow ~= periodSeg

        % A period boundary was crossed. Restart the transmission grid at
        % the segment start, keeping each sender's phase fraction. See
        % commPeriodAt for why the grid is re-anchored instead of carried
        % over.
        nextTx = segStartNow + phaseU * pNow;

        if pNow ~= periodNow
            periodSwitchTimes(end+1)  = tk;      %#ok<AGROW>
            periodSwitchValues(end+1) = pNow;    %#ok<AGROW>
            periodNow = pNow;
        end

        periodSeg = segNow;

    end

    fireMask = tk >= nextTx - 1e-12;

    if logPeriodicSenderFire
        PeriodicSenderFireLog(k,:) = reshape(fireMask,1,N+1);
    end

    if any(fireMask)

        net = enqueueNetworkPackets( ...
            net,PHat,VHat,leader,tk,cfg,netTrace,kTrace,fireMask);

        nextTx(fireMask) = ...
            nextTx(fireMask) + ...
            pNow;

        senderFireCount(fireMask) = senderFireCount(fireMask) + 1;

    end

    % Optional one-action branch injection. It is deliberately applied
    % after the baseline periodic scheduler and must not coincide with that
    % payload class's normal fire. The injected action uses the same
    % pre-drawn link/time channel outcome as every paired baseline.
    if forcedTransmission.enabled && k==forcedTransmission.sampleIndex
        [net,forcedTransmission] = localInjectForcedTransmission( ...
            net,forcedTransmission,fireMask,PHat,VHat,leader,tk,cfg, ...
            netTrace,kTrace);
    end


    % ========================================================
    % Deliver packets whose arrival time has passed
    % ========================================================

    net = deliverNetworkPackets( ...
        net,tk,cfg);

    forcedTransmission = localObserveForcedDelivery( ...
        forcedTransmission,net,tk);


    % ========================================================
    % Formation controller
    % ========================================================

    accCmd = distributedFormationPolicy( ...
        PHat,VHat,leader,controlCfg,net);


    % ========================================================
    % Logging
    % ========================================================

    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;
    DesiredOffsetsLog(k,:,:) = reshape(currentOffsets,1,N,3);
    DisturbanceAccelerationLog(k,:,:) = reshape( ...
        tcnsFollowerDisturbanceAt(cfg,tk),1,N,3);

    LeaderPos(k,:) = leader.pos';

    if logReceiverState
        ReceiverNeighborPositionLog(k,:,:,:) = reshape(net.Pij,[1 N N 3]);
        ReceiverNeighborVelocityLog(k,:,:,:) = reshape(net.Vij,[1 N N 3]);
        ReceiverNeighborGenTimeLog(k,:,:) = reshape(net.genTime,[1 N N]);
        ReceiverLeaderPositionLog(k,:,:) = reshape(net.leaderPos,[1 N 3]);
        ReceiverLeaderVelocityLog(k,:,:) = reshape(net.leaderVel,[1 N 3]);
        ReceiverLeaderAccelerationLog(k,:,:) = ...
            reshape(net.leaderAcc,[1 N 3]);
        ReceiverLeaderGenTimeLog(k,:) = reshape(net.leaderGenTime,[1 N]);
    end


    % ========================================================
    % AoI
    % ========================================================

    ages = [];


    for i = 1:N

        for j = 1:N

            if cfg.swarm.A(i,j)

                age = ...
                    tk - net.genTime(i,j) ...
                    + 0.5*dt;

                ages(end+1) = age; %#ok<AGROW>

            end

        end


        if cfg.swarm.pin(i)

            age = ...
                tk - net.leaderGenTime(i) ...
                + 0.5*dt;

            ages(end+1) = age; %#ok<AGROW>

        end

    end


    AoILog(k) = mean(ages);


    TxCountLog(k) = net.txCount;
    BroadcastCountLog(k) = net.broadcastCount;


    if k == K
        break;
    end


    % ========================================================
    % Double-integrator followers
    % ========================================================

    % Follower integration. cfg.sixdof.enable off (default) reproduces the
    % locked semi-implicit Euler exactly; on, each follower is a 6-DOF
    % quadrotor driven through the analytic command-consistent reference.
    [P, V, sixState] = integrateFollowers(P, V, accCmd, sixState, cfg, tk);


end


out.t = t;

out.P = Plog;
out.V = Vlog;
out.A = Alog;
out.desiredOffsets = DesiredOffsetsLog;
out.appliedFollowerDisturbance = DisturbanceAccelerationLog;

out.LeaderPos = LeaderPos;

if logReceiverState
    out.receiverNeighborPosition = ReceiverNeighborPositionLog;
    out.receiverNeighborVelocity = ReceiverNeighborVelocityLog;
    out.receiverNeighborGenTime = ReceiverNeighborGenTimeLog;
    out.receiverLeaderPosition = ReceiverLeaderPositionLog;
    out.receiverLeaderVelocity = ReceiverLeaderVelocityLog;
    out.receiverLeaderAcceleration = ReceiverLeaderAccelerationLog;
    out.receiverLeaderGenTime = ReceiverLeaderGenTimeLog;
end

out.meanAoI = AoILog;
out.dropCount = net.dropCount;
out.staleDiscardCount = ...
    net.staleDiscardCount;

% ============================================================
% Network statistics
% ============================================================

out.txCount    = net.txCount;
out.txCountLog = TxCountLog;

% 6-DOF bookkeeping. Empty when cfg.sixdof.enable is off.
out.six = sixState;

% Synthetic estimator bookkeeping. Empty when inert.
out.est = estState;

% ============================================================
% Realization provenance
%
% The hash of the realization this run actually consumed, reported so
% that "every method met the same channel" is an audited fact rather
% than an assertion re-derived by the experiment script. NaN means the
% run used no trace of that kind.
% ============================================================

if ~isempty(netTrace)
    out.traceHash      = netTrace.hash;
    out.traceHashExact = netTrace.hashExact;
else
    out.traceHash      = NaN;
    out.traceHashExact = NaN;
end

% The periodic path has no reverse channel at all.
out.ackTraceHash      = NaN;
out.ackTraceHashExact = NaN;

if ~isempty(phaseTrace)
    out.phaseHash = phaseTrace.hash;
else
    out.phaseHash = NaN;
end

out.senderFireCount = senderFireCount;

if logPeriodicSenderFire
    out.periodicSenderFireLog = PeriodicSenderFireLog;
end
out.forcedPeriodicTransmission = forcedTransmission;

out.periodSwitchTimes  = periodSwitchTimes;
out.periodSwitchValues = periodSwitchValues;

% Broadcast accounting (EXP07C): unique (timestep, sender, payload
% class) DATA transmissions. Passive counter, never read by the sim.
out.broadcastCount = net.broadcastCount;
out.broadcastCountLog = BroadcastCountLog;
out.rxCount = net.rxCount;
out.dropCount = net.dropCount;

out.staleDiscardCount = ...
    net.staleDiscardCount;


% Packet Delivery Ratio:
% packets that were NOT dropped by the channel
out.PDR = ...
    1 - net.dropCount / max(net.txCount,1);


% Packets that actually arrived before simulation ended
out.arrivalRatio = ...
    net.rxCount / max(net.txCount,1);

% ============================================================
% Out-of-order / effective communication statistics
% ============================================================

out.staleDiscardRatio = ...
    net.staleDiscardCount / ...
    max(net.rxCount,1);


out.effectiveUpdateRatio = ...
    (net.rxCount - net.staleDiscardCount) / ...
    max(net.txCount,1);

end


function F = localForcedTransmissionConfig(cfg,t,N)
%LOCALFORCEDTRANSMISSIONCONFIG Validate the default-off diagnostic hook.

F = struct('enabled',false,'time_s',NaN,'sampleIndex',NaN, ...
    'receiver',NaN,'sender',NaN,'linkClass','off', ...
    'attempted',false,'enqueued',false,'dropped',false, ...
    'resolved',false,'accepted',false,'arrivalTime_s',NaN, ...
    'txDelta',0,'dropDelta',0);
if ~isfield(cfg,'tcns') || ...
        ~isfield(cfg.tcns,'forcedPeriodicTransmission') || ...
        isempty(cfg.tcns.forcedPeriodicTransmission)
    return;
end

supplied = cfg.tcns.forcedPeriodicTransmission;
if ~isfield(supplied,'enabled')
    error('simSwarmNetworkQueued:ForcedTransmissionConfig', ...
        'forcedPeriodicTransmission.enabled is required.');
end
if ~isscalar(supplied.enabled) || ...
        ~(islogical(supplied.enabled) || isnumeric(supplied.enabled))
    error('simSwarmNetworkQueued:ForcedTransmissionConfig', ...
        'forcedPeriodicTransmission.enabled must be scalar logical.');
end
F.enabled = logical(supplied.enabled);
if ~F.enabled
    return;
end

required = {'time_s','receiver','sender','linkClass'};
for q = 1:numel(required)
    if ~isfield(supplied,required{q})
        error('simSwarmNetworkQueued:ForcedTransmissionConfig', ...
            'forcedPeriodicTransmission.%s is required.',required{q});
    end
end

validateattributes(supplied.time_s,{'numeric'}, ...
    {'real','finite','scalar','>=',0,'<=',t(end)}, ...
    mfilename,'forcedPeriodicTransmission.time_s');
validateattributes(supplied.receiver,{'numeric'}, ...
    {'real','finite','integer','scalar','>=',2,'<=',N}, ...
    mfilename,'forcedPeriodicTransmission.receiver');
validateattributes(supplied.sender,{'numeric'}, ...
    {'real','finite','integer','scalar','>=',1,'<=',N}, ...
    mfilename,'forcedPeriodicTransmission.sender');
[distance,sampleIndex] = min(abs(t-supplied.time_s));
if distance>1e-12
    error('simSwarmNetworkQueued:ForcedTransmissionGrid', ...
        'The forced transmission time must lie on the outer sample grid.');
end
if (isfield(cfg.net,'regime') && ~isempty(cfg.net.regime)) || ...
        (isfield(cfg.net,'jitterStd') && cfg.net.jitterStd~=0)
    error('simSwarmNetworkQueued:ForcedTransmissionChannelScope', ...
        'The first forced-action diagnostic requires static zero-jitter delay.');
end

linkClass = lower(char(supplied.linkClass));
i = supplied.receiver;
j = supplied.sender;
switch linkClass
    case 'ordinary'
        if cfg.swarm.A(i,j)==0
            error('simSwarmNetworkQueued:ForcedTransmissionLink', ...
                'The requested ordinary link is not in cfg.swarm.A.');
        end
    case 'pinned-leader'
        if j~=1 || cfg.swarm.pin(i)<=0
            error('simSwarmNetworkQueued:ForcedTransmissionLink', ...
                'A pinned-leader action requires sender 1 and a pinned receiver.');
        end
    otherwise
        error('simSwarmNetworkQueued:ForcedTransmissionClass', ...
            'linkClass must be ordinary or pinned-leader.');
end

F.time_s = double(t(sampleIndex));
F.sampleIndex = sampleIndex;
F.receiver = double(i);
F.sender = double(j);
F.linkClass = linkClass;

end


function [net,F] = localInjectForcedTransmission( ...
    net,F,fireMask,P,V,leader,tk,cfg,netTrace,kTrace)
%LOCALINJECTFORCEDTRANSMISSION Add exactly one directed payload action.

N = cfg.swarm.N;
singleCfg = cfg;
singleCfg.swarm.A = zeros(N);
singleCfg.swarm.pin = zeros(N,1);
singleFire = false(N+1,1);

switch F.linkClass
    case 'ordinary'
        if fireMask(F.sender)
            error('simSwarmNetworkQueued:ForcedTransmissionCollision', ...
                ['Forced ordinary action coincides with the baseline ' ...
                 'sender-payload clock.']);
        end
        singleCfg.swarm.A(F.receiver,F.sender) = 1;
        singleFire(F.sender) = true;
    case 'pinned-leader'
        if fireMask(N+1)
            error('simSwarmNetworkQueued:ForcedTransmissionCollision', ...
                ['Forced pinned-leader action coincides with the baseline ' ...
                 'leader-payload clock.']);
        end
        singleCfg.swarm.pin(F.receiver) = 1;
        singleFire(N+1) = true;
end

txBefore = net.txCount;
dropBefore = net.dropCount;
net = enqueueNetworkPackets( ...
    net,P,V,leader,tk,singleCfg,netTrace,kTrace,singleFire);
F.txDelta = net.txCount-txBefore;
F.dropDelta = net.dropCount-dropBefore;
F.attempted = F.txDelta==1;
F.dropped = F.dropDelta==1;
F.enqueued = F.attempted && ~F.dropped;
if ~F.attempted || F.txDelta~=1 || ~ismember(F.dropDelta,[0 1])
    error('simSwarmNetworkQueued:ForcedTransmissionAttempt', ...
        'The forced action did not create exactly one DATA attempt.');
end

np = netParamsAt(cfg,tk);
F.arrivalTime_s = tk+max(np.delay,0);
if F.dropped
    F.resolved = true;
end

end


function F = localObserveForcedDelivery(F,net,tk)
%LOCALOBSERVEFORCEDDELIVERY Record acceptance at the first due sample.

if ~F.enabled || ~F.enqueued || F.resolved || ...
        tk<F.arrivalTime_s-1e-12
    return;
end

if strcmp(F.linkClass,'ordinary')
    acceptedGenTime = net.genTime(F.receiver,F.sender);
else
    acceptedGenTime = net.leaderGenTime(F.receiver);
end
F.accepted = abs(acceptedGenTime-F.time_s)<=1e-12;
F.resolved = true;

end
