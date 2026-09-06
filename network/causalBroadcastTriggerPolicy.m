function [sendFrame, branch, info] = causalBroadcastTriggerPolicy( ...
    currentPos, currentVel, ...
    lastBroadcastPos, lastBroadcastVel, ...
    estimatedAges, latestUnconfirmed, ...
    timeSinceLastBroadcast, cfg)
%CAUSALBROADCASTTRIGGERPOLICY Worst-neighbour causal semantic broadcast rule.
%
% One sender state is common to every out-neighbour, but receiver freshness is
% link-specific.  Version 1 aggregates those receiver beliefs conservatively
% through their maximum age, then reuses the frozen Causal-v3 branch semantics.
% It adds no learned component and no new threshold parameter.
%
% latestUnconfirmed(i) means receiver i has not causally confirmed the sender's
% latest broadcast.  It is derived only from transmitted sequence numbers and
% delivered ACK summaries; channel drop/collision truth must never enter it.

estimatedAges = estimatedAges(:);
latestUnconfirmed = logical(latestUnconfirmed(:));

if numel(estimatedAges) ~= numel(latestUnconfirmed)
    error('causalBroadcastTriggerPolicy: receiver vectors must have equal length.');
end
if isempty(estimatedAges)
    sendFrame = false;
    branch = 0;
    info = emptyInfo();
    return;
end
if any(~isfinite(estimatedAges) | estimatedAges < 0)
    error('causalBroadcastTriggerPolicy: estimated ages must be finite and nonnegative.');
end

[worstAge,criticalReceiver] = max(estimatedAges);
nUnconfirmed = nnz(latestUnconfirmed);

[sendFrame, branch, base] = causalInnovationTriggerPolicy( ...
    currentPos, currentVel, ...
    lastBroadcastPos, lastBroadcastVel, ...
    worstAge, timeSinceLastBroadcast, nUnconfirmed, cfg);

info = base;
info.worstEstimatedAge = worstAge;
info.criticalReceiver  = criticalReceiver;
info.receiverCount     = numel(estimatedAges);
info.staleReceiverCount = nnz(estimatedAges >= cfg.aoiEvent.aoiThreshold);
info.unconfirmedReceiverCount = nUnconfirmed;
info.aggregation = 'worst-neighbour';

end


function info = emptyInfo()

info = struct( ...
    'branch',                   0, ...
    'worstEstimatedAge',        0, ...
    'criticalReceiver',         0, ...
    'receiverCount',            0, ...
    'staleReceiverCount',       0, ...
    'unconfirmedReceiverCount', 0, ...
    'aggregation',              'worst-neighbour');

end

