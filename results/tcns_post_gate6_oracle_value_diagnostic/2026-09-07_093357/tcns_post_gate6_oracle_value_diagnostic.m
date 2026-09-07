%% TCNS POST-GATE-6 - Oracle one-shot value-signal diagnostic
%
% Frozen design and decision rule:
% paper/tcns/POST_GATE6_VOI_DIAGNOSTIC_PROTOCOL.md

startup;
close all;

R = startExperiment('tcns_post_gate6_oracle_value_diagnostic', ...
    ['Necessary-headroom test for a finite-horizon predictive VoI ' ...
     'mechanism after the Gate-6 policy falsification.']);

scenarioIds = ["S1","S2","S6"];
seeds = (27020001:27020005)';
periodSamples = 10;
horizonSamples = 25;
nRows = numel(scenarioIds)*numel(seeds);
rows = repmat(localRow(),nRows,1);
traces = cell(numel(scenarioIds),numel(seeds));

q = 0;
for s = 1:numel(scenarioIds)
    for r = 1:numel(seeds)
        q = q+1;
        [cfg,scenario] = tcnsGate6Scenario(seeds(r),scenarioIds(s));
        cfg.net.commPeriod = periodSamples*cfg.swarm.dt;
        cfg.tcns.logReceiverState = true;
        t0 = tic;
        out = simSwarmNetworkQueued(cfg);
        value = tcnsOracleLinkUpdateValue(out,cfg,horizonSamples);
        rows(q) = localSummarize(out,value,cfg,scenario,toc(t0));
        traces{s,r} = table(out.t,value.total, ...
            'VariableNames',{'time_s','oracleValue'});
    end
end

raw = struct2table(rows);
writetable(raw,fullfile(R.dir,'tidy.csv'));

aggregate = table();
for s = 1:numel(scenarioIds)
    x = raw(raw.scenarioId==scenarioIds(s),:);
    a = table();
    a.scenarioId = scenarioIds(s);
    a.scenario = x.scenario(1);
    a.runCount = height(x);
    a.meanValue = mean(x.meanOracleValue);
    a.meanTemporalCv = mean(x.temporalCv);
    a.meanEventAllocationRatio = mean(x.eventAllocationRatio,'omitnan');
    a.minEventAllocationRatio = min(x.eventAllocationRatio,[],'omitnan');
    a.meanTopDecileEventAllocationRatio = ...
        mean(x.topDecileEventAllocationRatio,'omitnan');
    aggregate = [aggregate;a]; %#ok<AGROW>
end

s1 = raw(raw.scenarioId=="S1",:);
dynamicIds = ["S2","S6"];
decisionRows = table();
for s = 1:numel(dynamicIds)
    x = raw(raw.scenarioId==dynamicIds(s),:);
    [~,ix] = sort(x.seed);
    [~,i0] = sort(s1.seed);
    pairedCvRatio = x.temporalCv(ix)./s1.temporalCv(i0);
    d = table();
    d.scenarioId = dynamicIds(s);
    d.meanEventAllocationRatio = mean(x.eventAllocationRatio);
    d.meanPairedCvRatioToS1 = mean(pairedCvRatio);
    d.eventConcentrationPass = d.meanEventAllocationRatio>=1.25;
    d.temporalVariationPass = d.meanPairedCvRatioToS1>=1.25;
    d.scenarioPass = d.eventConcentrationPass && d.temporalVariationPass;
    decisionRows = [decisionRows;d]; %#ok<AGROW>
end

technicalPass = height(raw)==nRows && ...
    all(isfinite(raw.meanOracleValue)) && all(raw.meanOracleValue>0) && ...
    all(isfinite(raw.temporalCv)) && all(raw.temporalCv>0) && ...
    all(raw.saturationFraction==0) && ...
    all(raw.delaySamples==4) && ...
    all(abs(raw.successProbability-0.8)<1e-14);
signalPresent = technicalPass && all(decisionRows.scenarioPass);
if ~technicalPass
    scientificDecision = 'OUT_OF_SCOPE_OR_INVALID';
elseif signalPresent
    scientificDecision = 'SIGNAL_PRESENT';
else
    scientificDecision = 'INSUFFICIENT_SIGNAL';
end

writetable(aggregate,fullfile(R.dir,'aggregate.csv'));
writetable(decisionRows,fullfile(R.dir,'decision.csv'));

figure('Name','PostGate6_oracle_value_signal','Color','w', ...
    'Position',[80 80 1250 410]);
tiledlayout(1,numel(scenarioIds),'TileSpacing','compact','Padding','compact');
for s = 1:numel(scenarioIds)
    nexttile;
    commonTime = traces{s,1}.time_s;
    values = zeros(numel(commonTime),numel(seeds));
    for r = 1:numel(seeds)
        values(:,r) = traces{s,r}.oracleValue;
    end
    plot(commonTime,mean(values,2),'LineWidth',1.1, ...
        'Color',[0.15 0.35 0.68]);
    hold on;
    [~,scenario] = tcnsGate6Scenario(seeds(1),scenarioIds(s));
    localWindowLines(scenario.eventWindows_s);
    xlim([8 30]);
    xlabel('time [s]');
    ylabel('oracle isolated value [m^2]');
    title(scenario.name,'Interpreter','none');
    grid on;
end
saveAllFigures(R);

summary = struct();
summary.schemaVersion = 1;
summary.classification = 'post-Gate-6 necessary-headroom diagnostic';
summary.technicalStatus = localPassFail(technicalPass);
summary.scientificDecision = scientificDecision;
summary.runCount = height(raw);
summary.scenarios = scenarioIds;
summary.seeds = seeds;
summary.periodSamples = periodSamples;
summary.period_s = periodSamples*0.02;
summary.horizonSamples = horizonSamples;
summary.horizon_s = horizonSamples*0.02;
summary.noSaturation = all(raw.saturationFraction==0);
summary.decision = table2struct(decisionRows);
summary.warning = [ ...
    'Receiver-truth isolated value is not an online policy and does not ' ...
    'include in-flight competition or multi-link cross terms.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

fprintf('\nPost-Gate-6 oracle value diagnostic\n');
disp(decisionRows);
fprintf('Technical status: %s\n',summary.technicalStatus);
fprintf('Scientific decision: %s\n',scientificDecision);
fprintf('Results: %s\n',R.dir);

finishExperiment(R);


function row = localRow()

row = struct('scenarioId',"",'scenario',"",'seed',NaN, ...
    'periodSamples',NaN,'period_s',NaN,'horizonSamples',NaN, ...
    'horizon_s',NaN,'delaySamples',NaN,'successProbability',NaN, ...
    'meanOracleValue',NaN,'maxOracleValue',NaN,'temporalCv',NaN, ...
    'eventValueFraction',NaN,'eventDurationFraction',NaN, ...
    'eventAllocationRatio',NaN,'topDecileEventFraction',NaN, ...
    'topDecileEventAllocationRatio',NaN,'formationRMSE_m',NaN, ...
    'saturationFraction',NaN,'traceHashExact',NaN,'runtime_s',NaN);

end


function row = localSummarize(out,value,cfg,scenario,runtime_s)

row = localRow();
row.scenarioId = string(scenario.id);
row.scenario = string(scenario.name);
row.seed = cfg.net.seed;
row.periodSamples = round(cfg.net.commPeriod/cfg.swarm.dt);
row.period_s = cfg.net.commPeriod;
row.horizonSamples = value.kernel.horizonSamples;
row.horizon_s = value.kernel.horizon_s;
row.delaySamples = value.delaySamples;
row.successProbability = value.successProbability;
row.traceHashExact = out.traceHashExact;
row.runtime_s = runtime_s;

evalMask = out.t>=scenario.evaluationStart_s & out.t<out.t(end)-1e-12;
score = value.total(evalMask);
row.meanOracleValue = mean(score);
row.maxOracleValue = max(score);
row.temporalCv = std(score)/max(mean(score),eps);

eventMaskAll = localWindowMask(out.t,scenario.eventWindows_s);
eventMask = eventMaskAll(evalMask);
if any(eventMask)
    row.eventValueFraction = sum(score(eventMask))/max(sum(score),eps);
    row.eventDurationFraction = mean(eventMask);
    row.eventAllocationRatio = row.eventValueFraction / ...
        max(row.eventDurationFraction,eps);

    nTop = max(1,ceil(0.10*numel(score)));
    [~,order] = sort(score,'descend');
    top = false(size(score));
    top(order(1:nTop)) = true;
    row.topDecileEventFraction = mean(eventMask(top));
    row.topDecileEventAllocationRatio = ...
        row.topDecileEventFraction/max(row.eventDurationFraction,eps);
end

metrics = computeSwarmMetrics(out,cfg);
row.formationRMSE_m = metrics.formationRMSE;
acceleration = vecnorm(reshape( ...
    out.A(out.t>=scenario.evaluationStart_s,2:end,:),[],3),2,2);
row.saturationFraction = mean( ...
    acceleration>=cfg.swarm.maxAccel-1e-10);

end


function mask = localWindowMask(t,windows)

mask = false(size(t));
for q = 1:size(windows,1)
    mask = mask | (t>=windows(q,1)-1e-12 & t<windows(q,2)-1e-12);
end

end


function localWindowLines(windows)

for q = 1:size(windows,1)
    xline(windows(q,1),'--','Color',[0.55 0.55 0.55]);
    xline(windows(q,2),'--','Color',[0.55 0.55 0.55]);
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
    error('tcnsPostGate6:WriteJson','Cannot open %s.',path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end
