%% EXP06A - Swarm-size scalability
%
% Compare:
%
%   M0 Periodic 10 Hz
%   M1 Conventional event trigger
%   M2 Full ACK-assisted AoI-aware trigger
%
%
% Swarm sizes:
%
%   N = 5, 10, 20, 50
%
%
% Fixed representative network:
%
%   packet loss = 20 %
%   delay       = 80 ms
%   jitter      = 0
%
%
% Full AoI-aware policy is LOCKED:
%
%   epsP          = 0.05 m
%   epsV          = 0.10 m/s
%   AoI threshold = 0.12 s
%   AoI cooldown  = 0.10 s
%   max silence   = 0.50 s
%
%
% EXP06A changes ONLY swarm size / topology dimensions.
%
% ============================================================

startup;

close all;

%% ============================================================
% Result persistence
%
% Creates results/exp06a_scalability/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

expRun = startExperiment('exp06a_scalability');




%% ============================================================
% Debug first
%
% Final after validation:
%
%   numSeeds = 20;
% ============================================================

numSeeds = 20;


%% ============================================================
% Swarm sizes
% ============================================================

swarmSizes = [
    5
    10
    20
    50
];


nSize = ...
    numel(swarmSizes);


%% ============================================================
% Methods
% ============================================================

methodNames = {
    'Periodic10'
    'Periodic20'
    'State-event'
    'Full-AoI'
};

nMethod = numel(methodNames);


%% ============================================================
% Network
%
% Representative Moderate condition from EXP05.
% ============================================================

scenarioNames = {
    'Moderate'
    'Stressed'
};

scenarioLoss = [
    0.20
    0.40
];

scenarioDelay = [
    0.08
    0.12
];

nScenario = numel(scenarioLoss);

jitterStd = 0;


%% ============================================================
% Locked policy
% ============================================================

epsP = ...
    0.05;


epsV = ...
    0.10;


aoiThreshold = ...
    0.12;


aoiCooldown = ...
    0.10;


maxSilence = ...
    0.50;


%% ============================================================
% Evaluation thresholds
% ============================================================

formationThreshold = ...
    0.10;


safetyThreshold = ...
    0.25;


%% ============================================================
% Storage
%
% Dimensions:
%
%   seed x method x swarm-size
% ============================================================

RMSE = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

MAXERR = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

MINEVAL = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

AOI = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

TXRATECHANNEL = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

TXRATEAGENT = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

TXRATETOTAL = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

TXCOUNT = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

PDR = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

FORMFAIL = ...
    false(numSeeds,nMethod,nSize,nScenario);

SAFEFAIL = ...
    false(numSeeds,nMethod,nSize,nScenario);


%% ------------------------------------------------------------
% ACK-feedback diagnostics
%
% Only the full AoI-aware method maintains accepted-state memory.
% ackSyncMissCount counts occasions where the transmitter could not
% match an acceptance to a pending attempt; it should be 0. It is
% recorded here because nothing previously inspected it.
% ------------------------------------------------------------

ACKMISS = ...
    zeros(numSeeds,nMethod,nSize,nScenario);

ACKUPDATE = ...
    zeros(numSeeds,nMethod,nSize,nScenario);


CHANNELCOUNT = ...
    zeros(nSize,1);


%% ============================================================
% Header
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP06A swarm-size scalability\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Seeds          : %d\n', ...
    numSeeds);


fprintf('Network scenarios:\n');

for iS = 1:nScenario

    fprintf( ...
        '  %-10s : loss %.0f %% | delay %.0f ms\n', ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), ...
        1000*scenarioDelay(iS));

end

fprintf('\n');


fprintf( ...
    'epsP           : %.3f m\n', ...
    epsP);


fprintf( ...
    'epsV           : %.3f m/s\n', ...
    epsV);


fprintf( ...
    'AoI threshold  : %.3f s\n', ...
    aoiThreshold);


fprintf( ...
    'AoI cooldown   : %.3f s\n\n', ...
    aoiCooldown);


%% ============================================================
% Experiment
% ============================================================

ensureParallelPool(numSeeds);


for iS = 1:nScenario


    fprintf( ...
        '\n============================================================\n');

    fprintf( ...
        '%s network | loss %.0f %% | delay %.0f ms\n', ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), ...
        1000*scenarioDelay(iS));

    fprintf( ...
        '============================================================\n');


    %% ========================================================
    % Swarm-size loop
    % =========================================================

    for iN = 1:nSize


        N = ...
            swarmSizes(iN);


        %% ----------------------------------------------------
        % Determine channel count
        % -----------------------------------------------------

        cfgSize = ...
            defaultConfig();


        cfgSize = ...
            applyScalableSwarmConfig( ...
            cfgSize, ...
            N);


        nChannels = ...
            nnz(cfgSize.swarm.A) ...
            + sum(cfgSize.swarm.pin);


        CHANNELCOUNT(iN) = ...
            nChannels;


        fprintf( ...
            '------------------------------------------------------------\n');

        fprintf( ...
            'N = %d | channels = %d\n', ...
            N, ...
            nChannels);

        fprintf( ...
            '------------------------------------------------------------\n');


        %% ====================================================
        % Method loop
        % =====================================================

        for iM = 1:nMethod


            fprintf( ...
                '  %s\n', ...
                methodNames{iM});


            %% =================================================
            % Monte-Carlo seeds
            % ==================================================

            % Sliced accumulators. parfor cannot slice a 4-D array,
            % so each seed writes into a vector that is copied back
            % into the result arrays after the loop.
            rmseS     = zeros(numSeeds,1);
            maxerrS   = zeros(numSeeds,1);
            minevalS  = zeros(numSeeds,1);
            aoiS      = zeros(numSeeds,1);
            txcountS  = zeros(numSeeds,1);
            txtotalS  = zeros(numSeeds,1);
            pdrS      = zeros(numSeeds,1);
            ackmS     = zeros(numSeeds,1);
            ackuS     = zeros(numSeeds,1);


            parfor s = 1:numSeeds


                %% =============================================
                % Common configuration
                % ==============================================

                cfg = ...
                    defaultConfig();


                cfg = ...
                    applyScalableSwarmConfig( ...
                    cfg, ...
                    N);


                %% --------------------------------------------
                % Network scenario
                % ---------------------------------------------

                cfg.net.packetLoss = ...
                    scenarioLoss(iS);


                cfg.net.delay = ...
                    scenarioDelay(iS);


                cfg.net.jitterStd = ...
                    jitterStd;


                %% --------------------------------------------
                % Reproducible seed
                %
                % Same seed for all methods within the same
                % scenario / swarm size / Monte-Carlo run.
                % ---------------------------------------------

                cfg.net.seed = ...
                    1100000 ...
                    + 100000*iS ...
                    + 10000*iN ...
                    + s;


                %% --------------------------------------------
                % Conventional event-trigger parameters
                % ---------------------------------------------

                cfg.event.posThreshold = ...
                    epsP;


                cfg.event.velThreshold = ...
                    epsV;


                cfg.event.maxSilence = ...
                    maxSilence;


                %% --------------------------------------------
                % Full AoI-aware LOCKED parameters
                % ---------------------------------------------

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


                %% =============================================
                % Method
                % ==============================================

                switch iM


                    %% ----------------------------------------
                    % M0 - Periodic 10 Hz
                    % -----------------------------------------

                    case 1

                        cfg.net.commPeriod = ...
                            0.10;


                        out = ...
                            simSwarmNetworkQueued(cfg);


                    %% ----------------------------------------
                    % M1 - Periodic 20 Hz
                    % -----------------------------------------

                    case 2

                        cfg.net.commPeriod = ...
                            0.05;


                        out = ...
                            simSwarmNetworkQueued(cfg);


                    %% ----------------------------------------
                    % M2 - Conventional state-event
                    % -----------------------------------------

                    case 3

                        out = ...
                            simSwarmEventTriggered(cfg);


                    %% ----------------------------------------
                    % M3 - Full AoI-aware LOCKED method
                    % -----------------------------------------

                    case 4

                        out = ...
                            simSwarmAoIAware(cfg);

                end


                %% =============================================
                % Swarm metrics
                % ==============================================

                M = ...
                    computeSwarmMetrics( ...
                    out, ...
                    cfg);


                idxEval = ...
                    out.t >= 8;


                %% --------------------------------------------
                % Formation performance
                % ---------------------------------------------

                rmseS(s) = ...
                    M.formationRMSE;


                maxerrS(s) = ...
                    M.maxFormationError;


                minevalS(s) = ...
                    M.minSeparationEval;


                %% --------------------------------------------
                % AoI
                % ---------------------------------------------

                aoiS(s) = ...
                    mean( ...
                    out.meanAoI(idxEval));


                %% --------------------------------------------
                % Communication metrics
                % ---------------------------------------------

                missionTime = ...
                    out.t(end) ...
                    - out.t(1);


                txcountS(s) = ...
                    out.txCount;


                txtotalS(s) = ...
                    out.txCount ...
                    / max(missionTime,eps);


                pdrS(s) = ...
                    out.PDR;


                if isfield(out,'ackSyncMissCount')

                    ackmS(s) = ...
                        out.ackSyncMissCount;

                    ackuS(s) = ...
                        out.ackUpdateCount;

                end


                %% --------------------------------------------
                % Failure metrics
                % ---------------------------------------------

            end
            % End seed loop


            %% =================================================
            % Copy the sliced results back
            % ==================================================

            RMSE(:,iM,iN,iS)    = rmseS;
            MAXERR(:,iM,iN,iS)  = maxerrS;
            MINEVAL(:,iM,iN,iS) = minevalS;
            AOI(:,iM,iN,iS)     = aoiS;

            TXCOUNT(:,iM,iN,iS)       = txcountS;
            TXRATETOTAL(:,iM,iN,iS)   = txtotalS;
            TXRATECHANNEL(:,iM,iN,iS) = txtotalS / nChannels;
            TXRATEAGENT(:,iM,iN,iS)   = txtotalS / N;

            PDR(:,iM,iN,iS) = pdrS;

            ACKMISS(:,iM,iN,iS)   = ackmS;
            ACKUPDATE(:,iM,iN,iS) = ackuS;

            FORMFAIL(:,iM,iN,iS) = rmseS    > formationThreshold;
            SAFEFAIL(:,iM,iN,iS) = minevalS < safetyThreshold;


        end
        % End method loop


    end
    % End swarm-size loop


end
% End network-scenario loop


%% ============================================================
% Aggregate
%
% Preserve dimensions:
%
%   method x swarm-size
% ============================================================

meanRMSE = ...
    reshape(mean(RMSE,1), ...
    nMethod,nSize,nScenario);

stdRMSE = ...
    reshape(std(RMSE,0,1), ...
    nMethod,nSize,nScenario);

meanMAXERR = ...
    reshape(mean(MAXERR,1), ...
    nMethod,nSize,nScenario);

meanMINEVAL = ...
    reshape(mean(MINEVAL,1), ...
    nMethod,nSize,nScenario);

meanAOI = ...
    reshape(mean(AOI,1), ...
    nMethod,nSize,nScenario);

meanTXCHANNEL = ...
    reshape(mean(TXRATECHANNEL,1), ...
    nMethod,nSize,nScenario);

meanTXAGENT = ...
    reshape(mean(TXRATEAGENT,1), ...
    nMethod,nSize,nScenario);

meanTXTOTAL = ...
    reshape(mean(TXRATETOTAL,1), ...
    nMethod,nSize,nScenario);

meanTXCOUNT = ...
    reshape(mean(TXCOUNT,1), ...
    nMethod,nSize,nScenario);

meanPDR = ...
    reshape(mean(PDR,1), ...
    nMethod,nSize,nScenario);

formFailRate = ...
    reshape(mean(FORMFAIL,1), ...
    nMethod,nSize,nScenario);

safeFailRate = ...
    reshape(mean(SAFEFAIL,1), ...
    nMethod,nSize,nScenario);


%% ============================================================
% Main results
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP06A scalability results\n');

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'N   Channels Method       RMSE[m] StdRMSE MaxErr ', ...
    'MinEval AoI[s] Tx/ch Tx/agent TxTotal PDR FormFail SafeFail\n']);


fprintf([ ...
    '--- -------- ------------ ------- ------- ------ ', ...
    '------- ------ ----- -------- ------- --- -------- --------\n']);


for iS = 1:nScenario

    fprintf('\n%s network\n', ...
        scenarioNames{iS});


    for iN = 1:nSize

        for iM = 1:nMethod

            fprintf( ...
                ['%2d  %5d    %-12s %.4f  %.4f  %.4f  ' ...
                 '%.4f  %.3f  %5.2f   %6.2f  %7.1f %.3f   %.2f     %.2f\n'], ...
                swarmSizes(iN), ...
                CHANNELCOUNT(iN), ...
                methodNames{iM}, ...
                meanRMSE(iM,iN,iS), ...
                stdRMSE(iM,iN,iS), ...
                meanMAXERR(iM,iN,iS), ...
                meanMINEVAL(iM,iN,iS), ...
                meanAOI(iM,iN,iS), ...
                meanTXCHANNEL(iM,iN,iS), ...
                meanTXAGENT(iM,iN,iS), ...
                meanTXTOTAL(iM,iN,iS), ...
                meanPDR(iM,iN,iS), ...
                formFailRate(iM,iN,iS), ...
                safeFailRate(iM,iN,iS));

        end

        fprintf('\n');

    end

end


%% ============================================================
% Full AoI method versus periodic
% ============================================================

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Full AoI-aware scalability comparison\n');

fprintf( ...
    '============================================================\n\n');


for iS = 1:nScenario

    fprintf('%s\n',scenarioNames{iS});


    for iN = 1:nSize

        rmseVs10 = ...
            100 ...
            * ( ...
            meanRMSE(4,iN,iS) ...
            / meanRMSE(1,iN,iS) ...
            - 1);


        rmseVs20 = ...
            100 ...
            * ( ...
            meanRMSE(4,iN,iS) ...
            / meanRMSE(2,iN,iS) ...
            - 1);


        savingVs10 = ...
            100 ...
            * ( ...
            1 ...
            - meanTXCHANNEL(4,iN,iS) ...
            / meanTXCHANNEL(1,iN,iS));


        savingVs20 = ...
            100 ...
            * ( ...
            1 ...
            - meanTXCHANNEL(4,iN,iS) ...
            / meanTXCHANNEL(2,iN,iS));


        fprintf( ...
            ['  N=%2d | RMSE vs10 %+6.1f %% | vs20 %+6.1f %% | ' ...
             'traffic saving vs10 %+6.1f %% | vs20 %+6.1f %%\n'], ...
            swarmSizes(iN), ...
            rmseVs10, ...
            rmseVs20, ...
            savingVs10, ...
            savingVs20);

    end


    fprintf('\n');

end


%% ============================================================
% Growth exponent
%
% Fit:
%
%   total transmission rate ~ N^alpha
%
% alpha near 1 indicates approximately linear communication
% growth with swarm size.
% ============================================================

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Communication scaling exponent\n');

fprintf( ...
    '============================================================\n\n');


for iS = 1:nScenario

    fprintf('%s\n',scenarioNames{iS});


    for iM = 1:nMethod

        coeff = ...
            polyfit( ...
            log(swarmSizes(:)), ...
            log(squeeze(meanTXTOTAL(iM,:,iS))'), ...
            1);


        alpha = ...
            coeff(1);


        fprintf( ...
            '  %-12s alpha = %.3f\n', ...
            methodNames{iM}, ...
            alpha);

    end


    fprintf('\n');

end


%% ============================================================
% FINAL FIGURES
% ============================================================

for iS = 1:nScenario

    %% --------------------------------------------------------
    % Figure 1 - Formation RMSE versus swarm size
    % ---------------------------------------------------------

    figure;

    hold on;
    grid on;

    for iM = 1:nMethod

        plot( ...
            swarmSizes, ...
            squeeze(meanRMSE(iM,:,iS)), ...
            'o-', ...
            'LineWidth',1.3, ...
            'DisplayName',methodNames{iM});

    end

    xlabel('Number of agents N');
    ylabel('Formation RMSE [m]');

    title(sprintf( ...
        'EXP06A Formation Performance - %s Network', ...
        scenarioNames{iS}));

    legend('Location','best');


    %% --------------------------------------------------------
    % Figure 2 - Communication rate per channel
    % ---------------------------------------------------------

    figure;

    hold on;
    grid on;

    for iM = 1:nMethod

        plot( ...
            swarmSizes, ...
            squeeze(meanTXCHANNEL(iM,:,iS)), ...
            'o-', ...
            'LineWidth',1.3, ...
            'DisplayName',methodNames{iM});

    end

    xlabel('Number of agents N');
    ylabel('Transmission rate per channel [Hz]');

    title(sprintf( ...
        'EXP06A Per-channel Communication - %s Network', ...
        scenarioNames{iS}));

    legend('Location','best');


    %% --------------------------------------------------------
    % Figure 3 - Total communication scaling
    % ---------------------------------------------------------

    figure;

    hold on;
    grid on;

    for iM = 1:nMethod

        loglog( ...
            swarmSizes, ...
            squeeze(meanTXTOTAL(iM,:,iS)), ...
            'o-', ...
            'LineWidth',1.3, ...
            'DisplayName',methodNames{iM});

    end

    xlabel('Number of agents N');
    ylabel('Total transmission rate [packets/s]');

    title(sprintf( ...
        'EXP06A Total Communication Scaling - %s Network', ...
        scenarioNames{iS}));

    legend('Location','best');


    %% --------------------------------------------------------
    % Figure 4 - Resource/performance trade-off
    % ---------------------------------------------------------

    figure;

    hold on;
    grid on;

    for iM = 1:nMethod

        plot( ...
            squeeze(meanTXCHANNEL(iM,:,iS)), ...
            squeeze(meanRMSE(iM,:,iS)), ...
            'o-', ...
            'LineWidth',1.3, ...
            'DisplayName',methodNames{iM});

    end

    xlabel('Transmission rate per channel [Hz]');
    ylabel('Formation RMSE [m]');

    title(sprintf( ...
        'EXP06A Resource-Performance Trade-off - %s Network', ...
        scenarioNames{iS}));

    legend('Location','best');

end


fprintf('\nEXP06A completed.\n');


%% ============================================================
% ACK-feedback integrity check
%
% The accepted-state feedback path must never fail to match an
% acceptance to a pending attempt. A non-zero total means the
% transmitter's reference state froze on some link, which would
% inflate that link's trigger rate.
% ============================================================

fprintf('\n');
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
% Long-format results table
%
% One row per (seed, method, swarm size, network scenario).
% ============================================================

T = tidyFromArray( ...
    struct( ...
        'RMSE',          RMSE, ...
        'MAXERR',        MAXERR, ...
        'MINEVAL',       MINEVAL, ...
        'AOI',           AOI, ...
        'TXRATECHANNEL', TXRATECHANNEL, ...
        'TXRATEAGENT',   TXRATEAGENT, ...
        'TXRATETOTAL',   TXRATETOTAL, ...
        'TXCOUNT',       TXCOUNT, ...
        'PDR',           PDR, ...
        'ACKUPDATE',     ACKUPDATE, ...
        'ACKMISS',       ACKMISS, ...
        'FORMFAIL',      double(FORMFAIL), ...
        'SAFEFAIL',      double(SAFEFAIL)), ...
    {'seed','method','N','scenario'}, ...
    {1:numSeeds, methodNames, swarmSizes, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));


%% ============================================================
% Persist results
%
% save() with no variable list stores the ENTIRE script workspace,
% so every sweep axis and result array is preserved without having
% to enumerate names.
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);
