%% EXP05C - Ablation study
%
% A0 Periodic 10 Hz
%
% A1 State-event only
%
% A2 State-event
%    + fixed AoI-state coupling
%
% A3 State-event
%    + adaptive AoI-state coupling
%
% A4 Full method
%    + adaptive AoI-state coupling
%    + accepted-state / ACK-aware feedback
%
%
% IMPORTANT:
%
% A1-A4 use identical core thresholds:
%
%   epsP = 0.05 m
%   epsV = 0.10 m/s
%
% so component contributions are not confounded by different
% state-trigger thresholds.
%
% ============================================================

startup;

close all;

%% ============================================================
% Result persistence
%
% Creates results/exp05c_ablation/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

R = startExperiment('exp05c_ablation');




%% ============================================================
% DEBUG FIRST
% ============================================================

numSeeds = 20;


%% ============================================================
% Thresholds
% ============================================================

formationThreshold = 0.10;

safetyThreshold = 0.25;


%% ============================================================
% Fixed method parameters
% ============================================================

epsP = 0.05;

epsV = 0.10;

aoiThreshold = 0.12;

aoiCooldown = 0.10;

maxSilence = 0.50;


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


nScenario = ...
    numel(scenarioLoss);


%% ============================================================
% Ablation variants
% ============================================================

variantNames = {
    'A0 Periodic10'
    'A1 State-event'
    'A2 AoI-fixed'
    'A3 AoI-adaptive'
    'A4 Full-ACK'
};


nVariant = ...
    numel(variantNames);


%% ============================================================
% Storage
%
% seed x variant x scenario
% ============================================================

RMSE = ...
    zeros(numSeeds,nVariant,nScenario);


MAXERR = ...
    zeros(numSeeds,nVariant,nScenario);


MINEVAL = ...
    zeros(numSeeds,nVariant,nScenario);


AOI = ...
    zeros(numSeeds,nVariant,nScenario);


TXRATE = ...
    zeros(numSeeds,nVariant,nScenario);


PDR = ...
    zeros(numSeeds,nVariant,nScenario);


FORMFAIL = ...
    false(numSeeds,nVariant,nScenario);


SAFEFAIL = ...
    false(numSeeds,nVariant,nScenario);


%% ============================================================
% Number of active communication channels
% ============================================================

cfg0 = defaultConfig();


nChannels = ...
    nnz(cfg0.swarm.A) ...
    + sum(cfg0.swarm.pin);


%% ============================================================
% Header
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP05C component ablation\n');

fprintf( ...
    '============================================================\n\n');


fprintf('Seeds            : %d\n',numSeeds);

fprintf('epsP             : %.3f m\n',epsP);

fprintf('epsV             : %.3f m/s\n',epsV);

fprintf('AoI threshold    : %.3f s\n',aoiThreshold);

fprintf('AoI cooldown     : %.3f s\n',aoiCooldown);

fprintf('Maximum silence  : %.3f s\n\n',maxSilence);


%% ============================================================
% Experiment
% ============================================================

for iS = 1:nScenario


    fprintf( ...
        '------------------------------------------------------------\n');

    fprintf( ...
        '%s | loss %.0f %% | delay %.0f ms\n', ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), ...
        1000*scenarioDelay(iS));

    fprintf( ...
        '------------------------------------------------------------\n');


    for iV = 1:nVariant


        fprintf( ...
            '  %s\n', ...
            variantNames{iV});


        for s = 1:numSeeds


            %% ------------------------------------------------
            % Common configuration
            % -------------------------------------------------

            cfg = defaultConfig();


            cfg.net.packetLoss = ...
                scenarioLoss(iS);


            cfg.net.delay = ...
                scenarioDelay(iS);


            cfg.net.jitterStd = 0;


            % Same initial RNG seed across variants for each
            % scenario / Monte-Carlo realization.
            cfg.net.seed = ...
                900000 ...
                + 10000*iS ...
                + s;


            %% ------------------------------------------------
            % Common event parameters
            % -------------------------------------------------

            cfg.event.posThreshold = ...
                epsP;


            cfg.event.velThreshold = ...
                epsV;


            cfg.event.maxSilence = ...
                maxSilence;


            %% ------------------------------------------------
            % Common AoI parameters
            % -------------------------------------------------

            cfg.aoiEvent.posThreshold = ...
                epsP;


            cfg.aoiEvent.velThreshold = ...
                epsV;


            cfg.aoiEvent.aoiThreshold = ...
                aoiThreshold;


            cfg.aoiEvent.maxSilence = ...
                maxSilence;


            cfg.aoiEvent.minInterTx = ...
                cfg.swarm.dt;


            cfg.aoiEvent.aoiMinInterTx = ...
                aoiCooldown;


            cfg.aoiEvent.aoiStateScaleBase = ...
                0.50;


            cfg.aoiEvent.aoiStateScaleMin = ...
                0.20;


            cfg.aoiEvent.aoiAdaptRange = ...
                1.00;


            %% =================================================
            % VARIANT
            % ==================================================

            switch iV


                %% --------------------------------------------
                % A0 - Periodic 10 Hz
                % ---------------------------------------------

                case 1

                    cfg.net.commPeriod = ...
                        0.10;


                    out = ...
                        simSwarmNetworkQueued(cfg);


                %% --------------------------------------------
                % A1 - State-event only
                % ---------------------------------------------

                case 2

                    out = ...
                        simSwarmEventTriggered(cfg);


                %% --------------------------------------------
                % A2 - Fixed AoI coupling
                %
                % Attempted-state memory
                % ---------------------------------------------

                case 3

                    cfg.ablation.useAdaptiveScale = ...
                        false;


                    out = ...
                        simSwarmAoIAblation(cfg);


                %% --------------------------------------------
                % A3 - Adaptive AoI coupling
                %
                % Attempted-state memory
                % ---------------------------------------------

                case 4

                    cfg.ablation.useAdaptiveScale = ...
                        true;


                    out = ...
                        simSwarmAoIAblation(cfg);


                %% --------------------------------------------
                % A4 - FULL METHOD
                %
                % Adaptive AoI
                % + accepted-state feedback
                % ---------------------------------------------

                case 5

                    out = ...
                        simSwarmAoIAware(cfg);

            end


            %% =================================================
            % Metrics
            % ==================================================

            M = ...
                computeSwarmMetrics( ...
                out, ...
                cfg);


            idxEval = ...
                out.t >= 8;


            RMSE(s,iV,iS) = ...
                M.formationRMSE;


            MAXERR(s,iV,iS) = ...
                M.maxFormationError;


            MINEVAL(s,iV,iS) = ...
                M.minSeparationEval;


            AOI(s,iV,iS) = ...
                mean( ...
                out.meanAoI(idxEval));


            missionTime = ...
                out.t(end) ...
                - out.t(1);


            TXRATE(s,iV,iS) = ...
                out.txCount ...
                / max(missionTime,eps) ...
                / nChannels;


            PDR(s,iV,iS) = ...
                out.PDR;


            FORMFAIL(s,iV,iS) = ...
                M.formationRMSE ...
                > formationThreshold;


            SAFEFAIL(s,iV,iS) = ...
                M.minSeparationEval ...
                < safetyThreshold;

        end

    end

end


%% ============================================================
% Aggregate
%
% Always preserve:
%
%   variant x scenario
% ============================================================

meanRMSE = ...
    reshape( ...
    mean(RMSE,1), ...
    nVariant,nScenario);


stdRMSE = ...
    reshape( ...
    std(RMSE,0,1), ...
    nVariant,nScenario);


meanMAXERR = ...
    reshape( ...
    mean(MAXERR,1), ...
    nVariant,nScenario);


meanMINEVAL = ...
    reshape( ...
    mean(MINEVAL,1), ...
    nVariant,nScenario);


meanAOI = ...
    reshape( ...
    mean(AOI,1), ...
    nVariant,nScenario);


meanTXRATE = ...
    reshape( ...
    mean(TXRATE,1), ...
    nVariant,nScenario);


meanPDR = ...
    reshape( ...
    mean(PDR,1), ...
    nVariant,nScenario);


formFailRate = ...
    reshape( ...
    mean(FORMFAIL,1), ...
    nVariant,nScenario);


safeFailRate = ...
    reshape( ...
    mean(SAFEFAIL,1), ...
    nVariant,nScenario);


%% ============================================================
% Main table
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP05C ablation results\n');

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'Scenario   Variant          RMSE[m] StdRMSE MaxErr ', ...
    'MinEval AoI[s] TxRate PDR FormFail SafeFail\n']);


fprintf([ ...
    '---------- ---------------- ------- ------- ------ ', ...
    '------- ------ ------ --- -------- --------\n']);


for iS = 1:nScenario

    for iV = 1:nVariant

        fprintf( ...
            '%-10s %-16s %.4f  %.4f  %.4f  %.4f  %.3f  %5.2f  %.3f   %.2f     %.2f\n', ...
            scenarioNames{iS}, ...
            variantNames{iV}, ...
            meanRMSE(iV,iS), ...
            stdRMSE(iV,iS), ...
            meanMAXERR(iV,iS), ...
            meanMINEVAL(iV,iS), ...
            meanAOI(iV,iS), ...
            meanTXRATE(iV,iS), ...
            meanPDR(iV,iS), ...
            formFailRate(iV,iS), ...
            safeFailRate(iV,iS));

    end

    fprintf('\n');

end


%% ============================================================
% Incremental component contribution
%
% Positive RMSE reduction = improvement.
% ============================================================

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Incremental component contribution\n');

fprintf( ...
    '============================================================\n\n');


for iS = 1:nScenario


    fprintf('%s\n',scenarioNames{iS});


    %% --------------------------------------------------------
    % A1 -> A2
    % ---------------------------------------------------------

    gainA2 = ...
        100 ...
        * ( ...
        meanRMSE(2,iS) ...
        - meanRMSE(3,iS) ...
        ) ...
        / meanRMSE(2,iS);


    rateA2 = ...
        meanTXRATE(3,iS) ...
        - meanTXRATE(2,iS);


    fprintf( ...
        '  A1 -> A2 | fixed AoI coupling      : RMSE %+6.2f %% | rate %+5.2f Hz\n', ...
        gainA2, ...
        rateA2);


    %% --------------------------------------------------------
    % A2 -> A3
    % ---------------------------------------------------------

    gainA3 = ...
        100 ...
        * ( ...
        meanRMSE(3,iS) ...
        - meanRMSE(4,iS) ...
        ) ...
        / meanRMSE(3,iS);


    rateA3 = ...
        meanTXRATE(4,iS) ...
        - meanTXRATE(3,iS);


    fprintf( ...
        '  A2 -> A3 | adaptive threshold       : RMSE %+6.2f %% | rate %+5.2f Hz\n', ...
        gainA3, ...
        rateA3);


    %% --------------------------------------------------------
    % A3 -> A4
    % ---------------------------------------------------------

    gainA4 = ...
        100 ...
        * ( ...
        meanRMSE(4,iS) ...
        - meanRMSE(5,iS) ...
        ) ...
        / meanRMSE(4,iS);


    rateA4 = ...
        meanTXRATE(5,iS) ...
        - meanTXRATE(4,iS);


    fprintf( ...
        '  A3 -> A4 | accepted-state feedback  : RMSE %+6.2f %% | rate %+5.2f Hz\n', ...
        gainA4, ...
        rateA4);


    fprintf('\n');

end


%% ============================================================
% Figure 1
% RMSE by component
% ============================================================

figure;

bar(meanRMSE');

grid on;


set( ...
    gca, ...
    'XTick', ...
    1:nScenario, ...
    'XTickLabel', ...
    scenarioNames);


ylabel('Formation RMSE [m]');


title( ...
    'EXP05C component ablation - formation performance');


legend( ...
    variantNames, ...
    'Location','best');


yline( ...
    formationThreshold, ...
    '--', ...
    'Formation threshold');


%% ============================================================
% Figure 2
% Communication usage
% ============================================================

figure;

bar(meanTXRATE');

grid on;


set( ...
    gca, ...
    'XTick', ...
    1:nScenario, ...
    'XTickLabel', ...
    scenarioNames);


ylabel( ...
    'Transmission rate per channel [Hz]');


title( ...
    'EXP05C component ablation - communication usage');


legend( ...
    variantNames, ...
    'Location','best');


%% ============================================================
% Figure 3
% Resource-performance points
% ============================================================

figure;

hold on;

grid on;


markers = {
    'o'
    's'
    'd'
    '^'
    'v'
};


for iV = 1:nVariant

    plot( ...
        meanTXRATE(iV,:), ...
        meanRMSE(iV,:), ...
        markers{iV}, ...
        'MarkerSize',8, ...
        'LineStyle','-', ...
        'DisplayName', ...
        variantNames{iV});

end


yline( ...
    formationThreshold, ...
    '--', ...
    'Formation threshold');


xlabel( ...
    'Transmission rate per channel [Hz]');


ylabel( ...
    'Formation RMSE [m]');


title( ...
    'EXP05C resource-performance ablation');


legend('Location','best');


fprintf('\nEXP05C completed.\n');


%% ============================================================
% Persist results
%
% save() with no variable list stores the ENTIRE script workspace,
% so every sweep axis and result array is preserved without having
% to enumerate names.
% ============================================================

save(fullfile(R.dir,'workspace.mat'));

saveAllFigures(R);

finishExperiment(R);
