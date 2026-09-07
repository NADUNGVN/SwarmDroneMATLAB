%% TCNS PREDICTIVE VOI - Small online-policy sanity experiment
%
% Frozen protocol: paper/tcns/PREDICTIVE_VOI_SANITY_PROTOCOL.md

startup;
close all;

R = startExperiment('tcns_predictive_voi_small_sanity', ...
    ['One-seed S2/S6 online falsification of the causal in-flight-aware ' ...
     'one-shot VoI threshold policy.']);

scenarioIds = ["S2","S6"];
seed = 27020001;
periodSamples = [1 2 3 4 5 8 10 15 20 25 40];
prices = [0 1e-8 3e-8 1e-7 3e-7 1e-6 3e-6 1e-5 3e-5 ...
    1e-4 3e-4 1e-3 3e-3 1e-2 1];
horizonSamples = 25;
arms = localArms(periodSamples,prices,0.02,horizonSamples);
nTasks = numel(scenarioIds)*numel(arms);
rows = repmat(tcnsFrontierRow(),nTasks,1);

q = 0;
for s = 1:numel(scenarioIds)
    for a = 1:numel(arms)
        q = q+1;
        [cfg,scenario] = tcnsGate6Scenario(seed,scenarioIds(s));
        rows(q) = runTcnsFrontierCell(cfg,arms(a),scenario);
    end
end
raw = struct2table(rows);
writetable(raw,fullfile(R.dir,'tidy.csv'));

aggregateAll = table();
frontierAll = table();
budgetMatchedAll = table();
performanceMatchedAll = table();
decisionRows = repmat(localDecisionRow(),numel(scenarioIds),1);

for s = 1:numel(scenarioIds)
    sid = scenarioIds(s);
    x = raw(raw.scenarioId==sid,:);
    aggregate = aggregateTcnsFrontierRuns(x,arms,1);
    aggregate.scenarioId = repmat(sid,height(aggregate),1);
    aggregate.scenario = repmat(x.scenario(1),height(aggregate),1);

    p = aggregate(aggregate.methodFamily=="Periodic" & ...
        aggregate.failedRuns==0,:);
    v = aggregate(aggregate.methodFamily=="Predictive-VoI" & ...
        aggregate.failedRuns==0,:);
    frontierP = tcnsParetoFrontier(p, ...
        'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m');
    frontierV = tcnsParetoFrontier(v, ...
        'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m');
    matched = tcnsMatchFrontiers(frontierV,frontierP, ...
        'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m',101);

    frontierP.frontierFamily = repmat("Periodic",height(frontierP),1);
    frontierV.frontierFamily = repmat("Predictive-VoI",height(frontierV),1);
    frontier = [frontierP;frontierV];
    frontier.scenarioId = repmat(sid,height(frontier),1);
    budgetMatched = matched.budgetMatched;
    budgetMatched.scenarioId = repmat(sid,height(budgetMatched),1);
    performanceMatched = matched.performanceMatched;
    performanceMatched.scenarioId = repmat(sid,height(performanceMatched),1);

    predictiveRaw = x(x.methodFamily=="Predictive-VoI",:);
    interior = predictiveRaw.voiPrice>0 & predictiveRaw.voiPrice<1 & ...
        isfinite(predictiveRaw.voiEventAllocationRatio);
    d = localDecisionRow();
    d.scenarioId = sid;
    d.scenario = x.scenario(1);
    d.predictiveDistinctCosts = numel(unique(round( ...
        predictiveRaw.evaluationCost025PerChannel_Hz,10)));
    d.unsaturatedPredictivePoints = ...
        nnz(predictiveRaw.saturationFraction==0);
    d.periodicFrontierPoints = height(frontierP);
    d.predictiveFrontierPoints = height(frontierV);
    d.meanBudgetMatchedErrorDifference = ...
        matched.meanBudgetMatchedErrorDifference;
    d.fractionBudgetFavoringPredictive = ...
        matched.fractionBudgetGridFavoringA;
    d.meanPerformanceMatchedCostDifference = ...
        matched.meanPerformanceMatchedCostDifference;
    d.fractionPerformanceFavoringPredictive = ...
        matched.fractionPerformanceGridFavoringA;
    d.frontierHeadroom = d.fractionBudgetFavoringPredictive>0.25 || ...
        d.fractionPerformanceFavoringPredictive>0.25;
    d.meanInteriorEventAllocationRatio = ...
        mean(predictiveRaw.voiEventAllocationRatio(interior),'omitnan');
    d.eventConcentrationPass = ...
        d.meanInteriorEventAllocationRatio>1.15;
    d.maxBeliefCandidates = max(predictiveRaw.voiMaxCandidateCount);
    d.totalKnownFailureObservations = ...
        sum(predictiveRaw.voiKnownFailureCount);
    d.meanInFlightDiscount = ...
        mean(predictiveRaw.voiMeanInFlightDiscount,'omitnan');
    decisionRows(s) = d;

    aggregateAll = [aggregateAll;aggregate]; %#ok<AGROW>
    frontierAll = [frontierAll;frontier]; %#ok<AGROW>
    budgetMatchedAll = [budgetMatchedAll;budgetMatched]; %#ok<AGROW>
    performanceMatchedAll = ...
        [performanceMatchedAll;performanceMatched]; %#ok<AGROW>
end

decision = struct2table(decisionRows);
writetable(aggregateAll,fullfile(R.dir,'aggregate.csv'));
writetable(frontierAll,fullfile(R.dir,'frontiers.csv'));
writetable(budgetMatchedAll,fullfile(R.dir,'budget_matched.csv'));
writetable(performanceMatchedAll,fullfile(R.dir,'performance_matched.csv'));
writetable(decision,fullfile(R.dir,'decision.csv'));

causalMask = raw.methodFamily~="Periodic";
tracePass = true;
for s = 1:numel(scenarioIds)
    tracePass = tracePass && isscalar(unique( ...
        raw.traceHashExact(raw.scenarioId==scenarioIds(s))));
end
technicalPass = height(raw)==nTasks && all(~raw.failed) && ...
    all(isfinite(raw.primaryFormationRMSE_m)) && ...
    all(isfinite(raw.evaluationCost025PerChannel_Hz)) && ...
    all(raw.invariantViolations(causalMask)==0) && ...
    ~any(raw.diverged) && tracePass && ...
    all(decision.predictiveDistinctCosts>=5) && ...
    all(decision.unsaturatedPredictivePoints>=3) && ...
    all(decision.periodicFrontierPoints>=3) && ...
    all(decision.predictiveFrontierPoints>=3) && ...
    all(decision.maxBeliefCandidates>=2) && ...
    all(decision.totalKnownFailureObservations>0) && ...
    all(isfinite(decision.meanInFlightDiscount));
scientificPass = technicalPass && any(decision.frontierHeadroom) && ...
    all(decision.eventConcentrationPass);
if ~technicalPass
    scientificDecision = 'INVALID_OR_OUT_OF_SCOPE';
elseif scientificPass
    scientificDecision = 'MECHANISM_PROMISING';
else
    scientificDecision = 'STOP_PREDICTIVE_MECHANISM';
end

figure('Name','Predictive_VoI_small_sanity_frontiers','Color','w', ...
    'Position',[100 100 1050 430]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
for s = 1:numel(scenarioIds)
    nexttile;
    f = frontierAll(frontierAll.scenarioId==scenarioIds(s),:);
    p = f(f.frontierFamily=="Periodic",:);
    v = f(f.frontierFamily=="Predictive-VoI",:);
    plot(p.meanEvaluationCost025PerChannel_Hz, ...
        p.meanPrimaryFormationRMSE_m,'o-','LineWidth',1.1, ...
        'Color',[0.25 0.25 0.25],'MarkerFaceColor',[0.25 0.25 0.25]);
    hold on;
    plot(v.meanEvaluationCost025PerChannel_Hz, ...
        v.meanPrimaryFormationRMSE_m,'o-','LineWidth',1.1, ...
        'Color',[0.10 0.42 0.72],'MarkerFaceColor',[0.10 0.42 0.72]);
    title(decision.scenario(s),'Interpreter','none');
    xlabel('C_{0.25} [Hz/channel]');
    ylabel('primary formation RMSE [m]');
    grid on;
    legend({'periodic','predictive VoI'},'Location','best');
end
saveAllFigures(R);

summary = struct();
summary.schemaVersion = 1;
summary.classification = 'one-seed online-policy development falsification';
summary.technicalStatus = localPassFail(technicalPass);
summary.scientificDecision = scientificDecision;
summary.runCount = height(raw);
summary.seed = seed;
summary.scenarios = scenarioIds;
summary.periodSamples = periodSamples;
summary.voiPrices = prices;
summary.horizonSamples = horizonSamples;
summary.tracePass = tracePass;
summary.saturatedRunCount = nnz(raw.saturationFraction>0);
summary.decision = decisionRows;
summary.warning = [ ...
    'One development seed and narrow exact-belief channel scope; no ' ...
    'inferential or held-out claim is permitted.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

fprintf('\nPredictive-VoI online sanity\n');
disp(decision(:,{'scenarioId','predictiveDistinctCosts', ...
    'meanBudgetMatchedErrorDifference','fractionBudgetFavoringPredictive', ...
    'meanPerformanceMatchedCostDifference', ...
    'fractionPerformanceFavoringPredictive', ...
    'meanInteriorEventAllocationRatio','frontierHeadroom', ...
    'eventConcentrationPass'}));
fprintf('Technical status: %s\n',summary.technicalStatus);
fprintf('Scientific decision: %s\n',scientificDecision);

finishExperiment(R);


function arms = localArms(periodSamples,prices,h,horizonSamples)

prototype = struct('id',"",'family',"",'label',"",'kind',"", ...
    'parameterName',"",'parameterValue',NaN,'period_s',NaN, ...
    'epsilon_m',NaN,'retry_s',NaN,'voiPrice',NaN, ...
    'voiHorizonSamples',NaN);
nP = numel(periodSamples);
nV = numel(prices);
arms = repmat(prototype,nP+nV+2,1);
for q = 1:nP
    arms(q).id = "PS"+compose('%03d',periodSamples(q));
    arms(q).family = "Periodic";
    arms(q).label = "Periodic-"+periodSamples(q)+"step";
    arms(q).kind = "periodic";
    arms(q).parameterName = "periodSamples";
    arms(q).parameterValue = periodSamples(q);
    arms(q).period_s = periodSamples(q)*h;
end
for q = 1:nV
    k = nP+q;
    arms(k).id = "PV"+compose('%02d',q);
    arms(k).family = "Predictive-VoI";
    arms(k).label = "Predictive-VoI";
    arms(k).kind = "predictive-voi";
    arms(k).parameterName = "voiPrice";
    arms(k).parameterValue = prices(q);
    arms(k).voiPrice = prices(q);
    arms(k).voiHorizonSamples = horizonSamples;
end
k = nP+nV+1;
arms(k).id = "CAUSALV3";
arms(k).family = "Historical reference";
arms(k).label = "Causal-v3 frozen";
arms(k).kind = "legacy";
arms(k).parameterName = "frozen";
k = k+1;
arms(k).id = "GATE4STOPPED";
arms(k).family = "Stopped reference";
arms(k).label = "Gate-4 stopped";
arms(k).kind = "control-aware";
arms(k).parameterName = "epsilonPosition_m";
arms(k).parameterValue = 0.4;
arms(k).epsilon_m = 0.4;
arms(k).retry_s = 0.10;

end


function row = localDecisionRow()

row = struct('scenarioId',"",'scenario',"", ...
    'predictiveDistinctCosts',NaN,'unsaturatedPredictivePoints',NaN, ...
    'periodicFrontierPoints',NaN,'predictiveFrontierPoints',NaN, ...
    'meanBudgetMatchedErrorDifference',NaN, ...
    'fractionBudgetFavoringPredictive',NaN, ...
    'meanPerformanceMatchedCostDifference',NaN, ...
    'fractionPerformanceFavoringPredictive',NaN, ...
    'frontierHeadroom',false,'meanInteriorEventAllocationRatio',NaN, ...
    'eventConcentrationPass',false,'maxBeliefCandidates',NaN, ...
    'totalKnownFailureObservations',NaN,'meanInFlightDiscount',NaN);

end


function value = localPassFail(tf)

if tf, value = 'PASS'; else, value = 'FAIL'; end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
if fid<0
    error('tcnsPredictiveVoiSanity:WriteJson','Cannot open %s.',path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end
