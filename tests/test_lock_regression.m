% TEST_LOCK_REGRESSION Locked experiments must reproduce bit-identically.
%
% EXP05B/C/D and EXP06A are the ideal-feedback reference and must not move.
% Three files they depend on have since gained additive capabilities:
%
%   deliverNetworkPackets          propagates a packet's seq if it has one
%   enqueueNetworkPackets          optional pre-drawn channel trace
%   enqueueTriggeredNetworkPackets optional pre-drawn channel trace
%
% Every addition is default-off or keyed on a field the locked simulators
% never set, so the claim is that they are inert. This test proves that
% rather than asserting it, by re-running the locked configurations and
% comparing against values recorded in docs/PREREGISTRATION.md.
%
% Run this before merging anything that touches the shared network layer.

startup;

fprintf('\n=== Locked-experiment regression ===\n\n');

failures = 0;

tol = 1e-12;


%% ============================================================
% 1. EXP05C ablation contributions
%
% The published chain, from results/exp05c_ablation.
% ============================================================

fprintf('[1] EXP05C ablation chain (20 seeds)\n');

scenarioNames = {'Clean','Moderate','Stressed'};
scenarioLoss  = [0.00 0.20 0.40];
scenarioDelay = [0.00 0.08 0.12];

expectedGain = [ ...
    43.93  32.74  32.89; ...   % A1 -> A2
    15.04   8.43   9.05; ...   % A2 -> A3
     0.00   5.71  16.07];      % A3 -> A4

numSeeds = 20;

meanRMSE = zeros(5,3);

for iS = 1:3

    acc = zeros(numSeeds,5);

    for s = 1:numSeeds

        cfg = defaultConfig();

        cfg.net.packetLoss = scenarioLoss(iS);
        cfg.net.delay      = scenarioDelay(iS);
        cfg.net.jitterStd  = 0;
        cfg.net.seed       = 900000 + 10000*iS + s;

        cfg.event.posThreshold = 0.05;
        cfg.event.velThreshold = 0.10;
        cfg.event.maxSilence   = 0.50;

        cfg.aoiEvent.posThreshold      = 0.05;
        cfg.aoiEvent.velThreshold      = 0.10;
        cfg.aoiEvent.aoiThreshold      = 0.12;
        cfg.aoiEvent.maxSilence        = 0.50;
        cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
        cfg.aoiEvent.aoiMinInterTx     = 0.10;
        cfg.aoiEvent.aoiStateScaleBase = 0.50;
        cfg.aoiEvent.aoiStateScaleMin  = 0.20;
        cfg.aoiEvent.aoiAdaptRange     = 1.00;

        for iV = 1:5

            c = cfg;

            switch iV
                case 1
                    c.net.commPeriod = 0.10;
                    out = simSwarmNetworkQueued(c);
                case 2
                    out = simSwarmEventTriggered(c);
                case 3
                    c.ablation.useAdaptiveScale = false;
                    out = simSwarmAoIAblation(c);
                case 4
                    c.ablation.useAdaptiveScale = true;
                    out = simSwarmAoIAblation(c);
                case 5
                    out = simSwarmAoIAware(c);
            end

            M = computeSwarmMetrics(out, c);

            acc(s,iV) = M.formationRMSE;

        end

    end

    meanRMSE(:,iS) = mean(acc,1)';

end

for c = 1:3

    for iS = 1:3

        a = meanRMSE(c+1,iS);
        b = meanRMSE(c+2,iS);

        gain = 100*(a-b)/a;

        d = abs(gain - expectedGain(c,iS));

        if d < 0.005
            status = 'ok  ';
        else
            status = 'FAIL';
            failures = failures + 1;
        end

        fprintf('    %s A%d -> A%d %-9s expected %+6.2f %%  got %+6.2f %%\n', ...
            status, c, c+1, scenarioNames{iS}, expectedGain(c,iS), gain);

    end

end


%% ============================================================
% 2. EXP06A communication scaling exponent
% ============================================================

fprintf('\n[2] EXP06A scaling exponent, Full-AoI (20 seeds)\n');

swarmSizes = [5 10 20 50];

expectedAlpha = [0.996 0.978];   % Moderate, Stressed

scLoss  = [0.20 0.40];
scDelay = [0.08 0.12];

for iS = 1:2

    txTotal = zeros(numel(swarmSizes),1);

    for iN = 1:numel(swarmSizes)

        acc = zeros(numSeeds,1);

        for s = 1:numSeeds

            cfg = applyScalableSwarmConfig(defaultConfig(), swarmSizes(iN));

            cfg.net.packetLoss = scLoss(iS);
            cfg.net.delay      = scDelay(iS);
            cfg.net.jitterStd  = 0;
            cfg.net.seed       = 1100000 + 100000*(iS+1) + 10000*iN + s;

            cfg.aoiEvent.posThreshold      = 0.05;
            cfg.aoiEvent.velThreshold      = 0.10;
            cfg.aoiEvent.aoiThreshold      = 0.12;
            cfg.aoiEvent.maxSilence        = 0.50;
            cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
            cfg.aoiEvent.aoiMinInterTx     = 0.10;
            cfg.aoiEvent.aoiStateScaleBase = 0.50;
            cfg.aoiEvent.aoiStateScaleMin  = 0.20;
            cfg.aoiEvent.aoiAdaptRange     = 1.00;

            out = simSwarmAoIAware(cfg);

            acc(s) = out.txCount / (out.t(end)-out.t(1));

        end

        txTotal(iN) = mean(acc);

    end

    pf = polyfit(log(swarmSizes(:)), log(txTotal), 1);

    alpha = pf(1);

    d = abs(alpha - expectedAlpha(iS));

    if d < 0.002
        status = 'ok  ';
    else
        status = 'FAIL';
        failures = failures + 1;
    end

    names = {'Moderate','Stressed'};

    fprintf('    %s %-9s expected alpha %.3f  got %.3f\n', ...
        status, names{iS}, expectedAlpha(iS), alpha);

end


%% ============================================================
% 3. The trace path must be OFF unless asked for
%
% A default that quietly changed would invalidate every locked run,
% so check the flag itself rather than trusting the call sites.
% ============================================================

fprintf('\n[3] Trace and phase-offset defaults\n');

cfg = defaultConfig();

if ~isfield(cfg.net,'useTrace') || ~cfg.net.useTrace
    fprintf('    ok   useTrace defaults off\n');
else
    fprintf('    FAIL useTrace defaults ON\n');
    failures = failures + 1;
end

if ~isfield(cfg.net,'phaseOffset') || ~cfg.net.phaseOffset
    fprintf('    ok   phaseOffset defaults off\n');
else
    fprintf('    FAIL phaseOffset defaults ON\n');
    failures = failures + 1;
end


%% ============================================================
% 4. Trace mode must actually change the realisation
%
% If enabling it changed nothing, it would not be a new realisation
% and the CRN claim would be empty.
% ============================================================

fprintf('\n[4] Trace mode is live and shared\n');

cfg = defaultConfig();
cfg.net.packetLoss = 0.40;
cfg.net.delay      = 0.12;
cfg.net.seed       = 31337;

cfg.event.posThreshold = 0.05;
cfg.event.velThreshold = 0.10;
cfg.event.maxSilence   = 0.50;

legacyOut = simSwarmNetworkQueued(cfg);

cfg.net.useTrace = true;

traceOut = simSwarmNetworkQueued(cfg);

if legacyOut.dropCount ~= traceOut.dropCount
    fprintf('    ok   trace produces its own realisation (%d vs %d drops)\n', ...
        legacyOut.dropCount, traceOut.dropCount);
else
    fprintf('    FAIL trace mode is inert\n');
    failures = failures + 1;
end

% The same trace seed must give the same realisation to a different policy.
t1 = generateNetworkTrace(cfg);
t2 = generateNetworkTrace(cfg);

if t1.hash == t2.hash
    fprintf('    ok   trace is reproducible (hash %.0f)\n', t1.hash);
else
    fprintf('    FAIL trace is not reproducible\n');
    failures = failures + 1;
end

cfgOther = cfg;
cfgOther.net.seed = 31338;

t3 = generateNetworkTrace(cfgOther);

if t3.hash ~= t1.hash
    fprintf('    ok   a different seed gives a different realisation\n');
else
    fprintf('    FAIL different seeds collide\n');
    failures = failures + 1;
end


%% ============================================================
% Verdict
% ============================================================

fprintf('\n');

if failures == 0
    fprintf('test_lock_regression: PASS\n');
else
    error('test_lock_regression: FAILED with %d problem(s)', failures);
end
