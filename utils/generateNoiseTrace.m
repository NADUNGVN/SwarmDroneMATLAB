function trace = generateNoiseTrace(cfg, posSigma, velSigma)
%GENERATENOISETRACE Synthetic estimator noise on a physical-time grid.
%
%   trace = generateNoiseTrace(cfg, posSigma, velSigma)
%
% This is a SYNTHETIC estimator noise model. The sigmas are parameter
% assumptions, not hardware measurements, and must never be presented as a
% measured sensor model.
%
% The realization lives on a COMMON PHYSICAL-TIME MASTER GRID:
%
%   baseNoiseDt = 0.01 s
%   noise indexed by  seed x masterTime x agent x component
%
% At outer dt = 0.02 a run reads every second master sample; at dt = 0.04,
% every fourth. So every timestep setting meets the SAME realization in
% physical time, which is what makes the dt diagnostic interpretable.
%
% Two things this deliberately does NOT do:
%
%   - it does not generate noise per outer step independently for each dt,
%     which would give each dt its own realization and confound the
%     comparison with a different random draw
%   - it does not draw at trigger instants, which would let a policy that
%     transmits more often consume the stream faster and meet a different
%     realization than a quieter one
%
% Components 1:3 are position noise, 4:6 velocity noise.

baseDt = 0.01;

N = cfg.swarm.N;

T = cfg.swarm.T;

nSample = ceil(T / baseDt) + 2;

trace.baseDt    = baseDt;
trace.nSample   = nSample;
trace.posSigma  = posSigma;
trace.velSigma  = velSigma;

if posSigma <= 0 && velSigma <= 0

    trace.n         = zeros(nSample, N, 6);
    trace.hash      = 0;
    trace.hashExact = 0;

    return;

end

stream = RandStream('mt19937ar', ...
    'Seed', mod(cfg.net.seed + 80240001, 2^32));

n = zeros(nSample, N, 6);

w = randn(stream, nSample, N, 6);

n(:,:,1:3) = posSigma * w(:,:,1:3);
n(:,:,4:6) = velSigma * w(:,:,4:6);

% The leader is a kinematic reference in EXP09C and is left noise-free.
% This is a scope choice, recorded here so it cannot be mistaken for an
% oversight when reading the trace.
n(:,1,:) = 0;

trace.n = n;

% LOCKED hash, unchanged: its values appear in the EXP09C result table.
% Not thread-stable, for the same reason as the trace generators.
trace.hash = mod(sum(abs(n(:)) .* (1:numel(n))'), 2^52);

% EXACT hash for EXP10; order-independent and CSV-safe.
trace.hashExact = realizationHash(n(:));

end
