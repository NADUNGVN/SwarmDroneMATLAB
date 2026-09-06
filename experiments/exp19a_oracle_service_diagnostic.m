function exp19a_oracle_service_diagnostic(resumeDir)
%EXP19A_ORACLE_SERVICE_DIAGNOSTIC Development-only service headroom study.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp19aRegistry();
[registryHash,registryLeaves]=configHash(R);
[groupSeed,groupCell]=groups(R);
nGroup=numel(groupSeed);
checkpointName='tidy_checkpoint.csv';

if isempty(resumeDir)
    runScriptIsolated('test_service_scheduler_contracts');
    runScriptIsolated('test_exp19a_contracts');
    runScriptIsolated('test_exp19a_analysis_contracts');
    runScriptIsolated('test_exp19a_end_to_end');
    expRun=startExperiment('exp19a_oracle_service_diagnostic', ...
        ['Development-only oracle/TDMA service action-space diagnostic; ' ...
        'no hypothesis test, manuscript claim or hardware policy claim.']);
    writeJson(fullfile(expRun.dir,'development_registry.json'),R);
    writeJson(fullfile(expRun.dir,'development_opened.json'),struct( ...
        'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'developmentOnly',true,'hypothesisTestsPermitted',false, ...
        'confirmatoryClaimPermitted',false, ...
        'manuscriptClaimPermitted',false, ...
        'hardwarePolicyValidationPermitted',false));
    snapshotSource(expRun.dir);
    rows=repmat(exp19aEmptyRow(),0,1);
    completed=false(nGroup,1);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves);
    [rows,completed]=loadCheckpoint( ...
        fullfile(expRun.dir,checkpointName),groupSeed,groupCell,R);
    fprintf('EXP19A RESUME: %d/%d groups and %d rows recovered.\n', ...
        nnz(completed),nGroup,numel(rows));
end

checkpoint=fullfile(expRun.dir,checkpointName);
pending=find(~completed);
batchSize=12;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    seedBatch=groupSeed(indices);
    cellBatch=groupCell(indices);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),12)
        batch{q}=runGroup(seedBatch(q),cellBatch(q),R);
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
integrityVerdict=struct('status',ternary(all(gates.passed==1), ...
    'PASS','FAIL'),'gatesPassed',nnz(gates.passed), ...
    'gatesTotal',height(gates),'totalRuns',height(tidy), ...
    'developmentOnly',true,'performanceIsIntegrityGate',false, ...
    'negativeResultsRetained',true,'hypothesisTestsRun',false, ...
    'manuscriptClaimPermitted',false, ...
    'hardwarePolicyValidationPermitted',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP19A integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-40s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp19ADevelopment(expRun.dir);
    fprintf('\nEXP19A DEVELOPMENT VERDICT: %s (%d/%d gates)\n', ...
        analysis.verdict.status,analysis.verdict.gatesPassed, ...
        analysis.verdict.gatesTotal);
else
    analysis=struct();
    fprintf('\nEXP19A performance analysis NOT OPENED: integrity failure.\n');
end
save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp19a_oracle_service_diagnostic: integrity failure.');
end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp19ACell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp19aEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label,details]=applyExp19AArm(base,arm);
    meta=struct('stage','development-only','scenario',c.id, ...
        'scenarioLabel',c.label,'family','EXP19A oracle service diagnostic', ...
        'arm',arm.id,'pointIndex',k, ...
        'parameterValue',arm.periodicRateHz);
    rows(k)=runExp19ACell(cfg,method,label,meta,trace,details);
end

end


function [seeds,cells]=groups(R)

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
add('registry_recorded',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('development hash %.0f over %d leaves', ...
    registryHash,registryLeaves));
add('matrix_completeness',height(T)==R.expectedRuns, ...
    sprintf('%d/%d rows',height(T),R.expectedRuns));
keys=string(T.seed)+'|'+string(T.scenario)+'|'+string(T.arm);
add('unique_rows',numel(unique(keys))==height(T), ...
    'one row per seed/context/arm');
add('exact_development_seeds',isequal(unique(T.seed),R.seeds), ...
    'all and only 30 declared development seeds are present');
complete=true;
declared=sort(string({R.arms.id}))';
for seed=R.seeds'
    for c=R.cells
        idx=T.seed==seed & string(T.scenario)==string(c.id);
        complete=complete && nnz(idx)==numel(R.arms) && ...
            isequal(sort(string(T.arm(idx))),declared);
    end
end
add('complete_paired_groups',complete, ...
    'all nine arms occur once in each seed/context group');

crn=true;
for seed=R.seeds'
    for c=R.cells
        idx=T.seed==seed & string(T.scenario)==string(c.id);
        crn=crn && isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.CHANNEL_STATE_HASH(idx))) && ...
            isscalar(unique(T.ESTIMATOR_HASH_EXACT(idx)));
    end
end
add('paired_absolute_trace',crn, ...
    'channel, state and estimator traces match within each group');
eligible=T.DIVERGED==0;
finite=all(isfinite(T.RMSE(eligible)) & ...
    isfinite(T.OFFERED_UTIL(eligible)) & ...
    isfinite(T.MEAN_NODE_GOODPUT_HZ(eligible)) & ...
    isfinite(T.VIRTUAL_DEFICIT_MAX(eligible)) & ...
    isfinite(T.MAX_STARVATION_SEC(eligible)));
add('finite_eligible_outputs',finite, ...
    'all nondivergent control/service outcomes are finite');
feedback=string(T.feedbackMode)~='none';
causal=all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI(feedback)>=T.MEAN_TRUE_AOI(feedback)-1e-12);
add('causal_conservatism',causal, ...
    sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));
bounded=all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
add('bounded_memory',bounded,sprintf('max queue=%d max history=%d', ...
    max(T.MAX_QUEUE),max(T.MAX_HISTORY)));
accounting=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT==T.ACK_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=1+1e-12);
add('physical_accounting',accounting, ...
    'recipient outcomes, in-flight work and busy union close');
serviceAccounting=all(T.SERVICE_COMPLETIONS==T.DATA_DELIVERED) && ...
    all(T.SERVICE_ADMISSIONS>=T.SERVICE_COMPLETIONS) && ...
    all(T.VIRTUAL_DEFICIT_TERMINAL== ...
    T.SERVICE_ADMISSIONS-T.SERVICE_COMPLETIONS);
add('virtual_service_accounting',serviceAccounting, ...
    'Z terminal equals admitted semantic demand minus successful service');

scheduled=ismember(string(T.arm),string(R.scheduledArms));
oracle=ismember(string(T.arm),string(R.oracleArms));
urgency=string(T.arm)=='oracle-urgency-maxweight-piggyback';
deficit=string(T.arm)=='oracle-deficit-maxweight-piggyback';
add('no_scheduled_standalone_ack',all(T.ACK_STANDALONE(scheduled)==0), ...
    'all scheduling/frontier arms emit zero standalone ACK');
add('decision_log_contract', ...
    all(T.SERVICE_DECISION_LOG_VALID(scheduled)==1) && ...
    all(T.SERVICE_DECISIONS(scheduled)>0), ...
    'every scheduled transmission records eligible set and selection');
add('present_past_oracle_only',all(T.FUTURE_RANDOM_READS(oracle)==0) && ...
    all(T.RECEIVER_TRUTH_READS(urgency)>0) && ...
    all(T.RECEIVER_TRUTH_READS(deficit)==0), ...
    'urgency reads receiver truth; neither oracle reads future uniforms');
add('collision_free_scheduled_access', ...
    all(T.ENDOGENOUS_COLLISION_FRAMES(scheduled)==0), ...
    'scheduled arms have no endogenous collision; background remains counted');

baseline=string(T.arm)==string(R.baselineArm);
negative=string(T.arm)==string(R.negativeControl);
causalScheduled=scheduled & ~ismember(string(T.arm),string(R.periodicArms));
periodic=ismember(string(T.arm),string(R.periodicArms));
semantics=all(string(T.schedulerMode(baseline|negative))=='native') && ...
    all(string(T.feedbackMode(baseline))=='piggyback') && ...
    all(string(T.feedbackMode(causalScheduled))=='piggyback') && ...
    all(string(T.method(periodic))=='periodic') && ...
    all(string(T.feedbackMode(periodic))=='none') && ...
    all(string(T.macType(scheduled))=='tdma');
add('arm_semantics',semantics, ...
    'baseline, oracle, collision-free and periodic contracts match registry');
original=true;
for c=R.cells
    idx=string(T.scenario)==string(c.id);
    original=original && all(string(T.originalMacType(idx))==string(c.macType));
end
add('context_access_contract',original, ...
    'all contexts retain their declared original ALOHA/CSMA label');
add('unsafe_runs_retained',all(ismember(T.SAFEFAIL,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED), ...
    sprintf('%d observed safety failures retained',sum(T.SAFEFAIL)));
gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

    function add(name,flag,textValue)
        names{end+1,1}=name;
        passed(end+1,1)=logical(flag);
        detail{end+1,1}=textValue;
    end

end


function [rows,completed]=loadCheckpoint(path,groupSeed,groupCell,R)

if exist(path,'file')~=2
    error('exp19a: resume checkpoint is missing.');
end
T=readtable(path,'TextType','string');
expected=fieldnames(exp19aEmptyRow());
if ~isequal(T.Properties.VariableNames(:),expected)
    error('exp19a: checkpoint schema mismatch.');
end
rows=table2struct(T);
completed=false(numel(groupSeed),1);
for g=1:numel(groupSeed)
    c=R.cells(groupCell(g));
    idx=T.seed==groupSeed(g) & string(T.scenario)==string(c.id);
    if nnz(idx)==0, continue; end
    if nnz(idx)~=numel(R.arms) || ...
            ~isequal(sort(string(T.arm(idx))),sort(string({R.arms.id}))')
        error('exp19a: checkpoint contains an incomplete group.');
    end
    completed(g)=true;
end
if nnz(completed)*numel(R.arms)~=height(T)
    error('exp19a: checkpoint contains undeclared rows.');
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

runDir=char(runDir);
if ~isfolder(runDir), error('exp19a: resume directory is missing.'); end
record=jsondecode(fileread(fullfile(runDir,'development_opened.json')));
if record.registryHash~=registryHash || ...
        record.registryLeaves~=registryLeaves
    error('exp19a: resume registry mismatch.');
end
[expRoot,runId]=fileparts(runDir);
expRun=struct('name','exp19a_oracle_service_diagnostic', ...
    'runId',runId,'expRoot',expRoot,'dir',runDir, ...
    'figDir',fullfile(runDir,'figures'),'t0',tic);
v=ver;
v=v(strcmp({v.Name},'MATLAB'));
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',record.openedAt, ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed development run','sourceFile','');
expRun.logFile=fullfile(runDir,'console.log');
diary(expRun.logFile); diary on;

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP19_SERVICE_AWARE_RESEARCH_PROGRAM.md', ...
    'network/serviceSchedulerConfig.m','network/selectScheduledService.m', ...
    'network/recordServiceAdmission.m', ...
    'network/recordServiceCompletion.m', ...
    'network/updateServiceStarvation.m', ...
    'network/initSharedMediumState.m','network/enqueueBroadcastState.m', ...
    'network/advanceSharedMedium.m','simulation/simSwarmSharedMedium.m', ...
    'utils/exp19aRegistry.m','utils/applyExp19ACell.m', ...
    'utils/applyExp19AArm.m','utils/exp19aEmptyRow.m', ...
    'utils/runExp19ACell.m','utils/evaluateExp19Promotion.m', ...
    'tests/test_service_scheduler_contracts.m', ...
    'tests/test_exp19a_contracts.m', ...
    'tests/test_exp19a_analysis_contracts.m', ...
    'tests/test_exp19a_end_to_end.m', ...
    'experiments/analyzeExp19ADevelopment.m', ...
    'experiments/exp19a_oracle_service_diagnostic.m'};
freeze=fullfile(target,'frozen_source');
if ~isfolder(freeze), mkdir(freeze); end
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp19a: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
