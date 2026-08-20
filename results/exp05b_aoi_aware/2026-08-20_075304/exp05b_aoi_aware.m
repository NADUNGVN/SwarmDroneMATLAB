%% EXP05B - AoI-aware event-triggered communication
%
% Purpose:
%
%   Compare:
%
%       1. Periodic communication
%       2. Conventional event-triggered communication
%       3. AoI-aware event-triggered communication
%
% under clean and impaired communication networks.
%
%
% EXP05A baseline event trigger:
%
%   epsP       = 0.04 m
%   epsV       = 0.08 m/s
%   maxSilence = 0.50 s
%
%
% AoI-aware trigger:
%
%   SEND if:
%
%       position change >= epsP
%
%   OR
%
%       velocity change >= epsV
%
%   OR
%
%       receiver AoI >= AoI threshold
%
%   OR
%
%       maximum silence reached
%
%
% Primary research question:
%
%   Can explicit AoI awareness recover robustness under
%   packet loss / delay while using fewer transmissions than
%   periodic communication?
%
%
% Debug:
%
%   numSeeds = 3
%
% Final:
%
%   numSeeds = 20
%
% ============================================================

startup;

close all;

%% ============================================================
% Result persistence
%
% Creates results/exp05b_aoi_aware/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

expRun = startExperiment('exp05b_aoi_aware');




%% ============================================================
% Monte Carlo
% ============================================================

numSeeds = 20;


%% ============================================================
% Performance thresholds
% ============================================================

formationThreshold = ...
    0.10;                           % [m]


safetyThreshold = ...
    0.25;                           % [m]


robustFailureLimit = ...
    0.05;


%% ============================================================
% Network scenarios
%
% 1 = clean
% 2 = moderate impairment
% 3 = stressed impairment
%
% These scenarios are already characterized in EXP04B.
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
];                                  % [s]


scenarioJitter = [
    0
    0
    0
];


nScenario = ...
    numel(scenarioLoss);


%% ============================================================
% Periodic communication baselines
%
% 10 Hz:
%   practical baseline
%
% 20 Hz:
%   higher-resource robust baseline
% ============================================================

periodicRates = [
    10
    20
];


nPeriodic = ...
    numel(periodicRates);


%% ============================================================
% Conventional event-trigger baseline
%
% Same state-change thresholds as the proposed method, so the two
% policies differ only in the AoI mechanism (see EXP05D for the
% full threshold sweep / Pareto frontier of both policies).
% ============================================================

eventPosThreshold = ...
    0.05;


eventVelThreshold = ...
    0.10;


eventMaxSilence = ...
    0.50;


%% ============================================================
% AoI-aware profiles
%
% State-change thresholds are identical to the conventional
% event-trigger baseline above (0.05 m / 0.10 m/s), matching
% EXP05C and EXP06A. Only the AoI mechanism differs, so the
% comparison is not confounded by different trigger sensitivity.
% ============================================================

% Fixed AoI threshold
fixedAoIThreshold = 0.12;     % [s]

aoiPosThresholds = 0.05;
aoiVelThresholds = 0.10;
aoiCooldowns      = 0.10;

nAoI = 1;


%% ============================================================
% AoI-aware common parameters
% ============================================================

aoiMaxSilence = ...
    eventMaxSilence;

% Placeholder only. The value actually used is taken from
% aoiCooldowns(iA) where the AoI configuration is assembled.
aoiMinInterTx = ...
    0.02;


%% ============================================================
% Number of communication channels
% ============================================================

cfg0 = ...
    defaultConfig();


nChannels = ...
    nnz(cfg0.swarm.A) ...
    + sum(cfg0.swarm.pin);


%% ============================================================
% PERIODIC result arrays
%
% Dimensions:
%
%   seed x periodicRate x scenario
% ============================================================

pRMSE = zeros( ...
    numSeeds,nPeriodic,nScenario);


pMAXERR = zeros( ...
    numSeeds,nPeriodic,nScenario);


pMINEVAL = zeros( ...
    numSeeds,nPeriodic,nScenario);


pAOI = zeros( ...
    numSeeds,nPeriodic,nScenario);


pTXRATE = zeros( ...
    numSeeds,nPeriodic,nScenario);


pTXCOUNT = zeros( ...
    numSeeds,nPeriodic,nScenario);


pPDR = zeros( ...
    numSeeds,nPeriodic,nScenario);


pFORMATIONFAIL = false( ...
    numSeeds,nPeriodic,nScenario);


pSAFETYFAIL = false( ...
    numSeeds,nPeriodic,nScenario);


%% ============================================================
% EVENT result arrays
%
% Dimensions:
%
%   seed x scenario
% ============================================================

eRMSE = zeros( ...
    numSeeds,nScenario);


eMAXERR = zeros( ...
    numSeeds,nScenario);


eMINEVAL = zeros( ...
    numSeeds,nScenario);


eAOI = zeros( ...
    numSeeds,nScenario);


eTXRATE = zeros( ...
    numSeeds,nScenario);


eTXCOUNT = zeros( ...
    numSeeds,nScenario);


ePDR = zeros( ...
    numSeeds,nScenario);


eFORMATIONFAIL = false( ...
    numSeeds,nScenario);


eSAFETYFAIL = false( ...
    numSeeds,nScenario);


%% ============================================================
% AOI-AWARE result arrays
%
% Dimensions:
%
%   seed x AoI profile x scenario
% ============================================================

aRMSE = zeros( ...
    numSeeds,nAoI,nScenario);


aMAXERR = zeros( ...
    numSeeds,nAoI,nScenario);


aMINEVAL = zeros( ...
    numSeeds,nAoI,nScenario);


aAOIMEAN = zeros( ...
    numSeeds,nAoI,nScenario);


aAOIP95 = zeros( ...
    numSeeds,nAoI,nScenario);


aAOIMAX = zeros( ...
    numSeeds,nAoI,nScenario);


aTXRATE = zeros( ...
    numSeeds,nAoI,nScenario);


aTXCOUNT = zeros( ...
    numSeeds,nAoI,nScenario);


aPDR = zeros( ...
    numSeeds,nAoI,nScenario);


aSUPPRESSION = zeros( ...
    numSeeds,nAoI,nScenario);


aPOSITRIG = zeros( ...
    numSeeds,nAoI,nScenario);


aVELTRIG = zeros( ...
    numSeeds,nAoI,nScenario);


aAOITRIG = zeros( ...
    numSeeds,nAoI,nScenario);


aTIMEOUTTRIG = zeros( ...
    numSeeds,nAoI,nScenario);


aFORMATIONFAIL = false( ...
    numSeeds,nAoI,nScenario);


aSAFETYFAIL = false( ...
    numSeeds,nAoI,nScenario);


%% ------------------------------------------------------------
% ACK-feedback diagnostics
%
% ackSyncMissCount counts occasions where the transmitter could not
% match a receiver acceptance to a pending attempt; it should be 0.
% ------------------------------------------------------------

aACKMISS = zeros( ...
    numSeeds,nAoI,nScenario);


aACKUPDATE = zeros( ...
    numSeeds,nAoI,nScenario);


%% ============================================================
% Header
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'EXP05B AoI-aware event-triggered communication\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Seeds       : %d\n', ...
    numSeeds);


fprintf( ...
    'Event epsP  : %.3f m\n', ...
    eventPosThreshold);


fprintf( ...
    'Event epsV  : %.3f m/s\n', ...
    eventVelThreshold);


fprintf( ...
    'Max silence : %.3f s\n\n', ...
    eventMaxSilence);


fprintf( ...
    'Network scenarios\n');


for iS = 1:nScenario

    fprintf( ...
        '  %d. %-10s : loss %.0f %% | delay %.0f ms\n', ...
        iS, ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), ...
        1000*scenarioDelay(iS));

end


fprintf('\n');


%% ============================================================
% PERIODIC BASELINES
% ============================================================

fprintf( ...
    '------------------------------------------------------------\n');

fprintf( ...
    'Periodic baselines\n');

fprintf( ...
    '------------------------------------------------------------\n');


for iS = 1:nScenario

    for iP = 1:nPeriodic


        fprintf( ...
            '%-10s | periodic %2.0f Hz\n', ...
            scenarioNames{iS}, ...
            periodicRates(iP));


        for s = 1:numSeeds


            cfg = ...
                defaultConfig();


            cfg.net.commPeriod = ...
                1 / periodicRates(iP);


            cfg.net.packetLoss = ...
                scenarioLoss(iS);


            cfg.net.delay = ...
                scenarioDelay(iS);


            cfg.net.jitterStd = ...
                scenarioJitter(iS);


            cfg.net.seed = ...
                800000 ...
                + 10000*iS ...
                + s;


            out = ...
                simSwarmNetworkQueued(cfg);


            M = ...
                computeSwarmMetrics( ...
                out,cfg);


            idxEval = ...
                out.t >= 8;


            pRMSE(s,iP,iS) = ...
                M.formationRMSE;


            pMAXERR(s,iP,iS) = ...
                M.maxFormationError;


            pMINEVAL(s,iP,iS) = ...
                M.minSeparationEval;


            pAOI(s,iP,iS) = ...
                mean( ...
                out.meanAoI(idxEval));


            missionTime = ...
                out.t(end) ...
                - out.t(1);


            pTXCOUNT(s,iP,iS) = ...
                out.txCount;


            pTXRATE(s,iP,iS) = ...
                out.txCount ...
                / max(missionTime,eps) ...
                / nChannels;


            pPDR(s,iP,iS) = ...
                out.PDR;


            pFORMATIONFAIL(s,iP,iS) = ...
                M.formationRMSE ...
                > formationThreshold;


            pSAFETYFAIL(s,iP,iS) = ...
                M.minSeparationEval ...
                < safetyThreshold;

        end

    end

end


%% ============================================================
% CONVENTIONAL EVENT-TRIGGER BASELINE
% ============================================================

fprintf('\n');

fprintf( ...
    '------------------------------------------------------------\n');

fprintf( ...
    'Conventional event-trigger baseline\n');

fprintf( ...
    '------------------------------------------------------------\n');


for iS = 1:nScenario


    fprintf( ...
        '%-10s | conventional event trigger\n', ...
        scenarioNames{iS});


    for s = 1:numSeeds


        cfg = ...
            defaultConfig();


        cfg.net.packetLoss = ...
            scenarioLoss(iS);


        cfg.net.delay = ...
            scenarioDelay(iS);


        cfg.net.jitterStd = ...
            scenarioJitter(iS);


        cfg.net.seed = ...
            800000 ...
            + 10000*iS ...
            + s;


        cfg.event.posThreshold = ...
            eventPosThreshold;


        cfg.event.velThreshold = ...
            eventVelThreshold;


        cfg.event.maxSilence = ...
            eventMaxSilence;


        out = ...
            simSwarmEventTriggered(cfg);


        M = ...
            computeSwarmMetrics( ...
            out,cfg);


        idxEval = ...
            out.t >= 8;


        eRMSE(s,iS) = ...
            M.formationRMSE;


        eMAXERR(s,iS) = ...
            M.maxFormationError;


        eMINEVAL(s,iS) = ...
            M.minSeparationEval;


        eAOI(s,iS) = ...
            mean( ...
            out.meanAoI(idxEval));


        missionTime = ...
            out.t(end) ...
            - out.t(1);


        eTXCOUNT(s,iS) = ...
            out.txCount;


        eTXRATE(s,iS) = ...
            out.txCount ...
            / max(missionTime,eps) ...
            / nChannels;


        ePDR(s,iS) = ...
            out.PDR;


        eFORMATIONFAIL(s,iS) = ...
            M.formationRMSE ...
            > formationThreshold;


        eSAFETYFAIL(s,iS) = ...
            M.minSeparationEval ...
            < safetyThreshold;

    end

end


%% ============================================================
% AOI-AWARE EVENT TRIGGER
% ============================================================

fprintf('\n');

fprintf( ...
    '------------------------------------------------------------\n');

fprintf( ...
    'AoI-aware trigger sweep\n');

fprintf( ...
    '------------------------------------------------------------\n');


for iS = 1:nScenario

    for iA = 1:nAoI


        fprintf( ...
            '%-10s | epsP = %.3f | epsV = %.3f | AoI cooldown = %.3f s\n', ...
            scenarioNames{iS}, ...
            aoiPosThresholds(iA), ...
            aoiVelThresholds(iA), ...
            aoiCooldowns(iA));


        for s = 1:numSeeds


            cfg = ...
                defaultConfig();


            %% ------------------------------------------------
            % Network
            % -------------------------------------------------

            cfg.net.packetLoss = ...
                scenarioLoss(iS);


            cfg.net.delay = ...
                scenarioDelay(iS);


            cfg.net.jitterStd = ...
                scenarioJitter(iS);


            cfg.net.seed = ...
                800000 ...
                + 10000*iS ...
                + s;


            %% ------------------------------------------------
            % AoI-aware policy
            % -------------------------------------------------

            cfg.aoiEvent.posThreshold = ...
                aoiPosThresholds(iA);
            
            cfg.aoiEvent.velThreshold = ...
                aoiVelThresholds(iA);
            
            cfg.aoiEvent.aoiThreshold = ...
                fixedAoIThreshold;


            cfg.aoiEvent.maxSilence = ...
                aoiMaxSilence;


            cfg.aoiEvent.aoiMinInterTx = ...
                aoiCooldowns(iA);


            %% ------------------------------------------------
            % Simulation
            % -------------------------------------------------

            out = ...
                simSwarmAoIAware(cfg);


            M = ...
                computeSwarmMetrics( ...
                out,cfg);


            idxEval = ...
                out.t >= 8;


            %% ------------------------------------------------
            % Formation
            % -------------------------------------------------

            aRMSE(s,iA,iS) = ...
                M.formationRMSE;


            aMAXERR(s,iA,iS) = ...
                M.maxFormationError;


            aMINEVAL(s,iA,iS) = ...
                M.minSeparationEval;


            %% ------------------------------------------------
            % Mean AoI
            % -------------------------------------------------

            aAOIMEAN(s,iA,iS) = ...
                mean( ...
                out.meanAoI(idxEval));


            %% ------------------------------------------------
            % TRUE LINK-LEVEL AoI samples
            % -------------------------------------------------

            linkAoI = ...
                collectLinkAoI( ...
                out, ...
                cfg, ...
                idxEval);


            aAOIP95(s,iA,iS) = ...
                prctile( ...
                linkAoI,95);


            aAOIMAX(s,iA,iS) = ...
                max(linkAoI);


            %% ------------------------------------------------
            % Communication cost
            % -------------------------------------------------

            aTXCOUNT(s,iA,iS) = ...
                out.txCount;


            aTXRATE(s,iA,iS) = ...
                out.txRatePerChannel;


            if isfield(out,'ackSyncMissCount')

                aACKMISS(s,iA,iS) = ...
                    out.ackSyncMissCount;

                aACKUPDATE(s,iA,iS) = ...
                    out.ackUpdateCount;

            end


            aPDR(s,iA,iS) = ...
                out.PDR;


            %% ------------------------------------------------
            % Trigger statistics
            % -------------------------------------------------

            aSUPPRESSION(s,iA,iS) = ...
                out.suppressionRatio;


            aPOSITRIG(s,iA,iS) = ...
                out.positionTriggerRatio;


            aVELTRIG(s,iA,iS) = ...
                out.velocityTriggerRatio;


            aAOITRIG(s,iA,iS) = ...
                out.aoiTriggerRatio;


            aTIMEOUTTRIG(s,iA,iS) = ...
                out.timeoutTriggerRatio;


            %% ------------------------------------------------
            % Failures
            % -------------------------------------------------

            aFORMATIONFAIL(s,iA,iS) = ...
                M.formationRMSE ...
                > formationThreshold;


            aSAFETYFAIL(s,iA,iS) = ...
                M.minSeparationEval ...
                < safetyThreshold;

        end

    end

end


%% ============================================================
% Aggregate PERIODIC
% ============================================================

meanPRMSE = ...
    squeeze(mean(pRMSE,1));


meanPMAXERR = ...
    squeeze(mean(pMAXERR,1));


meanPMINEVAL = ...
    squeeze(mean(pMINEVAL,1));


meanPAOI = ...
    squeeze(mean(pAOI,1));


meanPTXRATE = ...
    squeeze(mean(pTXRATE,1));


meanPTXCOUNT = ...
    squeeze(mean(pTXCOUNT,1));


meanPPDR = ...
    squeeze(mean(pPDR,1));


pFormFail = ...
    squeeze(mean(pFORMATIONFAIL,1));


pSafeFail = ...
    squeeze(mean(pSAFETYFAIL,1));


%% ============================================================
% Aggregate EVENT
% ============================================================

meanERMSE = ...
    mean(eRMSE,1);


stdERMSE = ...
    std(eRMSE,0,1);


meanEMAXERR = ...
    mean(eMAXERR,1);


meanEMINEVAL = ...
    mean(eMINEVAL,1);


meanEAOI = ...
    mean(eAOI,1);


meanETXRATE = ...
    mean(eTXRATE,1);


meanETXCOUNT = ...
    mean(eTXCOUNT,1);


meanEPDR = ...
    mean(ePDR,1);


eFormFail = ...
    mean(eFORMATIONFAIL,1);


eSafeFail = ...
    mean(eSAFETYFAIL,1);


%% ============================================================
% Aggregate AOI-AWARE
%
% reshape is used instead of squeeze so that dimensions remain:
%
%   nAoI x nScenario
%
% even when nAoI = 1.
% ============================================================

meanARMSE = ...
    reshape( ...
    mean(aRMSE,1), ...
    nAoI,nScenario);


stdARMSE = ...
    reshape( ...
    std(aRMSE,0,1), ...
    nAoI,nScenario);


meanAMAXERR = ...
    reshape( ...
    mean(aMAXERR,1), ...
    nAoI,nScenario);


meanAMINEVAL = ...
    reshape( ...
    mean(aMINEVAL,1), ...
    nAoI,nScenario);


meanAAOI = ...
    reshape( ...
    mean(aAOIMEAN,1), ...
    nAoI,nScenario);


meanAAOIP95 = ...
    reshape( ...
    mean(aAOIP95,1), ...
    nAoI,nScenario);


meanAAOIMAX = ...
    reshape( ...
    mean(aAOIMAX,1), ...
    nAoI,nScenario);


meanATXRATE = ...
    reshape( ...
    mean(aTXRATE,1), ...
    nAoI,nScenario);


meanATXCOUNT = ...
    reshape( ...
    mean(aTXCOUNT,1), ...
    nAoI,nScenario);


meanAPDR = ...
    reshape( ...
    mean(aPDR,1), ...
    nAoI,nScenario);


meanASUPPRESSION = ...
    reshape( ...
    mean(aSUPPRESSION,1), ...
    nAoI,nScenario);


meanAPOS = ...
    reshape( ...
    mean(aPOSITRIG,1), ...
    nAoI,nScenario);


meanAVEL = ...
    reshape( ...
    mean(aVELTRIG,1), ...
    nAoI,nScenario);


meanAAOITRIG = ...
    reshape( ...
    mean(aAOITRIG,1), ...
    nAoI,nScenario);


meanATIMEOUT = ...
    reshape( ...
    mean(aTIMEOUTTRIG,1), ...
    nAoI,nScenario);


aFormFail = ...
    reshape( ...
    mean(aFORMATIONFAIL,1), ...
    nAoI,nScenario);


aSafeFail = ...
    reshape( ...
    mean(aSAFETYFAIL,1), ...
    nAoI,nScenario);



%% ============================================================
% Print PERIODIC results
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Periodic baseline results\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Scenario   Rate RMSE[m] MaxErr MinEval AoI[s] TxRate PDR FormFail SafeFail\n');


fprintf( ...
    '---------- ---- ------- ------ ------- ------ ------ --- -------- --------\n');


for iS = 1:nScenario

    for iP = 1:nPeriodic

        fprintf( ...
            '%-10s %2.0fHz %.4f  %.4f  %.4f  %.3f  %5.2f  %.3f   %.2f     %.2f\n', ...
            scenarioNames{iS}, ...
            periodicRates(iP), ...
            meanPRMSE(iP,iS), ...
            meanPMAXERR(iP,iS), ...
            meanPMINEVAL(iP,iS), ...
            meanPAOI(iP,iS), ...
            meanPTXRATE(iP,iS), ...
            meanPPDR(iP,iS), ...
            pFormFail(iP,iS), ...
            pSafeFail(iP,iS));

    end

end


%% ============================================================
% Print conventional EVENT baseline
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Conventional event-trigger results\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Scenario   RMSE[m] StdRMSE MaxErr MinEval AoI[s] TxRate PDR FormFail SafeFail\n');


fprintf( ...
    '---------- ------- ------- ------ ------- ------ ------ --- -------- --------\n');


for iS = 1:nScenario

    fprintf( ...
        '%-10s %.4f  %.4f  %.4f  %.4f  %.3f  %5.2f  %.3f   %.2f     %.2f\n', ...
        scenarioNames{iS}, ...
        meanERMSE(iS), ...
        stdERMSE(iS), ...
        meanEMAXERR(iS), ...
        meanEMINEVAL(iS), ...
        meanEAOI(iS), ...
        meanETXRATE(iS), ...
        meanEPDR(iS), ...
        eFormFail(iS), ...
        eSafeFail(iS));

end


%% ============================================================
% Print AOI-AWARE results
% ============================================================

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'AoI-aware event-trigger results\n');

fprintf( ...
    '============================================================\n\n');


fprintf([ ...
    'Scenario   epsP epsV RMSE[m] StdRMSE MaxErr MinEval ', ...
    'AoImean AoIP95 AoImax TxRate PDR ', ...
    'Suppress Pos Vel AoI Timeout FormFail SafeFail\n']);


fprintf([ ...
    '---------- ----- ------- ------- ------ ------- ', ...
    '------- ------ ------ ------ --- ', ...
    '-------- --- --- --- ------- -------- --------\n']);


for iS = 1:nScenario

    for iA = 1:nAoI

        fprintf( ...
            ['%-10s %.3f %.3f %.4f %.4f  %.4f  %.4f  ' ...
             '%.3f   %.3f  %.3f  %5.2f  %.3f  ' ...
             '%.3f  %.3f %.3f %.3f %.3f   %.2f     %.2f\n'], ...
            scenarioNames{iS}, ...
            aoiPosThresholds(iA), ...
            aoiVelThresholds(iA), ...
            meanARMSE(iA,iS), ...
            stdARMSE(iA,iS), ...
            meanAMAXERR(iA,iS), ...
            meanAMINEVAL(iA,iS), ...
            meanAAOI(iA,iS), ...
            meanAAOIP95(iA,iS), ...
            meanAAOIMAX(iA,iS), ...
            meanATXRATE(iA,iS), ...
            meanAPDR(iA,iS), ...
            meanASUPPRESSION(iA,iS), ...
            meanAPOS(iA,iS), ...
            meanAVEL(iA,iS), ...
            meanAAOITRIG(iA,iS), ...
            meanATIMEOUT(iA,iS), ...
            aFormFail(iA,iS), ...
            aSafeFail(iA,iS));

    end

end


%% ============================================================
% Find best AoI-aware profile for each scenario
%
% Robust validity:
%
%   formation failure <= 5 %
%   safety failure    <= 5 %
%
% Among valid profiles:
%
%   choose minimum transmission rate.
% ============================================================

bestAoIIdx = ...
    nan(nScenario,1);
%% ============================================================
% Reference communication costs
% ============================================================

idx10 = ...
    find(periodicRates == 10,1);

idx20 = ...
    find(periodicRates == 20,1);

fprintf('\n');

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Best robust AoI-aware operating points\n');

fprintf( ...
    '============================================================\n\n');


%% ------------------------------------------------------------
% Per-scenario headline numbers
%
% Stored as arrays rather than loop-local scalars; these are the
% figures quoted in the abstract.
% ------------------------------------------------------------

savingVs10      = nan(1,nScenario);
savingVs20      = nan(1,nScenario);
eventRateChange = nan(1,nScenario);


for iS = 1:nScenario


    robustValid = ...
        aFormFail(:,iS) ...
        <= robustFailureLimit ...
        & ...
        aSafeFail(:,iS) ...
        <= robustFailureLimit;


    validIdx = ...
        find(robustValid);


    fprintf( ...
        '%s\n', ...
        scenarioNames{iS});


    if isempty(validIdx)

        fprintf( ...
            '  No robust AoI-aware profile found.\n\n');

        continue;

    end


    [~,localIdx] = ...
        min( ...
        meanATXRATE(validIdx,iS));


    bestIdx = ...
        validIdx(localIdx);


    bestAoIIdx(iS) = ...
        bestIdx;


    %% --------------------------------------------------------
    % Saving versus periodic 10 Hz
    % -----------------------------------------------------

    savingVs10(iS) = ...
        100 ...
        * ( ...
        1 ...
        - meanATXRATE(bestIdx,iS) ...
        / meanPTXRATE(idx10,iS) ...
        );


    %% --------------------------------------------------------
    % Saving versus periodic 20 Hz
    % -----------------------------------------------------

    savingVs20(iS) = ...
        100 ...
        * ( ...
        1 ...
        - meanATXRATE(bestIdx,iS) ...
        / meanPTXRATE(idx20,iS) ...
        );


    %% --------------------------------------------------------
    % Difference versus conventional event trigger
    % -----------------------------------------------------

    eventRateChange(iS) = ...
        100 ...
        * ( ...
        meanATXRATE(bestIdx,iS) ...
        / meanETXRATE(iS) ...
        - 1 ...
        );


    fprintf('  AoI threshold          : %.3f s\n', fixedAoIThreshold);
    fprintf('  Position threshold     : %.3f m\n', aoiPosThresholds(bestIdx));
    fprintf('  Velocity threshold     : %.3f m/s\n', aoiVelThresholds(bestIdx));


    fprintf( ...
        '  Formation RMSE         : %.4f m\n', ...
        meanARMSE(bestIdx,iS));


    fprintf( ...
        '  Min separation         : %.4f m\n', ...
        meanAMINEVAL(bestIdx,iS));


    fprintf( ...
        '  Mean AoI               : %.3f s\n', ...
        meanAAOI(bestIdx,iS));


    fprintf( ...
        '  Link-level P95 AoI     : %.3f s\n', ...
        meanAAOIP95(bestIdx,iS));


    fprintf( ...
        '  Effective rate/channel : %.2f Hz\n', ...
        meanATXRATE(bestIdx,iS));


    fprintf( ...
        '  Saving vs periodic 10  : %.1f %%\n', ...
        savingVs10(iS));


    fprintf( ...
        '  Saving vs periodic 20  : %.1f %%\n', ...
        savingVs20(iS));


    fprintf( ...
        '  Rate change vs event   : %+.1f %%\n', ...
        eventRateChange(iS));


    fprintf( ...
        '  Formation failure      : %.2f\n', ...
        aFormFail(bestIdx,iS));


    fprintf( ...
        '  Safety failure         : %.2f\n\n', ...
        aSafeFail(bestIdx,iS));

end


%% ============================================================
% Direct comparison table
%
% Best AoI-aware profile vs:
%
%   conventional event trigger
%   periodic 10 Hz
%   periodic 20 Hz
% ============================================================

fprintf( ...
    '============================================================\n');

fprintf( ...
    'Method comparison at selected operating points\n');

fprintf( ...
    '============================================================\n\n');


fprintf( ...
    'Scenario   Method       RMSE[m] TxRate AoI[s] MinEval FormFail\n');


fprintf( ...
    '---------- ------------ ------- ------ ------ ------- --------\n');


for iS = 1:nScenario


    fprintf( ...
        '%-10s %-12s %.4f  %5.2f  %.3f  %.4f   %.2f\n', ...
        scenarioNames{iS}, ...
        'Periodic10', ...
        meanPRMSE(idx10,iS), ...
        meanPTXRATE(idx10,iS), ...
        meanPAOI(idx10,iS), ...
        meanPMINEVAL(idx10,iS), ...
        pFormFail(idx10,iS));


    fprintf( ...
        '%-10s %-12s %.4f  %5.2f  %.3f  %.4f   %.2f\n', ...
        scenarioNames{iS}, ...
        'Periodic20', ...
        meanPRMSE(idx20,iS), ...
        meanPTXRATE(idx20,iS), ...
        meanPAOI(idx20,iS), ...
        meanPMINEVAL(idx20,iS), ...
        pFormFail(idx20,iS));


    fprintf( ...
        '%-10s %-12s %.4f  %5.2f  %.3f  %.4f   %.2f\n', ...
        scenarioNames{iS}, ...
        'Event', ...
        meanERMSE(iS), ...
        meanETXRATE(iS), ...
        meanEAOI(iS), ...
        meanEMINEVAL(iS), ...
        eFormFail(iS));


    if ~isnan(bestAoIIdx(iS))

        iA = ...
            bestAoIIdx(iS);


        fprintf( ...
            '%-10s %-12s %.4f  %5.2f  %.3f  %.4f   %.2f\n', ...
            scenarioNames{iS}, ...
            'AoI-aware', ...
            meanARMSE(iA,iS), ...
            meanATXRATE(iA,iS), ...
            meanAAOI(iA,iS), ...
            meanAMINEVAL(iA,iS), ...
            aFormFail(iA,iS));

    end


    fprintf('\n');

end


%% ============================================================
% Figure 1
% AoI threshold versus RMSE
% ============================================================

figure;

hold on;
grid on;


for iS = 1:nScenario

    plot( ...
        aoiPosThresholds, ...
        meanARMSE(:,iS), ...
        'o-', ...
        'LineWidth',1.3, ...
        'DisplayName', ...
        scenarioNames{iS});

end


yline( ...
    formationThreshold, ...
    '--', ...
    'DisplayName', ...
    'Formation threshold');


xlabel( ...
    'AoI trigger threshold [s]');


xlabel('Position threshold \epsilon_p [m]  (\epsilon_v = 2\epsilon_p)');


title( ...
    'EXP05B AoI threshold versus formation performance');


legend('Location','best');


%% ============================================================
% Figure 2
% AoI threshold versus communication rate
% ============================================================

figure;

hold on;
grid on;


for iS = 1:nScenario

    plot( ...
        aoiPosThresholds, ...
        meanATXRATE(:,iS), ...
        'o-', ...
        'LineWidth',1.3, ...
        'DisplayName', ...
        scenarioNames{iS});

end


xlabel('Position threshold \epsilon_p [m]  (\epsilon_v = 2\epsilon_p)');


ylabel( ...
    'Transmission rate per channel [Hz]');


title( ...
    'EXP05B AoI threshold versus communication usage');


legend('Location','best');


%% ============================================================
% Figure 3
% Resource-performance frontier
% ============================================================

figure;

hold on;
grid on;


for iS = 1:nScenario

    plot( ...
        meanATXRATE(:,iS), ...
        meanARMSE(:,iS), ...
        'o-', ...
        'LineWidth',1.3, ...
        'DisplayName', ...
        ['AoI-aware - ' scenarioNames{iS}]);

end


yline( ...
    formationThreshold, ...
    '--', ...
    'DisplayName', ...
    'Formation threshold');


xlabel( ...
    'Transmission rate per channel [Hz]');


ylabel( ...
    'Formation RMSE [m]');


title( ...
    'EXP05B AoI-aware resource-performance frontier');


legend('Location','best');


%% ============================================================
% Figure 4
% Link-level P95 AoI
% ============================================================

figure;

hold on;
grid on;


for iS = 1:nScenario

    plot( ...
        aoiPosThresholds, ...
        meanAAOIP95(:,iS), ...
        'o-', ...
        'LineWidth',1.3, ...
        'DisplayName', ...
        scenarioNames{iS});

end


xlabel( ...
    'AoI trigger threshold [s]');


ylabel( ...
    'Link-level P95 AoI [s]');


title( ...
    'EXP05B true link-level AoI tail');


legend('Location','best');


%% ============================================================
% Figure 5
% Trigger reason composition for selected best profiles
% ============================================================

validScenarioIdx = ...
    find(~isnan(bestAoIIdx));


if ~isempty(validScenarioIdx)

    composition = ...
        zeros(numel(validScenarioIdx),4);


    labels = ...
        cell(numel(validScenarioIdx),1);


    for k = 1:numel(validScenarioIdx)

        iS = ...
            validScenarioIdx(k);


        iA = ...
            bestAoIIdx(iS);


        composition(k,:) = [
            meanAPOS(iA,iS) ...
            meanAVEL(iA,iS) ...
            meanAAOITRIG(iA,iS) ...
            meanATIMEOUT(iA,iS)
        ];


        labels{k} = ...
            scenarioNames{iS};

    end


    figure;


    bar( ...
        composition, ...
        'stacked');


    grid on;


    set( ...
        gca, ...
        'XTick', ...
        1:numel(validScenarioIdx), ...
        'XTickLabel', ...
        labels);


    xlabel( ...
        'Network scenario');


    ylabel( ...
        'Fraction of transmissions');


    title( ...
        'EXP05B selected AoI-aware trigger composition');


    legend( ...
        {'Position trigger', ...
         'Velocity trigger', ...
         'AoI trigger', ...
         'Timeout trigger'}, ...
        'Location','best');

end


%% ============================================================
% Figure 6
% Best-method comparison
% ============================================================

bestRMSE = ...
    nan(nScenario,4);


bestRate = ...
    nan(nScenario,4);


for iS = 1:nScenario

    bestRMSE(iS,1) = ...
        meanPRMSE(idx10,iS);


    bestRMSE(iS,2) = ...
        meanPRMSE(idx20,iS);


    bestRMSE(iS,3) = ...
        meanERMSE(iS);


    bestRate(iS,1) = ...
        meanPTXRATE(idx10,iS);


    bestRate(iS,2) = ...
        meanPTXRATE(idx20,iS);


    bestRate(iS,3) = ...
        meanETXRATE(iS);


    if ~isnan(bestAoIIdx(iS))

        iA = ...
            bestAoIIdx(iS);


        bestRMSE(iS,4) = ...
            meanARMSE(iA,iS);


        bestRate(iS,4) = ...
            meanATXRATE(iA,iS);

    end

end


figure;

hold on;
grid on;


markerSet = {
    'o'
    's'
    'd'
    '^'
};


methodNames = {
    'Periodic 10 Hz'
    'Periodic 20 Hz'
    'Event'
    'AoI-aware'
};


for iM = 1:4

    plot( ...
        bestRate(:,iM), ...
        bestRMSE(:,iM), ...
        markerSet{iM}, ...
        'MarkerSize',8, ...
        'LineStyle','none', ...
        'DisplayName', ...
        methodNames{iM});

end


yline( ...
    formationThreshold, ...
    '--', ...
    'DisplayName', ...
    'Formation threshold');


xlabel( ...
    'Transmission rate per channel [Hz]');


ylabel( ...
    'Formation RMSE [m]');


title( ...
    'EXP05B periodic vs event vs AoI-aware');


legend('Location','best');


%% ============================================================
% End
% ============================================================

fprintf('\n');

fprintf( ...
    'EXP05B completed.\n');

fprintf('\n');


%% ============================================================
% LOCAL FUNCTION
%
% Collect TRUE link-level AoI samples over evaluation window.
%
% This avoids computing P95 from the network-mean AoI series.
% ============================================================

function samples = collectLinkAoI( ...
    out, ...
    cfg, ...
    idxEval)

N = ...
    cfg.swarm.N;


samples = [];


evalIndices = ...
    find(idxEval);


%% ============================================================
% Neighbor links
% ============================================================

for i = 1:N

    for j = 1:N

        if cfg.swarm.A(i,j) == 0
            continue;
        end


        x = ...
            out.neighborAoI( ...
            evalIndices, ...
            i, ...
            j);


        x = ...
            x(:);


        x = ...
            x(isfinite(x));


        samples = [
            samples
            x
        ]; %#ok<AGROW>

    end

end


%% ============================================================
% Leader-pinning links
% ============================================================

for i = 1:N

    if ~cfg.swarm.pin(i)
        continue;
    end


    x = ...
        out.leaderAoI( ...
        evalIndices, ...
        i);


    x = ...
        x(:);


    x = ...
        x(isfinite(x));


    samples = [
        samples
        x
    ]; %#ok<AGROW>

end


if isempty(samples)

    error( ...
        'No valid link-level AoI samples were collected.');

end

end


%% ============================================================
% ACK-feedback integrity check
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('ACK feedback integrity\n');
fprintf('============================================================\n');

fprintf('  Accepted-state updates : %d\n', sum(aACKUPDATE(:)));
fprintf('  Sync misses            : %d\n', sum(aACKMISS(:)));

if sum(aACKMISS(:)) == 0
    fprintf('  STATUS                 : OK\n');
else
    fprintf('  STATUS                 : *** MISSES DETECTED ***\n');
end


%% ============================================================
% Long-format results table
%
% The three policy families have different sweep shapes, so each is
% flattened separately and then stacked into one table with a common
% "method" column.
% ============================================================

Tp = tidyFromArray( ...
    struct( ...
        'RMSE',    pRMSE, ...
        'MAXERR',  pMAXERR, ...
        'MINEVAL', pMINEVAL, ...
        'AOI',     pAOI, ...
        'TXRATE',  pTXRATE, ...
        'TXCOUNT', pTXCOUNT, ...
        'PDR',     pPDR, ...
        'FORMFAIL', double(pFORMATIONFAIL), ...
        'SAFEFAIL', double(pSAFETYFAIL)), ...
    {'seed','profile','scenario'}, ...
    {1:numSeeds, arrayfun(@(r) sprintf('Periodic%gHz',r), periodicRates, ...
                          'UniformOutput', false), scenarioNames});

Te = tidyFromArray( ...
    struct( ...
        'RMSE',    eRMSE, ...
        'MAXERR',  eMAXERR, ...
        'MINEVAL', eMINEVAL, ...
        'AOI',     eAOI, ...
        'TXRATE',  eTXRATE, ...
        'TXCOUNT', eTXCOUNT, ...
        'PDR',     ePDR, ...
        'FORMFAIL', double(eFORMATIONFAIL), ...
        'SAFEFAIL', double(eSAFETYFAIL)), ...
    {'seed','scenario'}, ...
    {1:numSeeds, scenarioNames});

Te.profile = repmat({'State-event'}, height(Te), 1);

Ta = tidyFromArray( ...
    struct( ...
        'RMSE',    aRMSE, ...
        'MAXERR',  aMAXERR, ...
        'MINEVAL', aMINEVAL, ...
        'AOI',     aAOIMEAN, ...
        'TXRATE',  aTXRATE, ...
        'TXCOUNT', aTXCOUNT, ...
        'PDR',     aPDR, ...
        'FORMFAIL', double(aFORMATIONFAIL), ...
        'SAFEFAIL', double(aSAFETYFAIL)), ...
    {'seed','profile','scenario'}, ...
    {1:numSeeds, repmat({'Full-AoI'},1,nAoI), scenarioNames});

T = [Tp; Te(:, Tp.Properties.VariableNames); Ta];

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
