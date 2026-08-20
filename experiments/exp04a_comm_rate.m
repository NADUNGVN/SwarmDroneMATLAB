%% EXP04A - Periodic communication-rate / resource-budget sweep
%
% Purpose:
%   Characterize the trade-off between communication resources
%   and distributed swarm formation performance.
%
% Network conditions:
%
%   packet loss = 0
%   delay       = 0
%   jitter      = 0
%
% Only the periodic communication rate is changed.
%
% Metrics:
%   - Formation RMSE
%   - Maximum formation error
%   - Minimum separation (full mission)
%   - Minimum separation after transient
%   - Mean AoI
%   - P95 of network-mean AoI
%   - Total transmissions
%   - Measured total transmissions per second
%   - Measured per-channel communication rate
%   - Communication reduction relative to 50 Hz
%   - RMS swarm acceleration/control effort
%   - Formation pass/fail
%   - Safety pass/fail
%
% ============================================================

startup;

close all;


%% ============================================================
% Communication-rate sweep
% ============================================================

commRates = [
     2
     5
    10
    20
    50
];                              % [Hz]


commPeriods = ...
    1 ./ commRates;              % [s]


nR = numel(commRates);


%% ============================================================
% Thresholds
% ============================================================

formationThreshold = 0.10;      % [m]

safetyThreshold = 0.25;         % [m]


%% ============================================================
% Result storage
% ============================================================

RMSE = zeros(nR,1);

MAXERR = zeros(nR,1);

MINFULL = zeros(nR,1);

MINEVAL = zeros(nR,1);

AOIMEAN = zeros(nR,1);

AOIP95 = zeros(nR,1);

TXCOUNT = zeros(nR,1);

TXRATE_TOTAL = zeros(nR,1);

TXRATE_PER_CHANNEL = zeros(nR,1);

ARRIVALRATIO = zeros(nR,1);

EFFECTIVEUPDATE = zeros(nR,1);

CONTROL_RMS = zeros(nR,1);

FORMATIONFAIL = false(nR,1);

SAFETYFAIL = false(nR,1);


%% ============================================================
% Header
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP04A periodic communication-rate sweep\n');

fprintf( ...
    '============================================================\n\n');


fprintf('Network conditions\n');

fprintf('  Packet loss : 0 %%\n');
fprintf('  Delay       : 0 ms\n');
fprintf('  Jitter      : 0 ms\n\n');


%% ============================================================
% Sweep communication rate
% ============================================================

for iR = 1:nR

    cfg = defaultConfig();


    %% --------------------------------------------------------
    % Clean network
    % ---------------------------------------------------------

    cfg.net.packetLoss = 0;

    cfg.net.delay = 0;

    cfg.net.jitterStd = 0;


    %% --------------------------------------------------------
    % Periodic communication rate
    % ---------------------------------------------------------

    cfg.net.commPeriod = ...
        commPeriods(iR);


    fprintf( ...
        'Requested communication rate = %.1f Hz ', ...
        commRates(iR));

    fprintf( ...
        '(Tc = %.3f s)\n', ...
        cfg.net.commPeriod);


    %% --------------------------------------------------------
    % Simulation
    % ---------------------------------------------------------

    out = ...
        simSwarmNetworkQueued(cfg);


    %% --------------------------------------------------------
    % Swarm metrics
    % ---------------------------------------------------------

    M = ...
        computeSwarmMetrics(out,cfg);


    RMSE(iR) = ...
        M.formationRMSE;


    MAXERR(iR) = ...
        M.maxFormationError;


    MINFULL(iR) = ...
        M.minSeparation;


    MINEVAL(iR) = ...
        M.minSeparationEval;


    %% --------------------------------------------------------
    % Evaluation window
    % ---------------------------------------------------------

    idxEval = ...
        out.t >= 8.0;


    %% --------------------------------------------------------
    % AoI
    %
    % NOTE:
    % AOIP95 here is the 95th percentile of the
    % network-mean AoI time series, not individual-link AoI.
    % ---------------------------------------------------------

    aoiEval = ...
        out.meanAoI(idxEval);


    AOIMEAN(iR) = ...
        mean(aoiEval);


    AOIP95(iR) = ...
        prctile(aoiEval,95);


    %% --------------------------------------------------------
    % Communication cost
    % ---------------------------------------------------------

    TXCOUNT(iR) = ...
        out.txCount;


    missionTime = ...
        out.t(end) - out.t(1);


    TXRATE_TOTAL(iR) = ...
        out.txCount / ...
        max(missionTime,eps);


    % Number of directed communication channels:
    %
    %   neighbor transmissions:
    %       nnz(A)
    %
    %   leader-to-pinned-follower transmissions:
    %       sum(pin)
    %
    nChannels = ...
        nnz(cfg.swarm.A) ...
        + sum(cfg.swarm.pin);


    TXRATE_PER_CHANNEL(iR) = ...
        TXRATE_TOTAL(iR) / ...
        max(nChannels,1);


    %% --------------------------------------------------------
    % Network delivery statistics
    % ---------------------------------------------------------

    ARRIVALRATIO(iR) = ...
        out.arrivalRatio;


    EFFECTIVEUPDATE(iR) = ...
        out.effectiveUpdateRatio;


    %% --------------------------------------------------------
    % Control effort
    %
    % RMS norm of commanded follower acceleration
    % after formation-acquisition transient.
    % ---------------------------------------------------------

    Aeval = ...
        out.A( ...
        idxEval, ...
        2:cfg.swarm.N, ...
        :);


    accelNormSq = ...
        sum(Aeval.^2,3);


    CONTROL_RMS(iR) = ...
        sqrt(mean(accelNormSq(:)));


    %% --------------------------------------------------------
    % Failure conditions
    % ---------------------------------------------------------

    FORMATIONFAIL(iR) = ...
        RMSE(iR) > ...
        formationThreshold;


    SAFETYFAIL(iR) = ...
        MINEVAL(iR) < ...
        safetyThreshold;

end


%% ============================================================
% Communication reduction
%
% Highest communication-rate condition is used as reference.
% In this experiment this should be 50 Hz.
% ============================================================

[~,idxHighestRate] = ...
    max(commRates);


txReference = ...
    TXCOUNT(idxHighestRate);


COMM_REDUCTION = ...
    100 * ...
    (1 - TXCOUNT / ...
    max(txReference,1));


%% ============================================================
% Ideal AoI reference
%
% For:
%
%   zero packet loss
%   zero communication delay
%   perfectly periodic communication
%
% mean AoI ~= Tc / 2
%
% Because the simulation timestep is dt = 0.02 s,
% rates whose periods are not integer multiples of dt may
% show small scheduler discretization differences.
% ============================================================

AOI_IDEAL = ...
    commPeriods / 2;


%% ============================================================
% Print summary
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP04A communication-resource results\n');

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'Rate   MeasRate RMSE[m] MaxErr[m] ', ...
    'MinFull MinEval AoImean AoIP95 ', ...
    'TxCount CommRed EffUpdate CtrlRMS FormFail SafeFail\n']);


fprintf([ ...
    '-----  -------- ------- --------- ', ...
    '------- ------- ------- ------ ', ...
    '------- ------- --------- ------- -------- --------\n']);


for iR = 1:nR

    fprintf( ...
        '%4.0fHz  %7.2f  %.4f   %.4f   %.4f  %.4f  %.3f   %.3f   %6.0f   %6.1f%%   %.3f    %.4f    %d        %d\n', ...
        commRates(iR), ...
        TXRATE_PER_CHANNEL(iR), ...
        RMSE(iR), ...
        MAXERR(iR), ...
        MINFULL(iR), ...
        MINEVAL(iR), ...
        AOIMEAN(iR), ...
        AOIP95(iR), ...
        TXCOUNT(iR), ...
        COMM_REDUCTION(iR), ...
        EFFECTIVEUPDATE(iR), ...
        CONTROL_RMS(iR), ...
        FORMATIONFAIL(iR), ...
        SAFETYFAIL(iR));

end


%% ============================================================
% AoI sanity validation
% ============================================================

AOI_ERROR = ...
    abs(AOIMEAN - AOI_IDEAL);


fprintf('\n');

fprintf('AoI sanity validation\n');

fprintf( ...
    '  Mean |simulation - Tc/2| : %.6f s\n', ...
    mean(AOI_ERROR));

fprintf( ...
    '  Max  |simulation - Tc/2| : %.6f s\n', ...
    max(AOI_ERROR));


%% ============================================================
% Find lowest communication rate satisfying requirements
% ============================================================

validCondition = ...
    (RMSE <= formationThreshold) ...
    & ...
    (MINEVAL >= safetyThreshold);


validIdx = ...
    find(validCondition);


fprintf('\n');

fprintf('Resource-performance operating point\n');


if isempty(validIdx)

    fprintf( ...
        '  No tested communication rate satisfies both constraints.\n');

    minValidRate = NaN;

else

    [minValidRate,localIdx] = ...
        min(commRates(validIdx));

    bestIdx = ...
        validIdx(localIdx);


    fprintf( ...
        '  Lowest tested valid rate : %.1f Hz\n', ...
        minValidRate);

    fprintf( ...
        '  Formation RMSE           : %.4f m\n', ...
        RMSE(bestIdx));

    fprintf( ...
        '  Min separation (eval)    : %.4f m\n', ...
        MINEVAL(bestIdx));

    fprintf( ...
        '  Mean AoI                 : %.3f s\n', ...
        AOIMEAN(bestIdx));

    fprintf( ...
        '  Communication reduction  : %.1f %% vs %.0f Hz\n', ...
        COMM_REDUCTION(bestIdx), ...
        commRates(idxHighestRate));

end


%% ============================================================
% Figure 1
% Communication rate vs formation RMSE
% ============================================================

figure;

plot( ...
    commRates, ...
    RMSE, ...
    'o-', ...
    'LineWidth',1.3);

hold on;

yline( ...
    formationThreshold, ...
    '--');

grid on;

xlabel('Communication rate [Hz]');

ylabel('Formation RMSE [m]');

title('EXP04A communication rate vs formation accuracy');

legend( ...
    'periodic communication', ...
    'formation threshold', ...
    'Location','best');


%% ============================================================
% Figure 2
% Communication rate vs AoI
% ============================================================

figure;

plot( ...
    commRates, ...
    AOIMEAN, ...
    'o-', ...
    'LineWidth',1.3);

hold on;

plot( ...
    commRates, ...
    AOI_IDEAL, ...
    '--', ...
    'LineWidth',1.2);

grid on;

xlabel('Communication rate [Hz]');

ylabel('Mean AoI [s]');

title('EXP04A communication rate vs Age of Information');

legend( ...
    'simulation', ...
    'ideal T_c / 2', ...
    'Location','best');


%% ============================================================
% Figure 3
% Resource-performance frontier
%
% x-axis:
%   communication cost
%
% y-axis:
%   formation error
%
% Desired direction:
%   bottom-left
% ============================================================

figure;

plot( ...
    TXRATE_TOTAL, ...
    RMSE, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Total packet transmissions per second');

ylabel('Formation RMSE [m]');

title('EXP04A communication-performance frontier');


for iR = 1:nR

    text( ...
        TXRATE_TOTAL(iR), ...
        RMSE(iR), ...
        sprintf('  %.0f Hz', ...
        commRates(iR)));

end


%% ============================================================
% Figure 4
% Communication reduction vs formation RMSE
% ============================================================

figure;

plot( ...
    COMM_REDUCTION, ...
    RMSE, ...
    'o-', ...
    'LineWidth',1.3);

hold on;

yline( ...
    formationThreshold, ...
    '--');

grid on;

xlabel('Communication reduction vs 50 Hz [%]');

ylabel('Formation RMSE [m]');

title('EXP04A communication saving vs formation accuracy');


%% ============================================================
% Figure 5
% Communication rate vs minimum separation
% ============================================================

figure;

plot( ...
    commRates, ...
    MINEVAL, ...
    'o-', ...
    'LineWidth',1.3);

hold on;

yline( ...
    safetyThreshold, ...
    '--');

grid on;

xlabel('Communication rate [Hz]');

ylabel('Minimum separation after t >= 8 s [m]');

title('EXP04A communication rate vs swarm safety');

legend( ...
    'minimum separation', ...
    'safety threshold', ...
    'Location','best');


%% ============================================================
% Figure 6
% Communication rate vs control effort
% ============================================================

figure;

plot( ...
    commRates, ...
    CONTROL_RMS, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Communication rate [Hz]');

ylabel('RMS commanded acceleration [m/s^2]');

title('EXP04A communication rate vs control effort');


%% ============================================================
% Figure 7
% RMSE versus AoI
% ============================================================

figure;

plot( ...
    AOIMEAN, ...
    RMSE, ...
    'o-', ...
    'LineWidth',1.3);

grid on;

xlabel('Mean AoI [s]');

ylabel('Formation RMSE [m]');

title('EXP04A formation accuracy versus information freshness');


%% ============================================================
% End
% ============================================================

fprintf('\n');
fprintf('EXP04A completed.\n');
fprintf('\n');