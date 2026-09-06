function exp14e_preregistered_holdout(resumeDir)
%EXP14E_PREREGISTERED_HOLDOUT Frozen 100-seed selected-candidate validation.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp14eRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=87778193 || registryLeaves~=58
    error('exp14e: frozen registry hash mismatch.');
end
[groupSeed,groupCell]=holdoutGroups(R);
nGroup=numel(groupSeed); batchSize=12;

if isempty(resumeDir)
    runScriptIsolated('test_exp14e_holdout_contracts');
    expRun=startExperiment('exp14e_preregistered_holdout', ...
        ['Frozen 100-seed selected adaptive-ACK/scaled-access holdout; ' ...
        'Holm primary family; ALOHA mandatory boundary.']);
    snapshotFreeze(expRun.dir);
    writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')),'registryHash',registryHash, ...
        'registryLeaves',registryLeaves,'firstSeed',R.seeds(1), ...
        'lastSeed',R.seeds(end),'policyParametersMayChange',false, ...
        'matrixMayChange',false,'primaryFamilySize',6, ...
        'performanceInspectedBeforeOpen',false);
    writeJson(fullfile(expRun.dir,'holdout_opened.json'),opened);
    rows=repmat(exp14eEmptyRow(),0,1);
    completed=false(nGroup,1);
    fprintf('EXP14E HOLDOUT IS NOW OPEN. Registry hash: %.0f\n',registryHash);
    fprintf('Frozen matrix: %d runs (%d seeds).\n', ...
        R.expectedRuns,numel(R.seeds));
else
    expRun=resumeExperiment(resumeDir,registryHash,registryLeaves);
    [rows,completed]=loadCheckpoint( ...
        fullfile(expRun.dir,'tidy_checkpoint.csv'),groupSeed,groupCell,R);
    fprintf(['EXP14E RESUME: %d complete groups, %d rows recovered; ' ...
        'no performance column inspected.\n'],nnz(completed),numel(rows));
end

checkpoint=fullfile(expRun.dir,'tidy_checkpoint.csv');
pending=find(~completed);
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),12)
        g=indices(q);
        batch{q}=runGroup(groupSeed(g),groupCell(g),R);
    end
    for q=1:numel(batch)
        rows=[rows; batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        indices(1),indices(end),nGroup,numel(rows),R.expectedRuns);
end

tidy=struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
gates=integrityGates(tidy,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
integrityVerdict=struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'totalRuns',height(tidy),'performanceIsIntegrityGate',false, ...
    'negativeResultsRetained',true,'configurationChangePermitted',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP14E integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-34s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp14EHoldout(expRun.dir);
    saveAllFigures(expRun);
    fprintf('\nEXP14E CLAIM VERDICT: %s\n',analysis.claimVerdict.status);
    fprintf('  Holm tests: %d/%d | CSMA cells: %d/%d\n', ...
        analysis.claimVerdict.holmTestsRejected, ...
        analysis.claimVerdict.holmTestsTotal, ...
        analysis.claimVerdict.primaryCellsSupported, ...
        analysis.claimVerdict.primaryCellsTotal);
else
    analysis=struct();
    fprintf('\nEXP14E performance analysis NOT OPENED: integrity failure.\n');
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp14e_preregistered_holdout: integrity gates failed.');
end

end


function rows=runGroup(seedValue,cellIndex,R)

cellDef=R.cells(cellIndex);
base=applyExp14ECell(cellDef.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp14eEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label]=applyExp14EArm(base,arm);
    meta=struct('stage','holdout','scenario',cellDef.id, ...
        'scenarioLabel',cellDef.label,'family','EXP14E fixed arms', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',NaN);
    row=runExp14Cell(cfg,method,label,meta,trace);
    row.candidateFlag=double(strcmp(arm.id,R.candidate));
    row.scaledAccess=double(arm.scaledAccess);
    row.historicalReference=double(arm.historicalReference);
    row.basePAccess=base.mac.pAccess;
    rows(k)=row;
end

end


function [seeds,cells]=holdoutGroups(R)

n=numel(R.seeds)*numel(R.cells);
seeds=zeros(n,1); cells=zeros(n,1); q=0;
for i=1:numel(R.seeds)
    for j=1:numel(R.cells)
        q=q+1; seeds(q)=R.seeds(i); cells(q)=j;
    end
end

end


function gates=integrityGates(T,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
[names,passed,detail]=addGate(names,passed,detail,'registry_contract', ...
    registryHash==87778193 && registryLeaves==58, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d frozen runs',height(T)));
keys=string(T.seed)+"|"+T.scenario+"|"+T.arm;
[names,passed,detail]=addGate(names,passed,detail,'unique_cells', ...
    numel(unique(keys))==height(T),'one row per seed/cell/arm');

groupComplete=true;
declared=sort(string({R.arms.id}))';
for seed=R.seeds'
    for c=R.cells
        Q=T(T.seed==seed & T.scenario==string(c.id),:);
        groupComplete=groupComplete && height(Q)==numel(R.arms) && ...
            isequal(sort(string(Q.arm)),declared);
    end
end
[names,passed,detail]=addGate(names,passed,detail,'complete_paired_groups', ...
    groupComplete,'all seven arms occur once per seed/cell');

eligible=T.DIVERGED==0;
finite=all(isfinite(T.RMSE(eligible)) & isfinite(T.MINSEP(eligible)) & ...
    isfinite(T.MEAN_TRUE_AOI(eligible)) & isfinite(T.OFFERED_UTIL(eligible)));
[names,passed,detail]=addGate(names,passed,detail,'finite_eligible_outputs', ...
    finite,'all nondivergent continuous outcomes are finite');
feedback=string(T.feedbackMode)~="none";
causal=all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI(feedback)>=T.MEAN_TRUE_AOI(feedback)-1e-12);
[names,passed,detail]=addGate(names,passed,detail,'causal_conservatism', ...
    causal,sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));
bounded=all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
[names,passed,detail]=addGate(names,passed,detail,'bounded_memory',bounded, ...
    sprintf('max queue=%d max history=%d',max(T.MAX_QUEUE),max(T.MAX_HISTORY)));
accounting=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT==T.ACK_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=1+1e-12);
[names,passed,detail]=addGate(names,passed,detail,'physical_accounting', ...
    accounting,'terminal accounting and channel busy union close');

crn=true;
for seed=R.seeds'
    for c=R.cells
        idx=T.seed==seed & T.scenario==string(c.id);
        crn=crn && isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.CHANNEL_STATE_HASH(idx)));
    end
end
[names,passed,detail]=addGate(names,passed,detail,'paired_absolute_trace', ...
    crn,'one trace and channel-state realization per seed/cell');

scaled=logical(T.scaledAccess);
expectedP=T.basePAccess;
expectedP(scaled)=min(T.basePAccess(scaled),1./T.N(scaled));
accessOk=all(abs(T.pAccess-expectedP)<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'access_semantics', ...
    accessOk,'all nonhistorical arms scale access; historical arm is frozen');

candidate=string(T.arm)==string(R.candidate);
candidateOk=all(string(T.method(candidate))=="mac-aware-broadcast") && ...
    all(string(T.feedbackMode(candidate))=="adaptive") && ...
    all(T.scaledAccess(candidate)==1) && ...
    all(T.LOAD_GUARD_BLOCKED(candidate)==0) && ...
    all(T.candidateFlag(candidate)==1) && all(T.candidateFlag(~candidate)==0);
[names,passed,detail]=addGate(names,passed,detail,'candidate_semantics', ...
    candidateOk,'selected arm is adaptive, scaled and guard-free');

methodsOk=armSemantics(T);
[names,passed,detail]=addGate(names,passed,detail,'comparator_semantics', ...
    methodsOk,'historical, piggyback, state, belief and P10 contracts match');
busyOk=all(T.MEAN_LOCAL_BUSY>=0 & T.MEAN_LOCAL_BUSY<=1 & ...
    T.MAX_LOCAL_BUSY>=T.MEAN_LOCAL_BUSY & T.MAX_LOCAL_BUSY<=1+1e-12);
[names,passed,detail]=addGate(names,passed,detail,'local_busy_contract', ...
    busyOk,'causal local busy estimates remain in [0,1]');
divergenceOk=all(ismember(T.DIVERGED,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED);
[names,passed,detail]=addGate(names,passed,detail,'divergence_accounting', ...
    divergenceOk,sprintf('%d divergences retained',sum(T.DIVERGED)));
gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function ok=armSemantics(T)

ok=checkArm(T,'access-only','causal-broadcast','hybrid') && ...
    checkArm(T,'historical-hybrid','causal-broadcast','hybrid') && ...
    checkArm(T,'piggyback-scaled','causal-broadcast','piggyback') && ...
    checkArm(T,'state-scaled','state-event','none') && ...
    checkArm(T,'belief-scaled','delayed-ack-belief','hybrid') && ...
    checkArm(T,'periodic-p10-scaled','periodic','none') && ...
    all(T.historicalReference(string(T.arm)=="historical-hybrid")==1) && ...
    all(T.historicalReference(string(T.arm)~="historical-hybrid")==0);

end


function ok=checkArm(T,id,method,mode)

idx=string(T.arm)==string(id);
ok=nnz(idx)>0 && all(string(T.method(idx))==string(method)) && ...
    all(string(T.feedbackMode(idx))==string(mode));

end


function [rows,completed]=loadCheckpoint(path,groupSeed,groupCell,R)

if exist(path,'file')~=2
    error('exp14e: resume checkpoint is missing.');
end
T=readtable(path,'TextType','string','Delimiter',',');
expected=fieldnames(exp14eEmptyRow());
if ~isequal(T.Properties.VariableNames(:),expected)
    error('exp14e: checkpoint schema mismatch.');
end
if height(T)>R.expectedRuns || mod(height(T),numel(R.arms))~=0
    error('exp14e: checkpoint is not group-complete.');
end
completed=false(numel(groupSeed),1);
for g=1:numel(groupSeed)
    id=R.cells(groupCell(g)).id;
    idx=T.seed==groupSeed(g) & T.scenario==string(id);
    if any(idx)
        if nnz(idx)~=numel(R.arms) || ...
                numel(unique(T.arm(idx)))~=numel(R.arms)
            error('exp14e: incomplete checkpoint group.');
        end
        completed(g)=true;
    end
end
if nnz(completed)*numel(R.arms)~=height(T)
    error('exp14e: checkpoint contains undeclared groups.');
end
rows=table2struct(T);
template=exp14eEmptyRow();
charFields=fieldnames(template);
charFields=charFields(structfun(@ischar,template));
for i=1:numel(rows)
    for f=1:numel(charFields)
        rows(i).(charFields{f})=char(string(rows(i).(charFields{f})));
    end
end

end


function expRun=resumeExperiment(runDir,registryHash,registryLeaves)

runDir=char(runDir);
openedPath=fullfile(runDir,'holdout_opened.json');
if exist(openedPath,'file')~=2
    error('exp14e: holdout_opened.json is missing.');
end
opened=jsondecode(fileread(openedPath));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves || ...
        opened.policyParametersMayChange || opened.matrixMayChange
    error('exp14e: opened holdout contract mismatch.');
end
[expRoot,runId]=fileparts(runDir); v=ver('MATLAB');
expRun.name='exp14e_preregistered_holdout'; expRun.runId=runId;
expRun.expRoot=expRoot; expRun.dir=runDir;
expRun.figDir=fullfile(runDir,'figures');
expRun.logFile=fullfile(runDir,'console.log');
expRun.notes='Recovery only; frozen holdout design and completed rows unchanged.';
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',opened.openedAt, ...
    'resumedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes',expRun.notes,'sourceFile',which(expRun.name));
expRun.t0=tic; diary(expRun.logFile); diary on;
fprintf('\nEXP14E RECOVERY ONLY: %s\n',runId);

end


function snapshotFreeze(target)

root=projectRoot();
files={'docs/EXP14E_PREREGISTERED_HOLDOUT_PLAN.md', ...
    'utils/exp14eRegistry.m','utils/applyExp14ECell.m', ...
    'utils/applyExp14EArm.m','utils/exp14eEmptyRow.m', ...
    'utils/applyExp14DArm.m','utils/exp14EmptyRow.m','utils/runExp14Cell.m', ...
    'utils/pairedCI.m','utils/pairedBootstrapCI.m','utils/wilsonCI.m', ...
    'utils/holmAdjustP.m', ...
    'utils/writeTableAtomic.m','simulation/simSwarmSharedMedium.m', ...
    'network/macAwarePolicyConfig.m','network/macAwareLoadGuard.m', ...
    'network/adaptiveStandaloneAckDecision.m','network/advanceSharedMedium.m', ...
    'metrics/computeSharedMediumMetrics.m', ...
    'tests/test_exp14e_holdout_contracts.m', ...
    'experiments/analyzeExp14EHoldout.m', ...
    'experiments/exp14e_preregistered_holdout.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function [names,passed,detail]=addGate(names,passed,detail,name,flag,text)

names{end+1,1}=name;
passed(end+1,1)=logical(flag);
detail{end+1,1}=text;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14e: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
