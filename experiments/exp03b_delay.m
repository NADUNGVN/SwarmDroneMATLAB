startup;

delayLevels = [
    0.00
    0.02
    0.04
    0.08
    0.12
    0.20
    0.30
];

nD = numel(delayLevels);


RMSE = zeros(nD,1);
MAXERR = zeros(nD,1);

MINFULL = zeros(nD,1);
MINEVAL = zeros(nD,1);

AOI = zeros(nD,1);


fprintf('\nEXP03B fixed-delay sweep\n\n');


for q = 1:nD

    cfg = defaultConfig();

    cfg.net.packetLoss = 0;

    cfg.net.delay = ...
        delayLevels(q);

    cfg.net.jitterStd = 0;


    fprintf( ...
        'Delay = %.0f ms\n', ...
        1000*cfg.net.delay);


    out = simSwarmNetworkQueued(cfg);

    M = computeSwarmMetrics(out,cfg);


    RMSE(q) = M.formationRMSE;

    MAXERR(q) = M.maxFormationError;

    MINFULL(q) = M.minSeparation;

    MINEVAL(q) = ...
        M.minSeparationEval;


    idx = out.t >= 8;

    AOI(q) = ...
        mean(out.meanAoI(idx));

end


%% ============================================================
% Analytical AoI
% ============================================================

cfg0 = defaultConfig();

AOITheory = ...
    delayLevels + ...
    cfg0.net.commPeriod/2;


%% ============================================================
% Summary
% ============================================================

fprintf('\n');

fprintf([ ...
    'Delay   RMSE[m]   MaxErr[m]  ', ...
    'MinFull[m] MinEval[m] AoI[s]\n']);


for q = 1:nD

    fprintf( ...
        '%4.0fms  %.4f    %.4f     %.4f     %.4f    %.3f\n', ...
        1000*delayLevels(q), ...
        RMSE(q), ...
        MAXERR(q), ...
        MINFULL(q), ...
        MINEVAL(q), ...
        AOI(q));

end


%% ============================================================
% Delay vs formation error
% ============================================================

figure;

plot( ...
    1000*delayLevels, ...
    RMSE, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Communication delay [ms]');
ylabel('Formation RMSE [m]');

title('EXP03B delay vs formation error');


%% ============================================================
% Delay vs AoI
% ============================================================

figure;

plot( ...
    1000*delayLevels, ...
    AOI, ...
    'o-', ...
    'LineWidth',1.3);

hold on;

plot( ...
    1000*delayLevels, ...
    AOITheory, ...
    '--', ...
    'LineWidth',1.3);

grid on;

xlabel('Communication delay [ms]');
ylabel('Mean AoI [s]');

title('EXP03B delay vs Age of Information');

legend( ...
    'simulation', ...
    'expected d + T_c/2', ...
    'Location','northwest');


%% ============================================================
% Safety
% ============================================================

figure;

plot( ...
    1000*delayLevels, ...
    MINEVAL, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Communication delay [ms]');
ylabel('Minimum separation after 8 s [m]');

title('EXP03B delay vs swarm separation');