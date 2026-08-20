startup;

lossLevels = [0 0.1 0.2 0.3 0.4 0.5 0.6];

numSeeds = 20;

nL = numel(lossLevels);

RMSE = zeros(numSeeds,nL);
MAXERR = zeros(numSeeds,nL);
MINSEP = zeros(numSeeds,nL);
PDR = zeros(numSeeds,nL);
AOI = zeros(numSeeds,nL);
MINSEPEVAL = zeros(numSeeds,nL);


fprintf('\nEXP03A packet-loss sweep\n\n');


for q = 1:nL

    pLoss = lossLevels(q);

    fprintf('Packet loss = %.0f %%\n', ...
        100*pLoss);


    for s = 1:numSeeds

        cfg = defaultConfig();

        cfg.net.packetLoss = pLoss;

        cfg.net.seed = 1000 + s;

        out = simSwarmNetwork(cfg);

        M = computeSwarmMetrics(out,cfg);


        RMSE(s,q) = M.formationRMSE;

        MAXERR(s,q) = M.maxFormationError;

        MINSEPEVAL(s,q) = ...
            M.minSeparationEval;

        PDR(s,q) = out.PDR;

        idx = out.t >= 8;

        AOI(s,q) = ...
            mean(out.meanAoI(idx));

    end

end


%% ============================================================
% Summary
% ============================================================

fprintf('\nSummary over %d Monte Carlo seeds\n', ...
    numSeeds);

fprintf('\n');

fprintf([ ...
    'Loss    RMSE[m]   MaxErr[m]  ', ...
    'MinFull[m] MinEval[m] PDR    AoI[s]\n']);

for q = 1:nL

    fprintf( ...
        '%3.0f%%    %.4f    %.4f     %.4f     %.4f    %.3f   %.3f\n', ...
        100*lossLevels(q), ...
        mean(RMSE(:,q)), ...
        mean(MAXERR(:,q)), ...
        mean(MINSEP(:,q)), ...
        mean(MINSEPEVAL(:,q)), ...
        mean(PDR(:,q)), ...
        mean(AOI(:,q)));

end


%% ============================================================
% Figure 1: Formation RMSE
% ============================================================

figure;

errorbar( ...
    100*lossLevels, ...
    mean(RMSE,1), ...
    std(RMSE,0,1), ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Packet loss [%]');
ylabel('Formation RMSE [m]');

title('EXP03A packet loss vs formation error');


%% ============================================================
% Figure 2: AoI
% ============================================================

figure;

plot( ...
    100*lossLevels, ...
    mean(AOI,1), ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Packet loss [%]');
ylabel('Mean AoI [s]');

title('EXP03A packet loss vs Age of Information');


%% ============================================================
% Figure 3: PDR
% ============================================================

figure;

plot( ...
    100*lossLevels, ...
    mean(PDR,1), ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Packet loss [%]');
ylabel('Packet delivery ratio');

ylim([0 1.05]);

title('EXP03A measured packet delivery ratio');