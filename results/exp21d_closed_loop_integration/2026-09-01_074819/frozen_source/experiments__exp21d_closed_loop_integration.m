function exp21d_closed_loop_integration(resumeDir)
%EXP21D_CLOSED_LOOP_INTEGRATION Frozen D-STR closed-loop comparison.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp21dClosedLoopRegistry();
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runRequiredTests();
    expRun=startExperiment('exp21d_closed_loop_integration', ...
        ['D-STR native acquisition on the continuous closed-loop event ' ...
        'timeline; prior-art integration only.']);
    writeJson(fullfile(expRun.dir,'integration_registry.json'),R);
    writeJson(fullfile(expRun.dir,'integration_opened.json'),struct( ...
        'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'policyOptimizationAllowed',false, ...
        'submissionClaimPermitted',false));
    snapshotSource(expRun.dir);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves);
end

[rows,completed]=loadCheckpoint(expRun.dir,R);
[seeds,cells]=groups(R);
pending=find(~completed);
checkpoint=fullfile(expRun.dir,'trajectory_checkpoint.csv');
batchSize=6;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    index=pending(first:last);
    selectedSeeds=seeds(index);
    selectedCells=cells(index);
    batch=cell(numel(index),1);
    for q=1:numel(index)
        batch{q}=runGroup(selectedSeeds(q),selectedCells(q),R);
    end
    for q=1:numel(batch), rows=[rows;batch{q}(:)]; end %#ok<AGROW>
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %2d--%2d / %2d; rows %3d / %3d\n', ...
        index(1),index(end),numel(seeds),numel(rows),R.expectedRuns);
end

T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'trajectory_tidy.csv'));
S=summaryTable(T);
writetable(S,fullfile(expRun.dir,'summary.csv'));
P=pairedComparison(T,R);
writetable(P,fullfile(expRun.dir,'paired_integration_comparison.csv'));
gates=integrationGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'integration_gates.csv'));
pass=all(gates.passed==1);
status=ternary(pass,'DSTR_CLOSED_LOOP_INTEGRATION_VALID', ...
    'DSTR_CLOSED_LOOP_INTEGRATION_INVALID');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'boundaryContinuationPermitted',pass, ...
    'newMethodPromotionAllowed',false, ...
    'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'integration_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','P','gates','verdict','R');

fprintf('\nEXP21D-CL integration gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP21D-CL VERDICT: %s\n',status);
finishExperiment(expRun);
if ~pass, error('exp21d-cl: closed-loop integration invalid.'); end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21dClosedLoopCell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp21dClosedLoopEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label,details]=applyExp21dClosedLoopArm(base,arm);
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family', ...
        'EXP21D D-STR closed-loop integration', ...
        'arm',arm.id,'pointIndex',k, ...
        'parameterValue',arm.periodicRateHz);
    rows(k)=runExp21dClosedLoopCell( ...
        cfg,method,label,meta,trace,details);
end

end


function gates=integrationGates(T,R,registryHash,registryLeaves)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
key=string(T.seed)+'|'+string(T.scenario)+'|'+string(T.arm);
add('matrix_complete_unique',height(T)==R.expectedRuns && ...
    numel(unique(key))==height(T),sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
add('exact_seed_cell_arm_coverage',isequal(unique(T.seed),R.seeds) && ...
    isequal(sort(unique(string(T.scenario))), ...
        sort(reshape(string({R.cells.id}),[],1))) && ...
    isequal(sort(unique(string(T.arm))), ...
        sort(reshape(string({R.arms.id}),[],1))), ...
    '30 seeds, two cells and three arms exact');

paired=true;
dstrPaired=true;
for seed=R.seeds'
    for c=R.cells
        index=T.seed==seed & string(T.scenario)==string(c.id);
        paired=paired && nnz(index)==numel(R.arms) && ...
            isscalar(unique(T.TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.EXP21C_TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.ESTIMATOR_HASH_EXACT(index)));
        d=index & ismember(string(T.arm),[string(R.nativeArm) string(R.warmArm)]);
        dstrPaired=dstrPaired && nnz(d)==2 && ...
            isscalar(unique(T.DSTR_KERNEL_TRACE_HASH_EXACT(d))) && ...
            isscalar(unique(T.DSTR_KERNEL_CONFIG_HASH(d)));
    end
end
add('paired_absolute_shared_traces',paired, ...
    'channel, clock and estimator hashes match within seed/cell');
add('paired_dstr_kernel_traces',dstrPaired, ...
    'native and oracle-warm derive from the same D-STR realization');

dstr=ismember(string(T.arm),[string(R.nativeArm) string(R.warmArm)]);
native=string(T.arm)==string(R.nativeArm);
warm=string(T.arm)==string(R.warmArm);
airtime=8*96/250e3;
add('causal_information_contract',all(T.FUTURE_RANDOM_READS(dstr)==0) && ...
    all(T.RECEIVER_TRUTH_READS(dstr)==0) && ...
    all(T.LOCAL_SCHEDULE_ONLY(dstr)==1), ...
    'zero future-random and receiver-truth decision reads');
add('exact_common_data_airtime',all(abs(T.DATA_AIRTIME- ...
    airtime*T.DATA_ATTEMPTED)<=1e-9), ...
    'all arms use 96 B / 250 kbit/s exact DATA airtime');
add('all_dstr_opportunities_served',all( ...
    T.DSTR_DATA_SKIPPED_NO_QUEUE(dstr)==0) && all( ...
    T.DSTR_DATA_ATTEMPTS(dstr)==T.DSTR_SCHEDULED_DATA_ATTEMPTS(dstr)), ...
    sprintf('%d skipped D-STR opportunities', ...
    sum(T.DSTR_DATA_SKIPPED_NO_QUEUE(dstr))));
add('data_collision_witness_match',all( ...
    T.DSTR_DATA_COLLISION_WITNESS_MATCH(dstr)==1), ...
    'event-engine collision frames equal translated kernel witnesses');
add('management_accounting_closes',all( ...
    T.DSTR_MANAGEMENT_ACCOUNTING_CLOSE(dstr)==1) && all(abs( ...
    T.DSTR_MANAGEMENT_AIRTIME(dstr)-airtime* ...
    T.DSTR_MANAGEMENT_ATTEMPTS(dstr))<=1e-9), ...
    'recipient partition and attempt-times-airtime close');
add('cross_plane_nonoverlap',all(T.DSTR_CROSS_PLANE_OVERLAPS(dstr)==0), ...
    sprintf('%d DATA/control overlaps',sum(T.DSTR_CROSS_PLANE_OVERLAPS(dstr))));
nativeStatus=all(ismember(T.DSTR_KERNEL_FINAL_RESOLVED(native),[0 1])) && ...
    all(ismember(T.DSTR_KERNEL_FINAL_COLLISION_FREE(native),[0 1])) && ...
    all(ismember(T.DSTR_KERNEL_FINAL_FRAME_AGREEMENT(native),[0 1]));
add('native_kernel_status_retained',nativeStatus,sprintf( ...
    '%d unresolved, %d physically invalid, %d disagreeing retained', ...
    sum(T.DSTR_KERNEL_FINAL_RESOLVED(native)==0), ...
    sum(T.DSTR_KERNEL_FINAL_COLLISION_FREE(native)==0), ...
    sum(T.DSTR_KERNEL_FINAL_FRAME_AGREEMENT(native)==0)));
add('warm_reference_has_no_management',all( ...
    T.DSTR_MANAGEMENT_ATTEMPTS(warm)==0) && all( ...
    T.DSTR_FIRST_CONVERGENCE_SEC(warm)==0), ...
    'oracle-warm removes attempts and begins valid at t=0');

recipient=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS);
charge=T.DATA_AIRTIME+T.ACK_AIRTIME;
charge(dstr)=charge(dstr)+T.DSTR_MANAGEMENT_AIRTIME(dstr);
charged=all(abs(T.OFFERED_UTIL-charge/12)<=1e-9) && ...
    all(T.CHANNEL_UTIL<=T.OFFERED_UTIL+1e-9);
add('recipient_and_airtime_accounting',recipient && charged, ...
    'terminal DATA partition and fully charged utilization close');
add('protocol_invariants',all(T.INVARIANT_VIOLATIONS==0), ...
    sprintf('%d invariant violations',sum(T.INVARIANT_VIOLATIONS)));
retained=all(ismember(T.SAFEFAIL,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED) && all(isfinite(T.OFFERED_UTIL));
add('all_failures_retained',retained,sprintf('%d unsafe retained', ...
    sum(T.SAFEFAIL)));
add('integration_scope_only',~R.policyOptimizationAllowed && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted, ...
    'no superiority threshold, policy promotion or submission claim');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function S=summaryTable(T)

U=T;
U.RMSE(logical(U.DIVERGED))=NaN;
[group,S]=findgroups(U(:,{'scenario','scenarioLabel','arm', ...
    'methodLabel','armKind','schedulerMode'}));
S.n=splitapply(@numel,U.RMSE,group);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,group);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,group);
S.meanChannelUtil=splitapply(@finiteMean,U.CHANNEL_UTIL,group);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,group);
S.meanDataGoodputHz=splitapply(@finiteMean,U.DATA_GOODPUT_HZ,group);
S.meanManagementAttempts=splitapply( ...
    @finiteMean,U.DSTR_MANAGEMENT_ATTEMPTS,group);
S.meanFirstConvergenceSec=splitapply( ...
    @finiteMean,U.DSTR_FIRST_CONVERGENCE_SEC,group);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,group);

end


function P=pairedComparison(T,R)

comparisons={R.nativeArm,R.periodicArm;R.nativeArm,R.warmArm};
metrics={'RMSE','OFFERED_UTIL','MEAN_TRUE_AOI'};
n=numel(R.cells)*size(comparisons,1)*numel(metrics);
P=table('Size',[n 9], ...
    'VariableTypes',{'string','string','string','string','double', ...
        'double','double','double','double'}, ...
    'VariableNames',{'scenario','candidate','reference','metric', ...
        'nPairs','meanDelta','ciLo','ciHi','relativeDelta'});
q=0;
for c=R.cells
    for pair=1:size(comparisons,1)
        A=selectRows(T,c.id,comparisons{pair,1});
        B=selectRows(T,c.id,comparisons{pair,2});
        for m=1:numel(metrics)
            q=q+1;
            x=A.(metrics{m}); y=B.(metrics{m});
            boot=pairedBootstrapCI(x,y,10000,16036900+q,30);
            P.scenario(q)=string(c.id);
            P.candidate(q)=string(comparisons{pair,1});
            P.reference(q)=string(comparisons{pair,2});
            P.metric(q)=string(metrics{m});
            P.nPairs(q)=boot.nPairs;
            P.meanDelta(q)=boot.meanD;
            P.ciLo(q)=boot.lo;
            P.ciHi(q)=boot.hi;
            P.relativeDelta(q)=boot.meanD/max(mean(y),eps);
        end
    end
end

end


function T=selectRows(T,scenario,arm)

T=T(string(T.scenario)==string(scenario) & string(T.arm)==string(arm),:);
T=sortrows(T,'seed');

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
path=fullfile(runDir,'trajectory_checkpoint.csv');
if ~isfile(path)
    rows=repmat(exp21dClosedLoopEmptyRow(),0,1);
    return;
end
T=readtable(path,'TextType','string');
rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    index=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(index)==numel(R.arms), completed(q)=true;
    elseif any(index), error('exp21d-cl: partial checkpoint group.'); end
end

end


function runRequiredTests()

names={'test_exp21d_closed_loop_integration_contracts', ...
    'test_exp21d_dstr_kernel_contracts', ...
    'test_exp21c_closed_loop_timing_contracts', ...
    'test_shared_medium_infrastructure', ...
    'test_shared_medium_end_to_end'};
for k=1:numel(names), runScriptIsolated(names{k}); end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP21D_CLOSED_LOOP_INTEGRATION_PLAN.md', ...
    'network/simulateDstrScheduling.m', ...
    'network/buildDstrContinuousSchedule.m', ...
    'network/buildDstrWarmContinuousSchedule.m', ...
    'network/advanceSharedMedium.m','network/serviceSchedulerConfig.m', ...
    'network/initSharedMediumState.m', ...
    'metrics/computeSharedMediumMetrics.m', ...
    'utils/exp21dClosedLoopRegistry.m', ...
    'utils/applyExp21dClosedLoopCell.m', ...
    'utils/buildExp21dClosedLoopKernelConfig.m', ...
    'utils/applyExp21dClosedLoopArm.m', ...
    'utils/exp21dClosedLoopEmptyRow.m', ...
    'utils/runExp21dClosedLoopCell.m', ...
    'tests/test_exp21d_closed_loop_integration_contracts.m', ...
    'experiments/exp21d_closed_loop_integration.m'};
freeze=fullfile(target,'frozen_source');
mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

if ~isfolder(runDir), error('exp21d-cl: resume directory not found.'); end
path=fullfile(runDir,'integration_opened.json');
opened=jsondecode(fileread(path));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves
    error('exp21d-cl: registry differs from the opened run.');
end
expRun=struct('name','exp21d_closed_loop_integration', ...
    'runId','resume','dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',struct());

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp21d-cl: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
