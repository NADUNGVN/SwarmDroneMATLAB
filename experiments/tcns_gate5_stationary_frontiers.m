%% TCNS GATE 5 - Complete stationary development frontiers
%
% The exact grids, matching convention and pass/fail criteria are frozen in
% paper/tcns/GATE5_FRONTIER_PROTOCOL.md. This experiment does not select an
% operating point and does not use held-out seeds.

startup;
close all;

R = startExperiment('tcns_gate5_stationary_frontiers', ...
    ['Five paired development seeds; full periodic/control-aware stationary ' ...
     'sweeps; automatic frontier and bidirectional matching.']);

sc = exp10Scenarios();
points = exp10Points();
pt = points(strcmp({points.id},'NOMINAL'));
scenarioIndex = sc.STRESSED;
seeds = (27020001:27020005)';
evaluationStart_s = 8;
periodSamples = [1 2 3 4 5 8 10 15 20 25 40];
epsilonSweep_m = [0.05 0.075 0.10 0.15 0.20 0.30 0.40 0.60 0.80 1.20 1.60];
retryInterval_s = 0.10;
matchingGridSize = 101;

cfg0 = applyExp10Point(pt,scenarioIndex,seeds(1));
cfg0.sixdof.enable = false;
cfg0.swarm.T = 30;
h = cfg0.swarm.dt;

arms = localArms(periodSamples,epsilonSweep_m,h,retryInterval_s);
nArms = numel(arms);
nSeeds = numel(seeds);
nTasks = nArms*nSeeds;
taskArm = repelem((1:nArms)',nSeeds);
taskSeed = repmat(seeds,nArms,1);
rawRows = repmat(localEmptyRow(),nTasks,1);

fprintf('Running %d arms x %d paired seeds = %d DI simulations.\n', ...
    nArms,nSeeds,nTasks);

parfor task = 1:nTasks
    arm = arms(taskArm(task));
    cfg = applyExp10Point(pt,scenarioIndex,taskSeed(task));
    cfg.sixdof.enable = false;
    cfg.swarm.T = 30;
    rawRows(task) = localRun(cfg,arm,evaluationStart_s,sc.names{scenarioIndex});
end

raw = struct2table(rawRows);
writetable(raw,fullfile(R.dir,'tidy.csv'));

aggregate = localAggregate(raw,arms,nSeeds);
aggregate.isPareto = false(height(aggregate),1);

periodicMask = aggregate.methodFamily=="Periodic" & ...
    aggregate.failedRuns==0;
controlMask = aggregate.methodFamily=="Control-aware" & ...
    aggregate.failedRuns==0;

[frontierPeriodic,maskPeriodic] = tcnsParetoFrontier( ...
    aggregate(periodicMask,:),'meanCost025PerChannel_Hz','meanFormationRMSE_m');
[frontierControl,maskControl] = tcnsParetoFrontier( ...
    aggregate(controlMask,:),'meanCost025PerChannel_Hz','meanFormationRMSE_m');

periodicIndices = find(periodicMask);
controlIndices = find(controlMask);
aggregate.isPareto(periodicIndices(maskPeriodic)) = true;
aggregate.isPareto(controlIndices(maskControl)) = true;

matched = tcnsMatchFrontiers(frontierControl,frontierPeriodic, ...
    'meanCost025PerChannel_Hz','meanFormationRMSE_m',matchingGridSize);

writetable(aggregate,fullfile(R.dir,'aggregate.csv'));
writetable(frontierPeriodic,fullfile(R.dir,'frontier_periodic.csv'));
writetable(frontierControl,fullfile(R.dir,'frontier_control_aware.csv'));
writetable(matched.budgetMatched,fullfile(R.dir,'budget_matched.csv'));
writetable(matched.performanceMatched, ...
    fullfile(R.dir,'performance_matched.csv'));

allFinitePass = all(raw.failed==0) && ...
    all(isfinite(raw.formationRMSE_m)) && ...
    all(isfinite(raw.cost025PerChannel_Hz));
causalPass = all(raw.invariantViolations( ...
    raw.methodFamily=="Control-aware")==0);
frontierSizePass = height(frontierPeriodic)>=3 && ...
    height(frontierControl)>=3;
matchingPass = height(matched.budgetMatched)==matchingGridSize && ...
    height(matched.performanceMatched)==matchingGridSize && ...
    all(isfinite(matched.budgetMatched{:,:}),'all') && ...
    all(isfinite(matched.performanceMatched{:,:}),'all');
tracePairingPass = localTracePairingPass(raw,seeds,nArms);
gatePass = allFinitePass && causalPass && frontierSizePass && ...
    matchingPass && tracePairingPass;

summary = struct();
summary.schemaVersion = 1;
summary.gate = 5;
summary.status = localPassFail(gatePass);
summary.classification = 'development-only stationary frontiers';
summary.scenario = sc.names{scenarioIndex};
summary.seeds = seeds;
summary.periodSamples = periodSamples;
summary.periodSeconds = periodSamples*h;
summary.epsilonSweep_m = epsilonSweep_m;
summary.retryInterval_s = retryInterval_s;
summary.matchingGridSize = matchingGridSize;
summary.allFinitePass = allFinitePass;
summary.causalPass = causalPass;
summary.frontierSizePass = frontierSizePass;
summary.matchingPass = matchingPass;
summary.tracePairingPass = tracePairingPass;
summary.periodicFrontierPoints = height(frontierPeriodic);
summary.controlAwareFrontierPoints = height(frontierControl);
summary.budgetOverlap_HzPerChannel = matched.budgetOverlap;
summary.performanceOverlap_m = matched.performanceOverlap;
summary.meanBudgetMatchedErrorDifferenceControlMinusPeriodic_m = ...
    matched.meanBudgetMatchedErrorDifference;
summary.meanPerformanceMatchedCostDifferenceControlMinusPeriodic_Hz = ...
    matched.meanPerformanceMatchedCostDifference;
summary.fractionBudgetGridFavoringControl = ...
    matched.fractionBudgetGridFavoringA;
summary.fractionPerformanceGridFavoringControl = ...
    matched.fractionPerformanceGridFavoringA;
summary.saturatedRunCount = nnz(raw.saturationFraction>0);
summary.divergedRunCount = nnz(raw.diverged);
summary.interpretation = [ ...
    'Differences cover the entire shared observed frontier domain and use ' ...
    'control-aware minus periodic. Negative favors control-aware. This ' ...
    'stationary development result does not select epsilon or period.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);
localWriteJson(fullfile(R.dir,'configuration.json'),struct( ...
    'baseConfiguration',cfg0,'scenario',sc.names{scenarioIndex}, ...
    'seeds',seeds,'evaluationStart_s',evaluationStart_s, ...
    'periodSamples',periodSamples,'epsilonSweep_m',epsilonSweep_m, ...
    'retryInterval_s',retryInterval_s, ...
    'cost','DATA + 0.25 ACK per configured channel per second', ...
    'matching','101-point linear interpolation on shared domains only'));

figure('Name','Gate5_stationary_frontiers','Color','w', ...
    'Position',[80 80 1180 820]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile([1 2]);
plot(frontierPeriodic.meanCost025PerChannel_Hz, ...
    frontierPeriodic.meanFormationRMSE_m,'o-', ...
    'Color',[0.25 0.25 0.25],'LineWidth',1.25, ...
    'MarkerFaceColor',[0.25 0.25 0.25]); hold on;
plot(frontierControl.meanCost025PerChannel_Hz, ...
    frontierControl.meanFormationRMSE_m,'o-', ...
    'Color',[0.10 0.38 0.70],'LineWidth',1.25, ...
    'MarkerFaceColor',[0.10 0.38 0.70]);
legacy = aggregate(aggregate.methodFamily=="Historical reference",:);
scatter(legacy.meanCost025PerChannel_Hz,legacy.meanFormationRMSE_m,70, ...
    [0.80 0.25 0.12],'filled');
xlabel('mean DATA + 0.25 ACK [Hz/channel]');
ylabel('mean formation RMSE [m]');
legend({'periodic Pareto frontier','control-aware Pareto frontier', ...
    'frozen Causal-v3'},'Location','best');
title('Stationary Stressed, five paired development seeds');
grid on;

nexttile;
plot(matched.budgetMatched.communicationBudget, ...
    matched.budgetMatched.errorDifferenceAminusB,'LineWidth',1.25, ...
    'Color',[0.10 0.38 0.70]); hold on;
yline(0,'--','equal performance');
xlabel('matched communication budget [Hz/channel]');
ylabel('RMSE control-aware - periodic [m]');
grid on;
title('Budget-matched over full overlap');

nexttile;
plot(matched.performanceMatched.formationErrorTarget, ...
    matched.performanceMatched.costDifferenceAminusB,'LineWidth',1.25, ...
    'Color',[0.10 0.38 0.70]); hold on;
yline(0,'--','equal cost');
xlabel('matched formation RMSE target [m]');
ylabel('cost control-aware - periodic [Hz/channel]');
grid on;
title('Performance-matched over full overlap');

saveAllFigures(R);

fprintf('\nGate 5 stationary frontier verdict: %s\n',summary.status);
fprintf('  periodic / control frontier points : %d / %d\n', ...
    height(frontierPeriodic),height(frontierControl));
fprintf('  budget overlap [Hz/channel]        : %.3f -- %.3f\n', ...
    matched.budgetOverlap);
fprintf('  performance overlap [m]            : %.4f -- %.4f\n', ...
    matched.performanceOverlap);
fprintf('  mean matched RMSE difference [m]   : %+.5f\n', ...
    matched.meanBudgetMatchedErrorDifference);
fprintf('  mean matched cost difference [Hz]  : %+.3f\n', ...
    matched.meanPerformanceMatchedCostDifference);
fprintf('  overlap fraction favoring control  : %.1f%% / %.1f%%\n', ...
    100*matched.fractionBudgetGridFavoringA, ...
    100*matched.fractionPerformanceGridFavoringA);

save(fullfile(R.dir,'workspace.mat'),'cfg0','arms','raw','aggregate', ...
    'frontierPeriodic','frontierControl','matched','summary');
finishExperiment(R);

if ~gatePass
    error('tcns_gate5_stationary_frontiers:GateFailed', ...
        'Gate-5 infrastructure criteria failed.');
end


function arms = localArms(periodSamples,epsilonSweep,h,retryInterval)

nP = numel(periodSamples);
nC = numel(epsilonSweep);
arms = repmat(struct('id',"",'family',"",'label',"",'kind',"", ...
    'parameterName',"",'parameterValue',NaN,'period_s',NaN, ...
    'epsilon_m',NaN,'retry_s',NaN),nP+nC+1,1);
for q = 1:nP
    arms(q).id = "P"+string(periodSamples(q));
    arms(q).family = "Periodic";
    arms(q).label = "Periodic-"+string(periodSamples(q))+"step";
    arms(q).kind = "periodic";
    arms(q).parameterName = "periodSamples";
    arms(q).parameterValue = periodSamples(q);
    arms(q).period_s = periodSamples(q)*h;
end
for q = 1:nC
    k = nP+q;
    arms(k).id = "CA"+string(q);
    arms(k).family = "Control-aware";
    arms(k).label = "Control-aware";
    arms(k).kind = "control-aware";
    arms(k).parameterName = "epsilonPosition_m";
    arms(k).parameterValue = epsilonSweep(q);
    arms(k).epsilon_m = epsilonSweep(q);
    arms(k).retry_s = retryInterval;
end
k = nP+nC+1;
arms(k).id = "CAUSALV3";
arms(k).family = "Historical reference";
arms(k).label = "Causal-v3 frozen";
arms(k).kind = "legacy";
arms(k).parameterName = "frozen";

end


function row = localRun(cfg,arm,evaluationStart,scenarioName)

row = localEmptyRow();
row.armId = arm.id;
row.methodFamily = arm.family;
row.method = arm.label;
row.parameterName = arm.parameterName;
row.parameterValue = arm.parameterValue;
row.period_s = arm.period_s;
row.epsilonPosition_m = arm.epsilon_m;
row.retryInterval_s = arm.retry_s;
row.seed = cfg.net.seed;
row.scenario = string(scenarioName);
t0 = tic;

try
    switch arm.kind
        case "periodic"
            cfg.net.commPeriod = arm.period_s;
            out = simSwarmNetworkQueued(cfg);
        case "control-aware"
            cfg.causal.policyMode = 'control-aware';
            cfg.controlAware.epsilonPosition = arm.epsilon_m;
            cfg.controlAware.retryInterval = arm.retry_s;
            out = simSwarmAoICausal(cfg);
        case "legacy"
            cfg.causal.policyMode = 'legacy-v3';
            out = simSwarmAoICausal(cfg);
        otherwise
            error('Gate5:UnknownArm','Unknown arm kind %s.',arm.kind);
    end

    metrics = computeSwarmMetrics(out,cfg);
    missionTime = out.t(end)-out.t(1);
    nChannels = nnz(cfg.swarm.A)+nnz(cfg.swarm.pin);
    ackCount = 0;
    if isfield(out,'ackTxCount'), ackCount = out.ackTxCount; end
    dataRate = out.txCount/max(missionTime,eps);
    ackRate = ackCount/max(missionTime,eps);
    idx = out.t>=evaluationStart;
    acceleration = vecnorm(reshape(out.A(idx,2:end,:),[],3),2,2);

    row.formationRMSE_m = metrics.formationRMSE;
    row.maxFormationError_m = metrics.maxFormationError;
    row.txCount = out.txCount;
    row.ackCount = ackCount;
    row.dataRatePerChannel_Hz = dataRate/nChannels;
    row.cost025PerChannel_Hz = (dataRate+0.25*ackRate)/nChannels;
    row.broadcastRate_Hz = out.broadcastCount/max(missionTime,eps);
    row.maxEvaluationAcceleration_mps2 = max(acceleration);
    row.saturationFraction = mean( ...
        acceleration>=cfg.swarm.maxAccel-1e-10);
    row.diverged = any(~isfinite(out.P),'all') || ...
        max(abs(out.P),[],'all')>100;
    row.traceHashExact = out.traceHashExact;
    if isfield(out,'invariantViolations')
        row.invariantViolations = out.invariantViolations;
    else
        row.invariantViolations = 0;
    end
    if isfield(out,'controlAwareViolationRatio') && ...
            out.controlAwareActive
        row.controlViolationRatio = out.controlAwareViolationRatio;
        row.controlMaxNormalizedRisk = out.controlAwareMaxNormalizedRisk;
    end
catch err
    row.failed = true;
    row.errorIdentifier = string(err.identifier);
    row.errorMessage = string(err.message);
end

row.runtime_s = toc(t0);

end


function aggregate = localAggregate(raw,arms,nSeeds)

out = repmat(localEmptyAggregate(),numel(arms),1);
for q = 1:numel(arms)
    r = raw(raw.armId==arms(q).id,:);
    good = ~r.failed;
    out(q).armId = arms(q).id;
    out(q).methodFamily = arms(q).family;
    out(q).method = arms(q).label;
    out(q).parameterName = arms(q).parameterName;
    out(q).parameterValue = arms(q).parameterValue;
    out(q).period_s = arms(q).period_s;
    out(q).epsilonPosition_m = arms(q).epsilon_m;
    out(q).seedCount = height(r);
    out(q).failedRuns = nnz(~good);
    out(q).divergedRuns = nnz(r.diverged);
    if nnz(good)==nSeeds
        out(q).meanFormationRMSE_m = mean(r.formationRMSE_m(good));
        out(q).stdFormationRMSE_m = std(r.formationRMSE_m(good));
        out(q).meanCost025PerChannel_Hz = ...
            mean(r.cost025PerChannel_Hz(good));
        out(q).stdCost025PerChannel_Hz = ...
            std(r.cost025PerChannel_Hz(good));
        out(q).meanDataRatePerChannel_Hz = ...
            mean(r.dataRatePerChannel_Hz(good));
        out(q).meanBroadcastRate_Hz = mean(r.broadcastRate_Hz(good));
        out(q).meanControlViolationRatio = ...
            mean(r.controlViolationRatio(good),'omitnan');
        out(q).saturatedRuns = nnz(r.saturationFraction(good)>0);
    end
end
aggregate = struct2table(out);

end


function pass = localTracePairingPass(raw,seeds,nArms)

pass = true;
for q = 1:numel(seeds)
    r = raw(raw.seed==seeds(q),:);
    pass = pass && height(r)==nArms && ...
        all(r.traceHashExact==r.traceHashExact(1));
end

end


function row = localEmptyRow()

row = struct('armId',"",'methodFamily',"",'method',"", ...
    'parameterName',"",'parameterValue',NaN,'period_s',NaN, ...
    'epsilonPosition_m',NaN,'retryInterval_s',NaN,'seed',NaN, ...
    'scenario',"",'formationRMSE_m',NaN,'maxFormationError_m',NaN, ...
    'txCount',NaN,'ackCount',NaN,'dataRatePerChannel_Hz',NaN, ...
    'cost025PerChannel_Hz',NaN,'broadcastRate_Hz',NaN, ...
    'maxEvaluationAcceleration_mps2',NaN,'saturationFraction',NaN, ...
    'diverged',false,'invariantViolations',NaN,'traceHashExact',NaN, ...
    'controlViolationRatio',NaN,'controlMaxNormalizedRisk',NaN, ...
    'runtime_s',NaN,'failed',false,'errorIdentifier',"",'errorMessage',"");

end


function row = localEmptyAggregate()

row = struct('armId',"",'methodFamily',"",'method',"", ...
    'parameterName',"",'parameterValue',NaN,'period_s',NaN, ...
    'epsilonPosition_m',NaN,'seedCount',NaN,'failedRuns',NaN, ...
    'divergedRuns',NaN,'saturatedRuns',NaN, ...
    'meanFormationRMSE_m',NaN,'stdFormationRMSE_m',NaN, ...
    'meanCost025PerChannel_Hz',NaN,'stdCost025PerChannel_Hz',NaN, ...
    'meanDataRatePerChannel_Hz',NaN,'meanBroadcastRate_Hz',NaN, ...
    'meanControlViolationRatio',NaN);

end


function value = localPassFail(pass)

if pass, value = 'PASS'; else, value = 'FAIL'; end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
assert(fid>0,'Gate5: cannot create %s.',path);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleaner;

end
