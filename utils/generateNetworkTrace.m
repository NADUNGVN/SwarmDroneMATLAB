function trace = generateNetworkTrace(cfg)
%GENERATENETWORKTRACE Pre-draw one network realisation, shared by all methods.
%
%   trace = generateNetworkTrace(cfg)
%
% Sharing a seed is NOT the same as sharing a realisation. Each policy calls
% rand a different number of times, so identical seeds desynchronise on the
% first transmission and the runs stop being paired. Seeds buy
% reproducibility; they do not buy common random numbers.
%
% This draws the channel outcome for every (link, timestep) IN ADVANCE, as a
% pure function of the seed, the swarm size and the horizon. Nothing about
% any policy enters. A method then consumes trace(i,j,k) at the instant it
% transmits, so two methods transmitting on the same link at the same
% timestep meet exactly the same channel, and a method that stays silent
% consumes nothing and disturbs nothing.
%
% The trace is regenerated inside each worker from the seed rather than
% broadcast, so parfor pays no communication cost even at N = 50.
%
% Fields (all K x N x N, or K x N for the leader links):
%
%   lossU        uniform draw; the packet is dropped when lossU < packetLoss
%   jitterZ      standard normal draw for delay jitter
%   leaderLossU  same, for the pinned leader links
%   leaderJitterZ
%
% Indexing convention matches the rest of the project: (i, j) is the link
% carrying data from transmitter j to receiver i.

N = cfg.swarm.N;

K = numel(0:cfg.swarm.dt:cfg.swarm.T);


%% ============================================================
% Dedicated stream
%
% Separate from the simulation's own rng() so that adding or removing
% a trace never perturbs anything else that draws randomness.
% ============================================================

seed = mod(cfg.net.seed + 20240001, 2^32);

stream = RandStream('mt19937ar', 'Seed', seed);


trace.lossU   = rand(stream, K, N, N);
trace.jitterZ = randn(stream, K, N, N);

trace.leaderLossU   = rand(stream, K, N);
trace.leaderJitterZ = randn(stream, K, N);


%% ============================================================
% Provenance
%
% The hash lets an experiment prove every method ran on the same
% realisation rather than merely asserting it.
% ============================================================

trace.seed = cfg.net.seed;
trace.N    = N;
trace.K    = K;

trace.hash = localHash([ ...
    trace.lossU(:); ...
    trace.jitterZ(:); ...
    trace.leaderLossU(:); ...
    trace.leaderJitterZ(:)]);

end


%% ============================================================
% LOCAL FUNCTION
%
% Cheap order-sensitive checksum. Not cryptographic; it only has to
% detect that two runs used different realisations.
% ============================================================

function h = localHash(v)

n = numel(v);

idx = (1:n)';

h = mod(sum(mod(floor(abs(v)*1e12), 1e9) .* mod(idx,9973)), 2^53 - 1);

end
