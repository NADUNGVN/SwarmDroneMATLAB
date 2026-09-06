function exp23a_local_witness_kernel_falsification(resumeDir,variant)
%EXP23A_LOCAL_WITNESS_KERNEL_FALSIFICATION Fresh witness-kernel matrix.

if nargin<1, resumeDir=''; end
if nargin<2, variant='exp23a'; end
startup; close all;
[R,experimentName,studyTag,description]=studyVariant(variant);
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runScriptIsolated('test_elcs_kernel_contracts');
    expRun=startExperiment(experimentName,description);
    writeJson(fullfile(expRun.dir,'kernel_registry.json'),R);
    writeJson(fullfile(expRun.dir,'kernel_opened.json'),struct( ...
        'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'policyOptimizationAllowed',false,'submissionClaimPermitted',false));
    snapshotSource(expRun.dir,studyTag);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves,experimentName);
end

[rows,completed]=loadCheckpoint(expRun.dir,R);
[seeds,cells]=groups(R); pending=find(~completed);
checkpoint=fullfile(expRun.dir,'kernel_checkpoint.csv'); batchSize=4;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending)); index=pending(first:last);
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
S=summaryTable(T); writetable(S,fullfile(expRun.dir,'kernel_summary.csv'));
gates=kernelGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'kernel_gates.csv'));
valid=all(gates.passed==1);
status='ELCS_W_KERNEL_INVALID';
if valid, status='ELCS_W_KERNEL_VALID'; end
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'continuousIntegrationPermitted',valid, ...
    'newMethodPromotionAllowed',false,'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'kernel_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','gates','verdict','R');
fprintf('\n%s local-witness kernel gates\n',studyTag);
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\n%s VERDICT: %s\n',studyTag,status);
finishExperiment(expRun);
if ~valid, error('exp23a: witness kernel study invalid.'); end

end


function [R,experimentName,studyTag,description]=studyVariant(variant)

switch lower(char(variant))
    case 'exp23a'
        R=exp23aWitnessKernelRegistry();
        experimentName='exp23a_local_witness_kernel_falsification';
        studyTag='EXP23A';
        description=['One-hop conflict-witness CLAIM/CERT kernel ' ...
            'falsification with exact byte bounds and fail-silent loss.'];
    case 'exp23b'
        R=exp23bWitnessRetryRegistry();
        experimentName='exp23b_local_witness_retry_validation';
        studyTag='EXP23B';
        description=['Fresh local-witness validation after causal exact-' ...
            'sequence receipt and next-frame retry repair.'];
    otherwise
        error('exp23a: unknown study variant %s.',char(variant));
end

end


function rows=runGroup(seedValue,cellIndex,R)

rows=repmat(exp23aWitnessKernelEmptyRow(),numel(R.conditions),1);
for k=1:numel(R.conditions)
    rows(k)=runExp23aWitnessKernelCell( ...
        seedValue,R.cells(cellIndex),R.conditions(k),R);
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
add('exact_matrix_coverage',coverage, ...
    '100 fresh seeds, two cells and five conditions exact');
add('one_hop_witness_cover',all(T.HIDDEN_CONFLICT_EDGES>0) && ...
    all(T.WITNESS_HASH_EXACT>0) && all(T.MAX_WITNESS_LOAD<=10), ...
    'all hidden conflict edges covered; no response exceeds one MTU');
zero=string(T.condition)==string(R.zeroCondition);
add('zero_loss_liveness',all(T.FINAL_ALL_CERTIFIED(zero)==1) && ...
    all(T.FIRST_ALL_CERTIFIED_FRAME(zero)==1), ...
    sprintf('%d/%d certify in frame one',sum(T.FINAL_ALL_CERTIFIED(zero)), ...
    nnz(zero)));
if isfield(R,'receiptRetryRequired') && R.receiptRetryRequired
    add('zero_loss_nominal_control_bound',all( ...
        T.CONTROL_ATTEMPTS(zero)==T.NOMINAL_CONTROL_ATTEMPT_BOUND(zero)) && ...
        all(T.CONTROL_BYTES(zero)==T.NOMINAL_CONTROL_BYTE_BOUND(zero)) && ...
        all(T.RETRY_CLAIM_ATTEMPTS(zero)==0), ...
        'zero loss uses scheduled epochs exactly and requires no retry');
end
for condition={R.claimLossCondition,R.certificateLossCondition}
    mask=string(T.condition)==string(condition{1});
    fraction=mean(T.FINAL_ALL_CERTIFIED(mask));
    add([strrep(condition{1},'-','_') '_liveness'], ...
        fraction>=R.minimumLossCertificationFraction,sprintf( ...
        'terminal certification %.1f%% (required %.1f%%)', ...
        100*fraction,100*R.minimumLossCertificationFraction));
end
if isfield(R,'receiptRetryRequired') && R.receiptRetryRequired
    loss=string(T.condition)==string(R.claimLossCondition) | ...
        string(T.condition)==string(R.certificateLossCondition);
    add('causal_retry_activated',all(T.RETRY_CLAIM_ATTEMPTS(loss)>0), ...
        sprintf('retry range %.0f--%.0f attempts', ...
        min(T.RETRY_CLAIM_ATTEMPTS(loss)),max(T.RETRY_CLAIM_ATTEMPTS(loss))));
end
data=string(T.condition)==string(R.dataLossCondition);
separation=true;
for seed=R.seeds'
    for c=R.cells
        a=T.seed==seed & string(T.scenario)==string(c.id) & zero;
        b=T.seed==seed & string(T.scenario)==string(c.id) & data;
        separation=separation && isscalar(find(a)) && isscalar(find(b)) && ...
            T.SCHEDULE_STATE_HASH(a)==T.SCHEDULE_STATE_HASH(b);
    end
end
add('data_information_separation',separation && ...
    all(T.SCHEDULED_RECIPIENT_ERASURE(data)>0), ...
    'DATA erasure changes delivery only, never certificate state');
blackout=string(T.condition)==string(R.blackoutCondition);
add('directed_certificate_blackout_boundary', ...
    all(T.FINAL_ALL_CERTIFIED(blackout)==0) && ...
    all(T.BLACKOUT_CLIENT_FINAL_ACTIVE(blackout)==0) && ...
    all(T.FALLBACK_ATTEMPTS(blackout)>0), ...
    sprintf('%d/%d failures retained with target inactive', ...
    nnz(T.FINAL_ALL_CERTIFIED(blackout)==0),nnz(blackout)));
add('edge_safety_all_conditions',all(T.FALSE_VALID_EDGE_FRAMES==0) && ...
    all(T.SCHEDULED_COLLISION_FRAMES==0) && ...
    all(T.CERTIFICATE_WITHOUT_FRESH_CLAIMS==0), ...
    'zero false-valid, scheduled collision and unsupported CERT events');
add('attempt_byte_and_recipient_accounting',all(T.ACCOUNTING_CLOSES==1) && ...
    all(T.CONTROL_ATTEMPT_BOUND_RATIO<=1+1e-12) && ...
    all(T.CONTROL_BYTE_BOUND_RATIO<=1+1e-12) && ...
    all(T.MAX_FALLBACK_ATTEMPTS_PER_NODE_FRAME<=1), ...
    sprintf('max attempt/byte ratios %.6f/%.6f', ...
    max(T.CONTROL_ATTEMPT_BOUND_RATIO),max(T.CONTROL_BYTE_BOUND_RATIO)));
add('causal_information_contract',all(T.FUTURE_RANDOM_READS==0) && ...
    all(T.RECEIVER_TRUTH_READS==0), ...
    'zero future-random and receiver-truth decision reads');
add('all_failures_retained',height(T)==R.expectedRuns, ...
    'no terminal failure row discarded');
add('kernel_scope_only',~R.policyOptimizationAllowed && ...
    ~R.closedLoopClaimPermitted && ~R.newMethodPromotionAllowed && ...
    ~R.submissionClaimPermitted, ...
    'no tuning, closed-loop, promotion or submission claim');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});
    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p); detail{end+1,1}=d;
    end

end


function S=summaryTable(T)

[group,S]=findgroups(T(:,{'scenario','scenarioLabel','condition', ...
    'conditionLabel','conditionKind','N'}));
S.nRuns=splitapply(@numel,T.FINAL_ALL_CERTIFIED,group);
S.certifiedFraction=splitapply(@mean,T.FINAL_ALL_CERTIFIED,group);
S.meanCertifiedNodeFrameFraction=splitapply( ...
    @mean,T.CERTIFIED_NODE_FRAME_FRACTION,group);
S.meanControlAttempts=splitapply(@mean,T.CONTROL_ATTEMPTS,group);
S.meanControlBytes=splitapply(@mean,T.CONTROL_BYTES,group);
S.meanFallbackAttempts=splitapply(@mean,T.FALLBACK_ATTEMPTS,group);
S.meanFallbackCollisions=splitapply(@mean,T.FALLBACK_COLLISION_FRAMES,group);

end


function [seeds,cells]=groups(R)

seeds=repelem(R.seeds,numel(R.cells));
cells=repmat((1:numel(R.cells))',numel(R.seeds),1);

end


function [rows,completed]=loadCheckpoint(runDir,R)

[seeds,cells]=groups(R); completed=false(size(seeds));
path=fullfile(runDir,'kernel_checkpoint.csv');
if ~isfile(path), rows=repmat(exp23aWitnessKernelEmptyRow(),0,1); return; end
T=readtable(path,'TextType','string'); rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    index=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(index)==numel(R.conditions), completed(q)=true;
    elseif any(index), error('exp23a: partial checkpoint group.'); end
end

end


function snapshotSource(target,studyTag)

root=projectRoot();
if strcmp(studyTag,'EXP23B')
    plan='docs/EXP23B_LOCAL_WITNESS_RETRY_PLAN.md';
    registry='utils/exp23bWitnessRetryRegistry.m';
    wrapper='experiments/exp23b_local_witness_retry_validation.m';
else
    plan='docs/EXP23A_LOCAL_WITNESS_KERNEL_PLAN.md';
    registry='utils/exp23aWitnessKernelRegistry.m';
    wrapper='';
end
files={'docs/EXP23_LOCAL_WITNESS_CERTIFICATE_DESIGN.md',plan, ...
    'network/buildConflictWitnessMap.m', ...
    'network/simulateElcsWitnessScheduling.m', ...
    'utils/conflictWitnessPayloadBound.m', ...
    'utils/elcsWitnessKernelConfig.m','utils/generateElcsWitnessTrace.m', ...
    'utils/elcsWitnessTraceHash.m',registry, ...
    'utils/applyExp23aWitnessCondition.m', ...
    'utils/runExp23aWitnessKernelCell.m', ...
    'utils/exp23aWitnessKernelEmptyRow.m', ...
    'experiments/exp23a_local_witness_kernel_falsification.m'};
if ~isempty(wrapper), files{end+1}=wrapper; end
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves,experimentName)

if ~isfolder(runDir), error('exp23a: resume directory not found.'); end
opened=jsondecode(fileread(fullfile(runDir,'kernel_opened.json')));
if opened.registryHash~=registryHash || opened.registryLeaves~=registryLeaves
    error('exp23a: registry differs from opened run.');
end
[~,runId]=fileparts(runDir);
meta=struct('experiment',experimentName, ...
    'runId',runId,'startedAt',opened.openedAt,'matlabVersion',version, ...
    'matlabRelease',version('-release'),'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed frozen witness-kernel checkpoint');
expRun=struct('name',experimentName, ...
    'runId',runId,'dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',meta,'t0',tic);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp23a: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
