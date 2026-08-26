function trace = generateExternalForceTrace(cfg, level)
%GENERATEEXTERNALFORCETRACE World-frame external-force / wind proxy.
%
%   trace = generateExternalForceTrace(cfg, level)
%
% This is NOT an aerodynamic wind model, and must not be described as one.
% It does not depend on the vehicle's relative airspeed, carries no drag
% coefficient, and does not scale with frontal area or heading. It is a
% world-frame forcing term whose magnitude is specified as a
% NOMINAL-MASS EQUIVALENT EXTERNAL ACCELERATION:
%
%   Fext = cfg.quad.m * aExtWorld        (m is the NOMINAL mass)
%
% so `level` is in m/s^2, not in m/s of wind speed.
%
% Because Fext is built from the nominal mass, the acceleration a heavier
% vehicle actually feels is Fext / m_true. At the mass +10 % arm the
% realised external acceleration is therefore about 9 % below the nominal
% level. That is a deliberate consequence of defining the forcing as a
% force rather than an acceleration, and it is reported rather than
% compensated: compensating would make the mass arm change two things at
% once.
%
%   aExtWorld(t) = mean horizontal vector + bounded, filtered zero-mean gust
%
% The gust is low-pass filtered white noise with a ~1 s correlation time,
% clipped to keep it bounded. No new turbulence model is introduced.
%
% CRN: the realization is drawn on a fixed PHYSICAL-TIME grid from the seed
% alone, and looked up by time. It does not depend on the method, on how
% often a policy transmits, or on the outer step. Indexing randomness by
% trigger call would let a chattier policy consume the stream faster and
% meet a different realization, which would destroy the comparison.

baseDt = 0.01;

T = cfg.swarm.T;

nSample = ceil(T / baseDt) + 2;

trace.baseDt  = baseDt;
trace.level   = level;
trace.nSample = nSample;

if level <= 0

    trace.a = zeros(nSample, 3);

    trace.rms  = 0;
    trace.peak = 0;
    trace.hash = 0;

    return;

end


%% ============================================================
% Dedicated stream
%
% Independent of the forward trace, the reverse trace, the link-failure
% stream and the blackout stream, so adding disturbance perturbs nothing
% else about the realization.
% ============================================================

stream = RandStream('mt19937ar', ...
    'Seed', mod(cfg.net.seed + 70240001, 2^32));


%% ============================================================
% Mean horizontal component
%
% Direction drawn from the seed so the sweep is not always along +x,
% but identical across methods at the same seed.
% ============================================================

theta = 2*pi*rand(stream);

meanMag = 0.7 * level;

meanVec = meanMag * [cos(theta), sin(theta), 0];


%% ============================================================
% Bounded, filtered zero-mean gust
% ============================================================

gustStd = 0.3 * level;

tauC = 1.0;

alpha = exp(-baseDt / tauC);

% Scale the driving noise so the stationary std of the filtered process
% is gustStd rather than gustStd/sqrt(1-alpha^2).
drive = gustStd * sqrt(1 - alpha^2);

g = zeros(nSample, 3);

w = randn(stream, nSample, 3);

for k = 2:nSample
    g(k,:) = alpha * g(k-1,:) + drive * w(k,:);
end

bound = 1.5 * level;

g = max(min(g, bound), -bound);

% Vertical gust is halved: a horizontal forcing proxy that pushes as hard
% up as sideways would be a strange disturbance to claim.
g(:,3) = 0.5 * g(:,3);


a = repmat(meanVec, nSample, 1) + g;

trace.a = a;

mag = sqrt(sum(a.^2, 2));

trace.rms  = sqrt(mean(mag.^2));
trace.peak = max(mag);

trace.hash = mod(sum(abs(a(:)) .* (1:numel(a))'), 2^52);

end
