function exp17_operating_envelope(resumeDir)
%EXP17_OPERATING_ENVELOPE Frozen operating-envelope robustness holdout.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp17Registry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=123727884 || registryLeaves~=122
    error('exp17: frozen registry hash mismatch.');
end
[groupSeed,groupCell]=holdoutGroups(R);
nGroup=numel(groupSeed); batchSize=16;

if isempty(resumeDir)
    runScriptIsolated('test_exp17_contracts');
    runScriptIsolated('test_exp17_analysis_contracts');
    expRun=startExperiment('exp17_operating_envelope', ...
        ['Frozen 100-seed operating-envelope holdout; 48-test core Holm ' ...
        'family plus reverse-asymmetric/hidden-terminal boundaries.']);
    snapshotFreeze(expRun.dir);
    writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')),'registryHash',registryHash, ...
        'registryLeaves',registryLeaves,'firstSeed',R.seeds(1), ...
        'lastSeed',R.seeds(end),'designMayChange',false, ...
        'continuationRuleMayChange',false, ...
        'primaryFamilySize',R.primaryFamilySize, ...
        'performanceInspectedBeforeOpen',false, ...
        'developmentEvidenceEndsAt','EXP16');
    writeJson(fullfile(expRun.dir,'holdout_opened.json'),opened);
    rows=repmat(exp17EmptyRow(),0,1);
    completed=false(nGroup,1);
    fprintf('EXP17 HOLDOUT IS NOW OPEN. Registry hash: %.0f\n',registryHash);
    fprintf('Frozen matrix: %d runs (%d seed/context groups).\n', ...
        R.expectedRuns,nGroup);
else
    expRun=resumeExperiment(resumeDir,registryHash,registryLeaves);
    [rows,completed]=loadCheckpoint( ...
        fullfile(expRun.dir,'tidy_checkpoint.csv'),groupSeed,groupCell,R);
    fprintf(['EXP17 RESUME: %d complete groups, %d rows recovered; ' ...
        'no performance column inspected.\n'],nnz(completed),numel(rows));
end

checkpoint=fullfile(expRun.dir,'tidy_checkpoint.csv');
pending=find(~completed);
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),16)
        g=indices(q);
        batch{q}=runGroup(groupSeed(g),groupCell(g),R);
    end
    for q=1:numel(batch)
        rows=[rows; batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %4d--%4d / %4d; rows %4d / %4d\n', ...
        indices(1),indices(end),nGroup,numel(rows),R.expectedRuns);
end

tidy=struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
gates=integrityGates(tidy,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
integrityVerdict=struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'totalRuns',height(tidy),'performanceIsIntegrityGate',false, ...
    'negativeResultsRetained',true,'designChangePermitted',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP17 integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-36s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp17Results(expRun.dir);
    saveAllFigures(expRun);
    fprintf('\nEXP17 ENVELOPE VERDICT: %s\n',analysis.claimVerdict.status);
    fprintf('  Core supported: %d/%d | continuation gate: %s\n', ...
        analysis.claimVerdict.coreCellsSupported, ...
        analysis.claimVerdict.coreCellsTotal, ...
        analysis.continuationVerdict.status);
else
    analysis=struct();
    fprintf('\nEXP17 performance analysis NOT OPENED: integrity failure.\n');
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp17_operating_envelope: integrity gates failed.');
end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp17Cell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp17EmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label]=applyExp17Arm(base,arm);
    meta=struct('stage','holdout','scenario',c.id, ...
        'scenarioLabel',c.label, ...
        'family','EXP17 operating envelope', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',c.background);
    row=runExp14Cell(cfg,method,label,meta,trace);
    row.route=arm.route;
    row.factorMacAloha=double(strcmp(arm.macType,'aloha'));
    row.factorAdaptive=double(strcmp(arm.route,'adaptive'));
    row.coreFlag=double(strcmp(c.role,'core'));
    row.channelRegime=c.channel;
    row.contextModifier=c.modifier;
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
    registryHash==123727884 && registryLeaves==122, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d frozen runs',height(T)));
keys=string(T.seed)+"|"+T.scenario+"|"+T.arm;
[names,passed,detail]=addGate(names,passed,detail,'unique_seed_context_arms', ...
    numel(unique(keys))==height(T),'one row per seed/context/arm');

declared=sort(string({R.arms.id}))'; groupComplete=true;
for seed=R.seeds'
    for c=R.cells
        Q=T(T.seed==seed & T.scenario==string(c.id),:);
        groupComplete=groupComplete && height(Q)==numel(R.arms) && ...
            isequal(sort(string(Q.arm)),declared);
    end
end
[names,passed,detail]=addGate(names,passed,detail,'complete_matched_groups', ...
    groupComplete,'all four arms occur once per seed/context');

eligible=T.DIVERGED==0;
finite=all(isfinite(T.RMSE(eligible)) & isfinite(T.MINSEP(eligible)) & ...
    isfinite(T.MEAN_TRUE_AOI(eligible)) & isfinite(T.OFFERED_UTIL(eligible)));
[names,passed,detail]=addGate(names,passed,detail,'finite_eligible_outputs', ...
    finite,'all nondivergent outcomes are finite');
causal=all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI>=T.MEAN_TRUE_AOI-1e-12);
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
    accounting,'terminal accounting and busy union close');

crn=true;
for seed=R.seeds'
    for c=R.cells
        Q=T(T.seed==seed & T.scenario==string(c.id),:);
        crn=crn && isscalar(unique(Q.TRACE_HASH_EXACT)) && ...
            isscalar(unique(Q.CHANNEL_STATE_HASH)) && ...
            isscalar(unique(Q.CHANNEL_MODEL_SIGNATURE)) && ...
            isscalar(unique(Q.ESTIMATOR_HASH_EXACT));
    end
end
[names,passed,detail]=addGate(names,passed,detail,'cross_mac_absolute_trace', ...
    crn,'one trace/channel/estimator realization per seed/context');

route=string(T.route); mac=string(T.macType);
adaptive=route=="adaptive"; piggy=route=="piggyback";
semantics=all((T.factorMacAloha==1 & mac=="aloha") | ...
    (T.factorMacAloha==0 & mac=="csma")) && ...
    all(T.factorAdaptive(adaptive)==1) && ...
    all(T.factorAdaptive(piggy)==0) && ...
    all(string(T.feedbackMode(adaptive))=="adaptive") && ...
    all(string(T.method(adaptive))=="mac-aware-broadcast") && ...
    all(string(T.feedbackMode(piggy))=="piggyback") && ...
    all(string(T.method(piggy))=="causal-broadcast");
[names,passed,detail]=addGate(names,passed,detail,'factor_route_semantics', ...
    semantics,'MAC and route factors match their method contracts');
actions=all(T.ACK_STANDALONE(piggy)==0) && ...
    all(T.ADAPTIVE_ACK_PERMITTED(piggy)==0) && ...
    all(T.ADAPTIVE_ACK_DEFERRED(piggy)==0) && ...
    all(T.ADAPTIVE_ACK_FORCED(piggy)==0) && ...
    sum(T.ADAPTIVE_ACK_PERMITTED(adaptive & mac=="csma"))>0 && ...
    sum(T.ADAPTIVE_ACK_PERMITTED(adaptive & mac=="aloha"))>0;
[names,passed,detail]=addGate(names,passed,detail,'ack_route_actions',actions, ...
    'standalone/adaptive actions occur only in adaptive arms');

expectedP=min(0.20,1./T.N);
accessOk=all(abs(T.pAccess-expectedP)<1e-12) && ...
    all(abs(T.basePAccess-expectedP)<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'analytical_access_scaling', ...
    accessOk,'configured and actual pAccess equal min(0.20,1/N)');

contextOk=true;
for c=R.cells
    Q=T(T.scenario==string(c.id),:);
    expectedCore=double(strcmp(c.role,'core'));
    contextOk=contextOk && height(Q)==numel(R.seeds)*numel(R.arms) && ...
        all(Q.N==c.N) && all(abs(Q.backgroundLoad-c.background)<1e-12) && ...
        all(Q.channelRegime==string(c.channel)) && ...
        all(Q.contextModifier==string(c.modifier)) && ...
        all(Q.coreFlag==expectedCore);
end
[names,passed,detail]=addGate(names,passed,detail,'context_semantics', ...
    contextOk,'N/channel/background/modifier/core flags match registry');
divergenceOk=all(ismember(T.DIVERGED,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED);
[names,passed,detail]=addGate(names,passed,detail,'divergence_accounting', ...
    divergenceOk,sprintf('%d divergences retained',sum(T.DIVERGED)));

gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function [rows,completed]=loadCheckpoint(path,groupSeed,groupCell,R)

if exist(path,'file')~=2
    rows=repmat(exp17EmptyRow(),0,1);
    completed=false(numel(groupSeed),1);
    return;
end
T=readtable(path,'TextType','string','Delimiter',',');
required=fieldnames(exp17EmptyRow())';
if ~all(ismember(required,T.Properties.VariableNames))
    error('exp17: checkpoint schema mismatch.');
end
if height(T)>R.expectedRuns || mod(height(T),numel(R.arms))~=0
    error('exp17: checkpoint is not group-complete.');
end
completed=false(numel(groupSeed),1);
for g=1:numel(groupSeed)
    id=R.cells(groupCell(g)).id;
    idx=T.seed==groupSeed(g) & T.scenario==string(id);
    if any(idx)
        if nnz(idx)~=numel(R.arms) || ...
                numel(unique(T.arm(idx)))~=numel(R.arms)
            error('exp17: incomplete checkpoint group.');
        end
        completed(g)=true;
    end
end
if nnz(completed)*numel(R.arms)~=height(T)
    error('exp17: checkpoint contains undeclared groups.');
end
rows=table2struct(T);
template=exp17EmptyRow();
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
    error('exp17: holdout_opened.json is missing.');
end
opened=jsondecode(fileread(openedPath));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves || ...
        opened.designMayChange || opened.continuationRuleMayChange
    error('exp17: opened holdout contract mismatch.');
end
[expRoot,runId]=fileparts(runDir); v=ver('MATLAB');
expRun.name='exp17_operating_envelope'; expRun.runId=runId;
expRun.expRoot=expRoot; expRun.dir=runDir;
expRun.figDir=fullfile(runDir,'figures');
if exist(expRun.figDir,'dir')~=7, mkdir(expRun.figDir); end
expRun.logFile=fullfile(runDir,'console.log');
expRun.notes='Recovery only; frozen design and completed rows unchanged.';
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',opened.openedAt, ...
    'resumedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes',expRun.notes,'sourceFile',which(expRun.name));
expRun.t0=tic; diary(expRun.logFile); diary on;
fprintf('\nEXP17 RECOVERY ONLY: %s\n',runId);

end


function snapshotFreeze(target)

root=projectRoot();
files={'docs/EXP17_OPERATING_ENVELOPE_PLAN.md', ...
    'utils/exp17Registry.m','utils/applyExp17Cell.m', ...
    'utils/applyExp17Arm.m','utils/exp17EmptyRow.m', ...
    'utils/exp14EmptyRow.m','utils/runExp14Cell.m', ...
    'utils/pairedCI.m','utils/pairedBootstrapCI.m','utils/wilsonCI.m', ...
    'utils/holmAdjustP.m','utils/writeTableAtomic.m', ...
    'configs/study2Exp14Config.m','utils/exp14ChannelScenarios.m', ...
    'utils/generateSharedMediumTrace.m','network/sharedMediumConfig.m', ...
    'network/sharedMediumChannelSignature.m','network/macAwarePolicyConfig.m', ...
    'network/adaptiveStandaloneAckDecision.m','network/advanceSharedMedium.m', ...
    'simulation/simSwarmSharedMedium.m','metrics/computeSharedMediumMetrics.m', ...
    'tests/test_exp17_contracts.m','tests/test_exp17_analysis_contracts.m', ...
    'experiments/analyzeExp17Results.m','experiments/exp17_operating_envelope.m'};
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
if fid<0, error('exp17: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
