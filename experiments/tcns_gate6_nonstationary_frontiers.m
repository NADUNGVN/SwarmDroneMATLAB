%% TCNS GATE 6 - Nonstationary frontier falsification
%
% Exact scenarios, grids, metrics and scientific stop rules are frozen in
% paper/tcns/GATE6_NONSTATIONARY_PROTOCOL.md.

startup;
close all;

R = startExperiment('tcns_gate6_nonstationary_frontiers', ...
    ['Decisive six-scenario development frontier campaign; scientific ' ...
     'go/no-go rule committed before execution.']);

scenarioIds = ["S1","S2","S3","S4","S5","S6"];
seeds = (27020001:27020005)';
periodSamples = [1 2 3 4 5 8 10 15 20 25 40];
epsilonSweep_m = [0.05 0.075 0.10 0.15 0.20 0.30 0.40 0.60 0.80 1.20 1.60];
retryInterval_s = 0.10;
matchingGridSize = 101;

[cfg0,scenario0] = tcnsGate6Scenario(seeds(1),'S1');
arms = tcnsFrontierArms(periodSamples,epsilonSweep_m, ...
    cfg0.swarm.dt,retryInterval_s,true);
nScenarios = numel(scenarioIds);
nArms = numel(arms);
nSeeds = numel(seeds);
nTasks = nScenarios*nArms*nSeeds;

taskScenario = zeros(nTasks,1);
taskArm = zeros(nTasks,1);
taskSeed = zeros(nTasks,1);
k = 0;
for s = 1:nScenarios
    for a = 1:nArms
        for r = 1:nSeeds
            k = k+1;
            taskScenario(k) = s;
            taskArm(k) = a;
            taskSeed(k) = seeds(r);
        end
    end
end

rawRows = repmat(tcnsFrontierRow(),nTasks,1);
fprintf('Running %d scenarios x %d arms x %d seeds = %d DI simulations.\n', ...
    nScenarios,nArms,nSeeds,nTasks);

parfor task = 1:nTasks
    [cfg,scenario] = tcnsGate6Scenario( ...
        taskSeed(task),scenarioIds(taskScenario(task)));
    rawRows(task) = runTcnsFrontierCell(cfg,arms(taskArm(task)),scenario);
end

raw = struct2table(rawRows);
writetable(raw,fullfile(R.dir,'tidy.csv'));

aggregateAll = table();
frontierAll = table();
budgetMatchedAll = table();
performanceMatchedAll = table();
comparisonRows = repmat(localComparisonRow(),nScenarios,1);

for s = 1:nScenarios
    scenarioId = scenarioIds(s);
    rawScenario = raw(raw.scenarioId==scenarioId,:);
    aggregate = aggregateTcnsFrontierRuns(rawScenario,arms,nSeeds);
    aggregate.scenarioId = repmat(scenarioId,height(aggregate),1);
    aggregate.scenario = repmat(rawScenario.scenario(1),height(aggregate),1);
    aggregate.isPareto = false(height(aggregate),1);

    pMask = aggregate.methodFamily=="Periodic" & aggregate.failedRuns==0;
    cMask = aggregate.methodFamily=="Control-aware" & aggregate.failedRuns==0;
    [frontierPeriodic,pKeep] = tcnsParetoFrontier(aggregate(pMask,:), ...
        'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m');
    [frontierControl,cKeep] = tcnsParetoFrontier(aggregate(cMask,:), ...
        'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m');
    pIndex = find(pMask);
    cIndex = find(cMask);
    aggregate.isPareto(pIndex(pKeep)) = true;
    aggregate.isPareto(cIndex(cKeep)) = true;

    matched = tcnsMatchFrontiers(frontierControl,frontierPeriodic, ...
        'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m', ...
        matchingGridSize);

    family = [repmat("Periodic",height(frontierPeriodic),1); ...
        repmat("Control-aware",height(frontierControl),1)];
    frontier = [frontierPeriodic;frontierControl];
    frontier.frontierFamily = family;

    budgetMatched = matched.budgetMatched;
    budgetMatched.scenarioId = repmat(scenarioId,height(budgetMatched),1);
    performanceMatched = matched.performanceMatched;
    performanceMatched.scenarioId = ...
        repmat(scenarioId,height(performanceMatched),1);

    aggregateAll = [aggregateAll;aggregate]; %#ok<AGROW>
    frontierAll = [frontierAll;frontier]; %#ok<AGROW>
    budgetMatchedAll = [budgetMatchedAll;budgetMatched]; %#ok<AGROW>
    performanceMatchedAll = ...
        [performanceMatchedAll;performanceMatched]; %#ok<AGROW>

    row = localComparisonRow();
    row.scenarioId = scenarioId;
    row.scenario = rawScenario.scenario(1);
    row.periodicFrontierPoints = height(frontierPeriodic);
    row.controlFrontierPoints = height(frontierControl);
    row.budgetOverlapLow = matched.budgetOverlap(1);
    row.budgetOverlapHigh = matched.budgetOverlap(2);
    row.performanceOverlapLow = matched.performanceOverlap(1);
    row.performanceOverlapHigh = matched.performanceOverlap(2);
    row.meanBudgetMatchedErrorDifference = ...
        matched.meanBudgetMatchedErrorDifference;
    row.fractionBudgetFavoringControl = ...
        matched.fractionBudgetGridFavoringA;
    row.meanPerformanceMatchedCostDifference = ...
        matched.meanPerformanceMatchedCostDifference;
    row.fractionPerformanceFavoringControl = ...
        matched.fractionPerformanceGridFavoringA;
    row.scenarioSupportsControl = ...
        row.meanBudgetMatchedErrorDifference<0 && ...
        row.fractionBudgetFavoringControl>0.5 && ...
        row.meanPerformanceMatchedCostDifference<0 && ...
        row.fractionPerformanceFavoringControl>0.5;
    comparisonRows(s) = row;
end

comparison = struct2table(comparisonRows);
writetable(aggregateAll,fullfile(R.dir,'aggregate.csv'));
writetable(frontierAll,fullfile(R.dir,'frontiers.csv'));
writetable(budgetMatchedAll,fullfile(R.dir,'budget_matched.csv'));
writetable(performanceMatchedAll,fullfile(R.dir,'performance_matched.csv'));
writetable(comparison,fullfile(R.dir,'scenario_comparison.csv'));

expectedRows = nTasks;
allFinitePass = height(raw)==expectedRows && all(~raw.failed) && ...
    all(isfinite(raw.primaryFormationRMSE_m)) && ...
    all(isfinite(raw.evaluationCost025PerChannel_Hz));
causalPass = all(raw.invariantViolations( ...
    raw.methodFamily=="Control-aware")==0);
tracePairingPass = localTracePairingPass(raw,scenarioIds,seeds,nArms);
noDivergencePass = ~any(raw.diverged);
frontierPass = all(comparison.periodicFrontierPoints>=3) && ...
    all(comparison.controlFrontierPoints>=3);
matchingPass = height(budgetMatchedAll)==nScenarios*matchingGridSize && ...
    height(performanceMatchedAll)==nScenarios*matchingGridSize && ...
    all(isfinite(budgetMatchedAll{:,1:4}),'all') && ...
    all(isfinite(performanceMatchedAll{:,1:4}),'all');
technicalPass = allFinitePass && causalPass && tracePairingPass && ...
    noDivergencePass && frontierPass && matchingPass;

nonstationary = comparison.scenarioId~="S1";
supportCount = nnz(comparison.scenarioSupportsControl(nonstationary));
if supportCount>=2
    scientificDecision = 'PROMISING';
elseif supportCount==1
    scientificDecision = 'WEAK';
else
    scientificDecision = 'STOP_CURRENT_MECHANISM';
end

manifest = cell(nScenarios*nSeeds,1);
k = 0;
for s = 1:nScenarios
    for r = 1:nSeeds
        k = k+1;
        [cfg,scenario] = tcnsGate6Scenario(seeds(r),scenarioIds(s));
        manifest{k} = struct('seed',seeds(r),'scenario',scenario, ...
            'network',cfg.net,'ack',cfg.ack,'tcns',localField(cfg,'tcns'), ...
            'fault',localField(cfg,'fault'));
    end
end
localWriteJson(fullfile(R.dir,'scenario_manifest.json'),manifest);

summary = struct();
summary.schemaVersion = 1;
summary.gate = 6;
summary.technicalStatus = localPassFail(technicalPass);
summary.scientificDecision = scientificDecision;
summary.classification = 'decisive development falsification';
summary.runCount = height(raw);
summary.scenarios = scenarioIds;
summary.seeds = seeds;
summary.periodSamples = periodSamples;
summary.epsilonSweep_m = epsilonSweep_m;
summary.retryInterval_s = retryInterval_s;
summary.matchingGridSize = matchingGridSize;
summary.allFinitePass = allFinitePass;
summary.causalPass = causalPass;
summary.tracePairingPass = tracePairingPass;
summary.noDivergencePass = noDivergencePass;
summary.frontierPass = frontierPass;
summary.matchingPass = matchingPass;
summary.saturatedRunCount = nnz(raw.saturationFraction>0);
summary.nonstationarySupportCount = supportCount;
summary.requiredSupportCount = 2;
summary.comparison = comparisonRows;
summary.interpretation = [ ...
    'Scientific decision follows the four-condition scenario rule frozen ' ...
    'before execution. A technical PASS does not override a WEAK or STOP ' ...
    'scientific decision.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','Gate6_nonstationary_frontiers','Color','w', ...
    'Position',[60 60 1350 820]);
tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
for s = 1:nScenarios
    nexttile;
    f = frontierAll(frontierAll.scenarioId==scenarioIds(s),:);
    p = f(f.frontierFamily=="Periodic",:);
    c = f(f.frontierFamily=="Control-aware",:);
    plot(p.meanEvaluationCost025PerChannel_Hz, ...
        p.meanPrimaryFormationRMSE_m,'o-', ...
        'Color',[0.25 0.25 0.25],'LineWidth',1.1, ...
        'MarkerFaceColor',[0.25 0.25 0.25]); hold on;
    plot(c.meanEvaluationCost025PerChannel_Hz, ...
        c.meanPrimaryFormationRMSE_m,'o-', ...
        'Color',[0.10 0.38 0.70],'LineWidth',1.1, ...
        'MarkerFaceColor',[0.10 0.38 0.70]);
    title(comparison.scenario(s),'Interpreter','none');
    xlabel('C_{0.25} [Hz/channel]');
    ylabel('primary RMSE [m]');
    grid on;
    if s==1
        legend({'periodic','control-aware'},'Location','best');
    end
end
saveAllFigures(R);

figure('Name','Gate6_matched_decision','Color','w', ...
    'Position',[100 100 1120 650]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
nexttile;
bar(categorical(comparison.scenarioId), ...
    comparison.meanBudgetMatchedErrorDifference, ...
    'FaceColor',[0.10 0.38 0.70]); hold on;
yline(0,'--');
ylabel('mean matched RMSE difference [m]');
title('Control-aware minus periodic; negative favors control-aware');
grid on;
nexttile;
bar(categorical(comparison.scenarioId), ...
    comparison.meanPerformanceMatchedCostDifference, ...
    'FaceColor',[0.10 0.38 0.70]); hold on;
yline(0,'--');
ylabel('mean matched cost difference [Hz/channel]');
xlabel('scenario');
grid on;
saveAllFigures(R);

fprintf('\nGate 6 technical verdict: %s\n',summary.technicalStatus);
for s = 1:nScenarios
    fprintf(['  %s %-27s dRMSE %+8.4f (%5.1f%% favor), ' ...
        'dCost %+8.3f (%5.1f%% favor), support %d\n'], ...
        comparison.scenarioId(s),comparison.scenario(s), ...
        comparison.meanBudgetMatchedErrorDifference(s), ...
        100*comparison.fractionBudgetFavoringControl(s), ...
        comparison.meanPerformanceMatchedCostDifference(s), ...
        100*comparison.fractionPerformanceFavoringControl(s), ...
        comparison.scenarioSupportsControl(s));
end
fprintf('Gate 6 scientific decision: %s (%d/5 nonstationary support)\n', ...
    scientificDecision,supportCount);

save(fullfile(R.dir,'workspace.mat'),'scenarioIds','seeds','arms','raw', ...
    'aggregateAll','frontierAll','budgetMatchedAll', ...
    'performanceMatchedAll','comparison','summary');
finishExperiment(R);

if ~technicalPass
    error('tcns_gate6_nonstationary_frontiers:TechnicalFailure', ...
        'Gate-6 technical validity criteria failed.');
end


function row = localComparisonRow()

row = struct('scenarioId',"",'scenario',"", ...
    'periodicFrontierPoints',NaN,'controlFrontierPoints',NaN, ...
    'budgetOverlapLow',NaN,'budgetOverlapHigh',NaN, ...
    'performanceOverlapLow',NaN,'performanceOverlapHigh',NaN, ...
    'meanBudgetMatchedErrorDifference',NaN, ...
    'fractionBudgetFavoringControl',NaN, ...
    'meanPerformanceMatchedCostDifference',NaN, ...
    'fractionPerformanceFavoringControl',NaN, ...
    'scenarioSupportsControl',false);

end


function pass = localTracePairingPass(raw,scenarioIds,seeds,nArms)

pass = true;
for s = 1:numel(scenarioIds)
    for r = 1:numel(seeds)
        q = raw(raw.scenarioId==scenarioIds(s) & raw.seed==seeds(r),:);
        pass = pass && height(q)==nArms && ...
            all(q.traceHashExact==q.traceHashExact(1));
    end
end

end


function value = localField(S,name)

if isfield(S,name), value = S.(name); else, value = struct(); end

end


function value = localPassFail(pass)

if pass, value = 'PASS'; else, value = 'FAIL'; end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
assert(fid>0,'Gate6: cannot create %s.',path);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleaner;

end
