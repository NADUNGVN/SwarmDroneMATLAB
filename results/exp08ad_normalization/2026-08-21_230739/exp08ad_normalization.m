%% EXP08A-D - Degree normalization diagnostic
%
% EXP08A (locked partial, tag exp08a-locked-partial) failed its safety
% generalization gate at Stressed / sparse6 / N=20, systematically: 0 of 20
% seeds cleared the 0.25 m threshold.
%
% The evidence pointing at the controller is a monotone correlation: under
% P10, whose communication is identical on every topology, RMSE rises with
% degree. A correlation is not causation, and the pre-registration therefore
% requires the failure to be described as "consistent with degree-dependent
% unnormalized consensus gain" rather than as proven.
%
% This diagnostic turns the correlation into an intervention. The neighbour
% consensus position and velocity sums are scaled by 2/d_i, where d_i is the
% follower's consensus in-degree. The factor is exactly 1 at d_i = 2, the
% degree Kp and Kv were tuned on, so ring behaviour is unchanged. Leader
% pinning is deliberately untouched.
%
% THIS IS A DIAGNOSTIC, NOT A GATED EXPERIMENT. It produces no new claim and
% cannot retroactively alter any EXP08A gate. Causal-AoI-v3 is unmodified;
% both controllers are retained.
%
% Two questions:
%
%   1. Does P10's degree trend disappear under normalization? If it does,
%      degree gain was the mechanism. If it survives, it was not.
%   2. Does the Stressed / sparse6 / N=20 safety failure clear?
%
% ============================================================

startup;

close all;


%% ============================================================
% Result persistence
% ============================================================

expRun = startExperiment('exp08ad_normalization');


%% ============================================================
% Scope: diagnostic only
% ============================================================

numSeeds = 3;


swarmSizes = [10 20 50];

nSize = numel(swarmSizes);

topologyNames = {'ring2'; 'sparse4'; 'sparse6'; 'geometric'};

nTopo = numel(topologyNames);

scenarioNames = {'Moderate'; 'Stressed'};

scenarioLoss  = [0.20; 0.40];
scenarioDelay = [0.08; 0.12];

nScenario = numel(scenarioNames);

IDX_STRESSED = 2;


% P10 isolates the controller: its communication is identical on every
% topology, so any change is the graph acting through the control law.
% Causal-v3 is included to confirm the intervention carries over to the
% method under study.
methodNames = {'P10'; 'Causal-v3'};

nMethod = numel(methodNames);

IDX_P10    = 1;
IDX_CAUSAL = 2;


controllerNames = {'original'; 'normalized'};

nCtrl = numel(controllerNames);

IDX_ORIG = 1;
IDX_NORM = 2;


%% ============================================================
% Locked policy parameters, unchanged
% ============================================================

epsP         = 0.05;
epsV         = 0.10;
aoiThreshold = 0.12;
aoiCooldown  = 0.10;
maxSilence   = 0.50;

safetyThreshold = 0.25;


%% ============================================================
% Structure, reported with consensus in-degree kept SEPARATE
%
% The structural figure symmetrises the graph and folds in leader-pin
% edges. The controller sees neither. What multiplies its gain is the
% consensus in-degree, and that is the quantity the 2/d_i factor uses.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP08A-D degree normalization diagnostic\n');
fprintf('============================================================\n\n');

fprintf('%-10s %4s | %9s %9s | %9s %5s %5s\n', ...
    'topology','N','structDeg','lambda2','consMean','min','max');

CONSMEAN = zeros(nTopo,nSize);
CONSMIN  = zeros(nTopo,nSize);
CONSMAX  = zeros(nTopo,nSize);
STRUCTDEG = zeros(nTopo,nSize);
LAMBDA2  = zeros(nTopo,nSize);

for iT = 1:nTopo
    for iN = 1:nSize

        cfgT = applyTopologyConfig(defaultConfig(), swarmSizes(iN), topologyNames{iT});
        g = graphConnectivity(cfgT.swarm.A, cfgT.swarm.pin);

        STRUCTDEG(iT,iN) = g.meanDegree;
        LAMBDA2(iT,iN)   = g.lambda2;
        CONSMEAN(iT,iN)  = g.consensusInDegreeMean;
        CONSMIN(iT,iN)   = g.consensusInDegreeMin;
        CONSMAX(iT,iN)   = g.consensusInDegreeMax;

        fprintf('%-10s %4d | %9.2f %9.4f | %9.2f %5d %5d\n', ...
            topologyNames{iT}, swarmSizes(iN), ...
            g.meanDegree, g.lambda2, ...
            g.consensusInDegreeMean, g.consensusInDegreeMin, g.consensusInDegreeMax);

    end
end


%% ============================================================
% Storage
% ============================================================

sz = [numSeeds nCtrl nMethod nTopo nSize nScenario];

RMSE    = zeros(sz);
MINEVAL = zeros(sz);
NDATA   = zeros(sz);
MISSION = zeros(sz);
SAFEFAIL = false(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\nSeeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n--- %s ---\n', scenarioNames{iS});

    for iN = 1:nSize
        for iT = 1:nTopo

            fprintf('  N=%-3d %-10s', swarmSizes(iN), topologyNames{iT});

            for iC = 1:nCtrl
                for iM = 1:nMethod

                    rmseS  = zeros(numSeeds,1);
                    minevS = zeros(numSeeds,1);
                    ndataS = zeros(numSeeds,1);
                    misS   = zeros(numSeeds,1);

                    parfor s = 1:numSeeds

                        cfg = applyTopologyConfig(defaultConfig(), ...
                            swarmSizes(iN), topologyNames{iT});

                        % The intervention. Everything else is untouched.
                        cfg.swarm.normalizeConsensusDegree = (iC == IDX_NORM);

                        cfg.net.packetLoss = scenarioLoss(iS);
                        cfg.net.delay      = scenarioDelay(iS);
                        cfg.net.jitterStd  = 0;

                        % Same seed family as EXP08A, so the original arm
                        % doubles as a regression on that locked run.
                        cfg.net.seed = 1700000 + 100000*iS + 10000*iN + 1000*iT + s;

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

                        cfg.ack.loss      = 0.0;
                        cfg.ack.delay     = scenarioDelay(iS);
                        cfg.ack.jitterStd = 0;
                        cfg.ack.useTrace  = true;

                        cfg.causal.useAdaptiveScale   = true;
                        cfg.causal.useAckFeedback     = true;
                        cfg.causal.innovationPriority = true;

                        if iM == IDX_P10
                            cfg.net.commPeriod = 0.10;
                            out = simSwarmNetworkQueued(cfg);
                        else
                            out = simSwarmAoICausal(cfg);
                        end

                        M = computeSwarmMetrics(out, cfg);

                        rmseS(s)  = M.formationRMSE;
                        minevS(s) = M.minSeparationEval;
                        ndataS(s) = out.txCount;
                        misS(s)   = out.t(end) - out.t(1);

                    end

                    RMSE(:,iC,iM,iT,iN,iS)    = rmseS;
                    MINEVAL(:,iC,iM,iT,iN,iS) = minevS;
                    NDATA(:,iC,iM,iT,iN,iS)   = ndataS;
                    MISSION(:,iC,iM,iT,iN,iS) = misS;

                    SAFEFAIL(:,iC,iM,iT,iN,iS) = minevS < safetyThreshold;

                end
            end

            fprintf('  done\n');

        end
    end

end


meanRMSE = squeeze(mean(RMSE,1));
meanMIN  = squeeze(mean(MINEVAL,1));
safeRate = squeeze(mean(SAFEFAIL,1));
rateData = squeeze(mean(NDATA,1)) ./ squeeze(mean(MISSION,1));


%% ============================================================
% Regression: the original arm must reproduce EXP08A
%
% Same seeds, flag off. If these move, the flag is not additive and
% nothing below can be trusted.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Regression against EXP08A (original controller, flag off)\n');
fprintf('============================================================\n\n');

% Published EXP08A values at Stressed / sparse6 / N=20.
expP10  = 0.4317;
expCaus = 0.3541;

gotP10  = meanRMSE(IDX_ORIG,IDX_P10,   3,2,IDX_STRESSED);
gotCaus = meanRMSE(IDX_ORIG,IDX_CAUSAL,3,2,IDX_STRESSED);

fprintf('  P10       expected %.4f  got %.4f  |d| %.2e\n', ...
    expP10, gotP10, abs(expP10-gotP10));
fprintf('  Causal-v3 expected %.4f  got %.4f  |d| %.2e\n', ...
    expCaus, gotCaus, abs(expCaus-gotCaus));

if abs(expP10-gotP10) < 5e-4 && abs(expCaus-gotCaus) < 5e-4
    fprintf('\n  Flag is additive: EXP08A reproduces with it off.\n');
else
    fprintf('\n  *** EXP08A DID NOT REPRODUCE. Nothing below is trustworthy. ***\n');
end


%% ============================================================
% Question 1: does the degree trend survive normalization?
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('P10 RMSE against consensus in-degree\n');
fprintf('============================================================\n\n');

fprintf('%-10s %4s %10s | %10s %10s %10s\n', ...
    'topology','N','consDeg','original','normalized','change');

for iS = 1:nScenario

    fprintf('\n%s\n', scenarioNames{iS});

    for iN = 1:nSize
        for iT = 1:nTopo

            a = meanRMSE(IDX_ORIG,IDX_P10,iT,iN,iS);
            b = meanRMSE(IDX_NORM,IDX_P10,iT,iN,iS);

            fprintf('%-10s %4d %10.2f | %10.4f %10.4f %9.1f%%\n', ...
                topologyNames{iT}, swarmSizes(iN), CONSMEAN(iT,iN), ...
                a, b, 100*(b-a)/a);

        end
    end

end


%% ============================================================
% Question 2: does the failing condition clear?
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Stressed / sparse6 / N=20, the condition EXP08A failed\n');
fprintf('============================================================\n\n');

fprintf('%-12s %-12s %10s %10s %10s\n', ...
    'controller','method','RMSE','minSep','SafeFail');

for iC = 1:nCtrl
    for iM = 1:nMethod
        fprintf('%-12s %-12s %10.4f %10.4f %10.2f\n', ...
            controllerNames{iC}, methodNames{iM}, ...
            meanRMSE(iC,iM,3,2,IDX_STRESSED), ...
            meanMIN(iC,iM,3,2,IDX_STRESSED), ...
            safeRate(iC,iM,3,2,IDX_STRESSED));
    end
end

fprintf('\n  Safety threshold %.2f m\n', safetyThreshold);


%% ============================================================
% Safety across every condition
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Conditions with SafeFail > 5%%\n');
fprintf('============================================================\n\n');

for iC = 1:nCtrl

    n = 0;

    for iS = 1:nScenario
        for iN = 1:nSize
            for iT = 1:nTopo
                for iM = 1:nMethod
                    if safeRate(iC,iM,iT,iN,iS) > 0.05
                        n = n + 1;
                        fprintf('  %-11s %-10s %-10s N=%-3d %-12s minSep %.4f\n', ...
                            controllerNames{iC}, scenarioNames{iS}, ...
                            topologyNames{iT}, swarmSizes(iN), methodNames{iM}, ...
                            meanMIN(iC,iM,iT,iN,iS));
                    end
                end
            end
        end
    end

    fprintf('  %s: %d condition(s) breaching\n\n', controllerNames{iC}, n);

end


%% ============================================================
% Figure
% ============================================================

figure('Name','EXP08A-D P10 RMSE versus consensus in-degree, Stressed');
hold on; grid on;
for iC = 1:nCtrl
    x = []; y = [];
    for iN = 1:nSize
        for iT = 1:nTopo
            x(end+1) = CONSMEAN(iT,iN); %#ok<SAGROW>
            y(end+1) = meanRMSE(iC,IDX_P10,iT,iN,IDX_STRESSED); %#ok<SAGROW>
        end
    end
    [x,o] = sort(x); y = y(o);
    plot(x, y, '-o', 'LineWidth', 1.3, 'MarkerSize', 7);
end
xlabel('Consensus in-degree');
ylabel('P10 formation RMSE [m]');
title('Stressed: does the degree trend survive normalization?');
legend(controllerNames,'Location','northwest');
hold off;


%% ============================================================
% Long-format table
% ============================================================

T = tidyFromArray( ...
    struct( ...
        'RMSE',     RMSE, ...
        'MINEVAL',  MINEVAL, ...
        'NDATA',    NDATA, ...
        'MISSION',  MISSION, ...
        'SAFEFAIL', double(SAFEFAIL)), ...
    {'seed','controller','method','topology','N','scenario'}, ...
    {1:numSeeds, controllerNames, methodNames, topologyNames, swarmSizes, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP08A-D completed. Diagnostic only; no gate, no new claim.\n');


%% ============================================================
% Persist
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);
