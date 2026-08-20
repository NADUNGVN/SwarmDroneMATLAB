%% EXP03D - Communication jitter and out-of-order packets
%
% Purpose:
%   Evaluate distributed swarm formation under stochastic
%   communication delay jitter.
%
% EXP03D isolates jitter:
%
%   packetLoss = 0
%   baseDelay  = 80 ms
%
% Jitter may cause packet reordering:
%
%   newer packet arrives before older packet
%
% The receiver must reject stale/out-of-order packets.
%
% Metrics:
%   - Formation RMSE
%   - Maximum formation error
%   - Minimum separation
%   - Mean AoI
%   - PDR
%   - Arrival ratio
%   - Stale discard ratio
%   - Effective update ratio
%   - Safety failure probability
%   - Formation failure probability
%
% ============================================================

startup;

close all;


%% ============================================================
% Experiment configuration
% ============================================================

% Fixed base communication delay
baseDelay = 0.08;        % [s] = 80 ms


% Standard deviation of Gaussian delay jitter
jitterLevels = [
    0.00
    0.02
    0.04
    0.06
    0.08
    0.12
];


% ------------------------------------------------------------
% First debug:
%
% numSeeds = 3;
%
% After validation:
%
% numSeeds = 20;
% ------------------------------------------------------------

numSeeds = 20;


nJ = numel(jitterLevels);


%% ============================================================
% Thresholds
% ============================================================

safetyThreshold = 0.25;       % [m]

formationThreshold = 0.10;    % [m]


%% ============================================================
% Monte Carlo storage
%
% Dimension:
%
%   seed x jitter-level
%
% ============================================================

RMSE = zeros(numSeeds,nJ);

MAXERR = zeros(numSeeds,nJ);

MINFULL = zeros(numSeeds,nJ);

MINEVAL = zeros(numSeeds,nJ);

AOI = zeros(numSeeds,nJ);

PDR = zeros(numSeeds,nJ);

ARRIVALRATIO = zeros(numSeeds,nJ);

STALEDISCARD = zeros(numSeeds,nJ);

EFFECTIVEUPDATE = zeros(numSeeds,nJ);

AOIP95 = zeros(numSeeds,nJ);
AOIMAX = zeros(numSeeds,nJ);

SAFETYFAIL = false(numSeeds,nJ);

FORMATIONFAIL = false(numSeeds,nJ);


%% ============================================================
% Experiment header
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP03D communication jitter / out-of-order sweep\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Base delay                  : %.0f ms\n', ...
    1000*baseDelay);

fprintf( ...
    'Packet loss                 : 0 %%\n');

fprintf( ...
    'Monte Carlo seeds/condition : %d\n\n', ...
    numSeeds);


%% ============================================================
% Monte Carlo sweep
% ============================================================

for iJ = 1:nJ

    jitterStd = jitterLevels(iJ);


    fprintf( ...
        'Jitter std = %3.0f ms\n', ...
        1000*jitterStd);


    for s = 1:numSeeds


        %% ----------------------------------------------------
        % Configuration
        % -----------------------------------------------------

        cfg = defaultConfig();


        % EXP03D isolates jitter.
        cfg.net.packetLoss = 0;


        % Fixed base latency
        cfg.net.delay = ...
            baseDelay;


        % Gaussian jitter
        cfg.net.jitterStd = ...
            jitterStd;


        % -----------------------------------------------------
        % Reproducible unique seed
        % -----------------------------------------------------

        cfg.net.seed = ...
            200000 ...
            + 1000*iJ ...
            + s;


        %% ----------------------------------------------------
        % Simulation
        % -----------------------------------------------------

        out = ...
            simSwarmNetworkQueued(cfg);


        %% ----------------------------------------------------
        % Formation metrics
        % -----------------------------------------------------

        M = ...
            computeSwarmMetrics(out,cfg);


        %% ----------------------------------------------------
        % Store swarm metrics
        % -----------------------------------------------------

        RMSE(s,iJ) = ...
            M.formationRMSE;


        MAXERR(s,iJ) = ...
            M.maxFormationError;


        MINFULL(s,iJ) = ...
            M.minSeparation;


        MINEVAL(s,iJ) = ...
            M.minSeparationEval;


        %% ----------------------------------------------------
        % Store network metrics
        % -----------------------------------------------------

        idxEval = ...
            out.t >= 8.0;


        AOI(s,iJ) = ...
            mean(out.meanAoI(idxEval));

        aoiEval = out.meanAoI(idxEval);

        AOIP95(s,iJ) = ...
            prctile(aoiEval,95);
        
        AOIMAX(s,iJ) = ...
            max(aoiEval);


        PDR(s,iJ) = ...
            out.PDR;


        ARRIVALRATIO(s,iJ) = ...
            out.arrivalRatio;


        STALEDISCARD(s,iJ) = ...
            out.staleDiscardRatio;


        EFFECTIVEUPDATE(s,iJ) = ...
            out.effectiveUpdateRatio;


        %% ----------------------------------------------------
        % Failure events
        % -----------------------------------------------------

        SAFETYFAIL(s,iJ) = ...
            M.minSeparationEval ...
            < safetyThreshold;


        FORMATIONFAIL(s,iJ) = ...
            M.formationRMSE ...
            > formationThreshold;

    end

end


%% ============================================================
% Monte Carlo statistics
% ============================================================

meanRMSE = ...
    mean(RMSE,1);

stdRMSE = ...
    std(RMSE,0,1);


meanMaxErr = ...
    mean(MAXERR,1);


meanMinFull = ...
    mean(MINFULL,1);


meanMinEval = ...
    mean(MINEVAL,1);


meanAoI = ...
    mean(AOI,1);

stdAoI = ...
    std(AOI,0,1);


meanPDR = ...
    mean(PDR,1);


meanArrivalRatio = ...
    mean(ARRIVALRATIO,1);


meanStaleDiscard = ...
    mean(STALEDISCARD,1);


meanEffectiveUpdate = ...
    mean(EFFECTIVEUPDATE,1);


safetyFailureRate = ...
    mean(SAFETYFAIL,1);


formationFailureRate = ...
    mean(FORMATIONFAIL,1);

meanAoIP95 = mean(AOIP95,1);
meanAoIMax = mean(AOIMAX,1);

%% ============================================================
% Print summary
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP03D mean results over %d Monte Carlo seeds\n', ...
    numSeeds);

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'Jitter RMSE[m] StdRMSE MaxErr[m] ', ...
    'MinFull MinEval AoImean AoIP95 AoImax ', ...
    'PDR Arrival StaleDisc EffUpdate SafeFail FormFail\n']);


fprintf([ ...
    '------  ------- ------- --------- ', ...
    '------- ------- ------ ', ...
    '--- --------- --------- -------- --------\n']);


for iJ = 1:nJ

    fprintf( ...
        '%4.0fms  %.4f  %.4f  %.4f   %.4f  %.4f  %.3f   %.3f   %.3f   %.3f   %.3f   %.3f     %.3f      %.2f     %.2f\n', ...
        1000*jitterLevels(iJ), ...
        meanRMSE(iJ), ...
        stdRMSE(iJ), ...
        meanMaxErr(iJ), ...
        meanMinFull(iJ), ...
        meanMinEval(iJ), ...
        meanAoI(iJ), ...
        meanAoIP95(iJ), ...
        meanAoIMax(iJ), ...
        meanPDR(iJ), ...
        meanArrivalRatio(iJ), ...
        meanStaleDiscard(iJ), ...
        meanEffectiveUpdate(iJ), ...
        safetyFailureRate(iJ), ...
        formationFailureRate(iJ));

end


%% ============================================================
% Baseline sanity check
%
% With zero jitter:
%
% loss  = 0
% delay = 80 ms
%
% EXP03B previously gave approximately:
%
% RMSE    = 0.0803 m
% AoI     = 0.130 s
% MinEval = 0.4991 m
%
% ============================================================

fprintf('\n');

fprintf('Zero-jitter cross-validation\n');

fprintf( ...
    '  RMSE     : %.4f m\n', ...
    meanRMSE(1));

fprintf( ...
    '  AoI      : %.3f s\n', ...
    meanAoI(1));

fprintf( ...
    '  MinEval  : %.4f m\n', ...
    meanMinEval(1));

fprintf( ...
    '  PDR      : %.3f\n', ...
    meanPDR(1));

fprintf( ...
    '  StaleDisc: %.3f\n', ...
    meanStaleDiscard(1));


%% ============================================================
% Relationship: AoI versus RMSE
% ============================================================

R = corrcoef( ...
    meanAoI, ...
    meanRMSE);


if numel(R) >= 4

    aoiRmseCorrelation = ...
        R(1,2);

else

    aoiRmseCorrelation = NaN;

end


fprintf('\n');

fprintf('AoI-RMSE relationship\n');

fprintf( ...
    '  Pearson correlation : %.6f\n', ...
    aoiRmseCorrelation);


%% ============================================================
% Figure 1
% Jitter versus formation RMSE
% ============================================================

figure;

errorbar( ...
    1000*jitterLevels, ...
    meanRMSE, ...
    stdRMSE, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Jitter standard deviation [ms]');

ylabel('Formation RMSE [m]');

title('EXP03D jitter vs formation error');


%% ============================================================
% Figure 2
% Jitter versus AoI
% ============================================================

figure;

errorbar( ...
    1000*jitterLevels, ...
    meanAoI, ...
    stdAoI, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Jitter standard deviation [ms]');

ylabel('Mean AoI [s]');

title('EXP03D jitter vs Age of Information');


%% ============================================================
% Figure 3
% Out-of-order stale packet discard
% ============================================================

figure;

plot( ...
    1000*jitterLevels, ...
    meanStaleDiscard, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Jitter standard deviation [ms]');

ylabel('Stale discard ratio');

title('EXP03D jitter vs stale packet discard');


%% ============================================================
% Figure 4
% Effective communication update ratio
% ============================================================

figure;

plot( ...
    1000*jitterLevels, ...
    meanEffectiveUpdate, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Jitter standard deviation [ms]');

ylabel('Effective update ratio');

title('EXP03D effective communication updates');


%% ============================================================
% Figure 5
% RMSE versus AoI
% ============================================================

figure;

plot( ...
    meanAoI, ...
    meanRMSE, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Mean AoI [s]');

ylabel('Formation RMSE [m]');

title('EXP03D formation degradation versus AoI');


%% ============================================================
% Figure 6
% Minimum separation
% ============================================================

figure;

plot( ...
    1000*jitterLevels, ...
    meanMinEval, ...
    'o-', ...
    'LineWidth',1.3);

hold on;

yline( ...
    safetyThreshold, ...
    '--');

grid on;

xlabel('Jitter standard deviation [ms]');

ylabel('Minimum separation after t >= 8 s [m]');

title('EXP03D jitter vs swarm separation');

legend( ...
    'mean minimum separation', ...
    'safety threshold', ...
    'Location','best');


%% ============================================================
% Figure 7
% Failure probability
% ============================================================

figure;

hold on;
grid on;

plot( ...
    1000*jitterLevels, ...
    formationFailureRate, ...
    'o-', ...
    'LineWidth',1.3);

plot( ...
    1000*jitterLevels, ...
    safetyFailureRate, ...
    's-', ...
    'LineWidth',1.3);

xlabel('Jitter standard deviation [ms]');

ylabel('Failure probability');

ylim([0 1.05]);

title('EXP03D failure probability');

legend( ...
    'formation failure', ...
    'safety failure', ...
    'Location','northwest');


%% ============================================================
% Figure 8
% PDR and effective-update ratio
% ============================================================

figure;

hold on;
grid on;

plot( ...
    1000*jitterLevels, ...
    meanPDR, ...
    'o-', ...
    'LineWidth',1.3);

plot( ...
    1000*jitterLevels, ...
    meanEffectiveUpdate, ...
    's-', ...
    'LineWidth',1.3);

xlabel('Jitter standard deviation [ms]');

ylabel('Ratio');

ylim([0 1.05]);

title('EXP03D PDR vs effective information updates');

legend( ...
    'PDR', ...
    'effective update ratio', ...
    'Location','southwest');


%% ============================================================
% End
% ============================================================

fprintf('\n');
fprintf('EXP03D completed.\n');
fprintf('\n');