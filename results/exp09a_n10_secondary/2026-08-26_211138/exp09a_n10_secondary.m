%% EXP09A N=10 - SECONDARY CHARACTERIZATION
%
% Identical to exp09a_multiuav_6dof at N = 10. This is characterization
% only: it does NOT feed the EXP09A gates, which are decided at N = 5 as
% pre-registered. Reported so the 6-DOF result is not left resting on a
% single swarm size.
%
%% EXP09A - Networked multi-UAV 6-DOF
%
% Causal-AoI-v3, swarm controller, communication thresholds and ACK/CRN are
% frozen. Nothing is tuned after debug.
%
% Every cell is run TWICE at the same seed: once as the locked
% double-integrator comparator, once with 6-DOF quadrotor followers. The
% outer loop, network, AoI bookkeeping and trigger logic are the same code
% in both modes - the only difference is how followers are integrated - so
% any delta is attributable to the dynamics rather than to a second
% implementation of the communication stack.
%
% The setpoint interface holds the commanded acceleration and derives the
% position and velocity references as its analytic integrals. That is NOT
% bit-identical to the comparator's semi-implicit Euler update: the two
% differ by 0.5*dt^2*a per step by construction. See swarm/setpointFromAccel.m.
%
% Event and Causal txCount are NOT expected to match the comparator. A
% different physical trajectory legitimately produces different trigger
% decisions. That difference is measured and reported, not treated as an
% error.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp09a_n10_secondary');


%% ============================================================
% Scope
% ============================================================

numSeeds = 20;

swarmN = 10;

topologyName = 'ring2';

scenarioNames = {'Clean'; 'Moderate'; 'Stressed'};
scenarioLoss  = [0.00; 0.20; 0.40];
scenarioDelay = [0.00; 0.08; 0.12];

methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

modeNames = {'DI'; '6DOF'};

nScenario = numel(scenarioNames);
nMethod   = numel(methodNames);
nMode     = numel(modeNames);

IDX_DI   = 1;
IDX_6DOF = 2;

IDX_P10   = 1;
IDX_P20   = 2;
IDX_EVENT = 3;
IDX_CAUSAL = 4;


%% ============================================================
% Locked parameters
% ============================================================

epsP = 0.05;  epsV = 0.10;
aoiThreshold = 0.12;  aoiCooldown = 0.10;  maxSilence = 0.50;

safetyThreshold = 0.25;

INNER_RATIO = 10;


%% ============================================================
% Storage
% ============================================================

sz = [numSeeds nMethod nMode nScenario];

RMSE     = nan(sz);
MAXERR   = nan(sz);
MINSEP   = nan(sz);
SAFEFAIL = false(sz);
DIVERGED = false(sz);

ROLLPK   = nan(sz);
PITCHPK  = nan(sz);
THRSAT   = nan(sz);
TRQSAT   = nan(sz);
SATURATE = nan(sz);
PERDRONE = nan(sz);
EFFORT   = nan(sz);

DATARATE = nan(sz);
ACKRATE  = nan(sz);
TRUEAOI  = nan(sz);
ESTAOI   = nan(sz);

HARDRATIO = nan(sz);
ADAPTRATIO = nan(sz);
REFRESHRATIO = nan(sz);

TRACEHASH = nan(sz);
ACKHASH   = nan(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP09A networked multi-UAV 6-DOF\n');
fprintf('============================================================\n\n');

fprintf('N = %d | topology = %s | outer 50 Hz | inner %d Hz | ratio %d:1\n', ...
    swarmN, topologyName, round(INNER_RATIO/0.02), INNER_RATIO);

fprintf('Seeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n--- %s ---\n', scenarioNames{iS});

    for iX = 1:nMode
        for iM = 1:nMethod

            fprintf('  %-6s %-12s', modeNames{iX}, methodNames{iM});

            rmseS = nan(numSeeds,1);
            maxeS = nan(numSeeds,1);
            msepS = nan(numSeeds,1);
            safeS = false(numSeeds,1);
            divS  = false(numSeeds,1);

            rollS = nan(numSeeds,1);
            pitcS = nan(numSeeds,1);
            thrS  = nan(numSeeds,1);
            trqS  = nan(numSeeds,1);
            satS  = nan(numSeeds,1);
            pdS   = nan(numSeeds,1);
            effS  = nan(numSeeds,1);

            dataS = nan(numSeeds,1);
            ackS  = nan(numSeeds,1);
            taoiS = nan(numSeeds,1);
            eaoiS = nan(numSeeds,1);

            hardS = nan(numSeeds,1);
            adapS = nan(numSeeds,1);
            refrS = nan(numSeeds,1);

            thS   = nan(numSeeds,1);
            ahS   = nan(numSeeds,1);

            parfor s = 1:numSeeds

                cfg = applyTopologyConfig(defaultConfig(), swarmN, topologyName);

                cfg.swarm.normalizeConsensusDegree = false;

                cfg.net.packetLoss = scenarioLoss(iS);
                cfg.net.delay      = scenarioDelay(iS);
                cfg.net.jitterStd  = 0;

                % The seed excludes the mode on purpose: the comparator and
                % the 6-DOF run must face the identical channel realization.
                cfg.net.seed = 3910000 + 10000*iS + s;

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

                cfg.sixdof.enable = (iX == 2);
                cfg.sixdof.ratio  = INNER_RATIO;

                fwd = generateNetworkTrace(cfg);
                rev = generateAckTrace(cfg);

                thS(s) = fwd.hash;
                ahS(s) = rev.hash;

                out = simSwarm6DOF(cfg, methodNames{iM});

                M = computeSwarmMetrics(out, cfg);
                Q = compute6DOFMetrics(out, cfg);

                mission = out.t(end) - out.t(1);

                divS(s) = Q.diverged || any(~isfinite(out.P(:)));

                % A diverged run is a stability failure AND unsafe. Its
                % continuous metrics are left NaN so they cannot enter a
                % mean; the denominator is reported separately.
                if divS(s)

                    safeS(s) = true;

                else

                    rmseS(s) = M.formationRMSE;
                    msepS(s) = M.minSeparationEval;
                    safeS(s) = M.minSeparationEval < safetyThreshold;

                    idxEval = out.t >= 8;

                    e = max(M.formationError(idxEval, 2:end), [], 2);
                    maxeS(s) = max(e);

                    effS(s)  = Q.controlEffort;

                    dataS(s) = out.txCount / mission;
                    taoiS(s) = mean(out.meanAoI(idxEval));

                    if isfield(out,'ackTxCount')
                        ackS(s) = out.ackTxCount / mission;
                    end

                    if isfield(out,'estimatedAoI')
                        ea = out.estimatedAoI(idxEval, :, :);
                        eaoiS(s) = mean(ea(isfinite(ea) & ea > 0));
                    end

                    if isfield(out,'hardInnovationRatio')
                        hardS(s) = out.hardInnovationRatio;
                        adapS(s) = out.adaptiveNewInfoRatio;
                        refrS(s) = out.refreshRatio;
                    end

                end

                % Attitude and saturation are reported even for a diverged
                % run: they are the evidence of HOW it failed.
                rollS(s) = Q.rollPeak;
                pitcS(s) = Q.pitchPeak;
                thrS(s)  = Q.thrustSat;
                trqS(s)  = Q.torqueSat;
                satS(s)  = Q.saturation;

                if ~isempty(Q.perDronePeakSat)
                    pdS(s) = max(Q.perDronePeakSat);
                end

            end

            RMSE(:,iM,iX,iS)     = rmseS;
            MAXERR(:,iM,iX,iS)   = maxeS;
            MINSEP(:,iM,iX,iS)   = msepS;
            SAFEFAIL(:,iM,iX,iS) = safeS;
            DIVERGED(:,iM,iX,iS) = divS;

            ROLLPK(:,iM,iX,iS)   = rollS;
            PITCHPK(:,iM,iX,iS)  = pitcS;
            THRSAT(:,iM,iX,iS)   = thrS;
            TRQSAT(:,iM,iX,iS)   = trqS;
            SATURATE(:,iM,iX,iS) = satS;
            PERDRONE(:,iM,iX,iS) = pdS;
            EFFORT(:,iM,iX,iS)   = effS;

            DATARATE(:,iM,iX,iS) = dataS;
            ACKRATE(:,iM,iX,iS)  = ackS;
            TRUEAOI(:,iM,iX,iS)  = taoiS;
            ESTAOI(:,iM,iX,iS)   = eaoiS;

            HARDRATIO(:,iM,iX,iS)    = hardS;
            ADAPTRATIO(:,iM,iX,iS)   = adapS;
            REFRESHRATIO(:,iM,iX,iS) = refrS;

            TRACEHASH(:,iM,iX,iS) = thS;
            ACKHASH(:,iM,iX,iS)   = ahS;

            fprintf('  done\n');

        end
    end

end


%% ============================================================
% CRN cross-check
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('CRN trace identity between DI and 6-DOF\n');
fprintf('============================================================\n\n');

fwdMatch = isequaln(TRACEHASH(:,:,IDX_DI,:), TRACEHASH(:,:,IDX_6DOF,:));
revMatch = isequaln(ACKHASH(:,:,IDX_DI,:),   ACKHASH(:,:,IDX_6DOF,:));

fprintf('  forward trace hash DI == 6DOF : %d\n', fwdMatch);
fprintf('  reverse trace hash DI == 6DOF : %d\n', revMatch);

if ~fwdMatch || ~revMatch
    error(['EXP09A: CRN mismatch between DI and 6-DOF. The comparator and ' ...
           'the 6-DOF run would face different channels and no delta ' ...
           'would be interpretable.']);
end


%% ============================================================
% Aggregation
%
% nanmean over the seeds that did not diverge. DIVERGED is counted
% separately so the denominator behind every mean stays visible.
% ============================================================

dims = [nMethod nMode nScenario];

mRMSE = nan(dims);  sRMSE = nan(dims);
mMAXE = nan(dims);  mMSEP = nan(dims);
mSAFE = nan(dims);  nDIV  = zeros(dims);  nOK = zeros(dims);
mROLL = nan(dims);  mPITC = nan(dims);
mTHR  = nan(dims);  mTRQ  = nan(dims);  mSAT = nan(dims);  mPD = nan(dims);
mEFF  = nan(dims);
mDATA = nan(dims);  mACK  = nan(dims);
mTAOI = nan(dims);  mEAOI = nan(dims);
mHARD = nan(dims);  mADAP = nan(dims);  mREFR = nan(dims);

for iS = 1:nScenario
    for iX = 1:nMode
        for iM = 1:nMethod

            d = DIVERGED(:,iM,iX,iS);

            nDIV(iM,iX,iS) = nnz(d);
            nOK(iM,iX,iS)  = nnz(~d);

            v = RMSE(~d,iM,iX,iS);

            if ~isempty(v)
                mRMSE(iM,iX,iS) = mean(v);
                sRMSE(iM,iX,iS) = std(v);
            end

            mMAXE(iM,iX,iS) = meanFinite(MAXERR(~d,iM,iX,iS));
            mMSEP(iM,iX,iS) = meanFinite(MINSEP(~d,iM,iX,iS));

            % SafeFail uses ALL seeds: a diverged run is unsafe.
            mSAFE(iM,iX,iS) = mean(SAFEFAIL(:,iM,iX,iS));

            mROLL(iM,iX,iS) = meanFinite(ROLLPK(:,iM,iX,iS));
            mPITC(iM,iX,iS) = meanFinite(PITCHPK(:,iM,iX,iS));
            mTHR(iM,iX,iS)  = meanFinite(THRSAT(:,iM,iX,iS));
            mTRQ(iM,iX,iS)  = meanFinite(TRQSAT(:,iM,iX,iS));
            mSAT(iM,iX,iS)  = meanFinite(SATURATE(:,iM,iX,iS));
            mPD(iM,iX,iS)   = meanFinite(PERDRONE(:,iM,iX,iS));

            mEFF(iM,iX,iS)  = meanFinite(EFFORT(~d,iM,iX,iS));
            mDATA(iM,iX,iS) = meanFinite(DATARATE(~d,iM,iX,iS));
            mACK(iM,iX,iS)  = meanFinite(ACKRATE(~d,iM,iX,iS));
            mTAOI(iM,iX,iS) = meanFinite(TRUEAOI(~d,iM,iX,iS));
            mEAOI(iM,iX,iS) = meanFinite(ESTAOI(~d,iM,iX,iS));
            mHARD(iM,iX,iS) = meanFinite(HARDRATIO(~d,iM,iX,iS));
            mADAP(iM,iX,iS) = meanFinite(ADAPTRATIO(~d,iM,iX,iS));
            mREFR(iM,iX,iS) = meanFinite(REFRESHRATIO(~d,iM,iX,iS));

        end
    end
end


%% ============================================================
% Required DI vs 6-DOF table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('DI vs 6-DOF\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %9s %11s %8s %11s %13s %8s %9s\n', ...
    'Scenario','Method','DI RMSE','6DOF RMSE','delta%','DI DATA Hz','6DOF DATA Hz', ...
    'delta%','dAoI%');

for iS = 1:nScenario
    for iM = 1:nMethod

        a = mRMSE(iM,IDX_DI,iS);
        b = mRMSE(iM,IDX_6DOF,iS);

        c = mDATA(iM,IDX_DI,iS);
        d = mDATA(iM,IDX_6DOF,iS);

        e = mTAOI(iM,IDX_DI,iS);
        f = mTAOI(iM,IDX_6DOF,iS);

        fprintf('%-10s %-12s %9.4f %11.4f %8.2f %11.2f %13.2f %8.2f %9.2f\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            a, b, 100*(b-a)/a, c, d, 100*(d-c)/c, 100*(f-e)/max(e,eps));

    end
    fprintf('\n');
end


%% ============================================================
% 6-DOF diagnostics
% ============================================================

fprintf('============================================================\n');
fprintf('6-DOF diagnostics\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %8s %8s %8s %8s %9s %9s %9s %10s %8s %8s\n', ...
    'Scenario','Method','RMSE','std','maxErr','minSep','rollPk','pitchPk', ...
    'thrSat%','torqSat%','pdSat%','effort');

for iS = 1:nScenario
    for iM = 1:nMethod

        fprintf('%-10s %-12s %8.4f %8.4f %8.4f %8.4f %9.2f %9.2f %9.3f %10.3f %8.3f %8.3f\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            mRMSE(iM,IDX_6DOF,iS), sRMSE(iM,IDX_6DOF,iS), ...
            mMAXE(iM,IDX_6DOF,iS), mMSEP(iM,IDX_6DOF,iS), ...
            mROLL(iM,IDX_6DOF,iS), mPITC(iM,IDX_6DOF,iS), ...
            100*mTHR(iM,IDX_6DOF,iS), 100*mTRQ(iM,IDX_6DOF,iS), ...
            100*mPD(iM,IDX_6DOF,iS), mEFF(iM,IDX_6DOF,iS));

    end
    fprintf('\n');
end

fprintf('%-10s %-12s %10s %10s %10s %10s %10s %10s %8s %8s\n', ...
    'Scenario','Method','DATA Hz','ACK Hz','trueAoI','estAoI','hardRat', ...
    'adaptRat','refrRat','nDiv');

for iS = 1:nScenario
    for iM = 1:nMethod

        fprintf('%-10s %-12s %10.2f %10.2f %10.4f %10.4f %10.3f %10.3f %8.3f %8d\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            mDATA(iM,IDX_6DOF,iS), mACK(iM,IDX_6DOF,iS), ...
            mTAOI(iM,IDX_6DOF,iS), mEAOI(iM,IDX_6DOF,iS), ...
            mHARD(iM,IDX_6DOF,iS), mADAP(iM,IDX_6DOF,iS), mREFR(iM,IDX_6DOF,iS), ...
            nDIV(iM,IDX_6DOF,iS));

    end
    fprintf('\n');
end


%% ============================================================
% Gates G1 - G7
% ============================================================

fprintf('============================================================\n');
fprintf('EXP09A acceptance gates\n');
fprintf('============================================================\n\n');

% G4 resolves 5 % only once the seed count can. Same rule as EXP08B 4.2.
safeEvaluable = numSeeds >= 20;

% --- G1 stability, over the 6-DOF runs ---
g1Div = sum(nDIV(:,IDX_6DOF,:), 'all');

% --- G2/G3/G4 safety, Causal-v3 under 6-DOF ---
g2 = mSAFE(IDX_CAUSAL,IDX_6DOF,1);
g3 = mSAFE(IDX_CAUSAL,IDX_6DOF,2);
g4 = mSAFE(IDX_CAUSAL,IDX_6DOF,3);

% --- G5 saturation, Causal-v3 under 6-DOF ---
g5Clean    = mSAT(IDX_CAUSAL,IDX_6DOF,1);
g5Stressed = mSAT(IDX_CAUSAL,IDX_6DOF,3);

% --- G6 proposed vs event, under 6-DOF ---
g6Bad = 0;
for iS = 1:nScenario
    if ~(mRMSE(IDX_CAUSAL,IDX_6DOF,iS) < mRMSE(IDX_EVENT,IDX_6DOF,iS))
        g6Bad = g6Bad + 1;
    end
end

% --- G7 sign consistency DI -> 6DOF ---
keepP10 = 0; keepP20 = 0;
for iS = 1:nScenario

    rDI = sign(mRMSE(IDX_CAUSAL,IDX_DI,iS)   - mRMSE(IDX_P10,IDX_DI,iS));
    r6D = sign(mRMSE(IDX_CAUSAL,IDX_6DOF,iS) - mRMSE(IDX_P10,IDX_6DOF,iS));

    sDI = sign(mRMSE(IDX_CAUSAL,IDX_DI,iS)   - mRMSE(IDX_P20,IDX_DI,iS));
    s6D = sign(mRMSE(IDX_CAUSAL,IDX_6DOF,iS) - mRMSE(IDX_P20,IDX_6DOF,iS));

    keepP10 = keepP10 + (rDI == r6D);
    keepP20 = keepP20 + (sDI == s6D);

    fprintf('    %-9s sign(Causal-P10) DI %+d -> 6DOF %+d | sign(Causal-P20) DI %+d -> 6DOF %+d\n', ...
        scenarioNames{iS}, rDI, r6D, sDI, s6D);

end

fprintf('\n');

gateNames = { ...
    'G1 Stability: 0 NaN, 0 DIVERGED', ...
    'G2 Clean SafeFail = 0', ...
    'G3 Moderate SafeFail = 0', ...
    'G4 Stressed SafeFail <= 5%', ...
    'G5 Saturation Clean<1% Stressed<5%', ...
    'G6 RMSE(Causal) < RMSE(State-event)', ...
    'G7 sign preserved >= 2/3 vs P10 AND P20'};

gatePass = [ ...
    g1Div == 0, ...
    g2 == 0, ...
    g3 == 0, ...
    g4 <= 0.05, ...
    g5Clean < 0.01 && g5Stressed < 0.05, ...
    g6Bad == 0, ...
    keepP10 >= 2 && keepP20 >= 2];

gateVals = { ...
    sprintf('%d diverged of %d 6-DOF runs', g1Div, numSeeds*nMethod*nScenario), ...
    sprintf('%.1f%%', 100*g2), ...
    sprintf('%.1f%%', 100*g3), ...
    sprintf('%.1f%%', 100*g4), ...
    sprintf('Clean %.3f%%, Stressed %.3f%%', 100*g5Clean, 100*g5Stressed), ...
    sprintf('%d of %d scenarios fail', g6Bad, nScenario), ...
    sprintf('P10 %d/3, P20 %d/3', keepP10, keepP20)};

gateStatus = cell(size(gateNames));

for q = 1:numel(gateNames)
    if q == 4 && ~safeEvaluable
        gateStatus{q} = 'DEFER';
        gateVals{q} = sprintf('%s at %d seeds - NOT EVALUABLE', gateVals{q}, numSeeds);
    elseif gatePass(q)
        gateStatus{q} = 'PASS';
    else
        gateStatus{q} = 'FAIL';
    end
end

for q = 1:numel(gateNames)
    fprintf('  [%-5s] %-42s %s\n', gateStatus{q}, gateNames{q}, gateVals{q});
end

nFailed = sum(strcmp(gateStatus,'FAIL'));
nDefer  = sum(strcmp(gateStatus,'DEFER'));

fprintf('\n');
if nDefer > 0
    fprintf('  EXP09A N=10 SECONDARY (not a gate): %d PASS, %d FAIL, %d DEFERRED to the 20-seed run\n', ...
        sum(strcmp(gateStatus,'PASS')), nFailed, nDefer);
elseif nFailed == 0
    fprintf('  EXP09A N=10 secondary: all %d/%d gate-equivalents met\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP09A N=10 secondary: %d of %d gate-equivalents not met\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Table
% ============================================================

T = tidyFromArray( ...
    struct('RMSE',RMSE,'MAXERR',MAXERR,'MINSEP',MINSEP, ...
           'SAFEFAIL',double(SAFEFAIL),'DIVERGED',double(DIVERGED), ...
           'ROLLPEAK',ROLLPK,'PITCHPEAK',PITCHPK, ...
           'THRUSTSAT',THRSAT,'TORQUESAT',TRQSAT,'SATURATION',SATURATE, ...
           'PERDRONEPEAKSAT',PERDRONE,'CONTROLEFFORT',EFFORT, ...
           'DATARATE',DATARATE,'ACKRATE',ACKRATE, ...
           'TRUEAOI',TRUEAOI,'ESTAOI',ESTAOI, ...
           'HARDRATIO',HARDRATIO,'ADAPTRATIO',ADAPTRATIO,'REFRESHRATIO',REFRESHRATIO, ...
           'TRACEHASH',TRACEHASH,'ACKTRACEHASH',ACKHASH), ...
    {'seed','method','mode','scenario'}, ...
    {1:numSeeds, methodNames, modeNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP09A completed.\n');


save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function m = meanFinite(v)
%MEANFINITE Mean over the finite entries, NaN when there are none.
%
% Used so a metric that is undefined for a method - ACK rate for the
% periodic baselines, innovation ratios outside Causal-v3 - reports NaN
% rather than silently contributing a zero to a comparison.

v = v(isfinite(v));

if isempty(v)
    m = NaN;
else
    m = mean(v);
end

end
