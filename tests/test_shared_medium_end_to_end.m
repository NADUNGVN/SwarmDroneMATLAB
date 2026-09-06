%% TEST_SHARED_MEDIUM_END_TO_END Sampled formation/MAC integration gates.

startup;

fprintf('\n============================================================\n');
fprintf('test_shared_medium_end_to_end\n');
fprintf('============================================================\n\n');

checks = cell(0,2);

cfg = study2SharedMediumConfig();
cfg.swarm.T = 0.8;
cfg.shared.evalStart = 0.2;
cfg.net.seed = 12012991;

% Periodic has no feedback channel and must be trace deterministic.
p1 = simSwarmSharedMedium(cfg,'periodic');
p2 = simSwarmSharedMedium(cfg,'periodic');
checks(end+1,:) = {isequaln(p1.P,p2.P) && ...
    isequaln(p1.netStats,p2.netStats) && ...
    p1.traceHashExact==p2.traceHashExact, ...
    'one method/action sequence is bit-identical on one MAC trace'};
checks(end+1,:) = {p1.ackTxCount==0 && ...
    p1.netStats.ackEntriesDelivered==0, ...
    'periodic broadcast does not pay for unused causal feedback'};

M = computeSharedMediumMetrics(p1,cfg);
checks(end+1,:) = {isfinite(M.formationRMSE) && ...
    isfinite(M.meanTrueAoI) && isfinite(M.channelUtilization), ...
    'control, freshness and channel metrics share one finite output contract'};

% Causal-Broadcast must use delivered ACKs without violating conservatism.
cb = simSwarmSharedMedium(cfg,'causal-broadcast');
ageMask = isfinite(cb.trueAoI) & isfinite(cb.estimatedAoI);
checks(end+1,:) = {cb.ackTxCount>0 && ...
    cb.netStats.ackEntriesDelivered>0 && cb.invariantViolations==0, ...
    'Causal-Broadcast receives real aggregated feedback with zero violations'};
checks(end+1,:) = {all(cb.estimatedAoI(ageMask) >= ...
    cb.trueAoI(ageMask)-1e-12), ...
    'sender confirmed age remains conservative at every logged active link'};

% All five nodes are synchronized at p=1 in one fully-conflicting domain.
collapseCfg = cfg;
collapseCfg.swarm.T = 0.4;
collapseCfg.mac.pAccess = 1;
collapse = simSwarmSharedMedium(collapseCfg,'periodic');
checks(end+1,:) = {collapse.netStats.collisionFrames>0 && ...
    collapse.netStats.dataRecipientSuccess==0 && ...
    collapse.netStats.dataFramesDeliveredAny==0, ...
    'p=1 synchronized periodic load produces the declared collision collapse'};

s = cb.netStats;
checks(end+1,:) = {s.dataRecipientSuccess+s.dataRecipientLoss == ...
    s.dataRecipientAttempts && s.busyTime <= ...
    s.dataAirtime+s.ackAirtime+1e-12, ...
    'completed recipient outcomes and airtime accounting close exactly'};
checks(end+1,:) = {s.maxQueueDepth<=cfg.mac.queueCapacity && ...
    s.maxHistoryDepth<=cfg.mac.historySize && ...
    all(isfinite(cb.P(:))) && all(isfinite(cb.V(:))), ...
    'finite queue/history bounds hold and plant state remains finite'};

flags = cellfun(@logical,checks(:,1));
for k = 1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_shared_medium_end_to_end: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_shared_medium_end_to_end: PASS (%d checks)\n',numel(flags));
