%% TCNS GATE 0 - Frozen baseline audit and selected deterministic replay
%
% This audit deliberately names the canonical EXP10 and EXP11 directories.
% It never uses EXP11/LATEST.txt to select canonical evidence. At the requested
% starting snapshot that pointer identified a three-seed debug run; after a
% successful reproduction it legitimately identifies the new 50-seed run.
%
% The selected replay is not a substitute for the full EXP10 reproduction.
% It is a fail-fast check over the nominal N=5 6-DOF point, all three network
% regimes, P10 and Causal-v3, using the first frozen holdout seed.  Gate 0 also
% runs experiments/run_simulation_v1_validation.m in forced full-run mode.

startup;
close all;

R = startExperiment('tcns_gate0_baseline_audit', ...
    'Explicit canonical audit plus selected deterministic 6-DOF replay.');

root = projectRoot();
startingCommit = 'dbbb4197849694154cfec769d18fc4b38b05f0ad';
expectedTree = '954fbf22ee37039619b3dd4b04d4dc4b22f85f86';
exp10Rel = fullfile('results','exp10a_final_validation','2026-08-27_091546');
exp11Rel = fullfile('results','exp11_dynamic_network','2026-08-27_174026');
exp11DebugRel = fullfile('results','exp11_dynamic_network','2026-08-27_175335');

exp10File = fullfile(root,exp10Rel,'tidy.csv');
exp11File = fullfile(root,exp11Rel,'tidy.csv');
exp11DebugFile = fullfile(root,exp11DebugRel,'tidy.csv');

mustExist(exp10File);
mustExist(exp11File);
mustExist(exp11DebugFile);

[gitStatus,gitCommit] = system(sprintf( ...
    'git -C "%s" rev-parse HEAD',root));
assert(gitStatus == 0,'Gate0: cannot resolve Git commit.');
gitCommit = strtrim(gitCommit);

[treeStatus,startingTree] = system(sprintf( ...
    'git -C "%s" show -s --format=%%T %s',root,startingCommit));
assert(treeStatus == 0,'Gate0: cannot resolve the starting tree.');
startingTree = strtrim(startingTree);
assert(strcmp(startingTree,expectedTree), ...
    'Gate0: requested starting tree mismatch. Expected %s, got %s.', ...
    expectedTree,startingTree);

[ancestorStatus,~] = system(sprintf( ...
    'git -C "%s" merge-base --is-ancestor %s HEAD',root,startingCommit));
assert(ancestorStatus == 0, ...
    'Gate0: starting commit is not an ancestor of the audit commit.');

fprintf('Requested tree : %s\n',expectedTree);
fprintf('Starting commit: %s\n',startingCommit);
fprintf('Audited commit : %s\n',gitCommit);
fprintf('Tree identity  : PASS\n\n');

E10 = readtable(exp10File,'TextType','string');
E11 = readtable(exp11File,'TextType','string');
E11debug = readtable(exp11DebugFile,'TextType','string');

checkDataset(E10,3400,50,'EXP10 canonical');
checkDataset(E11,400,50,'EXP11 canonical');
checkDataset(E11debug,24,3,'EXP11 debug');

latest11File = fullfile(root,'results','exp11_dynamic_network','LATEST.txt');
mustExist(latest11File);
latest11 = strtrim(fileread(latest11File));
latestPointsToDebug = strcmp(latest11,'2026-08-27_175335');
latest11Data = fullfile(root,'results','exp11_dynamic_network',latest11, ...
    'tidy.csv');
mustExist(latest11Data);
E11latest = readtable(latest11Data,'TextType','string');
latestIsFull = height(E11latest) == 400 && ...
    numel(unique(E11latest.seed)) == 50;
assert(latestPointsToDebug || latestIsFull, ...
    ['Gate0: EXP11 LATEST is neither the recorded historical debug run ' ...
     'nor a complete 400-row/50-seed run.']);

fprintf('EXP10 canonical : %d rows, %d seeds\n', ...
    height(E10),numel(unique(E10.seed)));
fprintf('EXP11 canonical : %d rows, %d seeds\n', ...
    height(E11),numel(unique(E11.seed)));
fprintf('EXP11 debug     : %d rows, %d seeds\n', ...
    height(E11debug),numel(unique(E11debug.seed)));
if latestPointsToDebug
    latestClass = 'historical debug, never used as canonical';
else
    latestClass = 'complete reproduction, canonical source still explicit';
end
fprintf('EXP11 LATEST    : %s (%s)\n\n',latest11,latestClass);

% -------------------------------------------------------------------------
% Canonical numerical summary, written without recomputing any simulation.
% -------------------------------------------------------------------------

scenarioNames = ["Clean";"Moderate";"Stressed"];
methodNames = ["P10";"Causal-v3"];
summary10 = table('Size',[6 8], ...
    'VariableTypes',{'string','string','double','double','double', ...
    'double','double','double'}, ...
    'VariableNames',{'scenario','method','n','formationRMSE_m', ...
    'dataRate_Hz','ackRate_Hz','total025_Hz','broadcastRate_Hz'});
row = 0;
for iScenario = 1:numel(scenarioNames)
    for iMethod = 1:numel(methodNames)
        idx = E10.point == "NOMINAL" & ...
            E10.scenario == scenarioNames(iScenario) & ...
            E10.method == methodNames(iMethod);
        assert(nnz(idx) == 50, ...
            'Gate0: EXP10 nominal cell is not a 50-seed cell.');
        row = row+1;
        summary10.scenario(row,1) = scenarioNames(iScenario);
        summary10.method(row,1) = methodNames(iMethod);
        summary10.n(row,1) = nnz(idx);
        summary10.formationRMSE_m(row,1) = mean(E10.RMSE(idx));
        summary10.dataRate_Hz(row,1) = mean(E10.DATARATE(idx));
        summary10.ackRate_Hz(row,1) = mean(E10.ACKRATE(idx));
        summary10.total025_Hz(row,1) = mean(E10.TOTAL025(idx));
        summary10.broadcastRate_Hz(row,1) = mean(E10.BCASTRATE(idx));
    end
end

writetable(summary10,fullfile(R.dir,'canonical_exp10_nominal_summary.csv'));

methodNames11 = ["P10";"P12.5";"P20";"Causal"; ...
    "StateEvent";"OraclePeriodic"];
summary11 = table('Size',[6 7], ...
    'VariableTypes',{'string','double','double','double','double', ...
    'double','double'}, ...
    'VariableNames',{'method','n','formationRMSE_m','dataRate_Hz', ...
    'ackRate_Hz','total025_Hz','broadcastRate_Hz'});
for iMethod = 1:numel(methodNames11)
    idx = E11.method == methodNames11(iMethod);
    assert(nnz(idx) == 50, ...
        'Gate0: EXP11 method %s is not a 50-seed cell.',methodNames11(iMethod));
    summary11.method(iMethod,1) = methodNames11(iMethod);
    summary11.n(iMethod,1) = nnz(idx);
    summary11.formationRMSE_m(iMethod,1) = mean(E11.RMSE(idx));
    summary11.dataRate_Hz(iMethod,1) = mean(E11.DATAHZ(idx));
    summary11.ackRate_Hz(iMethod,1) = mean(E11.ACKHZ(idx));
    summary11.total025_Hz(iMethod,1) = mean(E11.TOTW025(idx));
    summary11.broadcastRate_Hz(iMethod,1) = mean(E11.BCASTHZ(idx));
end
writetable(summary11,fullfile(R.dir,'canonical_exp11_summary.csv'));

% -------------------------------------------------------------------------
% Fail-fast selected replay against persisted EXP10 rows.
% -------------------------------------------------------------------------

seed = 25000001;
pts = exp10Points();
pt = pts(strcmp({pts.id},'NOMINAL'));
assert(isscalar(pt),'Gate0: NOMINAL point lookup is ambiguous.');
sc = exp10Scenarios();

replayNames = {'scenario','method','seed','expectedRMSE','actualRMSE', ...
    'absRMSEDifference','expectedMinSeparation','actualMinSeparation', ...
    'expectedDataCount','actualDataCount','expectedAckCount', ...
    'actualAckCount','expectedBroadcastCount','actualBroadcastCount', ...
    'expectedSaturation','actualSaturation','expectedForwardHashExact', ...
    'actualForwardHashExact','expectedAckHashExact','actualAckHashExact', ...
    'expectedInvariantViolations','actualInvariantViolations','pass'};
replayTypes = [{'string','string'},repmat({'double'},1,20),{'logical'}];
replay = table('Size',[6 numel(replayNames)], ...
    'VariableTypes',replayTypes,'VariableNames',replayNames);
rr = 0;

for iScenario = [sc.CLEAN sc.MODERATE sc.STRESSED]
    for iMethod = 1:numel(methodNames)
        method = methodNames(iMethod);
        cfg = applyExp10Point(pt,iScenario,seed);
        out = simSwarm6DOF(cfg,char(method));
        M = computeSwarmMetrics(out,cfg);
        Q = compute6DOFMetrics(out,cfg);
        mission = out.t(end)-out.t(1);

        expectedIdx = E10.point == "NOMINAL" & ...
            E10.scenario == string(sc.names{iScenario}) & ...
            E10.method == method & E10.seed == seed;
        assert(nnz(expectedIdx) == 1, ...
            'Gate0: selected canonical row lookup failed.');
        expected = E10(expectedIdx,:);

        ackCount = 0;
        if isfield(out,'ackTxCount'), ackCount = out.ackTxCount; end
        invariantCount = 0;
        if isfield(out,'invariantViolations')
            invariantCount = out.invariantViolations;
        end

        rr = rr+1;
        replay.scenario(rr,1) = string(sc.names{iScenario});
        replay.method(rr,1) = method;
        replay.seed(rr,1) = seed;
        replay.expectedRMSE(rr,1) = expected.RMSE;
        replay.actualRMSE(rr,1) = M.formationRMSE;
        replay.absRMSEDifference(rr,1) = abs(M.formationRMSE-expected.RMSE);
        replay.expectedMinSeparation(rr,1) = expected.MINSEP;
        replay.actualMinSeparation(rr,1) = M.minSeparationEval;
        replay.expectedDataCount(rr,1) = expected.DATACOUNT;
        replay.actualDataCount(rr,1) = out.txCount;
        replay.expectedAckCount(rr,1) = expected.ACKCOUNT;
        replay.actualAckCount(rr,1) = ackCount;
        replay.expectedBroadcastCount(rr,1) = expected.BCASTCOUNT;
        replay.actualBroadcastCount(rr,1) = out.broadcastCount;
        replay.expectedSaturation(rr,1) = expected.SATURATION;
        replay.actualSaturation(rr,1) = Q.saturation;
        replay.expectedForwardHashExact(rr,1) = expected.FWDHASHX;
        replay.actualForwardHashExact(rr,1) = out.traceHashExact;
        replay.expectedAckHashExact(rr,1) = expected.ACKHASHX;
        replay.actualAckHashExact(rr,1) = out.ackTraceHashExact;
        replay.expectedInvariantViolations(rr,1) = expected.INVARIANTS;
        replay.actualInvariantViolations(rr,1) = invariantCount;

        floatTol = 1e-12;
        sameFloat = replay.absRMSEDifference(rr) <= floatTol && ...
            abs(M.minSeparationEval-expected.MINSEP) <= floatTol && ...
            abs(Q.saturation-expected.SATURATION) <= floatTol;
        sameCounts = out.txCount == expected.DATACOUNT && ...
            ackCount == expected.ACKCOUNT && ...
            out.broadcastCount == expected.BCASTCOUNT;
        sameHashes = out.traceHashExact == expected.FWDHASHX && ...
            (isnan(expected.ACKHASHX) || ...
             out.ackTraceHashExact == expected.ACKHASHX);
        sameInvariants = invariantCount == expected.INVARIANTS;
        replay.pass(rr,1) = sameFloat && sameCounts && sameHashes && ...
            sameInvariants;

        fprintf('%-9s %-10s RMSE %.15g, DATA %d, ACK %d: %s\n', ...
            sc.names{iScenario},method,M.formationRMSE,out.txCount,ackCount, ...
            passFail(replay.pass(rr)));
    end
end

writetable(replay,fullfile(R.dir,'selected_replay_comparison.csv'));
assert(all(replay.pass), ...
    'Gate0: selected deterministic replay does not match canonical EXP10.');

audit = struct();
audit.schemaVersion = 1;
audit.gate = 0;
audit.status = 'PASS_SELECTED_REPLAY';
audit.startingCommit = startingCommit;
audit.requestedTree = expectedTree;
audit.gitCommit = gitCommit;
audit.startingTree = startingTree;
audit.matlab = version;
audit.release = version('-release');
audit.seed = seed;
audit.selectedReplayRows = height(replay);
audit.selectedReplayPassed = all(replay.pass);
audit.exp10Canonical = normalizePath(exp10Rel);
audit.exp10Rows = height(E10);
audit.exp10Seeds = numel(unique(E10.seed));
audit.exp11Canonical = normalizePath(exp11Rel);
audit.exp11Rows = height(E11);
audit.exp11Seeds = numel(unique(E11.seed));
audit.exp11Latest = latest11;
audit.exp11LatestIsDebug = latestPointsToDebug;
audit.exp11LatestIsFull = latestIsFull;
writeJson(fullfile(R.dir,'audit.json'),audit);

fprintf('\nGate-0 selected replay: PASS (%d/%d rows).\n', ...
    nnz(replay.pass),height(replay));
fprintf(['The full EXP10 forced reproduction remains a separate mandatory ' ...
    'Gate-0 step.\n']);

save(fullfile(R.dir,'workspace.mat'),'audit','replay','summary10','summary11');
finishExperiment(R);


function mustExist(path)
if exist(path,'file') ~= 2
    error('Gate0: required file is missing: %s',path);
end
end


function checkDataset(T,expectedRows,expectedSeeds,label)
assert(height(T) == expectedRows, ...
    'Gate0: %s has %d rows, expected %d.',label,height(T),expectedRows);
assert(ismember('seed',T.Properties.VariableNames), ...
    'Gate0: %s has no seed column.',label);
assert(numel(unique(T.seed)) == expectedSeeds, ...
    'Gate0: %s has %d seeds, expected %d.', ...
    label,numel(unique(T.seed)),expectedSeeds);
end


function value = passFail(tf)
if tf, value = 'PASS'; else, value = 'FAIL'; end
end


function writeJson(path,value)
fid = fopen(path,'w');
if fid < 0, error('Gate0: cannot open %s.',path); end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end


function value = normalizePath(value)
value = strrep(value,'\','/');
end
