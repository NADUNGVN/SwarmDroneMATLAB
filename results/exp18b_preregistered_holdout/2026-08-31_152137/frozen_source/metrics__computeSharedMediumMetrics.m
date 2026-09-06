function M = computeSharedMediumMetrics(out,cfg)
%COMPUTESHAREDMEDIUMMETRICS Control, MAC, freshness and energy diagnostics.

M = computeSwarmMetrics(out,cfg);

if isfield(cfg,'shared') && isfield(cfg.shared,'evalStart')
    evalStart = cfg.shared.evalStart;
else
    evalStart = 8.0;
end
idx = out.t >= evalStart;

trueAgeArray = out.trueAoI(idx,:,:);
estAgeArray = out.estimatedAoI(idx,:,:);
jointAge = isfinite(trueAgeArray) & isfinite(estAgeArray);
ageGap = estAgeArray(jointAge)-trueAgeArray(jointAge);
trueAge = trueAgeArray(isfinite(trueAgeArray));
estAge = estAgeArray(isfinite(estAgeArray));

M.meanTrueAoI = safeMean(trueAge);
M.p95TrueAoI = percentile(trueAge,95);
M.p99TrueAoI = percentile(trueAge,99);
M.maxTrueAoI = safeMax(trueAge);
M.meanEstimatedAoI = safeMean(estAge);
M.p95EstimatedAoI = percentile(estAge,95);
M.meanAoIGap = safeMean(ageGap);

s = out.netStats;
T = max(cfg.swarm.T,eps);

M.dataFramesGenerated = s.dataFramesGenerated;
M.dataFramesAttempted = s.dataFramesAttempted;
M.dataFramesDeliveredAny = s.dataFramesDeliveredAny;
M.ackFramesAttempted = s.ackFramesAttempted;
M.ackEntriesDelivered = s.ackEntriesDelivered;
M.dataRecipientAttempts = s.dataRecipientAttempts;
M.dataRecipientSuccess = s.dataRecipientSuccess;
M.dataRecipientLoss = s.dataRecipientLoss;
M.collisionFrames = s.collisionFrames;
M.collisionRate = s.collisionFrames/max(s.framesAttempted,1);
M.queueDrops = s.queueDrops;
M.supersededBeforeService = s.supersededBeforeService;
M.retryFrames = s.retryFrames;
M.obsoleteRetryDrops = s.obsoleteRetryDrops;
M.maxQueueDepth = s.maxQueueDepth;
M.maxHistoryDepth = s.maxHistoryDepth;
M.staleDataDiscarded = s.staleDataDiscarded;
M.staleAckDiscarded = s.staleAckDiscarded;
M.expiredHistoryAckCount = s.expiredHistoryAckCount;
M.ackBeforeAcceptCount = s.ackBeforeAcceptCount;
M.ackFramesStandalone = s.ackFramesStandalone;
M.adaptiveAckPermitted = s.adaptiveAckPermitted;
M.adaptiveAckDeferred = s.adaptiveAckDeferred;
M.adaptiveAckForced = s.adaptiveAckForced;
M.ackEntriesPiggybacked = s.ackEntriesPiggybacked;
M.ackEntriesTransferred = s.ackEntriesTransferred;
M.ackRecipientAttempts = s.ackRecipientAttempts;
M.ackRecipientSuccess = s.ackRecipientSuccess;
M.ackRecipientLoss = s.ackRecipientLoss;
M.terminalActiveFrames = out.terminalActiveFrames;
M.terminalDataRecipientAttempts = out.terminalDataRecipientAttempts;
M.terminalAckRecipientAttempts = out.terminalAckRecipientAttempts;

M.channelUtilization = s.busyTime/T;
M.offeredAirtimeUtilization = (s.dataAirtime+s.ackAirtime)/T;
M.dataAirtime = s.dataAirtime;
M.ackAirtime = s.ackAirtime;
M.piggybackOverheadAirtime = s.piggybackOverheadAirtime;
M.backgroundBusyTime = s.backgroundBusyTime;
M.backgroundCollisionFrames = s.backgroundCollisionFrames;
M.dataChannelRecipientAttempts = s.dataChannelRecipientAttempts;
M.ackChannelRecipientAttempts = s.ackChannelRecipientAttempts;
M.dataChannelBadStateAttempts = s.dataChannelBadStateAttempts;
M.ackChannelBadStateAttempts = s.ackChannelBadStateAttempts;
M.dataChannelBadAttemptFraction = s.dataChannelBadStateAttempts / ...
    max(s.dataChannelRecipientAttempts,1);
M.ackChannelBadAttemptFraction = s.ackChannelBadStateAttempts / ...
    max(s.ackChannelRecipientAttempts,1);
M.energyProxyJ = cfg.mac.txPowerW*(s.dataAirtime+s.ackAirtime);

M.dataFrameGoodputHz = s.dataFramesDeliveredAny/T;
M.dataRecipientGoodputHz = s.dataRecipientSuccess/T;
M.ackGoodputHz = s.ackEntriesDelivered/T;
M.meanAccessDelay = safeMean(out.netLogs.accessDelay);
M.p95AccessDelay = percentile(out.netLogs.accessDelay,95);
M.meanOneWayDelay = safeMean(out.netLogs.dataOneWayDelay);
M.p95OneWayDelay = percentile(out.netLogs.dataOneWayDelay,95);
M.meanConfirmationDelay = safeMean(out.netLogs.confirmationDelay);
M.p95ConfirmationDelay = percentile(out.netLogs.confirmationDelay,95);

activeSender = any(out.topology,1)';
x = s.perNodeDataFramesDeliveredAny(activeSender);
M.jainFrameGoodput = jainIndex(x);

M.networkRuntimeSec = out.networkRuntimeSec;
M.invariantViolations = out.invariantViolations;
M.safeFailure = M.minSeparationEval < 2*cfg.swarm.safetyRadius;
localBusy=out.localBusyLog(idx,:);
M.meanLocalBusyEstimate=safeMean(localBusy(:));
M.maxLocalBusyEstimate=safeMax(localBusy(:));
if isfield(out.policy,'loadGuardBlockedByBranch')
    M.loadGuardBlocked=sum(out.policy.loadGuardBlockedByBranch);
    M.loadGuardBlockedByBranch=out.policy.loadGuardBlockedByBranch;
    M.loadGuardBlockedBusy=out.policy.loadGuardBlockedBusy;
    M.loadGuardBlockedQueue=out.policy.loadGuardBlockedQueue;
else
    M.loadGuardBlocked=0;
    M.loadGuardBlockedByBranch=zeros(1,5);
    M.loadGuardBlockedBusy=0;
    M.loadGuardBlockedQueue=0;
end

end


function y = safeMean(x)

if isempty(x), y = NaN; else, y = mean(x); end

end


function y = safeMax(x)

if isempty(x), y = NaN; else, y = max(x); end

end


function y = percentile(x,p)

x = sort(x(isfinite(x)));
if isempty(x)
    y = NaN;
    return;
end
if isscalar(x)
    y = x;
    return;
end
r = 1+(numel(x)-1)*p/100;
lo = floor(r);
hi = ceil(r);
w = r-lo;
y = (1-w)*x(lo)+w*x(hi);

end


function y = jainIndex(x)

x = x(:);
if isempty(x) || all(x == 0)
    y = 0;
else
    y = sum(x)^2/(numel(x)*sum(x.^2));
end

end
