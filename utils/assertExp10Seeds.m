function report = assertExp10Seeds(exp10Seeds, verbose)
%ASSERTEXP10SEEDS Prove the EXP10 seed block is a genuine holdout.
%
%   report = assertExp10Seeds(exp10Seeds)
%   report = assertExp10Seeds(exp10Seeds, false)
%
% Three checks, run BEFORE any EXP10 simulation. The first two are
% blockers: a EXP10 seed that was used during development is not holdout
% evidence about the protocol that was developed against it.
%
%   1  BLOCKER   no EXP10 base seed appears in any EXP01-EXP09 family
%   2  BLOCKER   no two EXP10 trace types share a stream seed, i.e. the
%                six master realizations of a seed are independent draws
%                and not shifted copies of one another
%   3  REPORTED  whether any EXP10 stream seed coincides with a locked
%                experiment's stream seed OF A DIFFERENT TRACE TYPE
%
% Check 3 is reported rather than gated on purpose. If EXP10's reverse-
% channel stream happens to land on the same MT19937 seed that some
% locked experiment used for its link-fault permutation, the two consume
% unrelated draws in unrelated experiments and nothing in EXP10 is
% compared against that experiment's realization, so the coincidence
% carries no consequence. A coincidence of the SAME trace type would be
% different - it would mean EXP10 met a development realization - and
% that is what check 1 forbids at the root, since a same-type
% coincidence requires an equal base seed.

if nargin < 2 || isempty(verbose)
    verbose = true;
end

exp10Seeds = exp10Seeds(:);

fam = exp10SeedFamilies();

offNames = fieldnames(fam.offsets);

report.exp10Seeds = exp10Seeds';
report.nSeeds     = numel(exp10Seeds);


%% ============================================================
% 1  Base-seed disjointness
% ============================================================

collide = intersect(exp10Seeds, fam.all);

report.baseCollisions = collide(:)';
report.baseDisjoint   = isempty(collide);

report.perFamilyCollisions = zeros(1, numel(fam.names));

for f = 1:numel(fam.names)
    report.perFamilyCollisions(f) = ...
        numel(intersect(exp10Seeds, fam.seeds{f}));
end


%% ============================================================
% 2  Independence of the six master realizations within EXP10
% ============================================================

streamSeed = struct();

for o = 1:numel(offNames)
    streamSeed.(offNames{o}) = ...
        mod(exp10Seeds + fam.offsets.(offNames{o}), 2^32);
end

report.internalCollisions = {};

for o1 = 1:numel(offNames)
    for o2 = (o1+1):numel(offNames)

        a = streamSeed.(offNames{o1});
        b = streamSeed.(offNames{o2});

        shared = intersect(a, b);

        if ~isempty(shared)
            report.internalCollisions{end+1} = ...
                sprintf('%s vs %s: %d shared stream seed(s)', ...
                    offNames{o1}, offNames{o2}, numel(shared));
        end

    end
end

report.internalIndependent = isempty(report.internalCollisions);


%% ============================================================
% 3  Cross-experiment, cross-type stream coincidences (reported)
% ============================================================

historicalStreams = [];

for o = 1:numel(offNames)
    historicalStreams = [historicalStreams, ...
        mod(fam.all + fam.offsets.(offNames{o}), 2^32)];   %#ok<AGROW>
end

historicalStreams = unique(historicalStreams);

report.crossTypeCoincidences = 0;
report.crossTypeDetail = {};

for o = 1:numel(offNames)

    mine = streamSeed.(offNames{o});

    shared = intersect(mine, historicalStreams);

    if ~isempty(shared)
        report.crossTypeCoincidences = ...
            report.crossTypeCoincidences + numel(shared);
        report.crossTypeDetail{end+1} = ...
            sprintf('%s: %d stream seed(s) coincide with a locked stream', ...
                offNames{o}, numel(shared));
    end

end


%% ============================================================
% Verdict
% ============================================================

report.pass = report.baseDisjoint && report.internalIndependent;

if verbose

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('EXP10 holdout seed assertion\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('  EXP10 block          : %d..%d (%d seeds)\n', ...
        min(exp10Seeds), max(exp10Seeds), numel(exp10Seeds));
    fprintf('  EXP01-09 seed values : %d enumerated across %d families\n', ...
        numel(fam.all), numel(fam.names));

    if report.baseDisjoint
        fprintf('  [PASS ] no EXP10 seed appears in any development family\n');
    else
        fprintf('  [FAIL ] %d EXP10 seed(s) collide: %s\n', ...
            numel(report.baseCollisions), mat2str(report.baseCollisions));
    end

    if report.internalIndependent
        fprintf('  [PASS ] the six master realizations are independent streams\n');
    else
        fprintf('  [FAIL ] %s\n', strjoin(report.internalCollisions, '; '));
    end

    fprintf('  [INFO ] %d cross-experiment cross-type stream coincidence(s)', ...
        report.crossTypeCoincidences);

    if report.crossTypeCoincidences == 0
        fprintf('\n');
    else
        fprintf(' -- harmless, see assertExp10Seeds header\n');
        for d = 1:numel(report.crossTypeDetail)
            fprintf('           %s\n', report.crossTypeDetail{d});
        end
    end

end

if ~report.pass
    error('assertExp10Seeds:notHoldout', ...
        'EXP10 seed block failed the holdout assertion. Nothing was run.');
end

end
