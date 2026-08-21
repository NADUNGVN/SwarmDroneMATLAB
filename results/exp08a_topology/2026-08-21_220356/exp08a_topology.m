%% EXP08A - Static topology robustness
%
% Everything up to EXP07 ran on one degree-2 ring. That makes the channel
% count exactly 2.5N, so EXP06A's near-linear scaling was a property of the
% topology rather than of the method, and no result so far shows whether the
% conclusions survive a different graph.
%
% This sweeps four topologies at three swarm sizes under two networks:
%
%   N          10, 20, 50
%   topology   ring2, sparse4, sparse6, geometric
%   network    Moderate, Stressed
%
% giving 24 conditions. The Causal-AoI-v3 protocol is FROZEN: no policy,
% threshold, ACK, CRN or accounting change. Only the graph varies.
%
% Cost uses the pre-registered definition from section 2.5: TOTAL cost under
% the middle model, packet-w with w = 0.25, so DATA + 0.25*ACK.
%
% A condition whose graph is disconnected belongs to the connectivity
% impossibility region and is excluded from pass-rate arithmetic, per
% section 2.4. A policy is not judged to have failed because the network
% fell apart.
%
% ============================================================

startup;

close all;


%% ============================================================
% Result persistence
% ============================================================

expRun = startExperiment('exp08a_topology');


%% ============================================================
% Monte Carlo
%
% Debug pass. Reviewed before the 20-seed final pass.
% ============================================================

numSeeds = 3;


%% ============================================================
% Sweep axes
% ============================================================

swarmSizes = [10 20 50];

nSize = numel(swarmSizes);

topologyNames = {
    'ring2'
    'sparse4'
    'sparse6'
    'geometric'
};

nTopo = numel(topologyNames);

scenarioNames = {
    'Moderate'
    'Stressed'
};

scenarioLoss  = [0.20; 0.40];
scenarioDelay = [0.08; 0.12];

nScenario = numel(scenarioNames);

IDX_STRESSED = 2;


methodNames = {
    'P10'
    'P20'
    'State-event'
    'Causal-v3'
};

nMethod = numel(methodNames);

IDX_P10    = 1;
IDX_P20    = 2;
IDX_EVENT  = 3;
IDX_CAUSAL = 4;


%% ============================================================
% Locked policy parameters
% ============================================================

epsP         = 0.05;
epsV         = 0.10;
aoiThreshold = 0.12;
aoiCooldown  = 0.10;
maxSilence   = 0.50;

formationThreshold = 0.10;
safetyThreshold    = 0.25;

ackWeight = 0.25;   % pre-registered middle cost model


%% ============================================================
% Pre-check: every graph must be connected BEFORE any simulation
%
% Running first and checking later would waste hours on conditions
% that cannot be interpreted.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP08A topology robustness\n');
fprintf('============================================================\n\n');

fprintf('Connectivity pre-check\n\n');

fprintf('%-10s %4s %8s %9s %8s %9s %9s %10s\n', ...
    'topology','N','edges','meanDeg','minDeg','lambda2','channels','connected');

NUMEDGES  = zeros(nTopo,nSize);
MEANDEG   = zeros(nTopo,nSize);
MINDEG    = zeros(nTopo,nSize);
LAMBDA2   = zeros(nTopo,nSize);
NCHANNELS = zeros(nTopo,nSize);
CONNECTED = false(nTopo,nSize);

for iT = 1:nTopo
    for iN = 1:nSize

        cfgT = applyTopologyConfig(defaultConfig(), swarmSizes(iN), topologyNames{iT});

        g = graphConnectivity(cfgT.swarm.A, cfgT.swarm.pin);

        NUMEDGES(iT,iN)  = g.numEdges;
        MEANDEG(iT,iN)   = g.meanDegree;
        MINDEG(iT,iN)    = g.minDegree;
        LAMBDA2(iT,iN)   = g.lambda2;
        CONNECTED(iT,iN) = g.connected;
        NCHANNELS(iT,iN) = nnz(cfgT.swarm.A) + sum(cfgT.swarm.pin);

        fprintf('%-10s %4d %8d %9.2f %8d %9.4f %9d %10d\n', ...
            topologyNames{iT}, swarmSizes(iN), ...
            g.numEdges, g.meanDegree, g.minDegree, g.lambda2, ...
            NCHANNELS(iT,iN), g.connected);

    end
end

if all(CONNECTED(:))
    fprintf('\n  All %d graphs connected. Proceeding.\n', nTopo*nSize);
else
    fprintf('\n  %d graph(s) disconnected; those conditions are excluded.\n', ...
        nnz(~CONNECTED));
end


%% ============================================================
% Storage
%
% seed x method x topology x size x scenario
% ============================================================

sz = [numSeeds nMethod nTopo nSize nScenario];

RMSE    = zeros(sz);
AOI     = zeros(sz);
MINEVAL = zeros(sz);
NDATA   = zeros(sz);
NACK    = zeros(sz);
MISSION = zeros(sz);

FORMFAIL = false(sz);
SAFEFAIL = false(sz);

VIOL = zeros(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\nSeeds: %d | total sims: %d\n', ...
    numSeeds, numSeeds*nMethod*nTopo*nSize*nScenario);

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('%s | loss %.0f %% | delay %.0f ms\n', ...
        scenarioNames{iS}, 100*scenarioLoss(iS), 1000*scenarioDelay(iS));
    fprintf('------------------------------------------------------------\n');

    for iN = 1:nSize
        for iT = 1:nTopo

            if ~CONNECTED(iT,iN)
                fprintf('  N=%-3d %-10s SKIPPED (disconnected)\n', ...
                    swarmSizes(iN), topologyNames{iT});
                continue;
            end

            fprintf('  N=%-3d %-10s', swarmSizes(iN), topologyNames{iT});

            for iM = 1:nMethod

                rmseS  = zeros(numSeeds,1);
                aoiS   = zeros(numSeeds,1);
                minevS = zeros(numSeeds,1);
                ndataS = zeros(numSeeds,1);
                nackS  = zeros(numSeeds,1);
                misS   = zeros(numSeeds,1);
                violS  = zeros(numSeeds,1);

                parfor s = 1:numSeeds

                    cfg = applyTopologyConfig(defaultConfig(), ...
                        swarmSizes(iN), topologyNames{iT});

                    cfg.net.packetLoss = scenarioLoss(iS);
                    cfg.net.delay      = scenarioDelay(iS);
                    cfg.net.jitterStd  = 0;

                    cfg.net.seed = 1700000 + 100000*iS + 10000*iN + 1000*iT + s;

                    cfg.net.useTrace    = true;
                    cfg.net.phaseOffset = false;

                    cfg.event.posThreshold = epsP;
                    cfg.event.velThreshold = epsV;
                    cfg.event.maxSilence   = maxSilence;

                    cfg.aoiEvent.posThreshold      = epsP;
                    cfg.aoiEvent.velThreshold      = epsV;
                    cfg.aoiEvent.aoiThreshold      = aoiThreshold;
                    cfg.aoiEvent.maxSilence        = maxSilence;
                    cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
                    cfg.aoiEvent.aoiMinInterTx     = aoiCooldown;
                    cfg.aoiEvent.aoiStateScaleBase = 0.50;
                    cfg.aoiEvent.aoiStateScaleMin  = 0.20;
                    cfg.aoiEvent.aoiAdaptRange     = 1.00;

                    cfg.ack.loss             = 0.0;
                    cfg.ack.delay            = scenarioDelay(iS);
                    cfg.ack.jitterStd        = 0;
                    cfg.ack.useTrace         = true;
                    cfg.ack.assertInvariants = true;

                    cfg.causal.useAdaptiveScale   = true;
                    cfg.causal.useAckFeedback     = true;
                    cfg.causal.innovationPriority = true;

                    switch iM
                        case IDX_P10
                            cfg.net.commPeriod = 0.10;
                            out = simSwarmNetworkQueued(cfg);
                        case IDX_P20
                            cfg.net.commPeriod = 0.05;
                            out = simSwarmNetworkQueued(cfg);
                        case IDX_EVENT
                            out = simSwarmEventTriggered(cfg);
                        case IDX_CAUSAL
                            out = simSwarmAoICausal(cfg);
                    end

                    M = computeSwarmMetrics(out, cfg);

                    idxEval = out.t >= 8;

                    rmseS(s)  = M.formationRMSE;
                    aoiS(s)   = mean(out.meanAoI(idxEval));
                    minevS(s) = M.minSeparationEval;

                    ndataS(s) = out.txCount;
                    misS(s)   = out.t(end) - out.t(1);

                    if isfield(out,'ackTxCount')
                        nackS(s) = out.ackTxCount;
                    end

                    if isfield(out,'invariantViolations')
                        violS(s) = out.invariantViolations;
                    end

                end

                RMSE(:,iM,iT,iN,iS)    = rmseS;
                AOI(:,iM,iT,iN,iS)     = aoiS;
                MINEVAL(:,iM,iT,iN,iS) = minevS;
                NDATA(:,iM,iT,iN,iS)   = ndataS;
                NACK(:,iM,iT,iN,iS)    = nackS;
                MISSION(:,iM,iT,iN,iS) = misS;
                VIOL(:,iM,iT,iN,iS)    = violS;

                FORMFAIL(:,iM,iT,iN,iS) = rmseS  > formationThreshold;
                SAFEFAIL(:,iM,iT,iN,iS) = minevS < safetyThreshold;

            end

            fprintf('  done\n');

        end
    end

end


%% ============================================================
% Aggregate
% ============================================================

meanRMSE = squeeze(mean(RMSE,1));
meanAOI  = squeeze(mean(AOI,1));
meanMIN  = squeeze(mean(MINEVAL,1));

safeFailRate = squeeze(mean(SAFEFAIL,1));
formFailRate = squeeze(mean(FORMFAIL,1));

meanData = squeeze(mean(NDATA,1));
meanAck  = squeeze(mean(NACK,1));
meanMis  = squeeze(mean(MISSION,1));

% Pre-registered middle cost model: DATA + 0.25 * ACK, per second.
costTotal = (meanData + ackWeight*meanAck) ./ meanMis;

dataRate = meanData ./ meanMis;


%% ============================================================
% Results
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Results by condition\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-10s %4s %-12s %9s %9s %10s %9s %9s\n', ...
    'Scenario','Topology','N','Method','RMSE','AoI','cost/s','FormFail','SafeFail');

for iS = 1:nScenario
    for iN = 1:nSize
        for iT = 1:nTopo

            if ~CONNECTED(iT,iN); continue; end

            for iM = 1:nMethod
                fprintf('%-10s %-10s %4d %-12s %9.4f %9.3f %10.2f %9.2f %9.2f\n', ...
                    scenarioNames{iS}, topologyNames{iT}, swarmSizes(iN), ...
                    methodNames{iM}, ...
                    meanRMSE(iM,iT,iN,iS), meanAOI(iM,iT,iN,iS), ...
                    costTotal(iM,iT,iN,iS), ...
                    formFailRate(iM,iT,iN,iS), safeFailRate(iM,iT,iN,iS));
            end

            fprintf('\n');

        end
    end
end


%% ============================================================
% Advantage criterion
%
% Section 4.1: at Stressed, Causal-AoI must beat P10 on RMSE OR beat
% P20 on communication cost, in at least 80 % of connected conditions.
% ============================================================

fprintf('============================================================\n');
fprintf('Advantage at Stressed, per connected condition\n');
fprintf('============================================================\n\n');

fprintf('%-10s %4s %12s %12s %12s %12s %10s\n', ...
    'Topology','N','RMSE causal','RMSE P10','cost causal','cost P20','advantage');

advantage = false(nTopo,nSize);
counted   = false(nTopo,nSize);

for iN = 1:nSize
    for iT = 1:nTopo

        if ~CONNECTED(iT,iN); continue; end

        counted(iT,iN) = true;

        rc = meanRMSE(IDX_CAUSAL,iT,iN,IDX_STRESSED);
        r1 = meanRMSE(IDX_P10,   iT,iN,IDX_STRESSED);

        cc = costTotal(IDX_CAUSAL,iT,iN,IDX_STRESSED);
        c2 = costTotal(IDX_P20,   iT,iN,IDX_STRESSED);

        betterRMSE = rc < r1;
        cheaper    = cc < c2;

        advantage(iT,iN) = betterRMSE || cheaper;

        if betterRMSE && cheaper
            tag = 'both';
        elseif betterRMSE
            tag = 'RMSE';
        elseif cheaper
            tag = 'cost';
        else
            tag = 'NEITHER';
        end

        fprintf('%-10s %4d %12.4f %12.4f %12.2f %12.2f %10s\n', ...
            topologyNames{iT}, swarmSizes(iN), rc, r1, cc, c2, tag);

    end
end

nCounted   = nnz(counted);
nAdvantage = nnz(advantage & counted);

advantageRate = nAdvantage / max(nCounted,1);

fprintf('\n  Advantage in %d of %d connected conditions (%.1f %%)\n', ...
    nAdvantage, nCounted, 100*advantageRate);


%% ============================================================
% No single topology may carry the conclusion
%
% Section 4.1: dropping any ONE topology must still leave >= 80 %.
% Without this a result could rest entirely on the ring it was
% developed on.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Leave-one-topology-out\n');
fprintf('============================================================\n\n');

looRate = zeros(nTopo,1);

for iT = 1:nTopo

    keep = true(nTopo,1);
    keep(iT) = false;

    c = counted(keep,:);
    a = advantage(keep,:) & c;

    looRate(iT) = nnz(a) / max(nnz(c),1);

    fprintf('  drop %-10s -> %d of %d (%.1f %%)\n', ...
        topologyNames{iT}, nnz(a), nnz(c), 100*looRate(iT));

end

worstLoo = min(looRate);


%% ============================================================
% Safety where P20 is also safe
% ============================================================

safeComparable = 0;
safeViolations = 0;

for iS = 1:nScenario
    for iN = 1:nSize
        for iT = 1:nTopo

            if ~CONNECTED(iT,iN); continue; end

            if safeFailRate(IDX_P20,iT,iN,iS) <= 0.05
                safeComparable = safeComparable + 1;
                if safeFailRate(IDX_CAUSAL,iT,iN,iS) > 0.05
                    safeViolations = safeViolations + 1;
                end
            end

        end
    end
end


%% ============================================================
% Acceptance gates
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP08A acceptance gates\n');
fprintf('============================================================\n\n');

gateNames  = {};
gateValues = {};
gatePass   = [];

gateNames{end+1}  = 'Pre-check: all graphs connected';
gatePass(end+1)   = all(CONNECTED(:));
gateValues{end+1} = sprintf('%d of %d connected', nnz(CONNECTED), numel(CONNECTED));

gateNames{end+1}  = 'Causality invariants = 0';
gatePass(end+1)   = (sum(VIOL(:)) == 0);
gateValues{end+1} = sprintf('%d violation(s)', sum(VIOL(:)));

gateNames{end+1}  = 'SafeFail <= 5% where P20 is also safe';
gatePass(end+1)   = (safeViolations == 0);
gateValues{end+1} = sprintf('%d of %d comparable conditions breached', ...
    safeViolations, safeComparable);

gateNames{end+1}  = 'Stressed advantage in >= 80% of conditions';
gatePass(end+1)   = (advantageRate >= 0.80);
gateValues{end+1} = sprintf('%.1f %% (%d of %d)', ...
    100*advantageRate, nAdvantage, nCounted);

gateNames{end+1}  = 'No single topology carries it (leave-one-out >= 80%)';
gatePass(end+1)   = (worstLoo >= 0.80);
gateValues{end+1} = sprintf('worst %.1f %%', 100*worstLoo);

for q = 1:numel(gateNames)
    if gatePass(q); v = 'PASS'; else; v = 'FAIL'; end
    fprintf('  [%s] %-52s %s\n', v, gateNames{q}, gateValues{q});
end

nFailed = sum(~gatePass);

fprintf('\n');
if nFailed == 0
    fprintf('  EXP08A GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP08A GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Figures
% ============================================================

figure('Name','EXP08A RMSE by topology, Stressed');
bar(squeeze(meanRMSE(:,:,end,IDX_STRESSED))');
grid on;
set(gca,'XTickLabel',topologyNames);
ylabel('Formation RMSE [m]');
title(sprintf('Stressed, N = %d', swarmSizes(end)));
legend(methodNames,'Location','northwest');

figure('Name','EXP08A cost by topology, Stressed');
bar(squeeze(costTotal(:,:,end,IDX_STRESSED))');
grid on;
set(gca,'XTickLabel',topologyNames);
ylabel('Cost [units/s], packet-w 0.25');
title(sprintf('Stressed, N = %d', swarmSizes(end)));
legend(methodNames,'Location','northwest');

figure('Name','EXP08A connectivity');
bar(LAMBDA2');
grid on;
set(gca,'XTickLabel',arrayfun(@(n) sprintf('N=%d',n), swarmSizes, ...
    'UniformOutput', false));
ylabel('Algebraic connectivity \lambda_2');
title('Graph connectivity by topology and size');
legend(topologyNames,'Location','northeast');


%% ============================================================
% Long-format results table
% ============================================================

T = tidyFromArray( ...
    struct( ...
        'RMSE',     RMSE, ...
        'AOI',      AOI, ...
        'MINEVAL',  MINEVAL, ...
        'NDATA',    NDATA, ...
        'NACK',     NACK, ...
        'MISSION',  MISSION, ...
        'VIOL',     VIOL, ...
        'FORMFAIL', double(FORMFAIL), ...
        'SAFEFAIL', double(SAFEFAIL)), ...
    {'seed','method','topology','N','scenario'}, ...
    {1:numSeeds, methodNames, topologyNames, swarmSizes, scenarioNames});

% Attach the structural properties of each condition.
topoIdx = zeros(height(T),1);
sizeIdx = zeros(height(T),1);

for r = 1:height(T)
    topoIdx(r) = find(strcmp(topologyNames, T.topology{r}));
    sizeIdx(r) = find(swarmSizes == T.N(r));
end

lin = sub2ind([nTopo nSize], topoIdx, sizeIdx);

T.numEdges   = NUMEDGES(lin);
T.meanDegree = MEANDEG(lin);
T.minDegree  = MINDEG(lin);
T.lambda2    = LAMBDA2(lin);
T.nChannels  = NCHANNELS(lin);

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));


fprintf('\nEXP08A completed.\n');


%% ============================================================
% Persist results
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);
