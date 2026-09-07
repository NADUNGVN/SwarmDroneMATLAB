%% TCNS O1 - Centralized online-oracle frontier, Stage B
%
% Frozen before execution in paper/tcns/ORACLE_STAGE_B_PROTOCOL.md.

startup;
close all;

R = startExperiment('tcns_o1_oracle_frontier_stage_b', ...
    ['Frozen centralized current-state oracle expansion to S3/S4/S5 ' ...
     'after O1_STRONG_HEADROOM on S2/S6.']);

scenarioIds = ["S3","S4","S5"];
seeds = (27020001:27020005)';
periodSamples = [1 2 3 4 5 8 10 15 20 25 40];
lambdaSweep = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 ...
    1e-3 3e-3 1e-2 3e-2 1e-1 3e-1 1];
horizonSamples = 25;
matchingGridSize = 101;
rule = struct('meaningfulRmseFraction',0.02, ...
    'meaningfulCostFraction',0.05,'meaningfulRunLength',21, ...
    'narrowRunLength',11);

[cfg0,~] = tcnsGate6Scenario(seeds(1),scenarioIds(1));
arms = tcnsO1FrontierArms(periodSamples,lambdaSweep, ...
    cfg0.swarm.dt,horizonSamples);
nScenarios = numel(scenarioIds);
nSeeds = numel(seeds);
nArms = numel(arms);
nTasks = nScenarios*nSeeds*nArms;

taskScenario = zeros(nTasks,1);
taskSeed = zeros(nTasks,1);
taskArm = zeros(nTasks,1);
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
oracleOutputs = cell(nTasks,1);
fprintf(['Running %d scenarios x (%d periodic + %d O1) x %d seeds = ' ...
    '%d simulations.\n'],nScenarios,numel(periodSamples), ...
    numel(lambdaSweep),nSeeds,nTasks);

parfor task = 1:nTasks
    [cfg,scenario] = tcnsGate6Scenario( ...
        taskSeed(task),scenarioIds(taskScenario(task)));
    [row,out] = runTcnsFrontierCell( ...
        cfg,arms(taskArm(task)),scenario);
    rawRows(task) = row;
    if arms(taskArm(task)).kind=="centralized-state-oracle"
        oracleOutputs{task} = out;
    else
        oracleOutputs{task} = struct();
    end
end

raw = struct2table(rawRows);
writetable(raw,fullfile(R.dir,'tidy.csv'));
[periodicIdentityPass,periodicAudit] = ...
    tcnsO1PeriodicIdentityAudit(raw,scenarioIds,seeds);
writetable(periodicAudit,fullfile(R.dir,'periodic_identity_audit.csv'));

aggregateAll = table();
frontierAll = table();
budgetMatchedAll = table();
performanceMatchedAll = table();
comparisonRows = repmat(localComparisonRow(),nScenarios,1);

for s = 1:nScenarios
    sid = scenarioIds(s);
    rawScenario = raw(raw.scenarioId==sid,:);
    aggregate = aggregateTcnsFrontierRuns(rawScenario,arms,nSeeds);
    aggregate.scenarioId = repmat(sid,height(aggregate),1);
    aggregate.scenario = repmat(rawScenario.scenario(1),height(aggregate),1);
    aggregate.isPareto = false(height(aggregate),1);
    C = tcnsO1CompareFrontiers(aggregate,matchingGridSize,rule);

    pMask = aggregate.methodFamily=="Periodic" & aggregate.failedRuns==0;
    oMask = aggregate.methodFamily=="Centralized state oracle" & ...
        aggregate.failedRuns==0;
    pIndex = find(pMask);
    oIndex = find(oMask);
    aggregate.isPareto(pIndex(C.periodicKeep)) = true;
    aggregate.isPareto(oIndex(C.oracleKeep)) = true;
    frontier = [C.periodicFrontier;C.oracleFrontier];
    frontier.frontierFamily = [ ...
        repmat("Periodic",height(C.periodicFrontier),1); ...
        repmat("Centralized state oracle",height(C.oracleFrontier),1)];
    budget = C.budgetMatched;
    budget.scenarioId = repmat(sid,height(budget),1);
    performance = C.performanceMatched;
    performance.scenarioId = repmat(sid,height(performance),1);
    aggregateAll = [aggregateAll;aggregate]; %#ok<AGROW>
    frontierAll = [frontierAll;frontier]; %#ok<AGROW>
    budgetMatchedAll = [budgetMatchedAll;budget]; %#ok<AGROW>
    performanceMatchedAll = [performanceMatchedAll;performance]; %#ok<AGROW>

    row = localComparisonRow();
    row.scenarioId = sid;
    row.scenario = rawScenario.scenario(1);
    row.periodicFrontierPoints = height(C.periodicFrontier);
    row.oracleFrontierPoints = height(C.oracleFrontier);
    row.budgetOverlapLow = C.matched.budgetOverlap(1);
    row.budgetOverlapHigh = C.matched.budgetOverlap(2);
    row.performanceOverlapLow = C.matched.performanceOverlap(1);
    row.performanceOverlapHigh = C.matched.performanceOverlap(2);
    row = localAddStats(row,C.budgetStats,C.performanceStats);
    row.convincing = C.convincing;
    row.marginalOrNarrow = C.marginalOrNarrow;
    row.scenarioClassification = C.classification;
    comparisonRows(s) = row;
end

comparison = struct2table(comparisonRows);
writetable(aggregateAll,fullfile(R.dir,'aggregate.csv'));
writetable(frontierAll,fullfile(R.dir,'frontiers.csv'));
writetable(budgetMatchedAll,fullfile(R.dir,'budget_matched.csv'));
writetable(performanceMatchedAll, ...
    fullfile(R.dir,'performance_matched.csv'));
writetable(comparison,fullfile(R.dir,'scenario_comparison.csv'));

[actionDiagnostics,perLinkDiagnostics,timeDiagnostics] = ...
    tcnsO1CollectDiagnostics(oracleOutputs,raw,arms, ...
    taskArm,taskScenario,scenarioIds);
writetable(actionDiagnostics,fullfile(R.dir,'oracle_actions.csv'));
writetable(perLinkDiagnostics,fullfile(R.dir,'oracle_per_link.csv'));
writetable(timeDiagnostics,fullfile(R.dir,'oracle_event_time_traces.csv'));
oracleRaw = raw(raw.methodFamily=="Centralized state oracle",:);
trafficSummary = groupsummary(oracleRaw,{'scenarioId','oracleLambda'}, ...
    'mean',{'eventAllocationRatio','oracleEventAllocationRatio', ...
    'oracleUsefulDeliveryCount','oracleFailedTransmissionCount', ...
    'oracleNoInformationAttemptCount','oracleMeanUsefulResidualBefore_m', ...
    'oracleMeanUsefulResidualAfter_m'});
writetable(trafficSummary,fullfile(R.dir,'traffic_summary.csv'));

allFinitePass = height(raw)==nTasks && all(~raw.failed) && ...
    all(isfinite(raw.primaryFormationRMSE_m)) && ...
    all(isfinite(raw.evaluationCost025PerChannel_Hz));
tracePairingPass = localTracePairingPass(raw,scenarioIds,seeds,nArms);
noDivergencePass = ~any(raw.diverged);
oracleContractPass = tcnsO1OracleContractPass( ...
    oracleOutputs,arms,taskArm);
frontierPass = all(comparison.periodicFrontierPoints>=3) && ...
    all(comparison.oracleFrontierPoints>=3);
matchingPass = height(budgetMatchedAll)==nScenarios*matchingGridSize && ...
    height(performanceMatchedAll)==nScenarios*matchingGridSize && ...
    all(isfinite(budgetMatchedAll{:,1:4}),'all') && ...
    all(isfinite(performanceMatchedAll{:,1:4}),'all');
technicalPass = allFinitePass && tracePairingPass && ...
    noDivergencePass && oracleContractPass && periodicIdentityPass && ...
    frontierPass && matchingPass;

stageAPath = fullfile(projectRoot(),'results', ...
    'tcns_o1_oracle_frontier_stage_a','2026-09-07_160426', ...
    'scenario_comparison.csv');
stageA = readtable(stageAPath,'TextType','string');
stageAConvincing = nnz(localLogical(stageA.convincing));
stageBConvincing = nnz(comparison.convincing);
finalSupportCount = stageAConvincing+stageBConvincing;
finalSupportPass = technicalPass && finalSupportCount>=2;
if finalSupportPass
    finalDecision = 'O1_FINAL_SUPPORT';
    recommendation = 'GO_ACK_BELIEF_POLICY';
else
    finalDecision = 'O1_FINAL_SUPPORT_NOT_ESTABLISHED';
    recommendation = 'RESEARCH_LEAD_REVIEW_REQUIRED';
end

summary = struct();
summary.schemaVersion = 1;
summary.gate = 'centralized-online-oracle-frontier-stage-b';
summary.label = 'centralized_state_oracle';
summary.stageATechnicalStatus = 'PASS';
summary.stageAClassification = 'O1_STRONG_HEADROOM';
summary.technicalStatus = localPassFail(technicalPass);
summary.stageBScenarioCount = nScenarios;
summary.runCount = height(raw);
summary.scenarios = scenarioIds;
summary.seeds = seeds;
summary.periodSamples = periodSamples;
summary.lambdaSweep = lambdaSweep;
summary.horizonSamples = horizonSamples;
summary.matchingGridSize = matchingGridSize;
summary.rule = rule;
summary.periodicIdentityPass = periodicIdentityPass;
summary.tracePairingPass = tracePairingPass;
summary.oracleContractPass = oracleContractPass;
summary.noDivergencePass = noDivergencePass;
summary.frontierPass = frontierPass;
summary.matchingPass = matchingPass;
summary.actionCount = height(actionDiagnostics);
summary.acceptedUsefulDeliveryCount = nnz(actionDiagnostics.accepted);
summary.failedTransmissionCount = nnz(actionDiagnostics.dropped);
summary.noInformationAttemptCount = ...
    height(actionDiagnostics)-nnz(actionDiagnostics.accepted);
summary.actualSaturatedRunCount = nnz(raw.saturationFraction>0);
summary.oraclePredictedSaturationRunCount = nnz( ...
    oracleRaw.oracleEvaluationPredictedSaturationFraction>0);
summary.stageAConvincingCount = stageAConvincing;
summary.stageBConvincingCount = stageBConvincing;
summary.finalConvincingSupportCount = finalSupportCount;
summary.requiredSupportCount = 2;
summary.finalSupportPass = finalSupportPass;
summary.finalDecision = finalDecision;
summary.recommendation = recommendation;
summary.o2Required = false;
summary.comparison = comparisonRows;
summary.interpretation = [ ...
    'O1 remains privileged and non-implementable. Stage B measures breadth ' ...
    'under the unchanged Stage-A rule; no held-out seed or distributed ' ...
    'belief policy was opened.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','O1_stage_b_frontiers','Color','w', ...
    'Position',[60 80 1350 440]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for s = 1:nScenarios
    nexttile;
    f = frontierAll(frontierAll.scenarioId==scenarioIds(s),:);
    p = f(f.frontierFamily=="Periodic",:);
    o = f(f.frontierFamily=="Centralized state oracle",:);
    plot(p.meanEvaluationCost025PerChannel_Hz, ...
        p.meanPrimaryFormationRMSE_m,'o-', ...
        'Color',[0.25 0.25 0.25],'MarkerFaceColor',[0.25 0.25 0.25], ...
        'LineWidth',1.2); hold on;
    plot(o.meanEvaluationCost025PerChannel_Hz, ...
        o.meanPrimaryFormationRMSE_m,'s-', ...
        'Color',[0.68 0.20 0.13],'MarkerFaceColor',[0.68 0.20 0.13], ...
        'LineWidth',1.2);
    title(comparison.scenario(s),'Interpreter','none');
    xlabel('C_{0.25} [Hz/channel]'); ylabel('primary RMSE [m]');
    grid on;
    if s==1
        legend({'periodic','centralized state oracle'},'Location','best');
    end
end

figure('Name','O1_stage_b_matched_means','Color','w', ...
    'Position',[100 100 1120 650]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
nexttile;
bar(categorical(comparison.scenarioId),comparison.budgetMeanDifference, ...
    'FaceColor',[0.68 0.20 0.13]); hold on; yline(0,'--'); grid on;
ylabel('mean \Delta RMSE [m]');
title('O1 minus periodic: budget matched');
nexttile;
bar(categorical(comparison.scenarioId), ...
    comparison.performanceMeanDifference, ...
    'FaceColor',[0.68 0.20 0.13]); hold on; yline(0,'--'); grid on;
ylabel('mean \Delta C_{0.25} [Hz/channel]'); xlabel('scenario');
title('O1 minus periodic: performance matched');

figure('Name','O1_stage_b_event_allocation','Color','w', ...
    'Position',[60 80 1350 440]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for s = 1:nScenarios
    x = trafficSummary(trafficSummary.scenarioId==scenarioIds(s),:);
    nexttile;
    semilogx(max(x.oracleLambda,1e-7), ...
        x.mean_oracleEventAllocationRatio,'o-','LineWidth',1.2);
    yline(1,'--'); grid on;
    title(scenarioIds(s)+" event allocation");
    xlabel('\lambda (zero at 10^{-7})'); ylabel('R_{event}');
end
saveAllFigures(R);

fprintf('\nO1 Stage-B technical verdict: %s\n',localPassFail(technicalPass));
for s = 1:nScenarios
    fprintf(['  %s %-27s dRMSE mean/median %+9.5f/%+9.5f ' ...
        '(%5.1f%% favor, run %d); dCost %+9.4f/%+9.4f ' ...
        '(%5.1f%% favor, run %d) => %s\n'], ...
        comparison.scenarioId(s),comparison.scenario(s), ...
        comparison.budgetMeanDifference(s), ...
        comparison.budgetMedianDifference(s), ...
        100*comparison.budgetFractionFavoringO1(s), ...
        comparison.budgetLongestMeaningfulRun(s), ...
        comparison.performanceMeanDifference(s), ...
        comparison.performanceMedianDifference(s), ...
        100*comparison.performanceFractionFavoringO1(s), ...
        comparison.performanceLongestMeaningfulRun(s), ...
        comparison.scenarioClassification(s));
end
fprintf('Final convincing support: %d/5 (required >=2)\n',finalSupportCount);
fprintf('Final O1 decision: %s\n',finalDecision);
fprintf('Research recommendation: %s\n',recommendation);

save(fullfile(R.dir,'workspace.mat'),'scenarioIds','seeds','arms','raw', ...
    'aggregateAll','frontierAll','budgetMatchedAll', ...
    'performanceMatchedAll','comparison','summary');
finishExperiment(R);

if ~technicalPass
    error('tcns_o1_oracle_frontier_stage_b:TechnicalFailure', ...
        'O1 Stage-B technical validity criteria failed.');
end


function row = localComparisonRow()

row = struct('scenarioId',"",'scenario',"", ...
    'periodicFrontierPoints',NaN,'oracleFrontierPoints',NaN, ...
    'budgetOverlapLow',NaN,'budgetOverlapHigh',NaN, ...
    'performanceOverlapLow',NaN,'performanceOverlapHigh',NaN, ...
    'budgetMeanDifference',NaN,'budgetMedianDifference',NaN, ...
    'budgetFractionFavoringO1',NaN,'budgetMaximumAdvantage',NaN, ...
    'budgetMaximumDisadvantage',NaN,'budgetCrossings',NaN, ...
    'budgetLongestFavoringRun',NaN,'budgetLongestMeaningfulRun',NaN, ...
    'performanceMeanDifference',NaN,'performanceMedianDifference',NaN, ...
    'performanceFractionFavoringO1',NaN, ...
    'performanceMaximumAdvantage',NaN, ...
    'performanceMaximumDisadvantage',NaN,'performanceCrossings',NaN, ...
    'performanceLongestFavoringRun',NaN, ...
    'performanceLongestMeaningfulRun',NaN,'convincing',false, ...
    'marginalOrNarrow',false,'scenarioClassification',"");

end


function row = localAddStats(row,budget,performance)

row.budgetMeanDifference = budget.meanDifference;
row.budgetMedianDifference = budget.medianDifference;
row.budgetFractionFavoringO1 = budget.fractionFavoring;
row.budgetMaximumAdvantage = budget.maximumAdvantage;
row.budgetMaximumDisadvantage = budget.maximumDisadvantage;
row.budgetCrossings = budget.crossings;
row.budgetLongestFavoringRun = budget.longestFavoringRun;
row.budgetLongestMeaningfulRun = budget.longestMeaningfulRun;
row.performanceMeanDifference = performance.meanDifference;
row.performanceMedianDifference = performance.medianDifference;
row.performanceFractionFavoringO1 = performance.fractionFavoring;
row.performanceMaximumAdvantage = performance.maximumAdvantage;
row.performanceMaximumDisadvantage = performance.maximumDisadvantage;
row.performanceCrossings = performance.crossings;
row.performanceLongestFavoringRun = performance.longestFavoringRun;
row.performanceLongestMeaningfulRun = performance.longestMeaningfulRun;

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


function value = localLogical(x)

if islogical(x)
    value = x;
elseif isnumeric(x)
    value = x~=0;
else
    value = strcmpi(string(x),'true') | string(x)=="1";
end

end


function value = localPassFail(pass)

if pass, value = 'PASS'; else, value = 'FAIL'; end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
assert(fid>0,'O1 Stage B: cannot create %s.',path);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleaner;

end
