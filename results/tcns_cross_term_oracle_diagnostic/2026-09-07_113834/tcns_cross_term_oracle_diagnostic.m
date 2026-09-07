%% TCNS POST-FALSIFICATION - Centralized quadratic cross-term diagnostic
%
% Frozen design and decision rule:
% paper/tcns/CROSS_TERM_ORACLE_PROTOCOL.md

startup;
close all;

R = startExperiment('tcns_cross_term_oracle_diagnostic', ...
    ['Development-only centralized fixed-future-input audit of the ' ...
     'quadratic cross term omitted by the stopped predictive policy.']);

scenarioIds = ["S1","S2","S6"];
seeds = (27020001:27020005)';
periodSamples = 10;
horizonSamples = 25;
expectedRuns = numel(scenarioIds)*numel(seeds);
rows = repmat(localRow(),expectedRuns,1);
candidateTables = cell(expectedRuns,1);

q = 0;
for s = 1:numel(scenarioIds)
    for r = 1:numel(seeds)
        q = q+1;
        [cfg,scenario] = tcnsGate6Scenario(seeds(r),scenarioIds(s));
        cfg.net.commPeriod = periodSamples*cfg.swarm.dt;
        cfg.tcns.logReceiverState = true;
        t0 = tic;
        out = simSwarmNetworkQueued(cfg);
        value = tcnsOracleQuadraticCrossTerm(out,cfg,horizonSamples);
        candidates = localCandidates(value,cfg,scenario);
        rows(q) = localSummarize( ...
            out,value,candidates,cfg,scenario,toc(t0));
        candidateTables{q} = candidates;
        fprintf('  %s seed %d: %.1f%% non-beneficial, top overlap %.3f\n', ...
            scenario.id,seeds(r),100*rows(q).nonBeneficialFraction, ...
            rows(q).topDecileOverlap);
    end
end

raw = struct2table(rows);
candidates = vertcat(candidateTables{:});
writetable(raw,fullfile(R.dir,'runs.csv'));
writetable(candidates,fullfile(R.dir,'candidates.csv'));

aggregate = table();
for s = 1:numel(scenarioIds)
    x = raw(raw.scenarioId==scenarioIds(s),:);
    a = table();
    a.scenarioId = scenarioIds(s);
    a.scenario = x.scenario(1);
    a.runCount = height(x);
    a.meanCandidateCount = mean(x.candidateCount);
    a.meanNonBeneficialFraction = mean(x.nonBeneficialFraction);
    a.meanTopDecileOverlap = mean(x.topDecileOverlap);
    a.meanPearsonCorrelation = mean(x.pearsonCorrelation);
    a.meanCrossDominantFraction = mean(x.crossDominantFraction);
    a.meanMedianCrossToIsolatedRatio = ...
        mean(x.medianCrossToIsolatedRatio);
    a.meanEventPositiveBenefitAllocation = ...
        mean(x.eventPositiveBenefitAllocation,'omitnan');
    aggregate = [aggregate;a]; %#ok<AGROW>
end
writetable(aggregate,fullfile(R.dir,'aggregate.csv'));

technicalPass = height(raw)==expectedRuns && ...
    all(raw.candidateCount>=1000) && ...
    all(isfinite(raw.nonBeneficialFraction)) && ...
    all(isfinite(raw.topDecileOverlap)) && ...
    all(isfinite(raw.pearsonCorrelation)) && ...
    all(raw.maxDecompositionResidual<1e-12) && ...
    all(raw.saturationFraction==0) && ...
    all(raw.delaySamples==4) && ...
    all(abs(raw.successProbability-0.8)<1e-14);

decision = table();
for sid = ["S2","S6"]
    a = aggregate(aggregate.scenarioId==sid,:);
    d = table();
    d.scenarioId = sid;
    d.meanNonBeneficialFraction = a.meanNonBeneficialFraction;
    d.meanTopDecileOverlap = a.meanTopDecileOverlap;
    d.signGate = d.meanNonBeneficialFraction>=0.10;
    d.rankingGate = d.meanTopDecileOverlap<=0.80;
    d.material = d.signGate || d.rankingGate;
    decision = [decision;d]; %#ok<AGROW>
end
writetable(decision,fullfile(R.dir,'decision.csv'));

if ~technicalPass
    scientificDecision = 'INVALID_OR_OUT_OF_SCOPE';
elseif all(decision.material)
    scientificDecision = 'CROSS_TERM_MATERIAL';
else
    scientificDecision = 'CROSS_TERM_NOT_MATERIAL';
end

localPlot(candidates,scenarioIds);
saveAllFigures(R);

summary = struct();
summary.schemaVersion = 1;
summary.classification = ...
    'development-only centralized fixed-future-input cross-term diagnostic';
summary.technicalStatus = localPassFail(technicalPass);
summary.scientificDecision = scientificDecision;
summary.runCount = height(raw);
summary.candidateCount = height(candidates);
summary.scenarios = scenarioIds;
summary.seeds = seeds;
summary.periodSamples = periodSamples;
summary.horizonSamples = horizonSamples;
summary.decision = table2struct(decision);
summary.warning = [ ...
    'This is not a policy or a true closed-loop branch replay. Future ' ...
    'network inputs are frozen and the candidate correction persists.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

fprintf('\nCentralized quadratic cross-term diagnostic\n');
disp(decision);
fprintf('Technical status: %s\n',summary.technicalStatus);
fprintf('Scientific decision: %s\n',scientificDecision);
fprintf('Results: %s\n',R.dir);

finishExperiment(R);


function row = localRow()

row = struct('scenarioId',"",'scenario',"",'seed',NaN, ...
    'periodSamples',NaN,'horizonSamples',NaN,'delaySamples',NaN, ...
    'successProbability',NaN,'candidateCount',NaN, ...
    'nonBeneficialFraction',NaN,'topDecileOverlap',NaN, ...
    'pearsonCorrelation',NaN,'crossDominantFraction',NaN, ...
    'medianCrossToIsolatedRatio',NaN, ...
    'eventPositiveBenefitAllocation',NaN,'formationRMSE_m',NaN, ...
    'saturationFraction',NaN,'maxDecompositionResidual',NaN, ...
    'traceHashExact',NaN,'runtime_s',NaN);

end


function T = localCandidates(Q,cfg,scenario)

N = cfg.swarm.N;
validTime = Q.time_s>=scenario.evaluationStart_s & ...
    (1:numel(Q.time_s))'<=Q.lastDecisionIndex;
pieces = cell(nnz(cfg.swarm.A(2:end,:))+nnz(cfg.swarm.pin(2:end)),1);
q = 0;

for i = 2:N
    for j = 1:N
        if cfg.swarm.A(i,j)==0
            continue;
        end
        q = q+1;
        pieces{q} = localLinkRows( ...
            Q.time_s,Q.ordinaryIsolatedResponseEnergy(:,i,j), ...
            Q.ordinaryCrossContribution(:,i,j), ...
            Q.ordinaryExpectedBenefit(:,i,j),validTime,scenario, ...
            i,j,"ordinary",cfg.net.seed);
    end
    if cfg.swarm.pin(i)>0
        q = q+1;
        pieces{q} = localLinkRows( ...
            Q.time_s,Q.leaderIsolatedResponseEnergy(:,i), ...
            Q.leaderCrossContribution(:,i), ...
            Q.leaderExpectedBenefit(:,i),validTime,scenario, ...
            i,1,"pinned-leader",cfg.net.seed);
    end
end
T = vertcat(pieces{:});

end


function T = localLinkRows( ...
    time,isolated,crossContribution,benefit,validTime,scenario, ...
    receiver,sender,linkClass,seed)

mask = validTime & isfinite(isolated) & isolated>1e-14;
n = nnz(mask);
T = table( ...
    repmat(string(scenario.id),n,1), ...
    repmat(string(scenario.name),n,1), ...
    repmat(seed,n,1),time(mask), ...
    repmat(linkClass,n,1),repmat(receiver,n,1),repmat(sender,n,1), ...
    isolated(mask),crossContribution(mask),benefit(mask), ...
    localWindowMask(time(mask),scenario.eventWindows_s), ...
    'VariableNames',{'scenarioId','scenario','seed','time_s','linkClass', ...
    'receiver','sender','isolatedResponseEnergy','crossContribution', ...
    'expectedBenefit','eventWindow'});

end


function row = localSummarize(out,Q,C,cfg,scenario,runtime_s)

row = localRow();
row.scenarioId = string(scenario.id);
row.scenario = string(scenario.name);
row.seed = cfg.net.seed;
row.periodSamples = round(cfg.net.commPeriod/cfg.swarm.dt);
row.horizonSamples = Q.kernel.horizonSamples;
row.delaySamples = Q.delaySamples;
row.successProbability = Q.successProbability;
row.candidateCount = height(C);
row.nonBeneficialFraction = mean(C.expectedBenefit<=0);

nTop = max(1,ceil(0.10*height(C)));
[~,iIso] = sort(C.isolatedResponseEnergy,'descend');
[~,iTotal] = sort(C.expectedBenefit,'descend');
row.topDecileOverlap = numel(intersect( ...
    iIso(1:nTop),iTotal(1:nTop)))/nTop;

R = corrcoef(C.isolatedResponseEnergy,C.expectedBenefit);
row.pearsonCorrelation = R(1,2);
row.crossDominantFraction = mean( ...
    abs(C.crossContribution)>C.isolatedResponseEnergy);
row.medianCrossToIsolatedRatio = median( ...
    abs(C.crossContribution)./C.isolatedResponseEnergy);

positiveBenefit = max(C.expectedBenefit,0);
if any(C.eventWindow) && sum(positiveBenefit)>0
    valueFraction = sum(positiveBenefit(C.eventWindow)) / ...
        sum(positiveBenefit);
    durationFraction = mean(C.eventWindow);
    row.eventPositiveBenefitAllocation = ...
        valueFraction/max(durationFraction,eps);
end

metrics = computeSwarmMetrics(out,cfg);
row.formationRMSE_m = metrics.formationRMSE;
evaluationMask = out.t>=scenario.evaluationStart_s;
acceleration = vecnorm(reshape( ...
    out.A(evaluationMask,2:end,:),[],3),2,2);
row.saturationFraction = mean( ...
    acceleration>=cfg.swarm.maxAccel-1e-10);
row.maxDecompositionResidual = Q.maxDecompositionResidual;
row.traceHashExact = out.traceHashExact;
row.runtime_s = runtime_s;

end


function localPlot(C,scenarioIds)

figure('Name','TCNS_cross_term_oracle','Color','w', ...
    'Position',[80 80 1250 420]);
tiledlayout(1,numel(scenarioIds),'TileSpacing','compact','Padding','compact');
for s = 1:numel(scenarioIds)
    nexttile;
    x = C(C.scenarioId==scenarioIds(s),:);
    nonEvent = ~x.eventWindow;
    semilogx(x.isolatedResponseEnergy(nonEvent), ...
        x.expectedBenefit(nonEvent),'.','Color',[0.60 0.65 0.72], ...
        'MarkerSize',3);
    hold on;
    if any(x.eventWindow)
        semilogx(x.isolatedResponseEnergy(x.eventWindow), ...
            x.expectedBenefit(x.eventWindow),'.','Color',[0.85 0.25 0.15], ...
            'MarkerSize',4);
    end
    yline(0,'k--');
    xlabel('isolated response energy');
    ylabel('total quadratic benefit');
    title(scenarioIds(s));
    grid on;
end

end


function mask = localWindowMask(t,windows)

mask = false(size(t));
for q = 1:size(windows,1)
    mask = mask | (t>=windows(q,1)-1e-12 & t<windows(q,2)-1e-12);
end

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
    error('tcnsCrossTermOracle:WriteJson','Cannot open %s.',path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end
