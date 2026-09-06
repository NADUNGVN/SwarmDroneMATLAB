%% TCNS GATE 2 - ZOH staleness to state-uncertainty validation
%
% Development-only diagnostic. No trigger parameter is searched. Five
% fixed seeds exercise the frozen Causal-v3 policy in the frozen Stressed
% channel, but on the exact double-integrator subsystem covered by Gate 1.

startup;
close all;

R = startExperiment('tcns_gate2_staleness_bound_diagnostic', ...
    ['Development-seed validation of the exact ZOH age-to-state-error ' ...
     'envelope; no parameter sweep or policy comparison.']);

sc = exp10Scenarios();
points = exp10Points();
pt = points(strcmp({points.id},'NOMINAL'));
assert(isscalar(pt),'Gate2: unique NOMINAL EXP10 point not found.');

seeds = (27020001:27020005)';
scenarioIndex = sc.STRESSED;
scenarioName = string(sc.names{scenarioIndex});

cfg0 = applyExp10Point(pt,scenarioIndex,seeds(1));
cfg0.sixdof.enable = false;
cfg0.tcns.logReceiverState = true;

[receiverList,senderList] = find(cfg0.swarm.A~=0);
keep = receiverList>=2 & senderList>=2;
receiverList = receiverList(keep);
senderList = senderList(keep);
nLink = numel(receiverList);

assert(nLink>0,'Gate2: no follower-to-follower directed link exists.');

% This is the only deterministic global velocity envelope available from
% the current implementation without inventing a speed limiter. It is
% intentionally retained even if loose. The tighter local envelope uses
% the velocity carried by the already accepted payload.
initialSpeed = vecnorm(cfg0.swarm.initialVelocities(2:end,:),2,2);
missionVelocityEnvelope = max(initialSpeed) + ...
    cfg0.swarm.maxAccel*cfg0.swarm.T;

linkRows = repmat(localEmptyLinkRow(),numel(seeds)*nLink,1);
seedRows = repmat(localEmptySeedRow(),numel(seeds),1);
row = 0;
representativeTrace = table();

tol = 1e-10;

for s = 1:numel(seeds)
    cfg = applyExp10Point(pt,scenarioIndex,seeds(s));
    cfg.sixdof.enable = false;
    cfg.tcns.logReceiverState = true;

    out = simSwarmAoICausal(cfg);
    metrics = computeSwarmMetrics(out,cfg);
    K = numel(out.t);

    seedActualP = [];
    seedActualV = [];
    seedLocalP = [];
    seedLocalV = [];
    seedGlobalP = [];
    seedAge = [];
    seedAgeResidual = [];
    seedPayloadResidual = [];

    for ell = 1:nLink
        i = receiverList(ell);
        j = senderList(ell);
        row = row+1;

        heldP = reshape(out.receiverNeighborPosition(:,i,j,:),K,3);
        heldV = reshape(out.receiverNeighborVelocity(:,i,j,:),K,3);
        genTime = reshape(out.receiverNeighborGenTime(:,i,j),K,1);
        trueP = reshape(out.P(:,j,:),K,3);
        trueV = reshape(out.V(:,j,:),K,3);

        physicalAge = out.t-genTime;
        loggedAge = reshape(out.neighborAoI(:,i,j),K,1);
        payloadSpeed = vecnorm(heldV,2,2);

        localBound = tcnsZohStalenessBound(physicalAge,payloadSpeed, ...
            cfg.swarm.maxAccel,cfg.swarm.dt);
        globalBound = tcnsZohStalenessBound(physicalAge, ...
            missionVelocityEnvelope,cfg.swarm.maxAccel,cfg.swarm.dt);

        actualP = vecnorm(trueP-heldP,2,2);
        actualV = vecnorm(trueV-heldV,2,2);

        generatedIndex = round(genTime/cfg.swarm.dt)+1;
        generatedP = zeros(K,3);
        generatedV = zeros(K,3);
        for k = 1:K
            generatedP(k,:) = reshape(out.P(generatedIndex(k),j,:),1,3);
            generatedV(k,:) = reshape(out.V(generatedIndex(k),j,:),1,3);
        end
        payloadResidual = max(abs([heldP-generatedP heldV-generatedV]),[],2);
        ageResidual = abs(loggedAge-(physicalAge+cfg.swarm.dt/2));

        rowData = localEmptyLinkRow();
        rowData.seed = seeds(s);
        rowData.scenario = scenarioName;
        rowData.method = "Causal-v3 frozen";
        rowData.receiver = i;
        rowData.sender = j;
        rowData.sampleCount = K;
        rowData.meanPhysicalAge_s = mean(physicalAge);
        rowData.maxPhysicalAge_s = max(physicalAge);
        rowData.meanPositionError_m = mean(actualP);
        rowData.maxPositionError_m = max(actualP);
        rowData.meanLocalPositionBound_m = mean(localBound.position);
        rowData.maxLocalPositionBound_m = max(localBound.position);
        rowData.meanGlobalPositionBound_m = mean(globalBound.position);
        rowData.positionCoverage = mean(actualP<=localBound.position+tol);
        rowData.velocityCoverage = mean(actualV<=localBound.velocity+tol);
        rowData.maxPositionViolation_m = max(actualP-localBound.position);
        rowData.maxVelocityViolation_mps = max(actualV-localBound.velocity);
        rowData.medianLocalPositionTightness = ...
            localPercentile(localRatio(actualP,localBound.position),50);
        rowData.p95LocalPositionTightness = ...
            localPercentile(localRatio(actualP,localBound.position),95);
        rowData.p95GlobalPositionTightness = ...
            localPercentile(localRatio(actualP,globalBound.position),95);
        rowData.p95VelocityTightness = ...
            localPercentile(localRatio(actualV,localBound.velocity),95);
        rowData.maxAgeConventionResidual_s = max(ageResidual);
        rowData.maxPayloadGenerationResidual = max(payloadResidual);
        linkRows(row) = rowData;

        seedActualP = [seedActualP; actualP]; %#ok<AGROW>
        seedActualV = [seedActualV; actualV]; %#ok<AGROW>
        seedLocalP = [seedLocalP; localBound.position]; %#ok<AGROW>
        seedLocalV = [seedLocalV; localBound.velocity]; %#ok<AGROW>
        seedGlobalP = [seedGlobalP; globalBound.position]; %#ok<AGROW>
        seedAge = [seedAge; physicalAge]; %#ok<AGROW>
        seedAgeResidual = [seedAgeResidual; ageResidual]; %#ok<AGROW>
        seedPayloadResidual = [seedPayloadResidual; payloadResidual]; %#ok<AGROW>

        % Fixed before observing outcomes: first development seed and the
        % lexicographically first follower link after find().
        if s==1 && ell==1
            representativeTrace = table(out.t, ...
                repmat(seeds(s),K,1),repmat(i,K,1),repmat(j,K,1), ...
                physicalAge,loggedAge,actualP,localBound.position, ...
                globalBound.position,actualV,localBound.velocity, ...
                payloadSpeed, ...
                'VariableNames',{'time_s','seed','receiver','sender', ...
                'physicalAge_s','loggedAoI_s','positionError_m', ...
                'localPositionBound_m','globalPositionBound_m', ...
                'velocityError_mps','velocityBound_mps', ...
                'acceptedPayloadSpeed_mps'});
        end
    end

    seedData = localEmptySeedRow();
    seedData.seed = seeds(s);
    seedData.scenario = scenarioName;
    seedData.method = "Causal-v3 frozen";
    seedData.nLinks = nLink;
    seedData.nSamples = numel(seedActualP);
    seedData.formationRMSE_m = metrics.formationRMSE;
    seedData.dataTxCount = out.txCount;
    seedData.ackTxCount = out.ackTxCount;
    seedData.meanPhysicalAge_s = mean(seedAge);
    seedData.maxPhysicalAge_s = max(seedAge);
    seedData.positionCoverage = mean(seedActualP<=seedLocalP+tol);
    seedData.velocityCoverage = mean(seedActualV<=seedLocalV+tol);
    seedData.maxPositionViolation_m = max(seedActualP-seedLocalP);
    seedData.maxVelocityViolation_mps = max(seedActualV-seedLocalV);
    seedData.p95LocalPositionTightness = ...
        localPercentile(localRatio(seedActualP,seedLocalP),95);
    seedData.p95GlobalPositionTightness = ...
        localPercentile(localRatio(seedActualP,seedGlobalP),95);
    seedData.p95VelocityTightness = ...
        localPercentile(localRatio(seedActualV,seedLocalV),95);
    seedData.maxAgeConventionResidual_s = max(seedAgeResidual);
    seedData.maxPayloadGenerationResidual = max(seedPayloadResidual);
    seedData.maxAppliedAcceleration_mps2 = max(vecnorm( ...
        reshape(out.A(:,2:end,:),[],3),2,2));
    seedRows(s) = seedData;

    fprintf('seed %d: pos cov %.6f, vel cov %.6f, p95 tight %.3f\n', ...
        seeds(s),seedData.positionCoverage,seedData.velocityCoverage, ...
        seedData.p95LocalPositionTightness);
end

tidy = struct2table(linkRows);
perSeed = struct2table(seedRows);

assert(all(tidy.positionCoverage==1) && all(tidy.velocityCoverage==1), ...
    'Gate2: theoretical envelope coverage is below one.');
assert(max(tidy.maxAgeConventionResidual_s)<tol, ...
    'Gate2: half-step AoI conversion failed.');
assert(max(tidy.maxPayloadGenerationResidual)<tol, ...
    'Gate2: held payload is inconsistent with its generation state.');
assert(max(perSeed.maxAppliedAcceleration_mps2)<=cfg0.swarm.maxAccel+tol, ...
    'Gate2: implemented hard acceleration envelope was violated.');

writetable(tidy,fullfile(R.dir,'tidy.csv'));
writetable(perSeed,fullfile(R.dir,'per_seed.csv'));
writetable(representativeTrace,fullfile(R.dir,'representative_trace.csv'));

cfgRecord = cfg0;
localWriteJson(fullfile(R.dir,'configuration.json'),cfgRecord);

summary = struct();
summary.schemaVersion = 1;
summary.gate = 2;
summary.status = 'PASS';
summary.classification = 'development-only bound validation';
summary.seeds = seeds;
summary.scenario = char(scenarioName);
summary.packetLoss = cfg0.net.packetLoss;
summary.delay_s = cfg0.net.delay;
summary.sampleTime_s = cfg0.swarm.dt;
summary.swarmSize = cfg0.swarm.N;
summary.plant = 'semi-implicit double integrator';
summary.policy = 'Causal-v3 frozen; not evaluated for superiority';
summary.receiverEstimator = 'zero-order hold';
summary.maxAcceleration_mps2 = cfg0.swarm.maxAccel;
summary.configuredMaxSpeedEnforced = false;
summary.missionVelocityEnvelope_mps = missionVelocityEnvelope;
summary.minPositionCoverage = min(perSeed.positionCoverage);
summary.minVelocityCoverage = min(perSeed.velocityCoverage);
summary.maxPositionViolation_m = max(perSeed.maxPositionViolation_m);
summary.maxVelocityViolation_mps = max(perSeed.maxVelocityViolation_mps);
summary.meanP95LocalPositionTightness = ...
    mean(perSeed.p95LocalPositionTightness);
summary.meanP95GlobalPositionTightness = ...
    mean(perSeed.p95GlobalPositionTightness);
summary.meanP95VelocityTightness = mean(perSeed.p95VelocityTightness);
summary.maxAgeConventionResidual_s = ...
    max(perSeed.maxAgeConventionResidual_s);
summary.maxPayloadGenerationResidual = ...
    max(perSeed.maxPayloadGenerationResidual);
summary.interpretation = [ ...
    'The accepted-payload-speed envelope is deterministic and causal at ' ...
    'the receiver. The age-only mission envelope is also valid but its ' ...
    'position component is expected to be substantially more conservative ' ...
    'because the configured maxSpeed field is not enforced.'];
localWriteJson(fullfile(R.dir,'summary.json'),summary);

figure('Name','Gate2_ZOH_staleness_bound','Color','w', ...
    'Position',[100 100 1100 720]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

nexttile;
yyaxis left;
plot(representativeTrace.time_s,representativeTrace.positionError_m, ...
    'Color',[0.12 0.34 0.68],'LineWidth',1.25); hold on;
plot(representativeTrace.time_s,representativeTrace.localPositionBound_m, ...
    '--','Color',[0.80 0.23 0.16],'LineWidth',1.15);
plot(representativeTrace.time_s,representativeTrace.globalPositionBound_m, ...
    ':','Color',[0.35 0.35 0.35],'LineWidth',1.0);
ylabel('position error / bound [m]');
yyaxis right;
plot(representativeTrace.time_s,representativeTrace.physicalAge_s, ...
    'Color',[0.16 0.58 0.32 0.65],'LineWidth',0.9);
ylabel('physical age [s]');
title(sprintf('Fixed development trace: seed %d, link %d \\leftarrow %d', ...
    representativeTrace.seed(1),representativeTrace.receiver(1), ...
    representativeTrace.sender(1)));
grid on;
legend({'actual stale-position error','local theoretical bound', ...
    'age-only mission bound','physical age'},'Location','northwest');

nexttile;
yyaxis left;
plot(representativeTrace.time_s,representativeTrace.velocityError_mps, ...
    'Color',[0.12 0.34 0.68],'LineWidth',1.25); hold on;
plot(representativeTrace.time_s,representativeTrace.velocityBound_mps, ...
    '--','Color',[0.80 0.23 0.16],'LineWidth',1.15);
ylabel('velocity error / bound [m/s]');
yyaxis right;
plot(representativeTrace.time_s,representativeTrace.physicalAge_s, ...
    'Color',[0.16 0.58 0.32 0.65],'LineWidth',0.9);
ylabel('physical age [s]');
xlabel('time [s]');
grid on;
legend({'actual stale-velocity error','theoretical bound', ...
    'physical age'},'Location','northwest');

saveAllFigures(R);

fprintf('\nGate 2 ZOH staleness bound: PASS\n');
fprintf('  samples across seeds/links : %d\n',sum(perSeed.nSamples));
fprintf('  minimum position coverage : %.6f\n',summary.minPositionCoverage);
fprintf('  minimum velocity coverage : %.6f\n',summary.minVelocityCoverage);
fprintf('  mean p95 local tightness   : %.4f\n', ...
    summary.meanP95LocalPositionTightness);
fprintf('  mean p95 age-only tightness: %.4f\n', ...
    summary.meanP95GlobalPositionTightness);
fprintf('  max position violation [m]: %.3e\n', ...
    summary.maxPositionViolation_m);

save(fullfile(R.dir,'workspace.mat'),'cfg0','seeds','tidy','perSeed', ...
    'representativeTrace','summary');
finishExperiment(R);


function row = localEmptyLinkRow()

row = struct('seed',NaN,'scenario',"",'method',"",'receiver',NaN, ...
    'sender',NaN,'sampleCount',NaN,'meanPhysicalAge_s',NaN, ...
    'maxPhysicalAge_s',NaN,'meanPositionError_m',NaN, ...
    'maxPositionError_m',NaN,'meanLocalPositionBound_m',NaN, ...
    'maxLocalPositionBound_m',NaN,'meanGlobalPositionBound_m',NaN, ...
    'positionCoverage',NaN,'velocityCoverage',NaN, ...
    'maxPositionViolation_m',NaN,'maxVelocityViolation_mps',NaN, ...
    'medianLocalPositionTightness',NaN, ...
    'p95LocalPositionTightness',NaN, ...
    'p95GlobalPositionTightness',NaN,'p95VelocityTightness',NaN, ...
    'maxAgeConventionResidual_s',NaN, ...
    'maxPayloadGenerationResidual',NaN);

end


function row = localEmptySeedRow()

row = struct('seed',NaN,'scenario',"",'method',"",'nLinks',NaN, ...
    'nSamples',NaN,'formationRMSE_m',NaN,'dataTxCount',NaN, ...
    'ackTxCount',NaN,'meanPhysicalAge_s',NaN,'maxPhysicalAge_s',NaN, ...
    'positionCoverage',NaN,'velocityCoverage',NaN, ...
    'maxPositionViolation_m',NaN,'maxVelocityViolation_mps',NaN, ...
    'p95LocalPositionTightness',NaN, ...
    'p95GlobalPositionTightness',NaN,'p95VelocityTightness',NaN, ...
    'maxAgeConventionResidual_s',NaN, ...
    'maxPayloadGenerationResidual',NaN, ...
    'maxAppliedAcceleration_mps2',NaN);

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
assert(fid>0,'Gate2: cannot create %s.',path);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleaner;

end
