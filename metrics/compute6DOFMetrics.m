function Q = compute6DOFMetrics(out, cfg)
%COMPUTE6DOFMETRICS Attitude, saturation, effort and divergence.
%
%   Q = compute6DOFMetrics(out, cfg)
%
% Saturation is counted over FOLLOWER-INNER SAMPLES: one sample per
% follower per inner step. The leader is kinematic and contributes none.
%
%   thrustSat = saturated follower-inner samples / total
%   torqueSat = follower-inner samples with >= 1 saturated torque axis
%               / total
%   saturation = max(thrustSat, torqueSat)
%
% A run is DIVERGED if any state is non-finite, if any follower leaves a
% 50 m ball around the leader, or if roll or pitch exceeds 80 degrees.
%
% DIVERGED counts as a stability failure AND as unsafe. It is excluded from
% continuous means (RMSE, control effort) because averaging a diverged run
% turns a failure into a large finite number and hides exactly what the
% stability gate exists to catch - but it is reported separately so the
% denominator of every mean stays visible.

Q.sixdof = false;

Q.diverged = false;

Q.rollPeak  = NaN;
Q.pitchPeak = NaN;

Q.thrustSat = NaN;
Q.torqueSat = NaN;
Q.saturation = NaN;

Q.perDronePeakSat = [];

Q.controlEffort = NaN;

if ~isfield(out,'six') || isempty(out.six) || ~isfield(out.six,'x')
    return;
end

six = out.six;

Q.sixdof = true;

N = size(six.x, 2);

nFollower = N - 1;

total = six.sampleCount * nFollower;

if total <= 0
    return;
end

Q.thrustSat = sum(six.thrustSatCount(2:N)) / total;
Q.torqueSat = sum(six.torqueSatCount(2:N)) / total;

Q.saturation = max(Q.thrustSat, Q.torqueSat);

% Per-drone peak saturation: the worst single follower, on whichever
% channel saturates more for it. A swarm mean can hide one vehicle
% sitting on its limit while the rest are comfortable.
perDrone = max(six.thrustSatCount(2:N), six.torqueSatCount(2:N)) / six.sampleCount;

Q.perDronePeakSat = perDrone(:)';

Q.rollPeak  = rad2deg(six.rollPeak);
Q.pitchPeak = rad2deg(six.pitchPeak);

% Normalised effort: thrust against hover, torque against its own limit.
if six.effortN > 0

    hover = cfg.quad.m * cfg.quad.g;

    Q.controlEffort = ...
        (six.thrustSq / six.effortN) / hover^2 + ...
        (six.torqueSq / six.effortN);

end

Q.diverged = six.diverged || ~all(isfinite(six.x(:)));

end
