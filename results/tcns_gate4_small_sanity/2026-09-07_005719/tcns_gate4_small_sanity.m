%% TCNS GATE 4 - Small control-aware freshness falsification
%
% PREREGISTERED MECHANICS CHECK (development only)
%   seed:       27020001
%   scenario:   frozen EXP10 Stressed, exact DI plant
%   horizon:    12 s; metrics/saturation after 8 s
%   epsilon_d:  [0.10 0.20 0.40 0.80] m, fixed log2 spacing
%   references: P10 and frozen Causal-v3
%   retry:      0.10 s, inherited from the frozen refresh interval
%
% No value will be selected as a winning operating point. Gate 4 proceeds
% only if the causal contracts hold, the sweep produces at least two traffic
% levels, communication is weakly nonincreasing as epsilon is relaxed, the
% new-information and in-flight-suppression branches are exercised, and the
% evaluation interval remains unsaturated. This is not a superiority test.

startup;
close all;

R = startExperiment('tcns_gate4_small_sanity', ...
    ['Development-only falsification of the first theorem-derived ' ...
     'control-aware trigger. Fixed sweep declared in source before run.']);

sc = exp10Scenarios();
points = exp10Points();
pt = points(strcmp({points.id},'NOMINAL'));
seed = 27020001;
scenarioIndex = sc.STRESSED;
evaluationStart_s = 8;
epsilonSweep_m = [0.10 0.20 0.40 0.80];
retryInterval_s = 0.10;

cfgBase = applyExp10Point(pt,scenarioIndex,seed);
cfgBase.sixdof.enable = false;
cfgBase.swarm.T = 12;

nRows = 2+numel(epsilonSweep_m);
rows = repmat(localEmptyRow(),nRows,1);
outputs = cell(nRows,1);

% Reference 1: P10. It has no reverse ACK channel by construction.
out = simSwarm6DOF(cfgBase,'P10');
rows(1) = localRow(out,cfgBase,"P10",NaN,evaluationStart_s);
outputs{1} = out;

% Reference 2: exact frozen Causal-v3.
cfgLegacy = cfgBase;
cfgLegacy.causal.policyMode = 'legacy-v3';
out = simSwarmAoICausal(cfgLegacy);
rows(2) = localRow(out,cfgLegacy,"Causal-v3 frozen",NaN,evaluationStart_s);
outputs{2} = out;

coveragePass = true;
budgetAlgebraPass = true;
causalInvariantPass = true;
unsaturatedPass = true;

for e = 1:numel(epsilonSweep_m)
    cfg = cfgBase;
    cfg.causal.policyMode = 'control-aware';
    cfg.controlAware.epsilonPosition = epsilonSweep_m(e);
    cfg.controlAware.retryInterval = retryInterval_s;
    cfg.tcns.logReceiverState = true;
    cfg.tcns.logCausalSetBound = true;

    out = simSwarmAoICausal(cfg);
    rowIndex = 2+e;
    rows(rowIndex) = localRow(out,cfg,"Control-aware", ...
        epsilonSweep_m(e),evaluationStart_s);
    outputs{rowIndex} = out;

    D = tcnsCommunicationDisturbanceBound(out,cfg);
    coveragePass = coveragePass && all(D.causalSetCoverage(:));
    budgetAlgebraPass = budgetAlgebraPass && ...
        max(out.controlAwareBudget.certifiedPositionBound) <= ...
        epsilonSweep_m(e)+1e-12;
    causalInvariantPass = causalInvariantPass && out.invariantViolations==0;
    unsaturatedPass = unsaturatedPass && ...
        rows(rowIndex).maxEvaluationAcceleration_mps2 < ...
        cfg.swarm.maxAccel-1e-6;

    fprintf(['epsilon %.2f m: RMSE %.4f m, DATA %.2f, C0.25 %.2f ' ...
        'Hz/channel, violation %.1f%%\n'],epsilonSweep_m(e), ...
        rows(rowIndex).formationRMSE_m,rows(rowIndex).dataRatePerChannel_Hz, ...
        rows(rowIndex).cost025PerChannel_Hz, ...
        100*rows(rowIndex).controlViolationRatio);
end

tidy = struct2table(rows);
caMask = tidy.method=="Control-aware";
ca = sortrows(tidy(caMask,:),'epsilonPosition_m');

monotoneTrafficPass = all(diff(ca.txCount)<=0);
distinctTrafficPass = numel(unique(ca.txCount))>=2;
branchPass = all(ca.controlNewInformationCount>0) && ...
    all(ca.controlUsefulInFlightSuppressedCount>0);

traceHashes = [outputs{1}.traceHashExact; outputs{2}.traceHashExact];
for e = 1:numel(epsilonSweep_m)
    traceHashes(end+1,1) = outputs{2+e}.traceHashExact; %#ok<SAGROW>
end
sharedForwardTracePass = all(traceHashes==traceHashes(1));

gatePass = coveragePass && budgetAlgebraPass && causalInvariantPass && ...
    unsaturatedPass && monotoneTrafficPass && distinctTrafficPass && ...
    branchPass && sharedForwardTracePass;

writetable(tidy,fullfile(R.dir,'tidy.csv'));

repEpsilon = 0.40;
repIndex = 2+find(epsilonSweep_m==repEpsilon,1,'first');
repOut = outputs{repIndex};
repTrace = localTrace(repOut,cfgBase,seed,repEpsilon);
writetable(repTrace,fullfile(R.dir,'representative_trace.csv'));

localWriteJson(fullfile(R.dir,'configuration.json'),struct( ...
    'classification','development-only mechanics check', ...
    'seed',seed,'scenario',sc.names{scenarioIndex}, ...
    'evaluationStart_s',evaluationStart_s, ...
    'epsilonSweep_m',epsilonSweep_m, ...
    'retryInterval_s',retryInterval_s,'baseConfiguration',cfgBase));

summary = struct();
summary.schemaVersion = 1;
summary.gate = 4;
summary.status = localPassFail(gatePass);
summary.classification = 'development-only mechanics/falsification';
summary.seed = seed;
summary.scenario = sc.names{scenarioIndex};
summary.epsilonSweep_m = epsilonSweep_m;
summary.coveragePass = coveragePass;
summary.budgetAlgebraPass = budgetAlgebraPass;
summary.causalInvariantPass = causalInvariantPass;
summary.unsaturatedPass = unsaturatedPass;
summary.monotoneTrafficPass = monotoneTrafficPass;
summary.distinctTrafficPass = distinctTrafficPass;
summary.branchPass = branchPass;
summary.sharedForwardTracePass = sharedForwardTracePass;
summary.controlAwareTxCounts = ca.txCount';
summary.controlAwareFormationRMSE_m = ca.formationRMSE_m';
summary.controlAwareCost025PerChannel_Hz = ca.cost025PerChannel_Hz';
summary.controlAwareViolationRatio = ca.controlViolationRatio';
summary.nonControllerLeaderRowPolicy = [ ...
    'legacy-v3 retained on receiver row 1 to avoid a proposed-only removal ' ...
    'of controller-irrelevant configured traffic'];
summary.interpretation = [ ...
    'This one-seed stationary run tests mechanics and sweep ordering only. ' ...
    'It neither selects epsilon nor establishes a Pareto advantage.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','Gate4_small_sanity','Color','w', ...
    'Position',[100 80 1120 850]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

nexttile;
hCA = plot(ca.cost025PerChannel_Hz,ca.formationRMSE_m,'o-', ...
    'Color',[0.10 0.38 0.70],'LineWidth',1.3,'MarkerFaceColor',[0.10 0.38 0.70]);
hold on;
hP10 = scatter(tidy.cost025PerChannel_Hz(1),tidy.formationRMSE_m(1),70, ...
    [0.25 0.25 0.25],'filled');
hLegacy = scatter(tidy.cost025PerChannel_Hz(2),tidy.formationRMSE_m(2),70, ...
    [0.80 0.25 0.12],'filled');
xlabel('DATA + 0.25 ACK [Hz/channel]');
ylabel('formation RMSE [m]');
legend([hCA hP10 hLegacy],{'control-aware sweep','P10','Causal-v3'}, ...
    'Location','best');
grid on;
title('Development mechanics only: no operating point selected');

nexttile;
plot(repTrace.time_s,repTrace.maxNormalizedControlRisk,'LineWidth',1.2, ...
    'Color',[0.10 0.38 0.70]); hold on;
yline(1,'--','allocated local budget','Color',[0.80 0.25 0.12]);
ylabel('max link risk / budget');
xlim([0 cfgBase.swarm.T]);
grid on;
title(sprintf('Representative fixed sweep point: \\epsilon_d = %.2f m', ...
    repEpsilon));

nexttile;
yyaxis left;
stairs(repTrace.time_s,repTrace.controlAwareTxThisStep,'LineWidth',1.0);
hold on;
stairs(repTrace.time_s,repTrace.violatingLinksThisStep,'--','LineWidth',1.0);
ylabel('events / links per step');
yyaxis right;
plot(repTrace.time_s,repTrace.formationRMS_m,'LineWidth',1.15);
ylabel('formation RMS [m]');
xlabel('time [s]');
xlim([0 cfgBase.swarm.T]);
legend({'control-aware TX','violating links','formation RMS'}, ...
    'Location','best');
grid on;

saveAllFigures(R);

fprintf('\nGate 4 small-sanity verdict: %s\n',summary.status);
fprintf('  coverage / budget algebra / causal       %d / %d / %d\n', ...
    coveragePass,budgetAlgebraPass,causalInvariantPass);
fprintf('  unsaturated / monotone / distinct        %d / %d / %d\n', ...
    unsaturatedPass,monotoneTrafficPass,distinctTrafficPass);
fprintf('  branches / shared forward trace          %d / %d\n', ...
    branchPass,sharedForwardTracePass);

save(fullfile(R.dir,'workspace.mat'),'cfgBase','epsilonSweep_m','tidy', ...
    'repTrace','summary');
finishExperiment(R);

if ~gatePass
    error('tcns_gate4_small_sanity:GateFailed', ...
        'Gate-4 mechanics criteria failed; do not expand experiments.');
end


function row = localRow(out,cfg,method,epsilon,evaluationStart)

metrics = computeSwarmMetrics(out,cfg);
missionTime = out.t(end)-out.t(1);
nChannels = nnz(cfg.swarm.A)+nnz(cfg.swarm.pin);
ackCount = 0;
ackRate = 0;
if isfield(out,'ackTxCount')
    ackCount = out.ackTxCount;
    ackRate = ackCount/max(missionTime,eps);
end
dataRate = out.txCount/max(missionTime,eps);
idx = out.t>=evaluationStart;
acceleration = vecnorm(reshape(out.A(idx,2:end,:),[],3),2,2);

row = localEmptyRow();
row.method = string(method);
row.epsilonPosition_m = epsilon;
row.seed = cfg.net.seed;
row.formationRMSE_m = metrics.formationRMSE;
row.maxFormationError_m = metrics.maxFormationError;
row.txCount = out.txCount;
row.ackCount = ackCount;
row.dataRatePerChannel_Hz = dataRate/nChannels;
row.cost025PerChannel_Hz = (dataRate+0.25*ackRate)/nChannels;
row.broadcastRate_Hz = out.broadcastCount/max(missionTime,eps);
row.maxEvaluationAcceleration_mps2 = max(acceleration);
row.traceHashExact = out.traceHashExact;

if isfield(out,'controlAwareActive') && out.controlAwareActive
    row.receiverCommandBudget_mps2 = ...
        out.controlAwareBudget.receiverCommandBudget;
    row.controlViolationRatio = out.controlAwareViolationRatio;
    row.controlMeanNormalizedRisk = out.controlAwareMeanNormalizedRisk;
    row.controlMaxNormalizedRisk = out.controlAwareMaxNormalizedRisk;
    row.controlNewInformationCount = ...
        out.controlAwareNewInformationCount;
    row.controlRecoveryCount = out.controlAwareRecoveryCount;
    row.controlRetryCount = out.controlAwareRetryCount;
    row.controlUsefulInFlightSuppressedCount = ...
        out.controlAwareUsefulInFlightSuppressedCount;
end

end


function row = localEmptyRow()

row = struct('method',"",'epsilonPosition_m',NaN,'seed',NaN, ...
    'formationRMSE_m',NaN,'maxFormationError_m',NaN,'txCount',NaN, ...
    'ackCount',NaN,'dataRatePerChannel_Hz',NaN, ...
    'cost025PerChannel_Hz',NaN,'broadcastRate_Hz',NaN, ...
    'maxEvaluationAcceleration_mps2',NaN,'traceHashExact',NaN, ...
    'receiverCommandBudget_mps2',NaN,'controlViolationRatio',NaN, ...
    'controlMeanNormalizedRisk',NaN,'controlMaxNormalizedRisk',NaN, ...
    'controlNewInformationCount',NaN,'controlRecoveryCount',NaN, ...
    'controlRetryCount',NaN, ...
    'controlUsefulInFlightSuppressedCount',NaN);

end


function trace = localTrace(out,cfg,seed,epsilon)

K = numel(out.t);
m = cfg.swarm.N-1;
formation = zeros(K,m);
for k = 1:K
    P = reshape(out.P(k,2:end,:),m,3);
    leader = reshape(out.P(k,1,:),1,3);
    formation(k,:) = vecnorm(P-(leader+cfg.swarm.offsets(2:end,:)),2,2)';
end

caCumulative = out.controlAwareNewInformationCountLog + ...
    out.controlAwareRecoveryCountLog + out.controlAwareRetryCountLog;
txThisStep = [caCumulative(1);diff(caCumulative)];
trace = table(out.t,repmat(seed,K,1),repmat(epsilon,K,1), ...
    out.controlAwareStepRiskMax,out.controlAwareStepViolationCount, ...
    txThisStep,sqrt(mean(formation.^2,2)), ...
    'VariableNames',{'time_s','seed','epsilonPosition_m', ...
    'maxNormalizedControlRisk','violatingLinksThisStep', ...
    'controlAwareTxThisStep','formationRMS_m'});

end


function value = localPassFail(pass)

if pass
    value = 'PASS';
else
    value = 'FAIL';
end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
assert(fid>0,'Gate4: cannot create %s.',path);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleaner;

end
