%% EXP05D - Communication-cost / formation-error Pareto frontiers
%
% EXP05B compares three policies at ONE operating point each. That cannot
% answer the obvious reviewer question: if the baseline were retuned, would
% it reach the same point?
%
% This experiment sweeps the operating point of every policy and plots the
% resulting rate-vs-RMSE frontiers on a common axis:
%
%   F0  Periodic          swept over communication rate
%   F1  State-event       swept over epsP (epsV = 2*epsP)
%   F2  Full AoI-aware    swept over epsP (epsV = 2*epsP)
%
% The AoI mechanism parameters stay LOCKED at the values used by EXP05B,
% EXP05C and EXP06A:
%
%   AoI threshold = 0.12 s
%   AoI cooldown  = 0.10 s
%   max silence   = 0.50 s
%   scaleBase / scaleMin / adaptRange = 0.50 / 0.20 / 1.00
%
% The claim worth making is that the AoI-aware frontier lies BELOW the
% other two across the whole range, not that one tuned point beats one
% untuned point.
%
% Seeds are shared by every configuration within a scenario, so the
% comparison is paired.
%
% ============================================================

startup;

close all;


%% ============================================================
% Result persistence
% ============================================================

expRun = startExperiment('exp05d_pareto_frontier');


%% ============================================================
% Monte Carlo
% ============================================================

numSeeds = 20;


%% ============================================================
% Network scenarios
% ============================================================

scenarioNames = {
    'Clean'
    'Moderate'
    'Stressed'
};

scenarioLoss = [
    0.00
    0.20
    0.40
];

scenarioDelay = [
    0.00
    0.08
    0.12
];

nScenario = numel(scenarioNames);


%% ============================================================
% Sweep axes
%
% nPoint must be identical for all three families so the results
% form a rectangular array.
% ============================================================

periodicRates = [ 2  5  8  10  15  20 ];

epsPLevels    = [ 0.010 0.020 0.030 0.050 0.080 0.120 ];

epsVLevels    = 2 * epsPLevels;

nPoint = numel(periodicRates);

assert(numel(epsPLevels) == nPoint, ...
    'All families must sweep the same number of points.');


familyNames = {
    'Periodic'
    'State-event'
    'Full-AoI'
};

nFamily = numel(familyNames);


%% ============================================================
% Locked AoI policy parameters
% ============================================================

aoiThreshold = 0.12;

aoiCooldown  = 0.10;

maxSilence   = 0.50;


%% ============================================================
% Evaluation thresholds
% ============================================================

formationThreshold = 0.10;

safetyThreshold    = 0.25;


%% ============================================================
% Channel count
% ============================================================

cfg0 = defaultConfig();

nChannels = ...
    nnz(cfg0.swarm.A) ...
    + sum(cfg0.swarm.pin);


%% ============================================================
% Storage
%
% Dimensions: seed x family x sweep point x scenario
% ============================================================

RMSE    = zeros(numSeeds,nFamily,nPoint,nScenario);
MAXERR  = zeros(numSeeds,nFamily,nPoint,nScenario);
MINEVAL = zeros(numSeeds,nFamily,nPoint,nScenario);
AOI     = zeros(numSeeds,nFamily,nPoint,nScenario);
TXRATE  = zeros(numSeeds,nFamily,nPoint,nScenario);
TXCOUNT = zeros(numSeeds,nFamily,nPoint,nScenario);
PDR     = zeros(numSeeds,nFamily,nPoint,nScenario);

ACKMISS   = zeros(numSeeds,nFamily,nPoint,nScenario);
ACKUPDATE = zeros(numSeeds,nFamily,nPoint,nScenario);

FORMFAIL = false(numSeeds,nFamily,nPoint,nScenario);
SAFEFAIL = false(numSeeds,nFamily,nPoint,nScenario);


%% ============================================================
% Header
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP05D Pareto frontiers\n');
fprintf('============================================================\n\n');

fprintf('Seeds          : %d\n', numSeeds);
fprintf('Channels       : %d\n', nChannels);
fprintf('Sweep points   : %d per family\n', nPoint);
fprintf('Total sims     : %d\n\n', numSeeds*nFamily*nPoint*nScenario);

fprintf('Periodic rates : %s Hz\n', mat2str(periodicRates));
fprintf('epsP levels    : %s m\n', mat2str(epsPLevels));
fprintf('epsV levels    : %s m/s\n\n', mat2str(epsVLevels));

fprintf('AoI threshold  : %.3f s\n', aoiThreshold);
fprintf('AoI cooldown   : %.3f s\n', aoiCooldown);
fprintf('Max silence    : %.3f s\n', maxSilence);


%% ============================================================
% Experiment
% ============================================================

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('%s | loss %.0f %% | delay %.0f ms\n', ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), ...
        1000*scenarioDelay(iS));
    fprintf('------------------------------------------------------------\n');


    for iF = 1:nFamily

        fprintf('  %-12s', familyNames{iF});


        for iP = 1:nPoint

            % Sliced accumulators: a 4-D array cannot be sliced by parfor.
            rmseS    = zeros(numSeeds,1);
            maxerrS  = zeros(numSeeds,1);
            minevalS = zeros(numSeeds,1);
            aoiS     = zeros(numSeeds,1);
            txrateS  = zeros(numSeeds,1);
            txcountS = zeros(numSeeds,1);
            pdrS     = zeros(numSeeds,1);
            ackmS    = zeros(numSeeds,1);
            ackuS    = zeros(numSeeds,1);


            parfor s = 1:numSeeds

                cfg = defaultConfig();

                cfg.net.packetLoss = scenarioLoss(iS);
                cfg.net.delay      = scenarioDelay(iS);
                cfg.net.jitterStd  = 0;

                % Shared across families and sweep points so the
                % comparison is paired.
                cfg.net.seed = 1200000 + 10000*iS + s;

                % Conventional event trigger
                cfg.event.posThreshold = epsPLevels(iP);
                cfg.event.velThreshold = epsVLevels(iP);
                cfg.event.maxSilence   = maxSilence;

                % AoI-aware trigger
                cfg.aoiEvent.posThreshold      = epsPLevels(iP);
                cfg.aoiEvent.velThreshold      = epsVLevels(iP);
                cfg.aoiEvent.aoiThreshold      = aoiThreshold;
                cfg.aoiEvent.maxSilence        = maxSilence;
                cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
                cfg.aoiEvent.aoiMinInterTx     = aoiCooldown;
                cfg.aoiEvent.aoiStateScaleBase = 0.50;
                cfg.aoiEvent.aoiStateScaleMin  = 0.20;
                cfg.aoiEvent.aoiAdaptRange     = 1.00;

                switch iF

                    case 1
                        cfg.net.commPeriod = 1 / periodicRates(iP);
                        out = simSwarmNetworkQueued(cfg);

                    case 2
                        out = simSwarmEventTriggered(cfg);

                    case 3
                        out = simSwarmAoIAware(cfg);

                end

                M = computeSwarmMetrics(out,cfg);

                idxEval = out.t >= 8;

                rmseS(s)    = M.formationRMSE;
                maxerrS(s)  = M.maxFormationError;
                minevalS(s) = M.minSeparationEval;
                aoiS(s)     = mean(out.meanAoI(idxEval));

                txcountS(s) = out.txCount;
                txrateS(s)  = out.txCount / (out.t(end)-out.t(1)) / nChannels;
                pdrS(s)     = out.PDR;

                if isfield(out,'ackSyncMissCount')
                    ackmS(s) = out.ackSyncMissCount;
                    ackuS(s) = out.ackUpdateCount;
                end

            end


            RMSE(:,iF,iP,iS)    = rmseS;
            MAXERR(:,iF,iP,iS)  = maxerrS;
            MINEVAL(:,iF,iP,iS) = minevalS;
            AOI(:,iF,iP,iS)     = aoiS;
            TXRATE(:,iF,iP,iS)  = txrateS;
            TXCOUNT(:,iF,iP,iS) = txcountS;
            PDR(:,iF,iP,iS)     = pdrS;

            ACKMISS(:,iF,iP,iS)   = ackmS;
            ACKUPDATE(:,iF,iP,iS) = ackuS;

            FORMFAIL(:,iF,iP,iS) = rmseS    > formationThreshold;
            SAFEFAIL(:,iF,iP,iS) = minevalS < safetyThreshold;

            fprintf('.');

        end

        fprintf('\n');

    end

end


%% ============================================================
% Aggregate
%
% family x point x scenario
% ============================================================

meanRMSE    = reshape(mean(RMSE,1),    nFamily,nPoint,nScenario);
stdRMSE     = reshape(std(RMSE,0,1),   nFamily,nPoint,nScenario);
meanTXRATE  = reshape(mean(TXRATE,1),  nFamily,nPoint,nScenario);
meanAOI     = reshape(mean(AOI,1),     nFamily,nPoint,nScenario);
meanMINEVAL = reshape(mean(MINEVAL,1), nFamily,nPoint,nScenario);

formFailRate = reshape(mean(FORMFAIL,1), nFamily,nPoint,nScenario);
safeFailRate = reshape(mean(SAFEFAIL,1), nFamily,nPoint,nScenario);


%% ============================================================
% Results table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Frontier points\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %-9s %8s %8s %8s %8s %8s\n', ...
    'Scenario','Family','Setting','Rate[Hz]','RMSE[m]','Std','AoI[s]','FormFail');

for iS = 1:nScenario

    for iF = 1:nFamily

        for iP = 1:nPoint

            if iF == 1
                setting = sprintf('%g Hz', periodicRates(iP));
            else
                setting = sprintf('%.3f m', epsPLevels(iP));
            end

            fprintf('%-10s %-12s %-9s %8.2f %8.4f %8.4f %8.3f %8.2f\n', ...
                scenarioNames{iS}, ...
                familyNames{iF}, ...
                setting, ...
                meanTXRATE(iF,iP,iS), ...
                meanRMSE(iF,iP,iS), ...
                stdRMSE(iF,iP,iS), ...
                meanAOI(iF,iP,iS), ...
                formFailRate(iF,iP,iS));

        end

        fprintf('\n');

    end

end


%% ============================================================
% Dominance analysis
%
% For each AoI-aware point, interpolate what each baseline family
% achieves at the SAME communication rate. A positive margin means
% the AoI-aware policy is better at equal communication cost.
% ============================================================

fprintf('============================================================\n');
fprintf('Dominance of Full-AoI versus the baseline frontiers\n');
fprintf('============================================================\n\n');

fprintf('Margin = (baseline RMSE at the same rate) - (Full-AoI RMSE)\n');
fprintf('Positive margin => Full-AoI is better at equal cost.\n');
fprintf('NaN => the baseline was never measured at that rate.\n\n');

marginVsPeriodic = nan(nPoint,nScenario);
marginVsEvent    = nan(nPoint,nScenario);

for iS = 1:nScenario

    fprintf('%s\n', scenarioNames{iS});

    fprintf('  %8s %10s %14s %14s\n', ...
        'Rate[Hz]','AoI RMSE','vs Periodic','vs State-event');

    for iP = 1:nPoint

        rate = meanTXRATE(3,iP,iS);

        marginVsPeriodic(iP,iS) = ...
            localInterp(meanTXRATE(1,:,iS), meanRMSE(1,:,iS), rate) ...
            - meanRMSE(3,iP,iS);

        marginVsEvent(iP,iS) = ...
            localInterp(meanTXRATE(2,:,iS), meanRMSE(2,:,iS), rate) ...
            - meanRMSE(3,iP,iS);

        fprintf('  %8.2f %10.4f %+14.4f %+14.4f\n', ...
            rate, ...
            meanRMSE(3,iP,iS), ...
            marginVsPeriodic(iP,iS), ...
            marginVsEvent(iP,iS));

    end

    nWinP = sum(marginVsPeriodic(:,iS) > 0);
    nWinE = sum(marginVsEvent(:,iS)    > 0);
    nCmpP = sum(~isnan(marginVsPeriodic(:,iS)));
    nCmpE = sum(~isnan(marginVsEvent(:,iS)));

    fprintf(['  Full-AoI better at %d/%d comparable points vs Periodic, ' ...
             '%d/%d vs State-event\n\n'], ...
        nWinP, nCmpP, nWinE, nCmpE);

end


%% ============================================================
% ACK feedback integrity
% ============================================================

fprintf('============================================================\n');
fprintf('ACK feedback integrity\n');
fprintf('============================================================\n');
fprintf('  Accepted-state updates : %d\n', sum(ACKUPDATE(:)));
fprintf('  Sync misses            : %d\n', sum(ACKMISS(:)));

if sum(ACKMISS(:)) == 0
    fprintf('  STATUS                 : OK\n');
else
    fprintf('  STATUS                 : *** MISSES DETECTED ***\n');
end


%% ============================================================
% Figures
% ============================================================

markers = {'-o','-s','-^'};

for iS = 1:nScenario

    figure('Name', sprintf('EXP05D Pareto frontier %s', scenarioNames{iS}));

    hold on; grid on;

    for iF = 1:nFamily

        errorbar( ...
            meanTXRATE(iF,:,iS), ...
            meanRMSE(iF,:,iS), ...
            stdRMSE(iF,:,iS), ...
            markers{iF}, ...
            'LineWidth', 1.3, ...
            'MarkerSize', 6);

    end

    yline(formationThreshold, '--', 'Formation threshold');

    xlabel('Communication rate per channel [Hz]');
    ylabel('Formation RMSE [m]');
    title(sprintf('Rate versus formation error - %s', scenarioNames{iS}));
    legend(familyNames, 'Location', 'northeast');

    hold off;

end


figure('Name','EXP05D Full-AoI dominance margin');

hold on; grid on;

for iS = 1:nScenario

    plot(meanTXRATE(3,:,iS), marginVsPeriodic(:,iS), '-o', 'LineWidth', 1.3);

end

yline(0,'k--');

xlabel('Full-AoI communication rate per channel [Hz]');
ylabel('RMSE margin versus periodic at equal rate [m]');
title('Positive means Full-AoI is better than periodic at the same cost');
legend(scenarioNames, 'Location', 'best');

hold off;


%% ============================================================
% Long-format results table
%
% One row per (seed, policy family, sweep point, scenario).
% ============================================================

settingLabels = cell(1,nPoint);

for iP = 1:nPoint
    settingLabels{iP} = sprintf('p%d', iP);
end

T = tidyFromArray( ...
    struct( ...
        'RMSE',      RMSE, ...
        'MAXERR',    MAXERR, ...
        'MINEVAL',   MINEVAL, ...
        'AOI',       AOI, ...
        'TXRATE',    TXRATE, ...
        'TXCOUNT',   TXCOUNT, ...
        'PDR',       PDR, ...
        'ACKUPDATE', ACKUPDATE, ...
        'ACKMISS',   ACKMISS, ...
        'FORMFAIL',  double(FORMFAIL), ...
        'SAFEFAIL',  double(SAFEFAIL)), ...
    {'seed','family','point','scenario'}, ...
    {1:numSeeds, familyNames, settingLabels, scenarioNames});

% Attach the physical setting behind each sweep point.
pointIndex = cellfun(@(p) sscanf(p,'p%d'), T.point);

T.periodicRateHz = reshape(periodicRates(pointIndex), [], 1);
T.epsP           = reshape(epsPLevels(pointIndex),    [], 1);

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));


fprintf('\nEXP05D completed.\n');


%% ============================================================
% Persist results
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTION
%
% Linear interpolation of a frontier at a requested rate. Returns
% NaN outside the measured range, so dominance is only claimed
% where the baseline was actually measured.
% ============================================================

function y = localInterp(xs, ys, x)

xs = xs(:);
ys = ys(:);

[xs, order] = sort(xs);
ys = ys(order);

if isnan(x) || x < xs(1) || x > xs(end)
    y = NaN;
else
    y = interp1(xs, ys, x);
end

end
