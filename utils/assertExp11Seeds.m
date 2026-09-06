function report = assertExp11Seeds(exp11Seeds, verbose)
%ASSERTEXP11SEEDS Prove the EXP11 seed block is a genuine holdout.
%
%   report = assertExp11Seeds(exp11Seeds)
%   report = assertExp11Seeds(exp11Seeds, false)
%
% Same three checks as assertExp10Seeds, run BEFORE any EXP11 simulation,
% but against exp11SeedFamilies - which additionally contains the EXP10
% holdout block. EXP11 must be disjoint from the validation campaign as
% well as from development, otherwise it would be re-testing on seeds whose
% realisations already shaped the frozen claims.
%
%   1  BLOCKER   no EXP11 base seed appears in any EXP01-EXP10 family
%   2  BLOCKER   no two EXP11 trace types share a stream seed
%   3  REPORTED  cross-experiment coincidences of DIFFERENT trace types
%
% Check 3 stays reported for the reason given in assertExp10Seeds: two
% unrelated generators landing on the same MT19937 seed in unrelated
% experiments have no consequence, and a same-type coincidence is already
% impossible once check 1 holds.

if nargin < 2 || isempty(verbose)
    verbose = true;
end

exp11Seeds = exp11Seeds(:);

fam = exp11SeedFamilies();

offNames = fieldnames(fam.offsets);

report.exp11Seeds = exp11Seeds';
report.nSeeds     = numel(exp11Seeds);


%% ============================================================
% 1  Base-seed disjointness, including against EXP10
% ============================================================

collide = intersect(exp11Seeds, fam.all);

report.baseCollisions = collide(:)';
report.baseDisjoint   = isempty(collide);

report.perFamilyCollisions = zeros(1, numel(fam.names));

for f = 1:numel(fam.names)
    report.perFamilyCollisions(f) = ...
        numel(intersect(exp11Seeds, fam.seeds{f}));
end


%% ============================================================
% 2  Independence of the master realizations within EXP11
% ============================================================

streamSeed = struct();

for o = 1:numel(offNames)
    streamSeed.(offNames{o}) = ...
        mod(exp11Seeds + fam.offsets.(offNames{o}), 2^32);
end

report.internalCollisions = {};

for o1 = 1:numel(offNames)
    for o2 = (o1+1):numel(offNames)

        shared = intersect( ...
            streamSeed.(offNames{o1}), ...
            streamSeed.(offNames{o2}));

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

    shared = intersect(streamSeed.(offNames{o}), historicalStreams);

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
    fprintf('EXP11 holdout seed assertion\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('  EXP11 block          : %d..%d (%d seeds)\n', ...
        min(exp11Seeds), max(exp11Seeds), numel(exp11Seeds));
    fprintf('  EXP01-10 seed values : %d enumerated across %d families\n', ...
        numel(fam.all), numel(fam.names));

    if report.baseDisjoint
        fprintf('  [PASS ] no EXP11 seed appears in any prior family\n');
    else
        fprintf('  [FAIL ] %d EXP11 seed(s) collide: %s\n', ...
            numel(report.baseCollisions), mat2str(report.baseCollisions));
    end

    if report.internalIndependent
        fprintf('  [PASS ] the master realizations are independent streams\n');
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
    error('assertExp11Seeds:notHoldout', ...
        'EXP11 seed block failed the holdout assertion. Nothing was run.');
end

end
