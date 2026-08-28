function make_paper_tables()
%MAKE_PAPER_TABLES Generate every manuscript table from frozen results.
%
% Writes paper/tables/tableI..tableVI.tex. Runs no simulation.
%
% A UNIT HAZARD THIS FILE EXISTS TO KEEP STRAIGHT
%
% Two rate normalisations appear in this campaign and they are NOT
% comparable:
%
%   EXP07  TXRATE is PER CHANNEL. P10 reads exactly 10.000 Hz.
%   EXP10  DATA/ACK are SWARM TOTALS. P10 reads 99.67 Hz.
%
% Worse, the two eras run different channel counts at the same N = 5.
% EXP07 used defaultConfig's graph, which keeps in-links to the leader:
% nnz(A) = 10 plus 2 pinned links = 12 channels, so P10 totals 120 Hz.
% EXP08 onward use applyTopologyConfig, which removes in-links to the
% leader because the leader reads the reference directly: 8 + 2 = 10
% channels, so P10 totals 99.67 Hz.
%
% Every table therefore states its normalisation in the caption, and
% Table II and Table III are never placed in a way that invites the
% reader to divide one by the other. This is the same caveat the frozen
% campaign already records for N = 50 against EXP06A.

startup;

root = projectRoot();

tabDir = fullfile(root,'paper','tables');

if ~exist(tabDir,'dir')
    mkdir(tabDir);
end

fprintf('\n');
fprintf('============================================================\n');
fprintf('make_paper_tables\n');
fprintf('============================================================\n\n');

U  = localTidy('exp10b_unified_matrix');
E7 = localTidy('exp07a_causal_ack');
E7b = localTidy('exp07b_ack_impairment');
E8a = localTidy('exp08a_topology');
E8b = localTidy('exp08b_link_failure');
E8c = localTidy('exp08c_node_blackout');
E9a = localTidy('exp09a_multiuav_6dof');
E9b = localTidy('exp09b_physical_mismatch');
E9c = localTidy('exp09c_synthetic_estimator');
E9d = localTidy('exp09c_timestep_diagnostic');

scNames = {'Clean','Moderate','Stressed'};
mNames  = {'P10','P20','State-event','Causal-v3'};


%% ============================================================
% TABLE I - locked parameters
%
% Pulled from the config functions themselves rather than typed, so a
% parameter that moved would move here too.
% ============================================================

pts = exp10Points();
sc  = exp10Scenarios();

cfgN = applyExp10Point(pts(1), sc.MODERATE, 25000001);

rows = {
    'Swarm',      'followers $N$',                    sprintf('%d', cfgN.swarm.N), '--'
    'Swarm',      'outer timestep $\Delta t$',        sprintf('%.2f', cfgN.swarm.dt), 's'
    'Swarm',      'mission horizon $T$',              sprintf('%.0f', cfgN.swarm.T), 's'
    'Swarm',      'evaluation window start',          '8', 's'
    'Swarm',      'formation gain $K_p$',             sprintf('%.1f', cfgN.swarm.Kp), '--'
    'Swarm',      'formation gain $K_v$',             sprintf('%.1f', cfgN.swarm.Kv), '--'
    'Swarm',      'leader pinning $K_p^{L}$',         sprintf('%.1f', cfgN.swarm.KpLeader), '--'
    'Swarm',      'leader pinning $K_v^{L}$',         sprintf('%.1f', cfgN.swarm.KvLeader), '--'
    'Swarm',      'max commanded acceleration',       sprintf('%.1f', cfgN.swarm.maxAccel), 'm/s$^2$'
    'Swarm',      'safety threshold (minimum separation)', '0.25', 'm'
    'Graph',      'topology',                         'ring, degree 2 + leader pinning', '--'
    'Graph',      'directed channels at $N=5$',       sprintf('%d', nnz(cfgN.swarm.A) + sum(cfgN.swarm.pin)), '--'
    'Trigger',    'hard position threshold $\epsilon_p$',  sprintf('%.2f', cfgN.aoiEvent.posThreshold), 'm'
    'Trigger',    'hard velocity threshold $\epsilon_v$',  sprintf('%.2f', cfgN.aoiEvent.velThreshold), 'm/s'
    'Trigger',    'freshness threshold $\bar{A}$',    sprintf('%.2f', cfgN.aoiEvent.aoiThreshold), 's'
    'Trigger',    'refractory $\tau_{\min}$',         sprintf('%.2f', cfgN.aoiEvent.minInterTx), 's'
    'Trigger',    'refresh cooldown $\tau_{r}$',      sprintf('%.2f', cfgN.aoiEvent.aoiMinInterTx), 's'
    'Trigger',    'max silence $\tau_{\max}$',        sprintf('%.2f', cfgN.aoiEvent.maxSilence), 's'
    'Trigger',    'scale base $s_0$',                 sprintf('%.2f', cfgN.aoiEvent.aoiStateScaleBase), '--'
    'Trigger',    'scale floor $s_{\min}$',           sprintf('%.2f', cfgN.aoiEvent.aoiStateScaleMin), '--'
    'Trigger',    'adaptation range $\rho$',          sprintf('%.2f', cfgN.aoiEvent.aoiAdaptRange), '--'
    'Network',    'Clean loss / delay',               '0 / 0', '-- / s'
    'Network',    'Moderate loss / delay',            '0.20 / 0.08', '-- / s'
    'Network',    'Stressed loss / delay',            '0.40 / 0.12', '-- / s'
    'Network',    'periodic baselines',               '10 Hz (P10), 20 Hz (P20) per channel', '--'
    'Network',    'ACK channel',                      'cumulative, one per link per tick', '--'
    'Quadrotor',  'mass (nominal)',                   sprintf('%.3f', cfgN.quad.m), 'kg'
    'Quadrotor',  'linear drag (nominal)',            sprintf('%.2f', cfgN.quad.linearDrag), 'N/(m/s)'
    'Quadrotor',  'inner-loop ratio',                 sprintf('%d:1', cfgN.sixdof.ratio), '--'
    'Cost',       'ACK weights $w$',                  '0.10, 0.25, 0.50', '--'
    'Cost',       'airtime bytes DATA / ACK',         '48 / 24', 'B'
    'Cost',       'Pareto dominance margin',          '1', '\%'
    };

fid = localOpen(fullfile(tabDir,'tableI_parameters.tex'));

fprintf(fid, '%% Table I -- locked parameters. GENERATED, do not edit.\n');
fprintf(fid, '\\begin{tabular}{llrl}\n\\toprule\n');
fprintf(fid, 'Group & Parameter & Value & Unit \\\\\n\\midrule\n');

lastGroup = '';

for k = 1:size(rows,1)

    g = rows{k,1};

    if ~strcmp(g, lastGroup)
        if k > 1
            fprintf(fid, '\\addlinespace\n');
        end
        lastGroup = g;
    else
        g = '';
    end

    fprintf(fid, '%s & %s & %s & %s \\\\\n', g, rows{k,2}, rows{k,3}, rows{k,4});

end

fprintf(fid, '\\bottomrule\n\\end{tabular}\n');

fclose(fid);

fprintf('  tableI_parameters.tex\n');


%% ============================================================
% TABLE II - causal design evolution
%
% PER-CHANNEL Hz, from EXP07A. The chain is persisted as methods of that
% experiment, so every row here has a tidy.csv behind it.
% ============================================================

chain = { ...
    'Ideal-AoI',     'Ideal-feedback reference (non-causal)', 'reads receiver state directly in the same step; information-efficiency reference, not implementable and not a bound on attainable accuracy'; ...
    'A2c Fixed-OL',  'Causal, fixed threshold',   'open-loop freshness, no adaptation: rate barely moves with network quality'; ...
    'A3c Adapt-OL',  'Causal, adaptive, open loop','adapts the threshold but estimates freshness from what it sent, so the rate moves the WRONG way'; ...
    'A4c Dual-mem',  'Causal, dual memory',       'freshness now from ACKs; refresh cooldown becomes a ceiling on new information and pins the rate'; ...
    'A5c Innov-pri', 'Causal-AoI-v3 (proposed)',  'new information separated from refresh; only refresh is governed by the cooldown'};

fid = localOpen(fullfile(tabDir,'tableII_design_evolution.tex'));

fprintf(fid, '%% Table II -- causal design evolution. GENERATED, do not edit.\n');
fprintf(fid, '%% Rates are PER CHANNEL (P10 reads exactly 10.000 Hz).\n');
fprintf(fid, '\\setlength{\\tabcolsep}{3pt}%%\n');
fprintf(fid, '\\begin{tabular}{p{3.0cm}p{7.0cm}rrrr}\n\\toprule\n');
fprintf(fid, '\\multirow{2}{*}{Variant} & \\multirow{2}{*}{Feedback / semantics} & ');
fprintf(fid, '\\multicolumn{3}{c}{DATA rate per channel [Hz]} & Stressed \\\\\n');
fprintf(fid, '\\cmidrule(lr){3-5}\n');
fprintf(fid, ' & & Clean & Mod. & Str. & RMSE [m] \\\\\n\\midrule\n');

for k = 1:size(chain,1)

    r = zeros(1,3);

    for iS = 1:3
        idx = strcmp(E7.method,chain{k,1}) & strcmp(E7.scenario,scNames{iS});
        r(iS) = mean(E7.TXRATE(idx),'omitnan');
    end

    idxS = strcmp(E7.method,chain{k,1}) & strcmp(E7.scenario,'Stressed');

    rm = mean(E7.RMSE(idxS),'omitnan');
    sd = std(E7.RMSE(idxS),'omitnan');

    name = chain{k,2};

    if k == size(chain,1)
        name = ['\textbf{' name '}'];
    end

    fprintf(fid, '%s & %s & %.2f & %.2f & %.2f & %.4f $\\pm$ %.4f \\\\\n', ...
        name, chain{k,3}, r(1), r(2), r(3), rm, sd);

end

% Baselines for scale.
for b = {'P10','P20','A1 State-event'}

    r = zeros(1,3);
    for iS = 1:3
        idx = strcmp(E7.method,b{1}) & strcmp(E7.scenario,scNames{iS});
        r(iS) = mean(E7.TXRATE(idx),'omitnan');
    end

    idxS = strcmp(E7.method,b{1}) & strcmp(E7.scenario,'Stressed');

    fprintf(fid, '%s & %s & %.2f & %.2f & %.2f & %.4f $\\pm$ %.4f \\\\\n', ...
        b{1}, 'baseline', r(1), r(2), r(3), ...
        mean(E7.RMSE(idxS),'omitnan'), std(E7.RMSE(idxS),'omitnan'));

end

fprintf(fid, '\\bottomrule\n\\end{tabular}\n');

fclose(fid);

fprintf('  tableII_design_evolution.tex\n');


%% ============================================================
% TABLE III - EXP10 nominal holdout
%
% SWARM-TOTAL Hz, from the EXP10B unified matrix.
% ============================================================

fid = localOpen(fullfile(tabDir,'tableIII_nominal_holdout.tex'));

fprintf(fid, '%% Table III -- EXP10 nominal holdout. GENERATED, do not edit.\n');
fprintf(fid, '%% Rates are SWARM TOTALS over 10 directed channels.\n');
fprintf(fid, '\\begin{tabular}{llrrrrr}\n\\toprule\n');
fprintf(fid, 'Scenario & Method & RMSE [m] & $\\sigma$ & DATA [Hz] & ACK [Hz] & $C_{0.25}$ [Hz] \\\\\n');
fprintf(fid, '\\midrule\n');

for iS = 1:3

    for iM = 1:4

        r = localURow(U,'NOMINAL',scNames{iS},mNames{iM});

        sName = '';
        if iM == 1
            sName = scNames{iS};
        end

        mName = mNames{iM};
        if iM == 4
            mName = ['\textbf{' mName '}'];
        end

        fprintf(fid, '%s & %s & %.4f & %.4f & %.2f & %.2f & %.2f \\\\\n', ...
            sName, mName, r.RMSEmean, r.RMSEstd, r.DATA, r.ACK, r.Total_w025);

    end

    if iS < 3
        fprintf(fid, '\\addlinespace\n');
    end

end

fprintf(fid, '\\bottomrule\n\\end{tabular}\n');

fclose(fid);

fprintf('  tableIII_nominal_holdout.tex\n');


%% ============================================================
% TABLE IV - paired 50-seed confidence intervals
% ============================================================

A = localTidy('exp10a_final_validation');

nS = numel(unique(A.seed));

sel = strcmp(A.point,'NOMINAL') & strcmp(A.scenario,'Stressed');

    function v = pull(method, col)
        T = A(sel & strcmp(A.method,method), :);
        T = sortrows(T,'seed');
        v = T.(col);
    end

K1  = pairedCI(pull('Causal-v3','RMSE'),     pull('P10','RMSE'), nS);
K2a = pairedCI(pull('Causal-v3','DATARATE'), pull('P20','DATARATE'), nS);
K2b = pairedCI(pull('Causal-v3','TOTAL025'), pull('P20','TOTAL025'), nS);

claims = { ...
    'K1',  'RMSE', 'Causal-v3 $-$ P10',  'm',  K1,  '$<0$ (directional)'; ...
    'K2a', 'DATA', 'Causal-v3 $-$ P20',  'Hz', K2a, 'none (reported signed)'; ...
    'K2b', '$C_{0.25}=$ DATA $+\,0.25\,$ACK', 'Causal-v3 $-$ P20', 'Hz', K2b, 'none (reported signed)'};

fid = localOpen(fullfile(tabDir,'tableIV_paired_ci.tex'));

fprintf(fid, '%% Table IV -- paired holdout intervals. GENERATED, do not edit.\n');
fprintf(fid, '\\begin{tabular}{lllrrrcl}\n\\toprule\n');
fprintf(fid, 'Claim & Metric & Contrast & Mean $d$ & CI low & CI high & $n$ & Pre-registered hypothesis \\\\\n');
fprintf(fid, '\\midrule\n');

for k = 1:size(claims,1)

    S = claims{k,5};

    fprintf(fid, '%s & %s & %s & %+.4f & %+.4f & %+.4f & %d/%d & %s \\\\\n', ...
        claims{k,1}, claims{k,2}, claims{k,3}, ...
        S.meanD, S.lo, S.hi, S.nPairs, S.nRequested, claims{k,6});

end

fprintf(fid, '\\bottomrule\n\\end{tabular}\n');

fclose(fid);

fprintf('  tableIV_paired_ci.tex\n');


%% ============================================================
% TABLE V - robustness summary
%
% One row per robustness axis. Every number from a persisted file, with
% the experiment that produced it named in the row.
% ============================================================

vRows = {};

% --- ACK impairment (EXP07B): the saturation story ---
mR = mean(E7b.RMSE(strcmp(E7b.method,'Causal-v3') & ...
     strcmp(E7b.scenario,'Stressed') & strcmp(E7b.ackCell,'reliable')),'omitnan');
mI = mean(E7b.RMSE(strcmp(E7b.method,'Causal-v3') & ...
     strcmp(E7b.scenario,'Stressed') & strcmp(E7b.ackCell,'L20 D=fwd')),'omitnan');
sI = mean(E7b.MINSCALE(strcmp(E7b.method,'Causal-v3') & ...
     strcmp(E7b.scenario,'Stressed') & strcmp(E7b.ackCell,'L20 D=fwd')),'omitnan');

vRows(end+1,:) = {'ACK impairment', 'EXP07B', ...
    sprintf('Stressed RMSE %.4f reliable vs %.4f at 20\\%% ACK loss', mR, mI), ...
    sprintf('adaptive scale already at its floor $s_{\\min}=%.2f$', sI), ...
    'Saturation, not robustness'};

% --- topology (EXP08A) ---
cA = mean(E8a.RMSE(strcmp(E8a.method,'Causal-v3') & strcmp(E8a.scenario,'Stressed')),'omitnan');
cE = mean(E8a.RMSE(strcmp(E8a.method,'State-event') & strcmp(E8a.scenario,'Stressed')),'omitnan');
nTopo = numel(unique(E8a.topology));

vRows(end+1,:) = {'Topology', 'EXP08A', ...
    sprintf('%d topologies, $N\\in\\{10,20,50\\}$; Stressed mean RMSE %.4f vs %.4f (State-event)', nTopo, cA, cE), ...
    'communication ranking holds; absolute safety does not generalise', ...
    'Partial'};

% --- link fault (EXP08B) ---
selL = strcmp(E8b.fault,'perm 20%') & strcmp(E8b.topology,'ring2') & ...
       strcmp(E8b.scenario,'Stressed') & E8b.CONNECTED == 1;

uC = nnz(selL & strcmp(E8b.method,'Causal-v3') & E8b.SAFEFAIL == 1);
nC = nnz(selL & strcmp(E8b.method,'Causal-v3'));
uP = nnz(selL & strcmp(E8b.method,'P20') & E8b.SAFEFAIL == 1);
nP = nnz(selL & strcmp(E8b.method,'P20'));

vRows(end+1,:) = {'Permanent link failure', 'EXP08B', ...
    sprintf('20\\%% removal, ring2, Stressed: unsafe %d/%d (Causal) vs %d/%d (P20)', uC, nC, uP, nP), ...
    'failure rate is shared across methods', ...
    'Rejected (absolute), method-independent'};

% --- node blackout (EXP08C) ---
selB = strcmp(E8c.fault,'1node 5s') & strcmp(E8c.topology,'ring2') & ...
       strcmp(E8c.N,'N20') & strcmp(E8c.scenario,'Stressed');

uCb = nnz(selB & strcmp(E8c.method,'Causal-v3') & E8c.SAFEFAIL == 1);
nCb = nnz(selB & strcmp(E8c.method,'Causal-v3'));

rec = mean(E8c.RECOVERY(selB & strcmp(E8c.method,'Causal-v3')),'omitnan');

vRows(end+1,:) = {'Node blackout (5 s)', 'EXP08C', ...
    sprintf('1 node dark, $N=20$, Stressed: unsafe %d/%d, mean recovery %.2f s', uCb, nCb, rec), ...
    'shared across methods; recovery via max-silence backstop', ...
    'Rejected (absolute), method-independent'};

% --- 6-DOF transition (EXP09A) ---
dRm = mean(E9a.RMSE(strcmp(E9a.mode,'DI') & strcmp(E9a.method,'Causal-v3') & ...
     strcmp(E9a.scenario,'Stressed')),'omitnan');
sRm = mean(E9a.RMSE(strcmp(E9a.mode,'6DOF') & strcmp(E9a.method,'Causal-v3') & ...
     strcmp(E9a.scenario,'Stressed')),'omitnan');

vRows(end+1,:) = {'6-DOF followers', 'EXP09A', ...
    sprintf('Stressed Causal RMSE %.4f (DI) vs %.4f (6-DOF)', dRm, sRm), ...
    'communication ranking survives the plant change', ...
    'Supported'};

% --- plant mismatch (EXP09B) ---
b0 = mean(E9b.RMSE(strcmp(E9b.arm,'B0 nominal') & strcmp(E9b.method,'Causal-v3') & ...
     strcmp(E9b.scenario,'Moderate')),'omitnan');
b7 = mean(E9b.RMSE(strcmp(E9b.arm,'B7 combined') & strcmp(E9b.method,'Causal-v3') & ...
     strcmp(E9b.scenario,'Moderate')),'omitnan');

vRows(end+1,:) = {'Plant mismatch (B7)', 'EXP09B', ...
    sprintf('Moderate RMSE %.4f $\\rightarrow$ %.4f ($+%.0f\\%%$)', b0, b7, 100*(b7/b0-1)), ...
    'controller has no integral action; steady offset, not a communication effect', ...
    'Rejected (absolute)'};

% --- estimator noise (EXP09C) ---
n0 = mean(E9c.DATARATE(strcmp(E9c.arm,'N0 noiseless') & strcmp(E9c.method,'Causal-v3') & ...
     strcmp(E9c.scenario,'Clean')),'omitnan');
n3 = mean(E9c.DATARATE(strcmp(E9c.arm,'C3 combined') & strcmp(E9c.method,'Causal-v3') & ...
     strcmp(E9c.scenario,'Clean')),'omitnan');

vRows(end+1,:) = {'Estimator noise (C3)', 'EXP09C', ...
    sprintf('Clean DATA %.2f $\\rightarrow$ %.2f Hz ($\\times%.2f$)', n0, n3, n3/n0), ...
    'noise crosses the hard-innovation threshold: false triggers', ...
    'Rejected (bandwidth bound)'};

% --- timestep (EXP09C diagnostic) ---
dts = {'dt0.01','dt0.02','dt0.04'};
dv  = zeros(1,3);

for k = 1:3
    dv(k) = mean(E9d.DATARATE(strcmp(E9d.dt,dts{k}) & ...
        strcmp(E9d.method,'Causal-v3') & strcmp(E9d.scenario,'Stressed')),'omitnan');
end

vRows(end+1,:) = {'Outer timestep', 'EXP09C-dt', ...
    sprintf('Stressed DATA %.1f / %.1f / %.1f Hz at $\\Delta t=$ 0.01 / 0.02 / 0.04 s', dv(1), dv(2), dv(3)), ...
    'RMSE stable, rate is not: the trigger is evaluated per step', ...
    'Rejected (rate invariance)'};

fid = localOpen(fullfile(tabDir,'tableV_robustness.tex'));

fprintf(fid, '%% Table V -- robustness summary. GENERATED, do not edit.\n');
fprintf(fid, '\\setlength{\\tabcolsep}{2.5pt}%%\n');
fprintf(fid, '\\begin{tabular}{p{2.0cm}p{1.2cm}p{4.7cm}p{4.0cm}p{4.0cm}}\n\\toprule\n');
fprintf(fid, 'Axis & Source & Frozen evidence & Mechanism & Status \\\\\n\\midrule\n');

for k = 1:size(vRows,1)
    fprintf(fid, '%s & %s & %s & %s & %s \\\\\n\\addlinespace\n', ...
        vRows{k,1}, vRows{k,2}, vRows{k,3}, vRows{k,4}, vRows{k,5});
end

fprintf(fid, '\\bottomrule\n\\end{tabular}\n');

fclose(fid);

fprintf('  tableV_robustness.tex\n');


%% ============================================================
% TABLE VI - negative and boundary results
%
% The table the batch instruction singles out. Every rejected claim gets
% a row, with the number that rejected it.
% ============================================================

nRows = { ...
    'Stressed ACK-inclusive Pareto superiority', 'EXP07C, EXP10B', ...
    sprintf('Stressed non-dominated in %.0f\\%% of cells at $w=0.50$, airtime and broadcast', ...
        100*localFrac(U,'Stressed','dominated_w_0_50')), ...
    'ACK traffic is real traffic; pricing it removes the advantage'; ...
    ...
    'Universal topology safety', 'EXP08A', ...
    'safety gate fails systematically at one condition of the topology sweep', ...
    'unnormalised consensus gain scales with in-degree (EXP08A-D)'; ...
    ...
    'Absolute safety under permanent link failure', 'EXP08B, EXP10B', ...
    sprintf('EXP10 20\\%% removal, Moderate: unsafe %d/%d for P10, P20 and Causal alike', ...
        localSafeNum(U,'LINK','Moderate','Causal-v3'), ...
        localSafeDen(U,'LINK','Moderate','Causal-v3')), ...
    'formation geometry and controller, not the communication policy'; ...
    ...
    'Safety under a 5\,s node blackout', 'EXP08C, EXP10B', ...
    sprintf('EXP10, matched no-fault eligibility: unsafe %d/%d (Causal)', ...
        localSafeNum(U,'NODE','Moderate','Causal-v3'), ...
        localSafeDen(U,'NODE','Moderate','Causal-v3')), ...
    'a dark node cannot be reached by any policy'; ...
    ...
    '$\le 25\%$ RMSE degradation under B7 mismatch', 'EXP09B, EXP10B', ...
    sprintf('EXP10 Moderate: %.4f vs %.4f nominal, $+%.0f\\%%$', ...
        localURow(U,'MISMATCH','Moderate','Causal-v3').RMSEmean, ...
        localURow(U,'NOMINAL','Moderate','Causal-v3').RMSEmean, ...
        100*(localURow(U,'MISMATCH','Moderate','Causal-v3').RMSEmean / ...
             localURow(U,'NOMINAL','Moderate','Causal-v3').RMSEmean - 1)), ...
    'no integral action: a mass offset leaves a steady error'; ...
    ...
    'Clean estimator-noise traffic $<2\times$', 'EXP09C', ...
    sprintf('Clean DATA ratio $\\times%.2f$ against the noiseless arm', n3/n0), ...
    'measurement noise itself crosses the hard-innovation threshold'; ...
    ...
    'DATA-rate invariance to $\Delta t$', 'EXP09C-dt', ...
    sprintf('Stressed DATA %.1f / %.1f / %.1f Hz at $\\Delta t=$ 0.01 / 0.02 / 0.04 s', ...
        dv(1), dv(2), dv(3)), ...
    'the trigger is evaluated once per outer step by construction'};

fid = localOpen(fullfile(tabDir,'tableVI_negative_results.tex'));

fprintf(fid, '%% Table VI -- negative and boundary results. GENERATED, do not edit.\n');
fprintf(fid, '%% This table must not be removed or shortened: it is the record\n');
fprintf(fid, '%% that these claims were tested and did not hold.\n');
fprintf(fid, '\\begin{tabular}{p{4.1cm}lp{5.0cm}p{4.4cm}}\n\\toprule\n');
fprintf(fid, 'Rejected or bounded claim & Source & Frozen evidence & Attribution \\\\\n\\midrule\n');

for k = 1:size(nRows,1)
    fprintf(fid, '%s & %s & %s & %s \\\\\n\\addlinespace\n', ...
        nRows{k,1}, nRows{k,2}, nRows{k,3}, nRows{k,4});
end

fprintf(fid, '\\bottomrule\n\\end{tabular}\n');

fclose(fid);

fprintf('  tableVI_negative_results.tex\n\n');

fprintf('make_paper_tables: done, 6 tables.\n');

end


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function T = localTidy(expName)

r = projectRoot();

latest = fullfile(r,'results',expName,'LATEST.txt');

runId = strtrim(fileread(latest));

T = readtable(fullfile(r,'results',expName,runId,'tidy.csv'), ...
    'TextType','char');

end


function r = localURow(U, point, scen, method)

idx = strcmp(U.point,point) & strcmp(U.scenario,scen) & strcmp(U.method,method);

if nnz(idx) ~= 1
    error('make_paper_tables: %s/%s/%s matched %d rows.', ...
        point, scen, method, nnz(idx));
end

r = U(idx,:);

end


function f = localFrac(U, scen, col)

idx = strcmp(U.scenario,scen) & strcmp(U.method,'Causal-v3');

dom = U.(col)(idx);

ev = ~isnan(dom);

f = nnz(dom(ev) == 0) / max(nnz(ev),1);

end


function n = localSafeNum(U, point, scen, method)

n = localURow(U,point,scen,method).safeFailCount;

end


function n = localSafeDen(U, point, scen, method)

n = localURow(U,point,scen,method).safeEligibleCount;

end


function fid = localOpen(p)

fid = fopen(p,'w');

if fid < 0
    error('make_paper_tables: cannot write %s', p);
end

end
