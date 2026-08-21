% TEST_CAUSAL_INVARIANTS Static and dynamic checks that Causal-AoI is causal.
%
% Two independent lines of defence:
%
%   1. STATIC   the transmitter decision path must not even mention a
%               receiver-side register. This is checkable by reading the
%               source, without following any logic.
%
%   2. DYNAMIC  run the simulator with assertions on and confirm all six
%               invariant counters are zero, in every network condition.
%
% The static check exists because a runtime counter only catches violations
% on paths that happen to execute. Forbidding the identifier outright is a
% stronger guarantee and is what makes the claim auditable.

startup;

root = projectRoot();

fprintf('\n=== Causal-AoI invariant checks ===\n\n');

failures = 0;


%% ============================================================
% 1. STATIC: forbidden identifiers in the transmitter path
% ============================================================

% Files that run on the transmitter side and decide whether to send.
guardedFiles = {
    fullfile(root,'network','enqueueCausalAoIPackets.m')
    fullfile(root,'network','initAckChannelState.m')
};

% Receiver-side registers the transmitter must never consult.
forbidden = {
    'net.genTime'
    'net.leaderGenTime'
    'net.Pij'
    'net.Vij'
    'net.leaderPos'
    'net.leaderVel'
    'net.leaderAcc'
    'net.valid'
    'net.leaderValid'
};

fprintf('[1] Static check: forbidden receiver-side reads\n');

for f = 1:numel(guardedFiles)

    path = guardedFiles{f};

    [~,name,ext] = fileparts(path);

    src = fileread(path);

    lines = strsplit(src, newline);

    hits = 0;

    for L = 1:numel(lines)

        line = lines{L};

        % Ignore comments: prose may legitimately name what is banned.
        commentStart = strfind(line, '%');

        if ~isempty(commentStart)
            line = line(1:commentStart(1)-1);
        end

        for q = 1:numel(forbidden)

            % Whole-identifier match. A plain substring test would flag
            % net.leaderAcceptedSeq as net.leaderAcc, which is a
            % different field entirely.
            pattern = [regexptranslate('escape', forbidden{q}) ...
                '(?![A-Za-z0-9_])'];

            if ~isempty(regexp(line, pattern, 'once'))

                fprintf('    FAIL %s%s:%d  uses %s\n', ...
                    name, ext, L, forbidden{q});

                hits = hits + 1;

            end

        end

    end

    if hits == 0
        fprintf('    ok   %s%s\n', name, ext);
    else
        failures = failures + hits;
    end

end


%% ============================================================
% 2. STATIC: the locked files must be untouched
% ============================================================

fprintf('\n[2] Static check: locked simulators still use the oracle\n');

lockedPath = fullfile(root,'simulation','simSwarmAoIAware.m');

lockedSrc = fileread(lockedPath);

if contains(lockedSrc, 'net.genTime')
    fprintf('    ok   simSwarmAoIAware.m unchanged (still ideal-feedback)\n');
else
    fprintf('    FAIL simSwarmAoIAware.m appears modified\n');
    failures = failures + 1;
end


%% ============================================================
% 3. DYNAMIC: all six counters zero under every network condition
% ============================================================

fprintf('\n[3] Dynamic check: invariant counters with assertions enabled\n');

scenarioNames = {'Clean','Moderate','Stressed'};
scenarioLoss  = [0.00 0.20 0.40];
scenarioDelay = [0.00 0.08 0.12];

% Also exercise a degraded reverse channel, otherwise the ACK path is
% never actually stressed and the test proves very little.
ackLoss  = [0.00 0.10 0.20];

for iS = 1:numel(scenarioNames)

    cfg = defaultConfig();

    cfg.net.packetLoss = scenarioLoss(iS);
    cfg.net.delay      = scenarioDelay(iS);
    cfg.net.jitterStd  = 0;
    cfg.net.seed       = 424242 + iS;

    cfg.aoiEvent.posThreshold      = 0.05;
    cfg.aoiEvent.velThreshold      = 0.10;
    cfg.aoiEvent.aoiThreshold      = 0.12;
    cfg.aoiEvent.maxSilence        = 0.50;
    cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
    cfg.aoiEvent.aoiMinInterTx     = 0.10;
    cfg.aoiEvent.aoiStateScaleBase = 0.50;
    cfg.aoiEvent.aoiStateScaleMin  = 0.20;
    cfg.aoiEvent.aoiAdaptRange     = 1.00;

    cfg.ack.loss             = ackLoss(iS);
    cfg.ack.delay            = scenarioDelay(iS);
    cfg.ack.jitterStd        = 0;
    cfg.ack.assertInvariants = true;

    try

        out = simSwarmAoICausal(cfg);

        if out.invariantViolations == 0
            status = 'ok  ';
        else
            status = 'FAIL';
            failures = failures + 1;
        end

        fprintf(['    %s %-9s ackLoss %2.0f%%  violations %d  ' ...
                 'ackUpdates %d  staleAckDiscarded %d\n'], ...
            status, scenarioNames{iS}, 100*ackLoss(iS), ...
            out.invariantViolations, out.ackUpdateCount, ...
            out.staleAckDiscardedCount);

    catch err

        fprintf('    FAIL %-9s raised: %s\n', scenarioNames{iS}, err.message);

        failures = failures + 1;

    end

end


%% ============================================================
% 4. DYNAMIC: the ACK channel must actually be exercised
%
% A run where no ACK is ever superseded proves nothing about the
% protocol's handling of late or lost acknowledgements.
% ============================================================

fprintf('\n[4] Dynamic check: reverse channel is genuinely stressed\n');

cfg = defaultConfig();

cfg.net.packetLoss = 0.40;
cfg.net.delay      = 0.12;
cfg.net.seed       = 999001;

cfg.aoiEvent.posThreshold      = 0.05;
cfg.aoiEvent.velThreshold      = 0.10;
cfg.aoiEvent.aoiThreshold      = 0.12;
cfg.aoiEvent.maxSilence        = 0.50;
cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
cfg.aoiEvent.aoiMinInterTx     = 0.10;
cfg.aoiEvent.aoiStateScaleBase = 0.50;
cfg.aoiEvent.aoiStateScaleMin  = 0.20;
cfg.aoiEvent.aoiAdaptRange     = 1.00;

cfg.ack.loss             = 0.20;
cfg.ack.delay            = 0.12;
cfg.ack.assertInvariants = true;

% Jitter is required here: with a fixed reverse delay the ACK channel is
% FIFO, so no ACK can ever be superseded and the ordering logic would go
% untested no matter how much loss is applied.
cfg.ack.jitterStd        = 0.05;

out = simSwarmAoICausal(cfg);

if out.ackDropCount > 0
    fprintf('    ok   %d ACKs lost on the reverse channel\n', out.ackDropCount);
else
    fprintf('    FAIL no ACK was ever lost; reverse channel not exercised\n');
    failures = failures + 1;
end

if out.staleAckDiscardedCount > 0
    fprintf('    ok   %d superseded ACKs correctly discarded\n', ...
        out.staleAckDiscardedCount);
else
    fprintf('    FAIL no ACK was ever superseded; ordering logic untested\n');
    failures = failures + 1;
end


%% ============================================================
% 5. DYNAMIC: causal equals ideal at zero delay, differs otherwise
%
% At Clean the forward delay is zero, so an ACK floored at one timestep
% arrives at step k+1 -- exactly when the ideal simulator's own update
% would first be CONSUMED, since its sync happens after its trigger has
% already run. The two are therefore provably equivalent at Clean, and
% the ideal-feedback assumption is physically realizable there.
%
% That makes Clean a strong correctness check rather than a difference
% check: any deviation means the forward data path was altered.
%
% The oracle's unfair advantage is entirely a DELAY phenomenon, so the
% difference must appear as soon as delay > 0.
% ============================================================

fprintf('\n[5] Dynamic check: equivalence at zero delay, divergence with delay\n');

names = {'Clean','Moderate','Stressed'};
loss  = [0.00 0.20 0.40];
delay = [0.00 0.08 0.12];

for iS = 1:numel(names)

    cfg = defaultConfig();

    cfg.net.packetLoss = loss(iS);
    cfg.net.delay      = delay(iS);
    cfg.net.seed       = 555001;

    cfg.aoiEvent.posThreshold      = 0.05;
    cfg.aoiEvent.velThreshold      = 0.10;
    cfg.aoiEvent.aoiThreshold      = 0.12;
    cfg.aoiEvent.maxSilence        = 0.50;
    cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
    cfg.aoiEvent.aoiMinInterTx     = 0.10;
    cfg.aoiEvent.aoiStateScaleBase = 0.50;
    cfg.aoiEvent.aoiStateScaleMin  = 0.20;
    cfg.aoiEvent.aoiAdaptRange     = 1.00;

    cfg.ack.loss             = 0.0;
    cfg.ack.delay            = delay(iS);
    cfg.ack.jitterStd        = 0;
    cfg.ack.assertInvariants = true;

    outCausal = simSwarmAoICausal(cfg);
    outIdeal  = simSwarmAoIAware(cfg);

    Mc = computeSwarmMetrics(outCausal, cfg);
    Mi = computeSwarmMetrics(outIdeal,  cfg);

    relDiff = abs(Mc.formationRMSE - Mi.formationRMSE) / Mi.formationRMSE;

    fprintf('    %-9s ideal %.6f (%5.2f Hz) | causal %.6f (%5.2f Hz) | diff %6.2f %%\n', ...
        names{iS}, ...
        Mi.formationRMSE, outIdeal.txRatePerChannel, ...
        Mc.formationRMSE, outCausal.txRatePerChannel, ...
        100*relDiff);

    if iS == 1

        % Zero delay: must be exactly equal.
        if relDiff == 0
            fprintf('             ok   exact match, forward path unaltered\n');
        else
            fprintf('             FAIL forward data path differs from the ideal simulator\n');
            failures = failures + 1;
        end

    else

        % Non-zero delay: the oracle advantage must show up.
        if relDiff > 0
            fprintf('             ok   diverges from the oracle as required\n');
        else
            fprintf('             FAIL identical to the oracle despite %.0f ms delay\n', ...
                1000*delay(iS));
            failures = failures + 1;
        end

    end

end


%% ============================================================
% Verdict
% ============================================================

fprintf('\n');

if failures == 0
    fprintf('test_causal_invariants: PASS\n');
else
    error('test_causal_invariants: FAILED with %d problem(s)', failures);
end
