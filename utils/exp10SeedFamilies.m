function fam = exp10SeedFamilies()
%EXP10SEEDFAMILIES Every cfg.net.seed value EXP01-EXP09 ever used.
%
%   fam = exp10SeedFamilies()
%
% EXP10 is a HOLDOUT validation: it must not re-use a development seed,
% because a seed that was seen while the protocol was being designed is
% not independent evidence about it. Plan section 2 requires that to be
% an automated assertion rather than an inspection, and this function is
% the enumeration that assertion runs against.
%
% Each family is transcribed from the seed expression in the experiment
% script itself, with the index ranges taken GENEROUSLY - wider than the
% loops that actually ran. Over-enumeration only makes the disjointness
% test stricter, so an error here can make the test fail spuriously but
% cannot let a real collision through.
%
% Returns:
%   fam.names    family label per entry
%   fam.seeds    cell array of the seed values in each family
%   fam.all      the union, sorted unique
%   fam.offsets  the dedicated per-trace-type stream offsets, so a
%                caller can check derived streams as well as base seeds

names = {};
seeds = {};

sMax = 40;      % no locked experiment ran more than 20 seeds
iMax = 10;      % generous bound on every sweep index

% ---- defaultConfig, and anything that never overrode it ----
names{end+1} = 'defaultConfig';
seeds{end+1} = 1001;

% ---- EXP03A: 1000 + s ----
names{end+1} = 'exp03a_packet_loss';
seeds{end+1} = localGrid(1000, {}, 1, sMax);

% ---- EXP03C: 100000 + 1000*iL + 100*iD + s ----
names{end+1} = 'exp03c_loss_delay';
seeds{end+1} = localGrid(100000, {1000*(1:iMax), 100*(1:iMax)}, 1, sMax);

% ---- EXP03D: 200000 + 1000*iJ + s ----
names{end+1} = 'exp03d_jitter';
seeds{end+1} = localGrid(200000, {1000*(1:iMax)}, 1, sMax);

% ---- EXP04B: 300000 + 10000*iR + 1000*iL + 100*iD + s ----
names{end+1} = 'exp04b_rate_impairment';
seeds{end+1} = localGrid(300000, ...
    {10000*(1:iMax), 1000*(1:iMax), 100*(1:iMax)}, 1, sMax);

% ---- EXP05B: 800000 + 10000*iS + s ----
names{end+1} = 'exp05b_aoi_aware';
seeds{end+1} = localGrid(800000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP05C: 900000 + 10000*iS + s ----
names{end+1} = 'exp05c_ablation';
seeds{end+1} = localGrid(900000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP06A: 1100000 + 100000*iS + 10000*iN + s ----
names{end+1} = 'exp06a_scalability';
seeds{end+1} = localGrid(1100000, {100000*(1:iMax), 10000*(1:iMax)}, 1, sMax);

% ---- EXP05D: 1200000 + 10000*iS + s ----
names{end+1} = 'exp05d_pareto_frontier';
seeds{end+1} = localGrid(1200000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP07A: 1400000 + 10000*iS + s ----
names{end+1} = 'exp07a_causal_ack';
seeds{end+1} = localGrid(1400000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP07B: 1500000 + 10000*iS + s ----
names{end+1} = 'exp07b_ack_impairment';
seeds{end+1} = localGrid(1500000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP07C: 1600000 + 10000*iS + s ----
names{end+1} = 'exp07c_cost_model';
seeds{end+1} = localGrid(1600000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP08A and EXP08A-D:
%      1700000 + 100000*iS + 10000*iN + 1000*iT + s ----
names{end+1} = 'exp08a_topology / exp08ad_normalization';
seeds{end+1} = localGrid(1700000, ...
    {100000*(1:iMax), 10000*(1:iMax), 1000*(1:iMax)}, 1, sMax);

% ---- EXP08B: 1800000 + 10000*iS + 1000*iT + s ----
names{end+1} = 'exp08b_link_failure';
seeds{end+1} = localGrid(1800000, {10000*(1:iMax), 1000*(1:iMax)}, 1, sMax);

% ---- EXP08C: 2800000 + 100000*iN + 1000*iT + s ----
names{end+1} = 'exp08c_node_blackout';
seeds{end+1} = localGrid(2800000, {100000*(1:iMax), 1000*(1:iMax)}, 1, sMax);

% ---- EXP09A: 3900000 + 10000*iS + s ----
names{end+1} = 'exp09a_multiuav_6dof';
seeds{end+1} = localGrid(3900000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP09A N=10 secondary: 3910000 + 10000*iS + s ----
names{end+1} = 'exp09a_n10_secondary';
seeds{end+1} = localGrid(3910000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP09B: 4900000 + 10000*iS + s ----
names{end+1} = 'exp09b_physical_mismatch';
seeds{end+1} = localGrid(4900000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP09C: 5900000 + 10000*iS + s ----
names{end+1} = 'exp09c_synthetic_estimator';
seeds{end+1} = localGrid(5900000, {10000*(1:iMax)}, 1, sMax);

% ---- EXP09C timestep diagnostic: 6900000 + 10000*iS + s ----
names{end+1} = 'exp09c_timestep_diagnostic';
seeds{end+1} = localGrid(6900000, {10000*(1:iMax)}, 1, sMax);


fam.names = names;
fam.seeds = seeds;

allSeeds = [];

for k = 1:numel(seeds)
    allSeeds = [allSeeds, seeds{k}(:)'];   %#ok<AGROW>
end

fam.all = unique(allSeeds);


%% ============================================================
% Dedicated per-trace-type stream offsets
%
% Transcribed from the generators. A stream seed is
% mod(cfg.net.seed + offset, 2^32).
% ============================================================

fam.offsets = struct( ...
    'forward',   20240001, ...
    'ack',       30240001, ...
    'link',      50240001, ...
    'blackout',  60240001, ...
    'extForce',  70240001, ...
    'noise',     80240001, ...
    'phase',     90240001);

end


%% ============================================================
% LOCAL FUNCTION
%
% Cartesian sum of a base, a set of index-term vectors and sMin:sMax.
% ============================================================

function v = localGrid(base, terms, sMin, sMax)

v = base;

for k = 1:numel(terms)

    tk = terms{k};

    v = reshape(v(:) + tk(:)', 1, []);

end

v = reshape(v(:) + (sMin:sMax), 1, []);

v = unique(v);

end
