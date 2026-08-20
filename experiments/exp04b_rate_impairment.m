%% EXP04B - Communication rate x network impairment
%
% Purpose:
%   Characterize the resource-robustness trade-off of periodic
%   distributed swarm communication.
%
% Sweep dimensions:
%
%   communication rate
%       x packet loss
%       x fixed communication delay
%
% Jitter is disabled in EXP04B.
%
% Main questions:
%
%   1. Is 5 Hz still sufficient when the network is impaired?
%   2. When does 10 Hz become insufficient?
%   3. How much robustness is gained by increasing to 20 Hz?
%   4. What is the minimum communication rate satisfying
%      formation and safety constraints?
%
% Metrics:
%   - Formation RMSE
%   - Maximum formation error
%   - Minimum separation after transient
%   - Packet delivery ratio
%   - Mean AoI
%   - Analytical AoI validation
%   - Transmission rate
%   - Formation failure probability
%   - Safety failure probability
%
% ============================================================

startup;

close all;

%% ============================================================
% Result persistence
%
% Creates results/exp04b_rate_impairment/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

R = startExperiment('exp04b_rate_impairment');




%% ============================================================
% Communication-rate sweep
% ============================================================

commRates = [
     5
    10
    20
];                                  % [Hz]

commPeriods = ...
    1 ./ commRates;                  % [s]

nR = numel(commRates);


%% ============================================================
% Packet-loss sweep
% ============================================================

lossLevels = [
    0.0
    0.2
    0.4
];

nL = numel(lossLevels);


%% ============================================================
% Fixed-delay sweep
% ============================================================

delayLevels = [
    0.00
    0.08
    0.12
];                                  % [s]

nD = numel(delayLevels);


%% ============================================================
% Monte Carlo
%
% Debug:
%   numSeeds = 3
%
% Final:
%   numSeeds = 20
%
% ============================================================

numSeeds = 20;


%% ============================================================
% Performance thresholds
% ============================================================

formationThreshold = 0.10;          % [m]

safetyThreshold = 0.25;             % [m]


% Robust operating point:
%
% maximum allowed probability of failure
%
% With 20 seeds:
%   0.05 means at most approximately one failed run.
%
robustFailureLimit = 0.05;


%% ============================================================
% Result arrays
%
% Dimensions:
%
%   seed x rate x loss x delay
%
% ============================================================

RMSE = zeros( ...
    numSeeds,nR,nL,nD);

MAXERR = zeros( ...
    numSeeds,nR,nL,nD);

MINFULL = zeros( ...
    numSeeds,nR,nL,nD);

MINEVAL = zeros( ...
    numSeeds,nR,nL,nD);

PDR = zeros( ...
    numSeeds,nR,nL,nD);

AOI = zeros( ...
    numSeeds,nR,nL,nD);

ARRIVAL = zeros( ...
    numSeeds,nR,nL,nD);

TXRATE = zeros( ...
    numSeeds,nR,nL,nD);

FORMATIONFAIL = false( ...
    numSeeds,nR,nL,nD);

SAFETYFAIL = false( ...
    numSeeds,nR,nL,nD);


%% ============================================================
% Header
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP04B communication rate x network impairment\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Rates     : 5, 10, 20 Hz\n');

fprintf( ...
    'Loss      : 0, 20, 40 %%\n');

fprintf( ...
    'Delay     : 0, 80, 120 ms\n');

fprintf( ...
    'Jitter    : 0 ms\n');

fprintf( ...
    'Seeds     : %d per condition\n\n', ...
    numSeeds);


%% ============================================================
% Monte Carlo sweep
% ============================================================

for iR = 1:nR

    for iL = 1:nL

        for iD = 1:nD


            rate = ...
                commRates(iR);

            pLoss = ...
                lossLevels(iL);

            delay = ...
                delayLevels(iD);


            fprintf( ...
                'Rate = %2.0f Hz | Loss = %2.0f %% | Delay = %3.0f ms\n', ...
                rate, ...
                100*pLoss, ...
                1000*delay);


            for s = 1:numSeeds


                %% ============================================
                % Configuration
                % =============================================

                cfg = ...
                    defaultConfig();


                cfg.net.commPeriod = ...
                    commPeriods(iR);


                cfg.net.packetLoss = ...
                    pLoss;


                cfg.net.delay = ...
                    delay;


                % EXP04B excludes jitter.
                cfg.net.jitterStd = 0;


                %% ============================================
                % Reproducible seed
                %
                % Separate stream for every:
                %
                %   rate
                %   loss
                %   delay
                %   Monte Carlo run
                %
                % =============================================

                cfg.net.seed = ...
                    300000 ...
                    + 10000*iR ...
                    + 1000*iL ...
                    + 100*iD ...
                    + s;


                %% ============================================
                % Simulation
                % =============================================

                out = ...
                    simSwarmNetworkQueued(cfg);


                %% ============================================
                % Swarm metrics
                % =============================================

                M = ...
                    computeSwarmMetrics( ...
                    out,cfg);


                RMSE(s,iR,iL,iD) = ...
                    M.formationRMSE;


                MAXERR(s,iR,iL,iD) = ...
                    M.maxFormationError;


                MINFULL(s,iR,iL,iD) = ...
                    M.minSeparation;


                MINEVAL(s,iR,iL,iD) = ...
                    M.minSeparationEval;


                %% ============================================
                % Network metrics
                % =============================================

                PDR(s,iR,iL,iD) = ...
                    out.PDR;


                ARRIVAL(s,iR,iL,iD) = ...
                    out.arrivalRatio;


                idxEval = ...
                    out.t >= 8.0;


                AOI(s,iR,iL,iD) = ...
                    mean( ...
                    out.meanAoI(idxEval));


                missionTime = ...
                    out.t(end) ...
                    - out.t(1);


                TXRATE(s,iR,iL,iD) = ...
                    out.txCount ...
                    / max(missionTime,eps);


                %% ============================================
                % Failure events
                % =============================================

                FORMATIONFAIL(s,iR,iL,iD) = ...
                    M.formationRMSE ...
                    > formationThreshold;


                SAFETYFAIL(s,iR,iL,iD) = ...
                    M.minSeparationEval ...
                    < safetyThreshold;


            end

        end

    end

end


%% ============================================================
% Monte Carlo statistics
%
% Result dimensions after squeeze:
%
%   rate x loss x delay
%
% ============================================================

meanRMSE = ...
    squeeze(mean(RMSE,1));

stdRMSE = ...
    squeeze(std(RMSE,0,1));


meanMaxErr = ...
    squeeze(mean(MAXERR,1));


meanMinFull = ...
    squeeze(mean(MINFULL,1));


meanMinEval = ...
    squeeze(mean(MINEVAL,1));


meanPDR = ...
    squeeze(mean(PDR,1));


meanAoI = ...
    squeeze(mean(AOI,1));


meanArrival = ...
    squeeze(mean(ARRIVAL,1));


meanTxRate = ...
    squeeze(mean(TXRATE,1));


formationFailureRate = ...
    squeeze(mean(FORMATIONFAIL,1));


safetyFailureRate = ...
    squeeze(mean(SAFETYFAIL,1));


%% ============================================================
% Analytical AoI
%
% For:
%
%   Bernoulli packet loss p
%   fixed delay d
%   communication period Tc
%
% mean AoI:
%
%                    1 + p
% Delta = d + Tc * ----------
%                  2(1 - p)
%
% ============================================================

AOITheory = ...
    zeros(nR,nL,nD);


for iR = 1:nR

    Tc = ...
        commPeriods(iR);


    for iL = 1:nL

        p = ...
            lossLevels(iL);


        for iD = 1:nD

            d = ...
                delayLevels(iD);


            AOITheory(iR,iL,iD) = ...
                d ...
                + Tc ...
                * (1+p) ...
                / (2*(1-p));

        end

    end

end


%% ============================================================
% AoI validation
% ============================================================

AOIError = ...
    abs(meanAoI - AOITheory);


meanAOIError = ...
    mean(AOIError(:));


maxAOIError = ...
    max(AOIError(:));


%% ============================================================
% PDR theoretical validation
%
% Expected:
%
%   PDR = 1 - packet loss probability
%
% ============================================================

PDRTheory = ...
    zeros(nR,nL,nD);


for iR = 1:nR

    for iL = 1:nL

        for iD = 1:nD

            PDRTheory(iR,iL,iD) = ...
                1 - lossLevels(iL);

        end

    end

end


PDRError = ...
    abs(meanPDR - PDRTheory);


meanPDRError = ...
    mean(PDRError(:));


maxPDRError = ...
    max(PDRError(:));


%% ============================================================
% Communication reduction relative to 50-Hz periodic baseline
%
% This is nominal transmission-rate reduction.
%
%  5 Hz -> 90 %
% 10 Hz -> 80 %
% 20 Hz -> 60 %
%
% ============================================================

referenceRate = 50;


COMM_REDUCTION = ...
    100 * ...
    (1 - commRates/referenceRate);


%% ============================================================
% Print complete results
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP04B mean results over %d Monte Carlo seeds\n', ...
    numSeeds);

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'Rate Loss Delay RMSE[m] StdRMSE MaxErr ', ...
    'MinEval PDR AoI_sim AoI_th ', ...
    'FormFail SafeFail\n']);


fprintf([ ...
    '---- ---- ----- ------- ------- ------ ', ...
    '------- --- ------- ------ ', ...
    '-------- --------\n']);


for iR = 1:nR

    for iL = 1:nL

        for iD = 1:nD

            fprintf( ...
                '%2.0fHz %3.0f%% %3.0fms  %.4f  %.4f  %.4f  %.4f  %.3f  %.3f   %.3f    %.2f     %.2f\n', ...
                commRates(iR), ...
                100*lossLevels(iL), ...
                1000*delayLevels(iD), ...
                meanRMSE(iR,iL,iD), ...
                stdRMSE(iR,iL,iD), ...
                meanMaxErr(iR,iL,iD), ...
                meanMinEval(iR,iL,iD), ...
                meanPDR(iR,iL,iD), ...
                meanAoI(iR,iL,iD), ...
                AOITheory(iR,iL,iD), ...
                formationFailureRate(iR,iL,iD), ...
                safetyFailureRate(iR,iL,iD));

        end

    end

end


%% ============================================================
% Network-model validation summary
% ============================================================

fprintf('\n');

fprintf('Network analytical validation\n');

fprintf( ...
    '  Mean AoI error : %.6f s\n', ...
    meanAOIError);

fprintf( ...
    '  Max  AoI error : %.6f s\n', ...
    maxAOIError);

fprintf( ...
    '  Mean PDR error : %.6f\n', ...
    meanPDRError);

fprintf( ...
    '  Max  PDR error : %.6f\n', ...
    maxPDRError);


%% ============================================================
% Mean-valid operating point
%
% Condition is valid if:
%
%   mean RMSE <= threshold
%
% AND
%
%   mean MinEval >= safety threshold
%
% ============================================================

meanValid = ...
    (meanRMSE <= formationThreshold) ...
    & ...
    (meanMinEval >= safetyThreshold);


%% ============================================================
% Robust-valid operating point
%
% Condition is robust if:
%
%   formation failure probability <= 5%
%
% AND
%
%   safety failure probability <= 5%
%
% ============================================================

robustValid = ...
    (formationFailureRate ...
    <= robustFailureLimit) ...
    & ...
    (safetyFailureRate ...
    <= robustFailureLimit);


%% ============================================================
% Find minimum valid communication rate for every
% loss-delay pair
%
% Dimensions:
%
%   loss x delay
%
% ============================================================

minMeanValidRate = ...
    nan(nL,nD);


minRobustValidRate = ...
    nan(nL,nD);


for iL = 1:nL

    for iD = 1:nD


        %% ----------------------------------------------------
        % Minimum rate based on mean metrics
        % -----------------------------------------------------

        validRates = [];


        for iR = 1:nR

            if meanValid(iR,iL,iD)

                validRates(end+1) = ...
                    commRates(iR); %#ok<AGROW>

            end

        end


        if ~isempty(validRates)

            minMeanValidRate(iL,iD) = ...
                min(validRates);

        end


        %% ----------------------------------------------------
        % Minimum rate based on failure probability
        % -----------------------------------------------------

        validRates = [];


        for iR = 1:nR

            if robustValid(iR,iL,iD)

                validRates(end+1) = ...
                    commRates(iR); %#ok<AGROW>

            end

        end


        if ~isempty(validRates)

            minRobustValidRate(iL,iD) = ...
                min(validRates);

        end

    end

end


%% ============================================================
% Print resource-robustness frontier
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Minimum communication-rate frontier\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Loss Delay  MinMeanRate  MinRobustRate\n');


fprintf( ...
    '---- -----  -----------  -------------\n');


for iL = 1:nL

    for iD = 1:nD


        if isnan(minMeanValidRate(iL,iD))

            meanRateText = ...
                '>20';

        else

            meanRateText = ...
                sprintf( ...
                '%.0f', ...
                minMeanValidRate(iL,iD));

        end


        if isnan(minRobustValidRate(iL,iD))

            robustRateText = ...
                '>20';

        else

            robustRateText = ...
                sprintf( ...
                '%.0f', ...
                minRobustValidRate(iL,iD));

        end


        fprintf( ...
            '%3.0f%% %3.0fms      %4s Hz        %4s Hz\n', ...
            100*lossLevels(iL), ...
            1000*delayLevels(iD), ...
            meanRateText, ...
            robustRateText);

    end

end


%% ============================================================
% Figure 1
% RMSE heatmap for each communication rate
% ============================================================

figure;


for iR = 1:nR

    subplot(1,nR,iR);


    data = ...
        squeeze(meanRMSE(iR,:,:));


    imagesc( ...
        1000*delayLevels, ...
        100*lossLevels, ...
        data);


    set(gca,'YDir','normal');

    colorbar;


    xlabel('Delay [ms]');

    ylabel('Loss [%]');


    title( ...
        sprintf( ...
        'RMSE - %.0f Hz', ...
        commRates(iR)));


    for iL = 1:nL

        for iD = 1:nD

            text( ...
                1000*delayLevels(iD), ...
                100*lossLevels(iL), ...
                sprintf( ...
                '%.3f', ...
                data(iL,iD)), ...
                'HorizontalAlignment', ...
                'center');

        end

    end

end


%% ============================================================
% Figure 2
% Formation failure probability
% ============================================================

figure;


for iR = 1:nR

    subplot(1,nR,iR);


    data = ...
        squeeze( ...
        formationFailureRate(iR,:,:));


    imagesc( ...
        1000*delayLevels, ...
        100*lossLevels, ...
        data);


    set(gca,'YDir','normal');

    colorbar;

    caxis([0 1]);


    xlabel('Delay [ms]');

    ylabel('Loss [%]');


    title( ...
        sprintf( ...
        'Failure - %.0f Hz', ...
        commRates(iR)));


    for iL = 1:nL

        for iD = 1:nD

            text( ...
                1000*delayLevels(iD), ...
                100*lossLevels(iL), ...
                sprintf( ...
                '%.2f', ...
                data(iL,iD)), ...
                'HorizontalAlignment', ...
                'center');

        end

    end

end


%% ============================================================
% Figure 3
% Minimum robust communication rate
% ============================================================

figure;


plotData = ...
    minRobustValidRate;


% Replace NaN only for visualization.
% >20-Hz conditions appear above the tested range.
plotDataDisplay = ...
    plotData;


plotDataDisplay( ...
    isnan(plotDataDisplay)) = ...
    25;


imagesc( ...
    1000*delayLevels, ...
    100*lossLevels, ...
    plotDataDisplay);


set(gca,'YDir','normal');

colorbar;


xlabel('Communication delay [ms]');

ylabel('Packet loss [%]');

title('EXP04B minimum robust periodic communication rate');


for iL = 1:nL

    for iD = 1:nD


        if isnan( ...
                minRobustValidRate(iL,iD))

            labelText = ...
                '>20';

        else

            labelText = ...
                sprintf( ...
                '%.0f Hz', ...
                minRobustValidRate(iL,iD));

        end


        text( ...
            1000*delayLevels(iD), ...
            100*lossLevels(iL), ...
            labelText, ...
            'HorizontalAlignment', ...
            'center');

    end

end


%% ============================================================
% Figure 4
% Representative resource-robustness curves
%
% Conditions:
%
%   clean:
%       loss 0%, delay 0
%
%   moderate:
%       loss 20%, delay 80 ms
%
%   stressed:
%       loss 40%, delay 120 ms
%
% ============================================================

figure;

hold on;
grid on;


% Clean
iL = 1;
iD = 1;

plot( ...
    commRates, ...
    squeeze(meanRMSE(:,iL,iD)), ...
    'o-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    '0% loss, 0 ms');


% Moderate
iL = find( ...
    lossLevels == 0.2,1);

iD = find( ...
    delayLevels == 0.08,1);


plot( ...
    commRates, ...
    squeeze(meanRMSE(:,iL,iD)), ...
    's-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    '20% loss, 80 ms');


% Stressed
iL = find( ...
    lossLevels == 0.4,1);

iD = find( ...
    delayLevels == 0.12,1);


plot( ...
    commRates, ...
    squeeze(meanRMSE(:,iL,iD)), ...
    'd-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    '40% loss, 120 ms');


yline( ...
    formationThreshold, ...
    '--', ...
    'DisplayName', ...
    'formation threshold');


xlabel('Communication rate [Hz]');

ylabel('Formation RMSE [m]');

title('EXP04B resource-robustness frontier');

legend('Location','best');


%% ============================================================
% Figure 5
% AoI vs formation RMSE over ALL conditions
%
% If points continue following a common trend, this further
% supports AoI as a communication-state variable.
% ============================================================

figure;

hold on;
grid on;


for iR = 1:nR


    xAoI = ...
        squeeze(meanAoI(iR,:,:));


    yRMSE = ...
        squeeze(meanRMSE(iR,:,:));


    plot( ...
        xAoI(:), ...
        yRMSE(:), ...
        'o', ...
        'MarkerSize',7, ...
        'DisplayName', ...
        sprintf( ...
        '%.0f Hz', ...
        commRates(iR)));

end


xlabel('Mean AoI [s]');

ylabel('Formation RMSE [m]');

title('EXP04B formation performance versus information freshness');

legend('Location','northwest');


%% ============================================================
% AoI-RMSE global correlation
% ============================================================

xAoI = ...
    meanAoI(:);


yRMSE = ...
    meanRMSE(:);


R = ...
    corrcoef(xAoI,yRMSE);


aoiRmseCorrelation = ...
    R(1,2);


pFit = ...
    polyfit( ...
    xAoI,yRMSE,1);


yFit = ...
    polyval( ...
    pFit,xAoI);


SSres = ...
    sum( ...
    (yRMSE-yFit).^2);


SStot = ...
    sum( ...
    (yRMSE-mean(yRMSE)).^2);


aoiRmseR2 = ...
    1 - SSres/SStot;


fprintf('\n');

fprintf('Global AoI-RMSE relationship\n');


fprintf( ...
    '  Pearson correlation : %.6f\n', ...
    aoiRmseCorrelation);


fprintf( ...
    '  Linear fit           : RMSE = %.4f*AoI + %.4f\n', ...
    pFit(1), ...
    pFit(2));


fprintf( ...
    '  Linear R^2           : %.6f\n', ...
    aoiRmseR2);


%% ============================================================
% Figure 6
% Communication reduction relative to 50 Hz
% ============================================================

figure;


plot( ...
    commRates, ...
    COMM_REDUCTION, ...
    'o-', ...
    'LineWidth',1.3);


grid on;


xlabel('Periodic communication rate [Hz]');

ylabel('Communication reduction vs 50 Hz [%]');

title('EXP04B nominal communication resource saving');


%% ============================================================
% End
% ============================================================

fprintf('\n');

fprintf( ...
    'EXP04B completed.\n');

fprintf('\n');


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
