%% TEST_EXP11_REGIME_SEMANTICS
%
% The EXP11 negative control. EXP11 asks whether a policy that is never
% told the network regime can still track a network that changes underneath
% it. That question is only meaningful if the regime is genuinely hidden
% from the policy, so this file tries to prove the regime cannot leak.
%
% Four failures here would each invalidate the experiment while leaving the
% numbers looking perfectly reasonable:
%
%   - a regime that reaches a trigger threshold, an adaptive-scale
%     parameter, a cooldown or a controller gain would make Causal-v3
%     regime-aware, and "the policy adapted" would then mean nothing more
%     than "we told it the answer"
%   - a regime that changes a fixed periodic method's rate would destroy the
%     entire comparison, because the reviewer objection being answered is
%     precisely that a periodic rate cannot be tuned to an unknown network
%   - the piecewise-constant channel machinery introducing any effect
%     beyond loss and delay would mean the time-varying runs are not
%     comparable with the frozen fixed-channel results
%   - the oracle switching anywhere other than the four preregistered
%     boundaries would stop it being a periodic reference at all
%
% Each is checked directly, and the first is checked twice - once by
% behaviour and once by reading the source, because a behavioural check can
% only cover the paths it happens to exercise.
%
% ============================================================

startup;

fprintf('\n');
fprintf('============================================================\n');
fprintf('test_exp11_regime_semantics\n');
fprintf('============================================================\n\n');

verdict = @(f) subsref({'FAIL','ok'}, struct('type','{}','subs',{{f+1}}));

seed = 26000001;

regime = networkRegimeSchedule('exp11');


%% ============================================================
% [1] A regime carries channel parameters and nothing else
%
% netParamsAt and ackParamsAt are the only two consumers of a regime. If
% either returned anything a policy could read as a regime label, the
% hiding would be broken at the source.
% ============================================================

cfg = applyExp11Config(seed, regime);

np = netParamsAt(cfg, 45);
ap = ackParamsAt(cfg, 45);

npFields = sort(fieldnames(np));
apFields = sort(fieldnames(ap));

checks = { ...
    isequal(npFields, sort({'packetLoss';'delay';'jitterStd';'segment'})), ...
        'netParamsAt returns only channel parameters'; ...
    isequal(apFields, sort({'loss';'delay';'jitterStd';'segment'})), ...
        'ackParamsAt returns only channel parameters'; ...
    np.packetLoss == 0.40 && np.delay == 0.12, ...
        'the Stressed segment resolves to the locked Stressed channel'; ...
    ap.loss == 0 && ap.delay == 0.12, ...
        'the reverse channel follows the forward delay at zero loss'};


%% ============================================================
% [2] Every policy parameter is identical across regimes
%
% Build the config at two very different constant regimes and compare
% everything that is not a channel field. A regime that reached a
% threshold would show up here as a difference.
% ============================================================

flatClean    = localConstantRegime(regime, 0.00, 0.00);
flatStressed = localConstantRegime(regime, 0.40, 0.12);

cA = applyExp11Config(seed, flatClean);
cB = applyExp11Config(seed, flatStressed);

policySame   = true;
policyDetail = '';

policyGroups = {'aoiEvent', 'event', 'causal', 'sixdof'};

for g = 1:numel(policyGroups)
    gname = policyGroups{g};
    if ~isequal(cA.(gname), cB.(gname))
        policySame   = false;
        policyDetail = gname;
    end
end

% Controller gains and geometry live on cfg.swarm. The whole struct is
% compared rather than a named list of gains, so a gain added later is
% covered without anyone remembering to extend this test.
swarmSame = isequal(cA.swarm, cB.swarm);

% cfg.net.commPeriod is the fixed periodic rate. A regime must not move it.
periodSame = isequal(cA.net.commPeriod, cB.net.commPeriod);

noRegimeOnPolicy = ~isfield(cA.aoiEvent, 'regime') ...
    && ~isfield(cA.event,  'regime') ...
    && ~isfield(cA.causal, 'regime') ...
    && ~isfield(cA.swarm,  'regime');

checks = [checks; { ...
    policySame, ...
        'no trigger, adaptive-scale, cooldown or plant parameter moves with the regime'; ...
    swarmSame, ...
        'no controller gain or geometry parameter moves with the regime'; ...
    periodSame, ...
        'the fixed periodic period does not move with the regime'; ...
    noRegimeOnPolicy, ...
        'no regime field is attached to any policy or controller struct'}];

if ~policySame
    fprintf('    [detail] policy group that moved: %s\n', policyDetail);
end


%% ============================================================
% [3] Source-level guard: who is allowed to read a regime
%
% A behavioural test can only cover the code it runs. This reads the
% source instead and asserts that cfg.net.regime and cfg.ack.regime are
% READ ONLY by the files entitled to see them. If someone later makes the
% Causal trigger consult the regime, this fails even if the resulting
% numbers look better.
%
% Comments are stripped before the scan. The channel-layer files
% legitimately DISCUSS the regime in their headers - explaining that they
% fall back to the static values when no schedule is attached - and
% allow-listing them to silence that prose would blunt the guard on the two
% files where a leak is most likely. Stripping comments keeps them in scope
% for real reads while ignoring what they say about themselves.
%
% Stripping from the first % on each line can in principle hide a match
% inside a string literal that follows a percent sign. Nothing in this
% project puts a config path inside a format string, and the alternative -
% allow-listing whole files - is the weaker check.
% ============================================================

allowed = { ...
    'netParamsAt.m', 'ackParamsAt.m', 'commPeriodAt.m', ...
    'networkRegimeSchedule.m', 'oraclePeriodicSchedule.m', ...
    'applyExp11Config.m', 'simSwarmExp11.m', 'exp11Methods.m', ...
    'test_exp11_regime_semantics.m', 'exp11_dynamic_network.m'};

scanDirs = {'network', 'simulation', 'swarm', 'controllers', 'utils', ...
    'configs', 'experiments', 'tests'};

offenders = {};

for d = 1:numel(scanDirs)

    if ~isfolder(scanDirs{d})
        continue;
    end

    listing = dir(fullfile(scanDirs{d}, '*.m'));

    for f = 1:numel(listing)

        if any(strcmp(listing(f).name, allowed))
            continue;
        end

        txt = fileread(fullfile(scanDirs{d}, listing(f).name));

        code = localStripComments(txt);

        if contains(code, 'net.regime') || contains(code, 'ack.regime')
            offenders{end+1} = listing(f).name;   %#ok<AGROW>
        end

    end

end

checks = [checks; { ...
    isempty(offenders), ...
        'only the channel layer and the EXP11 driver read a regime'}];

if ~isempty(offenders)
    fprintf('    [detail] files that read a regime: %s\n', ...
        strjoin(offenders, ', '));
end


%% ============================================================
% [4] A degenerate regime IS the static channel
%
% A regime whose segments all carry one quality must reproduce a run with
% no regime at all, bit for bit. This is what licenses comparing EXP11
% against the frozen fixed-channel results: the machinery adds nothing.
%
% Run over a short horizon - the property is structural, and a full 83 s
% run per arm would make the suite pay for nothing extra.
% ============================================================

cStatic = applyExp11Config(seed, regime);
cStatic.swarm.T = 6.0;
cStatic.net = rmfield(cStatic.net, 'regime');
cStatic.ack = rmfield(cStatic.ack, 'regime');
cStatic.net.packetLoss = 0.20;
cStatic.net.delay      = 0.08;
cStatic.ack.loss       = 0.00;
cStatic.ack.delay      = 0.08;

cFlat = applyExp11Config(seed, localConstantRegime(regime, 0.20, 0.08));
cFlat.swarm.T = 6.0;

oStatic = simSwarm6DOF(cStatic, 'Causal-v3');
oFlat   = simSwarmExp11(cFlat, 'Causal');

checks = [checks; { ...
    isequal(oStatic.P, oFlat.P), ...
        'a constant regime leaves the trajectory bit-identical to a static channel'; ...
    oStatic.txCount == oFlat.txCount, ...
        'a constant regime leaves DATA count identical to a static channel'; ...
    oStatic.ackTxCount == oFlat.ackTxCount, ...
        'a constant regime leaves ACK count identical to a static channel'; ...
    isequal(oStatic.traceHashExact, oFlat.traceHashExact), ...
        'a constant regime consumes the same channel realization'}];


%% ============================================================
% [5] A regime change does not advance the random stream
%
% The regime changes the THRESHOLD a pre-drawn uniform is compared against
% and the delay added to a packet. It must not draw anything. Two runs on
% one seed under different regimes must therefore meet the same
% realization, which the exact trace hash proves.
% ============================================================

cS = applyExp11Config(seed, localConstantRegime(regime, 0.40, 0.12));
cS.swarm.T = 6.0;

oS = simSwarmExp11(cS, 'Causal');

checks = [checks; { ...
    isequal(oFlat.traceHashExact, oS.traceHashExact), ...
        'changing the regime does not perturb the forward realization'; ...
    isequal(oFlat.ackTraceHashExact, oS.ackTraceHashExact), ...
        'changing the regime does not perturb the reverse realization'; ...
    oS.dropCount > oFlat.dropCount, ...
        'the worse regime does drop more packets, so the threshold is live'}];


%% ============================================================
% [6] Fixed periodic methods never switch rate; only the oracle does
%
% out.periodSwitchTimes is the passive audit trail. Empty for a fixed
% method IS the evidence that it did not adapt, and this is the check the
% EXP11 gate list refers to.
% ============================================================

cRun = applyExp11Config(seed, regime);
cRun.swarm.T = 45.0;    % spans the 23 s and 38 s switches

fixedIds = {'P5','P10','P12.5','P20','P25'};

fixedNoSwitch = true;

for m = 1:numel(fixedIds)
    om = simSwarmExp11(cRun, fixedIds{m});
    if ~isempty(om.periodSwitchTimes)
        fixedNoSwitch = false;
    end
end

oOracle = simSwarmExp11(cRun, 'OraclePeriodic');

% Over [0, 45] the oracle crosses the 23 s and 38 s boundaries, and its
% rate changes at both: P5 -> P10 -> P20.
oracleTimes  = round(oOracle.periodSwitchTimes  * 1e6) / 1e6;
oracleValues = round(oOracle.periodSwitchValues * 1e6) / 1e6;

oracleOnlyAtBoundaries = ~isempty(oracleTimes) && ...
    all(ismember(oracleTimes, regime.switchTimes));

checks = [checks; { ...
    fixedNoSwitch, ...
        'no fixed periodic method changed rate at any channel switch'; ...
    oracleOnlyAtBoundaries, ...
        'the oracle switched only at preregistered regime boundaries'; ...
    isequal(oracleTimes, [23, 38]), ...
        'the oracle switched at exactly the boundaries inside the horizon'; ...
    isequal(oracleValues, [0.10, 0.05]), ...
        'the oracle took the preregistered rates P10 then P20'}];


%% ============================================================
% [7] The seed block is a holdout, and the schedule is what was registered
% ============================================================

seedReport = assertExp11Seeds(26000001:26000050, false);

checks = [checks; { ...
    seedReport.pass, ...
        'the EXP11 seed block is disjoint from EXP01-EXP10'; ...
    isequal(regime.switchTimes, [23, 38, 53, 68]), ...
        'the schedule has exactly the four preregistered switch instants'; ...
    isequal(regime.segStart, [8, 23, 38, 53, 68]) ...
        && isequal(regime.segEnd, [23, 38, 53, 68, 83]), ...
        'the five metric segments start at t = 8 and end at t = 83'; ...
    isequal(regime.loss,  [0.00, 0.20, 0.40, 0.20, 0.00]) ...
        && isequal(regime.delay, [0.00, 0.08, 0.12, 0.08, 0.00]), ...
        'the three quality levels are the locked EXP05-EXP10 values'}];


%% ============================================================
% Verdict
% ============================================================

okFlags = false(size(checks,1),1);
okNames = cell(size(checks,1),1);

for q = 1:size(checks,1)
    okFlags(q) = logical(checks{q,1});
    okNames{q} = checks{q,2};
    fprintf('    %-4s %s\n', verdict(okFlags(q)), okNames{q});
end

fprintf('\n');

nBad = nnz(~okFlags);

if nBad == 0
    fprintf('test_exp11_regime_semantics: PASS (%d checks)\n', numel(okFlags));
else
    fprintf('test_exp11_regime_semantics: FAIL (%d of %d checks)\n', ...
        nBad, numel(okFlags));
    for q = find(~okFlags(:)')
        fprintf('    failed: %s\n', okNames{q});
    end
    error('test_exp11_regime_semantics failed.');
end


%% ============================================================
% LOCAL FUNCTION
%
% A regime with the same quality on every segment. Used twice above: to
% show that the piecewise machinery collapses to the static channel, and to
% show that changing the quality changes nothing but the channel.
% ============================================================

function r = localConstantRegime(base, lossValue, delayValue)

r = base;

n = numel(base.tStart);

r.loss      = repmat(lossValue,  1, n);
r.delay     = repmat(delayValue, 1, n);
r.jitterStd = zeros(1, n);

end


%% ============================================================
% LOCAL FUNCTION
%
% Drop MATLAB comments so the source guard above tests code rather than
% prose. Everything from the first percent sign on a line is removed.
% ============================================================

function code = localStripComments(txt)

lines = regexp(txt, '\r?\n', 'split');

for q = 1:numel(lines)
    p = strfind(lines{q}, '%');
    if ~isempty(p)
        lines{q} = lines{q}(1:p(1)-1);
    end
end

code = strjoin(lines, char(10));

end
