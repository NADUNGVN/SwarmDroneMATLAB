function exp21c_closed_loop_timing_integration(resumeDir)
%EXP21C_CLOSED_LOOP_TIMING_INTEGRATION Frozen integration comparison.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp21cRegistry();
[registryHash,registryLeaves]=configHash(R);
if isempty(resumeDir)
    runRequiredTests();
    expRun=startExperiment('exp21c_closed_loop_timing_integration', ...
        ['Continuous local-clock event-engine integration; no policy ' ...
        'optimization or submission claim.']);
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
batchSize=10;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    idx=pending(first:last);
    selectedSeeds=seeds(idx); selectedCells=cells(idx);
    batch=cell(numel(idx),1);
    parfor (q=1:numel(idx),12)
        batch{q}=runGroup(selectedSeeds(q),selectedCells(q),R);
    end
    for q=1:numel(batch), rows=[rows;batch{q}(:)]; end %#ok<AGROW>
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %2d--%2d / %2d; rows %3d / %3d\n', ...
        idx(1),idx(end),numel(seeds),numel(rows),R.expectedRuns);
end

T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'trajectory_tidy.csv'));
S=summaryTable(T);
writetable(S,fullfile(expRun.dir,'summary.csv'));
P=pairedComparison(T,R);
writetable(P,fullfile(expRun.dir,'paired_integration_comparison.csv'));
gates=integrationGates(T,S,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'integration_gates.csv'));
pass=all(gates.passed==1);
status=ternary(pass,'CLOSED_LOOP_TIMING_INTEGRATION_VALID', ...
    'CLOSED_LOOP_TIMING_INTEGRATION_INVALID');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'reservationIntegrationPermitted',pass, ...
    'policyPromotionPermitted',false,'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'integration_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','P','gates','verdict','R');

fprintf('\nEXP21C integration gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP21C INTEGRATION VERDICT: %s\n',status);
finishExperiment(expRun);
if ~pass, error('exp21c: closed-loop integration invalid.'); end

end


function rows=runGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp21CCell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp21cEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label,details]=applyExp21CArm(base,arm);
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family', ...
        'EXP21C closed-loop timing integration', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',arm.guardFactor);
    rows(k)=runExp21CCell(cfg,method,label,meta,trace,details);
end

end


function gates=integrationGates(T,S,R,registryHash,registryLeaves)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
key=string(T.seed)+'|'+string(T.scenario)+'|'+string(T.arm);
add('matrix_complete_unique',height(T)==R.expectedRuns && ...
    numel(unique(key))==height(T),sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
add('exact_seed_cell_arm_coverage',isequal(unique(T.seed),R.seeds) && ...
    isequal(sort(unique(string(T.scenario))),sort(string({R.cells.id})')) && ...
    isequal(sort(unique(string(T.arm))),sort(string({R.arms.id})')), ...
    '30 seeds, two cells and four arms exact');
paired=true;
for seed=R.seeds'
    for c=R.cells
        idx=T.seed==seed & string(T.scenario)==string(c.id);
        paired=paired && nnz(idx)==numel(R.arms) && ...
            isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.EXP21C_TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.ESTIMATOR_HASH_EXACT(idx)));
    end
end
add('paired_absolute_traces',paired, ...
    'channel, estimator and continuous-clock hashes match per group');

continuous=string(T.schedulerMode)=='continuous-local-static-tdma';
ideal=string(T.arm)==string(R.idealArm);
zero=string(T.arm)==string(R.zeroArm);
witness=string(T.arm)==string(R.witnessArm);
safe=string(T.arm)==string(R.safeArm);
add('causal_local_information_only',all(T.FUTURE_RANDOM_READS==0) && ...
    all(T.RECEIVER_TRUTH_READS(continuous)==0) && ...
    all(T.LOCAL_SCHEDULE_ONLY(continuous)==1), ...
    'zero future reads, zero receiver-truth reads');
add('clock_equation_closes',all( ...
    T.CONTINUOUS_MAX_CLOCK_RESIDUAL(continuous)<=1e-11),sprintf( ...
    'maximum residual %.3g s', ...
    max(T.CONTINUOUS_MAX_CLOCK_RESIDUAL(continuous))));
exactDuration=8*96/250e3;
exact=all(abs(T.DATA_AIRTIME(continuous)- ...
    exactDuration*T.DATA_ATTEMPTED(continuous))<=1e-9) && ...
    all(T.CONTINUOUS_EXACT_AIRTIME(continuous)==1);
add('exact_physical_airtime',exact, ...
    'DATA airtime equals attempts times 3.072 ms');
add('zero_clock_collision_free',all(T.ENDOGENOUS_COLLISION_FRAMES(zero)==0), ...
    sprintf('%d zero-clock collision frames', ...
    sum(T.ENDOGENOUS_COLLISION_FRAMES(zero))));
add('safe_guard_collision_free',all(T.ENDOGENOUS_COLLISION_FRAMES(safe)==0), ...
    sprintf('%d safe-guard collision frames', ...
    sum(T.ENDOGENOUS_COLLISION_FRAMES(safe))));
witnessByCell=true;
for c=R.cells
    idx=witness & string(T.scenario)==string(c.id);
    witnessByCell=witnessByCell && sum(T.ENDOGENOUS_COLLISION_FRAMES(idx))>0;
end
add('unguarded_clock_mechanism_activated',witnessByCell, ...
    sprintf('%d witness collision frames', ...
    sum(T.ENDOGENOUS_COLLISION_FRAMES(witness))));
add('ideal_reference_collision_free', ...
    all(T.ENDOGENOUS_COLLISION_FRAMES(ideal)==0), ...
    'centralized reference has zero endogenous collisions');

consistent=true; text=cell(numel(R.cells),1);
for k=1:numel(R.cells)
    c=R.cells(k);
    z=one(S,c.id,R.zeroArm); i=one(S,c.id,R.idealArm);
    cellPass=z.meanRMSE<=i.meanRMSE*(1+R.maxZeroRelativeRmseGap) && ...
        z.meanChargedUtil<=i.meanChargedUtil+R.maxZeroAbsoluteUtilGap && ...
        z.safeFailures<=i.safeFailures;
    consistent=consistent && cellPass;
    text{k}=sprintf('%s RMSE %.5g/%.5g util %.5g/%.5g fail %d/%d', ...
        c.id,z.meanRMSE,i.meanRMSE,z.meanChargedUtil, ...
        i.meanChargedUtil,z.safeFailures,i.safeFailures);
end
add('zero_clock_consistent_with_ideal',consistent,strjoin(text,'; '));
account=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL(continuous)<=T.OFFERED_UTIL(continuous)+1e-9);
add('recipient_and_interval_accounting',account, ...
    'terminal recipient counts close and busy union does not exceed offered');
retained=all(ismember(T.SAFEFAIL,[0 1])) && all(T.SAFEFAIL>=T.DIVERGED) && ...
    all(isfinite(T.CHARGED_OFFERED_UTIL));
add('all_failures_retained',retained,sprintf('%d unsafe retained', ...
    sum(T.SAFEFAIL)));
add('integration_scope_only',~R.policyOptimizationAllowed && ...
    ~R.submissionClaimPermitted, ...
    'no policy promotion or submission decision in this study');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p); %#ok<AGROW>
        detail{end+1,1}=d; %#ok<AGROW>
    end

end


function S=summaryTable(T)

U=T; U.RMSE(logical(U.DIVERGED))=NaN;
[group,S]=findgroups(U(:,{'scenario','scenarioLabel','arm', ...
    'methodLabel','armKind','schedulerMode'}));
S.n=splitapply(@numel,U.RMSE,group);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,group);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,group);
S.meanChargedUtil=splitapply(@finiteMean,U.CHARGED_OFFERED_UTIL,group);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,group);
S.meanEndogenousCollisions=splitapply( ...
    @finiteMean,U.ENDOGENOUS_COLLISION_FRAMES,group);
S.meanStartAttempts=splitapply( ...
    @finiteMean,U.CONTINUOUS_START_ATTEMPTS,group);

end


function P=pairedComparison(T,R)

P=table('Size',[numel(R.cells)*2 9], ...
    'VariableTypes',{'string','string','double','double','double', ...
        'double','double','double','double'}, ...
    'VariableNames',{'scenario','comparison','nPairs','meanRmseDelta', ...
        'meanUtilDelta','rmseCiLo','rmseCiHi','utilCiLo','utilCiHi'});
q=0;
for c=R.cells
    ideal=selectRows(T,c.id,R.idealArm);
    for arm={R.zeroArm,R.safeArm}
        q=q+1; candidate=selectRows(T,c.id,arm{1});
        B1=pairedBootstrapCI(candidate.RMSE,ideal.RMSE, ...
            10000,16032900+q,30);
        B2=pairedBootstrapCI(candidate.CHARGED_OFFERED_UTIL, ...
            ideal.CHARGED_OFFERED_UTIL,10000,16032920+q,30);
        P.scenario(q)=string(c.id); P.comparison(q)=string(arm{1})+"-ideal";
        P.nPairs(q)=B1.nPairs; P.meanRmseDelta(q)=B1.meanD;
        P.meanUtilDelta(q)=B2.meanD; P.rmseCiLo(q)=B1.lo;
        P.rmseCiHi(q)=B1.hi; P.utilCiLo(q)=B2.lo; P.utilCiHi(q)=B2.hi;
    end
end

end


function r=one(S,scenario,arm)

idx=string(S.scenario)==string(scenario) & string(S.arm)==string(arm);
if nnz(idx)~=1, error('exp21c: expected one summary row.'); end
r=S(idx,:);

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

[seeds,cells]=groups(R); completed=false(size(seeds));
path=fullfile(runDir,'trajectory_checkpoint.csv');
if ~isfile(path), rows=repmat(exp21cEmptyRow(),0,1); return; end
T=readtable(path,'TextType','string'); rows=table2struct(T);
for q=1:numel(seeds)
    c=R.cells(cells(q));
    idx=T.seed==seeds(q) & string(T.scenario)==string(c.id);
    if nnz(idx)==numel(R.arms), completed(q)=true;
    elseif any(idx), error('exp21c: partial checkpoint group.'); end
end

end


function runRequiredTests()

names={'test_exp21c_closed_loop_timing_contracts', ...
    'test_shared_medium_infrastructure','test_shared_medium_end_to_end', ...
    'test_service_scheduler_contracts','test_exp21a_contracts'};
for k=1:numel(names)
    runScriptIsolated(names{k});
end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP21C_CLOSED_LOOP_TIMING_INTEGRATION_PLAN.md', ...
    'network/advanceSharedMedium.m','network/serviceSchedulerConfig.m', ...
    'network/initSharedMediumState.m','network/selectScheduledService.m', ...
    'utils/generateSharedMediumTrace.m','utils/exp21cRegistry.m', ...
    'utils/applyExp21CCell.m','utils/applyExp21CArm.m', ...
    'utils/exp21cEmptyRow.m','utils/runExp21CCell.m', ...
    'utils/runExp21ACell.m', ...
    'tests/test_exp21c_closed_loop_timing_contracts.m', ...
    'experiments/exp21c_closed_loop_timing_integration.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

record=jsondecode(fileread(fullfile(runDir,'integration_opened.json')));
if record.registryHash~=registryHash || record.registryLeaves~=registryLeaves
    error('exp21c: resume registry mismatch.');
end
[root,runId]=fileparts(runDir);
expRun=struct('name','exp21c_closed_loop_timing_integration', ...
    'runId',runId,'expRoot',root,'dir',runDir, ...
    'figDir',fullfile(runDir,'figures'),'t0',tic);
v=ver; v=v(strcmp({v.Name},'MATLAB'));
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',record.openedAt,'matlabVersion', ...
    sprintf('%s %s',v.Name,v.Version),'matlabRelease',v.Release, ...
    'computer',computer,'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed integration run','sourceFile','');
expRun.logFile=fullfile(runDir,'console.log'); diary(expRun.logFile); diary on;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp21c: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
