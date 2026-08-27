%% EXP10B - Unified final matrix, dominance, and preserved limitations
%
% EXP10B RUNS NO SIMULATION. It reads the tidy dataset EXP10A produced and
% aggregates it. That is a pre-registration requirement, not an
% optimisation: generating a second stochastic dataset for the "unified
% matrix" would mean the headline table described a different realization
% than the paired confidence intervals, and the two could disagree without
% either being wrong.
%
% If tidy.csv is missing, this script stops. It does not fall back to
% running the sweep itself.
%
% WHAT IT PRODUCES
%
%   1  the unified matrix: every cell that was run, unfiltered, with
%      accuracy, safety, every cost model, freshness and provenance
%   2  dominance of Causal-v3 in each cell under each of five cost models
%   3  the Moderate non-dominated fraction, against the pre-registered
%      >= 75 % reference criterion at w = 0.25
%   4  the Stressed dominance characterisation, with NO superiority gate,
%      because EXP07C rejected that claim and the rejection stands
%   5  the adaptivity ordering on the nominal point
%   6  the Causal-versus-State-event statement, derived by a rule fixed
%      in advance rather than asserted
%   7  LOCKED LIMITATIONS - NOT RE-TESTED AWAY
%
% SAFETY IS NOT AGGREGATED THE SAME WAY EVERYWHERE, ON PURPOSE
%
% Each fault point keeps its SOURCE experiment's eligibility rule, per
% plan section 7:
%
%   LINK   EXP08B: the denominator is the seeds whose active graph stayed
%          connected. A seed whose graph fell apart is a connectivity
%          fact, not evidence about the method.
%   NODE   EXP08C: MATCHED NO-FAULT ELIGIBILITY. A seed counts only if
%          the same method, scenario and seed was already safe WITHOUT
%          the blackout. That is why the N20REF point exists; without it
%          the rule is unevaluable and the failure rate would blame a
%          pre-existing geometry problem on the communication fault.
%
% Binary safety numbers are reported as raw paired counts and rates over
% those denominators. They are deliberately NOT pushed through a t
% interval: a proportion over an eligibility-filtered denominator is not
% a mean of a continuous variable, and wrapping it in one would hide the
% denominator that the rule is about.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp10b_unified_matrix');


%% ============================================================
% Load the EXP10A dataset
% ============================================================

srcName = 'exp10a_final_validation';

srcRoot = fullfile(projectRoot(), 'results', srcName);

latestFile = fullfile(srcRoot, 'LATEST.txt');

if exist(latestFile,'file') ~= 2
    error('exp10b:noDataset', ...
        ['No EXP10A result directory found at %s. EXP10B aggregates the ' ...
         'EXP10A dataset and never generates one.'], srcRoot);
end

srcRunId = strtrim(fileread(latestFile));

srcDir = fullfile(srcRoot, srcRunId);

tidyFile = fullfile(srcDir, 'tidy.csv');

if exist(tidyFile,'file') ~= 2
    error('exp10b:noTidy', 'EXP10A run %s has no tidy.csv.', srcRunId);
end

T = readtable(tidyFile, 'TextType','char');

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP10B unified final matrix\n');
fprintf('============================================================\n\n');

fprintf('Source dataset : %s/%s\n', srcName, srcRunId);
fprintf('Rows           : %d\n', height(T));

srcMeta = fullfile(srcDir, 'meta.json');

if exist(srcMeta,'file') == 2
    m = jsondecode(fileread(srcMeta));
    fprintf('Source commit  : %s\n', m.gitCommit);
    fprintf('Source runtime : %s\n', m.elapsedText);
end


%% ============================================================
% Scope, re-derived from the frozen registry
% ============================================================

sc  = exp10Scenarios();
pts = exp10Points();

methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

IDX_P10    = 1;
IDX_P20    = 2;
IDX_EVENT  = 3;
IDX_CAUSAL = 4;

nMethod = numel(methodNames);

seedList = unique(T.seed);

numSeeds = numel(seedList);

fprintf('Seeds          : %d (%d..%d)\n', ...
    numSeeds, min(seedList), max(seedList));

if numSeeds ~= 50
    fprintf(2, ['\nWARNING: the dataset carries %d seeds, not the ' ...
        'pre-registered 50. Every claim below inherits that and must ' ...
        'be read as a %d-seed result.\n'], numSeeds, numSeeds);
end

% Cell list, in the same order EXP10A used.
cellPoint = [];
cellScen  = [];

for ip = 1:numel(pts)
    for q = 1:numel(pts(ip).scenarios)
        cellPoint(end+1) = ip;                      %#ok<AGROW>
        cellScen(end+1)  = pts(ip).scenarios(q);    %#ok<AGROW>
    end
end

nCell = numel(cellPoint);

cellLabel = cell(nCell,1);

for c = 1:nCell
    cellLabel{c} = sprintf('%s / %s', ...
        pts(cellPoint(c)).id, sc.names{cellScen(c)});
end

% EXP07C cost-model constants, unchanged.
COST_W = [0.10; 0.25; 0.50];

DOMINANCE_MARGIN = 0.99;    % the pre-registered 1 % rule

MODERATE_REFERENCE_FRACTION = 0.75;


%% ============================================================
% Row index per (cell, method, seed)
% ============================================================

rowOf = nan(numSeeds, nMethod, nCell);

for c = 1:nCell

    ptId = pts(cellPoint(c)).id;
    scNm = sc.names{cellScen(c)};

    inCell = strcmp(T.point, ptId) & strcmp(T.scenario, scNm);

    for iM = 1:nMethod

        inM = inCell & strcmp(T.method, methodNames{iM});

        idx = find(inM);

        [~, order] = sort(T.seed(idx));

        idx = idx(order);

        if numel(idx) ~= numSeeds
            error('exp10b:rowCount', ...
                '%s %s has %d rows, expected %d.', ...
                cellLabel{c}, methodNames{iM}, numel(idx), numSeeds);
        end

        rowOf(:,iM,c) = idx;

    end

end

get = @(col, c, iM) T.(col)(rowOf(:,iM,c));


%% ============================================================
% Independent re-verification of the realization hashes
%
% EXP10A checked its hashes against the registry while it ran. This is
% the same check made again from the persisted file by a separate script,
% which is what makes the dataset auditable rather than self-certified.
% ============================================================

hashProblems = 0;

for c = 1:nCell
    for s = 1:numSeeds

        % The EXACT hash column, not the locked one: the locked hash sums
        % millions of floats past 2^53 and therefore round-trips through
        % a CSV only to fifteen digits, so comparing it against anything
        % recomputed exactly reports a difference that is an artefact of
        % the file format, not of the realization.
        fwd = arrayfun(@(iM) T.FWDHASHX(rowOf(s,iM,c)), 1:nMethod);

        if numel(unique(fwd)) ~= 1
            hashProblems = hashProblems + 1;
        end

        ph = [T.PHASEHASH(rowOf(s,IDX_P10,c)), T.PHASEHASH(rowOf(s,IDX_P20,c))];

        if ph(1) ~= ph(2)
            hashProblems = hashProblems + 1;
        end

    end
end

fprintf('\nRe-verified realization hashes from the persisted file: ');

if hashProblems == 0
    fprintf('%d mismatch(es) -- OK\n', hashProblems);
else
    fprintf('%d MISMATCH(ES)\n', hashProblems);
end


%% ============================================================
% Per-cell aggregation
% ============================================================

dims = [nMethod nCell];

mRMSE   = nan(dims);  sRMSE  = nan(dims);
mMINSEP = nan(dims);
nDIV    = zeros(dims);
nEVAL   = zeros(dims);

mDATA   = nan(dims);  mACK  = nan(dims);  mBCAST = nan(dims);
mT010   = nan(dims);  mT025 = nan(dims);  mT050  = nan(dims);
mAIR    = nan(dims);  mBCST = nan(dims);

mAOI    = nan(dims);  mEAOI = nan(dims);

mSAT    = nan(dims);  mEFF  = nan(dims);
mESTERR = nan(dims);

nCONN   = zeros(dims);

% Safety, under the source experiment's eligibility rule.
safeElig   = zeros(dims);
safeUnsafe = zeros(dims);
safeRate   = nan(dims);
safeRule   = cell(dims);

for c = 1:nCell

    pt = pts(cellPoint(c));

    for iM = 1:nMethod

        div  = get('DIVERGED', c, iM) > 0;
        conn = get('CONNECTED', c, iM) > 0;

        nDIV(iM,c)  = nnz(div);
        nCONN(iM,c) = nnz(conn);

        keep = ~div;

        nEVAL(iM,c) = nnz(keep);

        % MATLAB forbids indexing the result of a function call, so
        % each column is pulled out once and then masked.
        vRMSE   = get('RMSE',   c, iM);
        vMINSEP = get('MINSEP', c, iM);
        vAOI    = get('TRUEAOI', c, iM);
        vEAOI   = get('ESTAOI',  c, iM);
        vSAT    = get('SATURATION', c, iM);
        vEFF    = get('EFFORT',     c, iM);
        vEST    = get('ESTERR',     c, iM);

        mRMSE(iM,c) = localMeanFinite(vRMSE(keep));
        sRMSE(iM,c) = localStdFinite( vRMSE(keep));

        mMINSEP(iM,c) = localMeanFinite(vMINSEP(keep));

        % Traffic and cost are averaged over EVERY seed, diverged
        % included. A diverged run still transmitted, and excluding its
        % traffic would understate the cost of exactly the conditions
        % where a method fails.
        mDATA(iM,c)  = localMeanFinite(get('DATARATE',  c, iM));
        mACK(iM,c)   = localMeanFinite(get('ACKRATE',   c, iM));
        mBCAST(iM,c) = localMeanFinite(get('BCASTRATE', c, iM));

        mT010(iM,c) = localMeanFinite(get('TOTAL010', c, iM));
        mT025(iM,c) = localMeanFinite(get('TOTAL025', c, iM));
        mT050(iM,c) = localMeanFinite(get('TOTAL050', c, iM));

        mAIR(iM,c)  = localMeanFinite(get('AIRTIME',       c, iM));
        mBCST(iM,c) = localMeanFinite(get('BROADCASTCOST', c, iM));

        mAOI(iM,c)  = localMeanFinite(vAOI(keep));
        mEAOI(iM,c) = localMeanFinite(vEAOI(keep));

        mSAT(iM,c)    = localMeanFinite(vSAT(keep));
        mEFF(iM,c)    = localMeanFinite(vEFF(keep));
        mESTERR(iM,c) = localMeanFinite(vEST(keep));

    end

end


%% ============================================================
% Safety, per the source experiment's eligibility rule
% ============================================================

cRefMod = localFindCell(cellPoint, cellScen, pts, 'N20REF', sc.MODERATE);
cRefStr = localFindCell(cellPoint, cellScen, pts, 'N20REF', sc.STRESSED);

for c = 1:nCell

    pt = pts(cellPoint(c));

    for iM = 1:nMethod

        unsafe = get('SAFEFAIL', c, iM) > 0;
        conn   = get('CONNECTED', c, iM) > 0;

        switch lower(pt.kind)

            case 'link'

                % EXP08B: the denominator is the connected seeds.
                elig = conn;
                safeRule{iM,c} = 'EXP08B connected-seed denominator';

            case 'node'

                % EXP08C: matched no-fault eligibility. The reference is
                % the same method, scenario and seed at the N20REF
                % point, which is why that point is in the matrix.
                if cellScen(c) == sc.MODERATE
                    cRef = cRefMod;
                else
                    cRef = cRefStr;
                end

                refUnsafe = get('SAFEFAIL', cRef, iM) > 0;

                elig = conn & ~refUnsafe;

                safeRule{iM,c} = 'EXP08C matched no-fault eligibility';

            otherwise

                % No fault: every seed is evidence.
                elig = true(numSeeds,1);
                safeRule{iM,c} = 'all seeds';

        end

        safeElig(iM,c)   = nnz(elig);
        safeUnsafe(iM,c) = nnz(elig & unsafe);

        if nnz(elig) > 0
            safeRate(iM,c) = nnz(elig & unsafe) / nnz(elig);
        end

    end

end


%% ============================================================
% Dominance under each cost model
%
% The pre-registered 1 % rule, unchanged from EXP07C: method M is
% DOMINATED in a cell if some other method M' has BOTH
%
%   RMSE(M') <= 0.99 * RMSE(M)   AND   cost(M') <= 0.99 * cost(M)
%
% A cell is EVALUABLE only if every method in it has a finite mean RMSE
% and a finite cost. Cells that are not evaluable are counted and named
% rather than dropped silently, because a shrinking denominator is
% exactly how a fraction gets flattered.
% ============================================================

variantNames = {'w=0.10','w=0.25','w=0.50','airtime','broadcast'};

variantCost = {mT010, mT025, mT050, mAIR, mBCST};

W025 = 2;

nVariant = numel(variantNames);

dominated    = false(nMethod, nCell, nVariant);
nonDominated = false(nMethod, nCell, nVariant);
evaluable    = false(nCell, nVariant);

winnerRMSE = zeros(nCell,1);
winnerCost = zeros(nCell, nVariant);

for c = 1:nCell

    [~, winnerRMSE(c)] = min(mRMSE(:,c));

    for v = 1:nVariant

        cost = variantCost{v}(:,c);
        err  = mRMSE(:,c);

        evaluable(c,v) = all(isfinite(cost)) && all(isfinite(err));

        [~, winnerCost(c,v)] = min(cost);

        if ~evaluable(c,v)
            continue;
        end

        for iM = 1:nMethod

            isDom = false;

            for jM = 1:nMethod

                if jM == iM
                    continue;
                end

                if err(jM)  <= DOMINANCE_MARGIN*err(iM) && ...
                   cost(jM) <= DOMINANCE_MARGIN*cost(iM)
                    isDom = true;
                    break;
                end

            end

            dominated(iM,c,v)    = isDom;
            nonDominated(iM,c,v) = ~isDom;

        end

    end

end


%% ============================================================
% THE UNIFIED MATRIX
%
% Every cell, every method, unfiltered. Plan section 9 forbids removing
% any row, including the rows where Causal-v3 loses.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('UNIFIED FINAL MATRIX  (%d cells x %d methods)\n', nCell, nMethod);
fprintf('============================================================\n\n');

% Preallocated columns, assembled into the table after the loop.
%
% Growing a table one row at a time works, but MATLAB warns on every
% single row ("the assignment added rows ... did not assign values to all
% of the table's existing variables") because a row exists for a moment
% before its later columns are filled. Sixty-eight copies of that warning
% in the freeze log would bury a real one, and the warning is exactly the
% shape of message that ought to be readable.

nRowU = nCell * nMethod;

uPoint    = cell(nRowU,1);
uPlant    = cell(nRowU,1);
uN        = zeros(nRowU,1);
uTopology = cell(nRowU,1);
uScenario = cell(nRowU,1);
uMethod   = cell(nRowU,1);

uRMSEmean = nan(nRowU,1);
uRMSEstd  = nan(nRowU,1);
uMinSep   = nan(nRowU,1);

uSafeCount = nan(nRowU,1);
uSafeElig  = nan(nRowU,1);
uSafeRate  = nan(nRowU,1);
uSafeRule  = cell(nRowU,1);

uDATA = nan(nRowU,1);
uACK  = nan(nRowU,1);
uT010 = nan(nRowU,1);
uT025 = nan(nRowU,1);
uT050 = nan(nRowU,1);
uAIR  = nan(nRowU,1);
uBCST = nan(nRowU,1);

uAoI  = nan(nRowU,1);
uEAoI = nan(nRowU,1);

uSat  = nan(nRowU,1);
uEff  = nan(nRowU,1);
uEstE = nan(nRowU,1);

uDiv  = nan(nRowU,1);
uEval = nan(nRowU,1);
uConn = nan(nRowU,1);

uDom = nan(nRowU, nVariant);

uSrcExp = cell(nRowU,1);
uSrcTag = cell(nRowU,1);

rowIdx = 0;

for c = 1:nCell

    pt = pts(cellPoint(c));

    fprintf('--- %-26s N=%-3d %-5s %-8s   source %s (%s)\n', ...
        cellLabel{c}, pt.N, pt.plant, pt.topology, pt.source, pt.sourceTag);

    fprintf('    %-12s %8s %7s %8s %9s %8s %8s %8s %8s %8s %8s %7s %6s %5s %5s\n', ...
        'Method','RMSE','sd','minSep','SafeFail','DATA','ACK','T.010', ...
        'T.025','T.050','airtime','bcast','AoI','nDiv','nEv');

    for iM = 1:nMethod

        fprintf('    %-12s %8.4f %7.4f %8.4f %4d/%-4d %8.2f %8.2f %8.2f %8.2f %8.2f %8.0f %7.2f %6.3f %5d %5d\n', ...
            methodNames{iM}, mRMSE(iM,c), sRMSE(iM,c), mMINSEP(iM,c), ...
            safeUnsafe(iM,c), safeElig(iM,c), ...
            mDATA(iM,c), mACK(iM,c), ...
            mT010(iM,c), mT025(iM,c), mT050(iM,c), ...
            mAIR(iM,c), mBCST(iM,c), mAOI(iM,c), ...
            nDIV(iM,c), nEVAL(iM,c));

        rowIdx = rowIdx + 1;

        uPoint{rowIdx}    = pt.id;
        uPlant{rowIdx}    = pt.plant;
        uN(rowIdx)        = pt.N;
        uTopology{rowIdx} = pt.topology;
        uScenario{rowIdx} = sc.names{cellScen(c)};
        uMethod{rowIdx}   = methodNames{iM};

        uRMSEmean(rowIdx) = mRMSE(iM,c);
        uRMSEstd(rowIdx)  = sRMSE(iM,c);
        uMinSep(rowIdx)   = mMINSEP(iM,c);

        uSafeCount(rowIdx) = safeUnsafe(iM,c);
        uSafeElig(rowIdx)  = safeElig(iM,c);
        uSafeRate(rowIdx)  = safeRate(iM,c);
        uSafeRule{rowIdx}  = safeRule{iM,c};

        uDATA(rowIdx) = mDATA(iM,c);
        uACK(rowIdx)  = mACK(iM,c);
        uT010(rowIdx) = mT010(iM,c);
        uT025(rowIdx) = mT025(iM,c);
        uT050(rowIdx) = mT050(iM,c);
        uAIR(rowIdx)  = mAIR(iM,c);
        uBCST(rowIdx) = mBCST(iM,c);

        uAoI(rowIdx)  = mAOI(iM,c);
        uEAoI(rowIdx) = mEAOI(iM,c);

        uSat(rowIdx)  = mSAT(iM,c);
        uEff(rowIdx)  = mEFF(iM,c);
        uEstE(rowIdx) = mESTERR(iM,c);

        uDiv(rowIdx)  = nDIV(iM,c);
        uEval(rowIdx) = nEVAL(iM,c);
        uConn(rowIdx) = nCONN(iM,c);

        for v = 1:nVariant
            uDom(rowIdx,v) = double(dominated(iM,c,v));
        end

        uSrcExp{rowIdx} = pt.source;
        uSrcTag{rowIdx} = pt.sourceTag;

    end

    fprintf('    winner by RMSE: %-12s   winner by cost (w=0.25): %s\n', ...
        methodNames{winnerRMSE(c)}, methodNames{winnerCost(c,W025)});

    if winnerRMSE(c) ~= IDX_CAUSAL
        fprintf('    NOTE: Causal-v3 does NOT win this cell on RMSE.\n');
    end

    fprintf('\n');

end


%% ============================================================
% Assemble the unified matrix
% ============================================================

U = table(uPoint, uPlant, uN, uTopology, uScenario, uMethod, ...
    uRMSEmean, uRMSEstd, uMinSep, ...
    uSafeCount, uSafeElig, uSafeRate, uSafeRule, ...
    uDATA, uACK, uT010, uT025, uT050, uAIR, uBCST, ...
    uAoI, uEAoI, uSat, uEff, uEstE, ...
    uDiv, uEval, uConn, uSrcExp, uSrcTag, ...
    'VariableNames', { ...
        'point','plant','N','topology','scenario','method', ...
        'RMSEmean','RMSEstd','minSep', ...
        'safeFailCount','safeEligibleCount','safeFailRate','safeRule', ...
        'DATA','ACK','Total_w010','Total_w025','Total_w050', ...
        'airtime','broadcast', ...
        'AoI','estimatedAoI','saturation','effort','estError', ...
        'diverged','evaluable','connected', ...
        'sourceExperiment','sourceTag'});

for v = 1:nVariant
    U.(sprintf('dominated_%s', localSafeName(variantNames{v}))) = uDom(:,v);
end


%% ============================================================
% Moderate Pareto fraction
% ============================================================

fprintf('============================================================\n');
fprintf('Moderate: Causal-v3 non-dominated fraction\n');
fprintf('============================================================\n\n');

modCells = find(cellScen == sc.MODERATE);

fprintf('  %-12s %10s %10s %s\n', ...
    'Cost model','evaluable','non-dom','fraction');

modFraction = nan(nVariant,1);

for v = 1:nVariant

    ev = modCells(evaluable(modCells,v));

    nd = nnz(nonDominated(IDX_CAUSAL, ev, v));

    if ~isempty(ev)
        modFraction(v) = nd / numel(ev);
    end

    fprintf('  %-12s %10d %10d %8.1f %%\n', ...
        variantNames{v}, numel(ev), nd, 100*modFraction(v));

end

modExcluded = modCells(~evaluable(modCells,W025));

if ~isempty(modExcluded)
    fprintf('\n  Moderate cells NOT evaluable at w=0.25 (named, not dropped silently):\n');
    for q = 1:numel(modExcluded)
        fprintf('    %s\n', cellLabel{modExcluded(q)});
    end
end

modCriterionMet = modFraction(W025) >= MODERATE_REFERENCE_FRACTION;

fprintf('\n  Reference criterion: non-dominated in >= %.0f %% of evaluable\n', ...
    100*MODERATE_REFERENCE_FRACTION);
fprintf('  Moderate point-families at w = 0.25.\n');
fprintf('  Result: %.1f %%  ->  %s\n', 100*modFraction(W025), ...
    localMetNot(modCriterionMet));

if ~modCriterionMet
    fprintf('\n  The Moderate Pareto claim is therefore DOWNGRADED. It may\n');
    fprintf('  not be stated as "competitive with periodic in Moderate".\n');
end

fprintf('\n  Per-cell Moderate dominance at w = 0.25:\n\n');
fprintf('    %-26s %-14s %s\n', 'Cell', 'Causal', 'dominated by');

for q = 1:numel(modCells)

    c = modCells(q);

    if ~evaluable(c,W025)
        fprintf('    %-26s %-14s (cell not evaluable)\n', cellLabel{c}, '-');
        continue;
    end

    if nonDominated(IDX_CAUSAL,c,W025)
        fprintf('    %-26s %-14s -\n', cellLabel{c}, 'non-dominated');
    else
        fprintf('    %-26s %-14s %s\n', cellLabel{c}, 'DOMINATED', ...
            strjoin(localDominators(mRMSE(:,c), variantCost{W025}(:,c), ...
                IDX_CAUSAL, methodNames, DOMINANCE_MARGIN), ', '));
    end

end


%% ============================================================
% Stressed: characterisation only, NO superiority gate
%
% EXP07C rejected Stressed ACK-inclusive Pareto superiority. That
% rejection is a locked negative result and EXP10 does not re-open it.
% What follows is a description of what happened, not a test of whether
% it is good enough.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Stressed: dominance characterisation (NO gate)\n');
fprintf('============================================================\n\n');

strCells = find(cellScen == sc.STRESSED);

fprintf('  %-26s %-10s %-14s %s\n', ...
    'Cell','cost model','Causal','dominated by');

for q = 1:numel(strCells)

    c = strCells(q);

    for v = [1 2 3 4 5]

        if ~evaluable(c,v)
            status = '(not evaluable)';
            who = '-';
        elseif nonDominated(IDX_CAUSAL,c,v)
            status = 'non-dominated';
            who = '-';
        else
            status = 'DOMINATED';
            who = strjoin(localDominators(mRMSE(:,c), variantCost{v}(:,c), ...
                IDX_CAUSAL, methodNames, DOMINANCE_MARGIN), ', ');
        end

        if v == 1
            fprintf('  %-26s %-10s %-14s %s\n', ...
                cellLabel{c}, variantNames{v}, status, who);
        else
            fprintf('  %-26s %-10s %-14s %s\n', '', variantNames{v}, status, who);
        end

    end

    fprintf('\n');

end

strFraction = nan(nVariant,1);

for v = 1:nVariant
    ev = strCells(evaluable(strCells,v));
    if ~isempty(ev)
        strFraction(v) = nnz(nonDominated(IDX_CAUSAL, ev, v)) / numel(ev);
    end
end

fprintf('  Stressed non-dominated fraction, reported without a gate:\n');
for v = 1:nVariant
    fprintf('    %-12s %6.1f %%\n', variantNames{v}, 100*strFraction(v));
end


%% ============================================================
% Adaptivity criterion (plan section 11)
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Adaptivity on the nominal N=5 6-DOF point\n');
fprintf('============================================================\n\n');

cCln = localFindCell(cellPoint, cellScen, pts, 'NOMINAL', sc.CLEAN);
cMod = localFindCell(cellPoint, cellScen, pts, 'NOMINAL', sc.MODERATE);
cStr = localFindCell(cellPoint, cellScen, pts, 'NOMINAL', sc.STRESSED);

adaptCells = [cCln cMod cStr];

fprintf('  %-10s %10s %10s %11s %10s %10s\n', ...
    'Scenario','DATA Hz','ACK Hz','Total.025','RMSE','AoI');

for q = 1:numel(adaptCells)

    c = adaptCells(q);

    fprintf('  %-10s %10.2f %10.2f %11.2f %10.4f %10.3f\n', ...
        sc.names{cellScen(c)}, ...
        mDATA(IDX_CAUSAL,c), mACK(IDX_CAUSAL,c), mT025(IDX_CAUSAL,c), ...
        mRMSE(IDX_CAUSAL,c), mAOI(IDX_CAUSAL,c));

end

adaptData = mDATA(IDX_CAUSAL, adaptCells);
adaptTot  = mT025(IDX_CAUSAL, adaptCells);

adaptOrdered = all(diff(adaptData) > 0);

fprintf('\n  Criterion: Causal DATA  Clean < Moderate < Stressed\n');
fprintf('  DATA Hz      : %.2f < %.2f < %.2f  ->  %s\n', ...
    adaptData(1), adaptData(2), adaptData(3), localMetNot(adaptOrdered));

fprintf('  Total w=0.25 : %.2f -> %.2f -> %.2f  (ordering %s)\n', ...
    adaptTot(1), adaptTot(2), adaptTot(3), ...
    localOrderWord(all(diff(adaptTot) > 0)));

fprintf('\n  The two orderings are reported together because DATA alone\n');
fprintf('  does not say what happened to total communication: EXP07C\n');
fprintf('  showed ACK-inclusive cost can move the other way.\n');


%% ============================================================
% Causal-v3 versus State-event (plan section 12)
%
% The RULE is fixed in advance; the STATEMENT is derived from the data.
% The plan draft previously carried the conclusion itself, which would
% have pre-registered an outcome rather than a test.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Causal-v3 versus State-event across the whole final matrix\n');
fprintf('============================================================\n\n');

exceptions = {};

for c = 1:nCell

    a = mRMSE(IDX_CAUSAL,c);
    b = mRMSE(IDX_EVENT,c);

    if ~isfinite(a) || ~isfinite(b)
        exceptions{end+1} = sprintf('%s (not evaluable: %.4f vs %.4f)', ...
            cellLabel{c}, a, b);                                    %#ok<AGROW>
    elseif ~(a < b)
        exceptions{end+1} = sprintf('%s (Causal %.4f vs State-event %.4f)', ...
            cellLabel{c}, a, b);                                    %#ok<AGROW>
    end

end

causalBeatsEvent = isempty(exceptions);

if causalBeatsEvent

    fprintf('  Causal-v3 mean RMSE is lower than State-event in ALL %d cells.\n', nCell);
    fprintf('  The permitted statement is therefore:\n\n');
    fprintf('    "lower RMSE than State-event throughout the final matrix"\n');

else

    fprintf('  Causal-v3 mean RMSE is NOT lower than State-event in every\n');
    fprintf('  cell. The unconditional statement is NOT permitted. The\n');
    fprintf('  %d exception(s):\n\n', numel(exceptions));

    for q = 1:numel(exceptions)
        fprintf('    %s\n', exceptions{q});
    end

end


%% ============================================================
% LOCKED LIMITATIONS - NOT RE-TESTED AWAY
%
% Plan section 13. This section is fixed text plus the EXP10 evidence at
% the corresponding point. A favourable EXP10 number does not overwrite
% any of it: EXP10 ran ONE selected point per limitation, on new seeds,
% and one point cannot retract a sweep.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('LOCKED LIMITATIONS - NOT RE-TESTED AWAY\n');
fprintf('============================================================\n');

cLnkMod = localFindCell(cellPoint, cellScen, pts, 'LINK', sc.MODERATE);
cLnkStr = localFindCell(cellPoint, cellScen, pts, 'LINK', sc.STRESSED);
cNodMod = localFindCell(cellPoint, cellScen, pts, 'NODE', sc.MODERATE);
cNodStr = localFindCell(cellPoint, cellScen, pts, 'NODE', sc.STRESSED);
cMisMod = localFindCell(cellPoint, cellScen, pts, 'MISMATCH', sc.MODERATE);
cMisStr = localFindCell(cellPoint, cellScen, pts, 'MISMATCH', sc.STRESSED);
cEstMod = localFindCell(cellPoint, cellScen, pts, 'ESTIMATOR', sc.MODERATE);
cEstStr = localFindCell(cellPoint, cellScen, pts, 'ESTIMATOR', sc.STRESSED);

fprintf('\n  [EXP07C  exp07c-locked-negative]\n');
fprintf('  Stressed ACK-inclusive Pareto superiority: REJECTED.\n');
fprintf('  EXP10 does not re-open it. Stressed carries no superiority\n');
fprintf('  gate above, and the Stressed non-dominated fraction at\n');
fprintf('  w = 0.25 here is %.1f %% - reported, not tested.\n', ...
    100*strFraction(W025));

fprintf('\n  [EXP08A  exp08a-locked-partial]\n');
fprintf('  Safety generalization across topology: PARTIAL. EXP10 ran\n');
fprintf('  ring2 only, so it carries NO evidence either way about the\n');
fprintf('  other topologies and cannot narrow that limitation.\n');

fprintf('\n  [EXP08B  exp08b-locked-partial]\n');
fprintf('  Absolute safety under permanent link failure: FAILED, and\n');
fprintf('  failed for every method alike. EXP10 at N=20 ring2, 20 %%\n');
fprintf('  permanent removal:\n');
localPrintSafety(cLnkMod, cLnkStr, cellLabel, methodNames, ...
    safeUnsafe, safeElig, safeRate);

fprintf('\n  [EXP08C  exp08c-locked-partial]\n');
fprintf('  Safety under a 5 s node blackout: FAILED, for every method\n');
fprintf('  alike. EXP10 at N=20 ring2, one follower dark for 5 s, under\n');
fprintf('  EXP08C matched no-fault eligibility:\n');
localPrintSafety(cNodMod, cNodStr, cellLabel, methodNames, ...
    safeUnsafe, safeElig, safeRate);

fprintf('\n  [EXP09B  exp09b-locked-partial]\n');
fprintf('  Absolute RMSE robustness to plant mismatch: FAILED. The\n');
fprintf('  attribution stands - the controller has no integral action,\n');
fprintf('  so a mass offset leaves a steady error that no communication\n');
fprintf('  policy can remove. EXP10 at B7:\n');
fprintf('    %-26s Causal RMSE %.4f   nominal %.4f   (+%.1f %%)\n', ...
    cellLabel{cMisMod}, mRMSE(IDX_CAUSAL,cMisMod), mRMSE(IDX_CAUSAL,cMod), ...
    100*(mRMSE(IDX_CAUSAL,cMisMod)/mRMSE(IDX_CAUSAL,cMod) - 1));
fprintf('    %-26s Causal RMSE %.4f   nominal %.4f   (+%.1f %%)\n', ...
    cellLabel{cMisStr}, mRMSE(IDX_CAUSAL,cMisStr), mRMSE(IDX_CAUSAL,cStr), ...
    100*(mRMSE(IDX_CAUSAL,cMisStr)/mRMSE(IDX_CAUSAL,cStr) - 1));

fprintf('\n  [EXP09C  exp09c-locked-partial]\n');
fprintf('  Two limitations, both standing:\n');
fprintf('  (a) Clean-scenario estimator noise drove false triggers and\n');
fprintf('      more than doubled DATA traffic. EXP10 did not run the\n');
fprintf('      estimator point at Clean, so it carries NO evidence about\n');
fprintf('      that failure and cannot retract it.\n');
fprintf('  (b) The communication rate depends materially on the outer\n');
fprintf('      dt. EXP10 ran dt = 0.02 s only, so the dt-invariance\n');
fprintf('      rejection stands untouched.\n');
fprintf('  EXP10 at C3, for the record:\n');
fprintf('    %-26s Causal DATA %.2f Hz   nominal %.2f Hz   (x%.2f)\n', ...
    cellLabel{cEstMod}, mDATA(IDX_CAUSAL,cEstMod), mDATA(IDX_CAUSAL,cMod), ...
    mDATA(IDX_CAUSAL,cEstMod)/mDATA(IDX_CAUSAL,cMod));
fprintf('    %-26s Causal DATA %.2f Hz   nominal %.2f Hz   (x%.2f)\n', ...
    cellLabel{cEstStr}, mDATA(IDX_CAUSAL,cEstStr), mDATA(IDX_CAUSAL,cStr), ...
    mDATA(IDX_CAUSAL,cEstStr)/mDATA(IDX_CAUSAL,cStr));

fprintf('\n  [EXP06A graph convention]\n');
fprintf('  The N=50 anchor here uses the EXP08 graph convention, which\n');
fprintf('  removes in-links to the leader. Absolute traffic at N=50 is\n');
fprintf('  therefore NOT comparable with EXP06A. Only within-EXP10\n');
fprintf('  method ratios are.\n');


%% ============================================================
% Safety across the whole matrix
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Safety across the whole matrix, per source eligibility rule\n');
fprintf('============================================================\n\n');

fprintf('  %-26s %-12s %10s %10s %s\n', ...
    'Cell','Method','unsafe','eligible','rule');

for c = 1:nCell
    for iM = 1:nMethod

        if safeUnsafe(iM,c) == 0
            continue;
        end

        fprintf('  %-26s %-12s %10d %10d %s\n', ...
            cellLabel{c}, methodNames{iM}, ...
            safeUnsafe(iM,c), safeElig(iM,c), safeRule{iM,c});

    end
end

if sum(safeUnsafe(:)) == 0
    fprintf('  no eligible seed was unsafe anywhere in the matrix\n');
end


%% ============================================================
% Cells whose eligibility denominator is EMPTY
%
% EXP08C counts these separately and so must this. When a method was
% unsafe in every no-fault seed of a cell, matched no-fault eligibility
% leaves nothing eligible, the failure rate is 0/0, and the cell carries
% NO EVIDENCE about the fault. A bare NaN in the table above would read
% as "no failures", which is the opposite of what it means, so the cells
% are named here.
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('Cells with an EMPTY eligibility denominator - no evidence\n');
fprintf('------------------------------------------------------------\n\n');

nNoEvidence = 0;

for c = 1:nCell
    for iM = 1:nMethod

        if safeElig(iM,c) > 0
            continue;
        end

        nNoEvidence = nNoEvidence + 1;

        ptC = pts(cellPoint(c));

        fprintf('  %-26s %-12s 0 eligible seeds (%s)\n', ...
            cellLabel{c}, methodNames{iM}, safeRule{iM,c});

        if strcmpi(ptC.kind,'node')
            fprintf('%30s this method was unsafe in ALL %d no-fault seeds of the\n', ...
                '', numSeeds);
            fprintf('%30s matched N20REF cell, so its blackout safety here is\n', '');
            fprintf('%30s UNEVALUABLE, not zero.\n', '');
        end

    end
end

if nNoEvidence == 0
    fprintf('  none: every cell and method has at least one eligible seed\n');
end


%% ============================================================
% No-fault safety, reported on its own
%
% The eligibility rule above removes pre-existing unsafety from the fault
% points, which is correct - but it also means a method that is unsafe
% WITHOUT any fault can vanish from the fault tables. That is a finding in
% its own right and belongs in the report, not only in a denominator.
% ============================================================

fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('No-fault safety, all seeds - the baseline the rule subtracts\n');
fprintf('------------------------------------------------------------\n\n');

noFaultCells = [];

for c = 1:nCell
    if strcmpi(pts(cellPoint(c)).kind, 'nominal')
        noFaultCells(end+1) = c;   %#ok<AGROW>
    end
end

fprintf('  %-26s %-12s %10s %10s\n', 'Cell','Method','unsafe','of');

anyNoFaultUnsafe = false;

for q = 1:numel(noFaultCells)

    c = noFaultCells(q);

    for iM = 1:nMethod

        u = safeUnsafe(iM,c);

        if u == 0
            continue;
        end

        anyNoFaultUnsafe = true;

        fprintf('  %-26s %-12s %10d %10d\n', ...
            cellLabel{c}, methodNames{iM}, u, safeElig(iM,c));

    end

end

if ~anyNoFaultUnsafe
    fprintf('  no method was unsafe at any no-fault point\n');
end


%% ============================================================
% Divergence census
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('Divergence census - every run accounted for\n');
fprintf('============================================================\n\n');

totalRuns = height(T);

fprintf('  rows                     : %d\n', totalRuns);
fprintf('  labelled DIVERGED        : %d\n', nnz(T.DIVERGED > 0));
fprintf('  NaN RMSE without a label : %d\n', ...
    nnz(isnan(T.RMSE) & T.DIVERGED == 0));
fprintf('  beyond a 50 m ball, unlabelled : %d\n', ...
    nnz(T.MAXDEV > 50 & T.DIVERGED == 0));

if any(T.DIVERGED > 0)
    fprintf('\n  Diverged runs by cell:\n');
    for c = 1:nCell
        for iM = 1:nMethod
            if nDIV(iM,c) > 0
                fprintf('    %-26s %-12s %d of %d\n', ...
                    cellLabel{c}, methodNames{iM}, nDIV(iM,c), numSeeds);
            end
        end
    end
end


%% ============================================================
% Persist the unified matrix
% ============================================================

writetable(U, fullfile(expRun.dir,'tidy.csv'));

fprintf('\nunified matrix : %d rows x %d columns -> tidy.csv\n', ...
    height(U), width(U));

% A pointer back to the dataset this analysis describes, so a reader can
% never pair this table with a different EXP10A run.
fid = fopen(fullfile(expRun.dir,'SOURCE_DATASET.txt'),'w');
if fid > 0
    fprintf(fid, '%s/%s\n', srcName, srcRunId);
    fprintf(fid, 'tidy.csv rows: %d\n', height(T));
    fprintf(fid, 'seeds: %d (%d..%d)\n', ...
        numSeeds, min(seedList), max(seedList));
    fclose(fid);
end


%% ============================================================
% Figures
% ============================================================

figure('Name','EXP10B cost versus error, w=0.25, all cells');
markers = {'o','s','^','d'};
for iM = 1:nMethod
    plot(mT025(iM,:), mRMSE(iM,:), markers{iM}, ...
        'MarkerSize',7,'LineWidth',1.2,'DisplayName',methodNames{iM});
    hold on;
end
grid on;
xlabel('cost, DATA + 0.25 ACK  [Hz]');
ylabel('formation RMSE  [m]');
legend('Location','best');
title('EXP10B unified matrix: every cell, unfiltered');

figure('Name','EXP10B non-dominated fraction by cost model');
bar([modFraction strFraction]*100);
set(gca,'XTickLabel',variantNames);
ylabel('Causal-v3 non-dominated  [% of evaluable cells]');
legend({'Moderate','Stressed'},'Location','best');
yline(100*MODERATE_REFERENCE_FRACTION,'r--','LineWidth',1.4, ...
    'DisplayName','Moderate reference 75 %');
grid on;
title('Non-dominated fraction under each cost model');

figure('Name','EXP10B adaptivity on the nominal point');
bar([adaptData(:) adaptTot(:)]);
set(gca,'XTickLabel',sc.names);
ylabel('rate  [Hz]');
legend({'DATA','DATA + 0.25 ACK'},'Location','northwest');
grid on;
title('Causal-v3 adaptivity: DATA versus ACK-inclusive total');

figure('Name','EXP10B RMSE by method across the matrix');
bar(mRMSE');
set(gca,'XTick',1:nCell,'XTickLabel',cellLabel,'XTickLabelRotation',60);
ylabel('formation RMSE  [m]');
legend(methodNames,'Location','northwest');
grid on;
title('EXP10B RMSE, every cell');


%% ============================================================
% Persist
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function m = localMeanFinite(v)

v = v(isfinite(v));

if isempty(v)
    m = NaN;
else
    m = mean(v);
end

end


function s = localStdFinite(v)

v = v(isfinite(v));

if numel(v) < 2
    s = NaN;
else
    s = std(v);
end

end


function s = localMetNot(tf)

if tf
    s = 'MET';
else
    s = 'NOT MET';
end

end


function s = localOrderWord(tf)

if tf
    s = 'increasing';
else
    s = 'NOT increasing';
end

end


function s = localSafeName(v)
%LOCALSAFENAME Turn a cost-model label into a valid table variable name.

s = matlab.lang.makeValidName(v);

end


function who = localDominators(err, cost, iM, methodNames, margin)
%LOCALDOMINATORS Which methods dominate method iM in this cell.

who = {};

for jM = 1:numel(methodNames)

    if jM == iM
        continue;
    end

    if err(jM) <= margin*err(iM) && cost(jM) <= margin*cost(iM)
        who{end+1} = methodNames{jM};   %#ok<AGROW>
    end

end

if isempty(who)
    who = {'-'};
end

end


function localPrintSafety(cA, cB, cellLabel, methodNames, ...
    safeUnsafe, safeElig, safeRate)
%LOCALPRINTSAFETY Safety at two cells, all methods, with denominators.

for c = [cA cB]

    for iM = 1:numel(methodNames)

        fprintf('    %-26s %-12s %d/%d unsafe = %5.1f %%\n', ...
            cellLabel{c}, methodNames{iM}, ...
            safeUnsafe(iM,c), safeElig(iM,c), 100*safeRate(iM,c));

    end

end

end


function c = localFindCell(cellPoint, cellScen, pts, pointId, iScenario)

ids = arrayfun(@(k) pts(k).id, cellPoint, 'UniformOutput', false);

hit = find(strcmp(ids, pointId) & cellScen == iScenario);

if numel(hit) ~= 1
    error('exp10b:cellLookup', ...
        'Expected exactly one %s cell at scenario %d, found %d.', ...
        pointId, iScenario, numel(hit));
end

c = hit;

end
