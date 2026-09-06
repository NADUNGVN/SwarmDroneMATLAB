function exp14a_holdout_primary()
%EXP14A_HOLDOUT_PRIMARY Frozen 100-seed 6-DOF primary validation.

startup;
close all;

runScriptIsolated('test_shared_medium_infrastructure');
runScriptIsolated('test_shared_medium_channel_models');
runScriptIsolated('test_shared_medium_end_to_end');
runScriptIsolated('test_exp13_policy_contracts');
runScriptIsolated('test_exp14_infrastructure');

R = exp14Registry();
[registryHash,registryLeaves] = configHash(R);
if registryHash~=201658753 || registryLeaves~=139
    error('exp14a_holdout_primary: frozen registry hash mismatch.');
end

expRun = startExperiment('exp14a_holdout_primary', ...
    ['Frozen 100-seed N=5 6-DOF equal-budget frontier and mechanism ' ...
    'holdout; negative results retained; no performance gate.']);
snapshotFreeze(expRun.dir);
writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
opened = struct('openedAt',char(datetime('now', ...
    'Format','yyyy-MM-dd HH:mm:ss')),'registryHash',registryHash, ...
    'firstSeed',R.seeds(1),'lastSeed',R.seeds(end), ...
    'policyParametersMayChange',false);
writeJson(fullfile(expRun.dir,'holdout_opened.json'),opened);

fprintf('EXP14A HOLDOUT IS NOW OPEN. Registry hash: %.0f\n',registryHash);
fprintf('Primary matrix: %d frozen runs (%d seeds).\n', ...
    R.expected.primaryRuns,numel(R.seeds));

[groupSeed,groupScenario] = primaryGroups(R);
nGroup = numel(groupSeed);
allRows = repmat(exp14EmptyRow(),0,1);
batchSize = 16;
checkpoint = fullfile(expRun.dir,'tidy_checkpoint.csv');

for first = 1:batchSize:nGroup
    last = min(first+batchSize-1,nGroup);
    indices = first:last;
    batch = cell(numel(indices),1);
    parfor (q = 1:numel(indices),16)
        g = indices(q);
        batch{q} = runPrimaryGroup( ...
            groupSeed(g),groupScenario(g),R);
    end
    for q = 1:numel(batch)
        allRows = [allRows; batch{q}(:)]; %#ok<AGROW>
    end
    writetable(struct2table(allRows),checkpoint);
    fprintf('  completed groups %3d--%3d / %3d; rows %5d / %5d\n', ...
        first,last,nGroup,numel(allRows),R.expected.primaryRuns);
end

tidy = struct2table(allRows);
frontier = tidy(strcmp(tidy.stage,'frontier'),:);
mechanism = tidy(strcmp(tidy.stage,'mechanism'),:);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
writetable(frontier,fullfile(expRun.dir,'frontier.csv'));
writetable(mechanism,fullfile(expRun.dir,'mechanism.csv'));

frontierSummary = summarizeRows(frontier, ...
    {'scenarioLabel','family','pointIndex','parameterValue'});
mechanismSummary = summarizeRows(mechanism, ...
    {'scenarioLabel','family','arm'});
writetable(frontierSummary,fullfile(expRun.dir,'frontier_summary.csv'));
writetable(mechanismSummary,fullfile(expRun.dir,'mechanism_summary.csv'));

gates = primaryGates(tidy,frontier,mechanism,R);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
verdict = struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'totalRuns',height(tidy),'performanceClaimGate','NONE', ...
    'negativeResultsRetained',true, ...
    'configurationChangePermitted',false);
writeJson(fullfile(expRun.dir,'verdict.json'),verdict);

fprintf('\nEXP14A machine gates\n');
for k = 1:height(gates)
    fprintf('  [%-4s] %-34s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        gates.gate{k},gates.detail{k});
end
fprintf('\nEXP14A VERDICT: %s (%d/%d integrity gates)\n', ...
    verdict.status,verdict.gatesPassed,verdict.gatesTotal);
fprintf('Performance superiority was not a machine gate.\n');

save(fullfile(expRun.dir,'workspace.mat'),'tidy','frontier','mechanism', ...
    'frontierSummary','mechanismSummary','gates','verdict','R','-v7.3');
finishExperiment(expRun);

if ~all(gates.passed==1)
    error('exp14a_holdout_primary: %d of %d integrity gates failed.', ...
        nnz(gates.passed==0),height(gates));
end

end


function rows = runPrimaryGroup(seedValue,scenarioIndex,R)

sc = R.scenarios(scenarioIndex);
base = study2Exp14Config(seedValue,sc.id);
trace = generateSharedMediumTrace(base);
rows = repmat(exp14EmptyRow(), ...
    numel(R.frontiers)*5+numel(R.mechanisms),1);
kRun = 0;

for iFamily = 1:numel(R.frontiers)
    f = R.frontiers(iFamily);
    for iPoint = 1:numel(f.values)
        cfg = base;
        [cfg,method,label] = applyExp14FrontierPoint( ...
            cfg,f.id,f.values(iPoint));
        meta = makeMeta('frontier',sc,f.label, ...
            sprintf('%s-%d',f.id,iPoint),iPoint,f.values(iPoint));
        kRun = kRun+1;
        rows(kRun) = runExp14Cell(cfg,method,label,meta,trace);
    end
end

for iArm = 1:numel(R.mechanisms)
    arm = R.mechanisms(iArm);
    cfg = base;
    cfg.shared.feedbackMode = arm.feedbackMode;
    meta = makeMeta('mechanism',sc,arm.label,arm.id,iArm,NaN);
    kRun = kRun+1;
    rows(kRun) = runExp14Cell( ...
        cfg,arm.method,arm.label,meta,trace);
end

end


function meta = makeMeta(stage,sc,family,arm,pointIndex,value)

meta = struct('stage',stage,'scenario',sc.id, ...
    'scenarioLabel',sc.label,'family',family,'arm',arm, ...
    'pointIndex',pointIndex,'parameterValue',value);

end


function [seeds,scenarioIndex] = primaryGroups(R)

n = numel(R.seeds)*numel(R.scenarios);
seeds = zeros(n,1);
scenarioIndex = zeros(n,1);
k = 0;
for iSeed = 1:numel(R.seeds)
    for iScenario = 1:numel(R.scenarios)
        k = k+1;
        seeds(k)=R.seeds(iSeed);
        scenarioIndex(k)=iScenario;
    end
end

end


function gates = primaryGates(T,F,M,R)

names = cell(0,1); passed = false(0,1); detail = cell(0,1);
[names,passed,detail] = addGate(names,passed,detail, ...
    'matrix_completeness',height(T)==R.expected.primaryRuns && ...
    height(F)==R.expected.primaryFrontierRuns && ...
    height(M)==R.expected.primaryMechanismRuns, ...
    sprintf('total=%d frontier=%d mechanism=%d',height(T),height(F),height(M)));

keys = string(T.stage)+"|"+string(T.seed)+"|"+string(T.scenario)+"|"+ ...
    string(T.family)+"|"+string(T.arm);
[names,passed,detail] = addGate(names,passed,detail,'unique_cells', ...
    numel(unique(keys))==height(T),'every declared seed/cell appears once');

finite = all(isfinite(T.RMSE)) && all(isfinite(T.MINSEP)) && ...
    all(isfinite(T.MEAN_TRUE_AOI)) && all(isfinite(T.OFFERED_UTIL)) && ...
    all(isfinite(T.ROLL_PEAK_DEG)) && all(isfinite(T.SATURATION));
[names,passed,detail] = addGate(names,passed,detail,'finite_outputs', ...
    finite,'all required control, freshness, PHY and 6-DOF outputs are finite');

feedback = ~strcmp(T.feedbackMode,'none');
causal = all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI(feedback)>=T.MEAN_TRUE_AOI(feedback)-1e-12) && ...
    all(isnan(T.MEAN_EST_AOI(~feedback)));
[names,passed,detail] = addGate(names,passed,detail,'causal_conservatism', ...
    causal,sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));

bounded = all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
[names,passed,detail] = addGate(names,passed,detail,'bounded_memory',bounded, ...
    sprintf('max queue=%d max history=%d',max(T.MAX_QUEUE),max(T.MAX_HISTORY)));

accounting = all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS== ...
    T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS== ...
    T.ACK_RECIPIENT_ATTEMPTS) && all(T.CHANNEL_UTIL<=1+1e-12) && ...
    all(T.CHANNEL_UTIL<=T.OFFERED_UTIL+T.backgroundLoad+1e-12);
[names,passed,detail] = addGate(names,passed,detail,'physical_accounting', ...
    accounting,'DATA/ACK recipient outcomes and busy-time identities close');

crn = true; statePair = true;
for seed = R.seeds'
    crn = crn && isscalar(unique(T.TRACE_HASH_EXACT(T.seed==seed)));
    for k = 1:numel(R.scenarios)
        idx = T.seed==seed & strcmp(T.scenario,R.scenarios(k).id);
        statePair = statePair && isscalar(unique(T.CHANNEL_STATE_HASH(idx)));
    end
end
[names,passed,detail] = addGate(names,passed,detail,'paired_absolute_trace', ...
    crn && statePair && all(T.CHANNEL_STATE_HASH~=0), ...
    'one underlying trace per seed and one state realization per seed/scenario');

noFeedback = ~feedback;
information = all(T.ACK_ATTEMPTED(noFeedback)==0);
[names,passed,detail] = addGate(names,passed,detail, ...
    'feedback_information_constraint',information, ...
    'periodic/state arms emit no ACK traffic');

standalone = strcmp(M.arm,'broadcast-standalone');
piggyback = strcmp(M.arm,'broadcast-piggyback');
hybrid = strcmp(M.arm,'broadcast-hybrid');
mechanism = all(M.ACK_ENTRIES_PIGGYBACKED(standalone)==0) && ...
    all(M.ACK_STANDALONE(piggyback)==0) && ...
    all(M.ACK_ENTRIES_PIGGYBACKED(piggyback)>0) && ...
    all(M.ACK_STANDALONE(hybrid)>0) && ...
    all(M.ACK_ENTRIES_PIGGYBACKED(hybrid)>0);
[names,passed,detail] = addGate(names,passed,detail,'mechanism_semantics', ...
    mechanism,'standalone, piggyback and hybrid obligations remain distinct');

[names,passed,detail] = addGate(names,passed,detail,'plant_stability', ...
    all(T.DIVERGED==0),sprintf('%d diverged 6-DOF runs',sum(T.DIVERGED)));

scenarioOrder = all(diff([R.scenarios.stationaryMeanLoss])>0);
for k = 1:numel(R.scenarios)
    idx = strcmp(T.scenario,R.scenarios(k).id);
    scenarioOrder = scenarioOrder && all(abs(T.stationaryMeanDataLoss(idx)- ...
        R.scenarios(k).stationaryMeanLoss)<1e-12);
end
[names,passed,detail] = addGate(names,passed,detail,'channel_cell_identity', ...
    scenarioOrder,'logged stationary channel marginals match the frozen registry');

gates = table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function S = summarizeRows(T,groups)

[G,S] = findgroups(T(:,groups));
S.n = splitapply(@numel,T.RMSE,G);
S.meanRMSE = splitapply(@mean,T.RMSE,G);
S.stdRMSE = splitapply(@std,T.RMSE,G);
S.safeFailures = splitapply(@sum,T.SAFEFAIL,G);
S.meanTrueAoI = splitapply(@mean,T.MEAN_TRUE_AOI,G);
S.meanEstimatedAoI = splitapply(@nanmeanLocal,T.MEAN_EST_AOI,G);
S.meanOfferedUtil = splitapply(@mean,T.OFFERED_UTIL,G);
S.meanChannelUtil = splitapply(@mean,T.CHANNEL_UTIL,G);
S.meanCollisions = splitapply(@mean,T.COLLISION_FRAMES,G);
S.meanEnergyProxyJ = splitapply(@mean,T.ENERGY_PROXY_J,G);

end


function y = nanmeanLocal(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function [names,passed,detail] = addGate( ...
    names,passed,detail,name,flag,textValue)

names{end+1,1}=name;
passed(end+1,1)=logical(flag);
detail{end+1,1}=textValue;

end


function snapshotFreeze(target)

root = projectRoot();
files = {'docs/EXP14_HOLDOUT_PLAN.md','utils/exp14Registry.m', ...
    'utils/exp14ChannelScenarios.m','configs/study2Exp14Config.m', ...
    'utils/applyExp14FrontierPoint.m','utils/applyExp14OODPoint.m', ...
    'utils/applyExp14OODMethod.m','utils/exp14EmptyRow.m', ...
    'utils/runExp14Cell.m','utils/pairedBootstrapCI.m','utils/wilsonCI.m', ...
    'network/sharedMediumConfig.m','network/advanceSharedMedium.m', ...
    'network/sharedMediumChannelSignature.m', ...
    'utils/generateSharedMediumTrace.m','simulation/simSwarmSharedMedium.m', ...
    'metrics/computeSharedMediumMetrics.m', ...
    'experiments/analyzeExp14Results.m'};
freezeDir = fullfile(target,'frozen_source');
mkdir(freezeDir);
for k = 1:numel(files)
    [~,name,ext] = fileparts(files{k});
    copyfile(fullfile(root,files{k}),fullfile(freezeDir,[name ext]));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14a_holdout_primary: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y = ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
