function [sendFrame,info] = causalAoIOnlyBroadcastPolicy( ...
    estimatedAges,timeSinceLastBroadcast,cfg)
%CAUSALAOIONLYBROADCASTPOLICY ACK-confirmed age baseline without innovation.

ages = estimatedAges(:);
if isempty(ages) || any(~isfinite(ages) | ages < 0)
    error('causalAoIOnlyBroadcastPolicy: ages must be finite and nonnegative.');
end
if ~isscalar(timeSinceLastBroadcast) || ...
        ~isfinite(timeSinceLastBroadcast) || timeSinceLastBroadcast < 0
    error('causalAoIOnlyBroadcastPolicy: elapsed time is invalid.');
end

worstAge = max(ages);
eligible = timeSinceLastBroadcast >= cfg.aoiEvent.minInterTx-1e-12;
ageDue = worstAge >= cfg.aoiEvent.aoiThreshold-1e-12;
silenceDue = timeSinceLastBroadcast >= cfg.aoiEvent.maxSilence-1e-12;
sendFrame = eligible && (ageDue || silenceDue);

info = struct('worstEstimatedAge',worstAge, ...
    'ageDue',ageDue,'silenceDue',silenceDue,'eligible',eligible);

end
