function out = simSwarmSharedMedium(cfg, method, trace)
%SIMSWARMSHAREDMEDIUM End-to-end formation over the EXP12 shared medium.
%
%   out = simSwarmSharedMedium(cfg, method)
%   out = simSwarmSharedMedium(cfg, method, trace)
%
% Public method values:
%   'periodic'          fixed-period state broadcast, no ACK traffic
%   'state-event'       state-event broadcast, no ACK traffic
%   'causal-aoi-only'   worst confirmed-age baseline
%   'causal-aoci'       age-times-content-change baseline
%   'delayed-ack-belief' bounded particle age-belief baseline
%   'causal-broadcast'  worst-neighbour causal freshness with aggregated ACK
%   'mac-aware-broadcast' causal broadcast with local-busy ACK/load adaptation
%   'load-guarded-broadcast' causal broadcast with hybrid ACK and local guard
%   'causal-unicast'    same causal trigger, one DATA frame per receiver
%
% DATA and ACK share one finite-queue p-persistent channel.  A successful
% DATA event updates both receiver protocol truth and the state cache consumed
% by distributedFormationPolicy.  Collision/loss truth is never read by a
% trigger.  Every stochastic MAC decision comes from one pre-drawn absolute
% (slot,node/receiver/sender) trace.

if nargin < 1 || isempty(cfg)
    error('simSwarmSharedMedium: cfg is required.');
end
if nargin < 2 || isempty(method)
    if isfield(cfg,'shared') && isfield(cfg.shared,'method')
        method = cfg.shared.method;
    else
        error('simSwarmSharedMedium: method is required.');
    end
end

method = normalizeMethod(method);
cfg = normalizeConfig(cfg,method);
mac = sharedMediumConfig(cfg);
cfg.mac = mac;

rng(cfg.net.seed,'twister');

dt = cfg.swarm.dt;
slotRatio = dt/mac.slotTime;
if abs(slotRatio-round(slotRatio)) > 1e-10
    error(['simSwarmSharedMedium: swarm.dt must be an integer multiple ' ...
        'of mac.slotTime.']);
end

t = (0:dt:cfg.swarm.T)';
K = numel(t);
N = cfg.swarm.N;

P = cfg.swarm.initialPositions;
V = cfg.swarm.initialVelocities;
validatePlantBoundary(cfg,P,V);

topology = logical(cfg.swarm.A);
topology(logical(cfg.swarm.pin(:)),1) = true;
topology(1:N+1:end) = false;

leader = leaderReference(0);
net = initSharedMediumState(cfg,topology);
net = initializeSharedMediumControlState(net,P,V,leader,cfg);
if nargin < 3 || isempty(trace)
    trace = generateSharedMediumTrace(cfg);
else
    validateSuppliedTrace(trace,cfg,mac);
end

tx.lastPos  = P;
tx.lastVel  = V;
tx.lastTime = zeros(N,1);
tx.nextPeriodicTime = zeros(N,1);
tx.branchCounts = zeros(1,5);
tx.reasonCounts = zeros(1,3);
tx.requestCount = zeros(N,1);
tx.admittedCount = zeros(N,1);
tx.loadGuardBlockedByBranch = zeros(1,5);
tx.loadGuardBlockedBusy = 0;
tx.loadGuardBlockedQueue = 0;

belief = initializeBeliefState(cfg,topology);

Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);
LeaderPos = zeros(K,3);
LeaderVel = zeros(K,3);

TrueAoI = nan(K,N,N);
EstimatedAoI = nan(K,N,N);
MeanTrueAoI = nan(K,1);
MeanEstimatedAoI = nan(K,1);
QueueDepth = zeros(K,N);
BusyTimeLog = zeros(K,1);
DataAttemptLog = zeros(K,1);
DataDeliveredLog = zeros(K,1);
AckAttemptLog = zeros(K,1);
CollisionLog = zeros(K,1);
DataAirtimeLog = zeros(K,1);
AckAirtimeLog = zeros(K,1);
LocalBusyLog = zeros(K,N);

sixState = [];
estState = [];
networkRuntimeSec = 0;
networkEventCount = 0;

for k = 1:K
    tk = t(k);

    leader = leaderReference(tk);
    P(1,:) = leader.pos';
    V(1,:) = leader.vel';

    [PHat,VHat,estState] = applyEstimator(P,V,estState,cfg,tk);

    if strcmp(method,'delayed-ack-belief')
        belief = assimilateConfirmedBelief(belief,net,topology);
    end

    % No new frame is generated at the terminal sample because it has no
    % service interval inside the declared mission horizon.
    if k < K
        for sender = 1:N
            receivers = find(topology(:,sender));
            if isempty(receivers)
                continue;
            end

            elapsed = tk-tx.lastTime(sender);
            send = false;
            branch = 0;
            reason = 0;

            switch method
                case 'periodic'
                    if tk >= tx.nextPeriodicTime(sender)-1e-12
                        send = true;
                        while tx.nextPeriodicTime(sender) <= tk+1e-12
                            tx.nextPeriodicTime(sender) = ...
                                tx.nextPeriodicTime(sender) + cfg.net.commPeriod;
                        end
                    end

                case 'state-event'
                    [send,reason] = eventTriggerPolicy( ...
                        PHat(sender,:),VHat(sender,:), ...
                        tx.lastPos(sender,:),tx.lastVel(sender,:), ...
                        elapsed,cfg);

                case 'causal-aoi-only'
                    estimatedAges = tk-net.ackedGenTime(receivers,sender);
                    send = causalAoIOnlyBroadcastPolicy( ...
                        estimatedAges,elapsed,cfg);

                case 'causal-aoci'
                    estimatedAges = tk-net.ackedGenTime(receivers,sender);
                    send = causalAoCIBroadcastPolicy( ...
                        PHat(sender,:),VHat(sender,:), ...
                        tx.lastPos(sender,:),tx.lastVel(sender,:), ...
                        estimatedAges,elapsed,cfg);

                case 'delayed-ack-belief'
                    expectedAges = expectedBeliefAges( ...
                        belief,receivers,sender,tk);
                    send = delayedAckBeliefBroadcastPolicy( ...
                        expectedAges,elapsed,cfg);

                case {'causal-broadcast','mac-aware-broadcast', ...
                        'load-guarded-broadcast','causal-unicast'}
                    estimatedAges = tk-net.ackedGenTime(receivers,sender);
                    latestUnconfirmed = net.ackedSeq(receivers,sender) ...
                        < net.lastBroadcastSeq(sender);
                    [send,branch] = causalBroadcastTriggerPolicy( ...
                        PHat(sender,:),VHat(sender,:), ...
                        tx.lastPos(sender,:),tx.lastVel(sender,:), ...
                        estimatedAges,latestUnconfirmed,elapsed,cfg);
                    if any(strcmp(method,{'mac-aware-broadcast', ...
                            'load-guarded-broadcast'}))
                        requested=send;
                        [send,guard] = macAwareLoadGuard( ...
                            requested,branch,net.localBusyEWMA(sender), ...
                            numel(net.queues{sender}),cfg);
                        if requested && ~send
                            tx.loadGuardBlockedByBranch(branch) = ...
                                tx.loadGuardBlockedByBranch(branch)+1;
                            tx.loadGuardBlockedBusy = ...
                                tx.loadGuardBlockedBusy + ...
                                double(guard.blockedByBusy);
                            tx.loadGuardBlockedQueue = ...
                                tx.loadGuardBlockedQueue + ...
                                double(guard.blockedByQueue);
                        end
                    end
            end

            if ~send
                continue;
            end

            tx.requestCount(sender) = tx.requestCount(sender)+1;
            accPayload = nan(1,3);
            if sender == 1
                accPayload = leader.acc';
            end

            if strcmp(method,'causal-unicast')
                [net,nAdmitted,seq] = enqueueUnicastState( ...
                    net,sender,PHat(sender,:),VHat(sender,:), ...
                    tk,cfg,accPayload);
                admitted = nAdmitted > 0;
            else
                [net,admitted,seq] = enqueueBroadcastState( ...
                    net,sender,PHat(sender,:),VHat(sender,:), ...
                    tk,cfg,accPayload);
            end

            if admitted
                tx.admittedCount(sender) = tx.admittedCount(sender)+1;
                tx.lastPos(sender,:) = PHat(sender,:);
                tx.lastVel(sender,:) = VHat(sender,:);
                tx.lastTime(sender) = tk;
                if branch > 0
                    tx.branchCounts(branch) = tx.branchCounts(branch)+1;
                end
                if reason > 0
                    tx.reasonCounts(reason) = tx.reasonCounts(reason)+1;
                end
                if strcmp(method,'delayed-ack-belief')
                    belief = projectBeliefOnAdmission( ...
                        belief,sender,receivers,seq,tk,cfg);
                end
            end
        end
    end

    accCmd = distributedFormationPolicy(PHat,VHat,leader,cfg,net);

    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;
    LeaderPos(k,:) = leader.pos';
    LeaderVel(k,:) = leader.vel';

    active = find(topology);
    trueAgeMatrix = nan(N,N);
    estimatedAgeMatrix = nan(N,N);
    trueAgeMatrix(active) = tk-net.acceptedGenTime(active);
    if cfg.shared.feedbackEnabled
        estimatedAgeMatrix(active) = tk-net.ackedGenTime(active);
    end
    TrueAoI(k,:,:) = trueAgeMatrix;
    EstimatedAoI(k,:,:) = estimatedAgeMatrix;
    MeanTrueAoI(k) = mean(trueAgeMatrix(active));
    if cfg.shared.feedbackEnabled
        MeanEstimatedAoI(k) = mean(estimatedAgeMatrix(active));
    end

    QueueDepth(k,:) = cellfun(@numel,net.queues)';
    BusyTimeLog(k) = net.stats.busyTime;
    DataAttemptLog(k) = net.stats.dataFramesAttempted;
    DataDeliveredLog(k) = net.stats.dataFramesDeliveredAny;
    AckAttemptLog(k) = net.stats.ackFramesAttempted;
    CollisionLog(k) = net.stats.collisionFrames;
    DataAirtimeLog(k) = net.stats.dataAirtime;
    AckAirtimeLog(k) = net.stats.ackAirtime;
    LocalBusyLog(k,:) = net.localBusyEWMA;

    if cfg.shared.assertInvariants
        assertProtocolInvariants(net,topology,mac);
    end

    if k == K
        break;
    end

    tNetwork = tic;
    replayDue=net.ackBranchReplay.enabled && ...
        any(~cellfun(@isempty,net.pendingAck) & ...
        net.pendingAckDue<=tk+dt+1e-12);
    if replayDue
        context=struct('P',P,'V',V,'accCmd',accCmd, ...
            'sixState',sixState,'estState',estState,'tx',tx, ...
            'belief',belief,'outerIndex',k,'outerTime',tk);
        net.ackBranchState.contextHash=configHash(context);
    elseif net.ackBranchReplay.enabled
        net.ackBranchState.contextHash=0;
    end
    [net,events] = advanceSharedMedium(net,tk,tk+dt,cfg,trace);
    networkRuntimeSec = networkRuntimeSec + toc(tNetwork);
    networkEventCount = networkEventCount + numel(events);

    [P,V,sixState] = integrateFollowers( ...
        P,V,accCmd,sixState,cfg,tk);
end

out = struct();
out.method = method;
out.t = t;
out.P = Plog;
out.V = Vlog;
out.A = Alog;
out.LeaderPos = LeaderPos;
out.LeaderVel = LeaderVel;
out.meanAoI = MeanTrueAoI;
out.meanEstimatedAoI = MeanEstimatedAoI;
out.trueAoI = TrueAoI;
out.estimatedAoI = EstimatedAoI;
out.queueDepth = QueueDepth;
out.busyTimeLog = BusyTimeLog;
out.dataAttemptLog = DataAttemptLog;
out.dataDeliveredLog = DataDeliveredLog;
out.ackAttemptLog = AckAttemptLog;
out.collisionLog = CollisionLog;
out.dataAirtimeLog = DataAirtimeLog;
out.ackAirtimeLog = AckAirtimeLog;
out.localBusyLog = LocalBusyLog;
out.topology = topology;
out.netStats = net.stats;
out.netLogs = net.logs;
out.ackValueLog = net.logs.confirmationEvents;
out.ackValueLogging = net.ackValueLogging;
out.ackAdmissionLog = net.logs.ackAdmissionEvents;
out.ackBranchReplay = net.ackBranchReplay;
out.ackBranchState = net.ackBranchState;
out.policy = tx;
out.networkRuntimeSec = networkRuntimeSec;
out.networkEventCount = networkEventCount;
out.traceHashExact = trace.hashExact;
out.channelStateHash = trace.channelStateHash;
out.dataBadStateFraction = trace.dataBadFraction;
out.ackBadStateFraction = trace.ackBadFraction;
out.six = sixState;
out.est = estState;
out.belief = summarizeBelief(belief,topology,cfg);
out.feedbackMode = cfg.shared.feedbackMode;
out.pAccess = mac.pAccess;
out.macAwareConfig = cfg.shared.macAware;
terminal = sharedMediumTerminalCounts(net);
out.terminalActiveFrames = terminal.frames;
out.terminalDataRecipientAttempts = terminal.dataRecipientAttempts;
out.terminalAckRecipientAttempts = terminal.ackRecipientAttempts;

% Compatibility names are physical shared-medium quantities, never
% per-directed-link proxies.
out.txCount = net.stats.dataFramesAttempted;
out.broadcastCount = net.stats.dataFramesAttempted;
out.ackTxCount = net.stats.ackFramesAttempted;
out.rxCount = net.stats.dataRecipientSuccess;
out.dropCount = net.stats.dataRecipientLoss;
out.PDR = net.stats.dataRecipientSuccess / ...
    max(net.stats.dataRecipientAttempts,1);
out.invariantViolations = protocolViolationCount(net);

end


function validateSuppliedTrace(trace,cfg,mac)

required = {'slotTime','K','N','hashExact','modelSignature', ...
    'channelStateHash','dataBadFraction','ackBadFraction'};
for k = 1:numel(required)
    if ~isfield(trace,required{k})
        error('simSwarmSharedMedium: supplied trace lacks %s.',required{k});
    end
end
expectedK = ceil(cfg.swarm.T/mac.slotTime)+2;
if trace.N~=cfg.swarm.N || trace.K<expectedK || ...
        abs(trace.slotTime-mac.slotTime)>1e-12
    error(['simSwarmSharedMedium: supplied trace dimensions or slot time ' ...
        'do not match cfg.']);
end
if trace.modelSignature~=sharedMediumChannelSignature(mac,cfg.swarm.N)
    error(['simSwarmSharedMedium: supplied trace was generated for a ' ...
        'different channel model.']);
end
if isfield(trace,'sourceMode') && ...
        strcmp(char(string(trace.sourceMode)),'measured-probability-v1')
    validateMeasuredSharedMediumTrace(trace,cfg);
end

end


function method = normalizeMethod(method)

method = lower(strtrim(char(method)));
valid = {'periodic','state-event','causal-aoi-only','causal-aoci', ...
    'delayed-ack-belief','causal-broadcast','mac-aware-broadcast', ...
    'load-guarded-broadcast','causal-unicast'};
if ~any(strcmp(method,valid))
    error(['simSwarmSharedMedium: unknown method. Expected periodic, ' ...
        'state-event, causal-aoi-only, causal-aoci, delayed-ack-belief, ' ...
        'causal-broadcast, mac-aware-broadcast, load-guarded-broadcast, ' ...
        'or causal-unicast.']);
end

end


function cfg = normalizeConfig(cfg,method)

if ~isfield(cfg,'shared'), cfg.shared = struct(); end
if ~isfield(cfg,'event'), cfg.event = struct(); end
if ~isfield(cfg,'aoiEvent'), cfg.aoiEvent = struct(); end
if ~isfield(cfg,'mac'), cfg.mac = struct(); end

cfg.event = setDefault(cfg.event,'posThreshold',0.05);
cfg.event = setDefault(cfg.event,'velThreshold',0.10);
cfg.event = setDefault(cfg.event,'maxSilence',0.50);

cfg.aoiEvent = setDefault(cfg.aoiEvent,'posThreshold',0.05);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'velThreshold',0.10);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'aoiThreshold',0.12);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'maxSilence',0.50);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'minInterTx',cfg.swarm.dt);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'aoiMinInterTx',0.10);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'aoiStateScaleBase',0.50);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'aoiStateScaleMin',0.20);
cfg.aoiEvent = setDefault(cfg.aoiEvent,'aoiAdaptRange',1.00);

cfg.shared = setDefault(cfg.shared,'assertInvariants',true);
cfg.shared = setDefault(cfg.shared,'evalStart',8.0);
cfg.shared = setDefault(cfg.shared,'aociRiskThreshold',1.0);
cfg.shared = setDefault(cfg.shared,'beliefAgeThreshold', ...
    cfg.aoiEvent.aoiThreshold);
cfg.shared = setDefault(cfg.shared,'beliefParticleCount',64);
cfg.shared = setDefault(cfg.shared,'beliefDeliveryProbability',0.65);
cfg.shared.macAware = macAwarePolicyConfig(cfg);
cfg.shared.method = method;

if any(strcmp(method,{'periodic','state-event'}))
    cfg.shared.feedbackMode = 'none';
elseif strcmp(method,'mac-aware-broadcast')
    requested = 'adaptive';
    if isfield(cfg.shared,'feedbackMode') && ...
            ~isempty(cfg.shared.feedbackMode)
        requested = lower(strtrim(char(cfg.shared.feedbackMode)));
    end
    if ~strcmp(requested,'adaptive')
        error(['simSwarmSharedMedium: mac-aware-broadcast requires ' ...
            'feedbackMode=adaptive.']);
    end
    cfg.shared.feedbackMode = 'adaptive';
    if ~isfield(cfg.mac,'pAccess') || isempty(cfg.mac.pAccess)
        cfg.mac.pAccess=1;
    end
    if cfg.shared.macAware.accessScalingEnabled
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    end
elseif strcmp(method,'load-guarded-broadcast')
    requested = 'hybrid';
    if isfield(cfg.shared,'feedbackMode') && ...
            ~isempty(cfg.shared.feedbackMode)
        requested = lower(strtrim(char(cfg.shared.feedbackMode)));
    end
    if ~strcmp(requested,'hybrid')
        error(['simSwarmSharedMedium: load-guarded-broadcast requires ' ...
            'feedbackMode=hybrid.']);
    end
    if ~cfg.shared.macAware.loadGuardEnabled
        error(['simSwarmSharedMedium: load-guarded-broadcast requires an ' ...
            'enabled load guard.']);
    end
    cfg.shared.feedbackMode = 'hybrid';
    if ~isfield(cfg.mac,'pAccess') || isempty(cfg.mac.pAccess)
        cfg.mac.pAccess=1;
    end
    if cfg.shared.macAware.accessScalingEnabled
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    end
elseif strcmp(method,'causal-unicast')
    requested = 'standalone';
    if isfield(cfg.shared,'feedbackMode') && ...
            ~isempty(cfg.shared.feedbackMode)
        requested = lower(strtrim(char(cfg.shared.feedbackMode)));
    end
    if ~strcmp(requested,'standalone')
        error(['simSwarmSharedMedium: causal-unicast requires ' ...
            'feedbackMode=standalone.']);
    end
    cfg.shared.feedbackMode = 'standalone';
else
    cfg.shared = setDefault(cfg.shared,'feedbackMode','hybrid');
    if strcmp(cfg.shared.feedbackMode,'none')
        error(['simSwarmSharedMedium: causal policies require standalone, ' ...
            'piggyback, or hybrid feedback.']);
    end
    if strcmpi(cfg.shared.feedbackMode,'adaptive')
        error(['simSwarmSharedMedium: adaptive feedback requires ' ...
            'method=mac-aware-broadcast.']);
    end
end
cfg.shared.feedbackMode = sharedMediumFeedbackMode(cfg);
cfg.shared.feedbackEnabled = ~strcmp(cfg.shared.feedbackMode,'none');

validatePolicyParameters(cfg);

% This simulator owns event application.  The low-level kernel preserves its
% explicit-apply default for backward-compatible micro-tests.
cfg.mac.applyDeliveriesInline = true;

end


function validatePolicyParameters(cfg)

if ~isscalar(cfg.shared.aociRiskThreshold) || ...
        ~isfinite(cfg.shared.aociRiskThreshold) || ...
        cfg.shared.aociRiskThreshold <= 0
    error('simSwarmSharedMedium: aociRiskThreshold must be positive.');
end
if ~isscalar(cfg.shared.beliefAgeThreshold) || ...
        ~isfinite(cfg.shared.beliefAgeThreshold) || ...
        cfg.shared.beliefAgeThreshold <= 0
    error('simSwarmSharedMedium: beliefAgeThreshold must be positive.');
end
P = cfg.shared.beliefParticleCount;
if ~isscalar(P) || ~isfinite(P) || P < 2 || P ~= floor(P)
    error(['simSwarmSharedMedium: beliefParticleCount must be an integer ' ...
        'of at least two.']);
end
q = cfg.shared.beliefDeliveryProbability;
if ~isscalar(q) || ~isfinite(q) || q < 0 || q > 1
    error(['simSwarmSharedMedium: beliefDeliveryProbability must lie ' ...
        'in [0,1].']);
end

end


function belief = initializeBeliefState(cfg,topology)

P = cfg.shared.beliefParticleCount;
belief.particleGenTime = nan(cfg.swarm.N,cfg.swarm.N,P);
for q = 1:P
    layer = nan(cfg.swarm.N);
    layer(topology) = 0;
    belief.particleGenTime(:,:,q) = layer;
end
belief.particleCount = P;
belief.updateCount = 0;

end


function belief = assimilateConfirmedBelief(belief,net,topology)

for q = 1:belief.particleCount
    layer = belief.particleGenTime(:,:,q);
    layer(topology) = max(layer(topology),net.ackedGenTime(topology));
    belief.particleGenTime(:,:,q) = layer;
end

end


function ages = expectedBeliefAges(belief,receivers,sender,tk)

g = reshape(belief.particleGenTime(receivers,sender,:), ...
    numel(receivers),belief.particleCount);
ages = mean(max(tk-g,0),2);

end


function belief = projectBeliefOnAdmission( ...
    belief,sender,receivers,seq,tk,cfg)

P = belief.particleCount;
base = ((1:P)-0.5)/P;
qSuccess = cfg.shared.beliefDeliveryProbability;

for receiver = receivers(:)'
    rotation = seq*0.618033988749895 + sender*0.414213562373095 ...
        + receiver*0.732050807568877;
    u = mod(base+rotation,1);
    delivered = u < qSuccess;
    values = reshape(belief.particleGenTime(receiver,sender,:),1,P);
    values(delivered) = tk;
    belief.particleGenTime(receiver,sender,:) = reshape(values,1,1,P);
end
belief.updateCount = belief.updateCount+1;

end


function summary = summarizeBelief(belief,topology,cfg)

summary.particleCount = belief.particleCount;
summary.updateCount = belief.updateCount;
summary.deliveryProbability = cfg.shared.beliefDeliveryProbability;
if belief.updateCount == 0
    summary.meanGenerationTime = NaN;
else
    active = repmat(topology,1,1,belief.particleCount);
    summary.meanGenerationTime = mean(belief.particleGenTime(active));
end

end


function s = setDefault(s,name,value)

if ~isfield(s,name) || isempty(s.(name))
    s.(name) = value;
end

end


function validatePlantBoundary(cfg,P,V)

N = cfg.swarm.N;
if ~isscalar(N) || N < 2 || N ~= floor(N)
    error('simSwarmSharedMedium: swarm.N must be an integer >= 2.');
end
if ~isequal(size(P),[N 3]) || ~isequal(size(V),[N 3])
    error('simSwarmSharedMedium: initial states must be N-by-3.');
end
if ~isequal(size(cfg.swarm.A),[N N]) || ...
        any(cfg.swarm.A(:) ~= 0 & cfg.swarm.A(:) ~= 1)
    error('simSwarmSharedMedium: swarm.A must be binary N-by-N.');
end
if numel(cfg.swarm.pin) ~= N || ...
        any(cfg.swarm.pin(:) ~= 0 & cfg.swarm.pin(:) ~= 1)
    error('simSwarmSharedMedium: swarm.pin must be binary N-by-1.');
end
if ~isfield(cfg.net,'commPeriod') || ~isscalar(cfg.net.commPeriod) || ...
        cfg.net.commPeriod <= 0
    error('simSwarmSharedMedium: net.commPeriod must be positive.');
end

end


function assertProtocolInvariants(net,topology,mac)

if any(net.ackedSeq(topology) > net.acceptedSeq(topology))
    error('simSwarmSharedMedium: ACK sequence exceeds receiver truth.');
end
if any(net.ackedGenTime(topology) > net.acceptedGenTime(topology)+1e-12)
    error('simSwarmSharedMedium: estimated AoI is non-conservative.');
end
if any(cellfun(@numel,net.queues) > mac.queueCapacity)
    error('simSwarmSharedMedium: finite queue capacity was exceeded.');
end
if any(net.historyCount > mac.historySize)
    error('simSwarmSharedMedium: bounded sender history was exceeded.');
end
pending=~cellfun(@isempty,net.pendingAck);
if any(pending~=isfinite(net.pendingAckSince))
    error('simSwarmSharedMedium: pending ACK age state is inconsistent.');
end
if any(~isfinite(net.localBusyEWMA) | net.localBusyEWMA<0 | ...
        net.localBusyEWMA>1+1e-12)
    error('simSwarmSharedMedium: local busy estimate is invalid.');
end
if protocolViolationCount(net) > 0
    error('simSwarmSharedMedium: a causal protocol invariant was violated.');
end

end


function n = protocolViolationCount(net)

s = net.stats;
n = s.unknownSeqAckCount + s.seqGenTimeMismatchCount + ...
    s.futureGenTimeCount + s.senderRollbackCount + ...
    s.ackBeforeAcceptCount + s.causalConservatismViolationCount;

end
