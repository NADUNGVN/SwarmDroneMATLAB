function exp21d_boundary_continuation(resumeDir)
%EXP21D_BOUNDARY_CONTINUATION Frozen D-STR robustness falsification.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp21dBoundaryRegistry();
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runRequiredTests();
    expRun=startExperiment('exp21d_boundary_continuation', ...
        ['D-STR beacon-loss, management-visibility and rejoin boundary; ' ...
        'no optimization or promotion.']);
    writeJson(fullfile(expRun.dir,'boundary_registry.json'),R);
    writeJson(fullfile(expRun.dir,'boundary_opened.json'),struct( ...
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
T=addScheduleSemantics(T);
writetable(T,fullfile(expRun.dir,'trajectory_tidy.csv'));
S=summaryTable(T);
writetable(S,fullfile(expRun.dir,'summary_valid_replays.csv'));
V=validityTable(T);
writetable(V,fullfile(expRun.dir,'validity_summary.csv'));
P=pairedComparison(T,R);
writetable(P,fullfile(expRun.dir,'paired_boundary_comparison.csv'));
gates=boundaryGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'boundary_gates.csv'));
pass=all(gates.passed==1);
status=ternary(pass,'DSTR_BOUNDARY_STUDY_VALID', ...
    'DSTR_BOUNDARY_STUDY_INVALID');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'clockContinuationPermitted',pass, ...
    'newMethodPromotionAllowed',false, ...
    'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'boundary_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'), ...
    'T','S','V','P','gates','verdict','R');

fprintf('\nEXP21D-B boundary gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP21D-B VERDICT: %s\n',status);
finishExperiment(expRun);
if ~pass, error('exp21d-b: boundary study invalid.'); end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21dBoundaryCell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
dstrTrace=generateExp21dDstrTrace(seedValue,base.swarm.N,R);
conditions=unique(string({R.arms.condition}),'stable');
nativeSchedules=cell(numel(conditions),1);
for j=1:numel(conditions)
    C=buildExp21dBoundaryKernelConfig(base,R,conditions(j));
    nativeSchedules{j}=buildDstrContinuousSchedule( ...
        C,dstrTrace,base.swarm.T);
end
rows=repmat(exp21dBoundaryEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    conditionIndex=find(conditions==string(arm.condition),1);
    [cfg,method,label,details,Q]=applyExp21dBoundaryArm( ...
        base,arm,dstrTrace,nativeSchedules{conditionIndex});
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family', ...
        'EXP21D D-STR boundary continuation', ...
        'arm',arm.id,'pointIndex',k,'parameterValue', ...
        conditionValue(arm,R));
    rows(k)=runExp21dBoundaryCell( ...
        cfg,method,label,meta,trace,details,Q,arm);
end

end


function value=conditionValue(arm,R)

switch char(arm.condition)
    case 'beacon-loss', value=R.beaconErasureProbability;
    case 'churn-rejoin', value=R.churnFrame;
    otherwise, value=0;
end

end


function gates=boundaryGates(T,R,registryHash,registryLeaves)

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
    '30 seeds, two cells and six arms exact');

paired=true;
for seed=R.seeds'
    for c=R.cells
        index=T.seed==seed & string(T.scenario)==string(c.id);
        paired=paired && nnz(index)==numel(R.arms) && ...
            isscalar(unique(T.TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.EXP21C_TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.ESTIMATOR_HASH_EXACT(index))) && ...
            isscalar(unique(T.DSTR_KERNEL_TRACE_HASH_EXACT(index)));
    end
end
add('paired_absolute_traces',paired, ...
    'shared, estimator and D-STR hashes paired within seed/cell');
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

restricted=string(T.arm)==string(R.restrictedArm);
validFlag=all(T.PHYSICAL_REPLAY_VALID==double( ...
    T.KERNEL_PREFIX_MAX_FRAME_DISAGREEMENT==0));
marked=all(T.PHYSICAL_REPLAY_VALID(restricted)==double( ...
    T.KERNEL_PREFIX_MAX_FRAME_DISAGREEMENT(restricted)==0));
add('restricted_composability_marked',validFlag && marked, ...
    sprintf('%d/%d restricted rows physically composable', ...
    sum(T.PHYSICAL_REPLAY_VALID(restricted)),nnz(restricted)));
churn=string(T.arm)==string(R.churnArm);
add('rejoin_path_activated',all(T.KERNEL_CHURN_APPLIED(churn)==1), ...
    sprintf('%d/%d churn rows activated', ...
    sum(T.KERNEL_CHURN_APPLIED(churn)),nnz(churn)));

recipient=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS);
charge=(T.DATA_AIRTIME+T.ACK_AIRTIME+ ...
    T.DSTR_MANAGEMENT_AIRTIME)/12;
add('recipient_and_airtime_accounting',recipient && ...
    all(abs(T.OFFERED_UTIL-charge)<=1e-9) && ...
    all(T.CHANNEL_UTIL<=T.OFFERED_UTIL+1e-9), ...
    'right-censored DATA and fully charged utilization close');
add('protocol_invariants',all(T.INVARIANT_VIOLATIONS==0), ...
    sprintf('%d invariant violations',sum(T.INVARIANT_VIOLATIONS)));
retained=all(ismember(T.SAFEFAIL,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED) && ...
    all(ismember(T.SCHEDULE_TERMINAL_RESOLVED,[0 1])) && ...
    all(ismember(T.SCHEDULE_TERMINAL_COLLISION_FREE,[0 1]));
add('all_failures_retained',retained,sprintf( ...
    '%d unsafe, %d unresolved, %d invalid retained', ...
    sum(T.SAFEFAIL),sum(T.SCHEDULE_TERMINAL_RESOLVED==0), ...
    sum(T.SCHEDULE_TERMINAL_COLLISION_FREE==0)));
add('boundary_scope_only',~R.policyOptimizationAllowed && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted, ...
    'no tuning, method promotion or submission decision');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function S=summaryTable(T)

U=T(T.PHYSICAL_REPLAY_VALID==1,:);
U.RMSE(logical(U.DIVERGED))=NaN;
[group,S]=findgroups(U(:,{'scenario','scenarioLabel','arm', ...
    'methodLabel','armKind','BOUNDARY_CONDITION'}));
S.n=splitapply(@numel,U.RMSE,group);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,group);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,group);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,group);
S.meanChannelUtil=splitapply(@finiteMean,U.CHANNEL_UTIL,group);
S.meanGoodputHz=splitapply(@finiteMean,U.DATA_GOODPUT_HZ,group);
S.meanManagementAttempts=splitapply( ...
    @finiteMean,U.DSTR_MANAGEMENT_ATTEMPTS,group);
S.meanConvergenceSec=splitapply( ...
    @finiteMean,U.DSTR_FIRST_CONVERGENCE_SEC,group);
S.meanRecoveryFrame=splitapply( ...
    @finiteMean,U.DSTR_KERNEL_RECOVERY_FRAME,group);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,group);

end


function V=validityTable(T)

[group,V]=findgroups(T(:,{'scenario','arm','BOUNDARY_CONDITION'}));
V.n=splitapply(@numel,T.PHYSICAL_REPLAY_VALID,group);
V.physicallyComposable=splitapply(@sum,T.PHYSICAL_REPLAY_VALID,group);
V.terminalResolved=splitapply(@sum,T.SCHEDULE_TERMINAL_RESOLVED,group);
V.terminalCollisionFree=splitapply( ...
    @sum,T.SCHEDULE_TERMINAL_COLLISION_FREE,group);
V.terminalFrameAgreement=splitapply( ...
    @sum,T.SCHEDULE_TERMINAL_FRAME_AGREEMENT,group);
V.meanMaxFrameDisagreement=splitapply( ...
    @mean,T.DSTR_KERNEL_MAX_FRAME_DISAGREEMENT,group);
V.meanFalseResolvedNodeFrames=splitapply( ...
    @mean,T.DSTR_KERNEL_FALSE_RESOLVED_NODE_FRAMES,group);

end


function T=addScheduleSemantics(T)
% Warm rows replay a deterministic centralized schedule.  The paired
% native kernel remains useful provenance, but its terminal state is not
% the terminal state of the schedule that was actually replayed.

T.SCHEDULE_TERMINAL_RESOLVED=T.DSTR_KERNEL_FINAL_RESOLVED;
T.SCHEDULE_TERMINAL_COLLISION_FREE= ...
    T.DSTR_KERNEL_FINAL_COLLISION_FREE;
T.SCHEDULE_TERMINAL_FRAME_AGREEMENT= ...
    T.DSTR_KERNEL_FINAL_FRAME_AGREEMENT;
warm=T.WARM_REFERENCE==1;
T.SCHEDULE_TERMINAL_RESOLVED(warm)=1;
T.SCHEDULE_TERMINAL_COLLISION_FREE(warm)=1;
T.SCHEDULE_TERMINAL_FRAME_AGREEMENT(warm)=1;

end


function P=pairedComparison(T,R)

pairs={R.zeroNativeArm,R.zeroWarmArm; ...
    R.lossNativeArm,R.lossWarmArm; ...
    R.lossNativeArm,R.zeroNativeArm; ...
    R.churnArm,R.zeroNativeArm};
metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL'};
rows=cell(0,9);
q=0;
for c=R.cells
    for pair=1:size(pairs,1)
        A=selectRows(T,c.id,pairs{pair,1});
        B=selectRows(T,c.id,pairs{pair,2});
        valid=A.PHYSICAL_REPLAY_VALID==1 & B.PHYSICAL_REPLAY_VALID==1;
        A=A(valid,:); B=B(valid,:);
        for m=1:numel(metrics)
            q=q+1;
            if isempty(A)
                boot=struct('nPairs',0,'meanD',NaN,'lo',NaN,'hi',NaN);
                relative=NaN;
            else
                boot=pairedBootstrapCI(A.(metrics{m}),B.(metrics{m}), ...
                    10000,16037900+q,30);
                relative=boot.meanD/max(mean(B.(metrics{m})),eps);
            end
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
    rows=repmat(exp21dBoundaryEmptyRow(),0,1);
    return;
end
T=readtable(path,'TextType','string');
rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    index=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(index)==numel(R.arms), completed(q)=true;
    elseif any(index), error('exp21d-b: partial checkpoint group.'); end
end

end


function runRequiredTests()

names={'test_exp21d_closed_loop_integration_contracts', ...
    'test_exp21d_boundary_contracts', ...
    'test_exp21d_dstr_kernel_contracts', ...
    'test_exp21c_closed_loop_timing_contracts', ...
    'test_shared_medium_infrastructure'};
for k=1:numel(names), runScriptIsolated(names{k}); end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP21D_BOUNDARY_CONTINUATION_PLAN.md', ...
    'network/simulateDstrScheduling.m', ...
    'network/buildDstrContinuousSchedule.m', ...
    'network/buildDstrWarmContinuousSchedule.m', ...
    'network/advanceSharedMedium.m','network/initSharedMediumState.m', ...
    'network/serviceSchedulerConfig.m', ...
    'utils/exp21dBoundaryRegistry.m', ...
    'utils/applyExp21dBoundaryCell.m', ...
    'utils/buildExp21dBoundaryKernelConfig.m', ...
    'utils/applyExp21dBoundaryArm.m', ...
    'utils/exp21dBoundaryEmptyRow.m', ...
    'utils/runExp21dBoundaryCell.m', ...
    'utils/runExp21dClosedLoopCell.m', ...
    'tests/test_exp21d_boundary_contracts.m', ...
    'tests/test_exp21d_closed_loop_integration_contracts.m', ...
    'experiments/exp21d_boundary_continuation.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

if ~isfolder(runDir), error('exp21d-b: resume directory not found.'); end
opened=jsondecode(fileread(fullfile(runDir,'boundary_opened.json')));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves
    error('exp21d-b: registry differs from the opened run.');
end
[~,runId]=fileparts(runDir);
v=ver('MATLAB');
meta=struct('experiment','exp21d_boundary_continuation', ...
    'runId',runId,'startedAt',opened.openedAt, ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed from complete checkpoint for final housekeeping');
expRun=struct('name','exp21d_boundary_continuation', ...
    'runId',runId,'dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',meta,'t0',tic);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp21d-b: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
