%% EXP08B - Link failure and burst outage
%
% Original controller (normalizeConsensusDegree off) and frozen
% Causal-AoI-v3. No policy, threshold, ACK, CRN or accounting change.
%
% Link failures are modelled EXCLUSIVELY at the network-delivery layer.
% cfg.swarm.A is never modified during a fault, so the controller keeps
% trying to use a dead link exactly as a real one would, and the channel
% count stays fixed so communication cost remains comparable across fault
% levels. Editing A instead would change the control problem and the cost
% denominator at once, and the two could not be separated afterwards.
%
% Fault realizations are common across methods: which links die, and when,
% depends only on the seed and the nominal graph. Otherwise a difference
% between methods would mix the policy with the luck of the draw.
%
% Conditions:
%
%   none                     nominal
%   permanent 10 / 20 / 30%  links dead for the whole run
%   burst 2 s / 5 s          30% of links drop out from t = 12 s and return
%
% Connectivity classification uses the ACTIVE graph. Two separate facts are
% reported, because they are not the same thing:
%
%   lambda2 > 0          the graph still hangs together
%   isolatedFollowers    followers that lost EVERY consensus in-link
%
% A follower can keep lambda2 > 0 through its leader pin alone while having
% no relative information at all. Reading "connected" as "every follower
% still has neighbours" would be wrong.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp08b_link_failure');


%% ============================================================
% Scope
% ============================================================

numSeeds = 3;

topologyNames = {'ring2'; 'sparse4'};

nTopo = numel(topologyNames);

swarmN = 20;

scenarioNames = {'Moderate'; 'Stressed'};

scenarioLoss  = [0.20; 0.40];
scenarioDelay = [0.08; 0.12];

nScenario = numel(scenarioNames);


faultNames  = {'none'; 'perm 10%'; 'perm 20%'; 'perm 30%'; 'burst 2s'; 'burst 5s'};
faultTypes  = {'none'; 'permanent'; 'permanent'; 'permanent'; 'burst'; 'burst'};
faultLevels = [0; 0.10; 0.20; 0.30; 2.0; 5.0];

nFault = numel(faultNames);

IDX_BURST = [5 6];


methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

nMethod = numel(methodNames);

IDX_P10    = 1;
IDX_P20    = 2;
IDX_CAUSAL = 4;


%% ============================================================
% Locked parameters
% ============================================================

epsP = 0.05;  epsV = 0.10;
aoiThreshold = 0.12;  aoiCooldown = 0.10;  maxSilence = 0.50;

safetyThreshold = 0.25;


%% ============================================================
% Fault classification, before any simulation
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP08B link failure and burst outage\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-10s %9s %10s %11s %12s\n', ...
    'topology','fault','lambda2','connected','isolated','activeInDeg');

LAMBDA2  = zeros(nTopo,nFault);
ISOLATED = zeros(nTopo,nFault);
ACTIVEDEG = zeros(nTopo,nFault);
CONNECTED = false(nTopo,nFault);

for iT = 1:nTopo
    for iF = 1:nFault

        cfgT = applyTopologyConfig(defaultConfig(), swarmN, topologyNames{iT});
        cfgT.net.seed = 1800000;

        f = generateFaultRealization(cfgT, faultTypes{iF}, faultLevels(iF));
        g = graphConnectivity(f.activeA, cfgT.swarm.pin);

        LAMBDA2(iT,iF)   = g.lambda2;
        CONNECTED(iT,iF) = g.connected;
        ISOLATED(iT,iF)  = f.isolatedFollowers;
        ACTIVEDEG(iT,iF) = f.activeInDegreeMean;

        fprintf('%-10s %-10s %9.4f %10d %11d %12.2f\n', ...
            topologyNames{iT}, faultNames{iF}, ...
            g.lambda2, g.connected, f.isolatedFollowers, f.activeInDegreeMean);

    end
end

fprintf(['\n  Conditions with lambda2 = 0 belong to the connectivity\n' ...
         '  impossibility region and are excluded from gate arithmetic.\n']);


%% ============================================================
% Storage
% ============================================================

sz = [numSeeds nMethod nFault nTopo nScenario];

RMSE     = zeros(sz);
MINEVAL  = zeros(sz);
PEAKERR  = zeros(sz);
RECOVERY = nan(sz);
PEAKAOI  = zeros(sz);
NDATA    = zeros(sz);
NACK     = zeros(sz);
MISSION  = zeros(sz);
SAFEFAIL = false(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\nSeeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n--- %s ---\n', scenarioNames{iS});

    for iT = 1:nTopo
        for iF = 1:nFault

            fprintf('  %-10s %-10s', topologyNames{iT}, faultNames{iF});

            for iM = 1:nMethod

                rmseS = zeros(numSeeds,1);
                minvS = zeros(numSeeds,1);
                peakS = zeros(numSeeds,1);
                recvS = nan(numSeeds,1);
                paoiS = zeros(numSeeds,1);
                ndatS = zeros(numSeeds,1);
                nackS = zeros(numSeeds,1);
                misS  = zeros(numSeeds,1);

                parfor s = 1:numSeeds

                    cfg = applyTopologyConfig(defaultConfig(), swarmN, topologyNames{iT});

                    % Original controller, explicitly.
                    cfg.swarm.normalizeConsensusDegree = false;

                    cfg.net.packetLoss = scenarioLoss(iS);
                    cfg.net.delay      = scenarioDelay(iS);
                    cfg.net.jitterStd  = 0;

                    cfg.net.seed = 1800000 + 10000*iS + 1000*iT + s;

                    cfg.net.useTrace    = true;
                    cfg.net.phaseOffset = false;

                    cfg.aoiEvent.posThreshold      = epsP;
                    cfg.aoiEvent.velThreshold      = epsV;
                    cfg.aoiEvent.aoiThreshold      = aoiThreshold;
                    cfg.aoiEvent.maxSilence        = maxSilence;
                    cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
                    cfg.aoiEvent.aoiMinInterTx     = aoiCooldown;
                    cfg.aoiEvent.aoiStateScaleBase = 0.50;
                    cfg.aoiEvent.aoiStateScaleMin  = 0.20;
                    cfg.aoiEvent.aoiAdaptRange     = 1.00;

                    cfg.event.posThreshold = epsP;
                    cfg.event.velThreshold = epsV;
                    cfg.event.maxSilence   = maxSilence;

                    cfg.ack.loss      = 0.0;
                    cfg.ack.delay     = scenarioDelay(iS);
                    cfg.ack.jitterStd = 0;
                    cfg.ack.useTrace  = true;
                    cfg.ack.assertInvariants = true;

                    cfg.causal.useAdaptiveScale   = true;
                    cfg.causal.useAckFeedback     = true;
                    cfg.causal.innovationPriority = true;

                    % Common fault realization: seeded, method independent.
                    cfg.fault = generateFaultRealization(cfg, ...
                        faultTypes{iF}, faultLevels(iF));

                    switch iM
                        case 1
                            cfg.net.commPeriod = 0.10;
                            out = simSwarmNetworkQueued(cfg);
                        case 2
                            cfg.net.commPeriod = 0.05;
                            out = simSwarmNetworkQueued(cfg);
                        case 3
                            out = simSwarmEventTriggered(cfg);
                        case 4
                            out = simSwarmAoICausal(cfg);
                    end

                    M = computeSwarmMetrics(out, cfg);

                    rmseS(s) = M.formationRMSE;
                    minvS(s) = M.minSeparationEval;

                    ndatS(s) = out.txCount;
                    misS(s)  = out.t(end) - out.t(1);

                    if isfield(out,'ackTxCount')
                        nackS(s) = out.ackTxCount;
                    end

                    % Worst follower error over time.
                    e = max(M.formationError(:,2:end), [], 2);

                    tF = cfg.fault.tStart;
                    tR = cfg.fault.tEnd;

                    if strcmpi(faultTypes{iF}, 'none')
                        peakS(s) = max(e(out.t >= 8));
                        paoiS(s) = max(out.meanAoI(out.t >= 8));
                    else
                        peakS(s) = max(e(out.t >= tF));
                        paoiS(s) = max(out.meanAoI(out.t >= tF));
                        recvS(s) = recoveryTime(out.t, e, tF, tR);
                    end

                end

                RMSE(:,iM,iF,iT,iS)     = rmseS;
                MINEVAL(:,iM,iF,iT,iS)  = minvS;
                PEAKERR(:,iM,iF,iT,iS)  = peakS;
                RECOVERY(:,iM,iF,iT,iS) = recvS;
                PEAKAOI(:,iM,iF,iT,iS)  = paoiS;
                NDATA(:,iM,iF,iT,iS)    = ndatS;
                NACK(:,iM,iF,iT,iS)     = nackS;
                MISSION(:,iM,iF,iT,iS)  = misS;

                SAFEFAIL(:,iM,iF,iT,iS) = minvS < safetyThreshold;

            end

            fprintf('  done\n');

        end
    end

end


meanRMSE = squeeze(mean(RMSE,1));
meanMIN  = squeeze(mean(MINEVAL,1));
meanPEAK = squeeze(mean(PEAKERR,1));
meanAOIP = squeeze(mean(PEAKAOI,1));
safeRate = squeeze(mean(SAFEFAIL,1));
rateData = squeeze(mean(NDATA,1)) ./ squeeze(mean(MISSION,1));

% Recovery may be NaN when the run never returns to baseline; NaN counts
% as a failure, so it is kept rather than averaged away.
meanRECOV = squeeze(mean(RECOVERY,1));
anyNaNRec = squeeze(any(isnan(RECOVERY),1));


%% ============================================================
% Results
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Results\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-10s %-10s %-12s %8s %8s %8s %9s %9s %8s\n', ...
    'Scenario','Topology','Fault','Method','RMSE','minSep','peakErr','recovery','peakAoI','DATA/s');

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault
            for iM = 1:nMethod
                fprintf('%-10s %-10s %-10s %-12s %8.4f %8.4f %8.4f %9.3f %9.3f %8.1f\n', ...
                    scenarioNames{iS}, topologyNames{iT}, faultNames{iF}, methodNames{iM}, ...
                    meanRMSE(iM,iF,iT,iS), meanMIN(iM,iF,iT,iS), meanPEAK(iM,iF,iT,iS), ...
                    meanRECOV(iM,iF,iT,iS), meanAOIP(iM,iF,iT,iS), rateData(iM,iF,iT,iS));
            end
            fprintf('\n');
        end
    end
end


%% ============================================================
% Gates, per section 4.2
% ============================================================

fprintf('============================================================\n');
fprintf('EXP08B acceptance gates\n');
fprintf('============================================================\n\n');

safeBreach = 0; safeCount = 0;
recBreach  = 0; recCount  = 0;
peakBreach = 0; peakCount = 0;
excluded   = 0;

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault

            if ~CONNECTED(iT,iF)
                excluded = excluded + 1;
                continue;
            end

            safeCount = safeCount + 1;
            if safeRate(IDX_CAUSAL,iF,iT,iS) > 0.05
                safeBreach = safeBreach + 1;
            end

            peakCount = peakCount + 1;
            if meanPEAK(IDX_CAUSAL,iF,iT,iS) > 1.25*meanPEAK(IDX_P10,iF,iT,iS)
                peakBreach = peakBreach + 1;
            end

            if ismember(iF, IDX_BURST)
                recCount = recCount + 1;
                rc = meanRECOV(IDX_CAUSAL,iF,iT,iS);
                r2 = meanRECOV(IDX_P20,iF,iT,iS);
                if isnan(rc) || anyNaNRec(IDX_CAUSAL,iF,iT,iS) || rc > 1.25*r2
                    recBreach = recBreach + 1;
                end
            end

        end
    end
end

gateNames  = {'SafeFail <= 5% (connected)', ...
              'Recovery <= 1.25 x P20 (burst)', ...
              'Peak error <= 1.25 x P10'};
gatePass   = [safeBreach == 0, recBreach == 0, peakBreach == 0];
gateValues = {sprintf('%d of %d breached', safeBreach, safeCount), ...
              sprintf('%d of %d breached', recBreach, recCount), ...
              sprintf('%d of %d breached', peakBreach, peakCount)};

for q = 1:numel(gateNames)
    if gatePass(q); v='PASS'; else; v='FAIL'; end
    fprintf('  [%s] %-38s %s\n', v, gateNames{q}, gateValues{q});
end

fprintf('\n  Excluded (impossibility region): %d condition(s)\n', excluded);

nFailed = sum(~gatePass);

fprintf('\n');
if nFailed == 0
    fprintf('  EXP08B GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP08B GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Table
% ============================================================

T = tidyFromArray( ...
    struct('RMSE',RMSE,'MINEVAL',MINEVAL,'PEAKERR',PEAKERR, ...
           'RECOVERY',RECOVERY,'PEAKAOI',PEAKAOI,'NDATA',NDATA, ...
           'NACK',NACK,'MISSION',MISSION,'SAFEFAIL',double(SAFEFAIL)), ...
    {'seed','method','fault','topology','scenario'}, ...
    {1:numSeeds, methodNames, faultNames, topologyNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP08B completed.\n');


save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTION
%
% Recovery time, per docs/PREREGISTRATION.md section 2.2.
%
% Baseline is the mean worst-follower error over the 3 s before the
% fault. Recovery is the earliest time after clearance at which the
% error stays within 1.1 x baseline for a full second. Never reaching
% that returns NaN, which the gate counts as a failure.
% ============================================================

function T = recoveryTime(t, e, tFault, tClear)

if isinf(tClear)
    % Permanent fault: nothing is ever restored, so recovery is
    % undefined rather than infinite.
    T = NaN;
    return;
end

base = mean(e(t >= tFault-3 & t < tFault));

if ~isfinite(base) || base <= 0
    T = NaN;
    return;
end

limit = 1.1 * base;

idx = find(t >= tClear);

for a = 1:numel(idx)

    k = idx(a);

    window = t >= t(k) & t <= t(k) + 1.0;

    if ~any(t > t(k) + 1.0)
        break;   % not enough run left to confirm
    end

    if all(e(window) <= limit)
        T = t(k) - tClear;
        return;
    end

end

T = NaN;

end
