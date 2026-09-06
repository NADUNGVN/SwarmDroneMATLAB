function exp14i_mac_selective_validation(resumeDir)
%EXP14I_MAC_SELECTIVE_VALIDATION Frozen 100-seed MAC-selector holdout.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp14iRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=84940762 || registryLeaves~=52
    error('exp14i: frozen registry hash mismatch.');
end
[groupSeed,groupCell]=holdoutGroups(R);
nGroup=numel(groupSeed); batchSize=12;

if isempty(resumeDir)
    runScriptIsolated('test_exp14i_contracts');
    expRun=startExperiment('exp14i_mac_selective_validation', ...
        ['Frozen 100-seed MAC-selective feedback holdout; six-test Holm ' ...
        'family; N20 mandatory support boundary.']);
    snapshotFreeze(expRun.dir);
    writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')),'registryHash',registryHash, ...
        'registryLeaves',registryLeaves,'firstSeed',R.seeds(1), ...
        'lastSeed',R.seeds(end),'mappingMayChange',false, ...
        'matrixMayChange',false,'primaryFamilySize',R.primaryFamilySize, ...
        'performanceInspectedBeforeOpen',false, ...
        'developmentEvidenceEndsAt','EXP14H');
    writeJson(fullfile(expRun.dir,'holdout_opened.json'),opened);
    rows=repmat(exp14iEmptyRow(),0,1);
    completed=false(nGroup,1);
    fprintf('EXP14I HOLDOUT IS NOW OPEN. Registry hash: %.0f\n',registryHash);
    fprintf('Frozen matrix: %d runs (%d seeds).\n', ...
        R.expectedRuns,numel(R.seeds));
else
    expRun=resumeExperiment(resumeDir,registryHash,registryLeaves);
    [rows,completed]=loadCheckpoint( ...
        fullfile(expRun.dir,'tidy_checkpoint.csv'),groupSeed,groupCell,R);
    fprintf(['EXP14I RESUME: %d complete groups, %d rows recovered; ' ...
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
    'negativeResultsRetained',true,'mappingChangePermitted',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP14I integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-34s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp14IResults(expRun.dir);
    saveAllFigures(expRun);
    fprintf('\nEXP14I CLAIM VERDICT: %s\n',analysis.claimVerdict.status);
    fprintf('  Holm tests: %d/%d | primary cells: %d/%d\n', ...
        analysis.claimVerdict.holmTestsRejected, ...
        analysis.claimVerdict.holmTestsTotal, ...
        analysis.claimVerdict.primaryCellsSupported, ...
        analysis.claimVerdict.primaryCellsTotal);
else
    analysis=struct();
    fprintf('\nEXP14I performance analysis NOT OPENED: integrity failure.\n');
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp14i_mac_selective_validation: integrity gates failed.');
end

end


function rows=runGroup(seedValue,cellIndex,R)

cellDef=R.cells(cellIndex);
base=applyExp14ICell(cellDef.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp14iEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label,route]=applyExp14IArm(base,arm);
    meta=struct('stage','holdout','scenario',cellDef.id, ...
        'scenarioLabel',cellDef.label,'family','EXP14I fixed MAC selector', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',NaN);
    row=runExp14Cell(cfg,method,label,meta,trace);
    row.candidateFlag=double(strcmp(arm.id,R.candidate));
    row.route=route;
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
    registryHash==84940762 && registryLeaves==52, ...
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
    groupComplete,'all four arms occur once per seed/cell');

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

expectedP=min(T.basePAccess,1./T.N);
accessOk=all(abs(T.pAccess-expectedP)<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'access_semantics', ...
    accessOk,'all four arms use analytical access scaling');

candidate=string(T.arm)==string(R.candidate);
csmaCandidate=candidate & string(T.macType)=="csma";
alohaCandidate=candidate & string(T.macType)=="aloha";
routeOk=all(string(T.route(csmaCandidate))=="piggyback") && ...
    all(string(T.feedbackMode(csmaCandidate))=="piggyback") && ...
    all(string(T.route(alohaCandidate))=="adaptive") && ...
    all(string(T.feedbackMode(alohaCandidate))=="adaptive") && ...
    all(T.candidateFlag(candidate)==1) && all(T.candidateFlag(~candidate)==0);
[names,passed,detail]=addGate(names,passed,detail,'selector_semantics', ...
    routeOk,'candidate route depends only on configured MAC type');

armOk=checkArm(T,'fixed-adaptive-scaled','adaptive','adaptive') && ...
    checkArm(T,'fixed-piggyback-scaled','piggyback','piggyback') && ...
    checkArm(T,'access-only-scaled','access-only','hybrid') && ...
    all(T.LOAD_GUARD_BLOCKED(string(T.route)=="adaptive")==0);
[names,passed,detail]=addGate(names,passed,detail,'comparator_semantics', ...
    armOk,'fixed feedback and access-only contracts match');

[aliasOk,maxAliasDifference]=exactAliasGate(T,R);
[names,passed,detail]=addGate(names,passed,detail,'exact_route_alias', ...
    aliasOk,sprintf('max registered outcome difference %.3g', ...
    maxAliasDifference));

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


function ok=checkArm(T,id,route,mode)

idx=string(T.arm)==string(id);
ok=nnz(idx)>0 && all(string(T.route(idx))==string(route)) && ...
    all(string(T.feedbackMode(idx))==string(mode));

end


function [ok,maxDifference]=exactAliasGate(T,R)

fields={'RMSE','MINSEP','SAFEFAIL','DIVERGED','MEAN_TRUE_AOI', ...
    'MEAN_EST_AOI','DATA_ATTEMPTED','ACK_ATTEMPTED','COLLISION_FRAMES', ...
    'CHANNEL_UTIL','OFFERED_UTIL','DATA_AIRTIME','ACK_AIRTIME', ...
    'INVARIANT_VIOLATIONS','TRACE_HASH_EXACT','CHANNEL_STATE_HASH'};
ok=true; maxDifference=0;
for seed=R.seeds'
    for c=R.cells
        A=T(T.seed==seed & T.scenario==string(c.id) & ...
            T.arm==string(R.candidate),:);
        B=T(T.seed==seed & T.scenario==string(c.id) & ...
            T.arm==string(c.routedReference),:);
        if height(A)~=1 || height(B)~=1
            ok=false; continue;
        end
        for f=1:numel(fields)
            a=A.(fields{f}); b=B.(fields{f});
            ok=ok && isequaln(a,b);
            if isfinite(a) && isfinite(b)
                maxDifference=max(maxDifference,abs(a-b));
            end
        end
    end
end

end


function [rows,completed]=loadCheckpoint(path,groupSeed,groupCell,R)

if exist(path,'file')~=2
    error('exp14i: resume checkpoint is missing.');
end
T=readtable(path,'TextType','string','Delimiter',',');
expected=fieldnames(exp14iEmptyRow());
if ~isequal(T.Properties.VariableNames(:),expected)
    error('exp14i: checkpoint schema mismatch.');
end
if height(T)>R.expectedRuns || mod(height(T),numel(R.arms))~=0
    error('exp14i: checkpoint is not group-complete.');
end
completed=false(numel(groupSeed),1);
for g=1:numel(groupSeed)
    id=R.cells(groupCell(g)).id;
    idx=T.seed==groupSeed(g) & T.scenario==string(id);
    if any(idx)
        if nnz(idx)~=numel(R.arms) || ...
                numel(unique(T.arm(idx)))~=numel(R.arms)
            error('exp14i: incomplete checkpoint group.');
        end
        completed(g)=true;
    end
end
if nnz(completed)*numel(R.arms)~=height(T)
    error('exp14i: checkpoint contains undeclared groups.');
end
rows=table2struct(T);
template=exp14iEmptyRow();
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
    error('exp14i: holdout_opened.json is missing.');
end
opened=jsondecode(fileread(openedPath));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves || ...
        opened.mappingMayChange || opened.matrixMayChange
    error('exp14i: opened holdout contract mismatch.');
end
[expRoot,runId]=fileparts(runDir); v=ver('MATLAB');
expRun.name='exp14i_mac_selective_validation'; expRun.runId=runId;
expRun.expRoot=expRoot; expRun.dir=runDir;
expRun.figDir=fullfile(runDir,'figures');
expRun.logFile=fullfile(runDir,'console.log');
expRun.notes='Recovery only; frozen mapping and completed rows unchanged.';
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',opened.openedAt, ...
    'resumedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes',expRun.notes,'sourceFile',which(expRun.name));
expRun.t0=tic; diary(expRun.logFile); diary on;
fprintf('\nEXP14I RECOVERY ONLY: %s\n',runId);

end


function snapshotFreeze(target)

root=projectRoot();
files={'docs/EXP14I_MAC_SELECTIVE_VALIDATION_PLAN.md', ...
    'utils/exp14iRegistry.m','utils/applyExp14ICell.m', ...
    'utils/applyExp14IArm.m','utils/exp14iEmptyRow.m', ...
    'utils/applyExp14DArm.m','utils/exp14EmptyRow.m','utils/runExp14Cell.m', ...
    'utils/pairedCI.m','utils/pairedBootstrapCI.m','utils/wilsonCI.m', ...
    'utils/holmAdjustP.m','utils/writeTableAtomic.m', ...
    'simulation/simSwarmSharedMedium.m','network/macAwarePolicyConfig.m', ...
    'network/adaptiveStandaloneAckDecision.m','network/advanceSharedMedium.m', ...
    'metrics/computeSharedMediumMetrics.m','tests/test_exp14i_contracts.m', ...
    'experiments/analyzeExp14IResults.m', ...
    'experiments/exp14i_mac_selective_validation.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function [names,passed,detail]=addGate(names,passed,detail,name,flag,textValue)

names{end+1,1}=name;
passed(end+1,1)=logical(flag);
detail{end+1,1}=textValue;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14i: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
