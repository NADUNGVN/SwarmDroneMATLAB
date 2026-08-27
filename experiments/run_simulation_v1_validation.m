%% RUN_SIMULATION_V1_VALIDATION - EXP10C, the single-command freeze check
%
% One command that reproduces and verifies the whole simulation-v1.0
% claim set:
%
%   1  run the full test suite
%   2  validate the locked tags and hash the configuration
%   3  run or reload the EXP10A holdout dataset
%   4  rebuild the EXP10B unified matrix, tables and figures from it
%   5  re-verify every realization hash against a freshly drawn registry
%   6  check serial-versus-parallel determinism on one seed
%   7  write the environment manifest
%
% Any of 1, 2, 5 or 6 failing is a BLOCKER: the freeze does not proceed.
% A scientific result being unfavourable is not a blocker and never
% triggers a re-run.
%
% USAGE
%
%   run_simulation_v1_validation
%
%       Reloads the existing EXP10A dataset if one is present. This is
%       the normal reproduction path and takes minutes rather than hours.
%
%   v1ForceRun = true; run_simulation_v1_validation
%
%       Re-runs EXP10A from scratch. Only for a genuine regeneration.
%
%   v1SkipTests = true; run_simulation_v1_validation
%
%       Skips step 1. Provided for iterating on later steps; the freeze
%       is NOT valid on a run that skipped the tests, and the manifest
%       records that it did.
%
% WHY THE DETERMINISM CHECK IS BIT-IDENTITY AND NOT A TOLERANCE
%
% Every stochastic input is a pre-drawn realization indexed by (link,
% timestep) or by physical time, and both simulators pin the generator
% explicitly with rng(seed,'twister') because pool workers default to a
% different generator than the client. There is therefore no legitimate
% source of difference between a serial and a parallel execution of the
% same run, and a tolerance would only hide one. If bit-identity ever
% fails here, the correct response is to find the cause, not to widen the
% comparison.
%
% ============================================================

startup;

close all;


expRun = startExperiment('simulation_v1_validation');

relog = @() localRelog(expRun);


%% ============================================================
% Options
% ============================================================

forceRun  = localBaseFlag('v1ForceRun');
skipTests = localBaseFlag('v1SkipTests');

fprintf('\n');
fprintf('############################################################\n');
fprintf('# SIMULATION v1.0 VALIDATION\n');
fprintf('############################################################\n\n');

fprintf('  force EXP10A re-run : %s\n', localYesNo(forceRun));
fprintf('  skip test suite     : %s\n', localYesNo(skipTests));

blockers = {};

stepNames  = {};
stepStatus = {};
stepDetail = {};


%% ============================================================
% STEP 1 - test suite
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STEP 1 / 7  test suite\n');
fprintf('============================================================\n');

if skipTests

    testsPassed = false;

    stepNames{end+1}  = 'test suite';
    stepStatus{end+1} = 'SKIPPED';
    stepDetail{end+1} = 'v1SkipTests was set; this run cannot support a freeze';

    fprintf('\n  SKIPPED by request. The freeze is not valid on this run.\n');

else

    tTest = tic;

    try
        evalin('base', 'run_all_tests');
        testsPassed = true;
    catch err
        testsPassed = false;
        blockers{end+1} = sprintf('test suite failed: %s', err.message);
    end

    relog();

    stepNames{end+1}  = 'test suite';
    stepStatus{end+1} = localPassFail(testsPassed);
    stepDetail{end+1} = sprintf('%.1f min', toc(tTest)/60);

end


%% ============================================================
% STEP 2 - tags and configuration
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STEP 2 / 7  locked tags and configuration hash\n');
fprintf('============================================================\n\n');

requiredTags = { ...
    'exp07a-locked'; ...
    'exp07b-locked'; ...
    'exp07c-locked-negative'; ...
    'exp08a-locked-partial'; ...
    'exp08ad-locked-diagnostic'; ...
    'exp08b-locked-partial'; ...
    'exp08c-locked-partial'; ...
    'exp09a-locked'; ...
    'exp09b-locked-partial'; ...
    'exp09c-locked-partial'};

tagSha = cell(numel(requiredTags),1);
tagOk  = false(numel(requiredTags),1);

for k = 1:numel(requiredTags)

    [st, out] = system(sprintf('git -C "%s" rev-list -n1 %s', ...
        projectRoot(), requiredTags{k}));

    if st == 0
        tagSha{k} = strtrim(out);
        tagOk(k)  = ~isempty(tagSha{k});
    else
        tagSha{k} = '';
        tagOk(k)  = false;
    end

    fprintf('  [%-5s] %-28s %s\n', localOkMissing(tagOk(k)), ...
        requiredTags{k}, tagSha{k});

end

tagsPassed = all(tagOk);

if ~tagsPassed
    blockers{end+1} = sprintf('%d locked tag(s) missing', nnz(~tagOk));
end

% ---- configuration hashes ----

sc  = exp10Scenarios();
pts = exp10Points();

exp10Seeds = 25000001:25000050;

cfgHashDefault = configHash(defaultConfig());

pointCfgHash = zeros(numel(pts),1);

fprintf('\n  configuration hashes\n');
fprintf('    %-14s %20s\n', 'defaultConfig', sprintf('%.0f', cfgHashDefault));

for ip = 1:numel(pts)

    % Hashed at the FIRST holdout seed and Moderate, so the value is a
    % property of the point definition rather than of a particular run.
    cfgP = applyExp10Point(pts(ip), sc.MODERATE, exp10Seeds(1));

    pointCfgHash(ip) = configHash(cfgP);

    fprintf('    %-14s %20s\n', pts(ip).id, sprintf('%.0f', pointCfgHash(ip)));

end

stepNames{end+1}  = 'locked tags';
stepStatus{end+1} = localPassFail(tagsPassed);
stepDetail{end+1} = sprintf('%d of %d present', nnz(tagOk), numel(tagOk));


%% ============================================================
% STEP 3 - the EXP10A dataset
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STEP 3 / 7  EXP10A holdout dataset\n');
fprintf('============================================================\n\n');

srcRoot = fullfile(projectRoot(), 'results', 'exp10a_final_validation');

latestFile = fullfile(srcRoot, 'LATEST.txt');

haveDataset = exist(latestFile,'file') == 2;

if haveDataset
    srcRunId = strtrim(fileread(latestFile));
    haveDataset = exist(fullfile(srcRoot, srcRunId, 'tidy.csv'),'file') == 2;
end

if forceRun || ~haveDataset

    if forceRun
        fprintf('  Re-running EXP10A by request.\n');
    else
        fprintf('  No dataset found. Running EXP10A.\n');
    end

    evalin('base', 'clear exp10SmokeSeeds');
    evalin('base', 'exp10a_final_validation');

    relog();

    srcRunId = strtrim(fileread(latestFile));

else

    fprintf('  Reloading the existing dataset: %s\n', srcRunId);

end

srcDir = fullfile(srcRoot, srcRunId);

D = readtable(fullfile(srcDir,'tidy.csv'), 'TextType','char');

datasetSeeds = unique(D.seed);

datasetComplete = numel(datasetSeeds) == 50 && ...
    isequal(sort(datasetSeeds(:))', exp10Seeds);

fprintf('  rows   : %d\n', height(D));
fprintf('  seeds  : %d\n', numel(datasetSeeds));
fprintf('  block  : %d..%d\n', min(datasetSeeds), max(datasetSeeds));
fprintf('  matches the pre-registered 50-seed holdout block : %s\n', ...
    localYesNo(datasetComplete));

if ~datasetComplete
    fprintf(2, ['\n  The dataset is NOT the pre-registered 50-seed ' ...
        'block. Everything downstream describes a %d-seed run.\n'], ...
        numel(datasetSeeds));
end

stepNames{end+1}  = 'EXP10A dataset';
stepStatus{end+1} = localPassFail(datasetComplete);
stepDetail{end+1} = sprintf('%s, %d rows, %d seeds', ...
    srcRunId, height(D), numel(datasetSeeds));


%% ============================================================
% STEP 4 - rebuild the unified matrix, tables and figures
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STEP 4 / 7  rebuild EXP10B from the persisted dataset\n');
fprintf('============================================================\n\n');

try
    evalin('base', 'exp10b_unified_matrix');
    rebuildOk = true;
catch err
    rebuildOk = false;
    blockers{end+1} = sprintf('EXP10B rebuild failed: %s', err.message);
end

relog();

bRoot = fullfile(projectRoot(), 'results', 'exp10b_unified_matrix');

if exist(fullfile(bRoot,'LATEST.txt'),'file') == 2
    bRunId = strtrim(fileread(fullfile(bRoot,'LATEST.txt')));
else
    bRunId = '';
end

figCount = 0;

if ~isempty(bRunId)
    figCount = numel(dir(fullfile(bRoot, bRunId, 'figures', '*.png')));
end

fprintf('  EXP10B run : %s\n', bRunId);
fprintf('  figures    : %d\n', figCount);

stepNames{end+1}  = 'EXP10B rebuild';
stepStatus{end+1} = localPassFail(rebuildOk);
stepDetail{end+1} = sprintf('%s, %d figures', bRunId, figCount);


%% ============================================================
% STEP 5 - re-verify realization hashes against a fresh registry
%
% The registry is drawn again here, in this session, and compared against
% the hashes stored in the dataset. That is a stronger statement than the
% check EXP10A made while running: it says the realizations are
% reproducible from the seed in a new process, not merely consistent
% within one.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STEP 5 / 7  realization hashes, re-derived in this session\n');
fprintf('============================================================\n');

ensureParallelPool(16);

Nlist = unique([pts.N]);

reg = exp10Registry(datasetSeeds, Nlist, true);

relog();

hashMismatch = 0;
hashChecked  = 0;

for r = 1:height(D)

    N = D.pointN(r);

    iS = find(reg.seeds == D.seed(r), 1);
    iN = find(reg.N == N, 1);

    if isempty(iS) || isempty(iN)
        hashMismatch = hashMismatch + 1;
        continue;
    end

    hashChecked = hashChecked + 1;

    if D.FWDHASH(r) ~= reg.fwd(iS,iN)
        hashMismatch = hashMismatch + 1;
    end

    if strcmp(D.method{r}, 'Causal-v3') && D.ACKHASH(r) ~= reg.ack(iS,iN)
        hashMismatch = hashMismatch + 1;
    end

    if ismember(D.method{r}, {'P10','P20'}) && ...
            D.PHASEHASH(r) ~= reg.phase(iS,iN)
        hashMismatch = hashMismatch + 1;
    end

    if strcmp(D.kind{r},'link') && D.FAULTHASH(r) ~= reg.link(iS,iN)
        hashMismatch = hashMismatch + 1;
    end

    if strcmp(D.kind{r},'node') && D.BLACKHASH(r) ~= reg.blackout(iS,iN)
        hashMismatch = hashMismatch + 1;
    end

    if strcmp(D.kind{r},'mismatch') && D.EXTHASH(r) ~= reg.extForce(iS,iN)
        hashMismatch = hashMismatch + 1;
    end

    if strcmp(D.kind{r},'estimator') && D.NOISEHASH(r) ~= reg.noise(iS,iN)
        hashMismatch = hashMismatch + 1;
    end

end

hashesOk = hashMismatch == 0;

fprintf('\n  rows checked : %d\n', hashChecked);
fprintf('  mismatches   : %d\n', hashMismatch);

if ~hashesOk
    blockers{end+1} = sprintf('%d realization-hash mismatch(es)', hashMismatch);
end

stepNames{end+1}  = 'realization hashes';
stepStatus{end+1} = localPassFail(hashesOk);
stepDetail{end+1} = sprintf('%d rows, %d mismatch(es)', hashChecked, hashMismatch);


%% ============================================================
% STEP 6 - serial versus parallel determinism, one seed
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STEP 6 / 7  serial versus parallel determinism\n');
fprintf('============================================================\n\n');

detPoint = pts(1);              % NOMINAL, N = 5, 6-DOF
detScen  = sc.STRESSED;
detSeed  = exp10Seeds(1);

methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

nM = numel(methodNames);

fprintf('  point %s / %s, seed %d, all %d methods\n\n', ...
    detPoint.id, sc.names{detScen}, detSeed, nM);

% ---- serial, in the client ----

serialScalar = nan(nM, 10);
serialTraj   = cell(nM,1);

for iM = 1:nM

    cfgD = applyExp10Point(detPoint, detScen, detSeed);

    o = simSwarm6DOF(cfgD, methodNames{iM});

    serialScalar(iM,:) = localDetVector(o, cfgD);
    serialTraj{iM}     = o.P;

end

% ---- parallel, on pool workers ----

parScalar = nan(nM, 10);
parTraj   = cell(nM,1);

parfor iM = 1:nM

    cfgD = applyExp10Point(detPoint, detScen, detSeed);

    o = simSwarm6DOF(cfgD, methodNames{iM});

    parScalar(iM,:) = localDetVector(o, cfgD);
    parTraj{iM}     = o.P;

end

detNames = {'RMSE','minSep','DATA','ACK','broadcast','rx','drop', ...
            'fwdHash','ackHash','invariants'};

fprintf('  %-12s %-12s %24s %24s %s\n', ...
    'Method','Quantity','serial','parallel','identical');

detOk = true;

for iM = 1:nM

    for q = 1:numel(detNames)

        a = serialScalar(iM,q);
        b = parScalar(iM,q);

        same = isequaln(a, b);

        detOk = detOk && same;

        if ~same
            fprintf('  %-12s %-12s %24.15g %24.15g %s\n', ...
                methodNames{iM}, detNames{q}, a, b, 'NO');
        end

    end

    trajSame = isequaln(serialTraj{iM}, parTraj{iM});

    detOk = detOk && trajSame;

    fprintf('  %-12s %-12s %24s %24s %s\n', ...
        methodNames{iM}, 'trajectory', ...
        sprintf('%d samples', numel(serialTraj{iM})), ...
        sprintf('%d samples', numel(parTraj{iM})), ...
        localYesNo(trajSame));

end

fprintf('\n  bit-identical across serial and parallel execution : %s\n', ...
    localYesNo(detOk));

if ~detOk
    blockers{end+1} = 'serial and parallel execution disagree';
    fprintf(2, ['\n  This is a BLOCKER. No tolerance is applied: every ' ...
        'stochastic input is a pre-drawn realization and both simulators ' ...
        'pin the generator, so there is no legitimate source of ' ...
        'difference.\n']);
end

stepNames{end+1}  = 'serial/parallel determinism';
stepStatus{end+1} = localPassFail(detOk);
stepDetail{end+1} = sprintf('%d methods, trajectories and counters compared', nM);


%% ============================================================
% STEP 7 - environment manifest
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STEP 7 / 7  environment manifest\n');
fprintf('============================================================\n\n');

man = struct();

man.generatedAt = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));

[~, shaOut]    = system(sprintf('git -C "%s" rev-parse HEAD', projectRoot()));
[~, branchOut] = system(sprintf('git -C "%s" rev-parse --abbrev-ref HEAD', projectRoot()));
[~, dirtyOut]  = system(sprintf('git -C "%s" status --porcelain', projectRoot()));

man.git.sha    = strtrim(shaOut);
man.git.branch = strtrim(branchOut);
man.git.clean  = isempty(strtrim(dirtyOut));

man.git.dirtyFiles = numel(strsplit(strtrim(dirtyOut), newline));

if man.git.clean
    man.git.dirtyFiles = 0;
end

man.tags = struct();

for k = 1:numel(requiredTags)
    man.tags.(matlab.lang.makeValidName(requiredTags{k})) = tagSha{k};
end

v = ver('MATLAB');

man.matlab.name    = v.Name;
man.matlab.version = v.Version;
man.matlab.release = v.Release;
man.matlab.date    = v.Date;

allVer = ver;

man.toolboxes = cell(numel(allVer),1);

for k = 1:numel(allVer)
    man.toolboxes{k} = sprintf('%s %s', allVer(k).Name, allVer(k).Version);
end

man.platform.computer = computer;
man.platform.arch     = computer('arch');
man.platform.os       = localOsString();
man.platform.maxCores = feature('numcores');

pool = gcp('nocreate');

if isempty(pool)
    man.parallel.active     = false;
    man.parallel.numWorkers = 0;
    man.parallel.profile    = '';
else
    man.parallel.active     = true;
    man.parallel.numWorkers = pool.NumWorkers;
    man.parallel.profile    = pool.Cluster.Profile;
end

man.parallel.workerCapNote = ...
    ['EXP10A caps concurrent workers per point (16 at N=5, 12 at N=20, ' ...
     '8 at N=50) for memory. The cap affects scheduling only; step 6 ' ...
     'verifies results are independent of it.'];

man.seeds.block   = exp10Seeds;
man.seeds.count   = numel(exp10Seeds);
man.seeds.holdout = true;

man.configHash.defaultConfig = cfgHashDefault;

for ip = 1:numel(pts)
    man.configHash.(matlab.lang.makeValidName(pts(ip).id)) = pointCfgHash(ip);
end

% Trace hashes: the per-(N, seed) table is written to its own CSV, and a
% single fold of it goes in the manifest so a one-line comparison can
% detect any change.
man.traceHash.masterFold = realizationHash(reg.master(:));
man.traceHash.forwardFold  = realizationHash(reg.fwd(:));
man.traceHash.reverseFold  = realizationHash(reg.ack(:));
man.traceHash.phaseFold    = realizationHash(reg.phase(:));
man.traceHash.linkFold     = realizationHash(reg.link(:));
man.traceHash.blackoutFold = realizationHash(reg.blackout(:));
man.traceHash.extForceFold = realizationHash(reg.extForce(:));
man.traceHash.noiseFold    = realizationHash(reg.noise(:));
man.traceHash.N            = reg.N;

man.dataset.exp10aRunId = srcRunId;
man.dataset.exp10bRunId = bRunId;
man.dataset.rows        = height(D);
man.dataset.seeds       = numel(datasetSeeds);
man.dataset.complete    = datasetComplete;

man.checks.testsRun      = ~skipTests;
man.checks.testsPassed   = testsPassed;
man.checks.tagsPassed    = tagsPassed;
man.checks.hashesPassed  = hashesOk;
man.checks.determinism   = detOk;
man.checks.rebuildPassed = rebuildOk;

manFile = fullfile(expRun.dir, 'manifest.json');

fid = fopen(manFile,'w');
if fid > 0
    fprintf(fid, '%s\n', jsonencode(man, 'PrettyPrint', true));
    fclose(fid);
end

% Full trace-hash table, one row per (N, seed).
RH = table();
rr = 0;
for iN = 1:numel(reg.N)
    for iS = 1:numel(reg.seeds)
        rr = rr + 1;
        RH.N(rr)        = reg.N(iN);
        RH.seed(rr)     = reg.seeds(iS);
        RH.forward(rr)  = reg.fwd(iS,iN);
        RH.reverse(rr)  = reg.ack(iS,iN);
        RH.phase(rr)    = reg.phase(iS,iN);
        RH.link(rr)     = reg.link(iS,iN);
        RH.blackout(rr) = reg.blackout(iS,iN);
        RH.extForce(rr) = reg.extForce(iS,iN);
        RH.noise(rr)    = reg.noise(iS,iN);
        RH.master(rr)   = reg.master(iS,iN);
    end
end

writetable(RH, fullfile(expRun.dir,'trace_hashes.csv'));

fprintf('  manifest.json      : %d toolboxes, git %s%s\n', ...
    numel(man.toolboxes), man.git.sha(1:min(8,end)), ...
    localDirtyMark(man.git.clean));
fprintf('  trace_hashes.csv   : %d rows\n', height(RH));

stepNames{end+1}  = 'environment manifest';
stepStatus{end+1} = 'PASS';
stepDetail{end+1} = sprintf('manifest.json, trace_hashes.csv (%d rows)', height(RH));


%% ============================================================
% Verdict
% ============================================================

fprintf('\n');
fprintf('############################################################\n');
fprintf('# SIMULATION v1.0 VALIDATION SUMMARY\n');
fprintf('############################################################\n\n');

for k = 1:numel(stepNames)
    fprintf('  [%-7s] %-30s %s\n', ...
        stepStatus{k}, stepNames{k}, stepDetail{k});
end

freezeReady = isempty(blockers) && ~skipTests && datasetComplete;

fprintf('\n');

if freezeReady

    fprintf('  FREEZE READY: every blocking check passed.\n');
    fprintf('  simulation-v1.0 may be tagged on this commit.\n');

else

    fprintf('  FREEZE NOT READY.\n');

    if skipTests
        fprintf('    - the test suite was skipped\n');
    end

    if ~datasetComplete
        fprintf('    - the dataset is not the pre-registered 50-seed block\n');
    end

    for k = 1:numel(blockers)
        fprintf('    - %s\n', blockers{k});
    end

end

fprintf('\n  A scientific result being unfavourable is NOT a blocker and\n');
fprintf('  is not a reason to re-run anything.\n');


%% ============================================================
% Persist
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function localRelog(R)
%LOCALRELOG Restore this script's diary after a nested experiment.
%
% startExperiment points the diary at its own console.log and
% finishExperiment turns the diary off, so an inner experiment would
% otherwise truncate this script's log at the point it was called.

diary(R.logFile);
diary on;

end


function tf = localBaseFlag(name)
%LOCALBASEFLAG Read an optional boolean from the base workspace.

tf = false;

if evalin('base', sprintf('exist(''%s'',''var'')', name))
    val = evalin('base', name);
    tf = ~isempty(val) && all(logical(val));
end

end


function v = localDetVector(o, cfg)
%LOCALDETVECTOR The scalars the determinism check compares.

M = computeSwarmMetrics(o, cfg);

if isfield(o,'ackTxCount')
    ackCount = o.ackTxCount;
else
    ackCount = 0;
end

if isfield(o,'invariantViolations')
    inv = o.invariantViolations;
else
    inv = 0;
end

v = [ ...
    M.formationRMSE, ...
    M.minSeparationEval, ...
    o.txCount, ...
    ackCount, ...
    o.broadcastCount, ...
    o.rxCount, ...
    o.dropCount, ...
    o.traceHash, ...
    o.ackTraceHash, ...
    inv];

end


function s = localPassFail(tf)

if tf
    s = 'PASS';
else
    s = 'FAIL';
end

end


function s = localOkMissing(tf)

if tf
    s = 'ok';
else
    s = 'MISS';
end

end


function s = localYesNo(tf)

if tf
    s = 'yes';
else
    s = 'no';
end

end


function s = localDirtyMark(clean)

if clean
    s = ' (clean)';
else
    s = ' (DIRTY working tree)';
end

end


function s = localOsString()

try
    if ispc
        [~, o] = system('ver');
        s = strtrim(o);
    elseif ismac
        [~, o] = system('sw_vers -productVersion');
        s = ['macOS ' strtrim(o)];
    else
        [~, o] = system('uname -sr');
        s = strtrim(o);
    end
catch
    s = computer;
end

s = regexprep(s, '\s+', ' ');

end
