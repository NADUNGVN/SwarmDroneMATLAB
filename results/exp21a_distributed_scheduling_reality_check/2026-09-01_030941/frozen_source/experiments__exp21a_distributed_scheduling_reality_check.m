function exp21a_distributed_scheduling_reality_check(resumeDir)
%EXP21A_DISTRIBUTED_SCHEDULING_REALITY_CHECK Frozen development study.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp21aRegistry();
[registryHash,registryLeaves]=configHash(R);

if isempty(resumeDir)
    runScriptIsolated('test_exp21a_contracts');
    expRun=startExperiment('exp21a_distributed_scheduling_reality_check', ...
        ['Development/falsification of ideal-versus-distributed scheduling; ' ...
        'no tuning, confirmatory, manuscript, or hardware promotion.']);
    writeJson(fullfile(expRun.dir,'development_registry.json'),R);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'developmentFalsificationOnly',true, ...
        'candidateOptimizationAllowed',false, ...
        'confirmatoryClaimPermitted',false, ...
        'manuscriptClaimPermitted',false, ...
        'hardwareClaimPermitted',false);
    writeJson(fullfile(expRun.dir,'development_opened.json'),opened);
    snapshotSource(expRun.dir);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves);
end

[rows,completed]=loadCheckpoint(expRun.dir,R);
[groupSeed,groupCell]=groups(R);
pending=find(~completed);
checkpoint=fullfile(expRun.dir,'trajectory_checkpoint.csv');
batchSize=8;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    seeds=groupSeed(indices);
    cells=groupCell(indices);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),12)
        batch{q}=runGroup(seeds(q),cells(q),R);
    end
    for q=1:numel(batch)
        rows=[rows;batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        indices(1),indices(end),numel(groupSeed),numel(rows), ...
        R.expectedRuns);
end

T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'trajectory_tidy.csv'));
gates=integrityGates(T,R,expRun.dir,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'integrity_gates.csv'));
integrityVerdict=struct('status',ternary(all(gates.passed==1), ...
    'PASS','FAIL'),'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'runs',height(T), ...
    'developmentFalsificationOnly',true, ...
    'performanceIsIntegrityGate',false, ...
    'negativeResultsRetained',true);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP21A integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-42s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
if all(gates.passed==1)
    analysis=analyzeExp21AResults(expRun.dir);
    fprintf('\nEXP21A DEVELOPMENT VERDICT: %s\n',analysis.verdict.status);
else
    analysis=struct();
    fprintf('\nEXP21A performance analysis NOT OPENED: integrity failure.\n');
end
save(fullfile(expRun.dir,'workspace.mat'),'T','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp21a: integrity failure.');
end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21ACell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp21aEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label,details]=applyExp21AArm(base,arm);
    meta=struct('stage','development-falsification', ...
        'scenario',c.id,'scenarioLabel',c.label, ...
        'family','EXP21A distributed scheduling reality check', ...
        'arm',arm.id,'pointIndex',k, ...
        'parameterValue',arm.periodicRateHz);
    rows(k)=runExp21ACell(cfg,method,label,meta,trace,details);
end

end


function gates=integrityGates(T,R,runDir,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
add('registry_recorded',isfinite(registryHash) && registryLeaves>0 && ...
    isfile(fullfile(runDir,'development_registry.json')), ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));

keys=string(T.seed)+'|'+string(T.scenario)+'|'+string(T.arm);
matrix=height(T)==R.expectedRuns && numel(unique(keys))==height(T);
add('matrix_complete_unique',matrix,sprintf('%d/%d unique rows', ...
    numel(unique(keys)),R.expectedRuns));
add('exact_seeds',isequal(unique(T.seed),R.seeds), ...
    'all and only 30 declared seeds');
coverage=isequal(sort(unique(string(T.scenario))), ...
        sort(string({R.cells.id})')) && ...
    isequal(sort(unique(string(T.arm))),sort(string({R.arms.id})'));
add('exact_cell_arm_coverage',coverage,'8 cells and 7 arms only');

paired=true;
for seed=R.seeds'
    for c=R.cells
        idx=T.seed==seed & string(T.scenario)==string(c.id);
        paired=paired && nnz(idx)==numel(R.arms) && ...
            isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.EXP21_TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.CHANNEL_STATE_HASH(idx))) && ...
            isscalar(unique(T.ESTIMATOR_HASH_EXACT(idx)));
    end
end
add('paired_absolute_traces',paired, ...
    'channel, estimator, proposal, control-loss and clock hashes pair');

causal=all(T.INVARIANT_VIOLATIONS==0) && all(T.FUTURE_RANDOM_READS==0);
add('causality_and_no_future_reads',causal,sprintf( ...
    '%d protocol violations; %d future reads', ...
    sum(T.INVARIANT_VIOLATIONS),sum(T.FUTURE_RANDOM_READS)));
bounded=all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
add('bounded_data_memory',bounded,sprintf('max queue/history %d/%d', ...
    max(T.MAX_QUEUE),max(T.MAX_HISTORY)));
physical=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT==T.ACK_RECIPIENT_ATTEMPTS);
add('data_ack_terminal_accounting',physical, ...
    'DATA and ACK recipient attempts close including terminal frames');
control=all(T.CONTROL_ACCOUNTING_CLOSE==1) && ...
    all(T.CONTROL_RECIPIENT_SUCCESS+T.CONTROL_RECIPIENT_LOSS== ...
    T.CONTROL_RECIPIENT_ATTEMPTS);
add('control_recipient_accounting',control, ...
    'control success plus loss equals attempts');

dist=string(T.schedulerMode)=='distributed-reservation';
local=string(T.schedulerMode)=='local-static-tdma';
ideal=string(T.armKind)=='ideal-reference';
zmac=string(T.arm)=='zmac-like-hybrid';
activated=all(T.RESERVATION_EPOCHS(dist)>0) && ...
    all(T.CONTROL_FRAMES(dist)>0) && all(T.SERVICE_DECISIONS(local)>0) && ...
    all(T.SERVICE_DECISIONS(ideal)>0) && ...
    sum(T.ZMAC_OWNER_ATTEMPTS(zmac))>0 && ...
    sum(T.ZMAC_CONTENTION_ATTEMPTS(zmac))>0;
add('named_mechanisms_activated',activated, ...
    'reservation, local TDMA, ideal TDMA, and Z-MAC paths exercised');
charged=all(T.CHARGED_OFFERED_UTIL>=T.OFFERED_UTIL-1e-12) && ...
    all(T.CONTROL_AIRTIME(dist)>0) && ...
    all(T.CHARGED_OFFERED_UTIL(dist)>T.OFFERED_UTIL(dist));
add('control_airtime_positive_and_charged',charged, ...
    'distributed control blocks DATA and increases charged utilization');
localOnly=all(T.LOCAL_SCHEDULE_ONLY(dist|local)==1) && ...
    all(T.RECEIVER_TRUTH_READS(dist|local)==0);
add('local_schedule_information_only',localOnly, ...
    'local/static and reservation arms do not read receiver truth');

clockRows=(dist|local) & contains(string(T.scenario),'clock');
nominalRows=(dist|local) & contains(string(T.scenario),'nominal');
clockContract=all(T.MAX_ABS_CLOCK_OFFSET_SEC(nominalRows)==0) && ...
    all(T.MAX_ABS_CLOCK_DRIFT_PPM(nominalRows)==0) && ...
    all(T.MAX_ABS_CLOCK_OFFSET_SEC(clockRows)>0) && ...
    all(T.MAX_ABS_CLOCK_OFFSET_SEC(clockRows)<= ...
        R.reservation.clockOffsetMaxSec+1e-15) && ...
    all(T.MAX_ABS_CLOCK_DRIFT_PPM(clockRows)>0) && ...
    all(T.MAX_ABS_CLOCK_DRIFT_PPM(clockRows)<= ...
        R.reservation.clockDriftMaxPpm+1e-12);
add('clock_impairment_contract',clockContract, ...
    'zero in nominal and bounded nonzero in clock cells');

retained=all(ismember(T.SAFEFAIL,[0 1])) && all(T.SAFEFAIL>=T.DIVERGED) && ...
    all(isfinite(T.CHARGED_OFFERED_UTIL));
add('failures_retained_finite_cost',retained,sprintf( ...
    '%d unsafe and %d diverged runs retained', ...
    sum(T.SAFEFAIL),sum(T.DIVERGED)));
snapshot=isfolder(fullfile(runDir,'frozen_source')) && ...
    numel(dir(fullfile(runDir,'frozen_source','*')))>4;
add('frozen_source_snapshot_recorded',snapshot, ...
    'plan, registry, mechanism, runner, analyzer and tests copied');

gates=table(string(names),double(passed),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(name,ok,text)
        names{end+1,1}=name; %#ok<AGROW>
        passed(end+1,1)=logical(ok); %#ok<AGROW>
        detail{end+1,1}=text; %#ok<AGROW>
    end

end


function [seed,cellIndex]=groups(R)

n=numel(R.seeds)*numel(R.cells);
seed=zeros(n,1); cellIndex=zeros(n,1); q=0;
for s=R.seeds'
    for c=1:numel(R.cells)
        q=q+1; seed(q)=s; cellIndex(q)=c;
    end
end

end


function [rows,completed]=loadCheckpoint(runDir,R)

[seed,cellIndex]=groups(R);
completed=false(size(seed));
path=fullfile(runDir,'trajectory_checkpoint.csv');
if ~isfile(path)
    rows=repmat(exp21aEmptyRow(),0,1);
    return;
end
T=readtable(path,'TextType','string');
rows=table2struct(T);
validSeeds=ismember(T.seed,R.seeds);
validCells=ismember(string(T.scenario),string({R.cells.id}));
validArms=ismember(string(T.arm),string({R.arms.id}));
if ~all(validSeeds & validCells & validArms)
    error('exp21a: checkpoint contains an undeclared row.');
end
for q=1:numel(seed)
    c=R.cells(cellIndex(q));
    idx=T.seed==seed(q) & string(T.scenario)==string(c.id);
    if nnz(idx)==numel(R.arms)
        if numel(unique(string(T.arm(idx))))~=numel(R.arms)
            error('exp21a: duplicate/incomplete checkpoint group.');
        end
        completed(q)=true;
    elseif any(idx)
        error('exp21a: partial checkpoint group is not resumable.');
    end
end

end


function runScriptIsolated(name)

state=warning;
cleaner=onCleanup(@() warning(state)); %#ok<NASGU>
run(fullfile(projectRoot(),'tests',[name '.m']));

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

runDir=char(runDir);
if ~isfolder(runDir), error('exp21a: resume directory is missing.'); end
record=jsondecode(fileread(fullfile(runDir,'development_opened.json')));
if record.registryHash~=registryHash || record.registryLeaves~=registryLeaves
    error('exp21a: resume registry mismatch.');
end
[expRoot,runId]=fileparts(runDir);
expRun=struct('name','exp21a_distributed_scheduling_reality_check', ...
    'runId',runId,'expRoot',expRoot,'dir',runDir, ...
    'figDir',fullfile(runDir,'figures'),'t0',tic);
v=ver; v=v(strcmp({v.Name},'MATLAB'));
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',record.openedAt, ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed development/falsification run','sourceFile','');
expRun.logFile=fullfile(runDir,'console.log');
diary(expRun.logFile); diary on;

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP21A_DISTRIBUTED_SCHEDULING_REALITY_CHECK_PLAN.md', ...
    'network/serviceSchedulerConfig.m','network/initSharedMediumState.m', ...
    'network/advanceSharedMedium.m','network/selectScheduledService.m', ...
    'network/distributedReservationStep.m', ...
    'simulation/simSwarmSharedMedium.m', ...
    'utils/generateSharedMediumTrace.m','utils/exp21aRegistry.m', ...
    'utils/applyExp21ACell.m','utils/applyExp21AArm.m', ...
    'utils/exp21aEmptyRow.m','utils/runExp21ACell.m', ...
    'tests/test_exp21a_contracts.m','experiments/analyzeExp21AResults.m', ...
    'experiments/exp21a_distributed_scheduling_reality_check.m'};
freeze=fullfile(target,'frozen_source');
if ~isfolder(freeze), mkdir(freeze); end
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp21a: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
