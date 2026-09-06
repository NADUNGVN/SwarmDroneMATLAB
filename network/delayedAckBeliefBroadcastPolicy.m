function [sendFrame,info] = delayedAckBeliefBroadcastPolicy( ...
    expectedAges,timeSinceLastBroadcast,cfg)
%DELAYEDACKBELIEFBROADCASTPOLICY Bounded delayed-ACK age-belief baseline.

ages = expectedAges(:);
if isempty(ages) || any(~isfinite(ages) | ages < 0)
    error(['delayedAckBeliefBroadcastPolicy: expected ages must be finite ' ...
        'and nonnegative.']);
end

worstExpectedAge = max(ages);
eligible = timeSinceLastBroadcast >= cfg.aoiEvent.minInterTx-1e-12;
beliefDue = worstExpectedAge >= cfg.shared.beliefAgeThreshold-1e-12;
silenceDue = timeSinceLastBroadcast >= cfg.aoiEvent.maxSilence-1e-12;
sendFrame = eligible && (beliefDue || silenceDue);

info = struct('worstExpectedAge',worstExpectedAge, ...
    'beliefDue',beliefDue,'silenceDue',silenceDue,'eligible',eligible);

end
