%% EXP09B - Disturbance + plant mismatch
%
% Inherits the locked EXP09A architecture: N = 5, ring2, outer 50 Hz /
% inner 500 Hz, analytic command-consistent reference, ZOH control across
% all four RK4 stages, leader kinematic. Causal-v3, swarm controller, quad
% controller, communication thresholds and CRN/network are frozen.
%
% The controller ALWAYS reads the nominal cfg.quad. Perturbation enters
% only the true plant (cfg.quadTrue), which only the dynamics see.
% Retuning the controller per perturbation level would measure the quality
% of the retuning instead of the robustness of the communication policy.
%
% The external forcing is a WORLD-FRAME EXTERNAL-FORCE / WIND PROXY, not an
% aerodynamic wind model. Fext = m_nominal * aExtWorld, so the 0.5 and 1.0
% levels are nominal-mass equivalent external accelerations in m/s^2, not
% wind speeds. At the mass +10 % arm the acceleration actually felt is
% Fext / m_true, about 9 % below the nominal level; that is reported rather
% than compensated, because compensating would make the mass arm change two
% things at once.
%
% Saturation keeps the EXP09A semantics - command-saturation fraction over
% follower-inner samples - so the two experiments stay comparable.
%
% B7 is the only gated arm. B1-B6, B8 and B9 are attribution.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp09b_physical_mismatch');


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

armNames = { ...
    'B0 nominal'; ...
    'B1 wind 0.5'; ...
    'B2 wind 1.0'; ...
    'B3 mass +10%'; ...
    'B4 mass -10%'; ...
    'B5 drag +20%'; ...
    'B6 drag -20%'; ...
    'B7 combined'; ...
    'B8 lag 20ms'; ...
    'B9 lag 50ms'};

armWind = [0;   0.5; 1.0; 0;    0;    0;   0;   0.5;  0;     0];
armMass = [1;   1;   1;   1.10; 0.90; 1;   1;   1.10; 1;     1];
armDrag = [1;   1;   1;   1;    1;    1.2; 0.8; 1.20; 1;     1];
armLag  = [0;   0;   0;   0;    0;    0;   0;   0;    0.020; 0.050];

nScenario = numel(scenarioNames);
nMethod   = numel(methodNames);
nArm      = numel(armNames);

IDX_B0 = 1;
IDX_B7 = 8;

IDX_P10    = 1;
IDX_P20    = 2;
IDX_EVENT  = 3;
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

ROLLPK   = nan(sz);
PITCHPK  = nan(sz);
SATURATE = nan(sz);
EFFORT   = nan(sz);
LAGERR   = nan(sz);

DATARATE = nan(sz);
ACKRATE  = nan(sz);
TRUEAOI  = nan(sz);
ESTAOI   = nan(sz);

MASSRAT  = nan(sz);
DRAGRAT  = nan(sz);
AEXTRMS  = nan(sz);
AEXTPEAK = nan(sz);

INVSUM   = nan(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP09B disturbance and plant mismatch\n');
fprintf('============================================================\n\n');

fprintf('N = %d | %s | 6-DOF | controller reads NOMINAL plant only\n', swarmN, topologyName);
fprintf('Seeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n--- %s ---\n', scenarioNames{iS});

    for iA = 1:nArm

        fprintf('  %-13s', armNames{iA});

        for iM = 1:nMethod

            rmseS = nan(numSeeds,1);
            msepS = nan(numSeeds,1);
            safeS = false(numSeeds,1);
            divS  = false(numSeeds,1);
            rollS = nan(numSeeds,1);
            pitcS = nan(numSeeds,1);
            satS  = nan(numSeeds,1);
            effS  = nan(numSeeds,1);
            lagS  = nan(numSeeds,1);
            dataS = nan(numSeeds,1);
            ackS  = nan(numSeeds,1);
            taoiS = nan(numSeeds,1);
            eaoiS = nan(numSeeds,1);
            mrS   = nan(numSeeds,1);
            drS   = nan(numSeeds,1);
            arS   = nan(numSeeds,1);
            apS   = nan(numSeeds,1);
            invS  = nan(numSeeds,1);

            parfor s = 1:numSeeds

                cfg = applyTopologyConfig(defaultConfig(), swarmN, topologyName);

                cfg.swarm.normalizeConsensusDegree = false;

                cfg.net.packetLoss = scenarioLoss(iS);
                cfg.net.delay      = scenarioDelay(iS);
                cfg.net.jitterStd  = 0;

                % The seed excludes the arm on purpose: every arm meets the
                % same channel realization, so a delta is attributable to
                % the perturbation and not to the network draw.
                cfg.net.seed = 4900000 + 10000*iS + s;

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

                arm = struct('wind', armWind(iA), ...
                             'massFactor', armMass(iA), ...
                             'dragFactor', armDrag(iA), ...
                             'lagTau', armLag(iA));

                cfg = applyPlantPerturbation(cfg, arm);

                arS(s) = cfg.extForce.rms;
                apS(s) = cfg.extForce.peak;

                out = simSwarm6DOF(cfg, methodNames{iM});

                M = computeSwarmMetrics(out, cfg);
                Q = compute6DOFMetrics(out, cfg);

                mission = out.t(end) - out.t(1);

                divS(s) = Q.diverged || any(~isfinite(out.P(:)));

                if divS(s)

                    % A diverged run is a stability failure AND unsafe. Its
                    % continuous metrics stay NaN so they cannot enter a
                    % mean; the denominator is reported separately.
                    safeS(s) = true;

                else

                    rmseS(s) = M.formationRMSE;
                    msepS(s) = M.minSeparationEval;
                    safeS(s) = M.minSeparationEval < safetyThreshold;

                    idxEval = out.t >= 8;

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

                end

                rollS(s) = Q.rollPeak;
                pitcS(s) = Q.pitchPeak;
                satS(s)  = Q.saturation;
                lagS(s)  = Q.lagErrMean;
                mrS(s)   = Q.massRatio;
                drS(s)   = Q.dragRatio;

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
            ROLLPK(:,iM,iA,iS)   = rollS;
            PITCHPK(:,iM,iA,iS)  = pitcS;
            SATURATE(:,iM,iA,iS) = satS;
            EFFORT(:,iM,iA,iS)   = effS;
            LAGERR(:,iM,iA,iS)   = lagS;
            DATARATE(:,iM,iA,iS) = dataS;
            ACKRATE(:,iM,iA,iS)  = ackS;
            TRUEAOI(:,iM,iA,iS)  = taoiS;
            ESTAOI(:,iM,iA,iS)   = eaoiS;
            MASSRAT(:,iM,iA,iS)  = mrS;
            DRAGRAT(:,iM,iA,iS)  = drS;
            AEXTRMS(:,iM,iA,iS)  = arS;
            AEXTPEAK(:,iM,iA,iS) = apS;
            INVSUM(:,iM,iA,iS)   = invS;

        end

        fprintf('  done\n');

    end

end


%% ============================================================
% Aggregation
% ============================================================

dims = [nMethod nArm nScenario];

mRMSE = nan(dims);  sRMSE = nan(dims);
mMSEP = nan(dims);  mSAFE = nan(dims);
nDIV  = zeros(dims);
mROLL = nan(dims);  mPITC = nan(dims);
mSAT  = nan(dims);  mEFF  = nan(dims);  mLAG = nan(dims);
mDATA = nan(dims);  mACK  = nan(dims);
mTAOI = nan(dims);  mEAOI = nan(dims);
mMR   = nan(dims);  mDR   = nan(dims);
mAR   = nan(dims);  mAP   = nan(dims);
sumINV = zeros(dims);

for iS = 1:nScenario
    for iA = 1:nArm
        for iM = 1:nMethod

            d = DIVERGED(:,iM,iA,iS);

            nDIV(iM,iA,iS) = nnz(d);

            v = RMSE(~d,iM,iA,iS);

            if ~isempty(v)
                mRMSE(iM,iA,iS) = mean(v);
                sRMSE(iM,iA,iS) = std(v);
            end

            mMSEP(iM,iA,iS) = meanFinite(MINSEP(~d,iM,iA,iS));
            mSAFE(iM,iA,iS) = mean(SAFEFAIL(:,iM,iA,iS));

            mROLL(iM,iA,iS) = meanFinite(ROLLPK(:,iM,iA,iS));
            mPITC(iM,iA,iS) = meanFinite(PITCHPK(:,iM,iA,iS));
            mSAT(iM,iA,iS)  = meanFinite(SATURATE(:,iM,iA,iS));
            mLAG(iM,iA,iS)  = meanFinite(LAGERR(:,iM,iA,iS));

            mEFF(iM,iA,iS)  = meanFinite(EFFORT(~d,iM,iA,iS));
            mDATA(iM,iA,iS) = meanFinite(DATARATE(~d,iM,iA,iS));
            mACK(iM,iA,iS)  = meanFinite(ACKRATE(~d,iM,iA,iS));
            mTAOI(iM,iA,iS) = meanFinite(TRUEAOI(~d,iM,iA,iS));
            mEAOI(iM,iA,iS) = meanFinite(ESTAOI(~d,iM,iA,iS));

            mMR(iM,iA,iS)   = meanFinite(MASSRAT(:,iM,iA,iS));
            mDR(iM,iA,iS)   = meanFinite(DRAGRAT(:,iM,iA,iS));
            mAR(iM,iA,iS)   = meanFinite(AEXTRMS(:,iM,iA,iS));
            mAP(iM,iA,iS)   = meanFinite(AEXTPEAK(:,iM,iA,iS));

            sumINV(iM,iA,iS) = sum(INVSUM(:,iM,iA,iS), 'omitnan');

        end
    end
end


%% ============================================================
% Attribution table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Attribution: Causal-v3 across perturbation arms\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-13s %10s %12s %10s %9s %8s %8s %8s\n', ...
    'Scenario','Arm','CausalRMSE','deltaB0%','DATA Hz','minSep','sat%','aExtRMS','massR');

for iS = 1:nScenario

    base0 = mRMSE(IDX_CAUSAL,IDX_B0,iS);

    for iA = 1:nArm

        fprintf('%-10s %-13s %10.4f %12.2f %10.2f %9.4f %8.3f %8.3f %8.2f\n', ...
            scenarioNames{iS}, armNames{iA}, ...
            mRMSE(IDX_CAUSAL,iA,iS), ...
            100*(mRMSE(IDX_CAUSAL,iA,iS) - base0)/base0, ...
            mDATA(IDX_CAUSAL,iA,iS), mMSEP(IDX_CAUSAL,iA,iS), ...
            100*mSAT(IDX_CAUSAL,iA,iS), mAR(IDX_CAUSAL,iA,iS), ...
            mMR(IDX_CAUSAL,iA,iS));

    end

    fprintf('\n');

end


%% ============================================================
% B7 detail, all methods
% ============================================================

fprintf('============================================================\n');
fprintf('B7 combined medium - all methods\n');
fprintf('============================================================\n\n');

fprintf('%-10s %-12s %9s %9s %9s %9s %9s %8s %9s %9s %8s %8s\n', ...
    'Scenario','Method','B0 RMSE','B7 RMSE','delta%','minSep','SafeFail', ...
    'sat%','DATA Hz','dDATA%','estAoI','lagErr');

for iS = 1:nScenario
    for iM = 1:nMethod

        a = mRMSE(iM,IDX_B0,iS);
        b = mRMSE(iM,IDX_B7,iS);

        c = mDATA(iM,IDX_B0,iS);
        d = mDATA(iM,IDX_B7,iS);

        fprintf('%-10s %-12s %9.4f %9.4f %9.2f %9.4f %9.1f %8.3f %9.2f %9.2f %8.4f %8.4f\n', ...
            scenarioNames{iS}, methodNames{iM}, ...
            a, b, 100*(b-a)/a, mMSEP(iM,IDX_B7,iS), 100*mSAFE(iM,IDX_B7,iS), ...
            100*mSAT(iM,IDX_B7,iS), d, 100*(d-c)/c, ...
            mEAOI(iM,IDX_B7,iS), mLAG(iM,IDX_B7,iS));

    end
    fprintf('\n');
end


%% ============================================================
% Gates at B7
% ============================================================

fprintf('============================================================\n');
fprintf('EXP09B acceptance gates (B7 combined medium)\n');
fprintf('============================================================\n\n');

safeEvaluable = numSeeds >= 20;

g1Div = sum(nDIV(:,IDX_B7,:), 'all');

g2Bad = 0; g2Tot = 0;
g3Bad = 0; g3Tot = 0;
g4Bad = 0; g4Tot = 0;

for iS = 1:nScenario
    for iM = 1:nMethod

        a = mRMSE(iM,IDX_B0,iS);
        b = mRMSE(iM,IDX_B7,iS);

        g2Tot = g2Tot + 1;
        if ~(b <= 1.25*a)
            g2Bad = g2Bad + 1;
            fprintf('    G2 breach: %-9s %-12s %.4f -> %.4f  (%.2fx)\n', ...
                scenarioNames{iS}, methodNames{iM}, a, b, b/a);
        end

        g3Tot = g3Tot + 1;
        g3Bad = g3Bad + (mSAFE(iM,IDX_B7,iS) > 0.05);

        g4Tot = g4Tot + 1;
        g4Bad = g4Bad + (mSAT(iM,IDX_B7,iS) > 0.05);

    end
end

rC = mDATA(IDX_CAUSAL,IDX_B7,1);
rM = mDATA(IDX_CAUSAL,IDX_B7,2);
rS = mDATA(IDX_CAUSAL,IDX_B7,3);

g5 = (rC < rM) && (rM < rS);

gateNames = { ...
    'G1 0 NaN / 0 DIVERGED', ...
    'G2 RMSE_pert <= 1.25 x RMSE_nominal', ...
    'G3 SafeFail <= 5%', ...
    'G4 saturation <= 5%', ...
    'G5 Causal rate Clean<Moderate<Stressed'};

gatePass = [g1Div == 0, g2Bad == 0, g3Bad == 0, g4Bad == 0, g5];

gateVals = { ...
    sprintf('%d diverged of %d B7 runs', g1Div, numSeeds*nMethod*nScenario), ...
    sprintf('%d of %d cells breached', g2Bad, g2Tot), ...
    sprintf('%d of %d cells breached', g3Bad, g3Tot), ...
    sprintf('%d of %d cells breached', g4Bad, g4Tot), ...
    sprintf('%.2f < %.2f < %.2f Hz', rC, rM, rS)};

gateStatus = cell(size(gateNames));

for q = 1:numel(gateNames)
    if q == 3 && ~safeEvaluable
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


%% ============================================================
% Comparative diagnostics - NOT gates
% ============================================================

fprintf('\n  COMPARATIVE DIAGNOSTICS (not gates):\n');

cvBad = 0;
for iS = 1:nScenario
    cvBad = cvBad + ~(mRMSE(IDX_CAUSAL,IDX_B7,iS) < mRMSE(IDX_EVENT,IDX_B7,iS));
end

fprintf('    Causal < State-event at B7 : %d of %d scenarios fail\n', cvBad, nScenario);

keepP10 = 0; keepP20 = 0;
for iS = 1:nScenario

    r0 = sign(mRMSE(IDX_CAUSAL,IDX_B0,iS) - mRMSE(IDX_P10,IDX_B0,iS));
    r7 = sign(mRMSE(IDX_CAUSAL,IDX_B7,iS) - mRMSE(IDX_P10,IDX_B7,iS));

    s0 = sign(mRMSE(IDX_CAUSAL,IDX_B0,iS) - mRMSE(IDX_P20,IDX_B0,iS));
    s7 = sign(mRMSE(IDX_CAUSAL,IDX_B7,iS) - mRMSE(IDX_P20,IDX_B7,iS));

    keepP10 = keepP10 + (r0 == r7);
    keepP20 = keepP20 + (s0 == s7);

end

fprintf('    sign preserved B0 -> B7    : P10 %d/3, P20 %d/3\n', keepP10, keepP20);

fprintf('    causal invariant violations: %d total\n', sum(sumINV, 'all'));

nFailed = sum(strcmp(gateStatus,'FAIL'));
nDefer  = sum(strcmp(gateStatus,'DEFER'));

fprintf('\n');
if nDefer > 0
    fprintf('  EXP09B GATES: %d PASS, %d FAIL, %d DEFERRED to the 20-seed run\n', ...
        sum(strcmp(gateStatus,'PASS')), nFailed, nDefer);
elseif nFailed == 0
    fprintf('  EXP09B GATES: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  EXP09B GATES: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Table
% ============================================================

T = tidyFromArray( ...
    struct('RMSE',RMSE,'MINSEP',MINSEP,'SAFEFAIL',double(SAFEFAIL), ...
           'DIVERGED',double(DIVERGED),'ROLLPEAK',ROLLPK,'PITCHPEAK',PITCHPK, ...
           'SATURATION',SATURATE,'CONTROLEFFORT',EFFORT,'LAGERR',LAGERR, ...
           'DATARATE',DATARATE,'ACKRATE',ACKRATE, ...
           'TRUEAOI',TRUEAOI,'ESTAOI',ESTAOI, ...
           'MASSRATIO',MASSRAT,'DRAGRATIO',DRAGRAT, ...
           'AEXTRMS',AEXTRMS,'AEXTPEAK',AEXTPEAK,'INVARIANTS',INVSUM), ...
    {'seed','method','arm','scenario'}, ...
    {1:numSeeds, methodNames, armNames, scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP09B completed.\n');


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
