%% TCNS AB0.2 - ACK-cost-adjusted frozen O1 diagnostic
%
% Frozen in paper/tcns/AB0_ACK_COST_PROTOCOL.md before result generation.

startup;
close all;

R = startExperiment('tcns_ab0_ack_cost_adjusted_o1', ...
    ['Offline C0/C1/C2 cost sensitivity on immutable O1 actions; no ' ...
     'trajectory or scheduling behavior is rerun.']);

stageARun = fullfile(projectRoot(),'results', ...
    'tcns_o1_oracle_frontier_stage_a','2026-09-07_160426');
stageBRun = fullfile(projectRoot(),'results', ...
    'tcns_o1_oracle_frontier_stage_b','2026-09-07_162102');
rawA = readtable(fullfile(stageARun,'tidy.csv'),'TextType','string');
rawB = readtable(fullfile(stageBRun,'tidy.csv'),'TextType','string');
raw = [rawA;rawB];
raw.scenarioId = string(raw.scenarioId);
raw.armId = string(raw.armId);
raw.methodFamily = string(raw.methodFamily);
actions = [tcnsLoadO1ActionArchive(stageARun); ...
    tcnsLoadO1ActionArchive(stageBRun)];
actions.scenarioId = string(actions.scenarioId);
actions.linkClass = string(actions.linkClass);

scenarioIds = ["S2","S3","S4","S5","S6"];
seeds = (27020001:27020005)';
costModels = ["C0","C1","C2"];
matchingGridSize = 101;
rule = struct('meaningfulRmseFraction',0.02, ...
    'meaningfulCostFraction',0.05,'meaningfulRunLength',21, ...
    'narrowRunLength',11);

raw.adjustedAckC1Count = zeros(height(raw),1);
raw.adjustedAckC2Count = zeros(height(raw),1);
raw.evaluationCostC0_HzPerChannel = ...
    raw.evaluationCost025PerChannel_Hz;
raw.evaluationCostC1_HzPerChannel = ...
    raw.evaluationCost025PerChannel_Hz;
raw.evaluationCostC2_HzPerChannel = ...
    raw.evaluationCost025PerChannel_Hz;
actionGroupPass = true;
c2TuplePass = true;

for q = 1:height(raw)
    if raw.methodFamily(q)~="Centralized state oracle"
        continue;
    end
    [cfg,scenario] = tcnsGate6Scenario(raw.seed(q),raw.scenarioId(q));
    select = actions.scenarioId==raw.scenarioId(q) & ...
        actions.seed==raw.seed(q) & ...
        abs(actions.lambda-raw.oracleLambda(q))<1e-14;
    a = actions(select,:);
    actionGroupPass = actionGroupPass && ...
        height(a)==raw.oracleSendCount(q);
    ackAccounting = tcnsO1OfflineAckCounts(a,cfg,scenario);
    c1 = ackAccounting.c1Count;
    c2 = ackAccounting.c2Count;
    c2TuplePass = c2TuplePass && ackAccounting.c2AtMostC1;
    duration = scenario.horizon_s-scenario.evaluationStart_s;
    nChannels = nnz(cfg.swarm.A)+nnz(cfg.swarm.pin);
    raw.adjustedAckC1Count(q) = c1;
    raw.adjustedAckC2Count(q) = c2;
    raw.evaluationCostC1_HzPerChannel(q) = ...
        raw.evaluationCostC0_HzPerChannel(q)+0.25*c1/(duration*nChannels);
    raw.evaluationCostC2_HzPerChannel(q) = ...
        raw.evaluationCostC0_HzPerChannel(q)+0.25*c2/(duration*nChannels);
end
writetable(raw,fullfile(R.dir,'adjusted_runs.csv'));

operatingAll = table();
frontierAll = table();
budgetAll = table();
performanceAll = table();
comparisonRows = repmat(localComparisonRow(), ...
    numel(costModels)*numel(scenarioIds),1);
rowIndex = 0;

for cm = 1:numel(costModels)
    model = costModels(cm);
    costField = "evaluationCost"+model+"_HzPerChannel";
    for s = 1:numel(scenarioIds)
        sid = scenarioIds(s);
        x = raw(raw.scenarioId==sid,:);
        [G,armId] = findgroups(x.armId);
        family = splitapply(@(z) z(1),x.methodFamily,G);
        method = splitapply(@(z) z(1),x.method,G);
        parameterName = splitapply(@(z) z(1),x.parameterName,G);
        parameterValue = splitapply(@(z) z(1),x.parameterValue,G);
        period = splitapply(@(z) z(1),x.period_s,G);
        epsilon = splitapply(@(z) z(1),x.epsilonPosition_m,G);
        operating = table(armId,family,method,parameterName,parameterValue, ...
            period,epsilon,splitapply(@numel,x.seed,G), ...
            splitapply(@sum,x.failed,G),splitapply(@mean,x.primaryFormationRMSE_m,G), ...
            splitapply(@mean,x.(costField),G), ...
            'VariableNames',{'armId','methodFamily','method','parameterName', ...
            'parameterValue','period_s','epsilonPosition_m','seedCount', ...
            'failedRuns','meanPrimaryFormationRMSE_m', ...
            'meanEvaluationCost025PerChannel_Hz'});
        operating.scenarioId = repmat(sid,height(operating),1);
        operating.costModel = repmat(model,height(operating),1);
        C = tcnsO1CompareFrontiers(operating,matchingGridSize,rule);
        frontier = [C.periodicFrontier;C.oracleFrontier];
        frontier.frontierFamily = [repmat("Periodic",height(C.periodicFrontier),1); ...
            repmat("Centralized state oracle",height(C.oracleFrontier),1)];
        budget = C.budgetMatched;
        performance = C.performanceMatched;
        budget.scenarioId = repmat(sid,height(budget),1);
        budget.costModel = repmat(model,height(budget),1);
        performance.scenarioId = repmat(sid,height(performance),1);
        performance.costModel = repmat(model,height(performance),1);
        operatingAll = [operatingAll;operating]; %#ok<AGROW>
        frontierAll = [frontierAll;frontier]; %#ok<AGROW>
        budgetAll = [budgetAll;budget]; %#ok<AGROW>
        performanceAll = [performanceAll;performance]; %#ok<AGROW>

        rowIndex = rowIndex+1;
        comparisonRows(rowIndex) = localComparisonRow( ...
            model,sid,C);
    end
end
comparison = struct2table(comparisonRows);
writetable(operatingAll,fullfile(R.dir,'operating_points.csv'));
writetable(frontierAll,fullfile(R.dir,'frontiers.csv'));
writetable(budgetAll,fullfile(R.dir,'budget_matched.csv'));
writetable(performanceAll,fullfile(R.dir,'performance_matched.csv'));
writetable(comparison,fullfile(R.dir,'scenario_comparison.csv'));

support = groupsummary(comparison,'costModel','sum','convincing');
support.Properties.VariableNames{'sum_convincing'} = 'convincingSupportCount';
support.requiredSupportCount = repmat(2,height(support),1);
support.supportPass = support.convincingSupportCount>=2;
writetable(support,fullfile(R.dir,'support_count.csv'));

c0Expected = ["CONVINCING","MARGINAL_OR_NARROW","NO_HEADROOM", ...
    "CONVINCING","CONVINCING"];
c0 = comparison(comparison.costModel=="C0",:);
c0 = sortrows(c0,'scenarioId');
c0ExpectedSorted = table(scenarioIds',c0Expected', ...
    'VariableNames',{'scenarioId','classification'});
c0ExpectedSorted = sortrows(c0ExpectedSorted,'scenarioId');
c0ReproductionPass = isequal(c0.scenarioId,c0ExpectedSorted.scenarioId) && ...
    isequal(c0.classification,c0ExpectedSorted.classification);
monotoneCostPass = all(raw.evaluationCostC0_HzPerChannel<= ...
    raw.evaluationCostC2_HzPerChannel+1e-12) && ...
    all(raw.evaluationCostC2_HzPerChannel<= ...
    raw.evaluationCostC1_HzPerChannel+1e-12);
rowCountPass = height(raw)==625 && ...
    nnz(raw.methodFamily=="Centralized state oracle")==350;
c2 = support(support.costModel=="C2",:);
technicalPass = rowCountPass && actionGroupPass && c2TuplePass && ...
    c0ReproductionPass && monotoneCostPass && height(comparison)==15 && ...
    all(isfinite(comparison.budgetMeanDifference)) && ...
    all(isfinite(comparison.performanceMeanDifference));
if technicalPass && c2.supportPass
    decision = 'ACK_COST_SUPPORT_PRESERVED';
    recommendation = 'PROCEED_EXACT_BELIEF_AND_CALIBRATION';
else
    decision = 'STOP_ACK_BELIEF_IMPLEMENTATION';
    recommendation = 'RETURN_TO_RESEARCH_LEAD';
end

summary = struct('schemaVersion',1,'phase','AB0.2', ...
    'technicalStatus',localPassFail(technicalPass), ...
    'trajectoryRerunCount',0,'savedRunCount',height(raw), ...
    'o1RunCount',nnz(raw.methodFamily=="Centralized state oracle"), ...
    'actionCount',height(actions),'actionGroupPass',actionGroupPass, ...
    'c2TuplePass',c2TuplePass,'c0ReproductionPass',c0ReproductionPass, ...
    'monotoneCostPass',monotoneCostPass, ...
    'c1EqualsC2ForAllRuns',all(raw.adjustedAckC1Count==raw.adjustedAckC2Count), ...
    'costModels',costModels,'support',table2struct(support), ...
    'decision',decision,'recommendation',recommendation, ...
    'interpretation',[ ...
    'Costs only; frozen O1 actions and plant trajectories are unchanged. ' ...
    'C2 implements cumulative at-most-one ACK per link/delivery phase; ' ...
    'the causal simulator has pre- and post-scheduling delivery phases.']);
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','AB0_ACK_cost_support','Color','w', ...
    'Position',[100 100 1120 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile;
hold on;
for cm = 1:numel(costModels)
    x = comparison(comparison.costModel==costModels(cm),:);
    plot(categorical(x.scenarioId),x.budgetMeanDifference,'o-', ...
        'LineWidth',1.2,'DisplayName',costModels(cm));
end
yline(0,'--'); grid on; ylabel('mean \Delta RMSE [m]');
title('Budget matched: adjusted O1 minus periodic'); legend('Location','best');
nexttile;
hold on;
for cm = 1:numel(costModels)
    x = comparison(comparison.costModel==costModels(cm),:);
    plot(categorical(x.scenarioId),x.performanceMeanDifference,'o-', ...
        'LineWidth',1.2,'DisplayName',costModels(cm));
end
yline(0,'--'); grid on; ylabel('mean \Delta C [Hz/channel]');
title('Performance matched: adjusted O1 minus periodic'); legend('Location','best');
saveAllFigures(R);

fprintf('\nAB0 ACK-cost technical verdict: %s\n',localPassFail(technicalPass));
disp(comparison(:,{'costModel','scenarioId','budgetMeanDifference', ...
    'budgetFractionFavoringO1','performanceMeanDifference', ...
    'performanceFractionFavoringO1','classification'}));
disp(support);
fprintf('AB0 ACK-cost decision: %s\n',decision);
fprintf('Frozen next action: %s\n',recommendation);

save(fullfile(R.dir,'workspace.mat'),'raw','operatingAll','frontierAll', ...
    'budgetAll','performanceAll','comparison','support','summary');
finishExperiment(R);
if ~technicalPass
    error('tcns_ab0_ack_cost_adjusted_o1:TechnicalFailure', ...
        'AB0.2 technical validity failed.');
end


function row = localComparisonRow(model,sid,C)

row = struct('costModel',"",'scenarioId',"", ...
    'periodicFrontierPoints',NaN,'oracleFrontierPoints',NaN, ...
    'budgetMeanDifference',NaN,'budgetMedianDifference',NaN, ...
    'budgetFractionFavoringO1',NaN,'budgetMaximumAdvantage',NaN, ...
    'budgetMaximumDisadvantage',NaN,'budgetCrossings',NaN, ...
    'budgetLongestMeaningfulRun',NaN, ...
    'performanceMeanDifference',NaN,'performanceMedianDifference',NaN, ...
    'performanceFractionFavoringO1',NaN, ...
    'performanceMaximumAdvantage',NaN, ...
    'performanceMaximumDisadvantage',NaN,'performanceCrossings',NaN, ...
    'performanceLongestMeaningfulRun',NaN,'convincing',false, ...
    'marginalOrNarrow',false,'classification',"");
if nargin==0
    return;
end
row.costModel = model;
row.scenarioId = sid;
row.periodicFrontierPoints = height(C.periodicFrontier);
row.oracleFrontierPoints = height(C.oracleFrontier);
row.budgetMeanDifference = C.budgetStats.meanDifference;
row.budgetMedianDifference = C.budgetStats.medianDifference;
row.budgetFractionFavoringO1 = C.budgetStats.fractionFavoring;
row.budgetMaximumAdvantage = C.budgetStats.maximumAdvantage;
row.budgetMaximumDisadvantage = C.budgetStats.maximumDisadvantage;
row.budgetCrossings = C.budgetStats.crossings;
row.budgetLongestMeaningfulRun = C.budgetStats.longestMeaningfulRun;
row.performanceMeanDifference = C.performanceStats.meanDifference;
row.performanceMedianDifference = C.performanceStats.medianDifference;
row.performanceFractionFavoringO1 = C.performanceStats.fractionFavoring;
row.performanceMaximumAdvantage = C.performanceStats.maximumAdvantage;
row.performanceMaximumDisadvantage = C.performanceStats.maximumDisadvantage;
row.performanceCrossings = C.performanceStats.crossings;
row.performanceLongestMeaningfulRun = ...
    C.performanceStats.longestMeaningfulRun;
row.convincing = C.convincing;
row.marginalOrNarrow = C.marginalOrNarrow;
row.classification = C.classification;

end


function value = localPassFail(pass)

if pass, value = 'PASS'; else, value = 'FAIL'; end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
assert(fid>0,'AB0 cost: cannot create %s.',path);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleanup;

end
