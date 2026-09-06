function exp14b_holdout_ood(resumeDir)
%EXP14B_HOLDOUT_OOD Frozen fixed-point robustness matrix for EXP14.

if nargin<1, resumeDir=''; end

startup;
close all;

R = exp14Registry();
[registryHash,registryLeaves] = configHash(R);
if registryHash~=201658753 || registryLeaves~=139
    error('exp14b_holdout_ood: frozen registry hash mismatch.');
end

[groupSeed,groupPoint] = oodGroups(R);
nGroup = numel(groupSeed);
batchSize = 12;

if isempty(resumeDir)
    runScriptIsolated('test_exp14_infrastructure');
    expRun = startExperiment('exp14b_holdout_ood', ...
        ['Frozen 100-seed fixed-method secondary/OOD matrix; no retuning ' ...
        'and no performance gate.']);
    snapshotFreeze(expRun.dir);
    writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
    opened = struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')),'registryHash',registryHash, ...
        'firstSeed',R.seeds(1),'lastSeed',R.seeds(end), ...
        'policyParametersMayChange',false);
    writeJson(fullfile(expRun.dir,'holdout_opened.json'),opened);
    allRows = repmat(exp14EmptyRow(),0,1);
    completed = false(nGroup,1);
    fprintf('EXP14B OOD matrix: %d frozen runs.\n',R.expected.oodRuns);
else
    expRun=resumeExperiment(resumeDir,registryHash);
    checkpoint=fullfile(expRun.dir,'tidy_checkpoint.csv');
    [allRows,completed]=loadCheckpoint( ...
        checkpoint,groupSeed,groupPoint,R);
    fprintf(['EXP14B RESUME: %d complete groups and %d rows recovered; ' ...
        'no performance columns inspected.\n'],nnz(completed),numel(allRows));
end

checkpoint = fullfile(expRun.dir,'tidy_checkpoint.csv');
pending=find(~completed);
for first = 1:batchSize:numel(pending)
    last = min(first+batchSize-1,numel(pending));
    indices = pending(first:last);
    batch = cell(numel(indices),1);
    parfor (q = 1:numel(indices),12)
        g = indices(q);
        batch{q} = runOODGroup(groupSeed(g),groupPoint(g),R);
    end
    for q = 1:numel(batch)
        allRows = [allRows; batch{q}(:)]; %#ok<AGROW>
    end
    writetable(struct2table(allRows),checkpoint);
    fprintf('  completed pending groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        indices(1),indices(end),nGroup,numel(allRows),R.expected.oodRuns);
end

tidy = struct2table(allRows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
summary = summarizeRows(tidy,{'family','methodLabel'});
writetable(summary,fullfile(expRun.dir,'summary.csv'));
gates = oodGates(tidy,R);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
verdict = struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'totalRuns',height(tidy),'performanceClaimGate','NONE', ...
    'negativeResultsRetained',true,'configurationChangePermitted',false);
writeJson(fullfile(expRun.dir,'verdict.json'),verdict);

fprintf('\nEXP14B machine gates\n');
for k = 1:height(gates)
    fprintf('  [%-4s] %-34s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        gates.gate{k},gates.detail{k});
end
fprintf('\nEXP14B VERDICT: %s (%d/%d integrity gates)\n', ...
    verdict.status,verdict.gatesPassed,verdict.gatesTotal);

save(fullfile(expRun.dir,'workspace.mat'),'tidy','summary','gates', ...
    'verdict','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp14b_holdout_ood: %d of %d integrity gates failed.', ...
        nnz(gates.passed==0),height(gates));
end

end


function rows = runOODGroup(seedValue,pointIndex,R)

point = R.oodPoints(pointIndex);
base = applyExp14OODPoint(point.id,seedValue);
trace = generateSharedMediumTrace(base);
rows = repmat(exp14EmptyRow(),numel(R.oodMethods),1);

for k = 1:numel(R.oodMethods)
    arm = R.oodMethods(k);
    cfg = base;
    [cfg,method,label] = applyExp14OODMethod(cfg,arm);
    meta = struct('stage','ood','scenario','moderate', ...
        'scenarioLabel','Moderate','family',point.label,'arm',arm.id, ...
        'pointIndex',pointIndex,'parameterValue',NaN);
    rows(k)=runExp14Cell(cfg,method,label,meta,trace);
end

end


function [seeds,pointIndex] = oodGroups(R)

n=numel(R.seeds)*numel(R.oodPoints);
seeds=zeros(n,1); pointIndex=zeros(n,1); k=0;
for iSeed=1:numel(R.seeds)
    for iPoint=1:numel(R.oodPoints)
        k=k+1; seeds(k)=R.seeds(iSeed); pointIndex(k)=iPoint;
    end
end

end


function expRun=resumeExperiment(resumeDir,registryHash)

resumeDir=char(resumeDir);
openedPath=fullfile(resumeDir,'holdout_opened.json');
checkpointPath=fullfile(resumeDir,'tidy_checkpoint.csv');
if ~isfolder(resumeDir) || ~isfile(openedPath) || ~isfile(checkpointPath)
    error('exp14b_holdout_ood: invalid resume directory or artifacts.');
end
opened=jsondecode(fileread(openedPath));
if opened.registryHash~=registryHash || opened.policyParametersMayChange
    error('exp14b_holdout_ood: opened-run registry contract mismatch.');
end
[expRoot,runId]=fileparts(resumeDir);
expRun.name='exp14b_holdout_ood';
expRun.runId=runId;
expRun.expRoot=expRoot;
expRun.dir=resumeDir;
expRun.figDir=fullfile(resumeDir,'figures');
expRun.logFile=fullfile(resumeDir,'console.log');
expRun.notes=['Resumed after external interruption; frozen registry, ' ...
    'configuration and completed rows unchanged.'];
v=ver('MATLAB');
expRun.meta.experiment=expRun.name;
expRun.meta.runId=runId;
expRun.meta.startedAt=opened.openedAt;
expRun.meta.resumedAt=char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
expRun.meta.matlabVersion=sprintf('%s %s',v.Name,v.Version);
expRun.meta.matlabRelease=v.Release;
expRun.meta.computer=computer;
expRun.meta.projectRoot=projectRoot();
expRun.meta.gitCommit='';
expRun.meta.notes=expRun.notes;
expRun.meta.sourceFile=which('exp14b_holdout_ood');
expRun.t0=tic;
diary(expRun.logFile); diary on;
fprintf('\n============================================================\n');
fprintf('RESUME: %s\n',expRun.name);
fprintf('ID    : %s\n',runId);
fprintf('WHEN  : %s\n',expRun.meta.resumedAt);
fprintf('CHANGE: recovery only; frozen OOD design unchanged\n');
fprintf('============================================================\n\n');

end


function [rows,completed]=loadCheckpoint( ...
    checkpoint,groupSeed,groupPoint,R)

T=readtable(checkpoint,'TextType','string');
expectedFields=fieldnames(exp14EmptyRow());
if ~isequal(T.Properties.VariableNames(:),expectedFields)
    error('exp14b_holdout_ood: checkpoint schema mismatch.');
end
if height(T)>R.expected.oodRuns || mod(height(T),6)~=0
    error('exp14b_holdout_ood: checkpoint is not group-complete.');
end
completed=false(numel(groupSeed),1);
matched=false(height(T),1);
for g=1:numel(groupSeed)
    idx=T.seed==groupSeed(g) & T.pointIndex==groupPoint(g);
    n=nnz(idx);
    if n==0, continue; end
    if n~=6 || numel(unique(T.arm(idx)))~=6 || ...
            ~isscalar(unique(T.TRACE_HASH_EXACT(idx))) || ...
            ~isscalar(unique(T.CHANNEL_STATE_HASH(idx)))
        error('exp14b_holdout_ood: checkpoint group %d failed audit.',g);
    end
    completed(g)=true;
    matched=matched|idx;
end
if ~all(matched) || nnz(completed)*6~=height(T)
    error('exp14b_holdout_ood: checkpoint contains undeclared rows.');
end
rows=table2struct(T);

end


function gates = oodGates(T,R)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expected.oodRuns,sprintf('%d frozen OOD runs',height(T)));
keys=string(T.seed)+"|"+string(T.family)+"|"+string(T.arm);
[names,passed,detail]=addGate(names,passed,detail,'unique_cells', ...
    numel(unique(keys))==height(T),'every seed/point/method occurs once');
finiteRows=isfinite(T.RMSE) & isfinite(T.MINSEP) & ...
    isfinite(T.MEAN_TRUE_AOI) & isfinite(T.OFFERED_UTIL);
finite=all(finiteRows | T.DIVERGED==1);
[names,passed,detail]=addGate(names,passed,detail,'finite_outputs',finite, ...
    'required control, freshness and PHY outputs are finite');
feedback=~strcmp(T.feedbackMode,'none');
causal=all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI(feedback)>=T.MEAN_TRUE_AOI(feedback)-1e-12);
[names,passed,detail]=addGate(names,passed,detail,'causal_conservatism', ...
    causal,sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));
bounded=all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
[names,passed,detail]=addGate(names,passed,detail,'bounded_memory',bounded, ...
    sprintf('max queue=%d max history=%d',max(T.MAX_QUEUE),max(T.MAX_HISTORY)));
accounting=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT== ...
    T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT== ...
    T.ACK_RECIPIENT_ATTEMPTS) && all(T.CHANNEL_UTIL<=1+1e-12);
[names,passed,detail]=addGate(names,passed,detail,'physical_accounting', ...
    accounting,['DATA/ACK success, loss and terminal in-flight outcomes ' ...
    'plus channel union close']);
crn=true;
for seed=R.seeds'
    for k=1:numel(R.oodPoints)
        idx=T.seed==seed & strcmp(T.family,R.oodPoints(k).label);
        crn=crn && isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.CHANNEL_STATE_HASH(idx)));
    end
end
[names,passed,detail]=addGate(names,passed,detail,'paired_absolute_trace', ...
    crn,'one channel trace and state realization per seed/OOD point');
divergenceAccounted=all(ismember(T.DIVERGED,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED);
[names,passed,detail]=addGate(names,passed,detail, ...
    'divergence_accounting',divergenceAccounted, ...
    sprintf('%d diverged runs retained as safety failures',sum(T.DIVERGED)));

background=T(strcmp(T.family,'30% background busy'),:);
hidden=T(strcmp(T.family,'hidden terminals'),:);
reverse=T(strcmp(T.family,'reverse-asymmetric ACK'),:);
estimator=T(strcmp(T.family,'C3 estimator'),:);
oodExercised=all(background.BACKGROUND_BUSY_TIME>0) && ...
    sum(hidden.COLLISION_FRAMES)>0 && ...
    all(reverse.stationaryMeanAckLoss>reverse.stationaryMeanDataLoss) && ...
    all(estimator.ESTIMATOR_HASH_EXACT~=0);
[names,passed,detail]=addGate(names,passed,detail,'ood_perturbations_exercised', ...
    oodExercised,'background, hidden collision, ACK asymmetry and C3 noise are active');

gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function S = summarizeRows(T,groups)

[G,S]=findgroups(T(:,groups));
S.n=splitapply(@numel,T.RMSE,G);
S.meanRMSE=splitapply(@nanmeanLocal,T.RMSE,G);
S.safeFailures=splitapply(@sum,T.SAFEFAIL,G);
S.divergences=splitapply(@sum,T.DIVERGED,G);
S.meanTrueAoI=splitapply(@nanmeanLocal,T.MEAN_TRUE_AOI,G);
S.meanOfferedUtil=splitapply(@nanmeanLocal,T.OFFERED_UTIL,G);
S.meanCollisions=splitapply(@nanmeanLocal,T.COLLISION_FRAMES,G);
S.meanEnergyProxyJ=splitapply(@nanmeanLocal,T.ENERGY_PROXY_J,G);

end


function y=nanmeanLocal(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function [names,passed,detail]=addGate( ...
    names,passed,detail,name,flag,textValue)

names{end+1,1}=name; passed(end+1,1)=logical(flag); detail{end+1,1}=textValue;

end


function snapshotFreeze(target)

root=projectRoot();
files={'startup.m','docs/EXP14_HOLDOUT_PLAN.md','docs/EXP14_AMENDMENTS.md', ...
    'utils/exp14Registry.m','utils/exp14ChannelScenarios.m', ...
    'configs/study2Exp14Config.m','utils/applyExp14OODPoint.m', ...
    'utils/applyExp14OODMethod.m','utils/exp14EmptyRow.m', ...
    'utils/runExp14Cell.m','network/sharedMediumConfig.m', ...
    'network/sharedMediumChannelSignature.m', ...
    'network/sharedMediumTerminalCounts.m','network/advanceSharedMedium.m', ...
    'utils/generateSharedMediumTrace.m','simulation/simSwarmSharedMedium.m', ...
    'metrics/computeSharedMediumMetrics.m','experiments/exp14b_holdout_ood.m', ...
    'experiments/analyzeExp14Results.m'};
freezeDir=fullfile(target,'frozen_source');
mkdir(freezeDir);
for k=1:numel(files)
    relative=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freezeDir,relative));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14b_holdout_ood: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
