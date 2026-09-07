%% TCNS AF2 - passive calibration of the ACK-free receiver-memory PMF
%
% Preregistered in paper/tcns/AF2_PASSIVE_CALIBRATION_PROTOCOL.md.
% The PMF is reconstructed after each periodic run and cannot affect actions.

startup;
close all;

R = startExperiment('tcns_af2_passive_ack_free_calibration', ...
    ['Passive P10 S2/S6 calibration of the AF0 communication-filtration ' ...
     'receiver-memory PMF; no active policy and no held-out seeds.']);

scenarioIds = ["S2","S6"];
seeds = (27020001:27020005)';
period_s = 0.10;
evaluationStart_s = 8;
binEdges = 0:0.1:1;
minimumMceBinCount = 100;
thresholdNllGap = 0.05;
thresholdBrierGap = 0.03;
thresholdEce = 0.03;
thresholdMce = 0.10;

% Preallocate the exact number of link/sample observations.
nExpected = 0;
for s = 1:numel(scenarioIds)
    [cfgCount,scenarioCount] = tcnsGate6Scenario(seeds(1),scenarioIds(s));
    tCount = (0:cfgCount.swarm.dt:cfgCount.swarm.T)';
    nScored = nnz(tCount>=evaluationStart_s & ...
        tCount<scenarioCount.horizon_s-1e-12);
    nChannels = nnz(cfgCount.swarm.A)+nnz(cfgCount.swarm.pin);
    nExpected = nExpected+numel(seeds)*nScored*nChannels;
end
observationRows = repmat(localObservationRow(),nExpected,1);
runRows = repmat(localRunRow(),numel(scenarioIds)*numel(seeds),1);
binCount = zeros(numel(scenarioIds),numel(binEdges)-1);
binForecastSum = zeros(size(binCount));
binOutcomeSum = zeros(size(binCount));
observationIndex = 0;
runIndex = 0;
informationContractPass = true;

fprintf('Running %d passive P10 simulations.\n', ...
    numel(scenarioIds)*numel(seeds));
for s = 1:numel(scenarioIds)
    sid = scenarioIds(s);
    for r = 1:numel(seeds)
        [cfg,scenario] = tcnsGate6Scenario(seeds(r),sid);
        cfg.net.commPeriod = period_s;
        cfg.tcns.logReceiverState = true;
        cfg.tcns.logPeriodicSenderFire = true;
        out = simSwarmNetworkQueued(cfg);
        runIndex = runIndex+1;
        runRows(runIndex) = localRunRow(sid,seeds(r),out,cfg,scenario);

        N = cfg.swarm.N;
        certificate = formationTheoryCertificate(cfg);
        degreeScale = ones(N,1);
        degreeScale(certificate.followers) = certificate.degreeScale;
        emptyHistory = repmat(localPacket(0,0,0,[0 0 0], ...
            [0 0 0],[NaN NaN NaN]),0,1);
        histories = cell(N,1);
        seq = zeros(N,1);
        initial = cell(N,1);
        for j = 1:N
            histories{j} = emptyHistory;
            initial{j} = localPacket(0,0,0, ...
                reshape(out.P(1,j,:),1,3), ...
                reshape(out.V(1,j,:),1,3),[NaN NaN NaN]);
        end
        leaderHistory = emptyHistory;
        leaderSeq = 0;
        leaderInitial = localPacket(0,0,0, ...
            reshape(out.P(1,1,:),1,3),reshape(out.V(1,1,:),1,3), ...
            reshape(out.A(1,1,:),1,3));

        for k = 1:numel(out.t)
            tk = out.t(k);
            for j = 1:N
                if out.periodicSenderFireLog(k,j)
                    seq(j) = seq(j)+1;
                    histories{j}(end+1,1) = localPacket(seq(j),tk,tk, ...
                        reshape(out.P(k,j,:),1,3), ...
                        reshape(out.V(k,j,:),1,3),[NaN NaN NaN]); %#ok<AGROW>
                end
            end
            if out.periodicSenderFireLog(k,N+1)
                leaderSeq = leaderSeq+1;
                leaderHistory(end+1,1) = localPacket( ...
                    leaderSeq,tk,tk,reshape(out.P(k,1,:),1,3), ...
                    reshape(out.V(k,1,:),1,3), ...
                    reshape(out.A(k,1,:),1,3)); %#ok<AGROW>
            end

            if tk<evaluationStart_s || tk>=scenario.horizon_s-1e-12
                continue;
            end

            beliefs = cell(N,1);
            for j = 1:N
                if any(cfg.swarm.A(:,j))
                    beliefs{j} = tcnsAckFreeReceiverBelief( ...
                        initial{j},histories{j},tk,tk,cfg);
                end
            end
            if any(cfg.swarm.pin)
                leaderBelief = tcnsAckFreeReceiverBelief( ...
                    leaderInitial,leaderHistory,tk,tk,cfg);
            else
                leaderBelief = struct();
            end

            for i = 2:N
                for j = 1:N
                    if ~cfg.swarm.A(i,j), continue; end
                    belief = beliefs{j};
                    currentP = reshape(out.P(k,j,:),1,3);
                    currentV = reshape(out.V(k,j,:),1,3);
                    moments = tcnsAckFreeResidualMoments( ...
                        currentP,currentV,[],belief, ...
                        cfg.swarm.Kp*degreeScale(i), ...
                        cfg.swarm.Kv*degreeScale(i),0);
                    heldP = reshape( ...
                        out.receiverNeighborPosition(k,i,j,:),1,3);
                    heldV = reshape( ...
                        out.receiverNeighborVelocity(k,i,j,:),1,3);
                    actual = cfg.swarm.Kp*degreeScale(i)*(currentP-heldP) + ...
                        cfg.swarm.Kv*degreeScale(i)*(currentV-heldV);
                    realizedGen = out.receiverNeighborGenTime(k,i,j);
                    [row,outcomes] = localObservationRow( ...
                        sid,seeds(r),tk,i,j,"ordinary",belief,moments, ...
                        actual,realizedGen);
                    observationIndex = observationIndex+1;
                    observationRows(observationIndex) = row;
                    [binCount,binForecastSum,binOutcomeSum] = ...
                        localAccumulateBins(binCount,binForecastSum, ...
                        binOutcomeSum,s,belief.probability,outcomes,binEdges);
                    informationContractPass = informationContractPass && ...
                        localInformationContract(belief);
                end

                if cfg.swarm.pin(i)>0
                    currentP = reshape(out.P(k,1,:),1,3);
                    currentV = reshape(out.V(k,1,:),1,3);
                    currentA = reshape(out.A(k,1,:),1,3);
                    moments = tcnsAckFreeResidualMoments( ...
                        currentP,currentV,currentA,leaderBelief, ...
                        cfg.swarm.KpLeader,cfg.swarm.KvLeader,1);
                    heldP = reshape(out.receiverLeaderPosition(k,i,:),1,3);
                    heldV = reshape(out.receiverLeaderVelocity(k,i,:),1,3);
                    heldA = reshape( ...
                        out.receiverLeaderAcceleration(k,i,:),1,3);
                    actual = cfg.swarm.KpLeader*(currentP-heldP) + ...
                        cfg.swarm.KvLeader*(currentV-heldV) + ...
                        (currentA-heldA);
                    realizedGen = out.receiverLeaderGenTime(k,i);
                    [row,outcomes] = localObservationRow( ...
                        sid,seeds(r),tk,i,1,"pinned-leader", ...
                        leaderBelief,moments,actual,realizedGen);
                    observationIndex = observationIndex+1;
                    observationRows(observationIndex) = row;
                    [binCount,binForecastSum,binOutcomeSum] = ...
                        localAccumulateBins(binCount,binForecastSum, ...
                        binOutcomeSum,s,leaderBelief.probability, ...
                        outcomes,binEdges);
                    informationContractPass = informationContractPass && ...
                        localInformationContract(leaderBelief);
                end
            end
        end
        fprintf('  %s seed %d complete (%d observations total).\n', ...
            sid,seeds(r),observationIndex);
    end
end

if observationIndex~=nExpected
    error('tcns_af2_passive_ack_free_calibration:ObservationCount', ...
        'Expected %d observations but produced %d.',nExpected,observationIndex);
end
observations = struct2table(observationRows);
runs = struct2table(runRows);
writetable(observations,fullfile(R.dir,'tidy.csv'));
writetable(runs,fullfile(R.dir,'run_provenance.csv'));

calibrationRows = repmat(localCalibrationRow(), ...
    numel(scenarioIds)*(numel(binEdges)-1),1);
calibrationIndex = 0;
for s = 1:numel(scenarioIds)
    for b = 1:(numel(binEdges)-1)
        calibrationIndex = calibrationIndex+1;
        calibrationRows(calibrationIndex) = localCalibrationRow( ...
            scenarioIds(s),b,binEdges(b),binEdges(b+1), ...
            binCount(s,b),binForecastSum(s,b),binOutcomeSum(s,b), ...
            minimumMceBinCount);
    end
end
calibration = struct2table(calibrationRows);
writetable(calibration,fullfile(R.dir,'calibration_bins.csv'));

summaryRows = repmat(localSummaryRow(),numel(scenarioIds),1);
for s = 1:numel(scenarioIds)
    obs = observations(observations.scenarioId==scenarioIds(s),:);
    bins = calibration(calibration.scenarioId==scenarioIds(s),:);
    summaryRows(s) = localSummaryRow(scenarioIds(s),obs,bins, ...
        thresholdNllGap,thresholdBrierGap,thresholdEce,thresholdMce, ...
        informationContractPass);
end
scenarioSummary = struct2table(summaryRows);
writetable(scenarioSummary,fullfile(R.dir,'scenario_summary.csv'));

technicalPass = height(runs)==numel(scenarioIds)*numel(seeds) && ...
    all(~runs.diverged) && all(runs.receiverLogPresent) && ...
    all(runs.senderFireLogPresent) && all(runs.ackCount==0) && ...
    informationContractPass && observationIndex==nExpected;
calibrationPass = technicalPass && all(scenarioSummary.pass);
if calibrationPass
    verdict = 'AF2_CALIBRATION_PASS';
else
    verdict = 'STOP_BELIEF_MODEL';
end

result = struct('schemaVersion',1,'phase','AF2', ...
    'verdict',verdict,'technicalPass',technicalPass, ...
    'calibrationPass',calibrationPass, ...
    'scenarioIds',{cellstr(scenarioIds)},'seeds',seeds, ...
    'period_s',period_s,'evaluationStart_s',evaluationStart_s, ...
    'binEdges',binEdges,'minimumMceBinCount',minimumMceBinCount, ...
    'thresholds',struct('nllGap',thresholdNllGap, ...
        'brierGap',thresholdBrierGap,'ece',thresholdEce,'mce',thresholdMce), ...
    'informationContractPass',informationContractPass, ...
    'observationCount',height(observations), ...
    'candidateForecastCount',sum(calibration.count), ...
    'scenarioSummary',table2struct(scenarioSummary));
localWriteJson(fullfile(R.dir,'summary.json'),result);

figure('Name','AF2_ack_free_calibration','Color','w', ...
    'Position',[100 100 1080 460]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile; hold on;
plot([0 1],[0 1],'k--','DisplayName','ideal');
colors = lines(numel(scenarioIds));
for s = 1:numel(scenarioIds)
    x = calibration(calibration.scenarioId==scenarioIds(s) & ...
        calibration.count>0,:);
    plot(x.meanForecast,x.empiricalFrequency,'o-', ...
        'Color',colors(s,:),'LineWidth',1.2, ...
        'DisplayName',scenarioIds(s));
end
axis([0 1 0 1]); axis square; grid on;
xlabel('Mean predicted probability'); ylabel('Empirical frequency');
title('Receiver-state reliability'); legend('Location','best');
nexttile; hold on;
for s = 1:numel(scenarioIds)
    x = observations(observations.scenarioId==scenarioIds(s),:);
    stride = max(1,ceil(height(x)/2500));
    idx = 1:stride:height(x);
    scatter(x.expectedResidualNorm(idx),x.actualResidualNorm(idx),8, ...
        colors(s,:),'filled','MarkerFaceAlpha',0.22, ...
        'DisplayName',scenarioIds(s));
end
limit = max([observations.expectedResidualNorm; ...
    observations.actualResidualNorm]);
plot([0 limit],[0 limit],'k--','DisplayName','identity');
grid on; axis square;
xlabel('E[||d^c|| | I^{0,tx}]'); ylabel('realized ||d^c||');
title('Passive control-residual diagnostic'); legend('Location','best');
saveAllFigures(R);

disp(scenarioSummary);
fprintf('\nAF2 verdict: %s\n',verdict);
save(fullfile(R.dir,'workspace.mat'),'observations','runs', ...
    'calibration','scenarioSummary','result');
finishExperiment(R);
if ~calibrationPass
    error('tcns_af2_passive_ack_free_calibration:CalibrationStop', ...
        'AF2 returned %s under the frozen rule.',verdict);
end


function packet = localPacket(seq,sendTime,genTime,pos,vel,acc)

packet = struct('seq',seq,'sendTime',sendTime,'genTime',genTime, ...
    'pos',pos,'vel',vel,'acc',acc);

end


function [row,outcomes] = localObservationRow( ...
    scenarioId,seed,time_s,receiver,sender,linkClass,belief,moments, ...
    actualCorrection,realizedGenTime)

row = struct('scenarioId',"",'seed',NaN,'time_s',NaN,'receiver',NaN, ...
    'sender',NaN,'linkClass',"",'supportSize',NaN, ...
    'realizedSeq',NaN,'realizedGenTime_s',NaN, ...
    'realizedStateProbability',NaN,'negativeLogLikelihood',NaN, ...
    'conditionalEntropy',NaN,'brierScore',NaN, ...
    'conditionalBayesBrier',NaN,'mapCorrect',false, ...
    'normalizationResidual',NaN, ...
    'expectedResidualX',NaN,'expectedResidualY',NaN, ...
    'expectedResidualZ',NaN,'actualResidualX',NaN, ...
    'actualResidualY',NaN,'actualResidualZ',NaN, ...
    'normOfExpectedResidual',NaN,'expectedResidualNorm',NaN, ...
    'actualResidualNorm',NaN,'expectedSquaredResidualNorm',NaN, ...
    'actualSquaredResidualNorm',NaN,'momentIdentityResidual',NaN, ...
    'supportViolation',false);
if nargin==0
    outcomes = false(0,1);
    return;
end

actualCorrection = double(actualCorrection(:)');
idx = find(abs(belief.candidateGenTime-realizedGenTime)<1e-12,1);
outcomes = false(numel(belief.probability),1);
if isempty(idx)
    pTrue = 0;
    realizedSeq = NaN;
    supportViolation = true;
else
    outcomes(idx) = true;
    pTrue = belief.probability(idx);
    realizedSeq = belief.candidateSeq(idx);
    supportViolation = pTrue<=0;
end
positive = belief.probability>0;
entropy = -sum(belief.probability(positive).* ...
    log(belief.probability(positive)));
brier = sum((belief.probability-double(outcomes)).^2);
bayesBrier = 1-sum(belief.probability.^2);
[~,mapIdx] = max(belief.probability);

row.scenarioId = scenarioId;
row.seed = seed;
row.time_s = time_s;
row.receiver = receiver;
row.sender = sender;
row.linkClass = linkClass;
row.supportSize = belief.supportSize;
row.realizedSeq = realizedSeq;
row.realizedGenTime_s = realizedGenTime;
row.realizedStateProbability = pTrue;
row.negativeLogLikelihood = -log(max(pTrue,realmin));
row.conditionalEntropy = entropy;
row.brierScore = brier;
row.conditionalBayesBrier = bayesBrier;
row.mapCorrect = ~isempty(idx) && mapIdx==idx;
row.normalizationResidual = belief.normalizationResidual;
row.expectedResidualX = moments.expectedCorrection(1);
row.expectedResidualY = moments.expectedCorrection(2);
row.expectedResidualZ = moments.expectedCorrection(3);
row.actualResidualX = actualCorrection(1);
row.actualResidualY = actualCorrection(2);
row.actualResidualZ = actualCorrection(3);
row.normOfExpectedResidual = norm(moments.expectedCorrection);
row.expectedResidualNorm = moments.expectedNorm;
row.actualResidualNorm = norm(actualCorrection);
row.expectedSquaredResidualNorm = moments.expectedSquaredNorm;
row.actualSquaredResidualNorm = sum(actualCorrection.^2);
row.momentIdentityResidual = moments.identityResidual;
row.supportViolation = supportViolation;

end


function [count,forecastSum,outcomeSum] = localAccumulateBins( ...
    count,forecastSum,outcomeSum,scenarioIndex,probability,outcome,edges)

nBins = numel(edges)-1;
for q = 1:numel(probability)
    b = min(floor(probability(q)*nBins)+1,nBins);
    count(scenarioIndex,b) = count(scenarioIndex,b)+1;
    forecastSum(scenarioIndex,b) = ...
        forecastSum(scenarioIndex,b)+probability(q);
    outcomeSum(scenarioIndex,b) = ...
        outcomeSum(scenarioIndex,b)+double(outcome(q));
end

end


function row = localCalibrationRow( ...
    scenarioId,binIndex,lowerEdge,upperEdge,count,forecastSum, ...
    outcomeSum,minimumMceBinCount)

row = struct('scenarioId',"",'binIndex',NaN,'lowerEdge',NaN, ...
    'upperEdge',NaN,'count',NaN,'meanForecast',NaN, ...
    'empiricalFrequency',NaN,'absoluteGap',NaN,'includedInMCE',false);
if nargin==0, return; end
row.scenarioId = scenarioId;
row.binIndex = binIndex;
row.lowerEdge = lowerEdge;
row.upperEdge = upperEdge;
row.count = count;
if count>0
    row.meanForecast = forecastSum/count;
    row.empiricalFrequency = outcomeSum/count;
    row.absoluteGap = abs(row.meanForecast-row.empiricalFrequency);
end
row.includedInMCE = count>=minimumMceBinCount;

end


function row = localSummaryRow( ...
    scenarioId,obs,bins,nllThreshold,brierThreshold,eceThreshold, ...
    mceThreshold,informationContractPass)

row = struct('scenarioId',"",'observationCount',NaN, ...
    'candidateForecastCount',NaN,'supportViolationCount',NaN, ...
    'maxNormalizationResidual',NaN,'meanNLL',NaN,'meanEntropy',NaN, ...
    'nllMinusEntropy',NaN,'meanBrier',NaN,'meanBayesBrier',NaN, ...
    'brierMinusBayes',NaN,'ECE',NaN,'MCE',NaN,'mapAccuracy',NaN, ...
    'meanTrueProbability',NaN,'medianTrueProbability',NaN, ...
    'meanSupportSize',NaN,'maxSupportSize',NaN, ...
    'vectorComponentCorrelation',NaN,'vectorRMSE',NaN, ...
    'vectorBiasNorm',NaN,'normCorrelation',NaN,'normRMSE',NaN, ...
    'normBias',NaN,'secondMomentCorrelation',NaN, ...
    'secondMomentRMSE',NaN,'secondMomentBias',NaN, ...
    'maxMomentIdentityResidual',NaN,'supportPass',false, ...
    'probabilityPass',false,'nllPass',false,'brierPass',false, ...
    'ecePass',false,'mcePass',false,'informationContractPass',false, ...
    'pass',false,'verdict',"");
if nargin==0, return; end

row.scenarioId = scenarioId;
row.observationCount = height(obs);
row.candidateForecastCount = sum(bins.count);
row.supportViolationCount = nnz(obs.supportViolation);
row.maxNormalizationResidual = max(obs.normalizationResidual);
row.meanNLL = mean(obs.negativeLogLikelihood);
row.meanEntropy = mean(obs.conditionalEntropy);
row.nllMinusEntropy = row.meanNLL-row.meanEntropy;
row.meanBrier = mean(obs.brierScore);
row.meanBayesBrier = mean(obs.conditionalBayesBrier);
row.brierMinusBayes = row.meanBrier-row.meanBayesBrier;
nonempty = bins.count>0;
row.ECE = sum(bins.count(nonempty).*bins.absoluteGap(nonempty)) / ...
    sum(bins.count(nonempty));
mce = bins.includedInMCE & nonempty;
if any(mce), row.MCE = max(bins.absoluteGap(mce)); end
row.mapAccuracy = mean(obs.mapCorrect);
row.meanTrueProbability = mean(obs.realizedStateProbability);
row.medianTrueProbability = median(obs.realizedStateProbability);
row.meanSupportSize = mean(obs.supportSize);
row.maxSupportSize = max(obs.supportSize);

expectedVector = [obs.expectedResidualX obs.expectedResidualY ...
    obs.expectedResidualZ];
actualVector = [obs.actualResidualX obs.actualResidualY obs.actualResidualZ];
row.vectorComponentCorrelation = localCorrelation( ...
    expectedVector(:),actualVector(:));
row.vectorRMSE = sqrt(mean(sum((expectedVector-actualVector).^2,2)));
row.vectorBiasNorm = norm(mean(expectedVector-actualVector,1));
row.normCorrelation = localCorrelation( ...
    obs.expectedResidualNorm,obs.actualResidualNorm);
row.normRMSE = sqrt(mean((obs.expectedResidualNorm- ...
    obs.actualResidualNorm).^2));
row.normBias = mean(obs.expectedResidualNorm-obs.actualResidualNorm);
row.secondMomentCorrelation = localCorrelation( ...
    obs.expectedSquaredResidualNorm,obs.actualSquaredResidualNorm);
row.secondMomentRMSE = sqrt(mean((obs.expectedSquaredResidualNorm- ...
    obs.actualSquaredResidualNorm).^2));
row.secondMomentBias = mean(obs.expectedSquaredResidualNorm- ...
    obs.actualSquaredResidualNorm);
row.maxMomentIdentityResidual = max(obs.momentIdentityResidual);

row.supportPass = row.supportViolationCount==0;
row.probabilityPass = all(isfinite(obs.realizedStateProbability)) && ...
    all(obs.realizedStateProbability>=0) && ...
    row.maxNormalizationResidual<=1e-12;
row.nllPass = abs(row.nllMinusEntropy)<=nllThreshold;
row.brierPass = abs(row.brierMinusBayes)<=brierThreshold;
row.ecePass = row.ECE<=eceThreshold;
row.mcePass = isfinite(row.MCE) && row.MCE<=mceThreshold;
row.informationContractPass = informationContractPass;
row.pass = row.supportPass && row.probabilityPass && row.nllPass && ...
    row.brierPass && row.ecePass && row.mcePass && ...
    row.informationContractPass;
if row.pass
    row.verdict = "AF2_CALIBRATION_PASS";
else
    row.verdict = "STOP_BELIEF_MODEL";
end

end


function row = localRunRow(scenarioId,seed,out,cfg,scenario)

row = struct('scenarioId',"",'seed',NaN,'traceHashExact',NaN, ...
    'dt_s',NaN,'horizon_s',NaN,'period_s',NaN,'packetLoss',NaN, ...
    'delay_s',NaN,'jitterStd_s',NaN,'txCount',NaN,'ackCount',NaN, ...
    'dropCount',NaN,'receiverLogPresent',false, ...
    'senderFireLogPresent',false,'diverged',false);
if nargin==0, return; end
row.scenarioId = scenarioId;
row.seed = seed;
row.traceHashExact = out.traceHashExact;
row.dt_s = cfg.swarm.dt;
row.horizon_s = scenario.horizon_s;
row.period_s = cfg.net.commPeriod;
row.packetLoss = cfg.net.packetLoss;
row.delay_s = cfg.net.delay;
row.jitterStd_s = cfg.net.jitterStd;
row.txCount = out.txCount;
row.ackCount = 0;
row.dropCount = out.dropCount;
row.receiverLogPresent = isfield(out,'receiverNeighborGenTime') && ...
    isfield(out,'receiverLeaderGenTime');
row.senderFireLogPresent = isfield(out,'periodicSenderFireLog');
row.diverged = any(~isfinite(out.P),'all') || max(abs(out.P),[],'all')>100;

end


function pass = localInformationContract(belief)

pass = belief.exactWithinCommunicationFiltration && ...
    ~belief.conditionsOnPlantObservationHistory && ~belief.usesAck && ...
    ~belief.usesReceiverState && ~belief.usesRealizedChannelOutcome && ...
    ~belief.usesFutureInformation;

end


function value = localCorrelation(x,y)

x = double(x(:));
y = double(y(:));
valid = isfinite(x) & isfinite(y);
x = x(valid);
y = y(valid);
if numel(x)<2 || std(x)==0 || std(y)==0
    value = NaN;
    return;
end
C = corrcoef(x,y);
value = C(1,2);

end


function localWriteJson(path,value)

fid = fopen(path,'w');
if fid<0
    error('tcns_af2_passive_ack_free_calibration:JsonOpen', ...
        'Could not open %s for writing.',path);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end

