%% TCNS POST-FALSIFICATION - True branch-at-decision value diagnostic
%
% Frozen design and decision rule:
% paper/tcns/TRUE_BRANCH_VALUE_PROTOCOL.md

startup;
close all;

R = startExperiment('tcns_true_branch_value_diagnostic', ...
    ['Development-only paired full-simulation test of whether the ' ...
     'fixed-input cross-term score predicts true one-action value.']);

scenarioIds = ["S2","S6"];
seeds = (27020001:27020005)';
anchors_s = (8.5:1:27.5)';
horizonSamples = 25;
periodSamples = 10;
links = localFixedLinks();
expectedActions = numel(scenarioIds)*numel(seeds)*numel(anchors_s);
rows = repmat(localRow(),expectedActions,1);

q = 0;
for s = 1:numel(scenarioIds)
    for r = 1:numel(seeds)
        [cfg,scenario] = tcnsGate6Scenario(seeds(r),scenarioIds(s));
        cfg.net.commPeriod = periodSamples*cfg.swarm.dt;
        cfg.tcns.logReceiverState = true;
        cfg.tcns.logPeriodicSenderFire = true;
        baseline = simSwarmNetworkQueued(cfg);
        prediction = tcnsOracleQuadraticCrossTerm( ...
            baseline,cfg,horizonSamples);

        for a = 1:numel(anchors_s)
            q = q+1;
            link = links(mod(a-1,numel(links))+1);
            candidate = localSelectCandidate( ...
                baseline,prediction,anchors_s(a),link,horizonSamples);
            branchCfg = cfg;
            branchCfg.tcns.forcedPeriodicTransmission = struct( ...
                'enabled',true,'time_s',candidate.time_s, ...
                'receiver',link.receiver,'sender',link.sender, ...
                'linkClass',link.linkClass);
            t0 = tic;
            branch = simSwarmNetworkQueued(branchCfg);
            rows(q) = localSummarize( ...
                baseline,branch,prediction,candidate,link,cfg,scenario, ...
                anchors_s(a),horizonSamples,toc(t0));
        end
        fprintf('  %s seed %d: %d paired actions complete\n', ...
            scenario.id,seeds(r),numel(anchors_s));
    end
end

actions = struct2table(rows);
writetable(actions,fullfile(R.dir,'actions.csv'));

aggregate = table();
for sid = scenarioIds
    x = actions(actions.scenarioId==sid,:);
    accepted = x(x.forcedAccepted,:);
    [corrTotal,corrIsolated] = localCorrelations(accepted);
    [topMean,bottomMean,topPositiveFraction] = ...
        localQuartileDiagnostics(accepted);
    a = table();
    a.scenarioId = sid;
    a.actionCount = height(x);
    a.successCount = height(accepted);
    a.successFraction = mean(x.forcedAccepted);
    a.correlationTotal = corrTotal;
    a.correlationIsolated = corrIsolated;
    a.correlationGain = corrTotal-corrIsolated;
    a.topQuartileMeanRealizedBenefit = topMean;
    a.bottomQuartileMeanRealizedBenefit = bottomMean;
    a.topQuartilePositiveFraction = topPositiveFraction;
    a.allSuccessfulPositiveFraction = mean(accepted.realizedBenefit>0);
    aggregate = [aggregate;a]; %#ok<AGROW>
end
writetable(aggregate,fullfile(R.dir,'aggregate.csv'));

technicalPass = height(actions)==expectedActions && ...
    all(actions.selectionShift_s>=-1e-12) && ...
    all(actions.selectionShift_s<=0.18+1e-12) && ...
    all(actions.tracePaired) && all(actions.phasePaired) && ...
    all(actions.schedulePaired) && all(actions.preDecisionIdentity) && ...
    all(actions.txDelta==1) && all(actions.broadcastDelta==1) && ...
    all(actions.forcedAttempted) && ...
    all(actions.forcedAccepted==~actions.forcedDropped) && ...
    all(actions.dropStateIdentity(actions.forcedDropped)) && ...
    all(actions.baselineSaturationFraction==0) && ...
    all(actions.branchSaturationFraction==0) && ...
    all(aggregate.successCount>=50) && ...
    mean(actions.forcedAccepted)>=0.65 && ...
    mean(actions.forcedAccepted)<=0.95;

decision = table();
for sid = scenarioIds
    a = aggregate(aggregate.scenarioId==sid,:);
    d = table();
    d.scenarioId = sid;
    d.correlationTotal = a.correlationTotal;
    d.correlationIsolated = a.correlationIsolated;
    d.correlationGain = a.correlationGain;
    d.topQuartileMeanRealizedBenefit = ...
        a.topQuartileMeanRealizedBenefit;
    d.bottomQuartileMeanRealizedBenefit = ...
        a.bottomQuartileMeanRealizedBenefit;
    d.topQuartilePositiveFraction = a.topQuartilePositiveFraction;
    d.predictionGate = d.correlationTotal>=0.50;
    d.incrementalInformationGate = d.correlationGain>=0.10;
    d.positiveHeadroomGate = d.topQuartilePositiveFraction>=0.75;
    d.rankingHeadroomGate = d.topQuartileMeanRealizedBenefit > ...
        d.bottomQuartileMeanRealizedBenefit;
    d.scenarioPass = d.predictionGate && ...
        d.incrementalInformationGate && d.positiveHeadroomGate && ...
        d.rankingHeadroomGate;
    decision = [decision;d]; %#ok<AGROW>
end
writetable(decision,fullfile(R.dir,'decision.csv'));

if ~technicalPass
    scientificDecision = 'INVALID_OR_OUT_OF_SCOPE';
elseif all(decision.scenarioPass)
    scientificDecision = 'BRANCH_SIGNAL_VALID';
else
    scientificDecision = 'STOP_RICH_VOI';
end

localPlot(actions,scenarioIds);
saveAllFigures(R);

summary = struct();
summary.schemaVersion = 1;
summary.classification = ...
    'development-only paired true branch-at-decision diagnostic';
summary.technicalStatus = localPassFail(technicalPass);
summary.scientificDecision = scientificDecision;
summary.actionCount = height(actions);
summary.successCount = nnz(actions.forcedAccepted);
summary.successFraction = mean(actions.forcedAccepted);
summary.scenarios = scenarioIds;
summary.seeds = seeds;
summary.anchorTimes_s = anchors_s;
summary.horizonSamples = horizonSamples;
summary.periodSamples = periodSamples;
summary.decision = table2struct(decision);
summary.warning = [ ...
    'A single forced action on a periodic baseline is not an online ' ...
    'adaptive policy or a Pareto-frontier result.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

fprintf('\nTrue branch-at-decision value diagnostic\n');
disp(decision);
fprintf('Technical status: %s\n',summary.technicalStatus);
fprintf('Scientific decision: %s\n',scientificDecision);
fprintf('Results: %s\n',R.dir);

finishExperiment(R);


function links = localFixedLinks()

receiver = {2,2,3,3,4,4,5,5,2,4};
sender = {1,3,2,4,3,5,1,4,1,1};
linkClass = repmat({'ordinary'},1,10);
linkClass(9:10) = {'pinned-leader','pinned-leader'};
links = struct('receiver',receiver,'sender',sender, ...
    'linkClass',linkClass);

end


function candidate = localSelectCandidate( ...
    baseline,Q,anchor_s,link,horizonSamples)

startIndex = find(baseline.t>=anchor_s-1e-12,1,'first');
lastIndex = min([startIndex+9,Q.lastDecisionIndex, ...
    numel(baseline.t)-horizonSamples]);
if strcmp(link.linkClass,'ordinary')
    score = Q.ordinaryIsolatedResponseEnergy( ...
        :,link.receiver,link.sender);
    total = Q.ordinaryExpectedBenefit(:,link.receiver,link.sender);
    crossContribution = Q.ordinaryCrossContribution( ...
        :,link.receiver,link.sender);
    scheduleSlot = link.sender;
else
    score = Q.leaderIsolatedResponseEnergy(:,link.receiver);
    total = Q.leaderExpectedBenefit(:,link.receiver);
    crossContribution = Q.leaderCrossContribution(:,link.receiver);
    scheduleSlot = size(baseline.periodicSenderFireLog,2);
end

k = [];
for candidateIndex = startIndex:lastIndex
    eligible = ~baseline.periodicSenderFireLog( ...
        candidateIndex,scheduleSlot) && ...
        isfinite(score(candidateIndex)) && score(candidateIndex)>1e-14;
    if eligible
        k = candidateIndex;
        break;
    end
end
if isempty(k)
    error('tcnsTrueBranch:NoCandidate', ...
        'No eligible candidate for anchor %.2f and link %s %d->%d.', ...
        anchor_s,link.linkClass,link.sender,link.receiver);
end

candidate.index = k;
candidate.time_s = baseline.t(k);
candidate.expectedIsolated = score(k);
candidate.expectedTotal = total(k);
candidate.expectedCrossContribution = crossContribution(k);

end


function row = localRow()

row = struct('scenarioId',"",'scenario',"",'seed',NaN, ...
    'anchor_s',NaN,'decisionTime_s',NaN,'selectionShift_s',NaN, ...
    'linkClass',"",'receiver',NaN,'sender',NaN,'eventWindow',false, ...
    'expectedIsolatedEnergy',NaN,'expectedCrossContribution',NaN, ...
    'expectedTotalBenefit',NaN,'conditionalIsolatedEnergy',NaN, ...
    'conditionalTotalBenefit',NaN,'baselineFormationEnergy',NaN, ...
    'branchFormationEnergy',NaN,'realizedBenefit',NaN, ...
    'forcedAttempted',false,'forcedDropped',false, ...
    'forcedAccepted',false,'txDelta',NaN,'broadcastDelta',NaN, ...
    'rxDelta',NaN,'dropDelta',NaN,'tracePaired',false, ...
    'phasePaired',false,'schedulePaired',false, ...
    'preDecisionIdentity',false,'dropStateIdentity',false, ...
    'baselineSaturationFraction',NaN,'branchSaturationFraction',NaN, ...
    'runtime_s',NaN);

end


function row = localSummarize( ...
    baseline,branch,Q,candidate,link,cfg,scenario,anchor_s,H,runtime_s)

row = localRow();
row.scenarioId = string(scenario.id);
row.scenario = string(scenario.name);
row.seed = cfg.net.seed;
row.anchor_s = anchor_s;
row.decisionTime_s = candidate.time_s;
row.selectionShift_s = candidate.time_s-anchor_s;
row.linkClass = string(link.linkClass);
row.receiver = link.receiver;
row.sender = link.sender;
row.eventWindow = localWindowMask(candidate.time_s,scenario.eventWindows_s);
row.expectedIsolatedEnergy = candidate.expectedIsolated;
row.expectedCrossContribution = candidate.expectedCrossContribution;
row.expectedTotalBenefit = candidate.expectedTotal;
row.conditionalIsolatedEnergy = ...
    candidate.expectedIsolated/Q.successProbability;
row.conditionalTotalBenefit = ...
    candidate.expectedTotal/Q.successProbability;

k = candidate.index;
row.baselineFormationEnergy = localFormationEnergy(baseline,k,H,cfg);
row.branchFormationEnergy = localFormationEnergy(branch,k,H,cfg);
row.realizedBenefit = ...
    row.baselineFormationEnergy-row.branchFormationEnergy;

F = branch.forcedPeriodicTransmission;
row.forcedAttempted = F.attempted;
row.forcedDropped = F.dropped;
row.forcedAccepted = F.accepted;
row.txDelta = branch.txCount-baseline.txCount;
row.broadcastDelta = branch.broadcastCount-baseline.broadcastCount;
row.rxDelta = branch.rxCount-baseline.rxCount;
row.dropDelta = branch.dropCount-baseline.dropCount;
row.tracePaired = branch.traceHashExact==baseline.traceHashExact;
row.phasePaired = branch.phaseHash==baseline.phaseHash;
row.schedulePaired = isequal( ...
    branch.periodicSenderFireLog,baseline.periodicSenderFireLog);
row.preDecisionIdentity = isequaln( ...
    branch.P(1:k,:,:),baseline.P(1:k,:,:)) && ...
    isequaln(branch.V(1:k,:,:),baseline.V(1:k,:,:));
row.dropStateIdentity = ~F.dropped || ...
    (isequaln(branch.P,baseline.P) && isequaln(branch.V,baseline.V) && ...
    isequaln(branch.A,baseline.A));

evaluationMask = baseline.t>=scenario.evaluationStart_s;
row.baselineSaturationFraction = localSaturationFraction( ...
    baseline.A(evaluationMask,:,:),cfg);
row.branchSaturationFraction = localSaturationFraction( ...
    branch.A(evaluationMask,:,:),cfg);
row.runtime_s = runtime_s;

end


function value = localFormationEnergy(out,k,H,cfg)

followers = 2:cfg.swarm.N;
index = k+(1:H);
position = out.P(index,followers,:);
leader = out.P(index,1,:);
offset = out.desiredOffsets(index,followers,:);
error = position-leader-offset;
value = sum(error.^2,'all')/numel(followers);

end


function fraction = localSaturationFraction(acceleration,cfg)

followerAcceleration = reshape(acceleration(:,2:end,:),[],3);
fraction = mean(vecnorm(followerAcceleration,2,2)>= ...
    cfg.swarm.maxAccel-1e-10);

end


function [corrTotal,corrIsolated] = localCorrelations(T)

Rt = corrcoef(T.conditionalTotalBenefit,T.realizedBenefit);
Ri = corrcoef(T.conditionalIsolatedEnergy,T.realizedBenefit);
corrTotal = Rt(1,2);
corrIsolated = Ri(1,2);

end


function [topMean,bottomMean,topPositiveFraction] = ...
    localQuartileDiagnostics(T)

[~,order] = sort(T.conditionalTotalBenefit,'descend');
n = max(1,ceil(0.25*height(T)));
top = order(1:n);
bottom = order(end-n+1:end);
topMean = mean(T.realizedBenefit(top));
bottomMean = mean(T.realizedBenefit(bottom));
topPositiveFraction = mean(T.realizedBenefit(top)>0);

end


function localPlot(actions,scenarioIds)

figure('Name','TCNS_true_branch_value','Color','w', ...
    'Position',[80 80 1200 720]);
tiledlayout(2,numel(scenarioIds),'TileSpacing','compact','Padding','compact');
for s = 1:numel(scenarioIds)
    x = actions(actions.scenarioId==scenarioIds(s) & ...
        actions.forcedAccepted,:);
    nexttile(s);
    scatter(x.conditionalTotalBenefit,x.realizedBenefit,20, ...
        double(x.eventWindow),'filled');
    yline(0,'k--');
    xlabel('cross-term predictor');
    ylabel('realized branch benefit');
    title(scenarioIds(s)+" total predictor");
    grid on;

    nexttile(numel(scenarioIds)+s);
    scatter(x.conditionalIsolatedEnergy,x.realizedBenefit,20, ...
        double(x.eventWindow),'filled');
    yline(0,'k--');
    xlabel('isolated-energy predictor');
    ylabel('realized branch benefit');
    title(scenarioIds(s)+" isolated predictor");
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
    error('tcnsTrueBranch:WriteJson','Cannot open %s.',path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end
