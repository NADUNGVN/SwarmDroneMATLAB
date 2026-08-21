%% EXP08B - Link failure and burst outage
%
% Original controller (normalizeConsensusDegree off) and frozen
% Causal-AoI-v3. No policy, threshold, ACK, CRN or accounting change.
%
% Link failures are modelled EXCLUSIVELY at the network-delivery layer.
% cfg.swarm.A is never modified during a fault, so the controller keeps
% trying to use a dead link exactly as a real one would, and the channel
% count stays fixed so communication cost remains comparable across fault
% levels. Editing A instead would change the control problem and the cost
% denominator at once, and the two could not be separated afterwards.
%
% Fault realizations are common across methods: which links die, and when,
% depends only on the seed and the nominal graph. Otherwise a difference
% between methods would mix the policy with the luck of the draw.
%
% Conditions:
%
%   none                     nominal
%   permanent 10 / 20 / 30%  links dead for the whole run
%   burst 2 s / 5 s          30% of links drop out from t = 12 s and return
%
% Connectivity classification uses the ACTIVE graph. Two separate facts are
% reported, because they are not the same thing:
%
%   lambda2 > 0          the graph still hangs together
%   isolatedFollowers    followers that lost EVERY consensus in-link
%
% A follower can keep lambda2 > 0 through its leader pin alone while having
% no relative information at all. Reading "connected" as "every follower
% still has neighbours" would be wrong.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp08b_link_failure');


%% ============================================================
% Scope
% ============================================================

numSeeds = 3;

topologyNames = {'ring2'; 'sparse4'};

nTopo = numel(topologyNames);

swarmN = 20;

scenarioNames = {'Moderate'; 'Stressed'};

scenarioLoss  = [0.20; 0.40];
scenarioDelay = [0.08; 0.12];

nScenario = numel(scenarioNames);


faultNames  = {'none'; 'perm 10%'; 'perm 20%'; 'perm 30%'; 'burst 2s'; 'burst 5s'};
faultTypes  = {'none'; 'permanent'; 'permanent'; 'permanent'; 'burst'; 'burst'};
faultLevels = [0; 0.10; 0.20; 0.30; 2.0; 5.0];

nFault = numel(faultNames);

IDX_BURST = [5 6];


methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

nMethod = numel(methodNames);

IDX_P10    = 1;
IDX_P20    = 2;
IDX_CAUSAL = 4;


%% ============================================================
% Locked parameters
% ============================================================

epsP = 0.05;  epsV = 0.10;
aoiThreshold = 0.12;  aoiCooldown = 0.10;  maxSilence = 0.50;

safetyThreshold = 0.25;


%% ============================================================
% Fault classification, before any simulation
%
% Classification must be done on the realization that is actually
% simulated. The fault draw depends on cfg.net.seed, so it varies with
% seed, topology and scenario; classifying one representative seed and
% applying the verdict to all of them would exclude, or fail to
% exclude, the wrong runs.
%
% The classification itself is unchanged: symmetrised graph including
% leader-pin edges, connected <=> lambda2 > 1e-9, per section 2.4.
% Active consensus in-degree and isolated followers are reported
% ALONGSIDE it, not in place of it.
% ============================================================

CONNSEED = false(numSeeds, nFault, nTopo, nScenario);
L2SEED   = zeros(numSeeds, nFault, nTopo, nScenario);
ISOSEED  = zeros(numSeeds, nFault, nTopo, nScenario);
DEGSEED  = zeros(numSeeds, nFault, nTopo, nScenario);

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault
            for s = 1:numSeeds

                cfgT = applyTopologyConfig(defaultConfig(), swarmN, topologyNames{iT});
                cfgT.net.seed = 1800000 + 10000*iS + 1000*iT + s;

                f = generateFaultRealization(cfgT, faultTypes{iF}, faultLevels(iF));
                g = graphConnectivity(f.activeA, cfgT.swarm.pin);

                CONNSEED(s,iF,iT,iS) = g.connected;
                L2SEED(s,iF,iT,iS)   = g.lambda2;
                ISOSEED(s,iF,iT,iS)  = f.isolatedFollowers;
                DEGSEED(s,iF,iT,iS)  = f.activeInDegreeMean;

            end
        end
    end
end

nConn = squeeze(sum(CONNSEED,1));

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP08B link failure and burst outage\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-10s %-10s %9s %9s %10s %9s %12s\n', ...
    'Scenario','Topology','Fault','minL2','maxL2','connected','maxIso','activeInDeg');

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault

            l2 = L2SEED(:,iF,iT,iS);

            fprintf('%-10s %-10s %-10s %9.4f %9.4f %6d /%2d %9d %12.2f\n', ...
                scenarioNames{iS}, topologyNames{iT}, faultNames{iF}, ...
                min(l2), max(l2), nConn(iF,iT,iS), numSeeds, ...
                max(ISOSEED(:,iF,iT,iS)), mean(DEGSEED(:,iF,iT,iS)));

        end
    end
end

fprintf(['\n  Seeds with lambda2 = 0 belong to the connectivity\n' ...
         '  impossibility region and are excluded from gate arithmetic.\n' ...
         '  A condition with no connected seed is excluded entirely.\n']);

fprintf(['\n  isolated = followers holding zero consensus in-links while\n' ...
         '  lambda2 may still be positive through the leader pin. Such a\n' ...
         '  follower has no relative information at all, so its trajectory\n' ...
         '  is identical under every communication policy.\n']);


%% ============================================================
% Storage
% ============================================================

sz = [numSeeds nMethod nFault nTopo nScenario];

RMSE     = zeros(sz);
MINEVAL  = zeros(sz);
PEAKERR  = zeros(sz);
RECOVERY = nan(sz);
PEAKAOI  = zeros(sz);
NDATA    = zeros(sz);
NACK     = zeros(sz);
MISSION  = zeros(sz);
SAFEFAIL = false(sz);

% Passive diagnostics required by section 4.2. Reported, never gated.
MINSEPFAULT = zeros(sz);
TXFAULT     = zeros(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\nSeeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n--- %s ---\n', scenarioNames{iS});

    for iT = 1:nTopo
        for iF = 1:nFault

            fprintf('  %-10s %-10s', topologyNames{iT}, faultNames{iF});

            for iM = 1:nMethod

                rmseS = zeros(numSeeds,1);
                minvS = zeros(numSeeds,1);
                peakS = zeros(numSeeds,1);
                recvS = nan(numSeeds,1);
                paoiS = zeros(numSeeds,1);
                ndatS = zeros(numSeeds,1);
                nackS = zeros(numSeeds,1);
                misS  = zeros(numSeeds,1);
                msfS  = zeros(numSeeds,1);
                txfS  = zeros(numSeeds,1);

                parfor s = 1:numSeeds

                    cfg = applyTopologyConfig(defaultConfig(), swarmN, topologyNames{iT});

                    % Original controller, explicitly.
                    cfg.swarm.normalizeConsensusDegree = false;

                    cfg.net.packetLoss = scenarioLoss(iS);
                    cfg.net.delay      = scenarioDelay(iS);
                    cfg.net.jitterStd  = 0;

                    cfg.net.seed = 1800000 + 10000*iS + 1000*iT + s;

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

                    cfg.event.posThreshold = epsP;
                    cfg.event.velThreshold = epsV;
                    cfg.event.maxSilence   = maxSilence;

                    cfg.ack.loss      = 0.0;
                    cfg.ack.delay     = scenarioDelay(iS);
                    cfg.ack.jitterStd = 0;
                    cfg.ack.useTrace  = true;
                    cfg.ack.assertInvariants = true;

                    cfg.causal.useAdaptiveScale   = true;
                    cfg.causal.useAckFeedback     = true;
                    cfg.causal.innovationPriority = true;

                    % Common fault realization: seeded, method independent.
                    cfg.fault = generateFaultRealization(cfg, ...
                        faultTypes{iF}, faultLevels(iF));

                    switch iM
                        case 1
                            cfg.net.commPeriod = 0.10;
                            out = simSwarmNetworkQueued(cfg);
                        case 2
                            cfg.net.commPeriod = 0.05;
                            out = simSwarmNetworkQueued(cfg);
                        case 3
                            out = simSwarmEventTriggered(cfg);
                        case 4
                            out = simSwarmAoICausal(cfg);
                    end

                    M = computeSwarmMetrics(out, cfg);

                    rmseS(s) = M.formationRMSE;
                    minvS(s) = M.minSeparationEval;

                    ndatS(s) = out.txCount;
                    misS(s)  = out.t(end) - out.t(1);

                    if isfield(out,'ackTxCount')
                        nackS(s) = out.ackTxCount;
                    end

                    % Worst follower error over time.
                    e = max(M.formationError(:,2:end), [], 2);

                    tF = cfg.fault.tStart;
                    tR = cfg.fault.tEnd;

                    % Section 2.3 as amended: peak error and peak AoI are
                    % evaluated from max(tFault, 8 s). A permanent fault
                    % begins at t = 0, so the original window swallowed the
                    % startup transient and the peak came out
                    % method-independent. Bursts begin at 12 s and are
                    % unaffected by the correction.
                    tPeak = max(tF, 8);

                    peakS(s) = max(e(out.t >= tPeak));
                    paoiS(s) = max(out.meanAoI(out.t >= tPeak));

                    if ~strcmpi(faultTypes{iF}, 'none')
                        recvS(s) = recoveryTime(out.t, e, tF, tR);
                    end

                    % Passive diagnostics, section 4.2.
                    [msfS(s), txfS(s)] = faultWindowStats( ...
                        out, tPeak, min(tR, out.t(end)));

                end

                RMSE(:,iM,iF,iT,iS)     = rmseS;
                MINEVAL(:,iM,iF,iT,iS)  = minvS;
                PEAKERR(:,iM,iF,iT,iS)  = peakS;
                RECOVERY(:,iM,iF,iT,iS) = recvS;
                PEAKAOI(:,iM,iF,iT,iS)  = paoiS;
                NDATA(:,iM,iF,iT,iS)    = ndatS;
                NACK(:,iM,iF,iT,iS)     = nackS;
                MISSION(:,iM,iF,iT,iS)  = misS;

                MINSEPFAULT(:,iM,iF,iT,iS) = msfS;
                TXFAULT(:,iM,iF,iT,iS)     = txfS;

                SAFEFAIL(:,iM,iF,iT,iS) = minvS < safetyThreshold;

            end

            fprintf('  done\n');

        end
    end

end


% Every aggregate is taken over the CONNECTED seeds of that condition
% only. A seed whose active graph fell apart is in the connectivity
% impossibility region, and a policy is not judged on it. Because the
% fault draw varies with seed, this mask is per seed, not per
% condition.

dims = [nMethod nFault nTopo nScenario];

meanRMSE  = nan(dims);
meanMIN   = nan(dims);
meanPEAK  = nan(dims);
meanAOIP  = nan(dims);
safeRate  = nan(dims);
rateData  = nan(dims);
meanMSF   = nan(dims);
meanTXF   = nan(dims);
meanRECOV = nan(dims);
anyNaNRec = false(dims);

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault

            m = CONNSEED(:,iF,iT,iS);

            if ~any(m)
                continue;
            end

            for iM = 1:nMethod

                meanRMSE(iM,iF,iT,iS) = mean(RMSE(m,iM,iF,iT,iS));
                meanMIN(iM,iF,iT,iS)  = mean(MINEVAL(m,iM,iF,iT,iS));
                meanPEAK(iM,iF,iT,iS) = mean(PEAKERR(m,iM,iF,iT,iS));
                meanAOIP(iM,iF,iT,iS) = mean(PEAKAOI(m,iM,iF,iT,iS));
                safeRate(iM,iF,iT,iS) = mean(SAFEFAIL(m,iM,iF,iT,iS));
                meanMSF(iM,iF,iT,iS)  = mean(MINSEPFAULT(m,iM,iF,iT,iS));
                meanTXF(iM,iF,iT,iS)  = mean(TXFAULT(m,iM,iF,iT,iS));

                rateData(iM,iF,iT,iS) = ...
                    mean(NDATA(m,iM,iF,iT,iS)) / mean(MISSION(m,iM,iF,iT,iS));

                % Recovery may be NaN when the run never returns to
                % baseline. NaN counts as a failure per section 2.2, so
                % it is carried through rather than averaged away.
                meanRECOV(iM,iF,iT,iS) = mean(RECOVERY(m,iM,iF,iT,iS));
                anyNaNRec(iM,iF,iT,iS) = any(isnan(RECOVERY(m,iM,iF,iT,iS)));

            end

        end
    end
end


%% ============================================================
% Results
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Results\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-10s %-10s %-12s %8s %8s %8s %9s %9s %8s %10s %11s %7s %7s\n', ...
    'Scenario','Topology','Fault','Method','RMSE','minSep','peakErr','recovery','peakAoI','DATA/s', ...
    'minSepFlt','fltDATA/s','nConn','maxIso');

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault
            for iM = 1:nMethod
                fprintf('%-10s %-10s %-10s %-12s %8.4f %8.4f %8.4f %9.3f %9.3f %8.1f %10.4f %11.1f %7d %7d\n', ...
                    scenarioNames{iS}, topologyNames{iT}, faultNames{iF}, methodNames{iM}, ...
                    meanRMSE(iM,iF,iT,iS), meanMIN(iM,iF,iT,iS), meanPEAK(iM,iF,iT,iS), ...
                    meanRECOV(iM,iF,iT,iS), meanAOIP(iM,iF,iT,iS), rateData(iM,iF,iT,iS), ...
                    meanMSF(iM,iF,iT,iS), meanTXF(iM,iF,iT,iS), ...
                    nConn(iF,iT,iS), max(ISOSEED(:,iF,iT,iS)));
            end
            fprintf('\n');
        end
    end
end


%% ============================================================
% Gates, per section 4.2
% ============================================================

fprintf('============================================================\n');
fprintf('EXP08B acceptance gates\n');
fprintf('============================================================\n\n');

% The SafeFail gate is only evaluable once the seed count can resolve
% 5 %. At 3 seeds the finest non-zero rate is 1/3, so "<= 5 %" would
% collapse into "= 0", and any verdict would report the seed count
% rather than the method. At 20 seeds 0/20 and 1/20 pass while 2/20 or
% more fails, which is exactly the intended threshold. The gate itself
% is unchanged: absolute, and applied to every connected condition.
safeEvaluable = numSeeds >= 20;

safeBreach = 0; safeCount = 0;
recBreach  = 0; recCount  = 0;
peakBreach = 0; peakCount = 0;
excluded   = 0;
partial    = 0;

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault

            if ~any(CONNSEED(:,iF,iT,iS))
                excluded = excluded + 1;
                continue;
            end

            partial = partial + (nConn(iF,iT,iS) < numSeeds);

            safeCount = safeCount + 1;
            if safeRate(IDX_CAUSAL,iF,iT,iS) > 0.05
                safeBreach = safeBreach + 1;
            end

            peakCount = peakCount + 1;
            if meanPEAK(IDX_CAUSAL,iF,iT,iS) > 1.25*meanPEAK(IDX_P10,iF,iT,iS)
                peakBreach = peakBreach + 1;
            end

            if ismember(iF, IDX_BURST)
                recCount = recCount + 1;
                rc = meanRECOV(IDX_CAUSAL,iF,iT,iS);
                r2 = meanRECOV(IDX_P20,iF,iT,iS);
                if isnan(rc) || anyNaNRec(IDX_CAUSAL,iF,iT,iS) || rc > 1.25*r2
                    recBreach = recBreach + 1;
                end
            end

        end
    end
end

gateNames  = {'SafeFail <= 5% (connected)', ...
              'Recovery <= 1.25 x P20 (burst)', ...
              'Peak error <= 1.25 x P10'};
gatePass   = [safeBreach == 0, recBreach == 0, peakBreach == 0];
gateValues = {sprintf('%d of %d breached', safeBreach, safeCount), ...
              sprintf('%d of %d breached', recBreach, recCount), ...
              sprintf('%d of %d breached', peakBreach, peakCount)};

gateStatus = cell(size(gateNames));

for q = 1:numel(gateNames)
    if q == 1 && ~safeEvaluable
        gateStatus{q} = 'DEFER';
    elseif gatePass(q)
        gateStatus{q} = 'PASS';
    else
        gateStatus{q} = 'FAIL';
    end
end

if ~safeEvaluable
    gateValues{1} = sprintf('%d of %d conditions with >5%% at %d seeds - NOT EVALUABLE', ...
        safeBreach, safeCount, numSeeds);
end

for q = 1:numel(gateNames)
    fprintf('  [%-5s] %-38s %s\n', gateStatus{q}, gateNames{q}, gateValues{q});
end

fprintf('\n  Excluded entirely (impossibility region): %d condition(s)\n', excluded);
fprintf('  Partially excluded (some seeds disconnected): %d condition(s)\n', partial);


% Passive diagnostic. A breach shared by every method is a property of
% the condition, not of the policy, and the gate alone cannot tell the
% two apart.
fprintf('\n  SafeFail > 5%% per method, over connected conditions:\n');

for iM = 1:nMethod
    c = 0;
    for iS = 1:nScenario
        for iT = 1:nTopo
            for iF = 1:nFault
                if any(CONNSEED(:,iF,iT,iS)) && safeRate(iM,iF,iT,iS) > 0.05
                    c = c + 1;
                end
            end
        end
    end
    fprintf('    %-12s %d of %d\n', methodNames{iM}, c, safeCount);
end


% Passive diagnostic. A follower holding zero consensus in-links is
% driven by its leader pin alone, so its trajectory is bit-identical
% under every policy. When it is also the worst follower, E_max is the
% same for all methods and the Peak gate cannot discriminate. Counting
% these tells the reader how much of that gate actually carried
% information. Reported only; the gate is unchanged.
degen = 0; degenIso = 0; conSeeds = 0;

for iS = 1:nScenario
    for iT = 1:nTopo
        for iF = 1:nFault
            for s = 1:numSeeds

                if ~CONNSEED(s,iF,iT,iS)
                    continue;
                end

                conSeeds = conSeeds + 1;

                pk = PEAKERR(s,:,iF,iT,iS);

                if (max(pk) - min(pk)) < 1e-6
                    degen = degen + 1;
                    degenIso = degenIso + (ISOSEED(s,iF,iT,iS) > 0);
                end

            end
        end
    end
end

fprintf(['\n  Peak error identical across all methods: %d of %d ' ...
         'connected seed-conditions\n'], degen, conSeeds);
fprintf('    of which with >=1 isolated follower: %d\n', degenIso);

nFailed = sum(strcmp(gateStatus,'FAIL'));
nDefer  = sum(strcmp(gateStatus,'DEFER'));

fprintf('\n');
if nDefer > 0
    fprintf('  EXP08B GATES: %d PASS, %d FAIL, %d DEFERRED to the 20-seed run\n', ...
        sum(strcmp(gateStatus,'PASS')), nFailed, nDefer);
    fprintf('  No EXP08B verdict follows from this run.\n');
elseif nFailed == 0
    fprintf('  EXP08B GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP08B GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Table
% ============================================================

% Connectivity is a property of the fault realization, not of the
% method, so it is replicated across the method dimension to travel
% with every row.
CONNCOL = repmat(reshape(double(CONNSEED), [numSeeds 1 nFault nTopo nScenario]), ...
    [1 nMethod 1 1 1]);
ISOCOL  = repmat(reshape(ISOSEED,          [numSeeds 1 nFault nTopo nScenario]), ...
    [1 nMethod 1 1 1]);
L2COL   = repmat(reshape(L2SEED,           [numSeeds 1 nFault nTopo nScenario]), ...
    [1 nMethod 1 1 1]);

T = tidyFromArray( ...
    struct('RMSE',RMSE,'MINEVAL',MINEVAL,'PEAKERR',PEAKERR, ...
           'RECOVERY',RECOVERY,'PEAKAOI',PEAKAOI,'NDATA',NDATA, ...
           'NACK',NACK,'MISSION',MISSION,'SAFEFAIL',double(SAFEFAIL), ...
           'MINSEPFAULT',MINSEPFAULT,'TXFAULT',TXFAULT, ...
           'CONNECTED',CONNCOL,'ISOLATED',ISOCOL,'LAMBDA2',L2COL), ...
    {'seed','method','fault','topology','scenario'}, ...
    {1:numSeeds, methodNames, faultNames, topologyNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP08B completed.\n');


save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTION
%
% Recovery time, per docs/PREREGISTRATION.md section 2.2.
%
% Baseline is the mean worst-follower error over the 3 s before the
% fault. Recovery is the earliest time after clearance at which the
% error stays within 1.1 x baseline for a full second. Never reaching
% that returns NaN, which the gate counts as a failure.
% ============================================================

function T = recoveryTime(t, e, tFault, tClear)

if isinf(tClear)
    % Permanent fault: nothing is ever restored, so recovery is
    % undefined rather than infinite.
    T = NaN;
    return;
end

base = mean(e(t >= tFault-3 & t < tFault));

if ~isfinite(base) || base <= 0
    T = NaN;
    return;
end

limit = 1.1 * base;

idx = find(t >= tClear);

for a = 1:numel(idx)

    k = idx(a);

    window = t >= t(k) & t <= t(k) + 1.0;

    if ~any(t > t(k) + 1.0)
        break;   % not enough run left to confirm
    end

    if all(e(window) <= limit)
        T = t(k) - tClear;
        return;
    end

end

T = NaN;

end


%% ============================================================
% LOCAL FUNCTION
%
% Passive diagnostics over the fault window, per section 4.2.
%
% minSepFault  minimum pairwise separation while the fault is active.
%              M.minSeparationEval covers the whole evaluation window,
%              so it cannot say whether a close approach happened
%              during the outage or after it.
%
% txRateFault  DATA transmissions per second inside the same window,
%              from the passive cumulative log. The run total cannot
%              resolve this: a policy that surges during an outage and
%              a policy that stays flat can share a run average.
%
% Neither quantity is gated.
% ============================================================

function [minSepFault, txRateFault] = faultWindowStats(out, tA, tB)

idx = find(out.t >= tA & out.t <= tB);

if numel(idx) < 2
    minSepFault = NaN;
    txRateFault = NaN;
    return;
end

P = out.P(idx,:,:);

N = size(P,2);

d2min = inf;

for a = 1:N-1
    da = P(:,a,:) - P(:,a+1:N,:);
    d2 = sum(da.^2, 3);
    d2min = min(d2min, min(d2(:)));
end

minSepFault = sqrt(d2min);

span = out.t(idx(end)) - out.t(idx(1));

if span <= 0
    txRateFault = NaN;
else
    txRateFault = (out.txCountLog(idx(end)) - out.txCountLog(idx(1))) / span;
end

end
