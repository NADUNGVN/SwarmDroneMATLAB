%% MAKE_PAPER_METRICS - harvest every manuscript number from frozen results
%
% Reads the persisted result files of simulation-v1.0 and writes:
%
%   paper/generated/headline_metrics.csv   one row per number, with the
%                                          source file it came from
%   paper/generated/metrics.tex            LaTeX macros, so the manuscript
%                                          never hard-codes a number
%   paper/generated/PROVENANCE.md          which result directory fed what
%
% RUNS NO SIMULATION. It opens tidy.csv files and aggregates them. If a
% number cannot be derived from a persisted file it is not emitted, and
% the manuscript therefore cannot cite it.
%
% WHY MACROS RATHER THAN TYPED NUMBERS
%
% A number typed into prose is a number nobody can check. Every headline
% figure in the manuscript is \MetricSomething, defined here from the
% frozen file, so a mismatch between the paper and the data is a build
% error rather than a reader's problem. paper/scripts/paper_audit.m
% enforces that no stray decimal appears in the claim text.
%
% STATISTICAL CONVENTIONS, APPLIED UNIFORMLY
%
%   EXP10 key claims        paired mean difference + 95 % CI, n = 50
%   development experiments mean +- standard deviation, n = 20
%   binary safety           unsafe / eligible, and the percentage
%
% The paired intervals are recomputed here from the per-seed rows with
% utils/pairedCI, not copied from a console log, so the manuscript's
% interval and the dataset cannot drift apart.

function make_paper_metrics()
%MAKE_PAPER_METRICS Entry point.
%
% A FUNCTION, not a script, because the accumulator helpers below are
% NESTED functions: they share this workspace so addMetric and addMacro
% can append to M and macros. A script's local functions get their own
% workspace and the appends would silently vanish.

startup;

root = projectRoot();

paperDir = fullfile(root, 'paper');
genDir   = fullfile(paperDir, 'generated');

if ~exist(genDir,'dir')
    mkdir(genDir);
end

fprintf('\n');
fprintf('============================================================\n');
fprintf('make_paper_metrics - harvesting frozen results\n');
fprintf('============================================================\n\n');


%% ============================================================
% Metric accumulator
% ============================================================

M = struct('key',{},'value',{},'ciLo',{},'ciHi',{},'n',{}, ...
           'units',{},'source',{},'note',{});

    function addMetric(key, value, ciLo, ciHi, n, units, source, note)
        M(end+1) = struct('key',key,'value',value,'ciLo',ciLo, ...
            'ciHi',ciHi,'n',n,'units',units,'source',source,'note',note);
    end

macros = {};

    function addMacro(name, text)
        macros{end+1} = {name, text};   %#ok<AGROW>
    end


%% ============================================================
% Locate the frozen datasets
% ============================================================

exp10aDir = localLatestDir('exp10a_final_validation');
exp10bDir = localLatestDir('exp10b_unified_matrix');
exp07aDir = localLatestDir('exp07a_causal_ack');
exp07bDir = localLatestDir('exp07b_ack_impairment');
exp07cDir = localLatestDir('exp07c_cost_model');
exp08aDir = localLatestDir('exp08a_topology');
exp08bDir = localLatestDir('exp08b_link_failure');
exp08cDir = localLatestDir('exp08c_node_blackout');
exp09aDir = localLatestDir('exp09a_multiuav_6dof');
exp09bDir = localLatestDir('exp09b_physical_mismatch');
exp09cDir = localLatestDir('exp09c_synthetic_estimator');
exp09dDir = localLatestDir('exp09c_timestep_diagnostic');

A = readtable(fullfile(exp10aDir,'tidy.csv'), 'TextType','char');
U = readtable(fullfile(exp10bDir,'tidy.csv'), 'TextType','char');

fprintf('  EXP10A : %s  (%d rows)\n', localShort(exp10aDir), height(A));
fprintf('  EXP10B : %s  (%d rows)\n', localShort(exp10bDir), height(U));

nSeedA = numel(unique(A.seed));

fprintf('  seeds  : %d\n\n', nSeedA);


%% ============================================================
% 1. EXP10 paired key claims  (K1, K2a, K2b)
% ============================================================

srcA = localRel(exp10aDir);

selNomStr = strcmp(A.point,'NOMINAL') & strcmp(A.scenario,'Stressed');

    function v = pull(sel, method, col)
        idx = sel & strcmp(A.method, method);
        T = A(idx, :);
        T = sortrows(T, 'seed');
        v = T.(col);
    end

rmseC = pull(selNomStr,'Causal-v3','RMSE');
rmseP10 = pull(selNomStr,'P10','RMSE');

dataC = pull(selNomStr,'Causal-v3','DATACOUNT');
dataP20 = pull(selNomStr,'P20','DATACOUNT');

rateC = pull(selNomStr,'Causal-v3','DATARATE');
rateP20 = pull(selNomStr,'P20','DATARATE');

totC = pull(selNomStr,'Causal-v3','TOTAL025');
totP20 = pull(selNomStr,'P20','TOTAL025');

K1  = pairedCI(rmseC,  rmseP10, nSeedA);
K2aC = pairedCI(dataC, dataP20, nSeedA);
K2aR = pairedCI(rateC, rateP20, nSeedA);
K2bC = pairedCI(dataC + 0.25*pull(selNomStr,'Causal-v3','ACKCOUNT'), ...
                dataP20 + 0.25*pull(selNomStr,'P20','ACKCOUNT'), nSeedA);
K2bR = pairedCI(totC,  totP20, nSeedA);

addMetric('exp10.K1.rmse_causal_minus_p10', K1.meanD, K1.lo, K1.hi, ...
    K1.nPairs, 'm', srcA, 'Nominal Stressed, paired, directional < 0');
addMetric('exp10.K2a.data_causal_minus_p20_packets', K2aC.meanD, ...
    K2aC.lo, K2aC.hi, K2aC.nPairs, 'packets', srcA, 'no direction');
addMetric('exp10.K2a.data_causal_minus_p20_hz', K2aR.meanD, ...
    K2aR.lo, K2aR.hi, K2aR.nPairs, 'Hz', srcA, 'no direction');
addMetric('exp10.K2b.total_w025_causal_minus_p20_packets', K2bC.meanD, ...
    K2bC.lo, K2bC.hi, K2bC.nPairs, 'packets', srcA, 'DATA + 0.25 ACK');
addMetric('exp10.K2b.total_w025_causal_minus_p20_hz', K2bR.meanD, ...
    K2bR.lo, K2bR.hi, K2bR.nPairs, 'Hz', srcA, 'DATA + 0.25 ACK');

addMacro('MetricKoneMean',  sprintf('%.4f', K1.meanD));
addMacro('MetricKoneLo',    sprintf('%.4f', K1.lo));
addMacro('MetricKoneHi',    sprintf('%.4f', K1.hi));
addMacro('MetricKonePairs', sprintf('%d',   K1.nPairs));

addMacro('MetricKtwoaMean', sprintf('%.2f', K2aR.meanD));
addMacro('MetricKtwoaLo',   sprintf('%.2f', K2aR.lo));
addMacro('MetricKtwoaHi',   sprintf('%.2f', K2aR.hi));

addMacro('MetricKtwobMean', sprintf('%+.2f', K2bR.meanD));
addMacro('MetricKtwobLo',   sprintf('%+.2f', K2bR.lo));
addMacro('MetricKtwobHi',   sprintf('%+.2f', K2bR.hi));

addMacro('MetricSeeds', sprintf('%d', nSeedA));
addMacro('MetricRuns',  sprintf('%d', height(A)));
addMacro('MetricCells', sprintf('%d', height(U)/4));

fprintf('  K1  %+.4f  CI [%+.4f, %+.4f]  n=%d\n', ...
    K1.meanD, K1.lo, K1.hi, K1.nPairs);
fprintf('  K2a %+.4f Hz  CI [%+.4f, %+.4f]\n', ...
    K2aR.meanD, K2aR.lo, K2aR.hi);
fprintf('  K2b %+.4f Hz  CI [%+.4f, %+.4f]\n\n', ...
    K2bR.meanD, K2bR.lo, K2bR.hi);


%% ============================================================
% 2. Nominal holdout cells, all methods, all scenarios
% ============================================================

srcU = localRel(exp10bDir);

scNames = {'Clean','Moderate','Stressed'};
mNames  = {'P10','P20','State-event','Causal-v3'};
mTags   = {'Pten','Ptwenty','Event','Causal'};

    function r = urow(point, scen, method)
        idx = strcmp(U.point,point) & strcmp(U.scenario,scen) & ...
              strcmp(U.method,method);
        if nnz(idx) ~= 1
            error('make_paper_metrics: %s/%s/%s matched %d rows.', ...
                point, scen, method, nnz(idx));
        end
        r = U(idx,:);
    end

for iS = 1:numel(scNames)
    for iM = 1:numel(mNames)

        r = urow('NOMINAL', scNames{iS}, mNames{iM});

        pre = sprintf('exp10.nominal.%s.%s', lower(scNames{iS}), ...
            matlab.lang.makeValidName(mNames{iM}));

        addMetric([pre '.rmse_mean'], r.RMSEmean, NaN, NaN, nSeedA, 'm', srcU, '');
        addMetric([pre '.rmse_std'],  r.RMSEstd,  NaN, NaN, nSeedA, 'm', srcU, '');
        addMetric([pre '.data_hz'],   r.DATA,     NaN, NaN, nSeedA, 'Hz', srcU, '');
        addMetric([pre '.ack_hz'],    r.ACK,      NaN, NaN, nSeedA, 'Hz', srcU, '');
        addMetric([pre '.total_w025'],r.Total_w025,NaN,NaN, nSeedA, 'Hz', srcU, '');

        tag = sprintf('%s%s', mTags{iM}, scNames{iS});

        addMacro(['MetricRmse' tag],  sprintf('%.4f', r.RMSEmean));
        addMacro(['MetricData' tag],  sprintf('%.2f', r.DATA));
        addMacro(['MetricAck'  tag],  sprintf('%.2f', r.ACK));
        addMacro(['MetricTot'  tag],  sprintf('%.2f', r.Total_w025));

    end
end

% Adaptivity ordering, the S4 claim.
dCl = urow('NOMINAL','Clean','Causal-v3').DATA;
dMo = urow('NOMINAL','Moderate','Causal-v3').DATA;
dSt = urow('NOMINAL','Stressed','Causal-v3').DATA;

adaptOrdered = (dCl < dMo) && (dMo < dSt);

addMetric('exp10.adaptivity.ordered', double(adaptOrdered), NaN, NaN, ...
    nSeedA, 'bool', srcU, 'Causal DATA Clean < Moderate < Stressed');

addMacro('MetricAdaptOrdered', localYesNo(adaptOrdered));


%% ============================================================
% 3. Pareto fractions, per cost model, per scenario
% ============================================================

costCols = {'dominated_w_0_10','dominated_w_0_25','dominated_w_0_50', ...
            'dominated_airtime','dominated_broadcast'};
costTags = {'Wten','Wtwentyfive','Wfifty','Airtime','Broadcast'};
costName = {'w=0.10','w=0.25','w=0.50','airtime','broadcast'};

for iS = [2 3]

    scen = scNames{iS};

    for iC = 1:numel(costCols)

        idx = strcmp(U.scenario,scen) & strcmp(U.method,'Causal-v3');

        dom = U.(costCols{iC})(idx);

        ev  = ~isnan(dom);

        frac = nnz(dom(ev) == 0) / max(nnz(ev),1);

        addMetric(sprintf('exp10.pareto.%s.%s.nondominated_fraction', ...
            lower(scen), matlab.lang.makeValidName(costName{iC})), ...
            frac, NaN, NaN, nnz(ev), 'fraction', srcU, ...
            'Causal-v3 non-dominated, 1 % dominance rule');

        addMacro(sprintf('MetricPareto%s%s', scen, costTags{iC}), ...
            sprintf('%.1f', 100*frac));

    end

end

fprintf('  Moderate non-dominated w=0.25 : %s %%\n', ...
    localMacro(macros,'MetricParetoModerateWtwentyfive'));
fprintf('  Stressed non-dominated w=0.25 : %s %%\n\n', ...
    localMacro(macros,'MetricParetoStressedWtwentyfive'));


%% ============================================================
% 4. Causal versus State-event across the final matrix
% ============================================================

cellKeys = unique(strcat(U.point,'|',U.scenario));

nBeat = 0;
exceptions = {};

for k = 1:numel(cellKeys)

    parts = strsplit(cellKeys{k}, '|');

    a = urow(parts{1}, parts{2}, 'Causal-v3').RMSEmean;
    b = urow(parts{1}, parts{2}, 'State-event').RMSEmean;

    if a < b
        nBeat = nBeat + 1;
    else
        exceptions{end+1} = cellKeys{k};   %#ok<AGROW>
    end

end

addMetric('exp10.causal_beats_event.cells', nBeat, NaN, NaN, ...
    numel(cellKeys), 'cells', srcU, 'lower mean RMSE than State-event');

addMacro('MetricBeatEventCells', sprintf('%d', nBeat));
addMacro('MetricTotalCells',     sprintf('%d', numel(cellKeys)));

% Causal versus P10 and P20, for the honesty claims L4 and L5.
nBeatP10 = 0; excP10 = {};
nBeatP20 = 0;

for k = 1:numel(cellKeys)
    parts = strsplit(cellKeys{k}, '|');
    a  = urow(parts{1},parts{2},'Causal-v3').RMSEmean;
    p1 = urow(parts{1},parts{2},'P10').RMSEmean;
    p2 = urow(parts{1},parts{2},'P20').RMSEmean;
    if a < p1, nBeatP10 = nBeatP10 + 1; else, excP10{end+1} = cellKeys{k}; end %#ok<AGROW>
    if a < p2, nBeatP20 = nBeatP20 + 1; end
end

addMetric('exp10.causal_beats_p10.cells', nBeatP10, NaN, NaN, ...
    numel(cellKeys), 'cells', srcU, '');
addMetric('exp10.causal_beats_p20.cells', nBeatP20, NaN, NaN, ...
    numel(cellKeys), 'cells', srcU, '');

addMacro('MetricBeatPtenCells',     sprintf('%d', nBeatP10));
addMacro('MetricBeatPtwentyCells',  sprintf('%d', nBeatP20));

% Cheapest-method census, for L1.
nCheapest = 0;

for k = 1:numel(cellKeys)
    parts = strsplit(cellKeys{k}, '|');
    c = zeros(1,4);
    for iM = 1:4
        c(iM) = urow(parts{1},parts{2},mNames{iM}).Total_w025;
    end
    [~, w] = min(c);
    if w == 4
        nCheapest = nCheapest + 1;
    end
end

addMetric('exp10.causal_cheapest_w025.cells', nCheapest, NaN, NaN, ...
    numel(cellKeys), 'cells', srcU, 'cells where Causal-v3 has the lowest DATA + 0.25 ACK');

addMacro('MetricCausalCheapestCells', sprintf('%d', nCheapest));


%% ============================================================
% 5. Divergence and invariant census
% ============================================================

addMetric('exp10.diverged.runs', sum(A.DIVERGED), NaN, NaN, ...
    height(A), 'runs', srcA, '');
addMetric('exp10.invariant_violations', sum(A.INVARIANTS,'omitnan'), ...
    NaN, NaN, height(A), 'violations', srcA, '');

addMacro('MetricDiverged',  sprintf('%d', sum(A.DIVERGED)));
addMacro('MetricInvariants',sprintf('%d', sum(A.INVARIANTS,'omitnan')));


%% ============================================================
% 6. EXP07A causal design evolution  (Table II)
%
% The ablation chain is persisted as METHODS of EXP07A, so Ideal-AoI and
% A2c..A5c come from the frozen file. v1 and v2 are earlier CODE versions
% whose runs were not persisted as separate directories; their numbers
% live in the design log and are emitted with that provenance rather than
% presented as if a tidy file backed them.
% ============================================================

E7 = readtable(fullfile(exp07aDir,'tidy.csv'), 'TextType','char');

src7 = localRel(exp07aDir);

chain    = {'Ideal-AoI','A2c Fixed-OL','A3c Adapt-OL','A4c Dual-mem','A5c Innov-pri'};
chainTag = {'Ideal','Atwoc','Athreec','Afourc','Afivec'};

for k = 1:numel(chain)

    for iS = 1:numel(scNames)

        idx = strcmp(E7.method, chain{k}) & strcmp(E7.scenario, scNames{iS});

        rate = mean(E7.TXRATE(idx), 'omitnan');
        rmse = mean(E7.RMSE(idx),  'omitnan');
        sd   = std( E7.RMSE(idx),  'omitnan');

        pre = sprintf('exp07a.%s.%s', ...
            matlab.lang.makeValidName(chain{k}), lower(scNames{iS}));

        addMetric([pre '.tx_rate_hz'], rate, NaN, NaN, nnz(idx), 'Hz', src7, '');
        addMetric([pre '.rmse_mean'],  rmse, NaN, NaN, nnz(idx), 'm',  src7, '');
        addMetric([pre '.rmse_std'],   sd,   NaN, NaN, nnz(idx), 'm',  src7, '');

        addMacro(sprintf('MetricSeven%s%sRate', chainTag{k}, scNames{iS}), ...
            sprintf('%.2f', rate));
        addMacro(sprintf('MetricSeven%s%sRmse', chainTag{k}, scNames{iS}), ...
            sprintf('%.4f', rmse));

    end

end


%% ============================================================
% 7. EXP07B ACK impairment  (the saturation story)
% ============================================================

E7b = readtable(fullfile(exp07bDir,'tidy.csv'), 'TextType','char');

src7b = localRel(exp07bDir);

for scen = {'Moderate','Stressed'}

    ackCells = {'reliable','L20 D=fwd'};
    ackTags  = {'Reliable','Impaired'};

    for iC = 1:numel(ackCells)

        cell0 = ackCells(iC);

        idx = strcmp(E7b.method,'Causal-v3') & ...
              strcmp(E7b.scenario, scen{1}) & strcmp(E7b.ackCell, cell0{1});

        if ~any(idx)
            continue;
        end

        pre = sprintf('exp07b.%s.%s', lower(scen{1}), ...
            matlab.lang.makeValidName(cell0{1}));

        addMetric([pre '.rmse_mean'],  mean(E7b.RMSE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), 'm', src7b, '');
        addMetric([pre '.rmse_std'],   std(E7b.RMSE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), 'm', src7b, '');
        addMetric([pre '.tx_rate_hz'], mean(E7b.TXRATE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), 'Hz', src7b, '');
        addMetric([pre '.mean_scale'], mean(E7b.MEANSCALE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), '-', src7b, 'adaptive threshold scale');
        addMetric([pre '.min_scale'],  mean(E7b.MINSCALE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), '-', src7b, 'floor is aoiStateScaleMin = 0.20');

        % Macro names must be letters only: LaTeX rejects digits and
        % underscores in a command name, so the data label 'L20 D=fwd'
        % cannot be used to build one.
        addMacro(sprintf('MetricAckImp%s%sRmse', scen{1}, ackTags{iC}), ...
            sprintf('%.4f', mean(E7b.RMSE(idx),'omitnan')));
        addMacro(sprintf('MetricAckImp%s%sRate', scen{1}, ackTags{iC}), ...
            sprintf('%.2f', mean(E7b.TXRATE(idx),'omitnan')));
        addMacro(sprintf('MetricAckImp%s%sScale', scen{1}, ackTags{iC}), ...
            sprintf('%.3f', mean(E7b.MEANSCALE(idx),'omitnan')));

    end

end


%% ============================================================
% 8. EXP09A  DI versus 6-DOF, the plant-transition claim
% ============================================================

E9a = readtable(fullfile(exp09aDir,'tidy.csv'), 'TextType','char');

src9a = localRel(exp09aDir);

for mode = {'DI','6DOF'}
    for iS = 1:numel(scNames)
        for iM = 1:numel(mNames)

            idx = strcmp(E9a.mode,mode{1}) & ...
                  strcmp(E9a.scenario,scNames{iS}) & ...
                  strcmp(E9a.method,mNames{iM});

            if ~any(idx)
                continue;
            end

            pre = sprintf('exp09a.%s.%s.%s', lower(mode{1}), ...
                lower(scNames{iS}), matlab.lang.makeValidName(mNames{iM}));

            addMetric([pre '.rmse_mean'], mean(E9a.RMSE(idx),'omitnan'), ...
                NaN, NaN, nnz(idx), 'm', src9a, '');
            addMetric([pre '.data_hz'], mean(E9a.DATARATE(idx),'omitnan'), ...
                NaN, NaN, nnz(idx), 'Hz', src9a, '');

        end
    end
end


%% ============================================================
% 9. EXP09B mismatch and EXP09C estimator boundaries
% ============================================================

E9b = readtable(fullfile(exp09bDir,'tidy.csv'), 'TextType','char');
E9c = readtable(fullfile(exp09cDir,'tidy.csv'), 'TextType','char');
E9d = readtable(fullfile(exp09dDir,'tidy.csv'), 'TextType','char');

src9b = localRel(exp09bDir);
src9c = localRel(exp09cDir);
src9d = localRel(exp09dDir);

for arm = {'B0 nominal','B7 combined'}
    for iS = 1:numel(scNames)

        idx = strcmp(E9b.arm,arm{1}) & strcmp(E9b.scenario,scNames{iS}) & ...
              strcmp(E9b.method,'Causal-v3');

        if ~any(idx)
            continue;
        end

        pre = sprintf('exp09b.%s.%s', matlab.lang.makeValidName(arm{1}), ...
            lower(scNames{iS}));

        addMetric([pre '.rmse_mean'], mean(E9b.RMSE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), 'm', src9b, '');
        addMetric([pre '.rmse_std'], std(E9b.RMSE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), 'm', src9b, '');

    end
end

for arm = {'N0 noiseless','C3 combined'}
    for iS = 1:numel(scNames)

        idx = strcmp(E9c.arm,arm{1}) & strcmp(E9c.scenario,scNames{iS}) & ...
              strcmp(E9c.method,'Causal-v3');

        if ~any(idx)
            continue;
        end

        pre = sprintf('exp09c.%s.%s', matlab.lang.makeValidName(arm{1}), ...
            lower(scNames{iS}));

        addMetric([pre '.rmse_mean'], mean(E9c.RMSE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), 'm', src9c, '');
        addMetric([pre '.data_hz'], mean(E9c.DATARATE(idx),'omitnan'), ...
            NaN, NaN, nnz(idx), 'Hz', src9c, '');

    end
end

% The Clean traffic ratio that broke the EXP09C bandwidth gate.
d0 = mean(E9c.DATARATE(strcmp(E9c.arm,'N0 noiseless') & ...
     strcmp(E9c.scenario,'Clean') & strcmp(E9c.method,'Causal-v3')),'omitnan');
d3 = mean(E9c.DATARATE(strcmp(E9c.arm,'C3 combined') & ...
     strcmp(E9c.scenario,'Clean') & strcmp(E9c.method,'Causal-v3')),'omitnan');

addMetric('exp09c.clean.c3_over_noiseless_data_ratio', d3/d0, NaN, NaN, ...
    20, 'ratio', src9c, 'pre-registered bound was < 2.0');

addMacro('MetricCleanNoiseRatio', sprintf('%.2f', d3/d0));

% Timestep sensitivity of the DATA rate.
dtVals = unique(E9d.dt);

for k = 1:numel(dtVals)

    idx = strcmp(E9d.dt,dtVals{k}) & strcmp(E9d.method,'Causal-v3') & ...
          strcmp(E9d.scenario,'Stressed');

    if ~any(idx)
        continue;
    end

    addMetric(sprintf('exp09d.%s.stressed.data_hz', ...
        matlab.lang.makeValidName(dtVals{k})), ...
        mean(E9d.DATARATE(idx),'omitnan'), NaN, NaN, nnz(idx), 'Hz', ...
        src9d, 'DATA-rate dt invariance was rejected');

    dtTagMap = containers.Map( ...
        {'dt0.01','dt0.02','dt0.04'}, {'Fine','Base','Coarse'});

    if isKey(dtTagMap, dtVals{k})
        addMacro(sprintf('MetricDt%sData', dtTagMap(dtVals{k})), ...
            sprintf('%.2f', mean(E9d.DATARATE(idx),'omitnan')));
    end

end


%% ============================================================
% 10. Safety, with numerator and denominator kept together
% ============================================================

safeCells = {'LINK','Moderate'; 'LINK','Stressed'; ...
             'NODE','Moderate'; 'NODE','Stressed'; ...
             'N20REF','Stressed'; 'SCALE','Stressed'; ...
             'NOMINAL','Stressed'};

for k = 1:size(safeCells,1)
    for iM = 1:numel(mNames)

        r = urow(safeCells{k,1}, safeCells{k,2}, mNames{iM});

        pre = sprintf('exp10.safety.%s.%s.%s', lower(safeCells{k,1}), ...
            lower(safeCells{k,2}), matlab.lang.makeValidName(mNames{iM}));

        addMetric([pre '.unsafe'],   r.safeFailCount,    NaN, NaN, ...
            r.safeEligibleCount, 'seeds', srcU, r.safeRule{1});
        addMetric([pre '.eligible'], r.safeEligibleCount, NaN, NaN, ...
            nSeedA, 'seeds', srcU, r.safeRule{1});

    end
end


%% ============================================================
% Write headline_metrics.csv
% ============================================================

Tm = table();

Tm.key    = {M.key}';
Tm.value  = [M.value]';
Tm.ci_lo  = [M.ciLo]';
Tm.ci_hi  = [M.ciHi]';
Tm.n      = [M.n]';
Tm.units  = {M.units}';
Tm.source = {M.source}';
Tm.note   = {M.note}';

csvPath = fullfile(genDir,'headline_metrics.csv');

writetable(Tm, csvPath);

fprintf('  headline_metrics.csv : %d metrics\n', height(Tm));


%% ============================================================
% Write metrics.tex
% ============================================================

texPath = fullfile(genDir,'metrics.tex');

fid = fopen(texPath,'w');

fprintf(fid, '%% GENERATED FILE - do not edit.\n');
fprintf(fid, '%% Produced by paper/scripts/make_paper_metrics.m from the\n');
fprintf(fid, '%% frozen results of simulation-v1.0. Every headline number in\n');
fprintf(fid, '%% the manuscript is one of these macros, so a mismatch between\n');
fprintf(fid, '%% the paper and the data is a build error, not a reader problem.\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% EXP10A : %s\n', localRel(exp10aDir));
fprintf(fid, '%% EXP10B : %s\n', localRel(exp10bDir));
fprintf(fid, '\n');

% LaTeX command names may contain LETTERS ONLY. A digit or an underscore
% makes \newcommand fail at build time with a message pointing at the
% generated file rather than at the generator that produced it, so the
% check belongs here, where the name is still fixable. Seven names built
% from data labels such as 'L20 D=fwd' and 'dt0.01' failed this before it
% existed; readable letter-only tags replaced them.
badNames = {};

for k = 1:numel(macros)

    nm = macros{k}{1};

    if ~all(isletter(nm))
        badNames{end+1} = nm;   %#ok<AGROW>
    end

    fprintf(fid, '\\newcommand{\\%s}{%s}\n', nm, macros{k}{2});

end

fclose(fid);

if ~isempty(badNames)
    error('make_paper_metrics:badMacroName', ...
        ['Macro name(s) are not letters-only and LaTeX will reject ' ...
         'them: %s'], strjoin(badNames, ', '));
end

fprintf('  metrics.tex          : %d macros\n', numel(macros));


%% ============================================================
% Write PROVENANCE.md
% ============================================================

provPath = fullfile(genDir,'PROVENANCE.md');

fid = fopen(provPath,'w');

fprintf(fid, '# Generated-metric provenance\n\n');
fprintf(fid, 'Written by `paper/scripts/make_paper_metrics.m`. ');
fprintf(fid, 'No simulation is run; every value is read from a persisted\n');
fprintf(fid, '`tidy.csv` of the frozen `simulation-v1.0` campaign.\n\n');
fprintf(fid, '| Purpose | Result directory |\n|---|---|\n');

prov = { ...
    'EXP10 holdout dataset (paired claims, safety, divergence)', exp10aDir; ...
    'EXP10 unified matrix (per-cell means, dominance)',          exp10bDir; ...
    'EXP07A causal design chain and oracle comparator',          exp07aDir; ...
    'EXP07B ACK impairment and adaptive-scale saturation',       exp07bDir; ...
    'EXP07C cost models',                                       exp07cDir; ...
    'EXP08A topology generalization',                            exp08aDir; ...
    'EXP08B permanent and burst link failure',                   exp08bDir; ...
    'EXP08C node communication blackout',                        exp08cDir; ...
    'EXP09A double-integrator versus 6-DOF',                     exp09aDir; ...
    'EXP09B plant mismatch',                                     exp09bDir; ...
    'EXP09C synthetic estimator',                                exp09cDir; ...
    'EXP09C timestep diagnostic',                                exp09dDir};

for k = 1:size(prov,1)
    fprintf(fid, '| %s | `%s` |\n', prov{k,1}, localRel(prov{k,2}));
end

fprintf(fid, '\n## Statistical conventions\n\n');
fprintf(fid, '| Context | Reported as |\n|---|---|\n');
fprintf(fid, '| EXP10 key claims (K1, K2a, K2b) | paired mean difference, 95 %% CI, n = %d |\n', nSeedA);
fprintf(fid, '| Development experiments (EXP05-EXP09) | mean +- standard deviation, n = 20 |\n');
fprintf(fid, '| Binary safety | unsafe / eligible, and the percentage |\n');
fprintf(fid, '\nThe paired intervals are recomputed from per-seed rows with\n');
fprintf(fid, '`utils/pairedCI.m`, not copied from a console log.\n');

fclose(fid);

fprintf('  PROVENANCE.md        : %d source directories\n\n', size(prov,1));

fprintf('make_paper_metrics: done.\n');


end


%% ============================================================
% LOCAL FUNCTIONS
%
% Plain subfunctions: they need nothing from the parent workspace.
% ============================================================

function d = localLatestDir(expName)

r = projectRoot();

latest = fullfile(r,'results',expName,'LATEST.txt');

if exist(latest,'file') ~= 2
    error('make_paper_metrics: no LATEST.txt for %s.', expName);
end

d = fullfile(r,'results',expName,strtrim(fileread(latest)));

if exist(fullfile(d,'tidy.csv'),'file') ~= 2
    error('make_paper_metrics: %s has no tidy.csv.', d);
end

end


function s = localRel(d)

r = projectRoot();

s = strrep(strrep(d, r, ''), '\', '/');

s = regexprep(s, '^/', '');

end


function s = localShort(d)

[~, n] = fileparts(d);

s = n;

end


function s = localYesNo(tf)

if tf
    s = 'yes';
else
    s = 'no';
end

end


function v = localMacro(macros, name)

v = '(missing)';

for k = 1:numel(macros)
    if strcmp(macros{k}{1}, name)
        v = macros{k}{2};
        return;
    end
end

end
