%% EXP07B - ACK channel impairment
%
% EXP07A established that Causal-AoI-v3 works when the reverse channel is
% reliable. This asks what happens when the ACK path itself degrades:
% lost acknowledgements, extra one-way delay, and reordering under jitter.
%
% Nothing in the policy changes. No locked threshold moves. The only thing
% varied is the reverse channel.
%
% Forward DATA network is held fixed per scenario:
%
%   Moderate   DATA loss 20 %, delay  80 ms
%   Stressed   DATA loss 40 %, delay 120 ms
%
% ACK one-way delay = forward delay + extraDelay. So Stressed with
% extraDelay 80 ms means the ACK takes 120 + 80 = 200 ms to come back,
% against an AoI threshold of 120 ms.
%
% Grid:
%
%   core       ackLoss {0, 10, 20} %  x  extraDelay {0, 40, 80} ms, jitter 0
%   severe     ackLoss 20 %, extraDelay = forward delay  (ACK delay = 2x DATA)
%   reordering ackLoss 10 %, extraDelay 40 ms, jitter {40, 80} ms
%
% The severe cell is included because docs/PREREGISTRATION.md section 2.7
% defines severe as "ACK delay = 2x DATA delay". At Moderate that coincides
% with the core cell at extraDelay 80 ms; at Stressed it needs 120 ms, which
% the core grid does not contain. Measuring it directly means the
% pre-registered gate is evaluated exactly rather than approximated.
%
% ============================================================

startup;

close all;


%% ============================================================
% Result persistence
% ============================================================

expRun = startExperiment('exp07b_ack_impairment');


%% ============================================================
% Monte Carlo
%
% Final pass. The 3-seed debug pass was reviewed first, as the
% pre-registration requires. Nothing else changed between the two.
% ============================================================

numSeeds = 20;


%% ============================================================
% Forward network scenarios
% ============================================================

scenarioNames = {
    'Moderate'
    'Stressed'
};

scenarioLoss  = [0.20; 0.40];
scenarioDelay = [0.08; 0.12];

nScenario = numel(scenarioNames);


%% ============================================================
% ACK channel grid
%
% extraDelay = -1 is a sentinel meaning "equal to the forward delay",
% which is how the pre-registered severe level is defined.
% ============================================================

ackNames = {
    'reliable'
    'L0  D40'
    'L0  D80'
    'L10 D0'
    'L10 D40'
    'L10 D80'
    'L20 D0'
    'L20 D40'
    'L20 D80'
    'L20 D=fwd'
    'L10 D40 J40'
    'L10 D40 J80'
};

ackLoss = [
    0.00; 0.00; 0.00
    0.10; 0.10; 0.10
    0.20; 0.20; 0.20
    0.20
    0.10; 0.10
];

ackExtra = [
    0.000; 0.040; 0.080
    0.000; 0.040; 0.080
    0.000; 0.040; 0.080
    -1
    0.040; 0.040
];

ackJitter = [
    0.000; 0.000; 0.000
    0.000; 0.000; 0.000
    0.000; 0.000; 0.000
    0.000
    0.040; 0.080
];

nAck = numel(ackNames);

% Pre-registered impairment levels, by index into the grid above.
IDX_RELIABLE = 1;    % ackLoss 0,   ACK delay = DATA delay
IDX_MODERATE = 4;    % ackLoss 10%, ACK delay = DATA delay
IDX_SEVERE   = 10;   % ackLoss 20%, ACK delay = 2 x DATA delay

IDX_JITTER = [11 12];


%% ============================================================
% Methods
%
% The baselines carry no reverse channel, so their results must be
% identical in every ACK cell. Running them throughout turns that
% into a check that ACK settings cannot leak into them.
% ============================================================

methodNames = {
    'P10'
    'P20'
    'Causal-v3'
};

nMethod = numel(methodNames);

IDX_P10    = 1;
IDX_P20    = 2;
IDX_CAUSAL = 3;


%% ============================================================
% Locked policy parameters
% ============================================================

epsP         = 0.05;
epsV         = 0.10;
aoiThreshold = 0.12;
aoiCooldown  = 0.10;
maxSilence   = 0.50;

formationThreshold = 0.10;
safetyThreshold    = 0.25;


cfg0 = defaultConfig();

nChannels = nnz(cfg0.swarm.A) + sum(cfg0.swarm.pin);

dtSwarm = cfg0.swarm.dt;


%% ============================================================
% Storage
%
% seed x method x ackConfig x scenario
% ============================================================

RMSE     = zeros(numSeeds,nMethod,nAck,nScenario);
MINEVAL  = zeros(numSeeds,nMethod,nAck,nScenario);
AOI      = zeros(numSeeds,nMethod,nAck,nScenario);
TXRATE   = zeros(numSeeds,nMethod,nAck,nScenario);
ACKRATE  = nan(numSeeds,nMethod,nAck,nScenario);

FORMFAIL = false(numSeeds,nMethod,nAck,nScenario);
SAFEFAIL = false(numSeeds,nMethod,nAck,nScenario);

VIOL     = zeros(numSeeds,nMethod,nAck,nScenario);
MAXGAP   = nan(numSeeds,nMethod,nAck,nScenario);

ACKDELIV = nan(numSeeds,nMethod,nAck,nScenario);
STALEACK = nan(numSeeds,nMethod,nAck,nScenario);
DUPACK   = nan(numSeeds,nMethod,nAck,nScenario);
MEANOUT  = nan(numSeeds,nMethod,nAck,nScenario);
MAXOUT   = nan(numSeeds,nMethod,nAck,nScenario);

HARDR    = nan(numSeeds,nMethod,nAck,nScenario);
ADAPTR   = nan(numSeeds,nMethod,nAck,nScenario);
REFRESHR = nan(numSeeds,nMethod,nAck,nScenario);
ESTAOI   = nan(numSeeds,nMethod,nAck,nScenario);

% Adaptive scale. Once it sits on its floor the trigger can no longer
% distinguish degrees of staleness, so further ACK degradation cannot
% change any decision. That is the difference between robustness and
% saturation, and only this number tells them apart.
MEANSCALE = nan(numSeeds,nMethod,nAck,nScenario);
MINSCALE  = nan(numSeeds,nMethod,nAck,nScenario);


%% ============================================================
% Header
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP07B ACK channel impairment\n');
fprintf('============================================================\n\n');

fprintf('Seeds        : %d\n', numSeeds);
fprintf('ACK cells    : %d per scenario\n', nAck);
fprintf('Total sims   : %d\n\n', numSeeds*nMethod*nAck*nScenario);

fprintf('Policy is LOCKED and identical everywhere:\n');
fprintf('  epsP %.2f | epsV %.2f | AoIth %.2f | cooldown %.2f | maxSilence %.2f\n\n', ...
    epsP, epsV, aoiThreshold, aoiCooldown, maxSilence);


%% ============================================================
% Experiment
% ============================================================

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('%s | DATA loss %.0f %% | DATA delay %.0f ms\n', ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), 1000*scenarioDelay(iS));
    fprintf('------------------------------------------------------------\n');

    for iA = 1:nAck

        % Resolve the sentinel: severe means ACK delay = 2 x DATA delay.
        if ackExtra(iA) < 0
            thisExtra = scenarioDelay(iS);
        else
            thisExtra = ackExtra(iA);
        end

        thisAckDelay = scenarioDelay(iS) + thisExtra;

        fprintf('  %-13s ackLoss %3.0f%% ackDelay %5.0f ms jitter %3.0f ms', ...
            ackNames{iA}, 100*ackLoss(iA), 1000*thisAckDelay, 1000*ackJitter(iA));

        for iM = 1:nMethod

            rmseS  = zeros(numSeeds,1);
            minevS = zeros(numSeeds,1);
            aoiS   = zeros(numSeeds,1);
            txrS   = zeros(numSeeds,1);
            ackrS  = nan(numSeeds,1);
            violS  = zeros(numSeeds,1);
            gapS   = nan(numSeeds,1);
            delivS = nan(numSeeds,1);
            staleS = nan(numSeeds,1);
            dupS   = nan(numSeeds,1);
            moutS  = nan(numSeeds,1);
            xoutS  = nan(numSeeds,1);
            hS     = nan(numSeeds,1);
            aS     = nan(numSeeds,1);
            rS     = nan(numSeeds,1);
            eS     = nan(numSeeds,1);
            msS    = nan(numSeeds,1);
            nsS    = nan(numSeeds,1);

            parfor s = 1:numSeeds

                cfg = defaultConfig();

                cfg.net.packetLoss = scenarioLoss(iS);
                cfg.net.delay      = scenarioDelay(iS);
                cfg.net.jitterStd  = 0;

                cfg.net.seed = 1500000 + 10000*iS + s;

                % True CRN on the forward channel, as from v3 onward.
                % The ACK stream is separate, so varying ACK impairment
                % never perturbs the forward realisation.
                cfg.net.useTrace    = true;
                cfg.net.phaseOffset = false;

                cfg.aoiEvent.posThreshold      = epsP;
                cfg.aoiEvent.velThreshold      = epsV;
                cfg.aoiEvent.aoiThreshold      = aoiThreshold;
                cfg.aoiEvent.maxSilence        = maxSilence;
                cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
                cfg.aoiEvent.aoiMinInterTx     = aoiCooldown;
                cfg.aoiEvent.aoiStateScaleBase = 0.50;
                cfg.aoiEvent.aoiStateScaleMin  = 0.20;
                cfg.aoiEvent.aoiAdaptRange     = 1.00;

                % Reverse-channel CRN. The trace depends only on scenario
                % and seed, never on the impairment settings, so all 12 ACK
                % cells sit on one reverse realisation and a difference
                % between cells is the impairment rather than the draw.
                cfg.ack.useTrace = true;

                cfg.ack.loss             = ackLoss(iA);
                cfg.ack.delay            = thisAckDelay;
                cfg.ack.jitterStd        = ackJitter(iA);
                cfg.ack.assertInvariants = true;

                cfg.causal.useAdaptiveScale   = true;
                cfg.causal.useAckFeedback     = true;
                cfg.causal.innovationPriority = true;

                switch iM
                    case IDX_P10
                        cfg.net.commPeriod = 0.10;
                        out = simSwarmNetworkQueued(cfg);
                    case IDX_P20
                        cfg.net.commPeriod = 0.05;
                        out = simSwarmNetworkQueued(cfg);
                    case IDX_CAUSAL
                        out = simSwarmAoICausal(cfg);
                end

                M = computeSwarmMetrics(out, cfg);

                idxEval = out.t >= 8;

                rmseS(s)  = M.formationRMSE;
                minevS(s) = M.minSeparationEval;
                aoiS(s)   = mean(out.meanAoI(idxEval));
                txrS(s)   = out.txCount / (out.t(end)-out.t(1)) / nChannels;

                if isfield(out,'ackRatePerChannel')
                    ackrS(s)  = out.ackRatePerChannel;
                    delivS(s) = out.ackDeliveryRatio;
                    staleS(s) = out.staleAckDiscardedCount;
                    dupS(s)   = out.duplicateAckCount;
                    moutS(s)  = out.meanOutstanding;
                    xoutS(s)  = out.maxOutstanding;
                    violS(s)  = out.invariantViolations;
                    gapS(s)   = out.maxInterTxGap;
                    hS(s)     = out.hardInnovationRatio;
                    aS(s)     = out.adaptiveNewInfoRatio;
                    rS(s)     = out.refreshRatio;

                    e = out.estimatedAoI(idxEval,:,:);
                    eS(s) = mean(e(~isnan(e)));

                    msS(s) = out.meanAdaptiveScale;
                    nsS(s) = out.minAdaptiveScale;
                end

            end

            RMSE(:,iM,iA,iS)     = rmseS;
            MINEVAL(:,iM,iA,iS)  = minevS;
            AOI(:,iM,iA,iS)      = aoiS;
            TXRATE(:,iM,iA,iS)   = txrS;
            ACKRATE(:,iM,iA,iS)  = ackrS;
            VIOL(:,iM,iA,iS)     = violS;
            MAXGAP(:,iM,iA,iS)   = gapS;
            ACKDELIV(:,iM,iA,iS) = delivS;
            STALEACK(:,iM,iA,iS) = staleS;
            DUPACK(:,iM,iA,iS)   = dupS;
            MEANOUT(:,iM,iA,iS)  = moutS;
            MAXOUT(:,iM,iA,iS)   = xoutS;
            HARDR(:,iM,iA,iS)    = hS;
            ADAPTR(:,iM,iA,iS)   = aS;
            REFRESHR(:,iM,iA,iS) = rS;
            ESTAOI(:,iM,iA,iS)   = eS;
            MEANSCALE(:,iM,iA,iS) = msS;
            MINSCALE(:,iM,iA,iS)  = nsS;

            FORMFAIL(:,iM,iA,iS) = rmseS  > formationThreshold;
            SAFEFAIL(:,iM,iA,iS) = minevS < safetyThreshold;

        end

        fprintf('  done\n');

    end

end


%% ============================================================
% Aggregate
% ============================================================

meanRMSE   = reshape(mean(RMSE,1),   nMethod,nAck,nScenario);
stdRMSE    = reshape(std(RMSE,0,1),  nMethod,nAck,nScenario);
meanTXRATE = reshape(mean(TXRATE,1), nMethod,nAck,nScenario);
meanACKR   = reshape(mean(ACKRATE,1),nMethod,nAck,nScenario);
meanAOI    = reshape(mean(AOI,1),    nMethod,nAck,nScenario);
meanDELIV  = reshape(mean(ACKDELIV,1),nMethod,nAck,nScenario);
meanSTALE  = reshape(mean(STALEACK,1),nMethod,nAck,nScenario);
meanMOUT   = reshape(mean(MEANOUT,1),nMethod,nAck,nScenario);
maxMOUT    = reshape(max(MAXOUT,[],1),nMethod,nAck,nScenario);
maxGAP     = reshape(max(MAXGAP,[],1),nMethod,nAck,nScenario);

meanHARD    = reshape(mean(HARDR,1),   nMethod,nAck,nScenario);
meanADAPT   = reshape(mean(ADAPTR,1),  nMethod,nAck,nScenario);
meanREFRESH = reshape(mean(REFRESHR,1),nMethod,nAck,nScenario);
meanESTAOI  = reshape(mean(ESTAOI,1),  nMethod,nAck,nScenario);
meanSCALE   = reshape(mean(MEANSCALE,1),nMethod,nAck,nScenario);

formFailRate = reshape(mean(FORMFAIL,1), nMethod,nAck,nScenario);
safeFailRate = reshape(mean(SAFEFAIL,1), nMethod,nAck,nScenario);


%% ============================================================
% Results table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Causal-v3 under ACK impairment\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-13s %8s %9s %8s %8s %8s %9s %8s %8s\n', ...
    'Scenario','ACK cell','RMSE','Data[Hz]','ACK[Hz]','ackDeliv','estAoI', ...
    'staleAck','FormFail','SafeFail');

for iS = 1:nScenario
    for iA = 1:nAck
        fprintf('%-10s %-13s %8.4f %9.2f %8.2f %8.3f %8.3f %9.0f %8.2f %8.2f\n', ...
            scenarioNames{iS}, ackNames{iA}, ...
            meanRMSE(IDX_CAUSAL,iA,iS), meanTXRATE(IDX_CAUSAL,iA,iS), ...
            meanACKR(IDX_CAUSAL,iA,iS), meanDELIV(IDX_CAUSAL,iA,iS), ...
            meanESTAOI(IDX_CAUSAL,iA,iS), meanSTALE(IDX_CAUSAL,iA,iS), ...
            formFailRate(IDX_CAUSAL,iA,iS), safeFailRate(IDX_CAUSAL,iA,iS));
    end
    fprintf('\n');
end


%% ============================================================
% Baseline invariance
%
% P10 and P20 have no reverse channel. If any ACK setting reached
% them, the comparison would be meaningless.
% ============================================================

fprintf('============================================================\n');
fprintf('Baseline invariance across ACK cells\n');
fprintf('============================================================\n\n');

baselineDrift = 0;

for iS = 1:nScenario
    for iM = [IDX_P10 IDX_P20]
        spread = max(meanRMSE(iM,:,iS)) - min(meanRMSE(iM,:,iS));
        baselineDrift = max(baselineDrift, spread);
        fprintf('  %-10s %-10s RMSE spread across %d ACK cells: %.3e\n', ...
            scenarioNames{iS}, methodNames{iM}, nAck, spread);
    end
end

if baselineDrift < 1e-12
    fprintf('\n  Baselines are bit-identical everywhere: ACK settings do not leak.\n');
else
    fprintf('\n  *** BASELINES MOVED: ACK configuration is leaking into them ***\n');
end


%% ============================================================
% Degradation against the reliable-ACK reference
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('RMSE degradation versus reliable ACK\n');
fprintf('============================================================\n\n');

degradation = nan(nAck,nScenario);

fprintf('%-13s', 'ACK cell');
for iS = 1:nScenario
    fprintf(' %12s', scenarioNames{iS});
end
fprintf('\n');

for iA = 1:nAck
    fprintf('%-13s', ackNames{iA});
    for iS = 1:nScenario
        ref = meanRMSE(IDX_CAUSAL,IDX_RELIABLE,iS);
        degradation(iA,iS) = 100*(meanRMSE(IDX_CAUSAL,iA,iS) - ref)/ref;
        fprintf(' %11.2f%%', degradation(iA,iS));
    end
    fprintf('\n');
end


%% ============================================================
% Saturation analysis
%
% A degradation of exactly 0 % can mean two very different things:
% the protocol absorbed the impairment, or the trigger stopped
% being able to see it. adaptiveScale distinguishes them. Once it
% rests on scaleMin the trigger cannot tell 0.30 s of staleness
% from 0.46 s, so further ACK degradation changes no decision and a
% zero-degradation result is an artefact rather than robustness.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Adaptive-scale saturation\n');
fprintf('============================================================\n\n');

scaleFloor = 0.20;

fprintf('%-10s %-13s %9s %9s %10s\n', ...
    'Scenario','ACK cell','estAoI','scale','saturated');

nSaturated = zeros(nScenario,1);

for iS = 1:nScenario
    for iA = 1:nAck
        % Within 2 % of the floor. An exact-equality test is wrong here:
        % this is a mean over every trigger check, including the moments
        % just after an ACK lands when the estimate briefly drops, so it
        % settles near the floor rather than exactly on it.
        sat = meanSCALE(IDX_CAUSAL,iA,iS) <= scaleFloor * 1.02;
        nSaturated(iS) = nSaturated(iS) + sat;
        if sat
            mark = 'YES';
        else
            mark = '-';
        end
        fprintf('%-10s %-13s %9.3f %9.3f %10s\n', ...
            scenarioNames{iS}, ackNames{iA}, ...
            meanESTAOI(IDX_CAUSAL,iA,iS), meanSCALE(IDX_CAUSAL,iA,iS), mark);
    end
    fprintf('  %s: %d of %d cells saturated\n\n', ...
        scenarioNames{iS}, nSaturated(iS), nAck);
end


%% ============================================================
% Acceptance gates
%
% Thresholds from docs/PREREGISTRATION.md section 3.2, fixed before
% any of these numbers existed.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP07B acceptance gates\n');
fprintf('============================================================\n\n');

gateNames  = {};
gateValues = {};
gatePass   = [];

% --- Protocol invariants across every cell
totalViol = sum(sum(sum(VIOL(:,IDX_CAUSAL,:,:))));
gateNames{end+1}  = 'Protocol: invariants = 0 in every ACK cell';
gatePass(end+1)   = (totalViol == 0);
gateValues{end+1} = sprintf('%d violation(s) over %d cells', totalViol, nAck*nScenario);

% --- No deadlock: maxSilence must still bound link silence
worstGap = max(max(maxGAP(IDX_CAUSAL,:,:)));
gateNames{end+1}  = 'Protocol: no deadlock (gap <= maxSilence)';
gatePass(end+1)   = (worstGap <= maxSilence + dtSwarm + 1e-9);
gateValues{end+1} = sprintf('worst link silence %.3f s vs %.2f s', worstGap, maxSilence);

% --- Moderate degradation
modDeg = max(degradation(IDX_MODERATE,:));
gateNames{end+1}  = 'Moderate ACK impairment: degradation <= 10%';
gatePass(end+1)   = (modDeg <= 10);
gateValues{end+1} = sprintf('%.2f %% (worst scenario)', modDeg);

% --- Severe degradation
sevDeg = max(degradation(IDX_SEVERE,:));
gateNames{end+1}  = 'Severe ACK impairment: degradation <= 25%';
gatePass(end+1)   = (sevDeg <= 25);
gateValues{end+1} = sprintf('%.2f %% (worst scenario)', sevDeg);

% --- Safety at moderate
modSafe = max(safeFailRate(IDX_CAUSAL,IDX_MODERATE,:));
gateNames{end+1}  = 'Moderate ACK impairment: SafeFail <= 5%';
gatePass(end+1)   = (modSafe <= 0.05);
gateValues{end+1} = sprintf('%.2f', modSafe);

for q = 1:numel(gateNames)
    if gatePass(q); v = 'PASS'; else; v = 'FAIL'; end
    fprintf('  [%s] %-45s %s\n', v, gateNames{q}, gateValues{q});
end

nFailed = sum(~gatePass);

fprintf('\n');
if nFailed == 0
    fprintf('  EXP07B GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP07B GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, thresholds are NOT to be adjusted.\n');
end


%% ============================================================
% Reordering subtest
%
% Jitter is what actually produces out-of-order ACKs. If the stale
% count stays at zero here, the reordering path was never exercised
% and these cells prove nothing.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Reordering subtest (ACK jitter)\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-13s %10s %10s %10s %10s\n', ...
    'Scenario','ACK cell','staleAck','dupAck','RMSE','Data[Hz]');

meanDUP = reshape(mean(DUPACK,1), nMethod,nAck,nScenario);

for iS = 1:nScenario
    for iA = [IDX_MODERATE IDX_JITTER]
        fprintf('%-10s %-13s %10.0f %10.0f %10.4f %10.2f\n', ...
            scenarioNames{iS}, ackNames{iA}, ...
            meanSTALE(IDX_CAUSAL,iA,iS), meanDUP(IDX_CAUSAL,iA,iS), ...
            meanRMSE(IDX_CAUSAL,iA,iS), meanTXRATE(IDX_CAUSAL,iA,iS));
    end
    fprintf('\n');
end

jitterStale = sum(sum(meanSTALE(IDX_CAUSAL,IDX_JITTER,:)));

if jitterStale > 0
    fprintf('  Reordering path exercised: %.0f stale ACKs discarded.\n', jitterStale);
else
    fprintf('  *** No stale ACK under jitter: reordering never tested ***\n');
end


%% ============================================================
% Figures
% ============================================================

for iS = 1:nScenario

    figure('Name', sprintf('EXP07B RMSE vs ACK impairment - %s', scenarioNames{iS}));
    bar(squeeze(meanRMSE(IDX_CAUSAL,:,iS)));
    grid on;
    set(gca,'XTick',1:nAck,'XTickLabel',ackNames,'XTickLabelRotation',45);
    ylabel('Formation RMSE [m]');
    yline(meanRMSE(IDX_P10,1,iS),'--','P10');
    yline(meanRMSE(IDX_P20,1,iS),':','P20');
    title(sprintf('Causal-v3 under ACK impairment - %s', scenarioNames{iS}));

end

figure('Name','EXP07B degradation versus reliable ACK');
bar(degradation);
grid on;
set(gca,'XTick',1:nAck,'XTickLabel',ackNames,'XTickLabelRotation',45);
ylabel('RMSE degradation [%]');
yline(10,'--','moderate gate 10%');
yline(25,'-.','severe gate 25%');
legend(scenarioNames,'Location','northwest');
title('Degradation relative to a reliable ACK channel');


%% ============================================================
% Long-format results table
% ============================================================

T = tidyFromArray( ...
    struct( ...
        'RMSE',     RMSE, ...
        'MINEVAL',  MINEVAL, ...
        'AOI',      AOI, ...
        'TXRATE',   TXRATE, ...
        'ACKRATE',  ACKRATE, ...
        'ACKDELIV', ACKDELIV, ...
        'STALEACK', STALEACK, ...
        'DUPACK',   DUPACK, ...
        'MEANOUT',  MEANOUT, ...
        'MAXOUT',   MAXOUT, ...
        'MAXGAP',   MAXGAP, ...
        'HARDR',    HARDR, ...
        'ADAPTR',   ADAPTR, ...
        'REFRESHR', REFRESHR, ...
        'ESTAOI',    ESTAOI, ...
        'MEANSCALE', MEANSCALE, ...
        'MINSCALE',  MINSCALE, ...
        'VIOL',     VIOL, ...
        'FORMFAIL', double(FORMFAIL), ...
        'SAFEFAIL', double(SAFEFAIL)), ...
    {'seed','method','ackCell','scenario'}, ...
    {1:numSeeds, methodNames, ackNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));


fprintf('\nEXP07B completed.\n');


%% ============================================================
% Persist results
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);
