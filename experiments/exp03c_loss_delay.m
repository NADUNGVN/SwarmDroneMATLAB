%% EXP03C - Combined packet loss and fixed communication delay
%
% Purpose:
%   Evaluate distributed swarm formation under simultaneous
%   packet loss and fixed communication delay.
%
% Metrics:
%   - Formation RMSE
%   - Maximum formation error
%   - Minimum separation (full mission)
%   - Minimum separation after transient
%   - Packet Delivery Ratio (PDR)
%   - Mean Age of Information (AoI)
%   - Safety failure probability
%   - Formation failure probability
%
% Network model:
%   - Periodic communication
%   - Bernoulli packet loss
%   - Fixed delay
%   - Packet queue with generation/arrival timestamps
%
% AoI analytical model:
%
%        Delta_bar = d + Tc*(1+p)/(2*(1-p))
%
% where:
%   d  = fixed communication delay
%   Tc = communication period
%   p  = packet loss probability
%
% ============================================================

startup;

close all;

%% ============================================================
% Result persistence
%
% Creates results/exp03c_loss_delay/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

R = startExperiment('exp03c_loss_delay');




%% ============================================================
% Experiment configuration
% ============================================================

lossLevels = [
    0.0
    0.2
    0.4
    0.6
];

delayLevels = [
    0.00
    0.04
    0.08
    0.12
    0.20
    0.30
];

% ------------------------------------------------------------
% IMPORTANT
%
% First debug run:
%     numSeeds = 3;
%
% After results are verified:
%     numSeeds = 20;
% ------------------------------------------------------------

numSeeds = 20;


nL = numel(lossLevels);
nD = numel(delayLevels);


%% ============================================================
% Failure thresholds
% ============================================================

% Minimum allowed separation after formation acquisition
safetyThreshold = 0.25;       % [m]

% Formation considered failed if RMSE exceeds this
formationThreshold = 0.10;    % [m]


%% ============================================================
% Allocate Monte Carlo storage
%
% Dimension:
%
%   seed x packet-loss x delay
%
% ============================================================

RMSE = zeros(numSeeds,nL,nD);

MAXERR = zeros(numSeeds,nL,nD);

MINFULL = zeros(numSeeds,nL,nD);

MINEVAL = zeros(numSeeds,nL,nD);

PDR = zeros(numSeeds,nL,nD);

AOI = zeros(numSeeds,nL,nD);


SAFETYFAIL = false(numSeeds,nL,nD);

FORMATIONFAIL = false(numSeeds,nL,nD);


%% ============================================================
% Run experiment
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP03C packet-loss x fixed-delay sweep\n');
fprintf('============================================================\n\n');

fprintf('Monte Carlo seeds per condition: %d\n\n',numSeeds);


for iL = 1:nL

    for iD = 1:nD

        pLoss = lossLevels(iL);

        delay = delayLevels(iD);


        fprintf( ...
            'Loss = %2.0f %% | Delay = %3.0f ms\n', ...
            100*pLoss, ...
            1000*delay);


        for s = 1:numSeeds

            %% ------------------------------------------------
            % Configuration
            % -------------------------------------------------

            cfg = defaultConfig();


            cfg.net.packetLoss = pLoss;

            cfg.net.delay = delay;

            % EXP03C uses fixed delay only.
            % Jitter will be introduced in a later experiment.
            cfg.net.jitterStd = 0;


            % -------------------------------------------------
            % Reproducible random seed
            %
            % Each:
            %   loss level
            %   delay level
            %   Monte Carlo run
            %
            % receives a unique seed.
            % -------------------------------------------------

            cfg.net.seed = ...
                100000 ...
                + 1000*iL ...
                + 100*iD ...
                + s;


            %% ------------------------------------------------
            % Simulation
            % -------------------------------------------------

            out = simSwarmNetworkQueued(cfg);


            %% ------------------------------------------------
            % Swarm metrics
            % -------------------------------------------------

            M = computeSwarmMetrics(out,cfg);


            %% ------------------------------------------------
            % Store formation metrics
            % -------------------------------------------------

            RMSE(s,iL,iD) = ...
                M.formationRMSE;


            MAXERR(s,iL,iD) = ...
                M.maxFormationError;


            MINFULL(s,iL,iD) = ...
                M.minSeparation;


            MINEVAL(s,iL,iD) = ...
                M.minSeparationEval;


            %% ------------------------------------------------
            % Store network metrics
            % -------------------------------------------------

            PDR(s,iL,iD) = ...
                out.PDR;


            % Evaluate AoI only after formation acquisition
            idxEval = out.t >= 8.0;


            AOI(s,iL,iD) = ...
                mean(out.meanAoI(idxEval));


            %% ------------------------------------------------
            % Failure events
            % -------------------------------------------------

            SAFETYFAIL(s,iL,iD) = ...
                M.minSeparationEval ...
                < safetyThreshold;


            FORMATIONFAIL(s,iL,iD) = ...
                M.formationRMSE ...
                > formationThreshold;

        end

    end

end


%% ============================================================
% Monte Carlo statistics
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


safetyFailureRate = ...
    squeeze(mean(SAFETYFAIL,1));


formationFailureRate = ...
    squeeze(mean(FORMATIONFAIL,1));


%% ============================================================
% Analytical AoI
%
% Bernoulli packet loss + fixed communication delay
%
% mean AoI:
%
%   Delta_bar =
%
%       d + Tc * (1+p)/(2*(1-p))
%
% ============================================================

cfg0 = defaultConfig();

Tc = cfg0.net.commPeriod;


AOITheory = zeros(nL,nD);


for iL = 1:nL

    p = lossLevels(iL);


    for iD = 1:nD

        d = delayLevels(iD);


        AOITheory(iL,iD) = ...
            d ...
            + Tc * (1+p) ...
            / (2*(1-p));

    end

end


%% ============================================================
% Analytical AoI validation error
% ============================================================

AOITheoryError = ...
    abs(meanAoI - AOITheory);


maxAOITheoryError = ...
    max(AOITheoryError(:));


meanAOITheoryError = ...
    mean(AOITheoryError(:));


%% ============================================================
% Print results table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP03C mean results over %d Monte Carlo seeds\n',numSeeds);
fprintf('============================================================\n\n');


fprintf([ ...
    'Loss  Delay   RMSE[m]  StdRMSE   MaxErr[m]  ', ...
    'MinFull[m] MinEval[m]  PDR    ', ...
    'AoI_sim  AoI_th   SafeFail FormFail\n']);


fprintf([ ...
    '----  -----   -------  -------   ---------  ', ...
    '---------- ----------  -----  ', ...
    '-------  ------   -------- --------\n']);


for iL = 1:nL

    for iD = 1:nD

        fprintf( ...
            '%3.0f%%  %4.0fms   %.4f   %.4f    %.4f     %.4f     %.4f    %.3f   %.3f    %.3f     %.2f     %.2f\n', ...
            100*lossLevels(iL), ...
            1000*delayLevels(iD), ...
            meanRMSE(iL,iD), ...
            stdRMSE(iL,iD), ...
            meanMaxErr(iL,iD), ...
            meanMinFull(iL,iD), ...
            meanMinEval(iL,iD), ...
            meanPDR(iL,iD), ...
            meanAoI(iL,iD), ...
            AOITheory(iL,iD), ...
            safetyFailureRate(iL,iD), ...
            formationFailureRate(iL,iD));

    end

end


%% ============================================================
% AoI analytical validation summary
% ============================================================

fprintf('\n');
fprintf('AoI analytical validation\n');

fprintf( ...
    '  Mean |simulation - theory| : %.6f s\n', ...
    meanAOITheoryError);

fprintf( ...
    '  Max  |simulation - theory| : %.6f s\n', ...
    maxAOITheoryError);


%% ============================================================
% Important corner cases
% ============================================================

fprintf('\n');
fprintf('Corner-case sanity checks\n');


% ------------------------------------------------------------
% p = 0%, d = 0 ms
% ------------------------------------------------------------

iL0 = find(lossLevels == 0.0,1);
iD0 = find(delayLevels == 0.0,1);


if ~isempty(iL0) && ~isempty(iD0)

    fprintf( ...
        '  0%% loss,   0 ms : RMSE = %.4f m | AoI = %.3f s | theory = %.3f s\n', ...
        meanRMSE(iL0,iD0), ...
        meanAoI(iL0,iD0), ...
        AOITheory(iL0,iD0));

end


% ------------------------------------------------------------
% Maximum loss, zero delay
% ------------------------------------------------------------

iLmax = nL;


if ~isempty(iD0)

    fprintf( ...
        '  %.0f%% loss, 0 ms : RMSE = %.4f m | AoI = %.3f s | theory = %.3f s\n', ...
        100*lossLevels(iLmax), ...
        meanRMSE(iLmax,iD0), ...
        meanAoI(iLmax,iD0), ...
        AOITheory(iLmax,iD0));

end


% ------------------------------------------------------------
% Zero loss, maximum delay
% ------------------------------------------------------------

iDmax = nD;


if ~isempty(iL0)

    fprintf( ...
        '  0%% loss, %3.0f ms : RMSE = %.4f m | AoI = %.3f s | theory = %.3f s\n', ...
        1000*delayLevels(iDmax), ...
        meanRMSE(iL0,iDmax), ...
        meanAoI(iL0,iDmax), ...
        AOITheory(iL0,iDmax));

end


% ------------------------------------------------------------
% Maximum loss + maximum delay
% ------------------------------------------------------------

fprintf( ...
    '  %.0f%% loss, %3.0f ms : RMSE = %.4f m | AoI = %.3f s | theory = %.3f s\n', ...
    100*lossLevels(iLmax), ...
    1000*delayLevels(iDmax), ...
    meanRMSE(iLmax,iDmax), ...
    meanAoI(iLmax,iDmax), ...
    AOITheory(iLmax,iDmax));


%% ============================================================
% Figure 1
% Formation RMSE heatmap
% ============================================================

figure;

imagesc( ...
    1000*delayLevels, ...
    100*lossLevels, ...
    meanRMSE);

set(gca,'YDir','normal');

colorbar;

xlabel('Communication delay [ms]');

ylabel('Packet loss [%]');

title('EXP03C formation RMSE');


for iL = 1:nL

    for iD = 1:nD

        text( ...
            1000*delayLevels(iD), ...
            100*lossLevels(iL), ...
            sprintf('%.3f', ...
            meanRMSE(iL,iD)), ...
            'HorizontalAlignment','center');

    end

end


%% ============================================================
% Figure 2
% Mean AoI heatmap
% ============================================================

figure;

imagesc( ...
    1000*delayLevels, ...
    100*lossLevels, ...
    meanAoI);

set(gca,'YDir','normal');

colorbar;

xlabel('Communication delay [ms]');

ylabel('Packet loss [%]');

title('EXP03C mean Age of Information');


for iL = 1:nL

    for iD = 1:nD

        text( ...
            1000*delayLevels(iD), ...
            100*lossLevels(iL), ...
            sprintf('%.3f', ...
            meanAoI(iL,iD)), ...
            'HorizontalAlignment','center');

    end

end


%% ============================================================
% Figure 3
% Formation degradation versus AoI
% ============================================================

figure;

hold on;
grid on;


for iL = 1:nL

    plot( ...
        meanAoI(iL,:), ...
        meanRMSE(iL,:), ...
        'o-', ...
        'LineWidth',1.3, ...
        'DisplayName', ...
        sprintf( ...
        'loss = %.0f%%', ...
        100*lossLevels(iL)));

end


xlabel('Mean AoI [s]');

ylabel('Formation RMSE [m]');

title('EXP03C formation degradation versus AoI');

legend('Location','northwest');


%% ============================================================
% Figure 4
% Safety violation probability heatmap
% ============================================================

figure;

imagesc( ...
    1000*delayLevels, ...
    100*lossLevels, ...
    safetyFailureRate);

set(gca,'YDir','normal');

colorbar;

caxis([0 1]);

xlabel('Communication delay [ms]');

ylabel('Packet loss [%]');

title('EXP03C safety violation probability');


for iL = 1:nL

    for iD = 1:nD

        text( ...
            1000*delayLevels(iD), ...
            100*lossLevels(iL), ...
            sprintf('%.2f', ...
            safetyFailureRate(iL,iD)), ...
            'HorizontalAlignment','center');

    end

end


%% ============================================================
% Figure 5
% Formation failure probability heatmap
% ============================================================

figure;

imagesc( ...
    1000*delayLevels, ...
    100*lossLevels, ...
    formationFailureRate);

set(gca,'YDir','normal');

colorbar;

caxis([0 1]);

xlabel('Communication delay [ms]');

ylabel('Packet loss [%]');

title('EXP03C formation failure probability');


for iL = 1:nL

    for iD = 1:nD

        text( ...
            1000*delayLevels(iD), ...
            100*lossLevels(iL), ...
            sprintf('%.2f', ...
            formationFailureRate(iL,iD)), ...
            'HorizontalAlignment','center');

    end

end


%% ============================================================
% Figure 6
% Analytical AoI validation
% ============================================================

figure;

hold on;
grid on;


plot( ...
    AOITheory(:), ...
    meanAoI(:), ...
    'o', ...
    'MarkerSize',7);


maxAoI = max([ ...
    AOITheory(:); ...
    meanAoI(:)]);


plot( ...
    [0 maxAoI], ...
    [0 maxAoI], ...
    '--', ...
    'LineWidth',1.2);


xlabel('Analytical AoI [s]');

ylabel('Simulated AoI [s]');

title('EXP03C analytical AoI validation');

legend( ...
    'simulation', ...
    'ideal y = x', ...
    'Location','northwest');

axis equal;


%% ============================================================
% Figure 7
% Minimum separation after transient
% ============================================================

figure;

imagesc( ...
    1000*delayLevels, ...
    100*lossLevels, ...
    meanMinEval);

set(gca,'YDir','normal');

colorbar;

xlabel('Communication delay [ms]');

ylabel('Packet loss [%]');

title('EXP03C minimum separation after t >= 8 s');


for iL = 1:nL

    for iD = 1:nD

        text( ...
            1000*delayLevels(iD), ...
            100*lossLevels(iL), ...
            sprintf('%.3f', ...
            meanMinEval(iL,iD)), ...
            'HorizontalAlignment','center');

    end

end


%% ============================================================
% End
% ============================================================

fprintf('\n');
fprintf('EXP03C completed.\n');
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
