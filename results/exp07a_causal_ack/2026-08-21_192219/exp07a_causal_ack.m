%% EXP07A - Explicit causal ACK
%
% Replaces the ideal feedback path of simSwarmAoIAware with a real reverse
% ACK protocol, and evaluates the acceptance gates locked in
% docs/PREREGISTRATION.md before any of these numbers existed.
%
% Arms:
%
%   P10             periodic 10 Hz
%   P20             periodic 20 Hz
%   State-event     conventional event trigger
%   Ideal-AoI       simSwarmAoIAware, kept as an upper reference only
%   Causal-AoI      simSwarmAoICausal, the proposed implementation
%
% The AoI policy parameters are LOCKED and identical in every scenario:
%
%   epsP 0.05 m | epsV 0.10 m/s | AoIth 0.12 s | cooldown 0.10 s | maxSilence 0.50 s
%
% The ACK channel is symmetric with the forward channel (same delay, no
% loss); EXP07B is what degrades it.
%
% ============================================================

startup;

close all;


%% ============================================================
% Result persistence
% ============================================================

expRun = startExperiment('exp07a_causal_ack');


%% ============================================================
% Monte Carlo
%
% 3 for the debug pass, 20 for the final pass. The pre-registration
% requires the debug pass to be verified before the final one runs.
% ============================================================

numSeeds = 3;


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

nScenario = numel(scenarioNames);


%% ============================================================
% Methods
% ============================================================

% A1..A4c form the causal ablation chain. Each arm adds exactly one
% mechanism to the one before it, so a difference between neighbours
% is attributable to that mechanism alone:
%
%   A1  = State-event   state innovation only, no AoI branch
%   A2c = + AoI coupling, FIXED scale, freshness estimated OPEN LOOP
%   A3c = + ADAPTIVE scale,            freshness estimated OPEN LOOP
%   A4c = + real ACK feedback          freshness from acknowledgements
%
% A3c -> A4c is therefore the value of genuine feedback, measured
% without the oracle that made the ideal chain's 16.07% possible.
methodNames = {
    'P10'
    'P20'
    'A1 State-event'
    'Ideal-AoI'
    'A2c Fixed-OL'
    'A3c Adapt-OL'
    'A4c Causal-AoI'
};

nMethod = numel(methodNames);

IDX_P10    = 1;
IDX_P20    = 2;
IDX_EVENT  = 3;
IDX_IDEAL  = 4;
IDX_A2C    = 5;
IDX_A3C    = 6;
IDX_CAUSAL = 7;


%% ============================================================
% Locked policy parameters
% ============================================================

epsP         = 0.05;
epsV         = 0.10;
aoiThreshold = 0.12;
aoiCooldown  = 0.10;
maxSilence   = 0.50;


%% ============================================================
% Evaluation thresholds
% ============================================================

formationThreshold = 0.10;
safetyThreshold    = 0.25;


%% ============================================================
% Channel count
% ============================================================

cfg0 = defaultConfig();

nChannels = nnz(cfg0.swarm.A) + sum(cfg0.swarm.pin);


%% ============================================================
% Storage
%
% seed x method x scenario
% ============================================================

RMSE     = zeros(numSeeds,nMethod,nScenario);
MAXERR   = zeros(numSeeds,nMethod,nScenario);
MINEVAL  = zeros(numSeeds,nMethod,nScenario);
AOI      = zeros(numSeeds,nMethod,nScenario);
TXRATE   = zeros(numSeeds,nMethod,nScenario);
TXCOUNT  = zeros(numSeeds,nMethod,nScenario);
PDR      = zeros(numSeeds,nMethod,nScenario);

ACKRATE  = zeros(numSeeds,nMethod,nScenario);
ACKCOUNT = zeros(numSeeds,nMethod,nScenario);

FORMFAIL = false(numSeeds,nMethod,nScenario);
SAFEFAIL = false(numSeeds,nMethod,nScenario);

% Causality invariants, recorded for every arm (zero by construction for
% the arms that have no ACK channel).
VIOL_TOTAL      = zeros(numSeeds,nMethod,nScenario);
VIOL_BEFOREACC  = zeros(numSeeds,nMethod,nScenario);
VIOL_DROPPEDACK = zeros(numSeeds,nMethod,nScenario);
VIOL_ROLLBACK   = zeros(numSeeds,nMethod,nScenario);
VIOL_FUTURE     = zeros(numSeeds,nMethod,nScenario);
VIOL_STALEACC   = zeros(numSeeds,nMethod,nScenario);
VIOL_UNKNOWNSEQ = zeros(numSeeds,nMethod,nScenario);

STALEACKDISC = zeros(numSeeds,nMethod,nScenario);

% Trigger composition and adaptive state. These explain WHY a rate
% changes, which the rate alone cannot show.
POSTRIG   = zeros(numSeeds,nMethod,nScenario);
VELTRIG   = zeros(numSeeds,nMethod,nScenario);
AOITRIG   = zeros(numSeeds,nMethod,nScenario);
TIMEOUTTRIG = zeros(numSeeds,nMethod,nScenario);
MEANSCALE = nan(numSeeds,nMethod,nScenario);
MINSCALE  = nan(numSeeds,nMethod,nScenario);

% Gap between what the sender believes and the truth. Zero for every
% arm that has no AoI estimate.
ESTAOI = nan(numSeeds,nMethod,nScenario);

% v2 protocol diagnostics.
SUPPRINFLIGHT = nan(numSeeds,nMethod,nScenario);
MEANOUTST     = nan(numSeeds,nMethod,nScenario);
MAXOUTST      = nan(numSeeds,nMethod,nScenario);
ACKCUMGAIN    = nan(numSeeds,nMethod,nScenario);
DUPACK        = nan(numSeeds,nMethod,nScenario);


%% ============================================================
% Header
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP07A explicit causal ACK\n');
fprintf('============================================================\n\n');

fprintf('Seeds          : %d\n', numSeeds);
fprintf('Channels       : %d\n', nChannels);
fprintf('epsP / epsV    : %.3f m / %.3f m/s\n', epsP, epsV);
fprintf('AoI threshold  : %.3f s\n', aoiThreshold);
fprintf('AoI cooldown   : %.3f s\n', aoiCooldown);
fprintf('Max silence    : %.3f s\n', maxSilence);
fprintf('ACK channel    : symmetric with forward, no loss\n');


%% ============================================================
% Experiment
% ============================================================

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('%s | loss %.0f %% | delay %.0f ms\n', ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), ...
        1000*scenarioDelay(iS));
    fprintf('------------------------------------------------------------\n');

    for iM = 1:nMethod

        fprintf('  %-12s', methodNames{iM});

        rmseS   = zeros(numSeeds,1);
        maxerrS = zeros(numSeeds,1);
        minevS  = zeros(numSeeds,1);
        aoiS    = zeros(numSeeds,1);
        txrS    = zeros(numSeeds,1);
        txcS    = zeros(numSeeds,1);
        pdrS    = zeros(numSeeds,1);
        ackrS   = zeros(numSeeds,1);
        ackcS   = zeros(numSeeds,1);
        vTot    = zeros(numSeeds,1);
        vBef    = zeros(numSeeds,1);
        vDrp    = zeros(numSeeds,1);
        vRol    = zeros(numSeeds,1);
        vFut    = zeros(numSeeds,1);
        vSta    = zeros(numSeeds,1);
        vUnk    = zeros(numSeeds,1);
        sAckD   = zeros(numSeeds,1);
        pTrg    = zeros(numSeeds,1);
        vTrg    = zeros(numSeeds,1);
        aTrg    = zeros(numSeeds,1);
        tTrg    = zeros(numSeeds,1);
        mScale  = nan(numSeeds,1);
        nScale  = nan(numSeeds,1);
        eAoI    = nan(numSeeds,1);
        sInfl   = nan(numSeeds,1);
        mOut    = nan(numSeeds,1);
        xOut    = nan(numSeeds,1);
        cGain   = nan(numSeeds,1);
        dAck    = nan(numSeeds,1);

        parfor s = 1:numSeeds

            cfg = defaultConfig();

            cfg.net.packetLoss = scenarioLoss(iS);
            cfg.net.delay      = scenarioDelay(iS);
            cfg.net.jitterStd  = 0;

            % One seed family shared by every method, so the comparison
            % is paired.
            cfg.net.seed = 1400000 + 10000*iS + s;

            cfg.event.posThreshold = epsP;
            cfg.event.velThreshold = epsV;
            cfg.event.maxSilence   = maxSilence;

            cfg.aoiEvent.posThreshold      = epsP;
            cfg.aoiEvent.velThreshold      = epsV;
            cfg.aoiEvent.aoiThreshold      = aoiThreshold;
            cfg.aoiEvent.maxSilence        = maxSilence;
            cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
            cfg.aoiEvent.aoiMinInterTx     = aoiCooldown;
            cfg.aoiEvent.aoiStateScaleBase = 0.50;
            cfg.aoiEvent.aoiStateScaleMin  = 0.20;
            cfg.aoiEvent.aoiAdaptRange     = 1.00;

            % Reverse channel: same medium as the forward path.
            cfg.ack.loss             = 0.0;
            cfg.ack.delay            = scenarioDelay(iS);
            cfg.ack.jitterStd        = 0;
            cfg.ack.assertInvariants = true;

            switch iM

                case IDX_P10
                    cfg.net.commPeriod = 0.10;
                    out = simSwarmNetworkQueued(cfg);

                case IDX_P20
                    cfg.net.commPeriod = 0.05;
                    out = simSwarmNetworkQueued(cfg);

                case IDX_EVENT
                    out = simSwarmEventTriggered(cfg);

                case IDX_IDEAL
                    out = simSwarmAoIAware(cfg);

                case IDX_A2C
                    cfg.causal.useAdaptiveScale = false;
                    cfg.causal.useAckFeedback   = false;
                    out = simSwarmAoICausal(cfg);

                case IDX_A3C
                    cfg.causal.useAdaptiveScale = true;
                    cfg.causal.useAckFeedback   = false;
                    out = simSwarmAoICausal(cfg);

                case IDX_CAUSAL
                    cfg.causal.useAdaptiveScale = true;
                    cfg.causal.useAckFeedback   = true;
                    out = simSwarmAoICausal(cfg);

            end

            M = computeSwarmMetrics(out, cfg);

            idxEval = out.t >= 8;

            rmseS(s)   = M.formationRMSE;
            maxerrS(s) = M.maxFormationError;
            minevS(s)  = M.minSeparationEval;
            aoiS(s)    = mean(out.meanAoI(idxEval));

            txcS(s) = out.txCount;
            txrS(s) = out.txCount / (out.t(end)-out.t(1)) / nChannels;
            pdrS(s) = out.PDR;

            if isfield(out,'ackTxCount')
                ackcS(s) = out.ackTxCount;
                ackrS(s) = out.ackRatePerChannel;
            end

            % Guarded per field: the conventional event trigger reports
            % position/velocity/timeout but has no AoI branch at all.
            if isfield(out,'positionTriggerRatio')
                pTrg(s) = out.positionTriggerRatio;
            end
            if isfield(out,'velocityTriggerRatio')
                vTrg(s) = out.velocityTriggerRatio;
            end
            if isfield(out,'aoiTriggerRatio')
                aTrg(s) = out.aoiTriggerRatio;
            end
            if isfield(out,'timeoutTriggerRatio')
                tTrg(s) = out.timeoutTriggerRatio;
            end

            if isfield(out,'meanAdaptiveScale')
                mScale(s) = out.meanAdaptiveScale;
                nScale(s) = out.minAdaptiveScale;
            end

            if isfield(out,'estimatedAoI')
                e = out.estimatedAoI(idxEval,:,:);
                eAoI(s) = mean(e(~isnan(e)));
            end

            if isfield(out,'suppressedInFlightRatio')
                sInfl(s) = out.suppressedInFlightRatio;
                mOut(s)  = out.meanOutstanding;
                xOut(s)  = out.maxOutstanding;
                cGain(s) = out.ackCumulativeGain;
                dAck(s)  = out.duplicateAckCount;
            end

            if isfield(out,'invariantViolations')
                vTot(s)  = out.invariantViolations;
                vBef(s)  = out.ackBeforeAcceptCount;
                vDrp(s)  = out.ackForDroppedDataCount;
                vRol(s)  = out.senderRollbackCount;
                vFut(s)  = out.futureGenTimeCount;
                vSta(s)  = out.staleAckAcceptedCount;
                vUnk(s)  = out.unknownSeqAckCount;
                sAckD(s) = out.staleAckDiscardedCount;
            end

        end

        RMSE(:,iM,iS)     = rmseS;
        MAXERR(:,iM,iS)   = maxerrS;
        MINEVAL(:,iM,iS)  = minevS;
        AOI(:,iM,iS)      = aoiS;
        TXRATE(:,iM,iS)   = txrS;
        TXCOUNT(:,iM,iS)  = txcS;
        PDR(:,iM,iS)      = pdrS;
        ACKRATE(:,iM,iS)  = ackrS;
        ACKCOUNT(:,iM,iS) = ackcS;

        VIOL_TOTAL(:,iM,iS)      = vTot;
        VIOL_BEFOREACC(:,iM,iS)  = vBef;
        VIOL_DROPPEDACK(:,iM,iS) = vDrp;
        VIOL_ROLLBACK(:,iM,iS)   = vRol;
        VIOL_FUTURE(:,iM,iS)     = vFut;
        VIOL_STALEACC(:,iM,iS)   = vSta;
        VIOL_UNKNOWNSEQ(:,iM,iS) = vUnk;
        STALEACKDISC(:,iM,iS)    = sAckD;

        POSTRIG(:,iM,iS)     = pTrg;
        VELTRIG(:,iM,iS)     = vTrg;
        AOITRIG(:,iM,iS)     = aTrg;
        TIMEOUTTRIG(:,iM,iS) = tTrg;
        MEANSCALE(:,iM,iS)   = mScale;
        MINSCALE(:,iM,iS)    = nScale;
        ESTAOI(:,iM,iS)      = eAoI;

        SUPPRINFLIGHT(:,iM,iS) = sInfl;
        MEANOUTST(:,iM,iS)     = mOut;
        MAXOUTST(:,iM,iS)      = xOut;
        ACKCUMGAIN(:,iM,iS)    = cGain;
        DUPACK(:,iM,iS)        = dAck;

        FORMFAIL(:,iM,iS) = rmseS  > formationThreshold;
        SAFEFAIL(:,iM,iS) = minevS < safetyThreshold;

        fprintf(' done\n');

    end

end


%% ============================================================
% Aggregate
% ============================================================

meanRMSE    = reshape(mean(RMSE,1),    nMethod,nScenario);
stdRMSE     = reshape(std(RMSE,0,1),   nMethod,nScenario);
meanTXRATE  = reshape(mean(TXRATE,1),  nMethod,nScenario);
meanACKRATE = reshape(mean(ACKRATE,1), nMethod,nScenario);
meanAOI     = reshape(mean(AOI,1),     nMethod,nScenario);
meanMINEVAL = reshape(mean(MINEVAL,1), nMethod,nScenario);

formFailRate = reshape(mean(FORMFAIL,1), nMethod,nScenario);
safeFailRate = reshape(mean(SAFEFAIL,1), nMethod,nScenario);


%% ============================================================
% Results table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Results\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %8s %8s %9s %9s %8s %8s %8s\n', ...
    'Scenario','Method','RMSE','Std','Data[Hz]','ACK[Hz]','AoI[s]','FormFail','SafeFail');

for iS = 1:nScenario
    for iM = 1:nMethod
        fprintf('%-10s %-12s %8.4f %8.4f %9.2f %9.2f %8.3f %8.2f %8.2f\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            meanRMSE(iM,iS), stdRMSE(iM,iS), ...
            meanTXRATE(iM,iS), meanACKRATE(iM,iS), ...
            meanAOI(iM,iS), formFailRate(iM,iS), safeFailRate(iM,iS));
    end
    fprintf('\n');
end


%% ============================================================
% Causality invariants
% ============================================================

fprintf('============================================================\n');
fprintf('Causality invariants (Causal-AoI)\n');
fprintf('============================================================\n\n');

invNames = {
    'ackBeforeAcceptCount'
    'ackForDroppedDataCount'
    'senderRollbackCount'
    'futureGenTimeCount'
    'staleAckAcceptedCount'
    'unknownSeqAckCount'
};

invTotals = [
    sum(sum(VIOL_BEFOREACC(:,IDX_CAUSAL,:)))
    sum(sum(VIOL_DROPPEDACK(:,IDX_CAUSAL,:)))
    sum(sum(VIOL_ROLLBACK(:,IDX_CAUSAL,:)))
    sum(sum(VIOL_FUTURE(:,IDX_CAUSAL,:)))
    sum(sum(VIOL_STALEACC(:,IDX_CAUSAL,:)))
    sum(sum(VIOL_UNKNOWNSEQ(:,IDX_CAUSAL,:)))
];

for q = 1:numel(invNames)
    fprintf('  %-26s %d\n', invNames{q}, invTotals(q));
end

totalViolations = sum(invTotals);

fprintf('\n  %-26s %d\n', 'TOTAL', totalViolations);
fprintf('  %-26s %d\n', 'staleAckDiscarded (expected>0 only under jitter)', ...
    sum(sum(STALEACKDISC(:,IDX_CAUSAL,:))));


%% ============================================================
% Trigger composition
%
% The rate alone cannot say WHY a method transmits more. This table
% can: it separates hard state triggers from AoI-assisted ones and
% shows how saturated the adaptive scale became.
% ============================================================

meanPOSTRIG   = reshape(mean(POSTRIG,1),   nMethod,nScenario);
meanAOITRIG   = reshape(mean(AOITRIG,1),   nMethod,nScenario);
meanMEANSCALE = reshape(mean(MEANSCALE,1), nMethod,nScenario);
meanESTAOI    = reshape(mean(ESTAOI,1),    nMethod,nScenario);

fprintf('\n');
fprintf('============================================================\n');
fprintf('Trigger composition (AoI arms only)\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %10s %10s %10s %10s %10s\n', ...
    'Scenario','Method','posTrig','aoiTrig','meanScale','trueAoI','estAoI');

for iS = 1:nScenario
    for iM = [IDX_IDEAL IDX_CAUSAL]
        fprintf('%-10s %-12s %10.3f %10.3f %10.3f %10.3f %10.3f\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            meanPOSTRIG(iM,iS), meanAOITRIG(iM,iS), ...
            meanMEANSCALE(iM,iS), meanAOI(iM,iS), meanESTAOI(iM,iS));
    end
    fprintf('\n');
end


%% ============================================================
% Protocol diagnostics (v2)
%
% These are what distinguish v2 from v1. suppressedInFlight counts
% occasions where v1's single-memory rule would have transmitted but
% the innovation was already on the wire.
% ============================================================

meanSUPPR   = reshape(mean(SUPPRINFLIGHT,1), nMethod,nScenario);
meanOUTST   = reshape(mean(MEANOUTST,1),     nMethod,nScenario);
maxOUTST    = reshape(max(MAXOUTST,[],1),    nMethod,nScenario);
meanCUMGAIN = reshape(mean(ACKCUMGAIN,1),    nMethod,nScenario);
meanDUPACK  = reshape(mean(DUPACK,1),        nMethod,nScenario);

fprintf('\n');
fprintf('============================================================\n');
fprintf('Protocol diagnostics (causal arms)\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-16s %11s %11s %10s %10s %9s\n', ...
    'Scenario','Method','supprInFlt','meanOutst','maxOutst','ackCumGain','dupAck');

for iS = 1:nScenario
    for iM = [IDX_A2C IDX_A3C IDX_CAUSAL]
        fprintf('%-10s %-16s %11.3f %11.3f %10d %10.3f %9.0f\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            meanSUPPR(iM,iS), meanOUTST(iM,iS), maxOUTST(iM,iS), ...
            meanCUMGAIN(iM,iS), meanDUPACK(iM,iS));
    end
    fprintf('\n');
end


%% ============================================================
% Causal ablation chain
% ============================================================

fprintf('============================================================\n');
fprintf('Causal ablation: A1 -> A2c -> A3c -> A4c\n');
fprintf('============================================================\n\n');

chain = [IDX_EVENT IDX_A2C IDX_A3C IDX_CAUSAL];
chainNames = {'A1 -> A2c  AoI coupling', ...
              'A2c -> A3c adaptive scale', ...
              'A3c -> A4c real feedback'};

gainCausal = nan(3,nScenario);
rateCausal = nan(3,nScenario);

for iS = 1:nScenario

    fprintf('%s\n', scenarioNames{iS});

    for c = 1:3
        a = chain(c);
        b = chain(c+1);
        gainCausal(c,iS) = 100*(meanRMSE(a,iS)-meanRMSE(b,iS))/meanRMSE(a,iS);
        rateCausal(c,iS) = meanTXRATE(b,iS)-meanTXRATE(a,iS);
        fprintf('  %-28s RMSE %+7.2f %% | rate %+6.2f Hz\n', ...
            chainNames{c}, gainCausal(c,iS), rateCausal(c,iS));
    end

    fprintf('\n');

end


%% ============================================================
% Acceptance gates
%
% Thresholds come from docs/PREREGISTRATION.md and were fixed before
% any of the numbers above existed. They are evaluated mechanically
% here so the verdict does not depend on interpretation.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP07A acceptance gates\n');
fprintf('============================================================\n\n');

% Each gate is a row: {name, passed, formatted value}. Built inline
% because a MATLAB script's local functions cannot see its workspace.
gateNames  = {};
gateValues = {};
gatePass   = [];

% --- Causality
gateNames{end+1}  = 'Causality: 6 invariants = 0';
gatePass(end+1)   = (totalViolations == 0);
gateValues{end+1} = sprintf('%d violation(s)', totalViolations);

% --- Clean equivalence
cleanRel = abs(meanRMSE(IDX_CAUSAL,1) - meanRMSE(IDX_IDEAL,1)) ...
    / meanRMSE(IDX_IDEAL,1);
gateNames{end+1}  = 'Clean: |Causal-Ideal|/Ideal <= 2%';
gatePass(end+1)   = (cleanRel <= 0.02);
gateValues{end+1} = sprintf('%.3f %%', 100*cleanRel);

% --- Moderate versus P10
modRatio = meanRMSE(IDX_CAUSAL,2) / meanRMSE(IDX_P10,2);
gateNames{end+1}  = 'Moderate: Causal <= 1.10 x P10';
gatePass(end+1)   = (modRatio <= 1.10);
gateValues{end+1} = sprintf('%.4f vs %.4f  (ratio %.3f)', ...
    meanRMSE(IDX_CAUSAL,2), meanRMSE(IDX_P10,2), modRatio);

% --- Stressed versus P10
gateNames{end+1}  = 'Stressed: Causal < P10';
gatePass(end+1)   = (meanRMSE(IDX_CAUSAL,3) < meanRMSE(IDX_P10,3));
gateValues{end+1} = sprintf('%.4f vs %.4f', ...
    meanRMSE(IDX_CAUSAL,3), meanRMSE(IDX_P10,3));

% --- Versus the conventional event trigger
gateNames{end+1}  = 'Moderate: Causal < State-event';
gatePass(end+1)   = (meanRMSE(IDX_CAUSAL,2) < meanRMSE(IDX_EVENT,2));
gateValues{end+1} = sprintf('%.4f vs %.4f', ...
    meanRMSE(IDX_CAUSAL,2), meanRMSE(IDX_EVENT,2));

gateNames{end+1}  = 'Stressed: Causal < State-event';
gatePass(end+1)   = (meanRMSE(IDX_CAUSAL,3) < meanRMSE(IDX_EVENT,3));
gateValues{end+1} = sprintf('%.4f vs %.4f', ...
    meanRMSE(IDX_CAUSAL,3), meanRMSE(IDX_EVENT,3));

% --- Adaptive direction
rateOrdered = meanTXRATE(IDX_CAUSAL,1) < meanTXRATE(IDX_CAUSAL,2) ...
    && meanTXRATE(IDX_CAUSAL,2) < meanTXRATE(IDX_CAUSAL,3);
gateNames{end+1}  = 'Rate ordering: Clean < Moderate < Stressed';
gatePass(end+1)   = rateOrdered;
gateValues{end+1} = sprintf('%.2f < %.2f < %.2f Hz', ...
    meanTXRATE(IDX_CAUSAL,1), meanTXRATE(IDX_CAUSAL,2), meanTXRATE(IDX_CAUSAL,3));

% --- Cost ceiling
gateNames{end+1}  = 'Rate ceiling: Stressed data rate <= 20 Hz';
gatePass(end+1)   = (meanTXRATE(IDX_CAUSAL,3) <= 20);
gateValues{end+1} = sprintf('%.2f Hz', meanTXRATE(IDX_CAUSAL,3));

% --- Safety
maxSafeFail = max(safeFailRate(IDX_CAUSAL,:));
gateNames{end+1}  = 'Safety: SafeFail = 0 in all scenarios';
gatePass(end+1)   = (maxSafeFail == 0);
gateValues{end+1} = sprintf('max %.2f', maxSafeFail);


for q = 1:numel(gateNames)
    if gatePass(q)
        verdict = 'PASS';
    else
        verdict = 'FAIL';
    end
    fprintf('  [%s] %-42s %s\n', verdict, gateNames{q}, gateValues{q});
end

nFailed = sum(~gatePass);

fprintf('\n');

if nFailed == 0
    fprintf('  EXP07A GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP07A GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, thresholds are NOT to be adjusted.\n');
    fprintf('  Analyse the cause and report before changing anything.\n');
end


%% ============================================================
% Figures
% ============================================================

figure('Name','EXP07A formation error by method');
bar(meanRMSE');
grid on;
set(gca,'XTickLabel',scenarioNames);
ylabel('Formation RMSE [m]');
title('EXP07A formation error');
legend(methodNames,'Location','northwest');

figure('Name','EXP07A communication cost by method');
bar([meanTXRATE' meanACKRATE(IDX_CAUSAL,:)']);
grid on;
set(gca,'XTickLabel',scenarioNames);
ylabel('Rate per channel [Hz]');
title('EXP07A communication cost (last bar = Causal ACK overhead)');
legend([methodNames; {'Causal ACK'}],'Location','northwest');

figure('Name','EXP07A cost versus error');
hold on; grid on;
% Cycle markers so the list cannot fall behind the arm count.
markerPool = {'o','s','^','d','p','h','v','>','<','*'};
markers = markerPool(mod(0:nMethod-1, numel(markerPool)) + 1);
for iM = 1:nMethod
    plot(meanTXRATE(iM,:), meanRMSE(iM,:), ['-' markers{iM}], ...
        'LineWidth', 1.3, 'MarkerSize', 8);
end
yline(formationThreshold,'--','Formation threshold');
xlabel('Data rate per channel [Hz]');
ylabel('Formation RMSE [m]');
title('EXP07A cost versus error (each line spans Clean to Stressed)');
legend(methodNames,'Location','northeast');
hold off;


%% ============================================================
% Long-format results table
% ============================================================

T = tidyFromArray( ...
    struct( ...
        'RMSE',        RMSE, ...
        'MAXERR',      MAXERR, ...
        'MINEVAL',     MINEVAL, ...
        'AOI',         AOI, ...
        'TXRATE',      TXRATE, ...
        'TXCOUNT',     TXCOUNT, ...
        'ACKRATE',     ACKRATE, ...
        'ACKCOUNT',    ACKCOUNT, ...
        'PDR',         PDR, ...
        'VIOLATIONS',  VIOL_TOTAL, ...
        'POSTRIG',     POSTRIG, ...
        'VELTRIG',     VELTRIG, ...
        'AOITRIG',     AOITRIG, ...
        'TIMEOUTTRIG', TIMEOUTTRIG, ...
        'MEANSCALE',   MEANSCALE, ...
        'MINSCALE',    MINSCALE, ...
        'ESTAOI',        ESTAOI, ...
        'SUPPRINFLIGHT', SUPPRINFLIGHT, ...
        'MEANOUTST',     MEANOUTST, ...
        'MAXOUTST',      MAXOUTST, ...
        'ACKCUMGAIN',    ACKCUMGAIN, ...
        'DUPACK',        DUPACK, ...
        'STALEACKDISC',STALEACKDISC, ...
        'FORMFAIL',    double(FORMFAIL), ...
        'SAFEFAIL',    double(SAFEFAIL)), ...
    {'seed','method','scenario'}, ...
    {1:numSeeds, methodNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));


fprintf('\nEXP07A completed.\n');


%% ============================================================
% Persist results
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);
