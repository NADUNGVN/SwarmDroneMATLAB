function fam = exp11SeedFamilies()
%EXP11SEEDFAMILIES Every cfg.net.seed value EXP01-EXP10 ever used.
%
%   fam = exp11SeedFamilies()
%
% EXP11 is the one experiment authorised after the simulation-v1.0 freeze,
% and it must be a holdout in exactly the same sense EXP10 was: no seed it
% runs on may have been seen while the protocol was being built, and that
% includes the EXP10 holdout block itself. A seed used in the validation
% campaign is no longer unseen.
%
% This wraps exp10SeedFamilies rather than restating it. exp10SeedFamilies
% is a frozen-path file that produced locked results and is not edited; the
% EXP10 block is appended here, where the addition can be read as an
% addition. Everything else - the offsets, the localGrid convention, the
% generous index bounds - is inherited unchanged, so the two enumerations
% cannot drift apart.

fam = exp10SeedFamilies();


%% ============================================================
% The EXP10 holdout block
%
% Pre-registered as 25000001:25000050 and used verbatim as cfg.net.seed,
% with no scenario or topology index folded in. Enumerated to 25000100 -
% twice what ran - on the same principle as every other family here: over-
% enumeration can only make the disjointness test stricter, never laxer.
%
% The EXP10A smoke-debug hook drew its three seeds from inside this block,
% so it needs no separate entry.
% ============================================================

fam.names{end+1} = 'exp10_holdout_validation';
fam.seeds{end+1} = 25000001:25000100;

allSeeds = [];

for k = 1:numel(fam.seeds)
    allSeeds = [allSeeds, fam.seeds{k}(:)'];   %#ok<AGROW>
end

fam.all = unique(allSeeds);

end
