%% EXP07C - Communication cost realism
%
% EXP07A and EXP07B established what Causal-AoI-v3 does. This asks what it
% costs, under three different ways of pricing a transmission.
%
% ACCOUNTING ONLY. No policy, threshold, ACK, CRN or network behaviour
% changes. Every method runs exactly as it did in EXP07B; the only new thing
% is a passive counter recording unique (timestep, physical sender, payload
% class) DATA transmissions, and three cost functions applied afterwards.
%
% The question that matters: EXP07A and EXP07B reported DATA rate only. The
% proposed method also emits an ACK per accepted packet, which the baselines
% do not. Whether it remains competitive once that is priced in is exactly
% what a reviewer will ask.
%
% Cost families, from docs/PREREGISTRATION.md section 2.8:
%
%   packet-w    cost = nDATA + w*nACK,  w in {0.1, 0.25, 0.5}
%               Three variants of ONE family. The claim is supported only
%               if Causal is non-dominated for at least 2 of the 3.
%
%   airtime     DATA = 48 B, ACK = 24 B
%               Prices the fact that an ACK is a short frame.
%
%   broadcast   one radio transmission per (timestep, sender, payload class)
%               regardless of how many neighbours receive it; ACK stays
%               unicast. This is the model most favourable to periodic
%               schemes, which fire all their links together.
%
% Dominance uses the pre-registered 1 % rule: method M is dominated if some
% M' has BOTH RMSE <= 0.99*RMSE(M) AND cost <= 0.99*cost(M).
%
% EXP07C passes only if the Stressed conclusion holds under at least 2 of
% the 3 model families.
%
% ============================================================

startup;

close all;


%% ============================================================
% Result persistence
% ============================================================

expRun = startExperiment('exp07c_cost_model');


%% ============================================================
% Monte Carlo
%
% Debug pass. Reviewed before the 20-seed final pass, as the
% pre-registration requires.
% ============================================================

numSeeds = 3;


%% ============================================================
% Scenarios
% ============================================================

scenarioNames = {
    'Clean'
    'Moderate'
    'Stressed'
};

scenarioLoss  = [0.00; 0.20; 0.40];
scenarioDelay = [0.00; 0.08; 0.12];

nScenario = numel(scenarioNames);

IDX_STRESSED = 3;


%% ============================================================
% Methods
% ============================================================

methodNames = {
    'P10'
    'P20'
    'State-event'
    'Causal-v3'
};

nMethod = numel(methodNames);

IDX_P10    = 1;
IDX_P20    = 2;
IDX_EVENT  = 3;
IDX_CAUSAL = 4;


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


%% ============================================================
% Cost model constants
% ============================================================

packetW = [0.10 0.25 0.50];

nW = numel(packetW);

airtimeDataBytes = 48;
airtimeAckBytes  = 24;


cfg0 = defaultConfig();

nChannels = nnz(cfg0.swarm.A) + sum(cfg0.swarm.pin);


%% ============================================================
% Storage
% ============================================================

RMSE      = zeros(numSeeds,nMethod,nScenario);
MINEVAL   = zeros(numSeeds,nMethod,nScenario);
NDATA     = zeros(numSeeds,nMethod,nScenario);
NACK      = zeros(numSeeds,nMethod,nScenario);
NBROADCAST= zeros(numSeeds,nMethod,nScenario);
MISSION   = zeros(numSeeds,nMethod,nScenario);

FORMFAIL  = false(numSeeds,nMethod,nScenario);
SAFEFAIL  = false(numSeeds,nMethod,nScenario);


%% ============================================================
% Header
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP07C communication cost realism\n');
fprintf('============================================================\n\n');

fprintf('Seeds        : %d\n', numSeeds);
fprintf('Channels     : %d\n', nChannels);
fprintf('Accounting   : passive only, no behaviour change\n');
fprintf('ACK channel  : reliable, symmetric with the forward path\n');
fprintf('CRN          : forward and reverse traces both on\n\n');

fprintf('packet-w     : w = %s\n', mat2str(packetW));
fprintf('airtime      : DATA %d B, ACK %d B\n', airtimeDataBytes, airtimeAckBytes);
fprintf('broadcast    : unique (tick, sender, payload class); ACK unicast\n');


%% ============================================================
% Experiment
% ============================================================

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('%s | loss %.0f %% | delay %.0f ms\n', ...
        scenarioNames{iS}, ...
        100*scenarioLoss(iS), 1000*scenarioDelay(iS));
    fprintf('------------------------------------------------------------\n');

    for iM = 1:nMethod

        fprintf('  %-12s', methodNames{iM});

        rmseS  = zeros(numSeeds,1);
        minevS = zeros(numSeeds,1);
        ndataS = zeros(numSeeds,1);
        nackS  = zeros(numSeeds,1);
        nbcS   = zeros(numSeeds,1);
        misS   = zeros(numSeeds,1);

        parfor s = 1:numSeeds

            cfg = defaultConfig();

            cfg.net.packetLoss = scenarioLoss(iS);
            cfg.net.delay      = scenarioDelay(iS);
            cfg.net.jitterStd  = 0;

            cfg.net.seed = 1600000 + 10000*iS + s;

            cfg.net.useTrace    = true;
            cfg.net.phaseOffset = false;

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

            % Reliable symmetric ACK, as in EXP07B's reference cell.
            cfg.ack.loss             = 0.0;
            cfg.ack.delay            = scenarioDelay(iS);
            cfg.ack.jitterStd        = 0;
            cfg.ack.useTrace         = true;
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
                case IDX_EVENT
                    out = simSwarmEventTriggered(cfg);
                case IDX_CAUSAL
                    out = simSwarmAoICausal(cfg);
            end

            M = computeSwarmMetrics(out, cfg);

            rmseS(s)  = M.formationRMSE;
            minevS(s) = M.minSeparationEval;

            ndataS(s) = out.txCount;
            nbcS(s)   = out.broadcastCount;
            misS(s)   = out.t(end) - out.t(1);

            if isfield(out,'ackTxCount')
                nackS(s) = out.ackTxCount;
            else
                nackS(s) = 0;
            end

        end

        RMSE(:,iM,iS)       = rmseS;
        MINEVAL(:,iM,iS)    = minevS;
        NDATA(:,iM,iS)      = ndataS;
        NACK(:,iM,iS)       = nackS;
        NBROADCAST(:,iM,iS) = nbcS;
        MISSION(:,iM,iS)    = misS;

        FORMFAIL(:,iM,iS) = rmseS  > formationThreshold;
        SAFEFAIL(:,iM,iS) = minevS < safetyThreshold;

        fprintf(' done\n');

    end

end


%% ============================================================
% Passive-accounting invariants
%
% The counter must be arithmetically consistent with the run it
% describes. These check the accounting itself, not the protocol.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Passive-accounting invariants\n');
fprintf('============================================================\n\n');

accFail = 0;

% 1. Deduplication can only ever reduce the count.
if all(NBROADCAST(:) <= NDATA(:) + 1e-9)
    fprintf('  ok   broadcast <= unicast everywhere\n');
else
    fprintf('  FAIL broadcast exceeds unicast somewhere\n');
    accFail = accFail + 1;
end

% 2. A sender cannot dedupe below one transmission per payload class,
%    so the count cannot fall under nData / maxFanout.
maxFanout = max(sum(cfg0.swarm.A ~= 0, 1));

if all(NBROADCAST(:) >= NDATA(:)/max(maxFanout,1) - 1e-9)
    fprintf('  ok   broadcast >= unicast / maxFanout (%d)\n', maxFanout);
else
    fprintf('  FAIL broadcast below the dedup lower bound\n');
    accFail = accFail + 1;
end

% 3. Only the causal method has a reverse channel.
noAck = NACK(:,[IDX_P10 IDX_P20 IDX_EVENT],:);

if all(noAck(:) == 0)
    fprintf('  ok   baselines emit no ACK\n');
else
    fprintf('  FAIL a baseline emitted ACK traffic\n');
    accFail = accFail + 1;
end

% 4. Periodic broadcast count is exactly predictable: one send per
%    payload class per comm tick. This is the strongest check available.
nSenderClass = numel(unique([find(any(cfg0.swarm.A ~= 0, 1))])) + 1;

expectedP10 = round(cfg0.swarm.T / 0.10) * nSenderClass;
expectedP20 = round(cfg0.swarm.T / 0.05) * nSenderClass;

gotP10 = mean(mean(NBROADCAST(:,IDX_P10,:)));
gotP20 = mean(mean(NBROADCAST(:,IDX_P20,:)));

if abs(gotP10 - expectedP10) < 1e-9 && abs(gotP20 - expectedP20) < 1e-9
    fprintf('  ok   periodic broadcast exact: P10 %d, P20 %d (%d payload classes)\n', ...
        expectedP10, expectedP20, nSenderClass);
else
    fprintf('  FAIL periodic broadcast %g/%g, expected %d/%d\n', ...
        gotP10, gotP20, expectedP10, expectedP20);
    accFail = accFail + 1;
end

if accFail == 0
    fprintf('\n  Accounting invariants: PASS\n');
else
    fprintf('\n  Accounting invariants: %d FAILED\n', accFail);
end


%% ============================================================
% Aggregate and cost models
% ============================================================

meanRMSE = reshape(mean(RMSE,1), nMethod,nScenario);
meanData = reshape(mean(NDATA,1), nMethod,nScenario);
meanAck  = reshape(mean(NACK,1), nMethod,nScenario);
meanBc   = reshape(mean(NBROADCAST,1), nMethod,nScenario);
meanMis  = reshape(mean(MISSION,1), nMethod,nScenario);

safeFailRate = reshape(mean(SAFEFAIL,1), nMethod,nScenario);
formFailRate = reshape(mean(FORMFAIL,1), nMethod,nScenario);

% Cost families, all expressed as units per second.
nFamily = 3;

familyNames = {'packet-w', 'airtime', 'broadcast'};

% packet-w carries three variants; the other two carry one each.
costPacketW = zeros(nMethod,nScenario,nW);

for iW = 1:nW
    costPacketW(:,:,iW) = (meanData + packetW(iW)*meanAck) ./ meanMis;
end

costAirtime = (airtimeDataBytes*meanData + airtimeAckBytes*meanAck) ./ meanMis;

costBroadcast = (meanBc + meanAck) ./ meanMis;


%% ============================================================
% Cost table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('DATA / ACK / TOTAL accounting\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %9s %9s %9s %10s %9s\n', ...
    'Scenario','Method','RMSE','DATA/s','ACK/s','BCAST/s','SafeFail');

for iS = 1:nScenario
    for iM = 1:nMethod
        fprintf('%-10s %-12s %9.4f %9.2f %9.2f %10.2f %9.2f\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            meanRMSE(iM,iS), ...
            meanData(iM,iS)/meanMis(iM,iS), ...
            meanAck(iM,iS)/meanMis(iM,iS), ...
            meanBc(iM,iS)/meanMis(iM,iS), ...
            safeFailRate(iM,iS));
    end
    fprintf('\n');
end


%% ============================================================
% Dominance under each cost model
%
% Pre-registered 1 % rule: M is dominated if some M' has BOTH
% RMSE <= 0.99*RMSE(M) AND cost <= 0.99*cost(M).
% ============================================================

fprintf('============================================================\n');
fprintf('Pareto status of Causal-v3 under each cost model\n');
fprintf('============================================================\n\n');

% Assemble every cost variant into one list for uniform handling.
variantNames = cell(0);
variantCost  = {};
variantFamily = [];

for iW = 1:nW
    variantNames{end+1} = sprintf('packet-w %.2f', packetW(iW)); %#ok<SAGROW>
    variantCost{end+1}  = costPacketW(:,:,iW); %#ok<SAGROW>
    variantFamily(end+1) = 1; %#ok<SAGROW>
end

variantNames{end+1}  = 'airtime';
variantCost{end+1}   = costAirtime;
variantFamily(end+1) = 2;

variantNames{end+1}  = 'broadcast';
variantCost{end+1}   = costBroadcast;
variantFamily(end+1) = 3;

nVariant = numel(variantNames);

nonDominated = false(nVariant,nScenario);

fprintf('%-16s', 'Cost variant');
for iS = 1:nScenario
    fprintf(' %14s', scenarioNames{iS});
end
fprintf('\n');

for iV = 1:nVariant

    C = variantCost{iV};

    fprintf('%-16s', variantNames{iV});

    for iS = 1:nScenario

        dominated = false;
        dominator = '';

        for iM = 1:nMethod

            if iM == IDX_CAUSAL
                continue;
            end

            betterRMSE = meanRMSE(iM,iS) <= 0.99*meanRMSE(IDX_CAUSAL,iS);
            betterCost = C(iM,iS)        <= 0.99*C(IDX_CAUSAL,iS);

            if betterRMSE && betterCost
                dominated = true;
                dominator = methodNames{iM};
            end

        end

        nonDominated(iV,iS) = ~dominated;

        if dominated
            fprintf(' %14s', ['dom by ' dominator]);
        else
            fprintf(' %14s', 'non-dom');
        end

    end

    fprintf('\n');

end


%% ============================================================
% Acceptance gates
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP07C acceptance gates\n');
fprintf('============================================================\n\n');

% packet-w counts as supporting only if >= 2 of its 3 variants hold.
wSupport = sum(nonDominated(variantFamily == 1, IDX_STRESSED));

familySupport = false(nFamily,1);

familySupport(1) = (wSupport >= 2);
familySupport(2) = nonDominated(variantFamily == 2, IDX_STRESSED);
familySupport(3) = nonDominated(variantFamily == 3, IDX_STRESSED);

nSupport = sum(familySupport);

gateNames  = {};
gateValues = {};
gatePass   = [];

gateNames{end+1}  = 'Accounting invariants';
gatePass(end+1)   = (accFail == 0);
gateValues{end+1} = sprintf('%d failure(s)', accFail);

gateNames{end+1}  = 'packet-w: non-dominated in >= 2/3 variants';
gatePass(end+1)   = familySupport(1);
gateValues{end+1} = sprintf('%d of 3 variants', wSupport);

gateNames{end+1}  = 'Stressed conclusion holds in >= 2/3 families';
gatePass(end+1)   = (nSupport >= 2);
gateValues{end+1} = sprintf('%d of 3 families (%s)', nSupport, ...
    strjoin(familyNames(familySupport), ', '));

for q = 1:numel(gateNames)
    if gatePass(q); v = 'PASS'; else; v = 'FAIL'; end
    fprintf('  [%s] %-46s %s\n', v, gateNames{q}, gateValues{q});
end

nFailed = sum(~gatePass);

fprintf('\n');
if nFailed == 0
    fprintf('  EXP07C GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP07C GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Figures
% ============================================================

figure('Name','EXP07C cost versus error, packet-w 0.25');
hold on; grid on;
markers = {'o','s','^','d'};
for iM = 1:nMethod
    plot(squeeze(costPacketW(iM,:,2)), meanRMSE(iM,:), ['-' markers{iM}], ...
        'LineWidth',1.3,'MarkerSize',8);
end
xlabel('Cost [units/s], packet-w w=0.25');
ylabel('Formation RMSE [m]');
title('Cost versus error (each line spans Clean to Stressed)');
legend(methodNames,'Location','northeast');
hold off;

figure('Name','EXP07C cost by model family, Stressed');
bar([squeeze(costPacketW(:,IDX_STRESSED,2)) ...
     costAirtime(:,IDX_STRESSED)/10 ...
     costBroadcast(:,IDX_STRESSED)]);
grid on;
set(gca,'XTickLabel',methodNames);
ylabel('Cost [units/s]');
legend({'packet-w 0.25','airtime /10','broadcast'},'Location','northwest');
title('Stressed: cost under each model family');


%% ============================================================
% Long-format results table
% ============================================================

T = tidyFromArray( ...
    struct( ...
        'RMSE',       RMSE, ...
        'MINEVAL',    MINEVAL, ...
        'NDATA',      NDATA, ...
        'NACK',       NACK, ...
        'NBROADCAST', NBROADCAST, ...
        'MISSION',    MISSION, ...
        'FORMFAIL',   double(FORMFAIL), ...
        'SAFEFAIL',   double(SAFEFAIL)), ...
    {'seed','method','scenario'}, ...
    {1:numSeeds, methodNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));


fprintf('\nEXP07C completed.\n');


%% ============================================================
% Persist results
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);
