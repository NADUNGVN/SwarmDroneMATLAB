function report = paper_guard(verbose)
%PAPER_GUARD Prove the paper branch has not touched frozen simulation source.
%
%   report = paper_guard()
%
% simulation-v1.0 is frozen. The paper package reads frozen results and
% writes only into paper/generated, paper/figures and paper/tables. This
% checks that claim against git rather than trusting it, and it is a
% BLOCKER for the audit: a figure that required editing a simulator is not
% a figure about the frozen campaign.
%
% READ-ONLY, ENFORCED BY DIFF
%
%   simulation/  network/  controllers/  swarm/  models/  experiments/
%   metrics/     configs/  utils/        tests/
%
% The last four are not in the batch instruction's list but belong there
% for the same reason: utils/ holds the CRN generators and the hash
% functions, metrics/ computes RMSE and minimum separation, configs/ holds
% every locked parameter, and tests/ is what proves the locked values
% still reproduce. A paper-branch edit to any of them would change what
% the numbers mean just as surely as an edit to a simulator.
%
% WRITABLE
%
%   paper/**  docs/**  results/**  (results only by an experiment, which
%                                   the paper package never runs)
%
% If a table or figure appears to need a change under a read-only path,
% that is a STOP condition, not something to slip in here: it means the
% frozen artefact does not contain what the manuscript wants to say, and
% the honest responses are to change the manuscript or to re-open the
% freeze deliberately.

if nargin < 1 || isempty(verbose)
    verbose = true;
end

root = projectRoot();

frozenRef = 'simulation-v1.0';

readOnly = { ...
    'simulation/', 'network/', 'controllers/', 'swarm/', 'models/', ...
    'experiments/', 'metrics/', 'configs/', 'utils/', 'tests/', ...
    'run_all.m', 'startup.m'};

report.frozenRef = frozenRef;
report.readOnly  = readOnly;


%% ============================================================
% Does the frozen reference exist?
% ============================================================

[st, ~] = system(sprintf('git -C "%s" rev-parse --verify --quiet %s', ...
    root, frozenRef));

report.refExists = (st == 0);

if ~report.refExists
    report.pass = false;
    report.violations = {sprintf('the frozen reference %s does not exist', frozenRef)};
    if verbose
        fprintf('  [FAIL ] frozen reference %s not found\n', frozenRef);
    end
    return;
end


%% ============================================================
% What has changed since the freeze?
% ============================================================

[~, out] = system(sprintf('git -C "%s" diff --name-only %s HEAD', ...
    root, frozenRef));

changed = localSplitLines(out);

% Uncommitted work counts too: a figure generated from an edited
% simulator is no better for the edit being unstaged.
[~, out2] = system(sprintf('git -C "%s" status --porcelain', root));

dirty = {};

lines = localSplitLines(out2);

for k = 1:numel(lines)

    ln = lines{k};

    if numel(ln) > 3
        dirty{end+1} = strtrim(ln(4:end));   %#ok<AGROW>
    end

end

allTouched = unique([changed(:)', dirty(:)']);

report.changedSinceFreeze = allTouched;


%% ============================================================
% Violations
% ============================================================

violations = {};

for k = 1:numel(allTouched)

    f = strrep(allTouched{k}, '\', '/');

    if isempty(f)
        continue;
    end

    for r = 1:numel(readOnly)

        pat = readOnly{r};

        if endsWith(pat, '/')
            hit = startsWith(f, pat);
        else
            hit = strcmp(f, pat);
        end

        if hit
            violations{end+1} = f;   %#ok<AGROW>
            break;
        end
    end

end

report.violations = unique(violations);

report.pass = isempty(report.violations);


%% ============================================================
% Report
% ============================================================

if verbose

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('paper_guard: frozen simulation source\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('  frozen reference : %s\n', frozenRef);
    fprintf('  paths touched since the freeze : %d\n', numel(allTouched));

    if report.pass

        fprintf('  [PASS ] no read-only path was modified\n');

    else

        fprintf('  [FAIL ] %d read-only path(s) modified:\n', ...
            numel(report.violations));

        for k = 1:numel(report.violations)
            fprintf('           %s\n', report.violations{k});
        end

        fprintf(['\n  This is a STOP condition. A paper-branch edit under ' ...
                 'these paths\n  changes what the frozen numbers mean.\n']);

    end

end

end


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function c = localSplitLines(s)

s = strtrim(s);

if isempty(s)
    c = {};
    return;
end

c = strsplit(s, {sprintf('\n'), sprintf('\r')});

c = c(~cellfun(@isempty, c));

end
