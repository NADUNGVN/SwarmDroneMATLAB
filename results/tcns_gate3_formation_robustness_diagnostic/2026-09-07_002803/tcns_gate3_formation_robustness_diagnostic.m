%% TCNS GATE 3 - Communication uncertainty to formation robustness
%
% Development-only validation of the structured finite-horizon and UUB
% certificates. The run uses the same five Gate-2 development seeds and no
% policy parameter search. At t=8 s a perfect-current-information
% counterfactual is initialized from the stale trajectory's exact state.

startup;
close all;

R = startExperiment('tcns_gate3_formation_robustness_diagnostic', ...
    ['Development validation of structured sampled formation-degradation ' ...
     'bounds; frozen policy/channel and no parameter search.']);

sc = exp10Scenarios();
points = exp10Points();
pt = points(strcmp({points.id},'NOMINAL'));
seeds = (27020001:27020005)';
scenarioIndex = sc.STRESSED;
scenarioName = string(sc.names{scenarioIndex});
evaluationStart_s = 8;
tol = 2e-10;

cfg0 = applyExp10Point(pt,scenarioIndex,seeds(1));
cfg0.sixdof.enable = false;
cfg0.tcns.logReceiverState = true;
cfg0.tcns.logCausalSetBound = true;
certificate = tcnsFormationRobustnessCertificate(cfg0);

rows = repmat(localEmptyRow(),numel(seeds),1);
representativeTrace = table();

for s = 1:numel(seeds)
    cfg = applyExp10Point(pt,scenarioIndex,seeds(s));
    cfg.sixdof.enable = false;
    cfg.tcns.logReceiverState = true;
    cfg.tcns.logCausalSetBound = true;
    out = simSwarmAoICausal(cfg);
    metrics = computeSwarmMetrics(out,cfg);

    D = tcnsCommunicationDisturbanceBound(out,cfg);
    assert(all(D.coverage(:)), ...
        'Gate3: Gate-2 control-disturbance budget was violated.');
    assert(all(D.causalSetCoverage(:)), ...
        'Gate3: receiver state escaped the causal sender information set.');

    startIndex = find(out.t>=evaluationStart_s,1,'first');
    ideal = tcnsPerfectInformationContinuation(out,cfg,startIndex);
    idx = startIndex:numel(out.t);
    K = numel(idx);
    m = cfg.swarm.N-1;
    h = cfg.swarm.dt;

    actualAcceleration = vecnorm(reshape( ...
        out.A(idx,2:end,:),[],3),2,2);
    actualMaxAcceleration = max(actualAcceleration);
    assert(actualMaxAcceleration<cfg.swarm.maxAccel-1e-6 && ...
        ideal.maxFollowerAcceleration<cfg.swarm.maxAccel-1e-6, ...
        'Gate3: an evaluation continuation entered acceleration saturation.');

    recurrenceResidual = localRecurrenceResidual( ...
        out,ideal,D,cfg,startIndex);
    assert(recurrenceResidual<tol, ...
        'Gate3: exact communication-degradation recurrence failed.');

    theoretical = tcnsFiniteHorizonFormationBound( ...
        cfg,D.causalSetBound(idx,:));
    hardAccelerationEnvelope = tcnsFiniteHorizonFormationBound( ...
        cfg,D.bound(idx,:));
    actualNormInput = tcnsFiniteHorizonFormationBound( ...
        cfg,D.actualNorm(idx,:));

    actualPositionDegradation = zeros(K,m);
    actualScaledVelocityDegradation = zeros(K,m);
    actualFormationError = zeros(K,m);
    idealFormationError = zeros(K,m);

    for k = 1:K
        actualP = reshape(out.P(idx(k),2:end,:),m,3);
        actualV = reshape(out.V(idx(k),2:end,:),m,3);
        idealP = reshape(ideal.P(k,2:end,:),m,3);
        idealV = reshape(ideal.V(k,2:end,:),m,3);
        leaderP = out.LeaderPos(idx(k),:);

        actualPositionDegradation(k,:) = vecnorm(actualP-idealP,2,2)';
        actualScaledVelocityDegradation(k,:) = ...
            h*vecnorm(actualV-idealV,2,2)';
        actualFormationError(k,:) = vecnorm(actualP - ...
            (leaderP+cfg.swarm.offsets(2:end,:)),2,2)';
        idealFormationError(k,:) = vecnorm(idealP - ...
            (leaderP+cfg.swarm.offsets(2:end,:)),2,2)';
    end

    robustFormationBound = idealFormationError+theoretical.position;
    positionViolation = actualPositionDegradation-theoretical.position;
    velocityViolation = actualScaledVelocityDegradation - ...
        theoretical.scaledVelocity;
    formationViolation = actualFormationError-robustFormationBound;

    bbar = max(D.causalSetBound(idx,:),[],1)';
    structuredUub = certificate.positionPartialGain*bbar + ...
        certificate.positionTailCoefficient*norm(bbar,2);
    legacyUub = certificate.legacyLyapunovInputGain * ...
        h^2*norm(bbar,2);

    row = localEmptyRow();
    row.seed = seeds(s);
    row.scenario = scenarioName;
    row.method = "Causal-v3 frozen";
    row.evaluationStart_s = evaluationStart_s;
    row.sampleCount = K;
    row.formationRMSE_m = sqrt(mean(actualFormationError.^2,'all'));
    row.metricImplementationRMSE_m = metrics.formationRMSE;
    row.perfectContinuationRMSE_m = ...
        sqrt(mean(idealFormationError.^2,'all'));
    row.formationRMSEUpper_m = ...
        sqrt(mean(robustFormationBound.^2,'all'));
    row.degradationRMS_m = ...
        sqrt(mean(actualPositionDegradation.^2,'all'));
    row.degradationRMSUpper_m = ...
        sqrt(mean(theoretical.position.^2,'all'));
    row.positionCoverage = mean(positionViolation<=tol,'all');
    row.scaledVelocityCoverage = mean(velocityViolation<=tol,'all');
    row.formationCoverage = mean(formationViolation<=tol,'all');
    row.maxPositionViolation_m = max(positionViolation,[],'all');
    row.maxScaledVelocityViolation_m = max(velocityViolation,[],'all');
    row.maxFormationViolation_m = max(formationViolation,[],'all');
    row.p95FullPositionTightness = localPercentile(localRatio( ...
        actualPositionDegradation,theoretical.position),95);
    row.p95HardAccelerationTightness = localPercentile(localRatio( ...
        actualPositionDegradation,hardAccelerationEnvelope.position),95);
    row.p95PropagationOnlyTightness = localPercentile(localRatio( ...
        actualPositionDegradation,actualNormInput.position),95);
    row.maxActualPositionDegradation_m = ...
        max(actualPositionDegradation,[],'all');
    row.maxFinitePositionBound_m = max(theoretical.position,[],'all');
    row.maxHardAccelerationFiniteBound_m = ...
        max(hardAccelerationEnvelope.position,[],'all');
    row.maxStructuredPositionUUB_m = max(structuredUub);
    row.legacyCommunicationUUB_m = legacyUub;
    row.maxDisturbanceBound_mps2 = ...
        max(D.causalSetBound(idx,:),[],'all');
    row.maxHardAccelerationDisturbanceBound_mps2 = ...
        max(D.bound(idx,:),[],'all');
    row.maxDisturbanceViolation_mps2 = max( ...
        D.actualNorm(idx,:)-D.causalSetBound(idx,:),[],'all');
    row.maxRecurrenceResidual = recurrenceResidual;
    row.maxActualAcceleration_mps2 = actualMaxAcceleration;
    row.maxIdealAcceleration_mps2 = ideal.maxFollowerAcceleration;
    rows(s) = row;

    fprintf(['seed %d: degradation max %.4f <= %.4f m, ' ...
        'p95 tight %.3f, UUB %.3f m\n'],seeds(s), ...
        row.maxActualPositionDegradation_m,row.maxFinitePositionBound_m, ...
        row.p95FullPositionTightness,row.maxStructuredPositionUUB_m);

    if s==1
        maxActualDegradation = max(actualPositionDegradation,[],2);
        maxFiniteBound = max(theoretical.position,[],2);
        rmsFormation = sqrt(mean(actualFormationError.^2,2));
        rmsPerfectFormation = sqrt(mean(idealFormationError.^2,2));
        rmsRobustBound = sqrt(mean(robustFormationBound.^2,2));
        maxControlDisturbanceBound = max(D.bound(idx,:),[],2);
        representativeTrace = table(ideal.t,repmat(seeds(s),K,1), ...
            maxActualDegradation,maxFiniteBound,rmsFormation, ...
            rmsPerfectFormation,rmsRobustBound,maxControlDisturbanceBound, ...
            'VariableNames',{'time_s','seed', ...
            'maxPositionDegradation_m','maxFinitePositionBound_m', ...
            'formationRMS_m','perfectContinuationFormationRMS_m', ...
            'robustFormationRMSBound_m','maxControlDisturbanceBound_mps2'});
    end
end

perSeed = struct2table(rows);
assert(all(perSeed.positionCoverage==1) && ...
    all(perSeed.scaledVelocityCoverage==1) && ...
    all(perSeed.formationCoverage==1), ...
    'Gate3: at least one structured robustness envelope lost coverage.');
assert(max(abs(perSeed.formationRMSE_m - ...
    perSeed.metricImplementationRMSE_m))<1e-12, ...
    'Gate3: formation-RMSE translation disagrees with repository metrics.');

writetable(perSeed,fullfile(R.dir,'tidy.csv'));
writetable(representativeTrace, ...
    fullfile(R.dir,'representative_trace.csv'));
writematrix(certificate.positionPartialGain, ...
    fullfile(R.dir,'position_gain_partial.csv'));
writematrix(certificate.positionTailCoefficient, ...
    fullfile(R.dir,'position_gain_tail.csv'));

certificateRecord = rmfield(certificate,{'Ah','Bc'});
localWriteJson(fullfile(R.dir,'certificate.json'),certificateRecord);
localWriteJson(fullfile(R.dir,'configuration.json'),cfg0);

summary = struct();
summary.schemaVersion = 1;
summary.gate = 3;
summary.status = 'PASS';
summary.classification = 'development-only theory validation';
summary.seeds = seeds;
summary.scenario = char(scenarioName);
summary.evaluationStart_s = evaluationStart_s;
summary.scope = certificate.scope;
summary.blockLength = certificate.blockLength;
summary.blockContraction = certificate.blockContraction;
summary.legacyLyapunovInputGain = certificate.legacyLyapunovInputGain;
summary.maxUnitInputPositionUUB = ...
    max(certificate.unitInputPositionUltimateBound);
summary.minPositionCoverage = min(perSeed.positionCoverage);
summary.minFormationCoverage = min(perSeed.formationCoverage);
summary.maxRecurrenceResidual = max(perSeed.maxRecurrenceResidual);
summary.meanP95FullPositionTightness = ...
    mean(perSeed.p95FullPositionTightness);
summary.meanP95HardAccelerationTightness = ...
    mean(perSeed.p95HardAccelerationTightness);
summary.meanP95PropagationOnlyTightness = ...
    mean(perSeed.p95PropagationOnlyTightness);
summary.meanActualDegradationRMS_m = mean(perSeed.degradationRMS_m);
summary.meanDegradationRMSUpper_m = ...
    mean(perSeed.degradationRMSUpper_m);
summary.meanFormationRMSE_m = mean(perSeed.formationRMSE_m);
summary.meanFormationRMSEUpper_m = mean(perSeed.formationRMSEUpper_m);
summary.meanMaxStructuredPositionUUB_m = ...
    mean(perSeed.maxStructuredPositionUUB_m);
summary.meanLegacyCommunicationUUB_m = ...
    mean(perSeed.legacyCommunicationUUB_m);
summary.interpretation = [ ...
    'The theorem uses the causal ACK-confirmed-plus-outstanding payload ' ...
    'information set to bound communication-induced degradation relative ' ...
    'to a perfect-current-information continuation sharing the state at ' ...
    '8 s. Coverage does not establish policy superiority.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','Gate3_formation_robustness','Color','w', ...
    'Position',[100 100 1100 720]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

nexttile;
plot(representativeTrace.time_s, ...
    representativeTrace.maxPositionDegradation_m, ...
    'Color',[0.12 0.34 0.68],'LineWidth',1.35); hold on;
plot(representativeTrace.time_s, ...
    representativeTrace.maxFinitePositionBound_m,'--', ...
    'Color',[0.80 0.23 0.16],'LineWidth',1.2);
ylabel('max follower degradation [m]');
title(sprintf('Fixed development trace: seed %d', ...
    representativeTrace.seed(1)));
legend({'actual stale-vs-perfect degradation', ...
    'Gate-3 finite-horizon bound'},'Location','northwest');
grid on;

nexttile;
plot(representativeTrace.time_s,representativeTrace.formationRMS_m, ...
    'Color',[0.12 0.34 0.68],'LineWidth',1.35); hold on;
plot(representativeTrace.time_s, ...
    representativeTrace.perfectContinuationFormationRMS_m,':', ...
    'Color',[0.20 0.20 0.20],'LineWidth',1.15);
plot(representativeTrace.time_s, ...
    representativeTrace.robustFormationRMSBound_m,'--', ...
    'Color',[0.80 0.23 0.16],'LineWidth',1.2);
xlabel('time [s]');
ylabel('formation RMS / bound [m]');
legend({'actual stale-information formation', ...
    'perfect-information continuation','robust formation bound'}, ...
    'Location','northwest');
grid on;

saveAllFigures(R);

fprintf('\nGate 3 formation robustness: PASS\n');
fprintf('  minimum position/formation coverage : %.6f / %.6f\n', ...
    summary.minPositionCoverage,summary.minFormationCoverage);
fprintf('  max recurrence residual             : %.3e\n', ...
    summary.maxRecurrenceResidual);
fprintf('  mean p95 full-bound tightness        : %.4f\n', ...
    summary.meanP95FullPositionTightness);
fprintf('  mean p95 hard-accel tightness        : %.4f\n', ...
    summary.meanP95HardAccelerationTightness);
fprintf('  mean degradation RMS / upper [m]    : %.4f / %.4f\n', ...
    summary.meanActualDegradationRMS_m, ...
    summary.meanDegradationRMSUpper_m);
fprintf('  structured / legacy mean UUB [m]    : %.3f / %.3e\n', ...
    summary.meanMaxStructuredPositionUUB_m, ...
    summary.meanLegacyCommunicationUUB_m);

save(fullfile(R.dir,'workspace.mat'),'cfg0','seeds','certificate', ...
    'perSeed','representativeTrace','summary');
finishExperiment(R);


function residual = localRecurrenceResidual(out,ideal,D,cfg,startIndex)

m = cfg.swarm.N-1;
h = cfg.swarm.dt;
cert = formationTheoryCertificate(cfg);
A = cert.sampledAcl;
B = h^2*[eye(m);eye(m)];
K = numel(ideal.t);
residual = 0;

for k = 1:K-1
    globalIndex = startIndex+k-1;
    actualP = reshape(out.P(globalIndex,2:end,:),m,3);
    actualV = reshape(out.V(globalIndex,2:end,:),m,3);
    idealP = reshape(ideal.P(k,2:end,:),m,3);
    idealV = reshape(ideal.V(k,2:end,:),m,3);
    actualPNext = reshape(out.P(globalIndex+1,2:end,:),m,3);
    actualVNext = reshape(out.V(globalIndex+1,2:end,:),m,3);
    idealPNext = reshape(ideal.P(k+1,2:end,:),m,3);
    idealVNext = reshape(ideal.V(k+1,2:end,:),m,3);
    dc = reshape(D.actual(globalIndex,:,:),m,3);

    for axis = 1:3
        y = [actualP(:,axis)-idealP(:,axis); ...
            h*(actualV(:,axis)-idealV(:,axis))];
        yNext = [actualPNext(:,axis)-idealPNext(:,axis); ...
            h*(actualVNext(:,axis)-idealVNext(:,axis))];
        residual = max(residual,norm(yNext-(A*y+B*dc(:,axis)),inf));
    end
end

end


function row = localEmptyRow()

row = struct('seed',NaN,'scenario',"",'method',"", ...
    'evaluationStart_s',NaN,'sampleCount',NaN,'formationRMSE_m',NaN, ...
    'metricImplementationRMSE_m',NaN,'perfectContinuationRMSE_m',NaN, ...
    'formationRMSEUpper_m',NaN,'degradationRMS_m',NaN, ...
    'degradationRMSUpper_m',NaN,'positionCoverage',NaN, ...
    'scaledVelocityCoverage',NaN,'formationCoverage',NaN, ...
    'maxPositionViolation_m',NaN,'maxScaledVelocityViolation_m',NaN, ...
    'maxFormationViolation_m',NaN,'p95FullPositionTightness',NaN, ...
    'p95HardAccelerationTightness',NaN, ...
    'p95PropagationOnlyTightness',NaN, ...
    'maxActualPositionDegradation_m',NaN, ...
    'maxFinitePositionBound_m',NaN, ...
    'maxHardAccelerationFiniteBound_m',NaN, ...
    'maxStructuredPositionUUB_m',NaN, ...
    'legacyCommunicationUUB_m',NaN,'maxDisturbanceBound_mps2',NaN, ...
    'maxHardAccelerationDisturbanceBound_mps2',NaN, ...
    'maxDisturbanceViolation_mps2',NaN,'maxRecurrenceResidual',NaN, ...
    'maxActualAcceleration_mps2',NaN,'maxIdealAcceleration_mps2',NaN);

end


function ratio = localRatio(actual,bound)

keep = isfinite(actual) & isfinite(bound) & bound>1e-14;
ratio = actual(keep)./bound(keep);

end


function value = localPercentile(x,p)

x = sort(x(isfinite(x)));
if isempty(x)
    value = NaN;
    return;
end
position = 1+(numel(x)-1)*p/100;
lo = floor(position);
hi = ceil(position);
if lo==hi
    value = x(lo);
else
    value = x(lo)+(position-lo)*(x(hi)-x(lo));
end

end


function localWriteJson(path,value)

fid = fopen(path,'w');
assert(fid>0,'Gate3: cannot create %s.',path);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleaner;

end
