function exp22g_targeted_frontier_closure(resumeDir,variant)
%EXP22G_TARGETED_FRONTIER_CLOSURE Cost-targeted periodic falsification.

if nargin<1, resumeDir=''; end
if nargin<2, variant='exp22g'; end
startup;
close all;
[R,experimentName,studyTag,description]=studyVariant(variant);
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runRequiredTests();
    expRun=startExperiment(experimentName,description);
    writeJson(fullfile(expRun.dir,'targeted_registry.json'),R);
    writeJson(fullfile(expRun.dir,'targeted_opened.json'),struct( ...
        'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'policyOptimizationAllowed',false, ...
        'submissionClaimPermitted',false));
    snapshotSource(expRun.dir,studyTag);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves,experimentName);
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
D=dominanceTable(T,R);
writetable(D,fullfile(expRun.dir,'targeted_dominance.csv'));
gates=integrityGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'integrity_gates.csv'));
integrityPass=all(gates.passed==1);
lower=D(string(D.reference)==string(R.lowerCostArm),:);
epsilonKill=any(lower.epsilonDominates==1);
strictKill=any(lower.strictDominates==1);
confidenceKill=any(lower.epsilonConfidenceSupported==1);
if ~integrityPass
    status='ELCS_TARGETED_FRONTIER_STUDY_INVALID';
    next='repair_experiment_integrity';
elseif epsilonKill
    status='ELCS_EPSILON_DOMINATED_RETURN_TO_DESIGN';
    next='redesign_allocation_or_control_overhead';
else
    status='ELCS_TARGETED_FRONTIER_SURVIVES';
    next='robustness_and_remaining_direct_references';
end
verdict=struct('status',status,'integrityGatesPassed',sum(gates.passed), ...
    'integrityGatesTotal',height(gates),'rows',height(T), ...
    'strictDominanceFound',strictKill, ...
    'epsilonDominanceFound',epsilonKill, ...
    'confidenceSupportedEpsilonDominanceFound',confidenceKill, ...
    'next',next,'robustnessContinuationPermitted', ...
    integrityPass && ~epsilonKill, ...
    'newMethodPromotionAllowed',false,'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'targeted_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','D','gates','verdict','R');

fprintf('\n%s targeted-frontier integrity gates\n',studyTag);
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\n%s DECISION: %s\n',studyTag,status);
finishExperiment(expRun);
if ~integrityPass, error('exp22g: targeted frontier experiment invalid.'); end

end


function [R,experimentName,studyTag,description]=studyVariant(variant)

switch lower(char(variant))
    case 'exp22g'
        R=exp22gTargetedFrontierRegistry();
        experimentName='exp22g_targeted_frontier_closure';
        studyTag='EXP22G';
        description=['Analytically cost-targeted periodic frontier versus ' ...
            'ELCS-F; strict and epsilon dominance.'];
    case 'exp22k'
        R=exp22kEventDrivenFrontierRegistry();
        experimentName='exp22k_event_driven_frontier_closure';
        studyTag='EXP22K';
        description=['Fresh cost-targeted periodic falsification of ' ...
            'event-driven ELCS-F with protocol and analytical-bound gates.'];
    case 'exp22l'
        R=exp22lEventDrivenFrontierRepairRegistry();
        experimentName='exp22l_event_driven_frontier_gate_repair';
        studyTag='EXP22L';
        description=['Fresh-seed event-driven frontier rerun after ' ...
            'separating logical protocol and physical replay horizons.'];
    otherwise
        error('exp22g: unknown study variant %s.',char(variant));
end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21dClosedLoopCell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
N=base.swarm.N;
ER=exp22eElcsClosedLoopRegistry();
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
    if strcmp(arm.family,'periodic-static')
        if strcmp(arm.rateRule,'cost-match')
            rate=c.costMatchRateHz;
        else
            rate=c.lowerCostRateHz;
        end
        localArm=struct('id',arm.id,'label',arm.label, ...
            'family','periodic-static','periodicRateHz',rate);
        [cfg,method,label,details]=applyExp22fStaticArm(base,localArm,R);
    else
        [cfg,method,~,details]=applyExp22dElcsClockArm( ...
            base,elcsArm,elcsNative,trace,ER);
        label=arm.label;
        details.kind='candidate-elcs';
        rate=50;
    end
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family','EXP22G targeted frontier', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',rate);
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
    '30 fresh seeds, two cells and three arms exact');
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
static=string(T.ENGINE_FAMILY)=="periodic-static";
add('static_guarded_collision_free',all( ...
    T.ENDOGENOUS_COLLISION_FRAMES(static)==0) && all( ...
    T.CONTINUOUS_MAX_CLOCK_RESIDUAL(static)<=2e-12), ...
    'targeted static arms remain physically collision-free');
elcs=string(T.ENGINE_FAMILY)=="candidate-elcs";
replay=all(T.REPLAY_DATA_SKIPPED_NO_QUEUE(elcs)==0) && ...
    all(T.REPLAY_DATA_OUTCOME_MISMATCHES(elcs)==0) && ...
    all(T.REPLAY_COLLISION_WITNESS_MATCH(elcs)==1) && ...
    all(T.REPLAY_MANAGEMENT_ACCOUNTING_CLOSE(elcs)==1) && ...
    all(T.REPLAY_MANAGEMENT_ATTEMPT_MATCH(elcs)==1) && ...
    all(T.REPLAY_MANAGEMENT_RECIPIENT_MATCH(elcs)==1) && ...
    all(T.REPLAY_MANAGEMENT_AIRTIME_MATCH(elcs)==1) && ...
    all(T.REPLAY_CROSS_PLANE_OVERLAPS(elcs)==0);
add('exact_elcs_replay',replay, ...
    'ELCS queue opportunities, receiver outcomes and control accounting close');
add('elcs_safety',all(T.ELCS_FINAL_ALL_CERTIFIED(elcs)==1) && ...
    all(T.ELCS_FALSE_VALID_EDGE_FRAMES(elcs)==0) && ...
    all(T.ELCS_OWNER_LOCK_VIOLATIONS(elcs)==0) && ...
    all(T.ELCS_SCHEDULED_COLLISION_FRAMES(elcs)==0), ...
    'lease safety remains valid on every fresh seed');
if isfield(R,'eventDrivenContractRequired') && ...
        R.eventDrivenContractRequired
    requestDiscipline=all( ...
        T.ELCS_GRANT_WITHOUT_DECODED_REQUEST(elcs)==0) && all( ...
        T.ELCS_STATUS_ATTEMPTS(elcs)== ...
        T.ELCS_DISCOVERY_STATUS_ATTEMPTS(elcs)+ ...
        T.ELCS_REQUEST_STATUS_ATTEMPTS(elcs));
    add('event_driven_request_discipline',requestDiscipline, ...
        'STATUS partition closes and every GRANT follows a decoded request');
    bounded=all(T.ELCS_CONTROL_BOUND_RATIO(elcs)<=1+1e-12) && all( ...
        T.ELCS_STATUS_ATTEMPTS(elcs)+T.ELCS_GRANT_ATTEMPTS(elcs)<= ...
        T.ELCS_CONTROL_ATTEMPT_BOUND(elcs));
    add('event_driven_control_bound',bounded, ...
        sprintf('maximum observed/bound ratio %.6f', ...
        max(T.ELCS_CONTROL_BOUND_RATIO(elcs))));
    deadline=all(T.ELCS_FIRST_ALL_CERTIFIED_FRAME(elcs)<=T.N(elcs));
    add('event_driven_acquisition_deadline',deadline, ...
        sprintf('maximum first-certification excess %.0f frames',max( ...
        T.ELCS_FIRST_ALL_CERTIFIED_FRAME(elcs)-T.N(elcs))));
end
charge=(T.DATA_AIRTIME+T.ACK_AIRTIME+T.TOTAL_MANAGEMENT_AIRTIME)/12;
account=all(abs(T.TOTAL_OFFERED_UTIL-charge)<=1e-12) && ...
    all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
        T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=T.TOTAL_OFFERED_UTIL+1e-9);
add('recipient_and_airtime_accounting',account, ...
    'all actual DATA and management airtime and recipients close');
add('causal_and_closed_loop_invariants', ...
    all(T.FUTURE_RANDOM_READS==0) && ...
    all(T.RECEIVER_TRUTH_READS==0) && ...
    all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.SAFEFAIL==0) && all(T.DIVERGED==0), ...
    'zero causal, protocol, safety and divergence failures');
add('targeted_scope_only',~R.policyOptimizationAllowed && ...
    ~R.robustnessContinuationPermitted && ~R.submissionClaimPermitted, ...
    'no tuning, robustness, promotion or submission decision');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function D=dominanceTable(T,R)

rows=cell(0,18);
q=0;
bootstrapBase=16048900;
if isfield(R,'bootstrapSeedBase'), bootstrapBase=R.bootstrapSeedBase; end
for c=R.cells
    E=selectRows(T,c.id,R.elcsArm);
    for arm=R.arms(1:2)
        A=selectRows(T,c.id,arm.id);
        q=q+1;
        rmse=pairedBootstrapCI(A.RMSE,E.RMSE,10000,bootstrapBase+2*q,30);
        cost=pairedBootstrapCI(A.TOTAL_OFFERED_UTIL, ...
            E.TOTAL_OFFERED_UTIL,10000,bootstrapBase+1+2*q,30);
        er=mean(E.RMSE); ec=mean(E.TOTAL_OFFERED_UTIL);
        ar=mean(A.RMSE); ac=mean(A.TOTAL_OFFERED_UTIL);
        strict=ar<=(1-R.strictMargin)*er && ...
            ac<=(1-R.strictMargin)*ec;
        epsilon=ar<=(1+R.epsilonRmse)*er && ...
            ac<=(1-R.requiredCostImprovement)*ec;
        confidence=rmse.hi<=R.epsilonRmse*er && ...
            cost.hi<=-R.requiredCostImprovement*ec;
        rows(end+1,:)={string(c.id),string(arm.id),height(A), ...
            A.PERIODIC_RATE_HZ(1),ar,er,ac,ec, ...
            rmse.meanD,rmse.lo,rmse.hi,cost.meanD,cost.lo,cost.hi, ...
            (ar/er-1),ac/ec-1,double(strict),double(epsilon)+ ...
            2*double(confidence)}; %#ok<AGROW>
    end
end
D=cell2table(rows,'VariableNames',{'scenario','reference','nPairs', ...
    'periodicRateHz','referenceMeanRMSE','elcsMeanRMSE', ...
    'referenceMeanCost','elcsMeanCost','rmseDelta','rmseCiLo', ...
    'rmseCiHi','costDelta','costCiLo','costCiHi', ...
    'relativeRmse','relativeCost','strictDominates','epsilonCode'});
D.epsilonDominates=double(D.epsilonCode>=1);
D.epsilonConfidenceSupported=double(D.epsilonCode>=2);
D.epsilonCode=[];

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
    elseif any(index), error('exp22g: partial checkpoint group.'); end
end

end


function runRequiredTests()

names={'test_elcs_continuous_integration_contracts', ...
    'test_elcs_kernel_contracts','test_exp21c_closed_loop_timing_contracts'};
for k=1:numel(names), runScriptIsolated(names{k}); end

end


function snapshotSource(target,studyTag)

root=projectRoot();
if strcmp(studyTag,'EXP22K')
    plan='docs/EXP22K_EVENT_DRIVEN_FRONTIER_CLOSURE_PLAN.md';
    registry='utils/exp22kEventDrivenFrontierRegistry.m';
    wrapper='experiments/exp22k_event_driven_frontier_closure.m';
elseif strcmp(studyTag,'EXP22L')
    plan='docs/EXP22L_EVENT_DRIVEN_FRONTIER_GATE_REPAIR_PLAN.md';
    registry='utils/exp22lEventDrivenFrontierRepairRegistry.m';
    wrapper='experiments/exp22l_event_driven_frontier_gate_repair.m';
else
    plan='docs/EXP22G_TARGETED_FRONTIER_CLOSURE_PLAN.md';
    registry='utils/exp22gTargetedFrontierRegistry.m';
    wrapper='';
end
files={plan, ...
    'network/simulateElcsScheduling.m', ...
    'network/buildElcsContinuousSchedule.m', ...
    'network/applyDstrAffineClockSchedule.m', ...
    'network/advanceSharedMedium.m', ...
    registry, ...
    'utils/applyExp22fStaticArm.m','utils/runExp22fFeasibilityCell.m', ...
    'utils/exp22fFeasibilityEmptyRow.m', ...
    'experiments/exp22g_targeted_frontier_closure.m'};
if ~isempty(wrapper), files{end+1}=wrapper; end
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves,experimentName)

if ~isfolder(runDir), error('exp22g: resume directory not found.'); end
opened=jsondecode(fileread(fullfile(runDir,'targeted_opened.json')));
if opened.registryHash~=registryHash || opened.registryLeaves~=registryLeaves
    error('exp22g: registry differs from the opened run.');
end
[~,runId]=fileparts(runDir);
meta=struct('experiment',experimentName, ...
    'runId',runId,'startedAt',opened.openedAt, ...
    'matlabVersion',version,'matlabRelease',version('-release'), ...
    'computer',computer,'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed frozen targeted-frontier checkpoint');
expRun=struct('name',experimentName, ...
    'runId',runId,'dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',meta,'t0',tic);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp22g: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
