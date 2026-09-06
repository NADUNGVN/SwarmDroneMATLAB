function exp21d_clock_composition(resumeDir)
%EXP21D_CLOCK_COMPOSITION Frozen affine-clock D-STR composition study.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp21dClockRegistry();
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runRequiredTests();
    expRun=startExperiment('exp21d_clock_composition', ...
        ['D-STR single-epoch affine-clock composition with a finite-horizon ' ...
        'guard; prior-art boundary only.']);
    writeJson(fullfile(expRun.dir,'clock_registry.json'),R);
    writeJson(fullfile(expRun.dir,'clock_opened.json'),struct( ...
        'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'candidateDesignPermitted',false, ...
        'submissionClaimPermitted',false));
    snapshotSource(expRun.dir);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves);
end

[rows,completed]=loadCheckpoint(expRun.dir,R);
[seeds,cells]=groups(R);
pending=find(~completed);
checkpoint=fullfile(expRun.dir,'trajectory_checkpoint.csv');
batchSize=4;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    index=pending(first:last);
    batch=cell(numel(index),1);
    for q=1:numel(index)
        batch{q}=runGroup(seeds(index(q)),cells(index(q)),R);
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
writetable(P,fullfile(expRun.dir,'paired_clock_comparison.csv'));
gates=clockGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'clock_gates.csv'));
pass=all(gates.passed==1);
status=ternary(pass,'DSTR_AFFINE_CLOCK_COMPOSITION_VALID', ...
    'DSTR_AFFINE_CLOCK_COMPOSITION_INVALID');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'candidateDesignPermitted',pass, ...
    'newMethodPromotionAllowed',false, ...
    'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'clock_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'), ...
    'T','S','P','gates','verdict','R');

fprintf('\nEXP21D-C affine-clock composition gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP21D-C VERDICT: %s\n',status);
finishExperiment(expRun);
if ~pass, error('exp21d-c: affine-clock composition invalid.'); end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21dClosedLoopCell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
dstrTrace=generateExp21dDstrTrace(seedValue,base.swarm.N,R);
C=buildExp21dClosedLoopKernelConfig(base,R);
C.guardSec=R.shortGuardSec;
shortQ=buildDstrContinuousSchedule(C,dstrTrace,base.swarm.T);
C.guardSec=R.missionSafeGuardSec;
missionQ=buildDstrContinuousSchedule(C,dstrTrace,base.swarm.T);

rows=repmat(exp21dClockEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    if strcmp(arm.guardKind,'short'), nativeQ=shortQ;
    else, nativeQ=missionQ; end
    [cfg,method,label,details]=applyExp21dClockArm( ...
        base,arm,nativeQ,trace,R);
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family', ...
        'EXP21D D-STR affine-clock composition', ...
        'arm',arm.id,'pointIndex',k, ...
        'parameterValue',nativeQ.guardSec);
    rows(k)=runExp21dClockCell( ...
        cfg,method,label,meta,trace,details);
end

end


function gates=clockGates(T,R,registryHash,registryLeaves)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
key=string(T.seed)+'|'+string(T.scenario)+'|'+string(T.arm);
add('matrix_complete_unique',height(T)==R.expectedRuns && ...
    numel(unique(key))==height(T),sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
coverage=isequal(unique(T.seed),R.seeds) && ...
    isequal(sort(unique(string(T.scenario))), ...
        sort(reshape(string({R.cells.id}),[],1))) && ...
    isequal(sort(unique(string(T.arm))), ...
        sort(reshape(string({R.arms.id}),[],1)));
add('exact_seed_cell_arm_coverage',coverage, ...
    '30 fresh seeds, two cells and three arms exact');

paired=true;
missionPaired=true;
for seed=R.seeds'
    for c=R.cells
        index=T.seed==seed & string(T.scenario)==string(c.id);
        paired=paired && nnz(index)==numel(R.arms) && ...
            isscalar(unique(T.TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.EXP21C_TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.ESTIMATOR_HASH_EXACT(index))) && ...
            isscalar(unique(T.DSTR_KERNEL_TRACE_HASH_EXACT(index)));
        m=index & ismember(string(T.arm), ...
            [string(R.missionZeroArm) string(R.missionClockArm)]);
        missionPaired=missionPaired && nnz(m)==2 && ...
            isscalar(unique(T.CLOCK_BASE_SCHEDULE_HASH_EXACT(m))) && ...
            isscalar(unique(T.CLOCK_LOGICAL_OPPORTUNITY_HASH_EXACT(m))) && ...
            isscalar(unique(T.DSTR_SCHEDULED_DATA_ATTEMPTS(m))) && ...
            isscalar(unique(T.DSTR_MANAGEMENT_ATTEMPTS(m)));
    end
end
add('paired_absolute_traces',paired, ...
    'channel, clock, estimator and D-STR hashes paired within seed/cell');
add('mission_logical_opportunities_paired',missionPaired, ...
    'mission zero/clock arms share base schedule and logical opportunities');

clock=string(T.arm)==string(R.missionClockArm);
zero=~clock;
declared=all(T.CLOCK_APPLIED(clock)==1) && ...
    all(T.CLOCK_APPLIED(zero)==0) && all( ...
    T.CLOCK_REALIZED_MAX_OFFSET_SEC(clock)<=R.maxOffsetSec+1e-15) && ...
    all(T.CLOCK_REALIZED_MAX_DRIFT_PPM(clock)<=R.maxDriftPpm+1e-12);
add('clock_impairment_declared',declared, ...
    'only affine-clock arm consumes bounded nonzero clock realization');
timing=all(T.CLOCK_TIMING_CONFLICT_FREE==1) && ...
    all(T.CLOCK_MIN_INTERGROUP_GAP_SEC>=-1e-12) && ...
    all(T.CLOCK_MAX_INTRAGROUP_SKEW_SEC<8*96/250e3) && ...
    all(T.CLOCK_EQUATION_MAX_RESIDUAL_SEC<=1e-12) && ...
    all(T.CONTINUOUS_MAX_CLOCK_RESIDUAL<=1e-12);
add('affine_clock_and_guard_certificate',timing,sprintf( ...
    'max residual %.3g s; min gap %.3g s', ...
    max(T.CLOCK_EQUATION_MAX_RESIDUAL_SEC), ...
    min(T.CLOCK_MIN_INTERGROUP_GAP_SEC)));
add('causal_information_contract',all(T.FUTURE_RANDOM_READS==0) && ...
    all(T.RECEIVER_TRUTH_READS==0) && all(T.LOCAL_SCHEDULE_ONLY==1), ...
    'zero future-random and receiver-truth decision reads');
add('all_dstr_opportunities_served',all( ...
    T.DSTR_DATA_SKIPPED_NO_QUEUE==0) && all( ...
    T.DSTR_DATA_ATTEMPTS==T.DSTR_SCHEDULED_DATA_ATTEMPTS), ...
    sprintf('%d skipped opportunities',sum(T.DSTR_DATA_SKIPPED_NO_QUEUE)));
outcomes=all(T.DSTR_DATA_OUTCOME_MISMATCHES==0) && ...
    all(T.DSTR_OBSERVED_DATA_RECIPIENT_SUCCESS== ...
        T.DSTR_EXPECTED_DATA_RECIPIENT_SUCCESS) && ...
    all(T.DSTR_OBSERVED_DATA_RECIPIENT_ERASURE== ...
        T.DSTR_EXPECTED_DATA_RECIPIENT_ERASURE) && ...
    all(T.DSTR_OBSERVED_DATA_RECIPIENT_COLLISION== ...
        T.DSTR_EXPECTED_DATA_RECIPIENT_COLLISION);
add('exact_data_outcome_replay',outcomes, ...
    'scheduled and observed success/erasure/collision counts match');
add('data_collision_witness_match',all( ...
    T.DSTR_DATA_COLLISION_WITNESS_MATCH==1), ...
    'event collision frames equal completed kernel witnesses');
airtime=8*96/250e3;
management=all(T.DSTR_MANAGEMENT_ACCOUNTING_CLOSE==1) && all(abs( ...
    T.DSTR_MANAGEMENT_AIRTIME-airtime* ...
    T.DSTR_MANAGEMENT_ATTEMPTS)<=1e-9);
add('management_accounting_closes',management, ...
    'recipient partitions and management attempt-airtime close');
add('cross_plane_nonoverlap',all(T.DSTR_CROSS_PLANE_OVERLAPS==0), ...
    sprintf('%d overlap witnesses',sum(T.DSTR_CROSS_PLANE_OVERLAPS)));
recipient=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS);
charge=(T.DATA_AIRTIME+T.ACK_AIRTIME+T.DSTR_MANAGEMENT_AIRTIME)/12;
add('recipient_and_airtime_accounting',recipient && ...
    all(abs(T.OFFERED_UTIL-charge)<=1e-9) && ...
    all(T.CHANNEL_UTIL<=T.OFFERED_UTIL+1e-9), ...
    'terminal recipient partition and fully charged utilization close');
add('protocol_invariants',all(T.INVARIANT_VIOLATIONS==0), ...
    sprintf('%d invariant violations',sum(T.INVARIANT_VIOLATIONS)));
retained=all(ismember(T.SAFEFAIL,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED) && ...
    all(ismember(T.DSTR_KERNEL_FINAL_RESOLVED,[0 1])) && ...
    all(ismember(T.DSTR_KERNEL_FINAL_COLLISION_FREE,[0 1]));
add('all_failures_retained',retained,sprintf( ...
    '%d unsafe, %d unresolved, %d invalid retained', ...
    sum(T.SAFEFAIL),sum(T.DSTR_KERNEL_FINAL_RESOLVED==0), ...
    sum(T.DSTR_KERNEL_FINAL_COLLISION_FREE==0)));
add('clock_scope_only',~R.policyOptimizationAllowed && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted && ...
    ~R.candidateDesignPermitted, ...
    'no tuning, candidate selection, promotion or submission decision');
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
    'methodLabel','armKind'}));
S.n=splitapply(@numel,U.RMSE,group);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,group);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,group);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,group);
S.meanChannelUtil=splitapply(@finiteMean,U.CHANNEL_UTIL,group);
S.meanGoodputHz=splitapply(@finiteMean,U.DATA_GOODPUT_HZ,group);
S.meanMinIntergroupGapSec=splitapply( ...
    @finiteMean,U.CLOCK_MIN_INTERGROUP_GAP_SEC,group);
S.meanMaxIntragroupSkewSec=splitapply( ...
    @finiteMean,U.CLOCK_MAX_INTRAGROUP_SKEW_SEC,group);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,group);

end


function P=pairedComparison(T,R)

pairs={R.missionClockArm,R.missionZeroArm; ...
    R.missionZeroArm,R.shortArm};
metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'DATA_GOODPUT_HZ'};
rows=cell(0,9);
q=0;
for c=R.cells
    for pair=1:size(pairs,1)
        A=selectRows(T,c.id,pairs{pair,1});
        B=selectRows(T,c.id,pairs{pair,2});
        for m=1:numel(metrics)
            q=q+1;
            boot=pairedBootstrapCI(A.(metrics{m}),B.(metrics{m}), ...
                10000,16038900+q,30);
            relative=boot.meanD/max(abs(mean(B.(metrics{m}))),eps);
            rows(end+1,:)={string(c.id),string(pairs{pair,1}), ...
                string(pairs{pair,2}),string(metrics{m}),boot.nPairs, ...
                boot.meanD,boot.lo,boot.hi,relative}; %#ok<AGROW>
        end
    end
end
P=cell2table(rows,'VariableNames',{'scenario','candidate','reference', ...
    'metric','nPairs','meanDelta','ciLo','ciHi','relativeDelta'});

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
    rows=repmat(exp21dClockEmptyRow(),0,1);
    return;
end
T=readtable(path,'TextType','string');
rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    index=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(index)==numel(R.arms), completed(q)=true;
    elseif any(index), error('exp21d-c: partial checkpoint group.'); end
end

end


function runRequiredTests()

names={'test_exp21d_clock_composition_contracts', ...
    'test_exp21d_closed_loop_integration_contracts', ...
    'test_exp21d_dstr_kernel_contracts', ...
    'test_exp21c_closed_loop_timing_contracts', ...
    'test_shared_medium_infrastructure'};
for k=1:numel(names), runScriptIsolated(names{k}); end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP21D_CLOCK_COMPOSITION_PLAN.md', ...
    'network/simulateDstrScheduling.m', ...
    'network/buildDstrContinuousSchedule.m', ...
    'network/applyDstrAffineClockSchedule.m', ...
    'network/advanceSharedMedium.m','network/initSharedMediumState.m', ...
    'network/serviceSchedulerConfig.m', ...
    'utils/exp21dClockRegistry.m','utils/applyExp21dClockArm.m', ...
    'utils/exp21dClockEmptyRow.m','utils/runExp21dClockCell.m', ...
    'utils/runExp21dClosedLoopCell.m', ...
    'tests/test_exp21d_clock_composition_contracts.m', ...
    'experiments/exp21d_clock_composition.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

if ~isfolder(runDir), error('exp21d-c: resume directory not found.'); end
opened=jsondecode(fileread(fullfile(runDir,'clock_opened.json')));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves
    error('exp21d-c: registry differs from the opened run.');
end
[~,runId]=fileparts(runDir);
meta=struct('experiment','exp21d_clock_composition', ...
    'runId',runId,'startedAt',opened.openedAt, ...
    'matlabVersion',version,'matlabRelease',version('-release'), ...
    'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed from frozen affine-clock checkpoint');
expRun=struct('name','exp21d_clock_composition', ...
    'runId',runId,'dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',meta,'t0',tic);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp21d-c: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
