%% TCNS FB0 - feedback economics on the frozen O1 archive
%
% Preregistered in paper/tcns/FB0_FEEDBACK_ECONOMICS_PROTOCOL.md.
% This script performs no trajectory simulation.

startup;

R = startExperiment('tcns_fb0_feedback_economics', ...
    ['Offline feedback-price break-even analysis on immutable O1 and ' ...
     'periodic development runs; no trajectory is rerun.']);

sourceRun = fullfile(projectRoot(),'results', ...
    'tcns_ab0_ack_cost_adjusted_o1','2026-09-07_170715');
raw = readtable(fullfile(sourceRun,'adjusted_runs.csv'),'TextType','string');
raw.scenarioId = string(raw.scenarioId);
raw.armId = string(raw.armId);
raw.methodFamily = string(raw.methodFamily);

scenarioIds = ["S2","S3","S4","S5","S6"];
eta0 = 0.25;
expectedSeeds = 5;
expectedRows = 625;
expectedO1Rows = 350;

rows = table();
frontiers = table();
sourceChecks = struct();
sourceChecks.rowCount = height(raw)==expectedRows;
sourceChecks.o1RowCount = ...
    nnz(raw.methodFamily=="Centralized state oracle")==expectedO1Rows;
sourceChecks.c1EqualsC2 = ...
    all(raw.adjustedAckC1Count==raw.adjustedAckC2Count);
sourceChecks.nonnegativeAck = all(raw.adjustedAckC2Count>=0);

for s = 1:numel(scenarioIds)
    sid = scenarioIds(s);
    x = raw(raw.scenarioId==sid,:);
    [G,armId] = findgroups(x.armId);
    family = splitapply(@(z) z(1),x.methodFamily,G);
    method = splitapply(@(z) z(1),x.method,G);
    parameterName = splitapply(@(z) z(1),x.parameterName,G);
    parameterValue = splitapply(@(z) z(1),x.parameterValue,G);
    seedCount = splitapply(@numel,x.seed,G);
    failedRuns = splitapply(@sum,x.failed,G);
    meanError = splitapply(@mean,x.primaryFormationRMSE_m,G);
    meanDataCost = splitapply(@mean,x.evaluationCostC0_HzPerChannel,G);
    meanC2Cost = splitapply(@mean,x.evaluationCostC2_HzPerChannel,G);
    meanAckCount = splitapply(@mean,x.adjustedAckC2Count,G);

    % All Gate-6 scenarios use the same frozen horizon/topology dimensions,
    % but reconstruct these quantities per scenario rather than hard-code them.
    [cfg,scenario] = tcnsGate6Scenario(x.seed(1),sid);
    duration_s = scenario.horizon_s-scenario.evaluationStart_s;
    nChannels = nnz(cfg.swarm.A)+nnz(cfg.swarm.pin);
    meanAckRate = meanAckCount/(duration_s*nChannels);

    O = table(armId,family,method,parameterName,parameterValue,seedCount, ...
        failedRuns,meanError,meanDataCost,meanC2Cost,meanAckCount,meanAckRate, ...
        'VariableNames',{'armId','methodFamily','method','parameterName', ...
        'parameterValue','seedCount','failedRuns','formationRMSE_m', ...
        'dataCost_HzPerChannel','costC2_HzPerChannel', ...
        'feedbackEligibleCount','feedbackEligibleRate_HzPerChannel'});
    P = O(O.methodFamily=="Periodic",:);
    P = tcnsParetoFrontier(P,'dataCost_HzPerChannel','formationRMSE_m');
    if height(P)>1 && (any(diff(P.dataCost_HzPerChannel)<=0) || ...
            any(diff(P.formationRMSE_m)>=0))
        error('tcns_fb0_feedback_economics:PeriodicOrdering', ...
            'Periodic frontier is not strictly lower-left ordered.');
    end
    P.scenarioId = repmat(sid,height(P),1);
    frontiers = [frontiers;P]; %#ok<AGROW>

    Q = O(O.methodFamily=="Centralized state oracle",:);
    Q = sortrows(Q,'parameterValue','ascend');
    Q.scenarioId = repmat(sid,height(Q),1);
    Q.periodicMatchedCost_HzPerChannel = nan(height(Q),1);
    Q.etaCritical = nan(height(Q),1);
    Q.allowableFeedbackFractionRawAt025 = nan(height(Q),1);
    Q.allowableFeedbackFractionClippedAt025 = nan(height(Q),1);
    Q.eligibility = repmat("",height(Q),1);
    Q.economicClass = repmat("",height(Q),1);

    eMin = min(P.formationRMSE_m);
    eMax = max(P.formationRMSE_m);
    for q = 1:height(Q)
        if Q.formationRMSE_m(q)<eMin || Q.formationRMSE_m(q)>eMax
            Q.eligibility(q) = "OUTSIDE_PERIODIC_PERFORMANCE_DOMAIN";
            Q.economicClass(q) = "EXCLUDED_NO_EXTRAPOLATION";
            continue;
        end
        if Q.feedbackEligibleRate_HzPerChannel(q)<=0
            Q.eligibility(q) = "ZERO_FEEDBACK_RATE";
            Q.economicClass(q) = "EXCLUDED_ZERO_DENOMINATOR";
            continue;
        end
        cp = interp1(flip(P.formationRMSE_m), ...
            flip(P.dataCost_HzPerChannel),Q.formationRMSE_m(q),'linear');
        etaStar = (cp-Q.dataCost_HzPerChannel(q))/ ...
            Q.feedbackEligibleRate_HzPerChannel(q);
        fStar = etaStar/eta0;
        Q.periodicMatchedCost_HzPerChannel(q) = cp;
        Q.etaCritical(q) = etaStar;
        Q.allowableFeedbackFractionRawAt025(q) = fStar;
        Q.allowableFeedbackFractionClippedAt025(q) = min(1,max(0,fStar));
        Q.eligibility(q) = "ELIGIBLE";
        if etaStar<0
            Q.economicClass(q) = "DATA_ALREADY_UNECONOMIC";
        elseif etaStar<eta0
            Q.economicClass(q) = "PRICE_025_UNAFFORDABLE";
        else
            Q.economicClass(q) = "FULL_FEEDBACK_AFFORDABLE";
        end
    end
    rows = [rows;Q]; %#ok<AGROW>
end

writetable(rows,fullfile(R.dir,'feedback_economics_points.csv'));
writetable(frontiers,fullfile(R.dir,'periodic_frontiers.csv'));

summaryRows = repmat(localSummaryRow(),numel(scenarioIds),1);
for s = 1:numel(scenarioIds)
    sid = scenarioIds(s);
    x = rows(rows.scenarioId==sid,:);
    y = x(x.eligibility=="ELIGIBLE",:);
    summaryRows(s) = localSummaryRow(sid,x,y,eta0);
end
scenarioSummary = struct2table(summaryRows);
writetable(scenarioSummary,fullfile(R.dir,'scenario_summary.csv'));

eligible = rows.eligibility=="ELIGIBLE";
armSeedPass = all(rows.seedCount==expectedSeeds);
noFailuresPass = all(rows.failedRuns==0);
ratePass = all(rows.feedbackEligibleRate_HzPerChannel>=0);
costReconstructionPass = all(abs(rows.costC2_HzPerChannel - ...
    (rows.dataCost_HzPerChannel+eta0*rows.feedbackEligibleRate_HzPerChannel)) ...
    < 2e-12);
finiteEligiblePass = all(isfinite(rows.etaCritical(eligible))) && ...
    all(isfinite(rows.allowableFeedbackFractionRawAt025(eligible)));
algebraPass = all(abs(rows.allowableFeedbackFractionRawAt025(eligible)- ...
    rows.etaCritical(eligible)/eta0)<1e-12);
technicalPass = sourceChecks.rowCount && sourceChecks.o1RowCount && ...
    sourceChecks.c1EqualsC2 && sourceChecks.nonnegativeAck && armSeedPass && ...
    noFailuresPass && ratePass && costReconstructionPass && ...
    finiteEligiblePass && algebraPass;

summary = struct('schemaVersion',1,'phase','FB0', ...
    'technicalStatus',localPassFail(technicalPass), ...
    'sourceCommit','44d354fcba8f70576eb9c0e28206a23fae717aa8', ...
    'frozenO1Commit','ce835c9c3195db86e610c24f4a6db21d42211559', ...
    'sourceRun',strrep(sourceRun,'\','/'),'trajectoryRerunCount',0, ...
    'etaFrozen',eta0,'pointCount',height(rows), ...
    'eligiblePointCount',nnz(eligible),'sourceChecks',sourceChecks, ...
    'armSeedPass',armSeedPass,'noFailuresPass',noFailuresPass, ...
    'ratePass',ratePass,'costReconstructionPass',costReconstructionPass, ...
    'finiteEligiblePass',finiteEligiblePass,'algebraPass',algebraPass, ...
    'scenarioSummary',table2struct(scenarioSummary));
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','FB0_feedback_economics','Color','w', ...
    'Position',[100 100 1080 480]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile; hold on;
for s = 1:numel(scenarioIds)
    x = rows(rows.scenarioId==scenarioIds(s) & eligible,:);
    plot(x.dataCost_HzPerChannel,x.etaCritical,'o-', ...
        'DisplayName',scenarioIds(s),'LineWidth',1.1);
end
yline(eta0,'k--','price 0.25'); yline(0,'k:'); grid on;
xlabel('O1 DATA cost [Hz/channel]'); ylabel('\eta^*');
title('Critical feedback price'); legend('Location','best');
nexttile; hold on;
for s = 1:numel(scenarioIds)
    x = rows(rows.scenarioId==scenarioIds(s) & eligible,:);
    plot(x.dataCost_HzPerChannel, ...
        x.allowableFeedbackFractionRawAt025,'o-', ...
        'DisplayName',scenarioIds(s),'LineWidth',1.1);
end
yline(1,'k--','full feedback'); yline(0,'k:'); grid on;
xlabel('O1 DATA cost [Hz/channel]'); ylabel('raw f^* at \eta=0.25');
title('Affordable feedback fraction'); legend('Location','best');
saveAllFigures(R);

fprintf('\nFB0 technical verdict: %s\n',localPassFail(technicalPass));
disp(scenarioSummary);
save(fullfile(R.dir,'workspace.mat'),'raw','rows','frontiers', ...
    'scenarioSummary','summary');
finishExperiment(R);
if ~technicalPass
    error('tcns_fb0_feedback_economics:TechnicalFailure', ...
        'FB0 technical validity failed.');
end


function row = localSummaryRow(sid,allRows,eligibleRows,eta0)

row = struct('scenarioId',"",'pointCount',NaN,'eligiblePointCount',NaN, ...
    'outsideDomainCount',NaN,'etaMedian',NaN,'etaQ25',NaN,'etaQ75',NaN, ...
    'etaMinimum',NaN,'etaMaximum',NaN,'rawFractionMedianAt025',NaN, ...
    'rawFractionQ25At025',NaN,'rawFractionQ75At025',NaN, ...
    'fractionPositiveHeadroom',NaN,'fractionFullFeedbackAffordable',NaN, ...
    'etaFrozen',NaN);
if nargin==0
    return;
end
row.scenarioId = sid;
row.pointCount = height(allRows);
row.eligiblePointCount = height(eligibleRows);
row.outsideDomainCount = height(allRows)-height(eligibleRows);
row.etaFrozen = eta0;
if isempty(eligibleRows)
    return;
end
eta = eligibleRows.etaCritical;
f = eligibleRows.allowableFeedbackFractionRawAt025;
row.etaMedian = median(eta);
row.etaQ25 = prctile(eta,25);
row.etaQ75 = prctile(eta,75);
row.etaMinimum = min(eta);
row.etaMaximum = max(eta);
row.rawFractionMedianAt025 = median(f);
row.rawFractionQ25At025 = prctile(f,25);
row.rawFractionQ75At025 = prctile(f,75);
row.fractionPositiveHeadroom = mean(eta>0);
row.fractionFullFeedbackAffordable = mean(eta>=eta0);

end


function value = localPassFail(tf)
if tf
    value = 'PASS';
else
    value = 'FAIL';
end
end


function localWriteJson(path,value)
fid = fopen(path,'w');
if fid<0
    error('tcns_fb0_feedback_economics:JsonOpen', ...
        'Could not open %s for writing.',path);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
