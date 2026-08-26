%% EXP09C - Synthetic swarm-state estimator robustness study
%
% This is a SYNTHETIC study. The sigmas and latencies are parameter
% assumptions, not hardware measurements, and must never be presented as a
% measured sensor model.
%
% Noise appears ONCE, at the source estimate. Each follower forms
%
%   pHat_i(t) = pTrue_i(t - latency) + nP_i(t)
%   vHat_i(t) = vTrue_i(t - latency) + nV_i(t)
%
% and that single estimate feeds its formation self-state, its trigger, and
% the payload it transmits. The receiver adds no second draw: doing so
% would give a value that crossed the network twice the variance of one
% used locally, charging the noise to the act of transmitting.
%
% Safety and formation RMSE are measured on the TRUE state. Measuring them
% on the estimate would let a policy score as safe precisely because it
% could not see the collision. The estimator error is reported separately.
%
% Latency is applied at exactly t - latency by interpolation, never rounded
% to a multiple of dt: rounding would make the effective latency move with
% dt and confound the timestep diagnostic.
%
% The inner flight controller keeps using the true plant state. The scope
% here is swarm-estimator and trigger robustness, not low-level flight
% estimation. The leader stays noise-free because it is a kinematic
% reference. Both are scope choices to state in the paper.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp09c_synthetic_estimator');


%% ============================================================
% Scope
% ============================================================

numSeeds = 20;

swarmN = 5;

topologyName = 'ring2';

scenarioNames = {'Clean'; 'Moderate'; 'Stressed'};
scenarioLoss  = [0.00; 0.20; 0.40];
scenarioDelay = [0.00; 0.08; 0.12];

methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

% Structured sweep: C1 noise at zero latency, C2 latency at zero noise,
% C3 the combined medium. NOT a full Cartesian product.
armNames = { ...
    'N0 noiseless'; ...
    'N1 .01/.02'; ...
    'N2 .03/.05'; ...
    'N3 .05/.10'; ...
    'L50  0/0'; ...
    'L100 0/0'; ...
    'C3 combined'};

armPos = [0;    0.01; 0.03; 0.05; 0;     0;     0.03];
armVel = [0;    0.02; 0.05; 0.10; 0;     0;     0.05];
armLat = [0;    0;    0;    0;    0.050; 0.100; 0.050];

nScenario = numel(scenarioNames);
nMethod   = numel(methodNames);
nArm      = numel(armNames);

IDX_N0 = 1;
IDX_C3 = 7;

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

sz = [numSeeds nMethod nArm nScenario];

RMSE     = nan(sz);
MINSEP   = nan(sz);
SAFEFAIL = false(sz);
DIVERGED = false(sz);

ESTERR   = nan(sz);
POSRMS   = nan(sz);
VELRMS   = nan(sz);
LATCHK   = nan(sz);

DATARATE = nan(sz);
ACKRATE  = nan(sz);
TRUEAOI  = nan(sz);
ESTAOI   = nan(sz);

HARDR    = nan(sz);
ADAPTR   = nan(sz);
REFRESHR = nan(sz);

TRACEH   = nan(sz);
ACKH     = nan(sz);
NOISEH   = nan(sz);

INVSUM   = nan(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP09C synthetic swarm-state estimator robustness\n');
fprintf('============================================================\n\n');

fprintf('N = %d | %s | 6-DOF | noise at source only | true-state safety\n', ...
    swarmN, topologyName);
fprintf('Seeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n--- %s ---\n', scenarioNames{iS});

    for iA = 1:nArm

        fprintf('  %-14s', armNames{iA});

        for iM = 1:nMethod

            rmseS = nan(numSeeds,1);
            msepS = nan(numSeeds,1);
            safeS = false(numSeeds,1);
            divS  = false(numSeeds,1);
            eerrS = nan(numSeeds,1);
            prmsS = nan(numSeeds,1);
            vrmsS = nan(numSeeds,1);
            latS  = nan(numSeeds,1);
            dataS = nan(numSeeds,1);
            ackS  = nan(numSeeds,1);
            taoiS = nan(numSeeds,1);
            eaoiS = nan(numSeeds,1);
            hrS   = nan(numSeeds,1);
            arS   = nan(numSeeds,1);
            rrS   = nan(numSeeds,1);
            thS   = nan(numSeeds,1);
            ahS   = nan(numSeeds,1);
            nhS   = nan(numSeeds,1);
            invS  = nan(numSeeds,1);

            parfor s = 1:numSeeds

                cfg = applyTopologyConfig(defaultConfig(), swarmN, topologyName);

                cfg.swarm.normalizeConsensusDegree = false;

                cfg.net.packetLoss = scenarioLoss(iS);
                cfg.net.delay      = scenarioDelay(iS);
                cfg.net.jitterStd  = 0;

                % The seed excludes the arm on purpose: every arm meets the
                % same channel realization.
                cfg.net.seed = 5900000 + 10000*iS + s;

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

                cfg.sixdof.enable = true;
                cfg.sixdof.ratio  = INNER_RATIO;

                cfg.estimator.latency = armLat(iA);
                cfg.estimator.noise   = generateNoiseTrace(cfg, armPos(iA), armVel(iA));

                fwd = generateNetworkTrace(cfg);
                rev = generateAckTrace(cfg);

                thS(s) = fwd.hash;
                ahS(s) = rev.hash;
                nhS(s) = cfg.estimator.noise.hash;

                out = simSwarm6DOF(cfg, methodNames{iM});

                M = computeSwarmMetrics(out, cfg);
                Q = compute6DOFMetrics(out, cfg);

                mission = out.t(end) - out.t(1);

                divS(s) = Q.diverged || any(~isfinite(out.P(:)));

                latS(s) = armLat(iA);

                if divS(s)

                    safeS(s) = true;

                else

                    rmseS(s) = M.formationRMSE;
                    msepS(s) = M.minSeparationEval;
                    safeS(s) = M.minSeparationEval < safetyThreshold;

                    idxEval = out.t >= 8;

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
                        hrS(s) = out.hardInnovationRatio;
                        arS(s) = out.adaptiveNewInfoRatio;
                        rrS(s) = out.refreshRatio;
                    end

                end

                % Estimator diagnostics, taken from the estimator itself so
                % the realized noise is reported rather than the requested
                % sigma.
                if isfield(out,'est') && ~isempty(out.est) && out.est.nSum > 0
                    prmsS(s) = sqrt(out.est.nSumSq(1) / (3*out.est.nSum));
                    vrmsS(s) = sqrt(out.est.nSumSq(2) / (3*out.est.nSum));
                    eerrS(s) = sqrt(out.est.errSq / out.est.errN);
                end

                if isfield(out,'invariantViolations')
                    invS(s) = out.invariantViolations;
                else
                    invS(s) = 0;
                end

            end

            RMSE(:,iM,iA,iS)     = rmseS;
            MINSEP(:,iM,iA,iS)   = msepS;
            SAFEFAIL(:,iM,iA,iS) = safeS;
            DIVERGED(:,iM,iA,iS) = divS;
            ESTERR(:,iM,iA,iS)   = eerrS;
            POSRMS(:,iM,iA,iS)   = prmsS;
            VELRMS(:,iM,iA,iS)   = vrmsS;
            LATCHK(:,iM,iA,iS)   = latS;
            DATARATE(:,iM,iA,iS) = dataS;
            ACKRATE(:,iM,iA,iS)  = ackS;
            TRUEAOI(:,iM,iA,iS)  = taoiS;
            ESTAOI(:,iM,iA,iS)   = eaoiS;
            HARDR(:,iM,iA,iS)    = hrS;
            ADAPTR(:,iM,iA,iS)   = arS;
            REFRESHR(:,iM,iA,iS) = rrS;
            TRACEH(:,iM,iA,iS)   = thS;
            ACKH(:,iM,iA,iS)     = ahS;
            NOISEH(:,iM,iA,iS)   = nhS;
            INVSUM(:,iM,iA,iS)   = invS;

        end

        fprintf('  done\n');

    end

end


%% ============================================================
% Aggregation
% ============================================================

dims = [nMethod nArm nScenario];

mRMSE = nan(dims);  mMSEP = nan(dims);  mSAFE = nan(dims);
nDIV  = zeros(dims);
mEERR = nan(dims);  mPRMS = nan(dims);  mVRMS = nan(dims);
mDATA = nan(dims);  mACK  = nan(dims);
mTAOI = nan(dims);  mEAOI = nan(dims);
mHR   = nan(dims);  mAR   = nan(dims);  mRR = nan(dims);
sumINV = zeros(dims);

for iS = 1:nScenario
    for iA = 1:nArm
        for iM = 1:nMethod

            d = DIVERGED(:,iM,iA,iS);

            nDIV(iM,iA,iS) = nnz(d);

            mRMSE(iM,iA,iS) = meanFinite(RMSE(~d,iM,iA,iS));
            mMSEP(iM,iA,iS) = meanFinite(MINSEP(~d,iM,iA,iS));
            mSAFE(iM,iA,iS) = mean(SAFEFAIL(:,iM,iA,iS));

            mEERR(iM,iA,iS) = meanFinite(ESTERR(:,iM,iA,iS));
            mPRMS(iM,iA,iS) = meanFinite(POSRMS(:,iM,iA,iS));
            mVRMS(iM,iA,iS) = meanFinite(VELRMS(:,iM,iA,iS));

            mDATA(iM,iA,iS) = meanFinite(DATARATE(~d,iM,iA,iS));
            mACK(iM,iA,iS)  = meanFinite(ACKRATE(~d,iM,iA,iS));
            mTAOI(iM,iA,iS) = meanFinite(TRUEAOI(~d,iM,iA,iS));
            mEAOI(iM,iA,iS) = meanFinite(ESTAOI(~d,iM,iA,iS));

            mHR(iM,iA,iS) = meanFinite(HARDR(~d,iM,iA,iS));
            mAR(iM,iA,iS) = meanFinite(ADAPTR(~d,iM,iA,iS));
            mRR(iM,iA,iS) = meanFinite(REFRESHR(~d,iM,iA,iS));

            sumINV(iM,iA,iS) = sum(INVSUM(:,iM,iA,iS), 'omitnan');

        end
    end
end


%% ============================================================
% Sweep table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Structured sweep - Causal-v3\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-14s %9s %9s %9s %10s %10s %9s %8s %8s %8s\n', ...
    'Scenario','Arm','RMSE','minSep','estErr','posNoise','velNoise','DATA Hz', ...
    'x N0','hardR','refrR');

for iS = 1:nScenario

    d0 = mDATA(IDX_CAUSAL,IDX_N0,iS);

    for iA = 1:nArm

        fprintf('%-10s %-14s %9.4f %9.4f %9.4f %10.4f %10.4f %9.2f %8.2f %8.3f %8.3f\n', ...
            scenarioNames{iS}, armNames{iA}, ...
            mRMSE(IDX_CAUSAL,iA,iS), mMSEP(IDX_CAUSAL,iA,iS), ...
            mEERR(IDX_CAUSAL,iA,iS), mPRMS(IDX_CAUSAL,iA,iS), mVRMS(IDX_CAUSAL,iA,iS), ...
            mDATA(IDX_CAUSAL,iA,iS), mDATA(IDX_CAUSAL,iA,iS)/d0, ...
            mHR(IDX_CAUSAL,iA,iS), mRR(IDX_CAUSAL,iA,iS));

    end

    fprintf('\n');

end


%% ============================================================
% C3 detail, all methods
% ============================================================

fprintf('============================================================\n');
fprintf('C3 combined medium - all methods\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %9s %9s %9s %9s %9s %9s %9s %8s\n', ...
    'Scenario','Method','N0 RMSE','C3 RMSE','delta%','minSep','SafeFail', ...
    'N0 DATA','C3 DATA','ratio');

for iS = 1:nScenario
    for iM = 1:nMethod

        a = mRMSE(iM,IDX_N0,iS);
        b = mRMSE(iM,IDX_C3,iS);

        c = mDATA(iM,IDX_N0,iS);
        d = mDATA(iM,IDX_C3,iS);

        fprintf('%-10s %-12s %9.4f %9.4f %9.2f %9.4f %9.1f %9.2f %9.2f %8.2f\n', ...
            scenarioNames{iS}, methodNames{iM}, a, b, 100*(b-a)/a, ...
            mMSEP(iM,IDX_C3,iS), 100*mSAFE(iM,IDX_C3,iS), c, d, d/c);

    end
    fprintf('\n');
end


%% ============================================================
% Gates at C3
% ============================================================

fprintf('============================================================\n');
fprintf('EXP09C acceptance gates (C3 combined medium)\n');
fprintf('============================================================\n\n');

safeEvaluable = numSeeds >= 20;

g1Div = sum(nDIV(:,IDX_C3,:), 'all');

g2Bad = 0; g2Tot = 0;
for iS = 1:nScenario
    for iM = 1:nMethod
        g2Tot = g2Tot + 1;
        g2Bad = g2Bad + (mSAFE(iM,IDX_C3,iS) > 0.05);
    end
end

g3Bad = 0;
for iS = 1:nScenario
    r = mDATA(IDX_CAUSAL,IDX_C3,iS) / mDATA(IDX_CAUSAL,IDX_N0,iS);
    if ~(r < 2.0)
        g3Bad = g3Bad + 1;
        fprintf('    G3 breach: %-9s Causal %.2f Hz vs %.2f Hz noiseless (%.2fx)\n', ...
            scenarioNames{iS}, mDATA(IDX_CAUSAL,IDX_C3,iS), ...
            mDATA(IDX_CAUSAL,IDX_N0,iS), r);
    end
end

g4Inv = sum(sumINV(:,IDX_C3,:), 'all');

gateNames = { ...
    'G1 0 NaN / 0 DIVERGED', ...
    'G2 SafeFail <= 5%', ...
    'G3 Causal DATA < 2x noiseless', ...
    'G4 causal invariants = 0'};

gatePass = [g1Div == 0, g2Bad == 0, g3Bad == 0, g4Inv == 0];

gateVals = { ...
    sprintf('%d diverged of %d C3 runs', g1Div, numSeeds*nMethod*nScenario), ...
    sprintf('%d of %d cells breached', g2Bad, g2Tot), ...
    sprintf('%d of %d scenarios breached', g3Bad, nScenario), ...
    sprintf('%d violations', g4Inv)};

gateStatus = cell(size(gateNames));

for q = 1:numel(gateNames)
    if q == 2 && ~safeEvaluable
        gateStatus{q} = 'DEFER';
        gateVals{q} = sprintf('%s at %d seeds - NOT EVALUABLE', gateVals{q}, numSeeds);
    elseif gatePass(q)
        gateStatus{q} = 'PASS';
    else
        gateStatus{q} = 'FAIL';
    end
end

for q = 1:numel(gateNames)
    fprintf('  [%-5s] %-38s %s\n', gateStatus{q}, gateNames{q}, gateVals{q});
end


%% ============================================================
% False-trigger mechanism
% ============================================================

fprintf('\n  FALSE-TRIGGER MECHANISM (reported, not gated):\n');
fprintf('    %-10s %10s %10s %10s %10s\n', ...
    'Scenario','hardR','adaptR','refrR','DATA x N0');

for iS = 1:nScenario
    fprintf('    %-10s %10.4f %10.4f %10.4f %10.2f\n', ...
        scenarioNames{iS}, mHR(IDX_CAUSAL,IDX_C3,iS), mAR(IDX_CAUSAL,IDX_C3,iS), ...
        mRR(IDX_CAUSAL,IDX_C3,iS), ...
        mDATA(IDX_CAUSAL,IDX_C3,iS)/mDATA(IDX_CAUSAL,IDX_N0,iS));
end

nFailed = sum(strcmp(gateStatus,'FAIL'));
nDefer  = sum(strcmp(gateStatus,'DEFER'));

fprintf('\n');
if nDefer > 0
    fprintf('  EXP09C GATES: %d PASS, %d FAIL, %d DEFERRED to the 20-seed run\n', ...
        sum(strcmp(gateStatus,'PASS')), nFailed, nDefer);
elseif nFailed == 0
    fprintf('  EXP09C GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP09C GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Table
% ============================================================

T = tidyFromArray( ...
    struct('RMSE',RMSE,'MINSEP',MINSEP,'SAFEFAIL',double(SAFEFAIL), ...
           'DIVERGED',double(DIVERGED),'ESTERR',ESTERR, ...
           'POSNOISERMS',POSRMS,'VELNOISERMS',VELRMS,'LATENCY',LATCHK, ...
           'DATARATE',DATARATE,'ACKRATE',ACKRATE, ...
           'TRUEAOI',TRUEAOI,'ESTAOI',ESTAOI, ...
           'HARDRATIO',HARDR,'ADAPTRATIO',ADAPTR,'REFRESHRATIO',REFRESHR, ...
           'TRACEHASH',TRACEH,'ACKTRACEHASH',ACKH,'NOISEHASH',NOISEH, ...
           'INVARIANTS',INVSUM), ...
    {'seed','method','arm','scenario'}, ...
    {1:numSeeds, methodNames, armNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP09C completed.\n');


save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function m = meanFinite(v)
%MEANFINITE Mean over the finite entries, NaN when there are none.

v = v(isfinite(v));

if isempty(v)
    m = NaN;
else
    m = mean(v);
end

end
