%% EXP09C timestep diagnostic
%
% Causal-v3 at outer dt = 0.01 / 0.02 / 0.04 with the inner step fixed at
% 500 Hz, 6-DOF plant, nominal estimator.
%
% The CRN problem this exists to solve: the historical trace is indexed by
% OUTER TIMESTEP, so it cannot be reused across different dt. A dt = 0.04
% run takes half as many steps as dt = 0.02 and would therefore read half
% the trace, meeting a different channel realization than the run it is
% being compared against. The comparison would then measure the random draw
% rather than the timestep.
%
% So this diagnostic switches on the additive physical-time trace mode:
% the master trace is indexed by seed x physical-time slot x directed link
% at traceBaseDt = 0.01, and every dt reads the same slot at the same
% instant. The flag defaults OFF and test_lock_regression proves every
% locked experiment reproduces unchanged without it.
%
% Communication timing is NOT scaled with dt. commPeriod, minInterTx,
% aoiMinInterTx and maxSilence are physical properties of the protocol, not
% multiples of the integration step.
%
% Timing gate uses the SYMMETRIC relative difference, fixed before the run
% so no denominator is chosen after seeing which way the numbers fell:
%
%   d(x01, x02) = |x01 - x02| / ((x01 + x02)/2)
%
% dt = 0.04 is characterization only and carries no gate. If it breaks, the
% conclusion is that the method needs an outer rate of at least 25 Hz - a
% useful statement, not a failure to repair. The historical scheduler is
% not modified to make 0.04 look better.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp09c_timestep_diagnostic');


%% ============================================================
% Scope
% ============================================================

numSeeds = 20;

swarmN = 5;

topologyName = 'ring2';

scenarioNames = {'Moderate'; 'Stressed'};
scenarioLoss  = [0.20; 0.40];
scenarioDelay = [0.08; 0.12];

methodNames = {'P10'; 'P20'; 'Causal-v3'};

dtList = [0.01; 0.02; 0.04];

nScenario = numel(scenarioNames);
nMethod   = numel(methodNames);
nDt       = numel(dtList);

IDX_P10    = 1;
IDX_P20    = 2;
IDX_CAUSAL = 3;

IDX_DT01 = 1;
IDX_DT02 = 2;
IDX_DT04 = 3;


%% ============================================================
% Locked parameters
% ============================================================

epsP = 0.05;  epsV = 0.10;
aoiThreshold = 0.12;  aoiCooldown = 0.10;  maxSilence = 0.50;

safetyThreshold = 0.25;

TRACE_BASE_DT = 0.01;


%% ============================================================
% Storage
% ============================================================

sz = [numSeeds nMethod nDt nScenario];

RMSE     = nan(sz);
MINSEP   = nan(sz);
SAFEFAIL = false(sz);
DIVERGED = false(sz);
DATARATE = nan(sz);
TRUEAOI  = nan(sz);
TRACEH   = nan(sz);


%% ============================================================
% Experiment
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP09C timestep diagnostic\n');
fprintf('============================================================\n\n');

fprintf('inner 500 Hz fixed | physical-time CRN at %.3f s\n', TRACE_BASE_DT);
fprintf('Seeds %d | sims %d\n', numSeeds, prod(sz));

ensureParallelPool(numSeeds);


for iS = 1:nScenario

    fprintf('\n--- %s ---\n', scenarioNames{iS});

    for iD = 1:nDt

        fprintf('  dt = %.2f  ', dtList(iD));

        for iM = 1:nMethod

            rmseS = nan(numSeeds,1);
            msepS = nan(numSeeds,1);
            safeS = false(numSeeds,1);
            divS  = false(numSeeds,1);
            dataS = nan(numSeeds,1);
            taoiS = nan(numSeeds,1);
            thS   = nan(numSeeds,1);

            parfor s = 1:numSeeds

                cfg = applyTopologyConfig(defaultConfig(), swarmN, topologyName);

                cfg.swarm.normalizeConsensusDegree = false;

                cfg.swarm.dt = dtList(iD);

                cfg.net.packetLoss = scenarioLoss(iS);
                cfg.net.delay      = scenarioDelay(iS);
                cfg.net.jitterStd  = 0;

                cfg.net.seed = 6900000 + 10000*iS + s;

                cfg.net.useTrace    = true;
                cfg.net.phaseOffset = false;

                % Physical-time CRN, so every dt meets the same channel at
                % the same instant.
                cfg.net.traceBaseDt = TRACE_BASE_DT;

                % Communication timing is NOT scaled with dt.
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

                % Inner step stays 500 Hz, so the ratio follows dt.
                cfg.sixdof.ratio = round(cfg.swarm.dt / 0.002);

                fwd = generateNetworkTrace(cfg);
                thS(s) = fwd.hash;

                out = simSwarm6DOF(cfg, methodNames{iM});

                M = computeSwarmMetrics(out, cfg);
                Q = compute6DOFMetrics(out, cfg);

                mission = out.t(end) - out.t(1);

                divS(s) = Q.diverged || any(~isfinite(out.P(:)));

                if divS(s)
                    safeS(s) = true;
                else
                    rmseS(s) = M.formationRMSE;
                    msepS(s) = M.minSeparationEval;
                    safeS(s) = M.minSeparationEval < safetyThreshold;
                    dataS(s) = out.txCount / mission;
                    taoiS(s) = mean(out.meanAoI(out.t >= 8));
                end

            end

            RMSE(:,iM,iD,iS)     = rmseS;
            MINSEP(:,iM,iD,iS)   = msepS;
            SAFEFAIL(:,iM,iD,iS) = safeS;
            DIVERGED(:,iM,iD,iS) = divS;
            DATARATE(:,iM,iD,iS) = dataS;
            TRUEAOI(:,iM,iD,iS)  = taoiS;
            TRACEH(:,iM,iD,iS)   = thS;

        end

        fprintf('done\n');

    end

end


%% ============================================================
% CRN alignment check
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('CRN alignment across dt\n');
fprintf('============================================================\n\n');

aligned = true;

for iS = 1:nScenario
    for iM = 1:nMethod
        h = squeeze(TRACEH(:,iM,:,iS));
        if ~all(abs(h - h(:,1)) < 1e-9, 'all')
            aligned = false;
        end
    end
end

fprintf('  physical-time trace hash identical across dt : %d\n', aligned);

if ~aligned
    error(['EXP09C timestep: the CRN differs across dt, so any difference ' ...
           'would report the random draw rather than the timestep.']);
end


%% ============================================================
% Aggregation
% ============================================================

dims = [nMethod nDt nScenario];

mRMSE = nan(dims);  mMSEP = nan(dims);  mSAFE = nan(dims);
mDATA = nan(dims);  mTAOI = nan(dims);  nDIV = zeros(dims);

for iS = 1:nScenario
    for iD = 1:nDt
        for iM = 1:nMethod

            d = DIVERGED(:,iM,iD,iS);

            nDIV(iM,iD,iS)  = nnz(d);
            mRMSE(iM,iD,iS) = meanFinite(RMSE(~d,iM,iD,iS));
            mMSEP(iM,iD,iS) = meanFinite(MINSEP(~d,iM,iD,iS));
            mSAFE(iM,iD,iS) = mean(SAFEFAIL(:,iM,iD,iS));
            mDATA(iM,iD,iS) = meanFinite(DATARATE(~d,iM,iD,iS));
            mTAOI(iM,iD,iS) = meanFinite(TRUEAOI(~d,iM,iD,iS));

        end
    end
end


%% ============================================================
% Results, including the scheduler sanity check
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Results\n');
fprintf('============================================================\n\n');

fprintf('%-10s %6s %-12s %9s %9s %9s %10s %8s\n', ...
    'Scenario','dt','Method','RMSE','minSep','DATA Hz','trueAoI','nDiv');

for iS = 1:nScenario
    for iD = 1:nDt
        for iM = 1:nMethod

            fprintf('%-10s %6.2f %-12s %9.4f %9.4f %9.2f %10.4f %8d\n', ...
                scenarioNames{iS}, dtList(iD), methodNames{iM}, ...
                mRMSE(iM,iD,iS), mMSEP(iM,iD,iS), mDATA(iM,iD,iS), ...
                mTAOI(iM,iD,iS), nDIV(iM,iD,iS));

        end
    end
    fprintf('\n');
end

fprintf('  Scheduler sanity check - realized periodic rates:\n');

for iS = 1:nScenario
    for iD = 1:nDt
        fprintf('    %-9s dt %.2f : P10 %.2f Hz | P20 %.2f Hz\n', ...
            scenarioNames{iS}, dtList(iD), ...
            mDATA(IDX_P10,iD,iS), mDATA(IDX_P20,iD,iS));
    end
end


%% ============================================================
% Timing gate: dt 0.01 vs 0.02, Causal only
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Timestep gate (dt 0.01 vs 0.02, Causal-v3)\n');
fprintf('============================================================\n\n');

symDiff = @(a,b) abs(a-b) / ((a+b)/2);

rBad = 0; dBad = 0;

for iS = 1:nScenario

    r = symDiff(mRMSE(IDX_CAUSAL,IDX_DT01,iS), mRMSE(IDX_CAUSAL,IDX_DT02,iS));
    d = symDiff(mDATA(IDX_CAUSAL,IDX_DT01,iS), mDATA(IDX_CAUSAL,IDX_DT02,iS));

    fprintf('  %-9s RMSE %.4f vs %.4f -> %.2f%% | DATA %.2f vs %.2f -> %.2f%%\n', ...
        scenarioNames{iS}, ...
        mRMSE(IDX_CAUSAL,IDX_DT01,iS), mRMSE(IDX_CAUSAL,IDX_DT02,iS), 100*r, ...
        mDATA(IDX_CAUSAL,IDX_DT01,iS), mDATA(IDX_CAUSAL,IDX_DT02,iS), 100*d);

    rBad = rBad + (r > 0.05);
    dBad = dBad + (d > 0.05);

end

fprintf('\n');

gateNames = {'RMSE difference <= 5%', 'DATA-rate difference <= 5%'};
gatePass  = [rBad == 0, dBad == 0];
gateVals  = {sprintf('%d of %d scenarios breached', rBad, nScenario), ...
             sprintf('%d of %d scenarios breached', dBad, nScenario)};

for q = 1:numel(gateNames)
    if gatePass(q); v = 'PASS'; else; v = 'FAIL'; end
    fprintf('  [%-4s] %-32s %s\n', v, gateNames{q}, gateVals{q});
end


%% ============================================================
% dt = 0.04 boundary characterization - NOT a gate
% ============================================================

fprintf('\n  dt = 0.04 BOUNDARY CHARACTERIZATION (not a gate):\n');

for iS = 1:nScenario

    r = symDiff(mRMSE(IDX_CAUSAL,IDX_DT04,iS), mRMSE(IDX_CAUSAL,IDX_DT02,iS));
    d = symDiff(mDATA(IDX_CAUSAL,IDX_DT04,iS), mDATA(IDX_CAUSAL,IDX_DT02,iS));

    fprintf('    %-9s vs dt 0.02 : RMSE %+.2f%% | DATA %+.2f%% | SafeFail %.1f%% | nDiv %d\n', ...
        scenarioNames{iS}, 100*r, 100*d, ...
        100*mSAFE(IDX_CAUSAL,IDX_DT04,iS), nDIV(IDX_CAUSAL,IDX_DT04,iS));

end

fprintf(['\n    If dt = 0.04 breaks, the conclusion is that the method needs an\n' ...
         '    outer rate of at least 25 Hz. The scheduler is not modified to\n' ...
         '    make it look better.\n']);

nFailed = sum(~gatePass);

fprintf('\n');
if nFailed == 0
    fprintf('  TIMESTEP GATE: ALL PASS (%d/%d)\n', numel(gateNames), numel(gateNames));
else
    fprintf('  TIMESTEP GATE: %d of %d FAILED\n', nFailed, numel(gateNames));
    fprintf('  Per the pre-registration, nothing is to be tuned.\n');
end


%% ============================================================
% Table
% ============================================================

T = tidyFromArray( ...
    struct('RMSE',RMSE,'MINSEP',MINSEP,'SAFEFAIL',double(SAFEFAIL), ...
           'DIVERGED',double(DIVERGED),'DATARATE',DATARATE, ...
           'TRUEAOI',TRUEAOI,'TRACEHASH',TRACEH), ...
    {'seed','method','dt','scenario'}, ...
    {1:numSeeds, methodNames, ...
     arrayfun(@(v) sprintf('dt%.2f',v), dtList, 'UniformOutput', false), ...
     scenarioNames});

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows\n', height(T));

fprintf('\nEXP09C timestep diagnostic completed.\n');


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
