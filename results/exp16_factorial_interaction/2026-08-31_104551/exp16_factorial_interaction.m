function exp16_factorial_interaction(resumeDir)
%EXP16_FACTORIAL_INTERACTION Frozen MAC-by-feedback-route holdout.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp16Registry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=89775929 || registryLeaves~=56
    error('exp16: frozen registry hash mismatch.');
end
nGroup=numel(R.seeds); batchSize=12;

if isempty(resumeDir)
    runScriptIsolated('test_exp16_contracts');
    expRun=startExperiment('exp16_factorial_interaction', ...
        ['Frozen 100-seed route-by-MAC interaction holdout; matched 2-by-2 ' ...
        'factorial plus fixed-deadline hybrid references.']);
    snapshotFreeze(expRun.dir);
    writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')),'registryHash',registryHash, ...
        'registryLeaves',registryLeaves,'firstSeed',R.seeds(1), ...
        'lastSeed',R.seeds(end),'designMayChange',false, ...
        'estimandMayChange',false,'primaryFamilySize',R.primaryFamilySize, ...
        'performanceInspectedBeforeOpen',false, ...
        'developmentEvidenceEndsAt','EXP14I');
    writeJson(fullfile(expRun.dir,'holdout_opened.json'),opened);
    rows=repmat(exp16EmptyRow(),0,1);
    completed=false(nGroup,1);
    fprintf('EXP16 HOLDOUT IS NOW OPEN. Registry hash: %.0f\n',registryHash);
    fprintf('Frozen matrix: %d runs (%d seeds).\n', ...
        R.expectedRuns,numel(R.seeds));
else
    expRun=resumeExperiment(resumeDir,registryHash,registryLeaves);
    [rows,completed]=loadCheckpoint( ...
        fullfile(expRun.dir,'tidy_checkpoint.csv'),R);
    fprintf(['EXP16 RESUME: %d complete seeds, %d rows recovered; ' ...
        'no performance column inspected.\n'],nnz(completed),numel(rows));
end

checkpoint=fullfile(expRun.dir,'tidy_checkpoint.csv');
pending=find(~completed);
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),12)
        batch{q}=runGroup(R.seeds(indices(q)),R);
    end
    for q=1:numel(batch)
        rows=[rows; batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  seeds %3d--%3d / %3d; rows %3d / %3d\n', ...
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

fprintf('\nEXP16 integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-36s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp16Results(expRun.dir);
    saveAllFigures(expRun);
    fprintf('\nEXP16 CLAIM VERDICT: %s\n',analysis.claimVerdict.status);
    fprintf('  Holm tests: %d/%d | metric reversals: %d/%d\n', ...
        analysis.claimVerdict.holmTestsRejected, ...
        analysis.claimVerdict.holmTestsTotal, ...
        analysis.claimVerdict.metricsSupported, ...
        analysis.claimVerdict.metricsTotal);
else
    analysis=struct();
    fprintf('\nEXP16 performance analysis NOT OPENED: integrity failure.\n');
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp16_factorial_interaction: integrity gates failed.');
end

end


function rows=runGroup(seedValue,R)

base=applyExp16Cell(seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp16EmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label]=applyExp16Arm(base,arm);
    meta=struct('stage','holdout','scenario',R.baseCell.id, ...
        'scenarioLabel',R.baseCell.label, ...
        'family','EXP16 matched route-by-MAC factorial', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',NaN);
    row=runExp14Cell(cfg,method,label,meta,trace);
    row.route=arm.route;
    row.factorMacAloha=double(strcmp(arm.macType,'aloha'));
    row.factorAdaptive=double(strcmp(arm.route,'adaptive'));
    row.primaryFactorialFlag=double(arm.primaryFactorial);
    row.basePAccess=base.mac.pAccess;
    rows(k)=row;
end

end


function gates=integrityGates(T,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
[names,passed,detail]=addGate(names,passed,detail,'registry_contract', ...
    registryHash==89775929 && registryLeaves==56, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d frozen runs',height(T)));
keys=string(T.seed)+"|"+T.arm;
[names,passed,detail]=addGate(names,passed,detail,'unique_seed_arms', ...
    numel(unique(keys))==height(T),'one row per seed/arm');

declared=sort(string({R.arms.id}))'; groupComplete=true;
for seed=R.seeds'
    Q=T(T.seed==seed,:);
    groupComplete=groupComplete && height(Q)==numel(R.arms) && ...
        isequal(sort(string(Q.arm)),declared);
end
[names,passed,detail]=addGate(names,passed,detail,'complete_matched_groups', ...
    groupComplete,'all six arms occur once per seed');

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
    Q=T(T.seed==seed,:);
    crn=crn && isscalar(unique(Q.TRACE_HASH_EXACT)) && ...
        isscalar(unique(Q.CHANNEL_STATE_HASH)) && ...
        isscalar(unique(Q.CHANNEL_MODEL_SIGNATURE)) && ...
        isscalar(unique(Q.ESTIMATOR_HASH_EXACT));
end
[names,passed,detail]=addGate(names,passed,detail,'cross_mac_absolute_trace', ...
    crn,'one trace/channel/estimator realization per seed across all arms');

route=string(T.route); mac=string(T.macType);
registeredMac=(T.factorMacAloha==1 & mac=="aloha") | ...
    (T.factorMacAloha==0 & mac=="csma");
adaptive=route=="adaptive"; piggy=route=="piggyback";
hybrid=route=="fixed-hybrid";
routeOk=all(registeredMac) && ...
    all(T.factorAdaptive(adaptive)==1) && ...
    all(T.factorAdaptive(~adaptive)==0) && ...
    all(string(T.feedbackMode(adaptive))=="adaptive") && ...
    all(string(T.method(adaptive))=="mac-aware-broadcast") && ...
    all(string(T.feedbackMode(piggy))=="piggyback") && ...
    all(string(T.method(piggy))=="causal-broadcast") && ...
    all(string(T.feedbackMode(hybrid))=="hybrid") && ...
    all(string(T.method(hybrid))=="causal-broadcast");
[names,passed,detail]=addGate(names,passed,detail,'factor_route_semantics', ...
    routeOk,'MAC and feedback-route factors match their method contracts');

decisionOk=all(T.ACK_STANDALONE(piggy)==0) && ...
    all(T.ADAPTIVE_ACK_PERMITTED(~adaptive)==0) && ...
    all(T.ADAPTIVE_ACK_DEFERRED(~adaptive)==0) && ...
    all(T.ADAPTIVE_ACK_FORCED(~adaptive)==0) && ...
    sum(T.ADAPTIVE_ACK_PERMITTED(adaptive & mac=="csma"))>0 && ...
    sum(T.ADAPTIVE_ACK_PERMITTED(adaptive & mac=="aloha"))>0;
[names,passed,detail]=addGate(names,passed,detail,'ack_route_actions', ...
    decisionOk,'standalone/adaptive actions occur only in registered routes');

accessOk=all(abs(T.pAccess-0.20)<1e-12) && ...
    all(abs(T.basePAccess-0.20)<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'matched_access_scaling', ...
    accessOk,'configured and actual pAccess equal 1/N under both MACs');
primaryExpected=ismember(string(T.arm),string(R.primaryArms));
[names,passed,detail]=addGate(names,passed,detail,'primary_factorial_flags', ...
    all(logical(T.primaryFactorialFlag)==primaryExpected), ...
    'only the four registered 2-by-2 cells enter primary estimands');
divergenceOk=all(ismember(T.DIVERGED,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED);
[names,passed,detail]=addGate(names,passed,detail,'divergence_accounting', ...
    divergenceOk,sprintf('%d divergences retained',sum(T.DIVERGED)));

gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function [rows,completed]=loadCheckpoint(path,R)

if exist(path,'file')~=2
    rows=repmat(exp16EmptyRow(),0,1);
    completed=false(numel(R.seeds),1);
    return;
end
T=readtable(path,'TextType','string','Delimiter',',');
required=fieldnames(exp16EmptyRow())';
if ~all(ismember(required,T.Properties.VariableNames))
    error('exp16: checkpoint schema mismatch.');
end
if height(T)>R.expectedRuns || mod(height(T),numel(R.arms))~=0
    error('exp16: checkpoint is not seed-group complete.');
end
completed=false(numel(R.seeds),1);
for g=1:numel(R.seeds)
    idx=T.seed==R.seeds(g);
    if any(idx)
        if nnz(idx)~=numel(R.arms) || ...
                numel(unique(T.arm(idx)))~=numel(R.arms)
            error('exp16: incomplete checkpoint seed group.');
        end
        completed(g)=true;
    end
end
if nnz(completed)*numel(R.arms)~=height(T)
    error('exp16: checkpoint contains undeclared seeds.');
end
rows=table2struct(T);
template=exp16EmptyRow();
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
    error('exp16: holdout_opened.json is missing.');
end
opened=jsondecode(fileread(openedPath));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves || ...
        opened.designMayChange || opened.estimandMayChange
    error('exp16: opened holdout contract mismatch.');
end
[expRoot,runId]=fileparts(runDir); v=ver('MATLAB');
expRun.name='exp16_factorial_interaction'; expRun.runId=runId;
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
fprintf('\nEXP16 RECOVERY ONLY: %s\n',runId);

end


function snapshotFreeze(target)

root=projectRoot();
files={'docs/EXP16_FACTORIAL_INTERACTION_PLAN.md', ...
    'utils/exp16Registry.m','utils/applyExp16Cell.m', ...
    'utils/applyExp16Arm.m','utils/exp16EmptyRow.m', ...
    'utils/exp14EmptyRow.m','utils/runExp14Cell.m', ...
    'utils/pairedCI.m','utils/pairedBootstrapCI.m','utils/wilsonCI.m', ...
    'utils/holmAdjustP.m','utils/writeTableAtomic.m', ...
    'configs/study2Exp14Config.m','utils/exp14ChannelScenarios.m', ...
    'utils/generateSharedMediumTrace.m','network/sharedMediumConfig.m', ...
    'network/sharedMediumChannelSignature.m','network/macAwarePolicyConfig.m', ...
    'network/adaptiveStandaloneAckDecision.m','network/advanceSharedMedium.m', ...
    'simulation/simSwarmSharedMedium.m','metrics/computeSharedMediumMetrics.m', ...
    'tests/test_exp16_contracts.m','tests/test_exp16_analysis_contracts.m', ...
    'experiments/analyzeExp16Results.m', ...
    'experiments/exp16_factorial_interaction.m'};
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
if fid<0, error('exp16: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
