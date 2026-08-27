function trace = generateAckTrace(cfg)
%GENERATEACKTRACE Pre-draw the reverse-channel realisation.
%
%   trace = generateAckTrace(cfg)
%
% The forward trace (generateNetworkTrace) gives every method the same DATA
% channel. This does the same for the ACK path, which matters for a
% different reason: EXP07B sweeps ACK loss, delay and jitter, and without a
% pre-drawn reverse realisation each cell would draw a different sequence
% from the shared stream. Differences between cells would then mix the
% impairment being studied with the luck of the draw.
%
% CRITICAL PROPERTY: this depends only on the seed, the swarm size and the
% horizon. It does NOT depend on cfg.ack.loss, cfg.ack.delay or
% cfg.ack.jitterStd. One scenario and seed therefore yield one reverse
% realisation shared by every impairment cell, which is what makes the cells
% comparable. tests/test_lock_regression checks this by hashing the trace
% across cells.
%
% Indexing is (receiver timestep, i, j) for the reverse link carrying an
% acknowledgement from receiver i back to transmitter j, matching the (i,j)
% convention used for the forward link everywhere else.
%
% Fields:
%
%   lossU          uniform draw; the ACK is dropped when lossU < cfg.ack.loss
%   jitterZ        standard normal draw for reverse-path jitter
%   leaderLossU    same, for acknowledgements on the pinned leader links
%   leaderJitterZ
%
% A receiver decides once per sampling tick, and cumulative ACK semantics
% mean at most one acknowledgement per link per tick. One slot per
% (tick, link) is therefore the right granularity: if delivery runs twice
% within a tick, both reads land on the same slot, which is the same
% physical channel opportunity.

N = cfg.swarm.N;

% Trace length. By default one slot per outer step, exactly as every
% locked experiment has used it. With cfg.net.traceBaseDt set, the trace
% lives on a master physical-time grid instead, so runs at different
% outer dt meet the same channel realization at the same instant.
if isfield(cfg,'net') && isfield(cfg.net,'traceBaseDt') ...
        && ~isempty(cfg.net.traceBaseDt) && cfg.net.traceBaseDt > 0
    K = numel(0:cfg.net.traceBaseDt:cfg.swarm.T) + 1;
else
    K = numel(0:cfg.swarm.dt:cfg.swarm.T);
end


%% ============================================================
% Dedicated stream
%
% Offset distinct from the forward trace so the two realisations are
% independent rather than shifted copies of one another.
% ============================================================

seed = mod(cfg.net.seed + 30240001, 2^32);

stream = RandStream('mt19937ar', 'Seed', seed);


trace.lossU   = rand(stream, K, N, N);
trace.jitterZ = randn(stream, K, N, N);

trace.leaderLossU   = rand(stream, K, N);
trace.leaderJitterZ = randn(stream, K, N);


%% ============================================================
% Provenance
% ============================================================

trace.seed = cfg.net.seed;
trace.N    = N;
trace.K    = K;

flat = [ ...
    trace.lossU(:); ...
    trace.jitterZ(:); ...
    trace.leaderLossU(:); ...
    trace.leaderJitterZ(:)];

% LOCKED hash, unchanged; not thread-stable. See generateNetworkTrace.
trace.hash = localHash(flat);

% EXACT hash for EXP10; order-independent and CSV-safe.
trace.hashExact = realizationHash(flat);

end


%% ============================================================
% LOCAL FUNCTION
%
% Cheap order-sensitive checksum. Not cryptographic; it only has to
% detect that two runs used different realisations.
%
% NOT thread-stable, and deliberately unchanged.
% ============================================================

function h = localHash(v)

n = numel(v);

idx = (1:n)';

h = mod(sum(mod(floor(abs(v)*1e12), 1e9) .* mod(idx,9973)), 2^53 - 1);

end
