function [sendFrame,info] = causalAoCIBroadcastPolicy( ...
    currentPos,currentVel,lastBroadcastPos,lastBroadcastVel, ...
    estimatedAges,timeSinceLastBroadcast,cfg)
%CAUSALAO CIBROADCASTPOLICY AoCI-inspired age-times-change baseline.
%
% The score is a continuous-state adaptation, not the discrete Markov AoCI
% metric of Wang et al.  It intentionally has no new-information/refresh split.

ages = estimatedAges(:);
if isempty(ages) || any(~isfinite(ages) | ages < 0)
    error('causalAoCIBroadcastPolicy: ages must be finite and nonnegative.');
end

dp = norm(currentPos(:)-lastBroadcastPos(:));
dv = norm(currentVel(:)-lastBroadcastVel(:));
innovation = max(dp/cfg.aoiEvent.posThreshold, ...
    dv/cfg.aoiEvent.velThreshold);
worstAge = max(ages);
normalizedAge = worstAge/max(cfg.aoiEvent.aoiThreshold,eps);
score = innovation*normalizedAge;

eligible = timeSinceLastBroadcast >= cfg.aoiEvent.minInterTx-1e-12;
scoreDue = score >= cfg.shared.aociRiskThreshold-1e-12;
silenceDue = timeSinceLastBroadcast >= cfg.aoiEvent.maxSilence-1e-12;
sendFrame = eligible && (scoreDue || silenceDue);

info = struct('innovation',innovation,'worstEstimatedAge',worstAge, ...
    'normalizedAge',normalizedAge,'score',score,'scoreDue',scoreDue, ...
    'silenceDue',silenceDue,'eligible',eligible);

end
