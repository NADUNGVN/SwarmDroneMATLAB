%% EXP05A - Baseline event-triggered communication
%
% Purpose:
%
%   Compare periodic communication with a simple
%   state-change event-triggered communication policy.
%
% EXP05A uses a CLEAN network:
%
%   packet loss = 0
%   delay       = 0
%   jitter      = 0
%
% This isolates the communication policy itself.
%
%
% Event trigger:
%
%   SEND if
%
%       ||p(t)-p(lastTx)|| >= epsPos
%
%   OR
%
%       ||v(t)-v(lastTx)|| >= epsVel
%
%   OR
%
%       timeSinceLastTx >= maxSilence
%
%
% EXP05A is NOT yet the proposed AoI-aware method.
%
% It is the conventional event-triggered baseline that will
% later be compared against an AoI-aware policy.
%
% ============================================================

startup;

close all;

%% ============================================================
% Result persistence
%
% Creates results/exp05a_event_triggered/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

R = startExperiment('exp05a_event_triggered');




%% ============================================================
% Network conditions
% ============================================================

packetLoss = 0;

fixedDelay = 0;

jitterStd = 0;


%% ============================================================
% Periodic baselines
%
% Recomputed here to guarantee a direct comparison using the
% same simulator/configuration.
% ============================================================

periodicRates = [
     5
    10
    20
    50
];

nPeriodic = ...
    numel(periodicRates);


%% ============================================================
% Event-trigger profiles
%
% Increasing threshold produces progressively more aggressive
% communication saving.
%
% maxSilence guarantees that communication cannot remain silent
% indefinitely.
%
% ============================================================

eventPosThresholds = [
    0.01
    0.02
    0.04
    0.08
];                              % [m]


eventVelThresholds = [
    0.02
    0.04
    0.08
    0.16
];                              % [m/s]


eventMaxSilence = [
    0.50
    0.50
    0.50
    0.50
];                              % [s]


nEvent = ...
    numel(eventPosThresholds);


%% ============================================================
% Performance thresholds
% ============================================================

formationThreshold = ...
    0.10;                       % [m]

safetyThreshold = ...
    0.25;                       % [m]


%% ============================================================
% Periodic result arrays
% ============================================================

pRMSE = zeros(nPeriodic,1);

pMAXERR = zeros(nPeriodic,1);

pMINEVAL = zeros(nPeriodic,1);

pAOI = zeros(nPeriodic,1);

pTXCOUNT = zeros(nPeriodic,1);

pTXRATE = zeros(nPeriodic,1);

pCONTROL = zeros(nPeriodic,1);


%% ============================================================
% Event-trigger result arrays
% ============================================================

eRMSE = zeros(nEvent,1);

eMAXERR = zeros(nEvent,1);

eMINEVAL = zeros(nEvent,1);

eAOI = zeros(nEvent,1);

eAOIP95 = zeros(nEvent,1);

eTXCOUNT = zeros(nEvent,1);

eTXRATE = zeros(nEvent,1);

eCONTROL = zeros(nEvent,1);

eSUPPRESSION = zeros(nEvent,1);

ePOSREASON = zeros(nEvent,1);

eVELREASON = zeros(nEvent,1);

eTIMEOUTREASON = zeros(nEvent,1);

eFORMATIONFAIL = false(nEvent,1);

eSAFETYFAIL = false(nEvent,1);


%% ============================================================
% Header
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP05A baseline event-triggered communication\n');

fprintf( ...
    '============================================================\n\n');


fprintf('Network conditions\n');

fprintf('  Packet loss : 0 %%\n');

fprintf('  Delay       : 0 ms\n');

fprintf('  Jitter      : 0 ms\n\n');


%% ============================================================
% Determine number of directed communication channels
% ============================================================

cfg0 = ...
    defaultConfig();


nChannels = ...
    nnz(cfg0.swarm.A) ...
    + sum(cfg0.swarm.pin);


fprintf( ...
    'Directed communication channels : %d\n\n', ...
    nChannels);


%% ============================================================
% PERIODIC BASELINES
% ============================================================

fprintf( ...
    '------------------------------------------------------------\n');

fprintf( ...
    'Periodic communication baselines\n');

fprintf( ...
    '------------------------------------------------------------\n');


for iP = 1:nPeriodic

    cfg = ...
        defaultConfig();


    cfg.net.packetLoss = ...
        packetLoss;

    cfg.net.delay = ...
        fixedDelay;

    cfg.net.jitterStd = ...
        jitterStd;


    cfg.net.commPeriod = ...
        1 / periodicRates(iP);


    fprintf( ...
        'Periodic rate = %.0f Hz\n', ...
        periodicRates(iP));


    %% --------------------------------------------------------
    % Simulation
    % ---------------------------------------------------------

    out = ...
        simSwarmNetworkQueued(cfg);


    M = ...
        computeSwarmMetrics( ...
        out,cfg);


    %% --------------------------------------------------------
    % Metrics
    % ---------------------------------------------------------

    pRMSE(iP) = ...
        M.formationRMSE;


    pMAXERR(iP) = ...
        M.maxFormationError;


    pMINEVAL(iP) = ...
        M.minSeparationEval;


    idxEval = ...
        out.t >= 8.0;


    pAOI(iP) = ...
        mean( ...
        out.meanAoI(idxEval));


    pTXCOUNT(iP) = ...
        out.txCount;


    missionTime = ...
        out.t(end) ...
        - out.t(1);


    pTXRATE(iP) = ...
        out.txCount ...
        / max(missionTime,eps) ...
        / nChannels;


    %% --------------------------------------------------------
    % Control effort
    % ---------------------------------------------------------

    Aeval = ...
        out.A( ...
        idxEval, ...
        2:cfg.swarm.N, ...
        :);


    accelNormSq = ...
        sum(Aeval.^2,3);


    pCONTROL(iP) = ...
        sqrt( ...
        mean(accelNormSq(:)));

end


%% ============================================================
% EVENT-TRIGGERED POLICIES
% ============================================================

fprintf('\n');

fprintf( ...
    '------------------------------------------------------------\n');

fprintf( ...
    'Event-triggered policies\n');

fprintf( ...
    '------------------------------------------------------------\n');


for iE = 1:nEvent

    cfg = ...
        defaultConfig();


    %% --------------------------------------------------------
    % Clean network
    % ---------------------------------------------------------

    cfg.net.packetLoss = ...
        packetLoss;

    cfg.net.delay = ...
        fixedDelay;

    cfg.net.jitterStd = ...
        jitterStd;


    %% --------------------------------------------------------
    % Event-trigger configuration
    % ---------------------------------------------------------

    cfg.event.posThreshold = ...
        eventPosThresholds(iE);


    cfg.event.velThreshold = ...
        eventVelThresholds(iE);


    cfg.event.maxSilence = ...
        eventMaxSilence(iE);


    fprintf( ...
        ['Event profile %d | ' ...
         'epsP = %.3f m | ' ...
         'epsV = %.3f m/s | ' ...
         'maxSilence = %.2f s\n'], ...
        iE, ...
        cfg.event.posThreshold, ...
        cfg.event.velThreshold, ...
        cfg.event.maxSilence);


    %% --------------------------------------------------------
    % Simulation
    % ---------------------------------------------------------

    out = ...
        simSwarmEventTriggered(cfg);


    M = ...
        computeSwarmMetrics( ...
        out,cfg);


    %% --------------------------------------------------------
    % Formation metrics
    % ---------------------------------------------------------

    eRMSE(iE) = ...
        M.formationRMSE;


    eMAXERR(iE) = ...
        M.maxFormationError;


    eMINEVAL(iE) = ...
        M.minSeparationEval;


    %% --------------------------------------------------------
    % AoI
    % ---------------------------------------------------------

    idxEval = ...
        out.t >= 8.0;


    aoiEval = ...
        out.meanAoI(idxEval);


    eAOI(iE) = ...
        mean(aoiEval);


    eAOIP95(iE) = ...
        prctile( ...
        aoiEval,95);


    %% --------------------------------------------------------
    % Communication usage
    % ---------------------------------------------------------

    eTXCOUNT(iE) = ...
        out.txCount;


    missionTime = ...
        out.t(end) ...
        - out.t(1);


    eTXRATE(iE) = ...
        out.txCount ...
        / max(missionTime,eps) ...
        / nChannels;


    %% --------------------------------------------------------
    % Trigger statistics
    % ---------------------------------------------------------

    eSUPPRESSION(iE) = ...
        out.suppressionRatio;


    ePOSREASON(iE) = ...
        out.positionTriggerRatio;


    eVELREASON(iE) = ...
        out.velocityTriggerRatio;


    eTIMEOUTREASON(iE) = ...
        out.timeoutTriggerRatio;


    %% --------------------------------------------------------
    % Control effort
    % ---------------------------------------------------------

    Aeval = ...
        out.A( ...
        idxEval, ...
        2:cfg.swarm.N, ...
        :);


    accelNormSq = ...
        sum(Aeval.^2,3);


    eCONTROL(iE) = ...
        sqrt( ...
        mean(accelNormSq(:)));


    %% --------------------------------------------------------
    % Failure
    % ---------------------------------------------------------

    eFORMATIONFAIL(iE) = ...
        eRMSE(iE) ...
        > formationThreshold;


    eSAFETYFAIL(iE) = ...
        eMINEVAL(iE) ...
        < safetyThreshold;

end


%% ============================================================
% Communication reduction
%
% 50-Hz periodic baseline is reference.
% ============================================================

idx50 = ...
    find( ...
    periodicRates == 50,1);


if isempty(idx50)

    error( ...
        'EXP05A requires a 50-Hz periodic reference.');

end


referenceTx = ...
    pTXCOUNT(idx50);


pCommReduction = ...
    100 ...
    * (1 ...
    - pTXCOUNT/referenceTx);


eCommReduction = ...
    100 ...
    * (1 ...
    - eTXCOUNT/referenceTx);


%% ============================================================
% Comparison against practical 10-Hz periodic baseline
% ============================================================

idx10 = ...
    find( ...
    periodicRates == 10,1);


if isempty(idx10)

    error( ...
        'EXP05A requires a 10-Hz periodic baseline.');

end


baseline10RMSE = ...
    pRMSE(idx10);


baseline10Tx = ...
    pTXCOUNT(idx10);


eSavingVs10 = ...
    100 ...
    * (1 ...
    - eTXCOUNT/baseline10Tx);


%% ============================================================
% Print periodic summary
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Periodic baseline results\n');

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'Rate  RMSE[m] MaxErr[m] MinEval ', ...
    'AoI[s] TxCount TxRate/ch CommRed CtrlRMS\n']);


fprintf([ ...
    '----  ------- --------- ------- ', ...
    '------ ------- --------- ------- -------\n']);


for iP = 1:nPeriodic

    fprintf( ...
        '%3.0fHz  %.4f   %.4f    %.4f  %.3f   %6.0f   %7.2f    %6.1f%%  %.4f\n', ...
        periodicRates(iP), ...
        pRMSE(iP), ...
        pMAXERR(iP), ...
        pMINEVAL(iP), ...
        pAOI(iP), ...
        pTXCOUNT(iP), ...
        pTXRATE(iP), ...
        pCommReduction(iP), ...
        pCONTROL(iP));

end


%% ============================================================
% Print event-trigger summary
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Event-triggered results\n');

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'ID epsP epsV RMSE[m] MaxErr MinEval ', ...
    'AoImean AoIP95 TxRate/ch CommRed SaveVs10 ', ...
    'Suppress PosTrig VelTrig Timeout FormFail SafeFail\n']);


fprintf([ ...
    '-- ---- ---- ------- ------ ------- ', ...
    '------- ------ --------- ------- -------- ', ...
    '-------- ------- ------- ------- -------- --------\n']);


for iE = 1:nEvent

    fprintf( ...
        ['%2d %.3f %.3f %.4f  %.4f  %.4f  ' ...
         '%.3f   %.3f   %7.2f    %6.1f%%   %6.1f%%  ' ...
         '%.3f    %.3f   %.3f   %.3f    %d        %d\n'], ...
        iE, ...
        eventPosThresholds(iE), ...
        eventVelThresholds(iE), ...
        eRMSE(iE), ...
        eMAXERR(iE), ...
        eMINEVAL(iE), ...
        eAOI(iE), ...
        eAOIP95(iE), ...
        eTXRATE(iE), ...
        eCommReduction(iE), ...
        eSavingVs10(iE), ...
        eSUPPRESSION(iE), ...
        ePOSREASON(iE), ...
        eVELREASON(iE), ...
        eTIMEOUTREASON(iE), ...
        eFORMATIONFAIL(iE), ...
        eSAFETYFAIL(iE));

end


%% ============================================================
% Find valid event-trigger configurations
% ============================================================

validEvent = ...
    (eRMSE <= formationThreshold) ...
    & ...
    (eMINEVAL >= safetyThreshold);


validIdx = ...
    find(validEvent);


fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Event-trigger resource-performance operating point\n');

fprintf( ...
    '============================================================\n\n');


if isempty(validIdx)

    fprintf( ...
        'No tested event-trigger profile satisfies both constraints.\n');


else

    %% --------------------------------------------------------
    % Among valid profiles, choose one with fewest packets
    % ---------------------------------------------------------

    [~,localIdx] = ...
        min( ...
        eTXCOUNT(validIdx));


    bestIdx = ...
        validIdx(localIdx);


    fprintf( ...
        'Best valid event profile : %d\n', ...
        bestIdx);


    fprintf( ...
        '  eps position           : %.3f m\n', ...
        eventPosThresholds(bestIdx));


    fprintf( ...
        '  eps velocity           : %.3f m/s\n', ...
        eventVelThresholds(bestIdx));


    fprintf( ...
        '  max silence            : %.3f s\n', ...
        eventMaxSilence(bestIdx));


    fprintf( ...
        '  Formation RMSE         : %.4f m\n', ...
        eRMSE(bestIdx));


    fprintf( ...
        '  Min separation         : %.4f m\n', ...
        eMINEVAL(bestIdx));


    fprintf( ...
        '  Effective rate/channel : %.2f Hz\n', ...
        eTXRATE(bestIdx));


    fprintf( ...
        '  Mean AoI               : %.3f s\n', ...
        eAOI(bestIdx));


    fprintf( ...
        '  Reduction vs 50 Hz     : %.1f %%\n', ...
        eCommReduction(bestIdx));


    fprintf( ...
        '  Saving vs 10 Hz        : %.1f %%\n', ...
        eSavingVs10(bestIdx));

end


%% ============================================================
% Figure 1
% Communication-performance frontier
% ============================================================

figure;

hold on;
grid on;


plot( ...
    pTXRATE, ...
    pRMSE, ...
    'o-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    'periodic');


plot( ...
    eTXRATE, ...
    eRMSE, ...
    's-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    'event-triggered');


yline( ...
    formationThreshold, ...
    '--', ...
    'DisplayName', ...
    'formation threshold');


xlabel( ...
    'Effective transmission rate per channel [Hz]');


ylabel( ...
    'Formation RMSE [m]');


title( ...
    'EXP05A communication-performance frontier');


legend('Location','best');


%% ============================================================
% Figure 2
% Communication reduction versus formation error
% ============================================================

figure;

hold on;
grid on;


plot( ...
    pCommReduction, ...
    pRMSE, ...
    'o-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    'periodic');


plot( ...
    eCommReduction, ...
    eRMSE, ...
    's-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    'event-triggered');


yline( ...
    formationThreshold, ...
    '--', ...
    'DisplayName', ...
    'formation threshold');


xlabel( ...
    'Communication reduction vs 50 Hz [%]');


ylabel( ...
    'Formation RMSE [m]');


title( ...
    'EXP05A communication saving versus formation accuracy');


legend('Location','best');


%% ============================================================
% Figure 3
% AoI versus formation performance
% ============================================================

figure;

hold on;
grid on;


plot( ...
    pAOI, ...
    pRMSE, ...
    'o-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    'periodic');


plot( ...
    eAOI, ...
    eRMSE, ...
    's-', ...
    'LineWidth',1.3, ...
    'DisplayName', ...
    'event-triggered');


xlabel( ...
    'Mean AoI [s]');


ylabel( ...
    'Formation RMSE [m]');


title( ...
    'EXP05A information freshness versus formation accuracy');


legend('Location','best');


%% ============================================================
% Figure 4
% Trigger-reason composition
% ============================================================

figure;


triggerComposition = [
    ePOSREASON ...
    eVELREASON ...
    eTIMEOUTREASON
];


bar( ...
    1:nEvent, ...
    triggerComposition, ...
    'stacked');


grid on;


xlabel( ...
    'Event-trigger profile');


ylabel( ...
    'Fraction of transmissions');


title( ...
    'EXP05A event-trigger reason composition');


legend( ...
    {'Position trigger', ...
     'Velocity trigger', ...
     'Timeout trigger'}, ...
    'Location','best');


%% ============================================================
% Figure 5
% Effective transmission rate
% ============================================================

figure;


bar( ...
    1:nEvent, ...
    eTXRATE);


grid on;


xlabel( ...
    'Event-trigger profile');


ylabel( ...
    'Effective transmission rate per channel [Hz]');


title( ...
    'EXP05A event-trigger communication usage');


%% ============================================================
% Figure 6
% Minimum separation
% ============================================================

figure;


plot( ...
    eTXRATE, ...
    eMINEVAL, ...
    'o-', ...
    'LineWidth',1.3);


hold on;


yline( ...
    safetyThreshold, ...
    '--');


grid on;


xlabel( ...
    'Effective transmission rate per channel [Hz]');


ylabel( ...
    'Minimum separation after t >= 8 s [m]');


title( ...
    'EXP05A communication usage versus swarm safety');


%% ============================================================
% End
% ============================================================

fprintf('\n');

fprintf( ...
    'EXP05A completed.\n');

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
