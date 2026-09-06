function exp23d_local_witness_sharp_frontier(resumeDir)
%EXP23D_LOCAL_WITNESS_SHARP_FRONTIER Frozen periodic falsification.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp23dWitnessFrontierRegistry();
[registryHash,registryLeaves]=configHash(R);
experimentName='exp23d_local_witness_sharp_frontier';
if isempty(resumeDir)
    runRequiredTests();
    expRun=startExperiment(experimentName, ...
        ['Fresh measured-cost frontier falsification of ELCS-W against ' ...
        'guarded static periodic TDMA.']);
    writeJson(fullfile(expRun.dir,'frontier_registry.json'),R);
    writeJson(fullfile(expRun.dir,'frontier_opened.json'),struct( ...
        'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'policyOptimizationAllowed',false, ...
        'submissionClaimPermitted',false));
    snapshotSource(expRun.dir);
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
writetable(D,fullfile(expRun.dir,'frontier_dominance.csv'));
gates=integrityGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'integrity_gates.csv'));
integrityPass=all(gates.passed==1);
lower=D(string(D.reference)==string(R.lowerCostArm),:);
epsilonKill=any(lower.epsilonDominates==1);
strictKill=any(lower.strictDominates==1);
confidenceKill=any(lower.epsilonConfidenceSupported==1);
if ~integrityPass
    status='ELCS_W_FRONTIER_STUDY_INVALID';
    next='repair_experiment_integrity';
elseif epsilonKill
    status='ELCS_W_EPSILON_DOMINATED_RETURN_TO_DESIGN';
    next='redesign_local_witness_scheduling';
else
    status='ELCS_W_SHARP_PERIODIC_FRONTIER_SURVIVES';
    next='loss_and_load_robustness';
end
verdict=struct('status',status, ...
    'integrityGatesPassed',sum(gates.passed), ...
    'integrityGatesTotal',height(gates),'rows',height(T), ...
    'strictDominanceFound',strictKill, ...
    'epsilonDominanceFound',epsilonKill, ...
    'confidenceSupportedEpsilonDominanceFound',confidenceKill, ...
    'next',next,'robustnessContinuationPermitted', ...
    integrityPass && ~epsilonKill, ...
    'newMethodPromotionAllowed',false,'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'frontier_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','D','gates','verdict','R');

fprintf('\nEXP23D ELCS-W frontier integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP23D DECISION: %s\n',status);
finishExperiment(expRun);
if ~integrityPass, error('exp23d: frontier experiment invalid.'); end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21dClosedLoopCell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
N=base.swarm.N;
C=elcsWitnessKernelConfig(N,R.elcsMaxFrames);
C.guardSec=R.missionSafeGuardSec;
C.dataBytes=base.mac.dataBytes;
C.phyRateBps=base.mac.phyRateBps;
C.neighborGraph=logical(base.swarm.A);
C.managementReach=C.neighborGraph;
C.interferenceMatrix=logical(base.mac.interferenceMatrix);
C.conflictGraph=buildSenderConflictGraph( ...
    C.neighborGraph,C.interferenceMatrix);
elcsTrace=generateElcsWitnessTrace(seedValue,C);
nativeQ=buildElcsWitnessContinuousSchedule(C,elcsTrace,base.swarm.T);
CR=exp23cWitnessClosedLoopRegistry();
candidateArm=CR.arms(strcmp({CR.arms.id},CR.clockArm));

rows=repmat(exp23dWitnessFrontierEmptyRow(),numel(R.arms),1);
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
        [cfg,method,~,details]=applyExp23cWitnessClockArm( ...
            base,candidateArm,nativeQ,trace,CR);
        label=arm.label;
        details.kind='candidate-elcs-w';
        rate=50;
    end
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family','EXP23D ELCS-W frontier', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',rate);
    rows(k)=runExp23dWitnessFrontierCell( ...
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
rates=true;
for c=R.cells
    match=T(string(T.scenario)==string(c.id) & ...
        string(T.arm)=="periodic-cost-match",:);
    lower=T(string(T.scenario)==string(c.id) & ...
        string(T.arm)==string(R.lowerCostArm),:);
    rates=rates && all(abs(match.PERIODIC_RATE_HZ-c.costMatchRateHz)<1e-12) && ...
        all(abs(lower.PERIODIC_RATE_HZ-c.lowerCostRateHz)<1e-12);
end
add('parent_and_pilot_rates_frozen',rates, ...
    'cost-match derives from EXP23C; lower rate uses cost-only pilot rule');

periodic=string(T.ENGINE_FAMILY)=="periodic-static";
add('static_guarded_collision_free',all( ...
    T.ENDOGENOUS_COLLISION_FRAMES(periodic)==0) && all( ...
    T.CONTINUOUS_MAX_CLOCK_RESIDUAL(periodic)<=2e-12), ...
    'both periodic references remain physically collision-free');
candidate=string(T.ENGINE_FAMILY)=="candidate-elcs-w";
cover=all(T.ELCSW_ALL_EDGES_COVERED(candidate)==1) && ...
    all(T.ELCSW_HIDDEN_CONFLICT_EDGES(candidate)>0) && ...
    all(T.ELCSW_MAX_WITNESS_LOAD(candidate)<=10);
add('one_hop_witness_cover',cover, ...
    'candidate certifies hidden conflicts under one-hop management reach');
kernel=all(T.ELCSW_FINAL_ALL_CERTIFIED(candidate)==1) && ...
    all(T.ELCSW_FIRST_ALL_CERTIFIED_FRAME(candidate)==1) && ...
    all(T.ELCSW_RETRY_CLAIM_ATTEMPTS(candidate)==0) && ...
    all(T.ELCSW_FALSE_VALID_EDGE_FRAMES(candidate)==0) && ...
    all(T.ELCSW_SCHEDULED_COLLISION_FRAMES(candidate)==0) && ...
    all(T.ELCSW_CERTIFICATE_WITHOUT_FRESH_CLAIMS(candidate)==0);
add('elcs_w_kernel_safety',kernel, ...
    'certified frame 1; zero retry, false validity and scheduled collision');
replay=all(T.ELCSW_DATA_SKIPPED_NO_QUEUE(candidate)==0) && ...
    all(T.ELCSW_DATA_OUTCOME_MISMATCHES(candidate)==0) && ...
    all(T.ELCSW_DATA_COLLISION_WITNESS_MATCH(candidate)==1) && ...
    all(T.ELCSW_CROSS_PLANE_OVERLAPS(candidate)==0) && ...
    all(T.ELCSW_CLOCK_TIMING_CONFLICT_FREE(candidate)==1);
add('exact_elcs_w_replay',replay, ...
    'queue opportunities, receiver outcomes, clock guard and planes close');
management=all(T.ELCSW_MANAGEMENT_ACCOUNTING_CLOSE(candidate)==1) && ...
    all(T.ELCSW_MANAGEMENT_ATTEMPTS(candidate)== ...
        T.ELCSW_EXPECTED_MANAGEMENT_ATTEMPTS(candidate)) && ...
    all(abs(T.ELCSW_MANAGEMENT_AIRTIME(candidate)- ...
        T.ELCSW_EXPECTED_MANAGEMENT_AIRTIME(candidate))<=1e-12) && ...
    all(abs(T.ELCSW_MANAGEMENT_AIRTIME(candidate)- ...
        T.ELCSW_CONTROL_BYTES_AIRTIME(candidate))<=1e-12);
add('variable_payload_management_accounting',management, ...
    'attempt, recipient, byte and airtime accounting are exact');

eligible=true; costDetail='';
for c=R.cells
    A=selectRows(T,c.id,R.lowerCostArm);
    E=selectRows(T,c.id,R.elcsWArm);
    relative=mean(A.TOTAL_OFFERED_UTIL)/mean(E.TOTAL_OFFERED_UTIL)-1;
    eligible=eligible && relative<=-R.requiredCostImprovement+1e-12;
    costDetail=[costDetail sprintf('%s %.3f%%; ', ...
        c.id,100*relative)]; %#ok<AGROW>
end
add('measured_lower_cost_eligibility',eligible,costDetail);
charge=(T.DATA_AIRTIME+T.ACK_AIRTIME+T.TOTAL_MANAGEMENT_AIRTIME)/12;
account=all(abs(T.TOTAL_OFFERED_UTIL-charge)<=1e-12) && ...
    all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
        T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=T.TOTAL_OFFERED_UTIL+1e-9);
add('recipient_and_airtime_accounting',account, ...
    'actual DATA and variable management airtime and recipients close');
add('causal_and_closed_loop_invariants', ...
    all(T.FUTURE_RANDOM_READS==0) && ...
    all(T.RECEIVER_TRUTH_READS==0) && ...
    all(T.INVARIANT_VIOLATIONS==0), ...
    'zero causal and protocol-invariant failures');
retained=all(ismember(T.SAFEFAIL,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED) && all(isfinite(T.TOTAL_OFFERED_UTIL));
add('all_failures_retained',retained,sprintf( ...
    '%d unsafe and %d divergent trajectories retained', ...
    sum(T.SAFEFAIL),sum(T.DIVERGED)));
add('frontier_scope_only',~R.policyOptimizationAllowed && ...
    ~R.robustnessClaimPermitted && ~R.newMethodPromotionAllowed && ...
    ~R.submissionClaimPermitted, ...
    'no tuning, robustness, method promotion or submission decision');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});
if height(gates)~=R.requiredIntegrityContracts
    error('exp23d: registry contract count differs from implemented gates.');
end

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function D=dominanceTable(T,R)

rows=cell(0,18); q=0;
for c=R.cells
    E=selectRows(T,c.id,R.elcsWArm);
    for arm=R.arms(1:2)
        A=selectRows(T,c.id,arm.id);
        q=q+1;
        rmse=pairedBootstrapCI(A.RMSE,E.RMSE,10000, ...
            R.bootstrapSeedBase+2*q,30);
        cost=pairedBootstrapCI(A.TOTAL_OFFERED_UTIL, ...
            E.TOTAL_OFFERED_UTIL,10000,R.bootstrapSeedBase+1+2*q,30);
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
            ar/er-1,ac/ec-1,double(strict), ...
            double(epsilon)+2*double(confidence)}; %#ok<AGROW>
    end
end
D=cell2table(rows,'VariableNames',{'scenario','reference','nPairs', ...
    'periodicRateHz','referenceMeanRMSE','elcsWMeanRMSE', ...
    'referenceMeanCost','elcsWMeanCost','rmseDelta','rmseCiLo', ...
    'rmseCiHi','costDelta','costCiLo','costCiHi', ...
    'relativeRmse','relativeCost','strictDominates','epsilonCode'});
D.epsilonDominates=double(D.epsilonCode>=1);
D.epsilonConfidenceSupported=double(D.epsilonCode>=2);
D.epsilonCode=[];

end


function S=summaryTable(T)

[group,S]=findgroups(T(:,{'scenario','scenarioLabel','arm', ...
    'methodLabel','ENGINE_FAMILY','PERIODIC_RATE_HZ'}));
S.nRuns=splitapply(@numel,T.RMSE,group);
S.meanRMSE=splitapply(@mean,T.RMSE,group);
S.meanTrueAoI=splitapply(@mean,T.MEAN_TRUE_AOI,group);
S.meanTotalOfferedUtil=splitapply(@mean,T.TOTAL_OFFERED_UTIL,group);
S.meanChannelUtil=splitapply(@mean,T.CHANNEL_UTIL,group);
S.meanGoodputHz=splitapply(@mean,T.DATA_GOODPUT_HZ,group);
S.meanManagementUtil=splitapply( ...
    @mean,T.TOTAL_MANAGEMENT_UTIL,group);

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
    rows=repmat(exp23dWitnessFrontierEmptyRow(),0,1);
    return;
end
T=readtable(path,'TextType','string');
rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    index=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(index)==numel(R.arms), completed(q)=true;
    elseif any(index), error('exp23d: partial checkpoint group.'); end
end

end


function runRequiredTests()

names={'test_exp23d_witness_frontier_contracts', ...
    'test_elcs_continuous_integration_contracts', ...
    'test_elcs_kernel_contracts', ...
    'test_exp21c_closed_loop_timing_contracts'};
for k=1:numel(names), runScriptIsolated(names{k}); end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP23D_LOCAL_WITNESS_SHARP_FRONTIER_PLAN.md', ...
    'docs/EXP23C_LOCAL_WITNESS_CLOSED_LOOP_RESULTS_2026-09-03.md', ...
    'network/simulateElcsWitnessScheduling.m', ...
    'network/buildElcsWitnessContinuousSchedule.m', ...
    'network/applyDstrAffineClockSchedule.m', ...
    'network/advanceSharedMedium.m', ...
    'utils/exp23dWitnessFrontierRegistry.m', ...
    'utils/applyExp23cWitnessClockArm.m', ...
    'utils/applyExp22fStaticArm.m', ...
    'utils/runExp23cWitnessClosedLoopCell.m', ...
    'utils/runExp23dWitnessFrontierCell.m', ...
    'utils/exp23dWitnessFrontierEmptyRow.m', ...
    'tests/test_exp23d_witness_frontier_contracts.m', ...
    'experiments/exp23d_local_witness_sharp_frontier.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves,experimentName)

if ~isfolder(runDir), error('exp23d: resume directory not found.'); end
opened=jsondecode(fileread(fullfile(runDir,'frontier_opened.json')));
if opened.registryHash~=registryHash || opened.registryLeaves~=registryLeaves
    error('exp23d: registry differs from opened run.');
end
[~,runId]=fileparts(runDir);
meta=struct('experiment',experimentName, ...
    'runId',runId,'startedAt',opened.openedAt, ...
    'matlabVersion',version,'matlabRelease',version('-release'), ...
    'computer',computer,'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed frozen ELCS-W frontier checkpoint');
expRun=struct('name',experimentName, ...
    'runId',runId,'dir',runDir,'figDir',fullfile(runDir,'figures'), ...
    'expRoot',fileparts(runDir),'meta',meta,'t0',tic);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp23d: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)
if condition, value=a; else, value=b; end
end
