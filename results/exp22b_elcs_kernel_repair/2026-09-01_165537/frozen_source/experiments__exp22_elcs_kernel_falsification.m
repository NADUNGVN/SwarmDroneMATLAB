function exp22_elcs_kernel_falsification(resumeDir,variant)
%EXP22_ELCS_KERNEL_FALSIFICATION Frozen ELCS-F safety-kernel study.

if nargin<1, resumeDir=''; end
if nargin<2, variant='v1'; end
startup;
switch lower(char(variant))
    case 'v1'
        R=exp22ElcsKernelRegistry();
        experimentName='exp22_elcs_kernel_falsification';
    case 'v2'
        R=exp22bElcsKernelRegistry();
        experimentName='exp22b_elcs_kernel_repair';
    otherwise
        error('exp22-k: unknown variant %s.',char(variant));
end
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runScriptIsolated('test_elcs_kernel_contracts');
    expRun=startExperiment(experimentName, ...
        'ELCS-F edge-lease safety invariant; no tuning or performance claim.');
    writeJson(fullfile(expRun.dir,'kernel_registry.json'),R);
    writeJson(fullfile(expRun.dir,'kernel_opened.json'),struct( ...
        'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'policyOptimizationAllowed',false, ...
        'closedLoopClaimPermitted',false, ...
        'submissionClaimPermitted',false));
    snapshotSource(expRun.dir,R);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves,experimentName);
end

[rows,completed]=loadCheckpoint(expRun.dir,R);
[seeds,cells]=groups(R);
pending=find(~completed);
checkpoint=fullfile(expRun.dir,'kernel_checkpoint.csv');
batchSize=10;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    index=pending(first:last);
    batch=cell(numel(index),1);
    for q=1:numel(index)
        batch{q}=runGroup(seeds(index(q)),cells(index(q)),R);
    end
    for q=1:numel(batch), rows=[rows;batch{q}(:)]; end %#ok<AGROW>
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        index(1),index(end),numel(seeds),numel(rows),R.expectedRuns);
end

T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'kernel_tidy.csv'));
S=summaryTable(T);
writetable(S,fullfile(expRun.dir,'kernel_summary.csv'));
gates=kernelGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'kernel_gates.csv'));
pass=all(gates.passed==1);
status=ternary(pass,'ELCS_F_KERNEL_VALID', 'ELCS_F_KERNEL_INVALID');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'closedLoopIntegrationPermitted',pass, ...
    'newMethodPromotionAllowed',false, ...
    'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'kernel_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','gates','verdict','R');

fprintf('\nEXP22-K ELCS-F kernel gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP22-K VERDICT: %s\n',status);
finishExperiment(expRun);
if ~pass, error('exp22-k: ELCS-F kernel study invalid.'); end

end


function rows=runGroup(seedValue,cellIndex,R)

cellSpec=R.cells(cellIndex);
base=applyExp21dClosedLoopCell(cellSpec.exp21dCell,seedValue);
probe=elcsKernelConfig(base.swarm.N,R.maxFrames);
baseTrace=generateElcsTrace(seedValue,probe);
rows=repmat(exp22ElcsKernelEmptyRow(),numel(R.conditions),1);
for k=1:numel(R.conditions)
    condition=R.conditions(k);
    [C,T,conditionMeta]=applyExp22ElcsCondition( ...
        base,condition,baseTrace,R);
    rows(k)=runExp22ElcsKernelCell( ...
        seedValue,cellSpec,condition,C,T,conditionMeta);
end

end


function gates=kernelGates(T,R,registryHash,registryLeaves)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
key=string(T.seed)+'|'+string(T.scenario)+'|'+string(T.condition);
add('matrix_complete_unique',height(T)==R.expectedRuns && ...
    numel(unique(key))==height(T),sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
coverage=isequal(unique(T.seed),R.seeds) && ...
    isequal(sort(unique(string(T.scenario))), ...
        sort(reshape(string({R.cells.id}),[],1))) && ...
    isequal(sort(unique(string(T.condition))), ...
        sort(reshape(string({R.conditions.id}),[],1)));
add('exact_seed_cell_condition_coverage',coverage, ...
    '100 fresh seeds, two cells and seven conditions exact');

paired=true;
dataSeparated=true;
for seed=R.seeds'
    for c=R.cells
        index=T.seed==seed & string(T.scenario)==string(c.id);
        paired=paired && nnz(index)==numel(R.conditions) && ...
            isscalar(unique(T.BASE_TRACE_HASH_EXACT(index)));
        zero=index & string(T.condition)==string(R.zeroCondition);
        data=index & string(T.condition)==string(R.dataLossCondition);
        dataSeparated=dataSeparated && nnz(zero)==1 && nnz(data)==1 && ...
            T.SCHEDULE_STATE_HASH(zero)==T.SCHEDULE_STATE_HASH(data);
    end
end
add('paired_absolute_base_traces',paired, ...
    'all conditions share one absolute trace per seed/cell');
add('data_erasure_schedule_separation',dataSeparated, ...
    'zero and DATA-erasure rows have identical schedule-state hashes');

zero=string(T.condition)==string(R.zeroCondition);
add('zero_loss_certification',all(T.FINAL_ALL_CERTIFIED(zero)==1) && ...
    all(isfinite(T.FIRST_ALL_CERTIFIED_FRAME(zero))),sprintf( ...
    '%d/%d zero-loss rows fully certified', ...
    sum(T.FINAL_ALL_CERTIFIED(zero)),nnz(zero)));
add('scheduled_region_collision_free',all( ...
    T.FINAL_SCHEDULED_COLLISION_FREE==1) && ...
    all(T.SCHEDULED_COLLISION_FRAMES==0),sprintf( ...
    '%d scheduled collision frames',sum(T.SCHEDULED_COLLISION_FRAMES)));
safety=all(T.FALSE_VALID_EDGE_FRAMES==0) && ...
    all(T.OWNER_LOCK_VIOLATIONS==0) && ...
    all(T.STALE_GRANT_ACCEPTS==0) && all(T.FUTURE_GRANT_ACCEPTS==0);
add('edge_lease_safety_invariant',safety,sprintf( ...
    '%d false-valid, %d lock violations', ...
    sum(T.FALSE_VALID_EDGE_FRAMES),sum(T.OWNER_LOCK_VIOLATIONS)));

blackout=string(T.condition)==string(R.blackoutCondition);
blackoutSafe=all(T.BLACKOUT_OWNER_LOCK_EXPIRY(blackout)>0) && ...
    all(T.BLACKOUT_CLIENT_GRANT_EXPIRY(blackout)==0) && ...
    all(T.BLACKOUT_CLIENT_FINAL_ACTIVE(blackout)==0);
add('directed_grant_loss_is_conservative',blackoutSafe, ...
    sprintf('%d/%d selected clients remain uncertified', ...
    sum(T.BLACKOUT_CLIENT_FINAL_ACTIVE(blackout)==0),nnz(blackout)));
loss=string(T.condition)==string(R.stateLossCondition);
add('state_loss_recovery',all(isfinite(T.RECOVERY_FRAME(loss))) && ...
    all(T.FINAL_ALL_CERTIFIED(loss)==1),sprintf( ...
    '%d/%d state-loss rows recovered', ...
    sum(isfinite(T.RECOVERY_FRAME(loss))),nnz(loss)));
change=string(T.condition)==string(R.reconfigurationCondition);
fenced=all(isfinite(T.RECONFIGURATION_APPLIED_FRAME(change))) && ...
    all(T.RECONFIGURATION_APPLIED_FRAME(change)> ...
        T.RECONFIGURATION_RELEASE_FENCE(change));
add('owner_reconfiguration_fenced',fenced,sprintf( ...
    '%d/%d reconfigurations applied after fence', ...
    sum(T.RECONFIGURATION_APPLIED_FRAME(change)> ...
        T.RECONFIGURATION_RELEASE_FENCE(change)),nnz(change)));
if isfield(R,'requireReconfigurationRecovery') && ...
        R.requireReconfigurationRecovery
    repaired=all(T.FINAL_ALL_CERTIFIED(change)==1) && ...
        all(T.AUTOMATIC_RECOLOR_COUNT(change)>=1);
    add('owner_reconfiguration_recovers',repaired,sprintf( ...
        '%d/%d terminally certified; %d automatic recolors', ...
        sum(T.FINAL_ALL_CERTIFIED(change)),nnz(change), ...
        sum(T.AUTOMATIC_RECOLOR_COUNT(change))));
end

account=all(T.ACCOUNTING_CLOSES==1) && ...
    all(T.OFFERED_UTILIZATION+1e-12>=T.CHANNEL_UTILIZATION) && ...
    all(T.MANAGEMENT_RECIPIENT_ATTEMPTS== ...
        T.MANAGEMENT_RECIPIENT_SUCCESS+ ...
        T.MANAGEMENT_RECIPIENT_ERASURE+ ...
        T.MANAGEMENT_RECIPIENT_COLLISION) && ...
    all(T.SCHEDULED_RECIPIENT_ATTEMPTS== ...
        T.SCHEDULED_RECIPIENT_SUCCESS+ ...
        T.SCHEDULED_RECIPIENT_ERASURE+ ...
        T.SCHEDULED_RECIPIENT_COLLISION) && ...
    all(T.FALLBACK_RECIPIENT_ATTEMPTS== ...
        T.FALLBACK_RECIPIENT_SUCCESS+ ...
        T.FALLBACK_RECIPIENT_ERASURE+ ...
        T.FALLBACK_RECIPIENT_COLLISION);
add('recipient_and_airtime_accounting',account, ...
    'management, scheduled and fallback partitions and utilization close');
add('causal_information_contract',all(T.FUTURE_RANDOM_READS==0) && ...
    all(T.RECEIVER_TRUTH_READS==0), ...
    'zero future-random and receiver-truth decision reads');
retained=all(ismember(T.FINAL_ALL_CERTIFIED,[0 1])) && ...
    all(isfinite(T.CERTIFIED_NODE_FRAME_FRACTION)) && ...
    all(T.CERTIFIED_NODE_FRAME_FRACTION>=0 & ...
        T.CERTIFIED_NODE_FRAME_FRACTION<=1) && ...
    all(T.FALLBACK_ATTEMPTS>=0) && all(T.FALLBACK_COLLISION_FRAMES>=0);
add('all_boundary_outcomes_retained',retained,sprintf( ...
    '%d noncertified terminals, %d fallback collision frames retained', ...
    sum(T.FINAL_ALL_CERTIFIED==0),sum(T.FALLBACK_COLLISION_FRAMES)));
add('kernel_scope_only',~R.policyOptimizationAllowed && ...
    ~R.closedLoopClaimPermitted && ~R.newMethodPromotionAllowed && ...
    ~R.submissionClaimPermitted, ...
    'no tuning, closed-loop claim, promotion or submission decision');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function S=summaryTable(T)

[group,S]=findgroups(T(:,{'scenario','scenarioLabel','condition', ...
    'conditionLabel','conditionKind'}));
S.n=splitapply(@numel,T.FINAL_ALL_CERTIFIED,group);
S.finalCertified=splitapply(@sum,T.FINAL_ALL_CERTIFIED,group);
S.meanFirstCertifiedFrame=splitapply( ...
    @finiteMean,T.FIRST_ALL_CERTIFIED_FRAME,group);
S.meanCertifiedNodeFrameFraction=splitapply( ...
    @mean,T.CERTIFIED_NODE_FRAME_FRACTION,group);
S.meanRecoveryFrame=splitapply(@finiteMean,T.RECOVERY_FRAME,group);
S.meanAutomaticRecolorCount=splitapply( ...
    @mean,T.AUTOMATIC_RECOLOR_COUNT,group);
S.meanControlAttempts=splitapply(@mean,T.CONTROL_ATTEMPTS,group);
S.meanScheduledAttempts=splitapply(@mean,T.SCHEDULED_ATTEMPTS,group);
S.meanFallbackAttempts=splitapply(@mean,T.FALLBACK_ATTEMPTS,group);
S.meanOfferedUtilization=splitapply(@mean,T.OFFERED_UTILIZATION,group);
S.meanChannelUtilization=splitapply(@mean,T.CHANNEL_UTILIZATION,group);
S.fallbackCollisionFrames=splitapply( ...
    @sum,T.FALLBACK_COLLISION_FRAMES,group);

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function [seeds,cells]=groups(R)

seeds=repelem(R.seeds,numel(R.cells));
cells=repmat((1:numel(R.cells))',numel(R.seeds),1);

end


function [rows,completed]=loadCheckpoint(runDir,R)

[seeds,cells]=groups(R);
completed=false(size(seeds));
path=fullfile(runDir,'kernel_checkpoint.csv');
if ~isfile(path)
    rows=repmat(exp22ElcsKernelEmptyRow(),0,1);
    return;
end
T=readtable(path,'TextType','string');
rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    index=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(index)==numel(R.conditions), completed(q)=true;
    elseif any(index), error('exp22-k: partial checkpoint group.'); end
end

end


function snapshotSource(target,R)

root=projectRoot();
if startsWith(R.version,'EXP22B')
    plan='docs/EXP22B_ELCS_KERNEL_REPAIR_PLAN.md';
    registry='utils/exp22bElcsKernelRegistry.m';
else
    plan='docs/EXP22_ELCS_KERNEL_FALSIFICATION_PLAN.md';
    registry='utils/exp22ElcsKernelRegistry.m';
end
files={'docs/EXP22_EDGE_LEASE_CANDIDATE_DESIGN.md',plan, ...
    'network/buildSenderConflictGraph.m','network/elcsAcceptGrant.m', ...
    'network/simulateElcsScheduling.m','utils/generateElcsTrace.m', ...
    'utils/elcsKernelConfig.m',registry, ...
    'utils/applyExp22ElcsCondition.m', ...
    'utils/exp22ElcsKernelEmptyRow.m', ...
    'utils/runExp22ElcsKernelCell.m', ...
    'tests/test_elcs_kernel_contracts.m', ...
    'experiments/exp22_elcs_kernel_falsification.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun( ...
    runDir,registryHash,registryLeaves,experimentName)

if ~isfolder(runDir), error('exp22-k: resume directory not found.'); end
opened=jsondecode(fileread(fullfile(runDir,'kernel_opened.json')));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves
    error('exp22-k: registry differs from the opened run.');
end
[~,runId]=fileparts(runDir);
meta=struct('experiment',experimentName, ...
    'runId',runId,'startedAt',opened.openedAt, ...
    'matlabVersion',version,'matlabRelease',version('-release'), ...
    'computer',computer,'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed frozen ELCS-F kernel checkpoint');
expRun=struct('name',experimentName, ...
    'runId',runId,'dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',meta,'t0',tic);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp22-k: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
