%% TCNS O1 - Centralized online-oracle frontier, Stage A
%
% Frozen before execution in paper/tcns/ORACLE_FRONTIER_PROTOCOL.md.

startup;
close all;

R = startExperiment('tcns_o1_oracle_frontier_stage_a', ...
    ['Development-only centralized current-state oracle frontier on S2/S6; ' ...
     'privileged online diagnostic, never an implementable policy.']);

frozenPushedHead = ...
    '0487e2a5f3e255f59eb0c824be430991eb8d7474';
scenarioIds = ["S2","S6"];
seeds = (27020001:27020005)';
periodSamples = [1 2 3 4 5 8 10 15 20 25 40];
lambdaSweep = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 ...
    1e-3 3e-3 1e-2 3e-2 1e-1 3e-1 1];
horizonSamples = 25;
matchingGridSize = 101;
meaningfulRmseFraction = 0.02;
meaningfulCostFraction = 0.05;
meaningfulRunLength = 21;
narrowRunLength = 11;

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
    localPeriodicIdentityAudit(raw,scenarioIds,seeds);
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

    pMask = aggregate.methodFamily=="Periodic" & ...
        aggregate.failedRuns==0;
    oMask = aggregate.methodFamily=="Centralized state oracle" & ...
        aggregate.failedRuns==0;
    [periodicFrontier,pKeep] = tcnsParetoFrontier( ...
        aggregate(pMask,:),'meanEvaluationCost025PerChannel_Hz', ...
        'meanPrimaryFormationRMSE_m');
    [oracleFrontier,oKeep] = tcnsParetoFrontier( ...
        aggregate(oMask,:),'meanEvaluationCost025PerChannel_Hz', ...
        'meanPrimaryFormationRMSE_m');
    pIndex = find(pMask);
    oIndex = find(oMask);
    aggregate.isPareto(pIndex(pKeep)) = true;
    aggregate.isPareto(oIndex(oKeep)) = true;

    matched = tcnsMatchFrontiers(oracleFrontier,periodicFrontier, ...
        'meanEvaluationCost025PerChannel_Hz', ...
        'meanPrimaryFormationRMSE_m',matchingGridSize);
    budgetStats = localDifferenceStats( ...
        matched.budgetMatched.errorDifferenceAminusB, ...
        matched.budgetMatched.formationErrorB,meaningfulRmseFraction);
    performanceStats = localDifferenceStats( ...
        matched.performanceMatched.costDifferenceAminusB, ...
        matched.performanceMatched.communicationCostB, ...
        meaningfulCostFraction);
    convincing = localBasicSupport(budgetStats) && ...
        localBasicSupport(performanceStats) && ...
        budgetStats.longestMeaningfulRun>=meaningfulRunLength && ...
        performanceStats.longestMeaningfulRun>=meaningfulRunLength;
    marginal = ~convincing && (( ...
        budgetStats.longestMeaningfulRun>=narrowRunLength && ...
        performanceStats.longestMeaningfulRun>=narrowRunLength) || ...
        (localBasicSupport(budgetStats) && ...
         localBasicSupport(performanceStats)));

    budgetMatched = matched.budgetMatched;
    budgetMatched.relativeAdvantageO1 = ...
        -budgetMatched.errorDifferenceAminusB ./ ...
        budgetMatched.formationErrorB;
    budgetMatched.meaningfulO1Advantage = ...
        budgetMatched.relativeAdvantageO1>=meaningfulRmseFraction;
    budgetMatched.scenarioId = repmat(sid,height(budgetMatched),1);
    performanceMatched = matched.performanceMatched;
    performanceMatched.relativeAdvantageO1 = ...
        -performanceMatched.costDifferenceAminusB ./ ...
        performanceMatched.communicationCostB;
    performanceMatched.meaningfulO1Advantage = ...
        performanceMatched.relativeAdvantageO1>=meaningfulCostFraction;
    performanceMatched.scenarioId = ...
        repmat(sid,height(performanceMatched),1);

    frontier = [periodicFrontier;oracleFrontier];
    frontier.frontierFamily = [ ...
        repmat("Periodic",height(periodicFrontier),1); ...
        repmat("Centralized state oracle",height(oracleFrontier),1)];
    aggregateAll = [aggregateAll;aggregate]; %#ok<AGROW>
    frontierAll = [frontierAll;frontier]; %#ok<AGROW>
    budgetMatchedAll = [budgetMatchedAll;budgetMatched]; %#ok<AGROW>
    performanceMatchedAll = ...
        [performanceMatchedAll;performanceMatched]; %#ok<AGROW>

    row = localComparisonRow();
    row.scenarioId = sid;
    row.scenario = rawScenario.scenario(1);
    row.periodicFrontierPoints = height(periodicFrontier);
    row.oracleFrontierPoints = height(oracleFrontier);
    row.budgetOverlapLow = matched.budgetOverlap(1);
    row.budgetOverlapHigh = matched.budgetOverlap(2);
    row.performanceOverlapLow = matched.performanceOverlap(1);
    row.performanceOverlapHigh = matched.performanceOverlap(2);
    row.budgetMeanDifference = budgetStats.meanDifference;
    row.budgetMedianDifference = budgetStats.medianDifference;
    row.budgetFractionFavoringO1 = budgetStats.fractionFavoring;
    row.budgetMaximumAdvantage = budgetStats.maximumAdvantage;
    row.budgetMaximumDisadvantage = budgetStats.maximumDisadvantage;
    row.budgetCrossings = budgetStats.crossings;
    row.budgetLongestFavoringRun = budgetStats.longestFavoringRun;
    row.budgetLongestMeaningfulRun = budgetStats.longestMeaningfulRun;
    row.performanceMeanDifference = performanceStats.meanDifference;
    row.performanceMedianDifference = performanceStats.medianDifference;
    row.performanceFractionFavoringO1 = performanceStats.fractionFavoring;
    row.performanceMaximumAdvantage = performanceStats.maximumAdvantage;
    row.performanceMaximumDisadvantage = ...
        performanceStats.maximumDisadvantage;
    row.performanceCrossings = performanceStats.crossings;
    row.performanceLongestFavoringRun = ...
        performanceStats.longestFavoringRun;
    row.performanceLongestMeaningfulRun = ...
        performanceStats.longestMeaningfulRun;
    row.convincing = convincing;
    row.marginalOrNarrow = marginal;
    if convincing
        row.scenarioClassification = "CONVINCING";
    elseif marginal
        row.scenarioClassification = "MARGINAL_OR_NARROW";
    else
        row.scenarioClassification = "NO_HEADROOM";
    end
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
    localCollectOracleDiagnostics(oracleOutputs,raw,arms, ...
    taskArm,taskScenario,scenarioIds);
writetable(actionDiagnostics,fullfile(R.dir,'oracle_actions.csv'));
writetable(perLinkDiagnostics,fullfile(R.dir,'oracle_per_link.csv'));
writetable(timeDiagnostics,fullfile(R.dir,'oracle_event_time_traces.csv'));

expectedRows = nTasks;
allFinitePass = height(raw)==expectedRows && all(~raw.failed) && ...
    all(isfinite(raw.primaryFormationRMSE_m)) && ...
    all(isfinite(raw.evaluationCost025PerChannel_Hz));
tracePairingPass = localTracePairingPass(raw,scenarioIds,seeds,nArms);
noDivergencePass = ~any(raw.diverged);
oracleContractPass = localOracleContractPass( ...
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

if all(comparison.convincing)
    classification = 'O1_STRONG_HEADROOM';
    recommendation = 'PROCEED_O1_STAGE_B';
elseif any(comparison.convincing | comparison.marginalOrNarrow)
    classification = 'O1_PARTIAL_HEADROOM';
    recommendation = 'RUN_O2_BEFORE_POLICY_DECISION';
else
    classification = 'O1_NO_HEADROOM';
    recommendation = 'RUN_CHEAP_O2_UPPER_BOUND';
end

summary = struct();
summary.schemaVersion = 1;
summary.gate = 'centralized-online-oracle-frontier-stage-a';
summary.label = 'centralized_state_oracle';
summary.frozenPushedHead = frozenPushedHead;
summary.technicalStatus = localPassFail(technicalPass);
summary.classification = classification;
summary.recommendation = recommendation;
summary.runCount = height(raw);
summary.scenarios = scenarioIds;
summary.seeds = seeds;
summary.periodSamples = periodSamples;
summary.lambdaSweep = lambdaSweep;
summary.horizonSamples = horizonSamples;
summary.matchingGridSize = matchingGridSize;
summary.meaningfulRmseFraction = meaningfulRmseFraction;
summary.meaningfulCostFraction = meaningfulCostFraction;
summary.meaningfulRunLength = meaningfulRunLength;
summary.narrowRunLength = narrowRunLength;
summary.allFinitePass = allFinitePass;
summary.tracePairingPass = tracePairingPass;
summary.noDivergencePass = noDivergencePass;
summary.oracleContractPass = oracleContractPass;
summary.periodicIdentityPass = periodicIdentityPass;
summary.frontierPass = frontierPass;
summary.matchingPass = matchingPass;
summary.actionCount = height(actionDiagnostics);
summary.acceptedUsefulDeliveryCount = ...
    nnz(actionDiagnostics.accepted);
summary.failedTransmissionCount = nnz(actionDiagnostics.dropped);
summary.noInformationAttemptCount = ...
    height(actionDiagnostics)-nnz(actionDiagnostics.accepted);
summary.actualSaturatedRunCount = nnz(raw.saturationFraction>0);
summary.oraclePredictedSaturationRunCount = nnz( ...
    raw.oracleEvaluationPredictedSaturationFraction>0 & ...
    raw.methodFamily=="Centralized state oracle");
summary.comparison = comparisonRows;
summary.interpretation = [ ...
    'O1 is a privileged online diagnostic. Classification follows the ' ...
    'committed complete-domain and contiguous-segment rules; it is not a ' ...
    'claim of distributed deployability or general predictive validity.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','O1_stage_a_frontiers','Color','w', ...
    'Position',[100 100 1120 460]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
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
    xlabel('C_{0.25} [Hz/channel]');
    ylabel('primary RMSE [m]');
    grid on;
    legend({'periodic','centralized state oracle'},'Location','best');
end

figure('Name','O1_stage_a_matched_domains','Color','w', ...
    'Position',[100 100 1120 760]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for s = 1:nScenarios
    b = budgetMatchedAll(budgetMatchedAll.scenarioId==scenarioIds(s),:);
    p = performanceMatchedAll( ...
        performanceMatchedAll.scenarioId==scenarioIds(s),:);
    nexttile(s);
    plot(b.communicationBudget,b.errorDifferenceAminusB,'LineWidth',1.2);
    yline(0,'--'); grid on;
    title(scenarioIds(s)+" budget matched");
    xlabel('C_{0.25} [Hz/channel]'); ylabel('\Delta RMSE [m]');
    nexttile(nScenarios+s);
    plot(p.formationErrorTarget,p.costDifferenceAminusB,'LineWidth',1.2);
    yline(0,'--'); grid on;
    title(scenarioIds(s)+" performance matched");
    xlabel('RMSE target [m]'); ylabel('\Delta C_{0.25} [Hz/channel]');
end

figure('Name','O1_stage_a_event_allocation','Color','w', ...
    'Position',[100 100 1120 460]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
for s = 1:nScenarios
    x = raw(raw.scenarioId==scenarioIds(s) & ...
        raw.methodFamily=="Centralized state oracle",:);
    [G,lambda] = findgroups(x.oracleLambda);
    allocation = splitapply(@(z) mean(z,'omitnan'), ...
        x.oracleEventAllocationRatio,G);
    nexttile;
    semilogx(max(lambda,1e-7),allocation,'o-','LineWidth',1.2);
    yline(1,'--'); grid on;
    title(scenarioIds(s)+" event allocation");
    xlabel('\lambda (zero displayed at 10^{-7})'); ylabel('R_{event}');
end
saveAllFigures(R);

fprintf('\nO1 Stage-A technical verdict: %s\n', ...
    localPassFail(technicalPass));
for s = 1:nScenarios
    fprintf(['  %s %-22s budget mean/median %+9.5f/%+9.5f, ' ...
        'favor %5.1f%%, run %d; cost mean/median %+9.4f/%+9.4f, ' ...
        'favor %5.1f%%, run %d => %s\n'], ...
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
fprintf('O1 Stage-A classification: %s\n',classification);
fprintf('Frozen next action: %s\n',recommendation);

save(fullfile(R.dir,'workspace.mat'),'scenarioIds','seeds','arms','raw', ...
    'aggregateAll','frontierAll','budgetMatchedAll', ...
    'performanceMatchedAll','comparison','summary');
finishExperiment(R);

if ~technicalPass
    error('tcns_o1_oracle_frontier_stage_a:TechnicalFailure', ...
        'O1 Stage-A technical validity criteria failed.');
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


function S = localDifferenceStats(difference,reference,meaningfulFraction)

difference = double(difference(:));
reference = double(reference(:));
relativeAdvantage = -difference./reference;
S.meanDifference = mean(difference);
S.medianDifference = median(difference);
S.fractionFavoring = mean(difference<0);
S.maximumAdvantage = max(0,-min(difference));
S.maximumDisadvantage = max(0,max(difference));
nonzeroSign = sign(difference);
nonzeroSign = nonzeroSign(nonzeroSign~=0);
S.crossings = nnz(nonzeroSign(2:end)~=nonzeroSign(1:end-1));
S.longestFavoringRun = localLongestRun(difference<0);
S.longestMeaningfulRun = localLongestRun( ...
    relativeAdvantage>=meaningfulFraction);

end


function pass = localBasicSupport(S)

pass = S.meanDifference<0 && S.medianDifference<0 && ...
    S.fractionFavoring>0.5;

end


function longest = localLongestRun(mask)

mask = logical(mask(:));
if isempty(mask) || ~any(mask)
    longest = 0;
    return;
end
edges = diff([false;mask;false]);
starts = find(edges==1);
stops = find(edges==-1)-1;
longest = max(stops-starts+1);

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


function pass = localOracleContractPass(outputs,arms,taskArm)

pass = true;
for q = 1:numel(outputs)
    if arms(taskArm(q)).kind~="centralized-state-oracle"
        continue;
    end
    out = outputs{q};
    if isempty(out) || ~isfield(out,'centralizedStateOracleActive')
        pass = false;
        continue;
    end
    action = out.oracleActions;
    threshold = arms(taskArm(q)).oracleLambda;
    pass = pass && out.centralizedStateOracleActive && ...
        strcmp(out.centralizedStateOracleLabel,'centralized_state_oracle') && ...
        out.onlineNonanticipative && ~out.usesFutureChannelOutcome && ...
        ~out.usesFutureDisturbance && ~out.usesFutureFormationChange && ...
        ~out.usesFutureTrajectory && out.ackCountLog(end)==0 && ...
        out.txCount==out.oracleSendCount && ...
        height(action)==out.oracleSendCount && ...
        all(action.predictedValue>threshold) && ...
        all(abs(action.predictedValue - ...
        (action.predictedCrossContribution - ...
         action.predictedIsolatedEnergy))<1e-12);
end

end


function [pass,audit] = localPeriodicIdentityAudit(raw,scenarioIds,seeds)

archivePath = fullfile(projectRoot(),'results', ...
    'tcns_gate6_nonstationary_frontiers','2026-09-07_012209','tidy.csv');
archive = readtable(archivePath,'TextType','string');
archive.scenarioId = string(archive.scenarioId);
archive.armId = string(archive.armId);
current = raw(raw.methodFamily=="Periodic" & ...
    ismember(raw.scenarioId,scenarioIds),:);
archive = archive(archive.methodFamily=="Periodic" & ...
    ismember(archive.scenarioId,scenarioIds) & ...
    ismember(archive.seed,seeds),:);
current = sortrows(current,{'scenarioId','armId','seed'});
archive = sortrows(archive,{'scenarioId','armId','seed'});
fields = ["formationRMSE_m","primaryFormationRMSE_m", ...
    "evaluationCost025PerChannel_Hz","txCount","traceHashExact"];
rows = repmat(struct('metric',"",'maxAbsoluteDifference',NaN, ...
    'tolerance',NaN,'pass',false),numel(fields),1);
sameKeys = height(current)==height(archive) && ...
    isequal(current.scenarioId,archive.scenarioId) && ...
    isequal(current.armId,archive.armId) && ...
    isequal(current.seed,archive.seed);
for q = 1:numel(fields)
    rows(q).metric = fields(q);
    if sameKeys
        rows(q).maxAbsoluteDifference = max(abs( ...
            double(current.(fields(q)))-double(archive.(fields(q)))));
    end
    if ismember(fields(q),["txCount","traceHashExact"])
        rows(q).tolerance = 0;
    else
        rows(q).tolerance = 5e-12;
    end
    rows(q).pass = sameKeys && rows(q).maxAbsoluteDifference<=rows(q).tolerance;
end
audit = struct2table(rows);
pass = sameKeys && all(audit.pass);

end


function [actions,links,traces] = localCollectOracleDiagnostics( ...
    outputs,raw,arms,taskArm,taskScenario,scenarioIds)

actionCells = cell(numel(outputs),1);
linkCells = cell(numel(outputs),1);
traceCells = cell(numel(outputs),1);
for q = 1:numel(outputs)
    if arms(taskArm(q)).kind~="centralized-state-oracle"
        continue;
    end
    out = outputs{q};
    sid = scenarioIds(taskScenario(q));
    seed = raw.seed(q);
    lambda = arms(taskArm(q)).oracleLambda;
    [cfgScenario,scenario] = tcnsGate6Scenario(seed,sid);

    a = out.oracleActions;
    n = height(a);
    a = addvars(a,repmat(sid,n,1),repmat(seed,n,1), ...
        repmat(lambda,n,1),'Before',1, ...
        'NewVariableNames',{'scenarioId','seed','lambda'});
    actionCells{q} = a;

    linkRows = repmat(struct('scenarioId',"",'seed',NaN, ...
        'lambda',NaN,'linkClass',"",'receiver',NaN,'sender',NaN, ...
        'scheduledCount',NaN,'evaluationCount',NaN,'eventCount',NaN, ...
        'acceptedCount',NaN,'failedCount',NaN),0,1);
    linkClass = ["ordinary","pinned-leader"];
    for c = 1:numel(linkClass)
        if c==1
            [receiver,sender] = find(cfgScenario.swarm.A>0);
        else
            receiver = find(cfgScenario.swarm.pin>0);
            sender = ones(size(receiver));
        end
        for z = 1:numel(receiver)
            select = a.linkClass==linkClass(c) & ...
                a.receiver==receiver(z) & a.sender==sender(z);
            evalSelect = select & ...
                a.time_s>=scenario.evaluationStart_s & ...
                a.time_s<scenario.horizon_s-1e-12;
            eventSelect = evalSelect & ...
                localWindowMask(a.time_s,scenario.eventWindows_s);
            x = struct('scenarioId',sid,'seed',seed,'lambda',lambda, ...
                'linkClass',linkClass(c),'receiver',receiver(z), ...
                'sender',sender(z),'scheduledCount',nnz(select), ...
                'evaluationCount',nnz(evalSelect), ...
                'eventCount',nnz(eventSelect), ...
                'acceptedCount',nnz(select & a.accepted), ...
                'failedCount',nnz(select & a.dropped));
            linkRows(end+1,1) = x; %#ok<AGROW>
        end
    end
    linkCells{q} = struct2table(linkRows);

    t = out.t;
    event = localWindowMask(t,scenario.eventWindows_s);
    around = localExpandedWindowMask(t,scenario.eventWindows_s,1.0);
    dataEvents = [out.txCountLog(1);diff(out.txCountLog)];
    sendEvents = [out.oracleSendCountLog(1); ...
        diff(out.oracleSendCountLog)];
    traceCells{q} = table(repmat(sid,nnz(around),1), ...
        repmat(seed,nnz(around),1),repmat(lambda,nnz(around),1), ...
        t(around),event(around),dataEvents(around),sendEvents(around), ...
        out.oracleSendCountLog(around), ...
        out.oracleStepMaxValueLog(around), ...
        out.oraclePredictedSaturationFractionLog(around), ...
        'VariableNames',{'scenarioId','seed','lambda','time_s', ...
        'inEventWindow','dataAttempts','scheduledActions', ...
        'cumulativeScheduledActions','stepMaxValue', ...
        'predictedSaturationFraction'});
end
actions = vertcat(actionCells{~cellfun(@isempty,actionCells)});
links = vertcat(linkCells{~cellfun(@isempty,linkCells)});
traces = vertcat(traceCells{~cellfun(@isempty,traceCells)});

end


function mask = localWindowMask(t,windows)

mask = false(size(t));
for q = 1:size(windows,1)
    mask = mask | (t>=windows(q,1)-1e-12 & t<windows(q,2)-1e-12);
end

end


function mask = localExpandedWindowMask(t,windows,padding)

mask = false(size(t));
for q = 1:size(windows,1)
    mask = mask | (t>=windows(q,1)-padding-1e-12 & ...
        t<windows(q,2)+padding-1e-12);
end

end


function value = localPassFail(pass)

if pass, value = 'PASS'; else, value = 'FAIL'; end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
assert(fid>0,'O1: cannot create %s.',path);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleaner;

end
