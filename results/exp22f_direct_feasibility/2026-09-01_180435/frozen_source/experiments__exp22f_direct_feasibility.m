function exp22f_direct_feasibility(resumeDir)
%EXP22F_DIRECT_FEASIBILITY Direct periodic/D-STR feasibility kill test.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp22fFeasibilityRegistry();
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runRequiredTests();
    expRun=startExperiment('exp22f_direct_feasibility', ...
        ['ELCS-F direct common-PHY feasibility against full-mission ' ...
        'periodic static TDMA and native D-STR.']);
    writeJson(fullfile(expRun.dir,'feasibility_registry.json'),R);
    writeJson(fullfile(expRun.dir,'feasibility_opened.json'),struct( ...
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
batchSize=2;
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
D=dominanceTable(T,R);
writetable(D,fullfile(expRun.dir,'dominance.csv'));
gates=integrityGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'integrity_gates.csv'));
integrityPass=all(gates.passed==1);
periodicDominated=any(D.periodicReference==1 & D.dominates==1);
confidenceDominated=any( ...
    D.periodicReference==1 & D.confidenceSupported==1);
if ~integrityPass
    status='ELCS_FEASIBILITY_STUDY_INVALID';
    next='repair_experiment_integrity';
elseif periodicDominated
    status='ELCS_CURRENT_DESIGN_DOMINATED_RETURN_TO_DESIGN';
    next='redesign_allocation_or_control_overhead';
else
    status='ELCS_FEASIBILITY_NONDOMINATED_CONTINUE_REFERENCES';
    next='robustness_and_remaining_direct_references';
end
verdict=struct('status',status,'integrityGatesPassed',sum(gates.passed), ...
    'integrityGatesTotal',height(gates),'rows',height(T), ...
    'periodicDominanceFound',periodicDominated, ...
    'confidenceSupportedPeriodicDominanceFound',confidenceDominated, ...
    'next',next,'robustnessContinuationPermitted', ...
    integrityPass && ~periodicDominated, ...
    'newMethodPromotionAllowed',false,'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'feasibility_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','D','gates','verdict','R');

fprintf('\nEXP22F direct-feasibility integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP22F DECISION: %s\n',status);
finishExperiment(expRun);
if ~integrityPass, error('exp22f: feasibility experiment invalid.'); end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21dClosedLoopCell(c.id,seedValue);
trace=generateSharedMediumTrace(base);

% Native D-STR with the same full-mission guard and paired affine clocks.
DR=exp21dClockRegistry();
DR.missionSafeGuardSec=R.missionSafeGuardSec;
DR.clockLeadTimeSec=R.clockLeadTimeSec;
DR.maxOffsetSec=R.maxOffsetSec;
DR.maxDriftPpm=R.maxDriftPpm;
dstrTrace=generateExp21dDstrTrace(seedValue,base.swarm.N,DR);
DC=buildExp21dClosedLoopKernelConfig(base,DR);
DC.guardSec=R.missionSafeGuardSec;
dstrNative=buildDstrContinuousSchedule(DC,dstrTrace,base.swarm.T);
dstrArm=DR.arms(strcmp({DR.arms.id},DR.missionClockArm));

% Queue-compatible ELCS-F candidate.
ER=exp22eElcsClosedLoopRegistry();
N=base.swarm.N;
EC=elcsKernelConfig(N,R.elcsMaxFrames);
EC.guardSec=R.missionSafeGuardSec;
EC.dataBytes=base.mac.dataBytes;
EC.phyRateBps=base.mac.phyRateBps;
EC.neighborGraph=logical(base.swarm.A);
EC.interferenceMatrix=logical(base.mac.interferenceMatrix);
EC.conflictGraph=buildSenderConflictGraph( ...
    EC.neighborGraph,EC.interferenceMatrix);
EC.managementReach=true(N)-eye(N)>0;
elcsTrace=generateElcsTrace(seedValue,EC);
elcsNative=buildElcsContinuousSchedule(EC,elcsTrace,base.swarm.T);
elcsArm=ER.arms(strcmp({ER.arms.id},ER.clockArm));

rows=repmat(exp22fFeasibilityEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    switch arm.family
        case 'periodic-static'
            [cfg,method,label,details]=applyExp22fStaticArm(base,arm,R);
        case 'prior-art-dstr'
            [cfg,method,~,details]=applyExp21dClockArm( ...
                base,dstrArm,dstrNative,trace,DR);
            label=arm.label;
            details.kind='prior-art-dstr';
        case 'candidate-elcs'
            [cfg,method,~,details]=applyExp22dElcsClockArm( ...
                base,elcsArm,elcsNative,trace,ER);
            label=arm.label;
            details.kind='candidate-elcs';
        otherwise
            error('exp22f: unknown arm family %s.',arm.family);
    end
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family','EXP22F direct feasibility', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',arm.periodicRateHz);
    rows(k)=runExp22fFeasibilityCell( ...
        cfg,method,label,meta,trace,details,arm.family);
end

end


function gates=integrityGates(T,R,registryHash,registryLeaves)

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
add('exact_matrix_coverage',coverage, ...
    '30 fresh seeds, two cells and ten arms exact');
paired=true;
for seed=R.seeds'
    for c=R.cells
        index=T.seed==seed & string(T.scenario)==string(c.id);
        paired=paired && nnz(index)==numel(R.arms) && ...
            isscalar(unique(T.TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.EXP21C_TRACE_HASH_EXACT(index))) && ...
            isscalar(unique(T.ESTIMATOR_HASH_EXACT(index)));
    end
end
add('paired_shared_realizations',paired, ...
    'channel, initial state, estimator and clock draws paired');
add('causal_information_contract',all(T.FUTURE_RANDOM_READS==0) && ...
    all(T.RECEIVER_TRUTH_READS==0) && all(T.LOCAL_SCHEDULE_ONLY==1), ...
    'zero future-random and receiver-truth decision reads');

static=string(T.ENGINE_FAMILY)=="periodic-static";
add('static_guarded_collision_free',all( ...
    T.ENDOGENOUS_COLLISION_FRAMES(static)==0) && all( ...
    T.CONTINUOUS_MAX_CLOCK_RESIDUAL(static)<=1e-12),sprintf( ...
    '%d collision frames; max clock residual %.3g s', ...
    sum(T.ENDOGENOUS_COLLISION_FRAMES(static)), ...
    max(T.CONTINUOUS_MAX_CLOCK_RESIDUAL(static))));
replay=T.REPLAY_FLAG==1;
replayExact=all(T.REPLAY_DATA_SKIPPED_NO_QUEUE(replay)==0) && ...
    all(T.REPLAY_DATA_ATTEMPTS(replay)== ...
        T.REPLAY_DATA_OPPORTUNITIES(replay)) && ...
    all(T.REPLAY_DATA_OUTCOME_MISMATCHES(replay)==0) && ...
    all(T.REPLAY_COLLISION_WITNESS_MATCH(replay)==1) && ...
    all(T.REPLAY_EXPECTED_RECIPIENT_SUCCESS(replay)== ...
        T.REPLAY_OBSERVED_RECIPIENT_SUCCESS(replay)) && ...
    all(T.REPLAY_EXPECTED_RECIPIENT_ERASURE(replay)== ...
        T.REPLAY_OBSERVED_RECIPIENT_ERASURE(replay)) && ...
    all(T.REPLAY_EXPECTED_RECIPIENT_COLLISION(replay)== ...
        T.REPLAY_OBSERVED_RECIPIENT_COLLISION(replay));
add('exact_replay_outcomes',replayExact, ...
    'D-STR and ELCS attempts, recipient masks and collision witnesses match');
replayTiming=all(T.REPLAY_MANAGEMENT_ACCOUNTING_CLOSE(replay)==1) && ...
    all(T.REPLAY_CROSS_PLANE_OVERLAPS(replay)==0) && ...
    all(T.REPLAY_CLOCK_TIMING_SAFE(replay)==1) && ...
    all(T.REPLAY_CLOCK_MIN_GAP_SEC(replay)>=-1e-12) && ...
    all(T.REPLAY_CLOCK_RESIDUAL_SEC(replay)<=1e-12);
add('replay_control_and_timing',replayTiming, ...
    'management partitions, cross-plane separation and clock guards close');
elcs=string(T.ENGINE_FAMILY)=="candidate-elcs";
add('elcs_safety',all(T.ELCS_FINAL_ALL_CERTIFIED(elcs)==1) && ...
    all(T.ELCS_FALSE_VALID_EDGE_FRAMES(elcs)==0) && ...
    all(T.ELCS_OWNER_LOCK_VIOLATIONS(elcs)==0) && ...
    all(T.ELCS_SCHEDULED_COLLISION_FRAMES(elcs)==0), ...
    'ELCS certification, edge locks and scheduled safety remain valid');
dstr=string(T.ENGINE_FAMILY)=="prior-art-dstr";
add('dstr_native_valid',all(T.DSTR_FINAL_RESOLVED(dstr)==1) && ...
    all(T.DSTR_FINAL_COLLISION_FREE(dstr)==1), ...
    'native D-STR resolves and remains physically collision-free');
charge=(T.DATA_AIRTIME+T.ACK_AIRTIME+T.TOTAL_MANAGEMENT_AIRTIME)/12;
recipient=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS);
add('recipient_and_airtime_accounting',recipient && ...
    all(abs(T.TOTAL_OFFERED_UTIL-charge)<=1e-12) && ...
    all(T.CHANNEL_UTIL<=T.TOTAL_OFFERED_UTIL+1e-9), ...
    'recipient partition and all DATA/management attempt-airtime close');
add('closed_loop_invariants',all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.SAFEFAIL==0) && all(T.DIVERGED==0),sprintf( ...
    '%d invariant, %d unsafe and %d divergent rows', ...
    sum(T.INVARIANT_VIOLATIONS),sum(T.SAFEFAIL),sum(T.DIVERGED)));
add('all_outcomes_retained',height(T)==R.expectedRuns && ...
    all(isfinite(T.RMSE)) && all(isfinite(T.TOTAL_OFFERED_UTIL)), ...
    'all favorable and unfavorable performance rows retained');
add('feasibility_scope_only',~R.policyOptimizationAllowed && ...
    ~R.confirmationAllowed && ~R.robustnessContinuationPermitted && ...
    ~R.submissionClaimPermitted, ...
    'no tuning, confirmation, robustness or submission decision');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function D=dominanceTable(T,R)

rows=cell(0,16);
q=0;
for c=R.cells
    E=selectRows(T,c.id,R.elcsArm);
    for arm=R.arms'
        if strcmp(arm.id,R.elcsArm), continue; end
        A=selectRows(T,c.id,arm.id);
        q=q+1;
        rmse=pairedBootstrapCI(A.RMSE,E.RMSE,10000,16047900+2*q,30);
        cost=pairedBootstrapCI(A.TOTAL_OFFERED_UTIL, ...
            E.TOTAL_OFFERED_UTIL,10000,16047901+2*q,30);
        meanERmse=mean(E.RMSE);
        meanECost=mean(E.TOTAL_OFFERED_UTIL);
        dominates=mean(A.RMSE)<= ...
            (1-R.dominanceMargin)*meanERmse && ...
            mean(A.TOTAL_OFFERED_UTIL)<= ...
            (1-R.dominanceMargin)*meanECost;
        confidence=rmse.hi<=-R.dominanceMargin*meanERmse && ...
            cost.hi<=-R.dominanceMargin*meanECost;
        rows(end+1,:)={string(c.id),string(arm.id),string(arm.family), ...
            double(strcmp(arm.family,'periodic-static')),height(A), ...
            mean(A.RMSE),meanERmse,mean(A.TOTAL_OFFERED_UTIL), ...
            meanECost,rmse.meanD,rmse.lo,rmse.hi,cost.meanD, ...
            cost.lo,cost.hi,double(dominates)+2*double(confidence)}; %#ok<AGROW>
    end
end
D=cell2table(rows,'VariableNames',{'scenario','reference','family', ...
    'periodicReference','nPairs','referenceMeanRMSE','elcsMeanRMSE', ...
    'referenceMeanCost','elcsMeanCost','rmseDelta','rmseCiLo', ...
    'rmseCiHi','costDelta','costCiLo','costCiHi','decisionCode'});
D.dominates=double(D.decisionCode>=1);
D.confidenceSupported=double(D.decisionCode>=2);
D.decisionCode=[];

end


function S=summaryTable(T)

[group,S]=findgroups(T(:,{'scenario','scenarioLabel','arm', ...
    'methodLabel','ENGINE_FAMILY','PERIODIC_RATE_HZ'}));
S.n=splitapply(@numel,T.RMSE,group);
S.meanRMSE=splitapply(@mean,T.RMSE,group);
S.meanTrueAoI=splitapply(@mean,T.MEAN_TRUE_AOI,group);
S.meanTotalOfferedUtil=splitapply(@mean,T.TOTAL_OFFERED_UTIL,group);
S.meanChannelUtil=splitapply(@mean,T.CHANNEL_UTIL,group);
S.meanGoodputHz=splitapply(@mean,T.DATA_GOODPUT_HZ,group);
S.meanManagementUtil=splitapply(@mean,T.TOTAL_MANAGEMENT_UTIL,group);

end


function T=selectRows(T,scenario,arm)

T=T(string(T.scenario)==string(scenario) & string(T.arm)==string(arm),:);
T=sortrows(T,'seed');

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
    rows=repmat(exp22fFeasibilityEmptyRow(),0,1);
    return;
end
T=readtable(path,'TextType','string');
rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    index=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(index)==numel(R.arms), completed(q)=true;
    elseif any(index), error('exp22f: partial checkpoint group.'); end
end

end


function runRequiredTests()

names={'test_elcs_continuous_integration_contracts', ...
    'test_elcs_kernel_contracts', ...
    'test_exp21d_clock_composition_contracts', ...
    'test_exp21d_closed_loop_integration_contracts', ...
    'test_exp21c_closed_loop_timing_contracts'};
for k=1:numel(names), runScriptIsolated(names{k}); end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP22F_DIRECT_FEASIBILITY_PLAN.md', ...
    'docs/EXP22_EDGE_LEASE_CANDIDATE_DESIGN.md', ...
    'network/simulateElcsScheduling.m', ...
    'network/buildElcsContinuousSchedule.m', ...
    'network/simulateDstrScheduling.m', ...
    'network/buildDstrContinuousSchedule.m', ...
    'network/applyDstrAffineClockSchedule.m', ...
    'network/advanceSharedMedium.m','network/serviceSchedulerConfig.m', ...
    'utils/exp22fFeasibilityRegistry.m','utils/applyExp22fStaticArm.m', ...
    'utils/exp22fFeasibilityEmptyRow.m', ...
    'utils/runExp22fFeasibilityCell.m', ...
    'tests/test_elcs_continuous_integration_contracts.m', ...
    'experiments/exp22f_direct_feasibility.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

if ~isfolder(runDir), error('exp22f: resume directory not found.'); end
opened=jsondecode(fileread(fullfile(runDir,'feasibility_opened.json')));
if opened.registryHash~=registryHash || opened.registryLeaves~=registryLeaves
    error('exp22f: registry differs from the opened run.');
end
[~,runId]=fileparts(runDir);
meta=struct('experiment','exp22f_direct_feasibility', ...
    'runId',runId,'startedAt',opened.openedAt, ...
    'matlabVersion',version,'matlabRelease',version('-release'), ...
    'computer',computer,'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed frozen direct-feasibility checkpoint');
expRun=struct('name','exp22f_direct_feasibility', ...
    'runId',runId,'dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',meta,'t0',tic);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp22f: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
