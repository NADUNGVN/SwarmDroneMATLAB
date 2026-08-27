function R = exp11RunMetrics(out, cfg, regime)
%EXP11RUNMETRICS Mission, per-segment and transition metrics for one run.
%
%   R = exp11RunMetrics(out, cfg, regime)
%
% Three levels of aggregation from one run, all from the same logs so they
% cannot disagree with each other:
%
%   R.mission     scalars over t in [8, 83]
%   R.segment     one row per 15 s regime segment, five of them
%   R.transition  DATA rate in the 0-1 s, 1-3 s and 3-5 s windows after
%                 each of the four switches, plus the remainder
%
% TIME WINDOWS, AND WHY THEY PARTITION EXACTLY
%
% The mission window is t >= 8, inclusive of the final sample, which is the
% definition metrics/computeSwarmMetrics.m has used since EXP05 and which
% every locked result is stated on. The five segments partition that same
% window: the first four are half-open [start, end), the last is closed
% [68, 83]. So the segment DATA counts sum to the mission DATA count
% exactly, and a reader can check that they do.
%
% The cost of that exactness is that the final segment holds 751 samples
% against 750 for the others - 15.02 s rather than 15.00 s. Every rate is
% therefore divided by its own counted duration rather than by the nominal
% 15 s, so the extra sample cannot inflate the last segment's rate. The
% alternative, forcing all five to 750 samples, would leave the segments
% failing to sum to the mission, and a table whose parts do not add up
% invites exactly the wrong kind of doubt.
%
% WINDOWED COUNTS COME FROM CUMULATIVE LOGS
%
% txCountLog, ackCountLog and broadcastCountLog are cumulative and written
% every outer step. A count over [a, b] is the difference of the log at the
% last sample in the window and at the sample before the first. That is why
% the warm-up can be excluded after the fact: the run itself does not need
% to know where the metric window starts.

if nargin < 3 || isempty(regime)
    regime = networkRegimeSchedule('exp11');
end

t  = out.t(:);
K  = numel(t);
dt = cfg.swarm.dt;
N  = cfg.swarm.N;

% EXP07C accounting constants, unchanged.
AIRTIME_DATA_BYTES = 48;
AIRTIME_ACK_BYTES  = 24;

COST_W = [0.10, 0.25, 0.50];

SAFETY_THRESHOLD = 0.25;


%% ============================================================
% Cumulative logs, with a zero-ACK fallback
%
% A method with no reverse channel emits zero ACKs. That is zero, not
% missing: it is what makes the ACK-inclusive cost models comparable
% across methods, and it is the same convention EXP10 used.
% ============================================================

txLog = out.txCountLog(:);

if isfield(out, 'ackCountLog') && ~isempty(out.ackCountLog)
    ackLog = out.ackCountLog(:);
else
    ackLog = zeros(K,1);
end

if isfield(out, 'broadcastCountLog') && ~isempty(out.broadcastCountLog)
    bcLog = out.broadcastCountLog(:);
else
    bcLog = nan(K,1);
end


%% ============================================================
% Divergence
%
% A diverged run is a stability failure AND unsafe. Its continuous
% metrics stay NaN so they cannot enter a mean, and DIVERGED labels it, so
% no NaN in the dataset is unexplained. Traffic counters are still
% recorded: a diverged run did transmit, and dropping its traffic would
% understate the cost of exactly the conditions where a method fails.
% ============================================================

R.diverged = any(~isfinite(out.P(:)));


%% ============================================================
% Formation error and pairwise separation, over the whole run
%
% Same definitions as metrics/computeSwarmMetrics.m: follower i against
% the leader position plus its desired offset, leader row zeroed.
% Recomputed here rather than called, because the segment tables need the
% per-step series and not just the mission scalar.
% ============================================================

if R.diverged

    formationError = nan(K, N);
    d2 = nan(K, max(N*(N-1)/2, 1));

else

    P = out.P;

    leaderPos  = P(:,1,:);
    desiredPos = leaderPos + reshape(cfg.swarm.offsets, [1 N 3]);

    formationError = sqrt(sum((P - desiredPos).^2, 3));
    formationError(:,1) = 0;

    [iPair, jPair] = find(triu(true(N), 1));

    d2 = zeros(K, numel(iPair));

    for c = 1:3
        dc = P(:,iPair,c) - P(:,jPair,c);
        d2 = d2 + dc.^2;
    end

end


%% ============================================================
% Mission metrics, t in [8, 83]
% ============================================================

mIdx = t >= regime.evalStart - 1e-12;

mFirst = find(mIdx, 1, 'first');
mLast  = find(mIdx, 1, 'last');

nMissionSamples = mLast - mFirst + 1;

missionDur = nMissionSamples * dt;

R.mission.tStart   = t(mFirst);
R.mission.tEnd     = t(mLast);
R.mission.duration = missionDur;
R.mission.nSamples = nMissionSamples;

[R.mission.nData, R.mission.nAck, R.mission.nBcast] = ...
    localWindowCounts(txLog, ackLog, bcLog, mFirst, mLast);

R.mission.dataHz  = R.mission.nData  / missionDur;
R.mission.ackHz   = R.mission.nAck   / missionDur;
R.mission.bcastHz = R.mission.nBcast / missionDur;

for w = 1:numel(COST_W)
    fname = sprintf('total_w%03d', round(COST_W(w)*100));
    R.mission.(fname) = ...
        (R.mission.nData + COST_W(w)*R.mission.nAck) / missionDur;
end

R.mission.airtime = ...
    (AIRTIME_DATA_BYTES*R.mission.nData + ...
     AIRTIME_ACK_BYTES *R.mission.nAck) / missionDur;

R.mission.broadcast = (R.mission.nBcast + R.mission.nAck) / missionDur;

if R.diverged

    R.mission.rmse     = NaN;
    R.mission.maxError = NaN;
    R.mission.minSep   = NaN;
    R.mission.safeFail = true;
    R.mission.trueAoI  = NaN;
    R.mission.estAoI   = NaN;

else

    errEval = formationError(mIdx, 2:N);

    R.mission.rmse     = sqrt(mean(errEval(:).^2));
    R.mission.maxError = max(errEval(:));

    dEval = d2(mIdx, :);

    if isempty(dEval)
        R.mission.minSep = inf;
    else
        R.mission.minSep = sqrt(min(dEval(:)));
    end

    R.mission.safeFail = R.mission.minSep < SAFETY_THRESHOLD;

    R.mission.trueAoI = localMeanFinite(out.meanAoI(mIdx));

    if isfield(out, 'estimatedAoI') && ~isempty(out.estimatedAoI)
        ea = out.estimatedAoI(mIdx, :, :);
        R.mission.estAoI = mean(ea(isfinite(ea) & ea > 0));
    else
        % No estimated AoI exists for a method without a reverse
        % channel. NaN here means "this method has no such quantity",
        % not "the value was lost".
        R.mission.estAoI = NaN;
    end

end


%% ============================================================
% Per-segment metrics
%
% The two Clean segments and the two Moderate segments stay SEPARATE.
% Merging them would erase the return leg, which is the half of the
% adaptivity question a one-way sweep cannot answer.
% ============================================================

nSeg = numel(regime.segStart);

R.segment = struct( ...
    'name', regime.segName(:), ...
    'tStart', num2cell(regime.segStart(:)), ...
    'tEnd',   num2cell(regime.segEnd(:)));

for s = 1:nSeg

    a = regime.segStart(s);
    b = regime.segEnd(s);

    isLast = (s == nSeg);

    if isLast
        sIdx = (t >= a - 1e-12) & (t <= b + 1e-12);
    else
        sIdx = (t >= a - 1e-12) & (t <  b - 1e-12);
    end

    kFirst = find(sIdx, 1, 'first');
    kLast  = find(sIdx, 1, 'last');

    nSamples = kLast - kFirst + 1;
    segDur   = nSamples * dt;

    R.segment(s).nSamples = nSamples;
    R.segment(s).duration = segDur;
    R.segment(s).regime   = regime.label{s};

    [nD, nA, nB] = localWindowCounts(txLog, ackLog, bcLog, kFirst, kLast);

    R.segment(s).nData  = nD;
    R.segment(s).nAck   = nA;
    R.segment(s).nBcast = nB;

    R.segment(s).dataHz = nD / segDur;
    R.segment(s).ackHz  = nA / segDur;

    R.segment(s).total_w025 = (nD + 0.25*nA) / segDur;

    if R.diverged

        R.segment(s).rmse   = NaN;
        R.segment(s).minSep = NaN;
        R.segment(s).aoi    = NaN;

    else

        e = formationError(sIdx, 2:N);
        R.segment(s).rmse = sqrt(mean(e(:).^2));

        dSeg = d2(sIdx, :);

        if isempty(dSeg)
            R.segment(s).minSep = inf;
        else
            R.segment(s).minSep = sqrt(min(dSeg(:)));
        end

        R.segment(s).aoi = localMeanFinite(out.meanAoI(sIdx));

    end

end


%% ============================================================
% Transition diagnostics
%
% DATA rate in the 0-1 s, 1-3 s and 3-5 s windows after each switch, and
% over the remainder of the segment the switch opens. Purely descriptive:
% no response-time threshold is defined here or anywhere, because none was
% pre-registered and inventing one after seeing the traces is how a
% diagnostic turns into a claim.
%
% The delta columns compare each window against the LAST 5 s before the
% switch, so "how much did it move" is answered against what the method
% was actually doing rather than against a segment average that already
% contains the transition.
% ============================================================

winEdges = [0 1; 1 3; 3 5];

nSw = numel(regime.switchTimes);

R.transition = struct([]);

r = 0;

for w = 1:nSw

    tSw = regime.switchTimes(w);

    % Which segment the switch opens, and where it ends.
    segIdxAfter = find(regime.segStart == tSw, 1);

    if isempty(segIdxAfter)
        segEndAfter = regime.tEnd;
    else
        segEndAfter = regime.segEnd(segIdxAfter);
    end

    % Pre-switch baseline: the 5 s immediately before the switch.
    preRate = localRateOver(t, txLog, dt, tSw - 5, tSw);

    labelFrom = localRegimeLabelAt(regime, tSw - dt);
    labelTo   = localRegimeLabelAt(regime, tSw);

    for e = 1:size(winEdges,1)

        a = tSw + winEdges(e,1);
        b = tSw + winEdges(e,2);

        r = r + 1;

        R.transition(r).switchTime = tSw;
        R.transition(r).fromRegime = labelFrom;
        R.transition(r).toRegime   = labelTo;
        R.transition(r).window     = sprintf('%g-%gs', ...
            winEdges(e,1), winEdges(e,2));

        R.transition(r).dataHz    = localRateOver(t, txLog, dt, a, b);
        R.transition(r).preDataHz = preRate;
        R.transition(r).deltaHz   = R.transition(r).dataHz - preRate;

        if R.diverged
            R.transition(r).aoi      = NaN;
            R.transition(r).rmse     = NaN;
            R.transition(r).deltaAoI = NaN;
            R.transition(r).deltaRmse = NaN;
        else
            wIdx = (t >= a - 1e-12) & (t < b - 1e-12);
            pIdx = (t >= tSw - 5 - 1e-12) & (t < tSw - 1e-12);

            R.transition(r).aoi  = localMeanFinite(out.meanAoI(wIdx));
            eW = formationError(wIdx, 2:N);
            R.transition(r).rmse = sqrt(mean(eW(:).^2));

            preAoI  = localMeanFinite(out.meanAoI(pIdx));
            eP      = formationError(pIdx, 2:N);
            preRmse = sqrt(mean(eP(:).^2));

            R.transition(r).deltaAoI  = R.transition(r).aoi  - preAoI;
            R.transition(r).deltaRmse = R.transition(r).rmse - preRmse;
        end

    end

    % Remainder of the segment the switch opened, i.e. from +5 s to the
    % segment end. Reported so the three short windows can be read
    % against the settled behaviour rather than in isolation.
    r = r + 1;

    R.transition(r).switchTime = tSw;
    R.transition(r).fromRegime = labelFrom;
    R.transition(r).toRegime   = labelTo;
    R.transition(r).window     = 'remainder';

    R.transition(r).dataHz    = ...
        localRateOver(t, txLog, dt, tSw + 5, segEndAfter);
    R.transition(r).preDataHz = preRate;
    R.transition(r).deltaHz   = R.transition(r).dataHz - preRate;

    if R.diverged
        R.transition(r).aoi       = NaN;
        R.transition(r).rmse      = NaN;
        R.transition(r).deltaAoI  = NaN;
        R.transition(r).deltaRmse = NaN;
    else
        wIdx = (t >= tSw + 5 - 1e-12) & (t < segEndAfter - 1e-12);
        pIdx = (t >= tSw - 5 - 1e-12) & (t < tSw - 1e-12);

        R.transition(r).aoi = localMeanFinite(out.meanAoI(wIdx));
        eW = formationError(wIdx, 2:N);
        R.transition(r).rmse = sqrt(mean(eW(:).^2));

        preAoI  = localMeanFinite(out.meanAoI(pIdx));
        eP      = formationError(pIdx, 2:N);
        preRmse = sqrt(mean(eP(:).^2));

        R.transition(r).deltaAoI  = R.transition(r).aoi  - preAoI;
        R.transition(r).deltaRmse = R.transition(r).rmse - preRmse;
    end

end


%% ============================================================
% Provenance and invariant counters
% ============================================================

R.traceHash      = localField(out, 'traceHash',      NaN);
R.traceHashExact = localField(out, 'traceHashExact', NaN);
R.ackTraceHash      = localField(out, 'ackTraceHash',      NaN);
R.ackTraceHashExact = localField(out, 'ackTraceHashExact', NaN);
R.phaseHash         = localField(out, 'phaseHash',         NaN);

R.invariantViolations = localField(out, 'invariantViolations', 0);

R.periodSwitchTimes  = localField(out, 'periodSwitchTimes',  []);
R.periodSwitchValues = localField(out, 'periodSwitchValues', []);

R.txCountTotal = out.txCount;
R.dropCount    = localField(out, 'dropCount', NaN);

end


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function [nD, nA, nB] = localWindowCounts(txLog, ackLog, bcLog, kFirst, kLast)
%LOCALWINDOWCOUNTS Counts accumulated over samples kFirst..kLast.
%
% The logs are cumulative AFTER the step, so the count over a window is
% log(kLast) minus log(kFirst-1); at kFirst = 1 there is nothing before the
% window and the baseline is zero.

if kFirst <= 1
    base = [0 0 0];
else
    base = [txLog(kFirst-1), ackLog(kFirst-1), bcLog(kFirst-1)];
end

nD = txLog(kLast)  - base(1);
nA = ackLog(kLast) - base(2);
nB = bcLog(kLast)  - base(3);

end


function rate = localRateOver(t, txLog, dt, a, b)
%LOCALRATEOVER Mean DATA transmission rate over [a, b), in Hz.
%
% Returns NaN for an empty window rather than dividing by zero, so a window
% that falls outside the run is visibly absent instead of appearing as a
% zero rate.

idx = (t >= a - 1e-12) & (t < b - 1e-12);

if ~any(idx)
    rate = NaN;
    return;
end

kFirst = find(idx, 1, 'first');
kLast  = find(idx, 1, 'last');

if kFirst <= 1
    base = 0;
else
    base = txLog(kFirst-1);
end

n = txLog(kLast) - base;

rate = n / ((kLast - kFirst + 1) * dt);

end


function lbl = localRegimeLabelAt(regime, tk)
%LOCALREGIMELABELAT The regime label in force at tk.

idx = 1;

for s = 2:numel(regime.tStart)
    if tk >= regime.tStart(s) - 1e-12
        idx = s;
    else
        break;
    end
end

lbl = regime.label{idx};

end


function m = localMeanFinite(v)
%LOCALMEANFINITE Mean over the finite entries, NaN if there are none.
%
% AoI logs carry NaN on steps where no age sample exists - a link that has
% never delivered has no age. Averaging those in as zero would understate
% AoI precisely where the network is worst.

v = v(:);

keep = isfinite(v);

if ~any(keep)
    m = NaN;
else
    m = mean(v(keep));
end

end


function v = localField(s, name, defaultValue)

if isfield(s, name)
    v = s.(name);
else
    v = defaultValue;
end

end
