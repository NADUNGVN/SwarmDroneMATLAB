%% EXP08C - Node communication blackout
%
% Original controller (normalizeConsensusDegree off) and frozen
% Causal-AoI-v3. No policy, threshold, ACK, CRN or accounting change.
%
% A blackout is a COMMUNICATION-LAYER fault. The chosen follower cannot
% send DATA, receive DATA, send ACK or receive ACK; its dynamics and
% controller keep running, and cfg.swarm.A is never modified.
%
% Safety is measured against MATCHED NO-FAULT ELIGIBILITY, per section 4.3:
% a seed counts only if the same method / scenario / topology / N / seed was
% already safe without the fault. A configuration that was unsafe to begin
% with is not evidence about blackouts, and counting it would let a
% pre-existing geometry problem masquerade as a communication failure.
%
% Connectivity is judged on the subgraph induced by the nodes still
% radiating. A dark node is cut off by construction; that is the
% intervention, not an impossibility.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp08c_node_blackout');


%% ============================================================
% Scope
% ============================================================

numSeeds = 20;

swarmSizes = [10 20];

topologyNames = {'ring2'; 'sparse4'};

scenarioNames = {'Moderate'; 'Stressed'};
scenarioLoss  = [0.20; 0.40];
scenarioDelay = [0.08; 0.12];

methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

faultNames  = {'none'; '1node 2s'; '1node 5s'; '2node 2s'; '2node 5s'};
faultNodes  = [0; 1; 1; 2; 2];
faultDur    = [0; 2; 5; 2; 5];

nN        = numel(swarmSizes);
nTopo     = numel(topologyNames);
nScenario = numel(scenarioNames);
nMethod   = numel(methodNames);
nFault    = numel(faultNames);

IDX_NONE   = 1;
IDX_1NODE  = [2 3];
IDX_2NODE  = [4 5];

IDX_P20    = 2;
IDX_CAUSAL = 4;


%% ============================================================
% Locked parameters
% ============================================================

epsP = 0.05;  epsV = 0.10;
aoiThreshold = 0.12;  aoiCooldown = 0.10;  maxSilence = 0.50;

safetyThreshold = 0.25;


%% ============================================================
% Fault classification, per realization
% ============================================================

CONNSEED = false(numSeeds, nFault, nTopo, nN);
L2SEED   = zeros(numSeeds, nFault, nTopo, nN);
ISOSEED  = zeros(numSeeds, nFault, nTopo, nN);
DEGSEED  = zeros(numSeeds, nFault, nTopo, nN);
DEGMIN   = zeros(numSeeds, nFault, nTopo, nN);
DISCDUR  = zeros(numSeeds, nFault, nTopo, nN);

for iN = 1:nN
    for iT = 1:nTopo
        for iF = 1:nFault
            for s = 1:numSeeds

                cfgT = applyTopologyConfig(defaultConfig(), swarmSizes(iN), topologyNames{iT});
                cfgT.net.seed = 2800000 + 100000*iN + 1000*iT + s;

                b = generateBlackoutRealization(cfgT, faultNodes(iF), faultDur(iF));

                CONNSEED(s,iF,iT,iN) = b.connected;
                L2SEED(s,iF,iT,iN)   = b.lambda2;
                ISOSEED(s,iF,iT,iN)  = b.isolatedFollowers;
                DEGSEED(s,iF,iT,iN)  = b.activeInDegreeMean;
                DEGMIN(s,iF,iT,iN)   = b.activeInDegreeMin;
                DISCDUR(s,iF,iT,iN)  = b.disconnectedDuration;

            end
        end
    end
end

nConn = squeeze(sum(CONNSEED,1));

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP08C node communication blackout\n');
fprintf('============================================================\n\n');

fprintf('%4s %-10s %-10s %9s %9s %6s %6s %8s %10s %9s %8s\n', ...
    'N','Topology','Fault','minL2','maxL2','nConn','nDisc','maxIso', ...
    'inDegMean','inDegMin','discDur');

for iN = 1:nN
    for iT = 1:nTopo
        for iF = 1:nFault

            l2 = L2SEED(:,iF,iT,iN);

            fprintf('%4d %-10s %-10s %9.4f %9.4f %6d %6d %8d %10.2f %9d %8.1f\n', ...
                swarmSizes(iN), topologyNames{iT}, faultNames{iF}, ...
                min(l2), max(l2), nConn(iF,iT,iN), numSeeds - nConn(iF,iT,iN), ...
                max(ISOSEED(:,iF,iT,iN)), mean(DEGSEED(:,iF,iT,iN)), ...
                min(DEGMIN(:,iF,iT,iN)), mean(DISCDUR(:,iF,iT,iN)));

        end
    end
end

fprintf(['\n  lambda2 is computed on the subgraph induced by the nodes still\n' ...
         '  radiating. Seeds with lambda2 = 0 are labelled DISCONNECTED and\n' ...
         '  belong to the impossibility region, not to policy failure.\n']);


%% ============================================================
% Storage
% ============================================================

sz = [numSeeds nMethod nFault nTopo nN nScenario];

RMSE     = zeros(sz);
MINEVAL  = zeros(sz);
PEAKERR  = zeros(sz);
MINSEPBO = zeros(sz);
RECOVERY = nan(sz);
PEAKAOI  = zeros(sz);
TRUEAOI  = zeros(sz);
ESTAOI   = nan(sz);
SAFEFAIL = false(sz);

DATAPRE  = zeros(sz);
DATADUR  = zeros(sz);
DATAPOST = zeros(sz);
ACKPRE   = zeros(sz);
ACKDUR   = zeros(sz);
ACKPOST  = zeros(sz);

OUTMEAN  = nan(sz);
OUTMAX   = nan(sz);
PROBES   = nan(sz);
MAXGAP   = nan(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\nSeeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario
    for iN = 1:nN
        for iT = 1:nTopo

            fprintf('\n--- %s | N=%d | %s ---\n', ...
                scenarioNames{iS}, swarmSizes(iN), topologyNames{iT});

            for iF = 1:nFault

                fprintf('  %-10s', faultNames{iF});

                for iM = 1:nMethod

                    rmseS = zeros(numSeeds,1);
                    minvS = zeros(numSeeds,1);
                    peakS = zeros(numSeeds,1);
                    msboS = zeros(numSeeds,1);
                    recvS = nan(numSeeds,1);
                    paoiS = zeros(numSeeds,1);
                    taoiS = zeros(numSeeds,1);
                    eaoiS = nan(numSeeds,1);
                    dpreS = zeros(numSeeds,1);
                    ddurS = zeros(numSeeds,1);
                    dposS = zeros(numSeeds,1);
                    apreS = zeros(numSeeds,1);
                    adurS = zeros(numSeeds,1);
                    aposS = zeros(numSeeds,1);
                    omeaS = nan(numSeeds,1);
                    omaxS = nan(numSeeds,1);
                    probS = nan(numSeeds,1);
                    mgapS = nan(numSeeds,1);

                    parfor s = 1:numSeeds

                        cfg = applyTopologyConfig(defaultConfig(), ...
                            swarmSizes(iN), topologyNames{iT});

                        cfg.swarm.normalizeConsensusDegree = false;

                        cfg.net.packetLoss = scenarioLoss(iS);
                        cfg.net.delay      = scenarioDelay(iS);
                        cfg.net.jitterStd  = 0;

                        % The seed deliberately excludes the scenario: the
                        % blackout realization must be the same physical
                        % fault under Moderate and Stressed, so the two
                        % differ only in the channel.
                        cfg.net.seed = 2800000 + 100000*iN + 1000*iT + s;

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

                        cfg.blackout = generateBlackoutRealization(cfg, ...
                            faultNodes(iF), faultDur(iF));

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

                        e = max(M.formationError(:,2:end), [], 2);

                        if faultNodes(iF) == 0
                            tA = 8;
                            tB = out.t(end);
                        else
                            tA = cfg.blackout.tStart;
                            tB = cfg.blackout.tEnd;
                            recvS(s) = recoveryTime(out.t, e, tA, tB);
                        end

                        % Peak error and peak AoI start at max(tFault, 8 s),
                        % per section 2.3 as amended during EXP08B.
                        tPeak = max(tA, 8);

                        peakS(s) = max(e(out.t >= tPeak));
                        paoiS(s) = max(out.meanAoI(out.t >= tPeak));
                        taoiS(s) = mean(out.meanAoI(out.t >= 8));

                        if isfield(out,'estimatedAoI')
                            ea = out.estimatedAoI(out.t >= 8, :, :);
                            eaoiS(s) = mean(ea(isfinite(ea) & ea > 0));
                        end

                        msboS(s) = windowMinSeparation(out, tA, tB);

                        [dpreS(s), ddurS(s), dposS(s)] = ...
                            windowRates(out.t, out.txCountLog, tA, tB);

                        if isfield(out,'ackCountLog')
                            [apreS(s), adurS(s), aposS(s)] = ...
                                windowRates(out.t, out.ackCountLog, tA, tB);
                        end

                        if isfield(out,'meanOutstanding')
                            omeaS(s) = out.meanOutstanding;
                            omaxS(s) = out.maxOutstanding;
                        end

                        if isfield(out,'timeoutTriggerCount')
                            probS(s) = out.timeoutTriggerCount;
                        end

                        if isfield(out,'maxInterTxGap')
                            mgapS(s) = out.maxInterTxGap;
                        end

                    end

                    RMSE(:,iM,iF,iT,iN,iS)     = rmseS;
                    MINEVAL(:,iM,iF,iT,iN,iS)  = minvS;
                    PEAKERR(:,iM,iF,iT,iN,iS)  = peakS;
                    MINSEPBO(:,iM,iF,iT,iN,iS) = msboS;
                    RECOVERY(:,iM,iF,iT,iN,iS) = recvS;
                    PEAKAOI(:,iM,iF,iT,iN,iS)  = paoiS;
                    TRUEAOI(:,iM,iF,iT,iN,iS)  = taoiS;
                    ESTAOI(:,iM,iF,iT,iN,iS)   = eaoiS;
                    SAFEFAIL(:,iM,iF,iT,iN,iS) = minvS < safetyThreshold;

                    DATAPRE(:,iM,iF,iT,iN,iS)  = dpreS;
                    DATADUR(:,iM,iF,iT,iN,iS)  = ddurS;
                    DATAPOST(:,iM,iF,iT,iN,iS) = dposS;
                    ACKPRE(:,iM,iF,iT,iN,iS)   = apreS;
                    ACKDUR(:,iM,iF,iT,iN,iS)   = adurS;
                    ACKPOST(:,iM,iF,iT,iN,iS)  = aposS;

                    OUTMEAN(:,iM,iF,iT,iN,iS)  = omeaS;
                    OUTMAX(:,iM,iF,iT,iN,iS)   = omaxS;
                    PROBES(:,iM,iF,iT,iN,iS)   = probS;
                    MAXGAP(:,iM,iF,iT,iN,iS)   = mgapS;

                end

                fprintf('  done\n');

            end

        end
    end
end


%% ============================================================
% Results
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Results (means over connected seeds)\n');
fprintf('============================================================\n\n');

fprintf('%-9s %3s %-9s %-9s %-12s %8s %8s %8s %9s %9s %8s %8s %8s %7s\n', ...
    'Scen','N','Topo','Fault','Method','RMSE','minSep','peakErr','minSepBO', ...
    'recovery','preD/s','durD/s','postD/s','ratio');

for iS = 1:nScenario
    for iN = 1:nN
        for iT = 1:nTopo
            for iF = 1:nFault

                m = CONNSEED(:,iF,iT,iN);

                if ~any(m)
                    continue;
                end

                for iM = 1:nMethod

                    nomD = mean(DATAPRE(m,iM,IDX_NONE,iT,iN,iS));
                    durD = mean(DATADUR(m,iM,iF,iT,iN,iS));

                    fprintf(['%-9s %3d %-9s %-9s %-12s %8.4f %8.4f %8.4f ' ...
                             '%9.4f %9.3f %8.1f %8.1f %8.1f %7.2f\n'], ...
                        scenarioNames{iS}, swarmSizes(iN), topologyNames{iT}, ...
                        faultNames{iF}, methodNames{iM}, ...
                        mean(RMSE(m,iM,iF,iT,iN,iS)), mean(MINEVAL(m,iM,iF,iT,iN,iS)), ...
                        mean(PEAKERR(m,iM,iF,iT,iN,iS)), mean(MINSEPBO(m,iM,iF,iT,iN,iS)), ...
                        mean(RECOVERY(m,iM,iF,iT,iN,iS)), ...
                        mean(DATAPRE(m,iM,iF,iT,iN,iS)), durD, ...
                        mean(DATAPOST(m,iM,iF,iT,iN,iS)), ...
                        durD / max(nomD, eps));

                end

                fprintf('\n');

            end
        end
    end
end


%% ============================================================
% Gates, per section 4.3
% ============================================================

fprintf('============================================================\n');
fprintf('EXP08C acceptance gates\n');
fprintf('============================================================\n\n');

% The fault-induced SafeFail rate is only evaluable once the seed count
% can resolve 5 %. At 3 seeds the finest non-zero rate is 1/3, so the
% Stressed gate would collapse into "= 0" and the verdict would report
% the seed count rather than the method. Same rule as EXP08B section 4.2.
safeEvaluable = numSeeds >= 20;

modBreach = 0; modCount = 0;
strBreach = 0; strCount = 0;
recBreach = 0; recCount = 0;
secBreach = 0; secCount = 0;
cmpBreach = 0; cmpCount = 0;

excluded    = 0;   % conditions with no connected seed at all
partial     = 0;   % conditions that lost some seeds but not all
discSeeds   = 0;   % individual DISCONNECTED seed-conditions
noEligible  = 0;   % method-cells with no matched no-fault safe seed

ELIG   = zeros(nMethod, nFault, nTopo, nN, nScenario);
UNSAFE = zeros(nMethod, nFault, nTopo, nN, nScenario);
FRATE  = nan(nMethod, nFault, nTopo, nN, nScenario);

for iS = 1:nScenario
    for iN = 1:nN
        for iT = 1:nTopo
            for iF = 1:nFault

                m = CONNSEED(:,iF,iT,iN);

                if iF ~= IDX_NONE
                    discSeeds = discSeeds + nnz(~m);
                end

                if ~any(m)
                    if iF ~= IDX_NONE
                        excluded = excluded + 1;
                    end
                    continue;
                end

                if iF ~= IDX_NONE && ~all(m)
                    partial = partial + 1;
                end

                for iM = 1:nMethod

                    % Matched no-fault eligibility: the same method,
                    % scenario, topology, N and seed must already have
                    % been safe without the fault.
                    elig = m & ~SAFEFAIL(:,iM,IDX_NONE,iT,iN,iS);

                    bad = elig & SAFEFAIL(:,iM,iF,iT,iN,iS);

                    ELIG(iM,iF,iT,iN,iS)   = nnz(elig);
                    UNSAFE(iM,iF,iT,iN,iS) = nnz(bad);

                    if nnz(elig) > 0
                        FRATE(iM,iF,iT,iN,iS) = nnz(bad) / nnz(elig);
                    elseif iF ~= IDX_NONE
                        % No seed of this cell was safe before the fault,
                        % so the cell carries no evidence about blackouts.
                        % Counted, so a small denominator elsewhere is
                        % never mistaken for a small failure count.
                        noEligible = noEligible + 1;
                    end

                end

                if iF == IDX_NONE
                    continue;
                end

                r = FRATE(IDX_CAUSAL,iF,iT,iN,iS);

                if ismember(iF, IDX_1NODE) && ~isnan(r)

                    if iS == 1
                        modCount = modCount + 1;
                        if r > 0
                            modBreach = modBreach + 1;
                            fprintf(['    1-node Moderate breach: N=%d %-8s %-9s  ' ...
                                     '%d/%d = %.1f%%\n'], ...
                                swarmSizes(iN), topologyNames{iT}, faultNames{iF}, ...
                                UNSAFE(IDX_CAUSAL,iF,iT,iN,iS), ...
                                ELIG(IDX_CAUSAL,iF,iT,iN,iS), 100*r);
                        end
                    else
                        strCount = strCount + 1;
                        if r > 0.05
                            strBreach = strBreach + 1;
                            fprintf(['    1-node Stressed breach: N=%d %-8s %-9s  ' ...
                                     '%d/%d = %.1f%%\n'], ...
                                swarmSizes(iN), topologyNames{iT}, faultNames{iF}, ...
                                UNSAFE(IDX_CAUSAL,iF,iT,iN,iS), ...
                                ELIG(IDX_CAUSAL,iF,iT,iN,iS), 100*r);
                        end
                    end

                end

                if ismember(iF, IDX_2NODE) && ~isnan(r)
                    secCount = secCount + 1;
                    secBreach = secBreach + (r > 0.10);
                end

                rc = mean(RECOVERY(m,IDX_CAUSAL,iF,iT,iN,iS));
                r2 = mean(RECOVERY(m,IDX_P20,iF,iT,iN,iS));

                if ismember(iF, IDX_1NODE)
                    recCount = recCount + 1;
                    if isnan(rc) || rc > 5.0
                        recBreach = recBreach + 1;
                    end
                end

                cmpCount = cmpCount + 1;
                if isnan(rc) || isnan(r2) || rc > 1.25*r2
                    cmpBreach = cmpBreach + 1;
                end

            end
        end
    end
end

gateNames = {'1-node Moderate fault-SafeFail = 0', ...
             '1-node Stressed fault-SafeFail <= 5%', ...
             '1-node recovery <= 5 s'};

gatePass = [modBreach == 0, strBreach == 0, recBreach == 0];

gateVals = {sprintf('%d of %d breached', modBreach, modCount), ...
            sprintf('%d of %d breached', strBreach, strCount), ...
            sprintf('%d of %d breached', recBreach, recCount)};

gateStatus = cell(size(gateNames));

for q = 1:numel(gateNames)
    if q <= 2 && ~safeEvaluable
        gateStatus{q} = 'DEFER';
        gateVals{q} = sprintf('%s at %d seeds - NOT EVALUABLE', gateVals{q}, numSeeds);
    elseif gatePass(q)
        gateStatus{q} = 'PASS';
    else
        gateStatus{q} = 'FAIL';
    end
end

for q = 1:numel(gateNames)
    fprintf('  [%-5s] %-40s %s\n', gateStatus{q}, gateNames{q}, gateVals{q});
end

fprintf('\n  SECONDARY (characterization only, never moves the main claim):\n');
fprintf('    2-node fault-SafeFail <= 10%%: %d of %d breached\n', secBreach, secCount);

fprintf('\n  COMPARATIVE DIAGNOSTIC (not a gate):\n');
fprintf('    Trec(Causal) <= 1.25 x Trec(P20): %d of %d breached\n', cmpBreach, cmpCount);

fprintf('\n  DISCONNECTED / impossibility region:\n');
fprintf('    conditions excluded entirely      : %d\n', excluded);
fprintf('    conditions partially excluded     : %d\n', partial);
fprintf('    individual seed-conditions dropped: %d\n', discSeeds);
fprintf('    method-cells with no eligible seed: %d\n', noEligible);


% Per-method fault-induced SafeFail, to separate a policy failure from a
% condition that defeats every policy.
fprintf('\n  Fault-induced SafeFail > 0 per method (1-node conditions):\n');

for iM = 1:nMethod
    c = 0; tot = 0;
    for iS = 1:nScenario
        for iN = 1:nN
            for iT = 1:nTopo
                for iF = IDX_1NODE
                    r = FRATE(iM,iF,iT,iN,iS);
                    if ~isnan(r)
                        tot = tot + 1;
                        c = c + (r > 0);
                    end
                end
            end
        end
    end
    fprintf('    %-12s %d of %d cells\n', methodNames{iM}, c, tot);
end

fprintf(['    Denominators differ by method: a cell counts only when that\n' ...
         '    method had at least one matched no-fault safe seed. A method\n' ...
         '    already unsafe without any fault therefore contributes fewer\n' ...
         '    cells, not fewer failures.\n']);

nFailed = sum(strcmp(gateStatus,'FAIL'));
nDefer  = sum(strcmp(gateStatus,'DEFER'));

fprintf('\n');
if nDefer > 0
    fprintf('  EXP08C GATES: %d PASS, %d FAIL, %d DEFERRED to the 20-seed run\n', ...
        sum(strcmp(gateStatus,'PASS')), nFailed, nDefer);
elseif nFailed == 0
    fprintf('  EXP08C GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP08C GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Table
% ============================================================

% Connectivity is a property of the fault realization, not of the method
% or the channel, so it is replicated across those dimensions to travel
% with every row.
rep = @(X) repmat(reshape(X, [numSeeds 1 nFault nTopo nN 1]), ...
    [1 nMethod 1 1 1 nScenario]);

T = tidyFromArray( ...
    struct('RMSE',RMSE,'MINEVAL',MINEVAL,'PEAKERR',PEAKERR,'MINSEPBO',MINSEPBO, ...
           'RECOVERY',RECOVERY,'PEAKAOI',PEAKAOI,'TRUEAOI',TRUEAOI,'ESTAOI',ESTAOI, ...
           'SAFEFAIL',double(SAFEFAIL), ...
           'DATAPRE',DATAPRE,'DATADUR',DATADUR,'DATAPOST',DATAPOST, ...
           'ACKPRE',ACKPRE,'ACKDUR',ACKDUR,'ACKPOST',ACKPOST, ...
           'OUTMEAN',OUTMEAN,'OUTMAX',OUTMAX,'PROBES',PROBES,'MAXGAP',MAXGAP, ...
           'CONNECTED',rep(double(CONNSEED)),'ISOLATED',rep(ISOSEED), ...
           'LAMBDA2',rep(L2SEED),'DISCDUR',rep(DISCDUR)), ...
    {'seed','method','fault','topology','N','scenario'}, ...
    {1:numSeeds, methodNames, faultNames, topologyNames, ...
     arrayfun(@(v) sprintf('N%d',v), swarmSizes, 'UniformOutput', false), ...
     scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP08C completed.\n');


save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function T = recoveryTime(t, e, tFault, tClear)
%RECOVERYTIME Section 2.2. NaN when baseline is never regained.

if ~isfinite(tClear)
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

    if ~any(t > t(k) + 1.0)
        break;
    end

    window = t >= t(k) & t <= t(k) + 1.0;

    if all(e(window) <= limit)
        T = t(k) - tClear;
        return;
    end

end

T = NaN;

end


function d = windowMinSeparation(out, tA, tB)
%WINDOWMINSEPARATION Closest approach while the blackout is active.
%
% minSeparationEval spans the whole evaluation window, so it cannot say
% whether a close approach happened during the outage or after it.

idx = find(out.t >= tA & out.t <= tB);

if numel(idx) < 2
    d = NaN;
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

d = sqrt(d2min);

end


function [pre, dur, post] = windowRates(t, cumLog, tA, tB)
%WINDOWRATES Transmission rates before, during and after the outage.
%
% Taken from a passive cumulative counter. A run total cannot resolve
% this: a policy that surges during an outage and one that goes quiet can
% share the same run average.

pre  = segmentRate(t, cumLog, max(tA-3, t(1)), tA);
dur  = segmentRate(t, cumLog, tA, min(tB, t(end)));
post = segmentRate(t, cumLog, min(tB, t(end)), t(end));

end


function r = segmentRate(t, cumLog, tA, tB)

idx = find(t >= tA & t <= tB);

if numel(idx) < 2
    r = NaN;
    return;
end

span = t(idx(end)) - t(idx(1));

if span <= 0
    r = NaN;
else
    r = (cumLog(idx(end)) - cumLog(idx(1))) / span;
end

end
