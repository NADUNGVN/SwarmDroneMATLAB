function row = runExp14Cell(cfg,method,methodLabel,meta,trace)
%RUNEXP14CELL Execute and flatten one frozen EXP14 simulation cell.

out = simSwarmSharedMedium(cfg,method,trace);
M = computeSharedMediumMetrics(out,cfg);
Q = compute6DOFMetrics(out,cfg);

row = exp14EmptyRow();
row.stage = meta.stage;
row.seed = cfg.net.seed;
row.scenario = meta.scenario;
row.scenarioLabel = meta.scenarioLabel;
row.family = meta.family;
row.arm = meta.arm;
row.pointIndex = meta.pointIndex;
row.parameterValue = meta.parameterValue;
row.method = method;
row.methodLabel = methodLabel;
row.feedbackMode = out.feedbackMode;
row.N = cfg.swarm.N;
if isfield(cfg.swarm,'topology'), row.topology=cfg.swarm.topology; end
if Q.sixdof, row.plant='6dof'; else, row.plant='di'; end
row.macType = cfg.mac.type;
row.pAccess = out.pAccess;
row.configuredPAccess = cfg.mac.pAccess;
row.backgroundLoad = cfg.mac.backgroundLoad;
row.carrierSenseDensity = mean(cfg.mac.carrierSenseMatrix(:));
row.interferenceDensity = mean(cfg.mac.interferenceMatrix(:));

[row.stationaryMeanDataLoss,row.meanBadDurationDataSec] = ...
    channelMarginal(cfg.mac.burst.dataGoodLoss,cfg.mac.burst.dataBadLoss, ...
    cfg.mac.burst.dataGoodToBad,cfg.mac.burst.dataBadToGood,cfg.mac.slotTime);
[row.stationaryMeanAckLoss,row.meanBadDurationAckSec] = ...
    channelMarginal(cfg.mac.burst.ackGoodLoss,cfg.mac.burst.ackBadLoss, ...
    cfg.mac.burst.ackGoodToBad,cfg.mac.burst.ackBadToGood,cfg.mac.slotTime);

row.RMSE = M.formationRMSE;
row.MINSEP = M.minSeparationEval;
% Divergence is an explicit stability and safety failure.  It is retained as
% a binary outcome even when a continuous metric becomes non-finite.
row.SAFEFAIL = double(M.safeFailure || Q.diverged);
row.DIVERGED = double(Q.diverged);
row.ROLL_PEAK_DEG = Q.rollPeak;
row.PITCH_PEAK_DEG = Q.pitchPeak;
row.SATURATION = Q.saturation;
row.CONTROL_EFFORT = Q.controlEffort;
row.MEAN_TRUE_AOI = M.meanTrueAoI;
row.P95_TRUE_AOI = M.p95TrueAoI;
row.P99_TRUE_AOI = M.p99TrueAoI;
row.MAX_TRUE_AOI = M.maxTrueAoI;
row.MEAN_EST_AOI = M.meanEstimatedAoI;
row.MEAN_AOI_GAP = M.meanAoIGap;
row.DATA_GENERATED = M.dataFramesGenerated;
row.DATA_ATTEMPTED = M.dataFramesAttempted;
row.DATA_DELIVERED = M.dataFramesDeliveredAny;
row.ACK_ATTEMPTED = M.ackFramesAttempted;
row.ACK_ENTRIES_DELIVERED = M.ackEntriesDelivered;
row.DATA_RECIPIENT_ATTEMPTS = M.dataRecipientAttempts;
row.DATA_RECIPIENT_SUCCESS = M.dataRecipientSuccess;
row.DATA_RECIPIENT_LOSS = M.dataRecipientLoss;
row.ACK_RECIPIENT_ATTEMPTS = M.ackRecipientAttempts;
row.ACK_RECIPIENT_SUCCESS = M.ackRecipientSuccess;
row.ACK_RECIPIENT_LOSS = M.ackRecipientLoss;
row.TERMINAL_ACTIVE_FRAMES = M.terminalActiveFrames;
row.TERMINAL_DATA_INFLIGHT = M.terminalDataRecipientAttempts;
row.TERMINAL_ACK_INFLIGHT = M.terminalAckRecipientAttempts;
row.COLLISION_FRAMES = M.collisionFrames;
row.COLLISION_RATE = M.collisionRate;
row.QUEUE_DROPS = M.queueDrops;
row.SUPERSEDED = M.supersededBeforeService;
row.RETRIES = M.retryFrames;
row.OBSOLETE_RETRY_DROPS = M.obsoleteRetryDrops;
row.MAX_QUEUE = M.maxQueueDepth;
row.MAX_HISTORY = M.maxHistoryDepth;
row.historySize = cfg.mac.historySize;
row.STALE_DATA_DISCARDED = M.staleDataDiscarded;
row.STALE_ACK_DISCARDED = M.staleAckDiscarded;
row.EXPIRED_HISTORY_ACK = M.expiredHistoryAckCount;
row.ACK_BEFORE_ACCEPT = M.ackBeforeAcceptCount;
row.ACK_STANDALONE = M.ackFramesStandalone;
row.ACK_ENTRIES_PIGGYBACKED = M.ackEntriesPiggybacked;
row.ACK_ENTRIES_TRANSFERRED = M.ackEntriesTransferred;
row.ADAPTIVE_ACK_PERMITTED = M.adaptiveAckPermitted;
row.ADAPTIVE_ACK_DEFERRED = M.adaptiveAckDeferred;
row.ADAPTIVE_ACK_FORCED = M.adaptiveAckForced;
row.MEAN_LOCAL_BUSY = M.meanLocalBusyEstimate;
row.MAX_LOCAL_BUSY = M.maxLocalBusyEstimate;
row.LOAD_GUARD_BLOCKED = M.loadGuardBlocked;
row.LOAD_GUARD_BLOCKED_BUSY = M.loadGuardBlockedBusy;
row.LOAD_GUARD_BLOCKED_QUEUE = M.loadGuardBlockedQueue;
row.LOAD_GUARD_BRANCH3 = M.loadGuardBlockedByBranch(3);
row.LOAD_GUARD_BRANCH4 = M.loadGuardBlockedByBranch(4);
row.CHANNEL_UTIL = M.channelUtilization;
row.OFFERED_UTIL = M.offeredAirtimeUtilization;
row.DATA_AIRTIME = M.dataAirtime;
row.ACK_AIRTIME = M.ackAirtime;
row.PIGGYBACK_AIRTIME = M.piggybackOverheadAirtime;
row.BACKGROUND_BUSY_TIME = M.backgroundBusyTime;
row.BACKGROUND_COLLISION_FRAMES = M.backgroundCollisionFrames;
row.ENERGY_PROXY_J = M.energyProxyJ;
row.DATA_GOODPUT_HZ = M.dataFrameGoodputHz;
row.RECIPIENT_GOODPUT_HZ = M.dataRecipientGoodputHz;
row.ACK_GOODPUT_HZ = M.ackGoodputHz;
row.MEAN_ACCESS_DELAY = M.meanAccessDelay;
row.P95_ACCESS_DELAY = M.p95AccessDelay;
row.MEAN_CONFIRM_DELAY = M.meanConfirmationDelay;
row.P95_CONFIRM_DELAY = M.p95ConfirmationDelay;
row.JAIN_FRAME_GOODPUT = M.jainFrameGoodput;
row.DATA_CHANNEL_ATTEMPTS = M.dataChannelRecipientAttempts;
row.ACK_CHANNEL_ATTEMPTS = M.ackChannelRecipientAttempts;
row.DATA_BAD_ATTEMPT_FRACTION = M.dataChannelBadAttemptFraction;
row.ACK_BAD_ATTEMPT_FRACTION = M.ackChannelBadAttemptFraction;
row.TRACE_DATA_BAD_FRACTION = out.dataBadStateFraction;
row.TRACE_ACK_BAD_FRACTION = out.ackBadStateFraction;
row.NETWORK_RUNTIME_SEC = M.networkRuntimeSec;
row.INVARIANT_VIOLATIONS = M.invariantViolations;
row.TRACE_HASH_EXACT = out.traceHashExact;
row.CHANNEL_STATE_HASH = out.channelStateHash;
row.CHANNEL_MODEL_SIGNATURE = trace.modelSignature;
if isfield(cfg,'estimator') && isfield(cfg.estimator,'noise')
    row.ESTIMATOR_HASH_EXACT = cfg.estimator.noise.hashExact;
else
    row.ESTIMATOR_HASH_EXACT = 0;
end
row.CONFIG_HASH = configHash(cfg);

end


function [meanLoss,meanBadDuration] = channelMarginal( ...
    goodLoss,badLoss,pGoodToBad,pBadToGood,slotTime)

denominator = pGoodToBad+pBadToGood;
if denominator==0
    stationaryBad = 0;
else
    stationaryBad = pGoodToBad/denominator;
end
meanLoss = (1-stationaryBad)*goodLoss+stationaryBad*badLoss;
if pBadToGood==0
    meanBadDuration = inf;
else
    meanBadDuration = slotTime/pBadToGood;
end

end
