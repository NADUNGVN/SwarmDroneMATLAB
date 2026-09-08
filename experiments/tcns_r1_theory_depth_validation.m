%% TCNS R1 THEORY DEPTH - regret, multi-action and rank robustness

startup;
close all;
R = startExperiment('tcns_r1_theory_depth_validation', ...
    ['R1 theorem diagnostics only: local minimax regret, sender-wise ' ...
     'multi-action missing dimension, coalition ownership, and 80-digit ' ...
     'rank robustness.']);

seed = 27020001;
[cfg,~] = tcnsGate6Scenario(seed,'S1');
H = 25;
D = 4;
model = tcnsInformationLimitsModel(cfg,H,D,0);

audit = tcnsR1TheoryDepthAudit(model);
ordinaryWitness = tcnsInformationLimitsDynamicWitness( ...
    cfg,H,D,'ordinary',5,1);
pinWitness = tcnsInformationLimitsDynamicWitness( ...
    cfg,H,D,'pinned-leader',4,1);
regretTable = struct2table([ ...
    localRegretRow(ordinaryWitness);localRegretRow(pinWitness)]);

allRankStable = all(audit.rankTable.stableAcrossToleranceGrid);
allVpaPositive = all(audit.rankTable.vpaNormalizedResidual>1e-12);
allAugmentRanksIncrease = all( ...
    audit.rankTable.augmentedRank==audit.rankTable.referenceRank+1);
allCoalitionsExist = all(isfinite(audit.senderTable.minimumCoalitionSize)) ...
    && all(audit.senderTable.allAgentsIdentifyAllValues);
regretPass = all(regretTable.qMinus<0 & regretTable.qPlus>0 & ...
    regretTable.randomizedMinimaxRegret>0 & ...
    regretTable.deterministicMinimaxRegret>0);
if allRankStable && allVpaPositive && allAugmentRanksIncrease && ...
        allCoalitionsExist && regretPass
    classification = "R1_THEORY_DEPTH_PASS";
else
    classification = "R1_THEORY_DEPTH_FAIL";
end

summary.schemaVersion = 1;
summary.seed = seed;
summary.horizonSamples = H;
summary.delaySamples = D;
summary.senderCount = height(audit.senderTable);
summary.actionCount = height(audit.actionCatalog);
summary.allRankConclusionsStable = allRankStable;
summary.allVpaResidualsPositive = allVpaPositive;
summary.allAugmentedRanksIncreaseByOne = allAugmentRanksIncrease;
summary.allMultiActionCoalitionsExist = allCoalitionsExist;
summary.bothWitnessRegretsPositive = regretPass;
summary.classification = char(classification);
summary.noSchedulerImplemented = true;
summary.noPerformanceExperiment = true;
summary.noHeldOutSeedsUsed = true;

writetable(audit.actionCatalog,fullfile(R.dir,'action_catalog.csv'));
writetable(audit.senderActionTable, ...
    fullfile(R.dir,'sender_action_missing_norms.csv'));
writetable(audit.senderTable,fullfile(R.dir,'sender_multi_action.csv'));
writetable(audit.rankTable,fullfile(R.dir,'rank_robustness.csv'));
writetable(audit.toleranceTable,fullfile(R.dir,'rank_tolerance_sweep.csv'));
writetable(audit.spectrumTable,fullfile(R.dir,'singular_spectra.csv'));
writetable(regretTable,fullfile(R.dir,'witness_regret.csv'));
fid = fopen(fullfile(R.dir,'summary.json'),'w');
assert(fid>0,'R1TheoryDepth: cannot create summary.json.');
fprintf(fid,'%s\n',jsonencode(summary,'PrettyPrint',true));
fclose(fid);
save(fullfile(R.dir,'workspace.mat'),'cfg','model','audit', ...
    'ordinaryWitness','pinWitness','regretTable','summary');

figure('Color','w','Position',[100 100 1000 430]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;
bar(categorical("UAV "+string(audit.senderTable.sender)), ...
    [audit.senderTable.actionCount audit.senderTable.missingRank]);
ylabel('dimension'); legend('candidate actions p_j','missing rank r_j^*', ...
    'Location','best'); grid on;
title('Sender-wise missing-information compression');
nexttile;
bar(categorical(regretTable.payload), ...
    [regretTable.randomizedMinimaxRegret ...
     regretTable.deterministicMinimaxRegret]);
ylabel('unavoidable local regret');
legend('randomized','deterministic','Location','best'); grid on;
title('Reachable information-state decision regret');
saveAllFigures(R);

fprintf('R1 multi-action sender count       : %d\n',height(audit.senderTable));
for k = 1:height(audit.senderTable)
    fprintf('  sender %d: p=%d, r*=%.0f, coalition=%g\n', ...
        audit.senderTable.sender(k),audit.senderTable.actionCount(k), ...
        audit.senderTable.missingRank(k), ...
        audit.senderTable.minimumCoalitionSize(k));
end
fprintf('rank conclusions stable           : %d / %d\n', ...
    nnz(audit.rankTable.stableAcrossToleranceGrid),height(audit.rankTable));
fprintf('ordinary randomized/deterministic : %.6e / %.6e\n', ...
    regretTable.randomizedMinimaxRegret(1), ...
    regretTable.deterministicMinimaxRegret(1));
fprintf('pin randomized/deterministic      : %.6e / %.6e\n', ...
    regretTable.randomizedMinimaxRegret(2), ...
    regretTable.deterministicMinimaxRegret(2));
fprintf('classification                    : %s\n',classification);
finishExperiment(R);


function row = localRegretRow(W)
qMinus = W.minus.expectedValue;
qPlus = W.plus.expectedValue;
a = -qMinus;
denominator = qPlus+a;
probability = qPlus/denominator;
row.payload = sprintf('%s:%d->%d',W.linkClass,W.sender,W.receiver);
row.qMinus = qMinus;
row.qPlus = qPlus;
row.valueMidpoint = (qPlus+qMinus)/2;
row.valueInformationRadius = (qPlus-qMinus)/2;
row.optimalTransmitProbability = probability;
row.randomizedMinimaxRegret = qPlus*a/denominator;
row.deterministicMinimaxRegret = min(qPlus,a);
end

