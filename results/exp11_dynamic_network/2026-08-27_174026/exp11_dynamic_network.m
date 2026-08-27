%% EXP11 - WITHIN-RUN NETWORK SWITCHING / FIXED-PERIODIC CHALLENGE
%
% The one additional experiment authorised after the simulation-v1.0 freeze.
% It answers one reviewer objection and nothing else:
%
%   "Why not just use, or tune, a periodic rate such as P20?"
%
% Every experiment up to EXP10 held network quality FIXED for a whole run.
% Under that design a periodic rate can be chosen with knowledge of the
% condition it will meet, and the objection is fair. EXP11 removes that
% knowledge: one mission passes through Clean, Moderate, Stressed, Moderate
% and Clean again, the five fixed periodic baselines are never told which
% regime is active, and their rates cannot move.
%
% WHAT EXP11 DOES NOT DO
%
% It does not modify Causal-v3, the controller, the 6-DOF plant, or any
% threshold, cooldown, max-silence bound or adaptive-scale parameter. Every
% one of those is the frozen EXP10 NOMINAL value, and
% tests/test_exp11_regime_semantics.m asserts that a regime change reaches
% the channel and nothing else. It also does not move the simulation-v1.0
% tag: EXP11 is separate supplementary evidence, not a revision of the
% frozen campaign.
%
% PRE-REGISTERED, BEFORE ANY RUN
%
%   Scenario     N = 5, ring2, 6-DOF followers at inner ratio 10, original
%                controller, outer dt 0.02 s, inner dt 0.002 s, T = 83 s
%   Timeline     0-23 Clean, 23-38 Moderate, 38-53 Stressed,
%                53-68 Moderate, 68-83 Clean; 0-8 s is warm-up and enters
%                no metric
%   Methods      P5, P10, P12.5, P20, P25 (rates fixed for all 83 s),
%                State-event, Causal-v3, plus Oracle-periodic as a
%                NON-CAUSAL / REGIME-AWARE REFERENCE that is never a gate
%   Seeds        26000001:26000050, holdout, asserted disjoint from
%                EXP01-EXP10 before anything runs
%   Statistics   paired over seeds, 95 % CI, nPairs reported
%
%   H1   Causal-v3 adapts within a run in BOTH directions: the four
%        adjacent segment DATA-rate differences have CIs excluding zero
%        with signs +, +, -, -
%   H2a  RMSE(Causal - P10) < 0, supported only if the upper CI < 0
%   H2b  Total_w025(Causal - P20) < 0, supported only if the upper CI < 0
%   H3   Causal-v3 classified NON-DOMINATED or DOMINATED against the
%        fixed-periodic frontier by the EXP07C 1 % rule. It is NOT
%        pre-registered that Causal must win.
%   H4   Oracle gap, reported with paired CIs, no gate in either direction
%
% If H2 or H3 come out against the method, the negative result stands as
% it is. Nothing here is re-tuned after seeing a number.
%
% ============================================================

clear; close all; clc;

startup;

expRun = startExperiment('exp11_dynamic_network', ...
    'Within-run network switching; fixed-periodic challenge.');


%% ============================================================
% Configuration
% ============================================================

regime = networkRegimeSchedule('exp11');

exp11Seeds = 26000001:26000050;

% Debug hook. Section 11 of the pre-registration requires three seeds to
% be run first and STOPS on a technical or infrastructure bug rather than
% on a bad scientific result. Set this in the base workspace before
% running to take that path; it changes nothing else.
if evalin('base', 'exist(''exp11SmokeSeeds'',''var'')')
    exp11Seeds = evalin('base', 'exp11SmokeSeeds');
    fprintf('\n*** DEBUG RUN: %d seed(s) ***\n', numel(exp11Seeds));
end

numSeeds = numel(exp11Seeds);

M = exp11Methods();

methodIds = {M.id};
nMethod   = numel(methodIds);

nSeg = numel(regime.segStart);

% Four switches x (three post-switch windows + remainder).
nTrans = numel(regime.switchTimes) * 4;

nRun = numSeeds * nMethod;

% Index of the methods the hypotheses name, resolved once so a rename
% cannot silently point a hypothesis at the wrong arm.
iCausal = find(strcmp(methodIds, 'Causal'),         1);
iEvent  = find(strcmp(methodIds, 'StateEvent'),     1);
iP10    = find(strcmp(methodIds, 'P10'),            1);
iP20    = find(strcmp(methodIds, 'P20'),            1);
iOracle = find(strcmp(methodIds, 'OraclePeriodic'), 1);

iFixed = find(strcmp({M.family}, 'periodic'));

assert(~isempty(iCausal) && ~isempty(iEvent) && ~isempty(iP10) ...
    && ~isempty(iP20) && ~isempty(iOracle) && numel(iFixed) == 5, ...
    'exp11: the method list does not contain the pre-registered arms.');

% EXP07C 1 % dominance rule, unchanged.
DOMINANCE_MARGIN = 0.99;

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP11  within-run network switching\n');
fprintf('============================================================\n');
fprintf('Scenario : N=5 ring2 6-DOF, T=%g s, outer dt=%g s\n', ...
    regime.tEnd, 0.02);
fprintf('Timeline : ');
for s = 1:numel(regime.tStart)
    if s < numel(regime.tStart)
        fprintf('%g-%g %s  ', regime.tStart(s), regime.tStart(s+1), ...
            regime.label{s});
    else
        fprintf('%g-%g %s\n', regime.tStart(s), regime.tEnd, regime.label{s});
    end
end
fprintf('Switches : %s\n', mat2str(regime.switchTimes));
fprintf('Metrics  : t in [%g, %g], five %g s segments\n', ...
    regime.evalStart, regime.tEnd, 15);
fprintf('Methods  : %s\n', strjoin(methodIds, ', '));
fprintf('Seeds    : %d holdout (%d..%d)\n', ...
    numSeeds, min(exp11Seeds), max(exp11Seeds));
fprintf('Runs     : %d\n', nRun);


%% ============================================================
% PRE-RUN ASSERTION - the seeds are a genuine holdout
%
% Runs before anything is simulated and raises rather than warns. EXP11
% must be disjoint from EXP10 as well as from development: a seed whose
% realisation already shaped the frozen claims is not fresh evidence
% about them.
% ============================================================

seedReport = assertExp11Seeds(exp11Seeds);


%% ============================================================
% Storage  [seed x method], and [seed x method x segment/window]
% ============================================================

sz = [numSeeds nMethod];

RMSE     = nan(sz);
MAXERR   = nan(sz);
MINSEP   = nan(sz);
SAFEFAIL = false(sz);
DIVERGED = false(sz);

NDATA  = nan(sz);
NACK   = nan(sz);
NBCAST = nan(sz);
MISDUR = nan(sz);

DATAHZ = nan(sz);
ACKHZ  = nan(sz);

TOTW010 = nan(sz);
TOTW025 = nan(sz);
TOTW050 = nan(sz);
AIRTIME = nan(sz);
BCASTHZ = nan(sz);

TRUEAOI = nan(sz);
ESTAOI  = nan(sz);

FWDHASH  = nan(sz);
FWDHASHX = nan(sz);
ACKHASH  = nan(sz);
ACKHASHX = nan(sz);
PHASEHASH = nan(sz);

INVARIANTS = nan(sz);
DROPCOUNT  = nan(sz);
NPERIODSW  = nan(sz);

SEEDVALUE = nan(sz);

SEG_RMSE   = nan(numSeeds, nMethod, nSeg);
SEG_DATAHZ = nan(numSeeds, nMethod, nSeg);
SEG_ACKHZ  = nan(numSeeds, nMethod, nSeg);
SEG_W025   = nan(numSeeds, nMethod, nSeg);
SEG_AOI    = nan(numSeeds, nMethod, nSeg);
SEG_MINSEP = nan(numSeeds, nMethod, nSeg);

TR_DATAHZ = nan(numSeeds, nMethod, nTrans);
TR_DELTAHZ = nan(numSeeds, nMethod, nTrans);
TR_DELTAAOI = nan(numSeeds, nMethod, nTrans);
TR_DELTARMSE = nan(numSeeds, nMethod, nTrans);

% Oracle switch audit: recorded per run so the gate checks the runs that
% happened rather than the schedule that was intended.
ORACLE_SW_OK = true(sz);

transLabel = cell(nTrans,1);
segLabel   = regime.segName;


%% ============================================================
% Main sweep
%
% N = 5 throughout, so the memory pressure that capped EXP10's workers at
% larger N does not arise; the cap is the EXP10 N = 5 value.
% ============================================================

wCap = 16;

ensureParallelPool(wCap);

tSweep = tic;

for iM = 1:nMethod

    methodId = methodIds{iM};

    fprintf('\n--- [%d/%d] %-16s ', iM, nMethod, methodId);

    rmseS = nan(numSeeds,1);
    maxeS = nan(numSeeds,1);
    msepS = nan(numSeeds,1);
    safeS = false(numSeeds,1);
    divS  = false(numSeeds,1);

    ndS = nan(numSeeds,1);
    naS = nan(numSeeds,1);
    nbS = nan(numSeeds,1);
    duS = nan(numSeeds,1);

    dhzS = nan(numSeeds,1);
    ahzS = nan(numSeeds,1);

    w010S = nan(numSeeds,1);
    w025S = nan(numSeeds,1);
    w050S = nan(numSeeds,1);
    airS  = nan(numSeeds,1);
    bhzS  = nan(numSeeds,1);

    taoiS = nan(numSeeds,1);
    eaoiS = nan(numSeeds,1);

    fwdHS = nan(numSeeds,1);
    fwdXS = nan(numSeeds,1);
    ackHS = nan(numSeeds,1);
    ackXS = nan(numSeeds,1);
    phHS  = nan(numSeeds,1);

    invS = nan(numSeeds,1);
    drpS = nan(numSeeds,1);
    npsS = nan(numSeeds,1);
    oswS = true(numSeeds,1);

    sdS = nan(numSeeds,1);

    segRmseS = nan(numSeeds, nSeg);
    segDataS = nan(numSeeds, nSeg);
    segAckS  = nan(numSeeds, nSeg);
    segW025S = nan(numSeeds, nSeg);
    segAoIS  = nan(numSeeds, nSeg);
    segSepS  = nan(numSeeds, nSeg);

    trDataS  = nan(numSeeds, nTrans);
    trDHzS   = nan(numSeeds, nTrans);
    trDAoIS  = nan(numSeeds, nTrans);
    trDRmseS = nan(numSeeds, nTrans);

    trLabelS = cell(numSeeds, 1);

    switchTimesRef = regime.switchTimes;

    parfor (s = 1:numSeeds, wCap)

        seedValue = exp11Seeds(s);

        cfg = applyExp11Config(seedValue, regime);

        sdS(s) = seedValue;

        out = simSwarmExp11(cfg, methodId);

        R = exp11RunMetrics(out, cfg, regime);

        rmseS(s) = R.mission.rmse;
        maxeS(s) = R.mission.maxError;
        msepS(s) = R.mission.minSep;
        safeS(s) = R.mission.safeFail;
        divS(s)  = R.diverged;

        ndS(s) = R.mission.nData;
        naS(s) = R.mission.nAck;
        nbS(s) = R.mission.nBcast;
        duS(s) = R.mission.duration;

        dhzS(s) = R.mission.dataHz;
        ahzS(s) = R.mission.ackHz;

        w010S(s) = R.mission.total_w010;
        w025S(s) = R.mission.total_w025;
        w050S(s) = R.mission.total_w050;
        airS(s)  = R.mission.airtime;
        bhzS(s)  = R.mission.broadcast;

        taoiS(s) = R.mission.trueAoI;
        eaoiS(s) = R.mission.estAoI;

        fwdHS(s) = R.traceHash;
        fwdXS(s) = R.traceHashExact;
        ackHS(s) = R.ackTraceHash;
        ackXS(s) = R.ackTraceHashExact;
        phHS(s)  = R.phaseHash;

        invS(s) = R.invariantViolations;
        drpS(s) = R.dropCount;
        npsS(s) = numel(R.periodSwitchTimes);

        % Every recorded period switch must sit on a pre-registered
        % boundary. For the five fixed methods the list is empty and this
        % is trivially true, which is itself the evidence they did not
        % adapt.
        if isempty(R.periodSwitchTimes)
            oswS(s) = true;
        else
            oswS(s) = all(ismember( ...
                round(R.periodSwitchTimes*1e6)/1e6, switchTimesRef));
        end

        segRmseS(s,:) = [R.segment.rmse];
        segDataS(s,:) = [R.segment.dataHz];
        segAckS(s,:)  = [R.segment.ackHz];
        segW025S(s,:) = [R.segment.total_w025];
        segAoIS(s,:)  = [R.segment.aoi];
        segSepS(s,:)  = [R.segment.minSep];

        trDataS(s,:)  = [R.transition.dataHz];
        trDHzS(s,:)   = [R.transition.deltaHz];
        trDAoIS(s,:)  = [R.transition.deltaAoI];
        trDRmseS(s,:) = [R.transition.deltaRmse];

        lbl = cell(1, nTrans);
        for r = 1:nTrans
            lbl{r} = sprintf('t%g:%s->%s:%s', ...
                R.transition(r).switchTime, ...
                R.transition(r).fromRegime, ...
                R.transition(r).toRegime, ...
                R.transition(r).window);
        end
        trLabelS{s} = lbl;

        fprintf('.');

    end

    RMSE(:,iM)     = rmseS;
    MAXERR(:,iM)   = maxeS;
    MINSEP(:,iM)   = msepS;
    SAFEFAIL(:,iM) = safeS;
    DIVERGED(:,iM) = divS;

    NDATA(:,iM)  = ndS;
    NACK(:,iM)   = naS;
    NBCAST(:,iM) = nbS;
    MISDUR(:,iM) = duS;

    DATAHZ(:,iM) = dhzS;
    ACKHZ(:,iM)  = ahzS;

    TOTW010(:,iM) = w010S;
    TOTW025(:,iM) = w025S;
    TOTW050(:,iM) = w050S;
    AIRTIME(:,iM) = airS;
    BCASTHZ(:,iM) = bhzS;

    TRUEAOI(:,iM) = taoiS;
    ESTAOI(:,iM)  = eaoiS;

    FWDHASH(:,iM)  = fwdHS;
    FWDHASHX(:,iM) = fwdXS;
    ACKHASH(:,iM)  = ackHS;
    ACKHASHX(:,iM) = ackXS;
    PHASEHASH(:,iM) = phHS;

    INVARIANTS(:,iM) = invS;
    DROPCOUNT(:,iM)  = drpS;
    NPERIODSW(:,iM)  = npsS;
    ORACLE_SW_OK(:,iM) = oswS;

    SEEDVALUE(:,iM) = sdS;

    SEG_RMSE(:,iM,:)   = segRmseS;
    SEG_DATAHZ(:,iM,:) = segDataS;
    SEG_ACKHZ(:,iM,:)  = segAckS;
    SEG_W025(:,iM,:)   = segW025S;
    SEG_AOI(:,iM,:)    = segAoIS;
    SEG_MINSEP(:,iM,:) = segSepS;

    TR_DATAHZ(:,iM,:)    = trDataS;
    TR_DELTAHZ(:,iM,:)   = trDHzS;
    TR_DELTAAOI(:,iM,:)  = trDAoIS;
    TR_DELTARMSE(:,iM,:) = trDRmseS;

    if isempty(transLabel{1}) && ~isempty(trLabelS{1})
        transLabel = trLabelS{1}(:);
    end

    fprintf('  done (%.1f min elapsed)', toc(tSweep)/60);

end

sweepMinutes = toc(tSweep)/60;

fprintf('\n\nSweep complete: %d runs in %.1f min\n', nRun, sweepMinutes);


%% ============================================================
% GATES
%
% Section 9 of the pre-registration. These are infrastructure gates: they
% ask whether the experiment is a valid measurement, not whether the
% result is favourable. A gate failure means STOP; an unfavourable
% hypothesis outcome does not.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('GATES\n');
fprintf('============================================================\n\n');

gateNames = {};
gatePass  = [];
gateDetail = {};

% --- G1: causal invariant violations ---
nInv = sum(INVARIANTS(:), 'omitnan');
gateNames{end+1} = 'G1 zero causal invariant violations';
gatePass(end+1)  = (nInv == 0);
gateDetail{end+1} = sprintf('%d violation(s) across %d runs', nInv, nRun);

% --- G2: no NaN / divergence ---
nDiv = nnz(DIVERGED);
nBadRmse = nnz(~isfinite(RMSE) & ~DIVERGED);
gateNames{end+1} = 'G2 no divergence and no unexplained NaN';
gatePass(end+1)  = (nDiv == 0) && (nBadRmse == 0);
gateDetail{end+1} = sprintf('%d diverged, %d non-finite RMSE outside divergence', ...
    nDiv, nBadRmse);

% --- G3: trace hashes match across methods at each seed ---
% Every method at one seed must meet the same forward and reverse
% realisation. This is what makes the paired differences paired.
fwdOk = true;
ackOk = true;

for s = 1:numSeeds
    hv = FWDHASHX(s,:);
    if numel(unique(hv(isfinite(hv)))) > 1
        fwdOk = false;
    end
    av = ACKHASHX(s,:);
    if numel(unique(av(isfinite(av)))) > 1
        ackOk = false;
    end
end

gateNames{end+1} = 'G3 one channel realization per seed, across all methods';
gatePass(end+1)  = fwdOk && ackOk;
gateDetail{end+1} = sprintf('forward %s, reverse %s', ...
    localYesNo(fwdOk), localYesNo(ackOk));

% --- G4: all seeds present, none duplicated ---
seedsOk = true;
for iM = 1:nMethod
    sv = SEEDVALUE(:,iM);
    if numel(unique(sv)) ~= numSeeds || any(~ismember(sv, exp11Seeds))
        seedsOk = false;
    end
end
gateNames{end+1} = 'G4 every seed present exactly once for every method';
gatePass(end+1)  = seedsOk;
gateDetail{end+1} = sprintf('%d seeds x %d methods', numSeeds, nMethod);

% --- G5: fixed periodic rates never changed ---
fixedSwitches = sum(sum(NPERIODSW(:, iFixed)));
gateNames{end+1} = 'G5 fixed periodic rates unchanged across all switches';
gatePass(end+1)  = (fixedSwitches == 0);
gateDetail{end+1} = sprintf('%d rate change(s) recorded across the five fixed methods', ...
    fixedSwitches);

% --- G6: oracle switched only at pre-registered boundaries ---
oracleSw = NPERIODSW(:, iOracle);
oracleOk = all(ORACLE_SW_OK(:)) && all(oracleSw == numel(regime.switchTimes));
gateNames{end+1} = 'G6 oracle switched only at the four registered boundaries';
gatePass(end+1)  = oracleOk;
gateDetail{end+1} = sprintf('%s switches per run, all on a boundary: %s', ...
    mat2str(unique(oracleSw)'), localYesNo(all(ORACLE_SW_OK(:))));

% --- G7: no method except the oracle received a regime label ---
% Asserted structurally by tests/test_exp11_regime_semantics.m, which is
% re-run here so the gate list is self-contained rather than a reference
% to a test someone may not have run.
regimeGuardPass = true;
regimeGuardErr = '';
try
    runScriptIsolated('test_exp11_regime_semantics');
catch ME
    regimeGuardPass = false;
    regimeGuardErr = ME.message;
end
gateNames{end+1} = 'G7 regime reaches the channel only (negative control)';
gatePass(end+1)  = regimeGuardPass;
if regimeGuardPass
    gateDetail{end+1} = 'test_exp11_regime_semantics PASS';
else
    gateDetail{end+1} = sprintf('test_exp11_regime_semantics FAIL: %s', ...
        regimeGuardErr);
end

for g = 1:numel(gateNames)
    if gatePass(g)
        fprintf('  [PASS ] %-58s %s\n', gateNames{g}, gateDetail{g});
    else
        fprintf('  [FAIL ] %-58s %s\n', gateNames{g}, gateDetail{g});
    end
end

allGatesPass = all(logical(gatePass));

fprintf('\n  Gates: %d of %d pass\n', nnz(gatePass), numel(gatePass));


%% ============================================================
% H1 - within-run adaptivity, both directions
%
% Four adjacent segment differences in DATA rate, each a paired CI over
% seeds. The target signs are +, +, -, -: the rate rises into degradation
% and comes back down out of it. The two Clean and the two Moderate
% segments are never merged, so the return leg is measured rather than
% assumed. Clean_1 == Clean_2 is NOT required: recovery need not be exact.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('H1  within-run adaptivity  (DATA rate, adjacent segments)\n');
fprintf('============================================================\n\n');

adjPairs = [2 1; 3 2; 4 3; 5 4];
adjSign  = [+1; +1; -1; -1];

h1 = struct([]);
row = 0;

reportMethods = [iCausal, iEvent, iP10, iP20, iOracle];

for mm = reportMethods

    fprintf('  %s\n', methodIds{mm});

    for a = 1:size(adjPairs,1)

        hi = adjPairs(a,1);
        lo = adjPairs(a,2);

        S = pairedCI(SEG_DATAHZ(:,mm,hi), SEG_DATAHZ(:,mm,lo), numSeeds);

        if adjSign(a) > 0
            supported = S.lo > 0;
            wanted = '> 0';
        else
            supported = S.hi < 0;
            wanted = '< 0';
        end

        row = row + 1;
        h1(row).method    = methodIds{mm};
        h1(row).diff      = sprintf('%s - %s', segLabel{hi}, segLabel{lo});
        h1(row).wanted    = wanted;
        h1(row).meanD     = S.meanD;
        h1(row).lo        = S.lo;
        h1(row).hi        = S.hi;
        h1(row).nPairs    = S.nPairs;
        h1(row).complete  = S.complete;
        h1(row).supported = supported;

        fprintf('    %-24s %s  mean %+8.3f  CI [%+8.3f, %+8.3f]  n=%2d  %s\n', ...
            h1(row).diff, wanted, S.meanD, S.lo, S.hi, S.nPairs, ...
            localSupport(supported));

    end

    fprintf('\n');

end

h1Causal = h1(strcmp({h1.method}, 'Causal'));
h1Supported = all([h1Causal.supported]) && all([h1Causal.complete]);

fprintf('  H1 verdict for Causal-v3: %s\n', localSupport(h1Supported));

if ~all([h1Causal.complete])
    fprintf('  NOTE: at least one CI is incomplete; the claim is downgraded.\n');
end


%% ============================================================
% H2 - against the two fixed rates the frozen results named
%
% H2a  RMSE(Causal - P10)        < 0
% H2b  Total_w025(Causal - P20)  < 0
%
% Supported only if the UPPER CI bound is below zero. If one fails, the
% experiment is not modified and the failure is reported.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('H2  Causal-v3 against the fixed rates\n');
fprintf('============================================================\n\n');

S2a = pairedCI(RMSE(:,iCausal),    RMSE(:,iP10),    numSeeds);
S2b = pairedCI(TOTW025(:,iCausal), TOTW025(:,iP20), numSeeds);

h2aSupported = S2a.hi < 0;
h2bSupported = S2b.hi < 0;

fprintf('  H2a  RMSE(Causal - P10)       mean %+9.5f  CI [%+9.5f, %+9.5f]  n=%d  %s\n', ...
    S2a.meanD, S2a.lo, S2a.hi, S2a.nPairs, localSupport(h2aSupported));
fprintf('  H2b  Tot_w025(Causal - P20)   mean %+9.4f  CI [%+9.4f, %+9.4f]  n=%d  %s\n', ...
    S2b.meanD, S2b.lo, S2b.hi, S2b.nPairs, localSupport(h2bSupported));

fprintf('\n  Reference means over %d seeds:\n', numSeeds);
fprintf('    RMSE      Causal %.5f   P10 %.5f   P20 %.5f\n', ...
    mean(RMSE(:,iCausal),'omitnan'), mean(RMSE(:,iP10),'omitnan'), ...
    mean(RMSE(:,iP20),'omitnan'));
fprintf('    Tot_w025  Causal %.3f   P10 %.3f   P20 %.3f\n', ...
    mean(TOTW025(:,iCausal),'omitnan'), mean(TOTW025(:,iP10),'omitnan'), ...
    mean(TOTW025(:,iP20),'omitnan'));

if ~S2a.complete || ~S2b.complete
    fprintf('\n  NOTE: an incomplete pair count; the affected claim is downgraded.\n');
end


%% ============================================================
% H3 - the fixed-periodic Pareto frontier
%
% RMSE against Total_w025, seed-mean per method, over the five fixed rates.
% Causal-v3 is classified by the same 1 % dominance rule EXP07C used: it is
% DOMINATED if some fixed rate achieves RMSE <= 0.99 x its RMSE AND cost
% <= 0.99 x its cost. It was never pre-registered that Causal must be
% non-dominated.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('H3  fixed-periodic Pareto frontier  (RMSE vs Total_w025)\n');
fprintf('============================================================\n\n');

meanRmse = mean(RMSE, 1, 'omitnan');
meanCost = mean(TOTW025, 1, 'omitnan');

fprintf('  %-16s %10s %12s\n', 'method', 'RMSE', 'Tot_w025');
fprintf('  %-16s %10s %12s\n', repmat('-',1,16), repmat('-',1,10), ...
    repmat('-',1,12));

for iM = 1:nMethod
    tag = '';
    if strcmp(M(iM).family, 'oracle')
        tag = '   (non-causal / regime-aware reference)';
    end
    fprintf('  %-16s %10.5f %12.3f%s\n', methodIds{iM}, ...
        meanRmse(iM), meanCost(iM), tag);
end

% Dominance of Causal by any FIXED periodic rate.
dominators = {};

for k = iFixed
    if meanRmse(k) <= DOMINANCE_MARGIN*meanRmse(iCausal) && ...
            meanCost(k) <= DOMINANCE_MARGIN*meanCost(iCausal)
        dominators{end+1} = methodIds{k};   %#ok<AGROW>
    end
end

causalDominated = ~isempty(dominators);

fprintf('\n  Causal-v3 vs the fixed-periodic frontier: %s\n', ...
    localDominance(causalDominated));

if causalDominated
    fprintf('  Dominated by: %s\n', strjoin(dominators, ', '));
end

% The frontier itself, for the report: which fixed rates are non-dominated
% within their own family.
fixedNonDom = {};

for k = iFixed
    dominated = false;
    for k2 = iFixed
        if k2 == k
            continue;
        end
        if meanRmse(k2) <= DOMINANCE_MARGIN*meanRmse(k) && ...
                meanCost(k2) <= DOMINANCE_MARGIN*meanCost(k)
            dominated = true;
        end
    end
    if ~dominated
        fixedNonDom{end+1} = methodIds{k};   %#ok<AGROW>
    end
end

fprintf('  Non-dominated fixed rates: %s\n', strjoin(fixedNonDom, ', '));


%% ============================================================
% H4 - the oracle gap
%
% Reported with paired CIs and NO gate in either direction. Oracle-periodic
% is a NON-CAUSAL / REGIME-AWARE REFERENCE: it is handed the regime and the
% switch times, which no deployable policy has. It is an
% information-efficiency reference for rate adaptation, not an accuracy
% bound and not a performance upper bound - a rate chosen per regime is not
% optimal even within the periodic family. If the oracle is better, that
% stands as reported.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('H4  gap to Oracle-periodic  (non-causal reference, no gate)\n');
fprintf('============================================================\n\n');

S4r = pairedCI(RMSE(:,iCausal),    RMSE(:,iOracle),    numSeeds);
S4c = pairedCI(TOTW025(:,iCausal), TOTW025(:,iOracle), numSeeds);

fprintf('  RMSE(Causal - Oracle)      mean %+9.5f  CI [%+9.5f, %+9.5f]  n=%d\n', ...
    S4r.meanD, S4r.lo, S4r.hi, S4r.nPairs);
fprintf('  Tot_w025(Causal - Oracle)  mean %+9.4f  CI [%+9.4f, %+9.4f]  n=%d\n', ...
    S4c.meanD, S4c.lo, S4c.hi, S4c.nPairs);

fprintf('\n  Oracle schedule: Clean->P5, Moderate->P10, Stressed->P20,\n');
fprintf('  switching at %s s. Pre-registered before any run.\n', ...
    mat2str(regime.switchTimes));


%% ============================================================
% Five-segment table
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('FIVE-SEGMENT TABLE  (seed means, n=%d)\n', numSeeds);
fprintf('============================================================\n');

for iM = 1:nMethod

    fprintf('\n  %s\n', methodIds{iM});
    fprintf('    %-11s %-9s %9s %9s %9s %10s %9s %8s\n', ...
        'segment', 'regime', 'RMSE', 'DATA Hz', 'ACK Hz', 'Tot_w025', ...
        'AoI', 'minSep');

    for s = 1:nSeg
        fprintf('    %-11s %-9s %9.5f %9.2f %9.2f %10.2f %9.4f %8.3f\n', ...
            segLabel{s}, regime.label{s}, ...
            mean(SEG_RMSE(:,iM,s),'omitnan'), ...
            mean(SEG_DATAHZ(:,iM,s),'omitnan'), ...
            mean(SEG_ACKHZ(:,iM,s),'omitnan'), ...
            mean(SEG_W025(:,iM,s),'omitnan'), ...
            mean(SEG_AOI(:,iM,s),'omitnan'), ...
            mean(SEG_MINSEP(:,iM,s),'omitnan'));
    end

end


%% ============================================================
% Transition diagnostics
%
% Descriptive only. No response-time threshold is defined, because none was
% pre-registered; inventing one now would turn a diagnostic into a claim.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('TRANSITION DIAGNOSTICS  (seed means, n=%d)\n', numSeeds);
fprintf('============================================================\n');

for mm = [iCausal, iEvent, iP20, iOracle]

    fprintf('\n  %s\n', methodIds{mm});
    fprintf('    %-34s %9s %9s %10s %10s\n', ...
        'switch / window', 'DATA Hz', 'dHz', 'dAoI', 'dRMSE');

    for r = 1:nTrans
        fprintf('    %-34s %9.2f %+9.2f %+10.4f %+10.4f\n', ...
            transLabel{r}, ...
            mean(TR_DATAHZ(:,mm,r),'omitnan'), ...
            mean(TR_DELTAHZ(:,mm,r),'omitnan'), ...
            mean(TR_DELTAAOI(:,mm,r),'omitnan'), ...
            mean(TR_DELTARMSE(:,mm,r),'omitnan'));
    end

end


%% ============================================================
% Safety
%
% Reported as a count over the full seed block, not as a t interval: a
% safety-failure rate is a proportion, and forcing it through a paired CI
% would misstate its distribution.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SAFETY  (min pairwise separation < 0.25 m on t in [8, 83])\n');
fprintf('============================================================\n\n');

fprintf('  %-16s %10s %12s %12s\n', 'method', 'failures', 'minSep mean', 'minSep worst');
for iM = 1:nMethod
    fprintf('  %-16s %6d/%-3d %12.3f %12.3f\n', methodIds{iM}, ...
        nnz(SAFEFAIL(:,iM)), numSeeds, ...
        mean(MINSEP(:,iM),'omitnan'), min(MINSEP(:,iM)));
end


%% ============================================================
% Invariant counters
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('COUNTERS\n');
fprintf('============================================================\n\n');

fprintf('  %-16s %12s %12s %12s %12s\n', ...
    'method', 'invariants', 'drops', 'rate changes', 'diverged');
for iM = 1:nMethod
    fprintf('  %-16s %12d %12.0f %12d %12d\n', methodIds{iM}, ...
        sum(INVARIANTS(:,iM),'omitnan'), ...
        sum(DROPCOUNT(:,iM),'omitnan'), ...
        sum(NPERIODSW(:,iM),'omitnan'), ...
        nnz(DIVERGED(:,iM)));
end


%% ============================================================
% Tidy dataset
% ============================================================

nRow = numSeeds * nMethod;

mIdxCol = repmat(1:nMethod, numSeeds, 1);

T = table();

T.seed   = SEEDVALUE(:);
T.method = methodIds(mIdxCol(:))';
T.family = {M(mIdxCol(:)).family}';

T.RMSE     = RMSE(:);
T.MAXERR   = MAXERR(:);
T.MINSEP   = MINSEP(:);
T.SAFEFAIL = double(SAFEFAIL(:));
T.DIVERGED = double(DIVERGED(:));

T.NDATA  = NDATA(:);
T.NACK   = NACK(:);
T.NBCAST = NBCAST(:);
T.MISDUR = MISDUR(:);

T.DATAHZ = DATAHZ(:);
T.ACKHZ  = ACKHZ(:);

T.TOTW010 = TOTW010(:);
T.TOTW025 = TOTW025(:);
T.TOTW050 = TOTW050(:);
T.AIRTIME = AIRTIME(:);
T.BCASTHZ = BCASTHZ(:);

T.TRUEAOI = TRUEAOI(:);
T.ESTAOI  = ESTAOI(:);

for s = 1:nSeg
    T.(sprintf('SEG%d_RMSE',   s)) = reshape(SEG_RMSE(:,:,s),   nRow, 1);
    T.(sprintf('SEG%d_DATAHZ', s)) = reshape(SEG_DATAHZ(:,:,s), nRow, 1);
    T.(sprintf('SEG%d_ACKHZ',  s)) = reshape(SEG_ACKHZ(:,:,s),  nRow, 1);
    T.(sprintf('SEG%d_W025',   s)) = reshape(SEG_W025(:,:,s),   nRow, 1);
    T.(sprintf('SEG%d_AOI',    s)) = reshape(SEG_AOI(:,:,s),    nRow, 1);
    T.(sprintf('SEG%d_MINSEP', s)) = reshape(SEG_MINSEP(:,:,s), nRow, 1);
end

for r = 1:nTrans
    T.(sprintf('TR%02d_DATAHZ',    r)) = reshape(TR_DATAHZ(:,:,r),    nRow, 1);
    T.(sprintf('TR%02d_DELTAHZ',   r)) = reshape(TR_DELTAHZ(:,:,r),   nRow, 1);
    T.(sprintf('TR%02d_DELTAAOI',  r)) = reshape(TR_DELTAAOI(:,:,r),  nRow, 1);
    T.(sprintf('TR%02d_DELTARMSE', r)) = reshape(TR_DELTARMSE(:,:,r), nRow, 1);
end

T.FWDHASH   = FWDHASH(:);
T.FWDHASHX  = FWDHASHX(:);
T.ACKHASH   = ACKHASH(:);
T.ACKHASHX  = ACKHASHX(:);
T.PHASEHASH = PHASEHASH(:);

T.INVARIANTS = INVARIANTS(:);
T.DROPCOUNT  = DROPCOUNT(:);
T.NPERIODSW  = NPERIODSW(:);

writetable(T, fullfile(expRun.dir, 'tidy.csv'));

% The transition-window key, so the TRxx columns are readable without
% re-deriving the window order.
Tkey = table((1:nTrans)', transLabel, ...
    'VariableNames', {'index','window'});
writetable(Tkey, fullfile(expRun.dir, 'transition_key.csv'));

Tseg = table((1:nSeg)', segLabel(:), regime.label(:), ...
    regime.segStart(:), regime.segEnd(:), ...
    'VariableNames', {'index','name','regime','tStart','tEnd'});
writetable(Tseg, fullfile(expRun.dir, 'segment_key.csv'));

fprintf('\nWrote %d rows to %s\n', height(T), ...
    fullfile(expRun.dir, 'tidy.csv'));


%% ============================================================
% Figures
% ============================================================

% DATA rate per segment, one line per method: the picture the whole
% experiment is about.
figure('Name','EXP11 segment DATA rate','Position',[100 100 900 520]);
hold on; grid on;

segX = 1:nSeg;

for iM = 1:nMethod
    y = squeeze(mean(SEG_DATAHZ(:,iM,:), 1, 'omitnan'));
    if strcmp(M(iM).family, 'periodic')
        sty = '--';
    elseif strcmp(M(iM).family, 'oracle')
        sty = ':';
    else
        sty = '-';
    end
    plot(segX, y, sty, 'LineWidth', 1.8, 'Marker', 'o', ...
        'DisplayName', methodIds{iM});
end

set(gca, 'XTick', segX, 'XTickLabel', segLabel);
ylabel('swarm DATA rate [Hz]');
title('EXP11  DATA rate by regime segment (seed means)');
legend('Location','eastoutside');

% RMSE per segment.
figure('Name','EXP11 segment RMSE','Position',[100 100 900 520]);
hold on; grid on;

for iM = 1:nMethod
    y = squeeze(mean(SEG_RMSE(:,iM,:), 1, 'omitnan'));
    if strcmp(M(iM).family, 'periodic')
        sty = '--';
    elseif strcmp(M(iM).family, 'oracle')
        sty = ':';
    else
        sty = '-';
    end
    plot(segX, y, sty, 'LineWidth', 1.8, 'Marker', 'o', ...
        'DisplayName', methodIds{iM});
end

set(gca, 'XTick', segX, 'XTickLabel', segLabel);
ylabel('formation RMSE [m]');
title('EXP11  formation RMSE by regime segment (seed means)');
legend('Location','eastoutside');

% Pareto: fixed-periodic frontier with Causal, State-event and the oracle.
figure('Name','EXP11 Pareto','Position',[100 100 760 560]);
hold on; grid on;

plot(meanCost(iFixed), meanRmse(iFixed), '--o', 'LineWidth', 1.6, ...
    'Color', [0.35 0.35 0.35], 'DisplayName', 'fixed periodic');

for mm = [iCausal, iEvent, iOracle]
    plot(meanCost(mm), meanRmse(mm), 'p', 'MarkerSize', 14, ...
        'LineWidth', 1.6, 'DisplayName', methodIds{mm});
end

for k = iFixed
    text(meanCost(k), meanRmse(k), ['  ' methodIds{k}], 'FontSize', 8);
end

xlabel('Total\_w025 [normalised packets/s]');
ylabel('formation RMSE [m]');
title('EXP11  RMSE vs communication cost, time-varying network');
legend('Location','best');


%% ============================================================
% Verdict
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP11 SUMMARY\n');
fprintf('============================================================\n\n');

fprintf('  Runs           : %d (%d seeds x %d methods) in %.1f min\n', ...
    nRun, numSeeds, nMethod, sweepMinutes);
fprintf('  Gates          : %d of %d PASS\n', nnz(gatePass), numel(gatePass));
fprintf('  H1 adaptivity  : %s\n', localSupport(h1Supported));
fprintf('  H2a RMSE<P10   : %s  (mean %+.5f, CI [%+.5f, %+.5f])\n', ...
    localSupport(h2aSupported), S2a.meanD, S2a.lo, S2a.hi);
fprintf('  H2b cost<P20   : %s  (mean %+.4f, CI [%+.4f, %+.4f])\n', ...
    localSupport(h2bSupported), S2b.meanD, S2b.lo, S2b.hi);
fprintf('  H3 Pareto      : %s\n', localDominance(causalDominated));
fprintf('  H4 oracle gap  : RMSE %+.5f, cost %+.4f (reported, no gate)\n', ...
    S4r.meanD, S4c.meanD);

if ~allGatesPass
    fprintf('\n  GATE FAILURE. The measurement is not valid; results above\n');
    fprintf('  are printed for diagnosis and must not be quoted.\n');
end

save(fullfile(expRun.dir, 'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function s = localYesNo(f)
if f
    s = 'yes';
else
    s = 'NO';
end
end


function s = localSupport(f)
if f
    s = 'SUPPORTED';
else
    s = 'NOT SUPPORTED';
end
end


function s = localDominance(f)
if f
    s = 'DOMINATED';
else
    s = 'NON-DOMINATED';
end
end
