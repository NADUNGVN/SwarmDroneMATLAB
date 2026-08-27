%% RUN_CLEAN_CLONE_CHECK - reproduce the freeze from a fresh clone
%
% Clones the repository at its current HEAD into a temporary directory and
% reproduces the claim set there, in a MATLAB process that has never seen
% the working copy. That is the difference between "it runs here" and "it
% reproduces": a check run inside the working tree cannot detect an
% uncommitted file that the result silently depends on.
%
% In the clone:
%
%   1  the full test suite, including test_lock_regression
%   2  EXP10B rebuilt from the PERSISTED tidy files, since results/*.mat
%      and *.fig are not in version control but console.log, tidy.csv,
%      meta.json and the PNGs are
%   3  one EXP10A smoke seed, re-simulated from scratch
%
% Then, back here:
%
%   4  the clone's unified matrix must equal this one exactly - EXP10B is
%      a deterministic function of the dataset, so any difference means
%      the two ran different code or different data
%   5  the clone's freshly simulated seed must reproduce this dataset's
%      rows for that seed, metrics and realization hashes alike
%
% USAGE
%
%   run_clean_clone_check
%
%   v1CloneSeed = 25000007; run_clean_clone_check     % a different seed
%
% Requires the EXP10A dataset and the EXP10B unified matrix to be
% COMMITTED. A clone cannot see uncommitted results, and step 2 failing
% with a missing dataset usually means exactly that.
%
% ============================================================

startup;


%% ============================================================
% Setup
% ============================================================

root = projectRoot();

[~, shaOut] = system(sprintf('git -C "%s" rev-parse HEAD', root));

headSha = strtrim(shaOut);

[~, dirtyOut] = system(sprintf('git -C "%s" status --porcelain', root));

workingTreeClean = isempty(strtrim(dirtyOut));

if evalin('base','exist(''v1CloneSeed'',''var'')')
    cloneSeed = evalin('base','v1CloneSeed');
else
    cloneSeed = 25000001;
end

cloneDir = fullfile(tempdir, sprintf('swarm_clean_clone_%s', headSha(1:8)));

fprintf('\n');
fprintf('############################################################\n');
fprintf('# CLEAN-CLONE REPRODUCTION CHECK\n');
fprintf('############################################################\n\n');

fprintf('  source        : %s\n', root);
fprintf('  HEAD          : %s\n', headSha);
fprintf('  working tree  : %s\n', localCleanWord(workingTreeClean));
fprintf('  clone         : %s\n', cloneDir);
fprintf('  smoke seed    : %d\n', cloneSeed);

if ~workingTreeClean
    fprintf(2, ['\n  WARNING: the working tree has uncommitted changes. ' ...
        'The clone reproduces HEAD, so anything uncommitted is NOT ' ...
        'under test here.\n']);
end

problems = {};


%% ============================================================
% Clone
% ============================================================

if exist(cloneDir,'dir')
    fprintf('\n  removing a previous clone...\n');
    rmdir(cloneDir, 's');
end

fprintf('\n  cloning...\n');

[st, out] = system(sprintf('git clone --quiet --no-hardlinks "%s" "%s"', ...
    root, cloneDir));

if st ~= 0
    error('cleanClone:cloneFailed', 'git clone failed: %s', out);
end

[st, out] = system(sprintf('git -C "%s" checkout --quiet %s', cloneDir, headSha));

if st ~= 0
    error('cleanClone:checkoutFailed', 'git checkout failed: %s', out);
end

[~, cloneShaOut] = system(sprintf('git -C "%s" rev-parse HEAD', cloneDir));

fprintf('  clone HEAD    : %s\n', strtrim(cloneShaOut));


%% ============================================================
% Run the suite, the rebuild and one seed inside the clone
%
% restoredefaultpath first, so nothing on this session's path can leak
% into the clone's process and make the reproduction look better than it
% is.
% ============================================================

logFile = fullfile(cloneDir, 'clean_clone_run.log');

% Each of the three stages is wrapped, so a failure in one still leaves
% the other two to report. Without that, a test failure aborts -batch and
% the clone tells you nothing about whether the dataset reproduces - which
% is the more interesting question when a test is what broke.
%
% Every stage goes through runScriptIsolated for the same reason the
% validation entry point does: these are scripts, and letting them share
% one workspace is how the test suite once aborted after its seventh file
% without saying so.
cmd = sprintf([ ...
    'restoredefaultpath; cd(''%s''); startup; ' ...
    'try, runScriptIsolated(''run_all_tests''); ' ...
    'catch e, fprintf(2,''CLONE STAGE FAILED tests: %%s\\n'', e.message); end; ' ...
    'try, runScriptIsolated(''exp10b_unified_matrix''); ' ...
    'catch e, fprintf(2,''CLONE STAGE FAILED rebuild: %%s\\n'', e.message); end; ' ...
    'try, exp10SmokeSeeds = %d; ' ...
    'runScriptIsolated(''exp10a_final_validation''); ' ...
    'catch e, fprintf(2,''CLONE STAGE FAILED smoke: %%s\\n'', e.message); end;'], ...
    strrep(cloneDir,'\','\\'), cloneSeed);

matlabExe = fullfile(matlabroot,'bin','matlab');

fullCmd = sprintf('"%s" -batch "%s" > "%s" 2>&1', matlabExe, cmd, logFile);

fprintf('\n  running the clone (test suite, rebuild, one seed)...\n');

tClone = tic;

[stRun, ~] = system(fullCmd);

fprintf('  clone finished in %.1f min, exit status %d\n', ...
    toc(tClone)/60, stRun);

if stRun ~= 0

    problems{end+1} = sprintf('the clone run exited with status %d', stRun);

    if exist(logFile,'file') == 2
        txt = fileread(logFile);
        lines = strsplit(txt, newline);
        fprintf(2, '\n  last 25 lines of the clone log:\n');
        for k = max(1,numel(lines)-24):numel(lines)
            fprintf(2, '    %s\n', lines{k});
        end
    end

end


%% ============================================================
% CHECK 4 - the rebuilt unified matrix must be identical
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('unified matrix, rebuilt in the clone versus here\n');
fprintf('------------------------------------------------------------\n\n');

mineB  = localLatestTidy(root,     'exp10b_unified_matrix');
theirB = localLatestTidy(cloneDir, 'exp10b_unified_matrix');

matrixSame = false;

if isempty(mineB) || isempty(theirB)

    problems{end+1} = 'a unified matrix is missing on one side';
    fprintf('  MISSING: mine %s, clone %s\n', ...
        localHave(mineB), localHave(theirB));

else

    A = readtable(mineB,  'TextType','char');
    B = readtable(theirB, 'TextType','char');

    [matrixSame, detail] = localCompareTables(A, B);

    fprintf('  rows        : %d here, %d in the clone\n', height(A), height(B));
    fprintf('  identical   : %s\n', localYesNo(matrixSame));

    if ~matrixSame
        problems{end+1} = 'the rebuilt unified matrix differs';
        for k = 1:min(10,numel(detail))
            fprintf(2, '    %s\n', detail{k});
        end
    end

end


%% ============================================================
% CHECK 5 - the freshly simulated seed must reproduce the dataset
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('seed %d, re-simulated in the clone versus the dataset here\n', cloneSeed);
fprintf('------------------------------------------------------------\n\n');

mineA  = localDatasetTidy(root, cloneSeed);
theirA = localLatestTidy(cloneDir, 'exp10a_final_validation');

seedSame = false;

if isempty(mineA) || isempty(theirA)

    problems{end+1} = 'the EXP10A dataset is missing on one side';
    fprintf('  MISSING: mine %s, clone %s\n', ...
        localHave(mineA), localHave(theirA));

else

    DA = readtable(mineA,  'TextType','char');
    DB = readtable(theirA, 'TextType','char');

    DA = DA(DA.seed == cloneSeed, :);
    DB = DB(DB.seed == cloneSeed, :);

    key = @(T) strcat(T.point, '|', T.scenario, '|', T.method);

    DA = sortrows(DA, {'point','scenario','method'});
    DB = sortrows(DB, {'point','scenario','method'});

    cols = {'RMSE','MINSEP','SAFEFAIL','DIVERGED','DATACOUNT','ACKCOUNT', ...
            'BCASTCOUNT','FWDHASH','ACKHASH','PHASEHASH','FAULTHASH', ...
            'BLACKHASH','EXTHASH','NOISEHASH','INVARIANTS'};

    fprintf('  rows for this seed : %d here, %d in the clone\n', ...
        height(DA), height(DB));

    if height(DA) ~= height(DB) || ~isequal(key(DA), key(DB))

        problems{end+1} = 'the seed produced a different set of cells';
        fprintf(2, '    cell sets differ\n');

    else

        bad = {};

        for k = 1:numel(cols)

            a = DA.(cols{k});
            b = DB.(cols{k});

            if ~isequaln(a, b)
                d = find(~( (a == b) | (isnan(a) & isnan(b)) ));
                bad{end+1} = sprintf('%s differs in %d of %d rows', ...
                    cols{k}, numel(d), height(DA));                 %#ok<AGROW>
            end

        end

        seedSame = isempty(bad);

        fprintf('  bit-identical      : %s\n', localYesNo(seedSame));

        if ~seedSame
            problems{end+1} = 'the re-simulated seed does not reproduce';
            for k = 1:numel(bad)
                fprintf(2, '    %s\n', bad{k});
            end
        end

    end

end


%% ============================================================
% Test suite verdict inside the clone
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('test suite inside the clone\n');
fprintf('------------------------------------------------------------\n\n');

cloneTestsPassed = false;

if exist(logFile,'file') == 2

    txt = fileread(logFile);

    cloneTestsPassed = contains(txt, 'TEST SUITE: ALL PASS');

    fprintf('  TEST SUITE: ALL PASS found in the clone log : %s\n', ...
        localYesNo(cloneTestsPassed));

    if contains(txt, 'test_lock_regression: PASS')
        fprintf('  test_lock_regression: PASS\n');
    else
        fprintf(2, '  test_lock_regression did NOT report PASS\n');
    end

end

if ~cloneTestsPassed
    problems{end+1} = 'the test suite did not pass in the clone';
end


%% ============================================================
% Verdict
% ============================================================

cloneOk = isempty(problems);

fprintf('\n');
fprintf('############################################################\n');
fprintf('# CLEAN-CLONE CHECK: %s\n', localPassFail(cloneOk));
fprintf('############################################################\n\n');

if cloneOk

    fprintf('  A fresh clone of %s reproduces:\n', headSha(1:8));
    fprintf('    - the whole test suite\n');
    fprintf('    - the unified matrix, rebuilt from persisted tidy files\n');
    fprintf('    - seed %d, re-simulated bit-identically\n', cloneSeed);

else

    for k = 1:numel(problems)
        fprintf('  - %s\n', problems{k});
    end

end

fprintf('\n  clone log : %s\n', logFile);
fprintf('  clone dir : %s  (left in place for inspection)\n', cloneDir);


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function f = localLatestTidy(rootDir, expName)
%LOCALLATESTTIDY Path to the LATEST tidy.csv of an experiment, or ''.

f = '';

latest = fullfile(rootDir, 'results', expName, 'LATEST.txt');

if exist(latest,'file') ~= 2
    return;
end

runId = strtrim(fileread(latest));

cand = fullfile(rootDir, 'results', expName, runId, 'tidy.csv');

if exist(cand,'file') == 2
    f = cand;
end

end


function f = localDatasetTidy(rootDir, seedValue)
%LOCALDATASETTIDY The EXP10A dataset to compare the clone against.
%
% Selection order, and each clause is here because getting it wrong
% produces a WRONG VERDICT rather than an error:
%
%   1  the run LATEST.txt names, if it contains the seed. That is the
%      dataset every other artefact in the repo describes, so it is the
%      one a reproduction claim is about.
%   2  otherwise the run with the most seeds, breaking ties on the NEWEST
%      directory name.
%
% Not simply LATEST unconditionally: a smoke run writes LATEST.txt too,
% and comparing against a 1-seed smoke would make the check trivially
% pass.
%
% The tie-break is not cosmetic. It was originally a strict "more seeds
% than the best so far", which meant that among two complete 50-seed
% datasets the FIRST one alphabetically won - the superseded one. The
% check then compared the clone's fresh run against a dataset predating
% the exact-checksum fix and reported that the clone "does not
% reproduce", naming exactly the three columns that fix had changed. The
% clone was reproducing perfectly; the harness was pointing at the wrong
% file.

f = '';

expDir = fullfile(rootDir, 'results', 'exp10a_final_validation');

if exist(expDir,'dir') ~= 7
    return;
end

% ---- 1. the run LATEST.txt names ----

latest = fullfile(expDir, 'LATEST.txt');

if exist(latest,'file') == 2

    runId = strtrim(fileread(latest));

    cand = fullfile(expDir, runId, 'tidy.csv');

    if localHasSeed(cand, seedValue)
        f = cand;
        return;
    end

end

% ---- 2. most seeds, newest directory wins a tie ----

d = dir(expDir);

names = {};

for k = 1:numel(d)
    if d(k).isdir && ~startsWith(d(k).name, '.')
        names{end+1} = d(k).name;   %#ok<AGROW>
    end
end

names = sort(names);   % run ids are timestamps, so this is chronological

best = 0;

for k = 1:numel(names)

    cand = fullfile(expDir, names{k}, 'tidy.csv');

    n = localSeedCount(cand, seedValue);

    % >= rather than >, so that the newest of two equally complete
    % datasets is the one selected.
    if n > 0 && n >= best
        best = n;
        f = cand;
    end

end

end


function tf = localHasSeed(tidyPath, seedValue)

tf = localSeedCount(tidyPath, seedValue) > 0;

end


function n = localSeedCount(tidyPath, seedValue)
%LOCALSEEDCOUNT Distinct seeds in a tidy file, or 0 if it lacks the seed.

n = 0;

if exist(tidyPath,'file') ~= 2
    return;
end

T = readtable(tidyPath, 'TextType','char');

if ~ismember('seed', T.Properties.VariableNames)
    return;
end

if ~any(T.seed == seedValue)
    return;
end

n = numel(unique(T.seed));

end


function [same, detail] = localCompareTables(A, B)
%LOCALCOMPARETABLES Column-by-column comparison with NaN treated as equal.

detail = {};

if height(A) ~= height(B)
    detail{end+1} = sprintf('row count %d versus %d', height(A), height(B));
    same = false;
    return;
end

va = A.Properties.VariableNames;
vb = B.Properties.VariableNames;

if ~isequal(sort(va), sort(vb))
    detail{end+1} = 'column sets differ';
    same = false;
    return;
end

same = true;

for k = 1:numel(va)

    a = A.(va{k});
    b = B.(va{k});

    if ~isequaln(a, b)
        same = false;
        detail{end+1} = sprintf('column %s differs', va{k});   %#ok<AGROW>
    end

end

end


function s = localHave(f)

if isempty(f)
    s = 'absent';
else
    s = 'present';
end

end


function s = localYesNo(tf)

if tf
    s = 'yes';
else
    s = 'NO';
end

end


function s = localCleanWord(tf)

if tf
    s = 'clean';
else
    s = 'DIRTY';
end

end


function s = localPassFail(tf)

if tf
    s = 'PASS';
else
    s = 'FAIL';
end

end
