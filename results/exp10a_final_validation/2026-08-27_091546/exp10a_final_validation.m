%% EXP10A - Final validation: 50 holdout seeds, paired CRN, confidence intervals
%
% This is the final stochastic run of the campaign. Everything it needs is
% frozen before it starts and lives outside this file:
%
%   utils/exp10Points.m      the selected-point matrix
%   utils/applyExp10Point.m  the config for one run at one point
%   utils/exp10Scenarios.m   the three network scenarios
%   utils/exp10Registry.m    the master CRN realizations, per (N, seed)
%   utils/assertExp10Seeds.m the holdout proof for the seed block
%
% so that EXP10B and run_simulation_v1_validation re-derive the identical
% matrix rather than a copy of it that can drift.
%
% WHAT THIS EXPERIMENT IS AND IS NOT
%
% It is not a new sweep and not a search. Nothing is tuned, no threshold,
% cost model, controller or Pareto definition moves, and no cell is added
% or removed after a number is seen. Its job is to state, on seeds never
% used during development, what the frozen protocol does at points that
% ALREADY EXPOSED LIMITS in EXP07-EXP09.
%
% THREE PRE-REGISTERED KEY CLAIMS (plan section 6)
%
%   K1   Nominal Stressed, paired RMSE(Causal - P10), directional < 0
%   K2a  Nominal Stressed, paired DATA(Causal - P20), NO direction
%   K2b  Nominal Stressed, paired DATA + 0.25*ACK (Causal - P20), NO direction
%
% K2 is split because EXP07C already proved that ACK-inclusive cost can
% reverse a DATA-only conclusion. Reporting a DATA saving while the
% ACK-inclusive total rises would be the exact error EXP07C recorded, so
% both are reported side by side and neither carries a direction.
%
% Every claim reports the mean paired difference AND a 95 % CI. An
% interval that contains zero DOWNGRADES the claim to "not distinguishable
% at 50 seeds". Adding seeds after seeing the interval is forbidden: that
% is choosing the sample size by the result.
%
% THE TWO KINDS OF GATE HERE
%
% The EXP10A gate is an INFRASTRUCTURE gate: hashes match, no missing
% rows, no unlabelled NaN, every seed used exactly once, paired statistics
% present, protocol invariants zero. It says the dataset is trustworthy.
%
% K1 is a SCIENTIFIC claim and may PASS, FAIL or come out INCONCLUSIVE.
% None of those three is a reason to change anything about the run.
%
% ============================================================

startup;

close all;


expRun = startExperiment('exp10a_final_validation');


%% ============================================================
% Scope
% ============================================================

exp10Seeds = 25000001:25000050;

% ------------------------------------------------------------
% Debug hook, used for infrastructure smoke tests only.
%
% Setting exp10SmokeSeeds in the base workspace before running shortens
% the seed block. It exists because a 3400-run sweep is a poor way to
% discover a typo in a hash check, and EXP08B set the same precedent by
% recording its 3-seed debug run as its own result directory.
%
% It cannot disguise itself as the final run: the seed list is printed
% into console.log, written into every row of tidy.csv, and gate G2
% checks the recorded seeds against this list, so a shortened run is
% visibly a shortened run. The FINAL result is the one whose console.log
% shows the full 50-seed block.
% ------------------------------------------------------------

if evalin('base','exist(''exp10SmokeSeeds'',''var'')')

    smoke = evalin('base','exp10SmokeSeeds');

    if ~isempty(smoke)
        exp10Seeds = smoke;
        fprintf(2, ['\nSMOKE TEST: seed block shortened to %d ' ...
                    'seeds. This is NOT the final validation run.\n'], ...
                    numel(smoke));
    end

end

numSeeds = numel(exp10Seeds);

methodNames = {'P10'; 'P20'; 'State-event'; 'Causal-v3'};

IDX_P10    = 1;
IDX_P20    = 2;
IDX_EVENT  = 3;
IDX_CAUSAL = 4;

nMethod = numel(methodNames);

sc  = exp10Scenarios();
pts = exp10Points();

safetyThreshold = 0.25;

% EXP07C accounting constants, unchanged.
AIRTIME_DATA_BYTES = 48;
AIRTIME_ACK_BYTES  = 24;

COST_W = [0.10; 0.25; 0.50];

W_REFERENCE = 2;    % w = 0.25 is the reference cost model


%% ============================================================
% Cell list
%
% One cell is one (point, scenario). The points carry different N and
% different scenario sets, so the matrix is enumerated as a flat cell
% list rather than as a rectangular array over point x scenario, which
% would have implied cells that do not exist.
% ============================================================

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

nRun = numSeeds * nMethod * nCell;


%% ============================================================
% Header
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP10A final validation - 50 holdout seeds\n');
fprintf('============================================================\n\n');

fprintf('Points   : %d\n', numel(pts));
fprintf('Cells    : %d (point x scenario)\n', nCell);
fprintf('Methods  : %s\n', strjoin(methodNames', ', '));
fprintf('Seeds    : %d holdout (%d..%d)\n', ...
    numSeeds, min(exp10Seeds), max(exp10Seeds));
fprintf('Runs     : %d\n', nRun);
fprintf('Phase    : ON (per sender, per payload class)\n');

fprintf('\nSelected points:\n\n');

for ip = 1:numel(pts)
    fprintf('  %-10s N=%-3d %-5s %-8s %s\n', ...
        pts(ip).id, pts(ip).N, pts(ip).plant, pts(ip).topology, pts(ip).label);
end


%% ============================================================
% PRE-RUN ASSERTION 1 - the seeds are a genuine holdout
%
% Runs before anything is simulated and raises rather than warns. A
% development seed in this block would make EXP10 a re-test of the data
% the protocol was built on.
% ============================================================

seedReport = assertExp10Seeds(exp10Seeds);


%% ============================================================
% PRE-RUN ASSERTION 2 - master realizations, fixed in advance
% ============================================================

Nlist = unique([pts.N]);

ensureParallelPool(16);

reg = exp10Registry(exp10Seeds, Nlist, true);

% Map an N to its registry column.
regCol = containers.Map(num2cell(reg.N), num2cell(1:numel(reg.N)));


%% ============================================================
% Storage
%
% [seed x method x cell]. Column-major linearisation puts seed fastest,
% which is what the row construction at the end relies on.
% ============================================================

sz = [numSeeds nMethod nCell];

RMSE     = nan(sz);
MINSEP   = nan(sz);
SAFEFAIL = false(sz);
DIVERGED = false(sz);

DATACOUNT  = nan(sz);
ACKCOUNT   = nan(sz);
BCASTCOUNT = nan(sz);
MISSION    = nan(sz);

TRUEAOI = nan(sz);
ESTAOI  = nan(sz);

HARDR    = nan(sz);
ADAPTR   = nan(sz);
REFRESHR = nan(sz);
MAXGAP   = nan(sz);

SATURATE = nan(sz);
EFFORT   = nan(sz);
ROLLPK   = nan(sz);
PITCHPK  = nan(sz);
MASSRAT  = nan(sz);
DRAGRAT  = nan(sz);
ESTERR   = nan(sz);

CONNECTED = true(sz);
LAMBDA2   = nan(sz);
ISOLATED  = nan(sz);
INDEGMIN  = nan(sz);

% Two hashes per channel trace. The EXACT ones (…X) are what the gate
% uses: they are integer-summed below 2^53, so summation order and thread
% count cannot move them, and they round-trip through tidy.csv. The
% LOCKED ones are the generator hashes whose values appear in EXP07-EXP09
% result tables; they sum millions of floats past 2^53 and are therefore
% NOT thread-stable, so they are recorded for continuity and reported,
% never gated. See utils/realizationHash.m.
FWDHASH   = nan(sz);
ACKHASH   = nan(sz);
FWDHASHX  = nan(sz);
ACKHASHX  = nan(sz);
PHASEHASH = nan(sz);
FAULTHASH = nan(sz);
BLACKHASH = nan(sz);
EXTHASH   = nan(sz);
NOISEHASH = nan(sz);
EXTHASHX  = nan(sz);
NOISEHASHX = nan(sz);

INVARIANTS = nan(sz);

% Largest distance any follower reached from the leader. Recorded so the
% completeness of the DIVERGED labelling can be checked rather than
% assumed: the 6-DOF divergence rule uses a 50 m ball, but the
% double-integrator points inherit the historical rule, which is
% non-finite states only. If a DI run ever left the same 50 m ball while
% staying finite, this column is what shows it.
MAXDEV = nan(sz);

SEEDVALUE = nan(sz);


%% ============================================================
% Main sweep
% ============================================================

tSweep = tic;

for c = 1:nCell

    ip = cellPoint(c);
    iS = cellScen(c);

    pt = pts(ip);

    % Worker cap. At N = 50 one Causal-v3 run holds a 61 MB forward
    % trace, a 61 MB reverse trace and two 30 MB AoI logs, so sixteen
    % concurrent workers would push the machine into swap and the run
    % would slow down rather than speed up. The cap changes scheduling
    % only; every result is independent of it, which the serial-versus-
    % parallel determinism check in EXP10C verifies directly.
    if pt.N >= 50
        wCap = 8;
    elseif pt.N >= 20
        wCap = 12;
    else
        wCap = 16;
    end

    fprintf('\n--- [%2d/%2d] %-24s N=%-3d %-5s  (%d workers)\n', ...
        c, nCell, cellLabel{c}, pt.N, pt.plant, wCap);

    for iM = 1:nMethod

        fprintf('    %-12s', methodNames{iM});

        rmseS = nan(numSeeds,1);
        msepS = nan(numSeeds,1);
        safeS = false(numSeeds,1);
        divS  = false(numSeeds,1);

        dataS  = nan(numSeeds,1);
        ackS   = nan(numSeeds,1);
        bcastS = nan(numSeeds,1);
        misS   = nan(numSeeds,1);

        taoiS = nan(numSeeds,1);
        eaoiS = nan(numSeeds,1);

        hrS   = nan(numSeeds,1);
        arS   = nan(numSeeds,1);
        rrS   = nan(numSeeds,1);
        gapS  = nan(numSeeds,1);

        satS  = nan(numSeeds,1);
        effS  = nan(numSeeds,1);
        rollS = nan(numSeeds,1);
        pitcS = nan(numSeeds,1);
        mrS   = nan(numSeeds,1);
        drS   = nan(numSeeds,1);
        eerrS = nan(numSeeds,1);

        connS = true(numSeeds,1);
        l2S   = nan(numSeeds,1);
        isoS  = nan(numSeeds,1);
        degS  = nan(numSeeds,1);

        fwdHS   = nan(numSeeds,1);
        ackHS   = nan(numSeeds,1);
        fwdXS   = nan(numSeeds,1);
        ackXS   = nan(numSeeds,1);
        phHS    = nan(numSeeds,1);
        fltHS   = nan(numSeeds,1);
        blkHS   = nan(numSeeds,1);
        extHS   = nan(numSeeds,1);
        nseHS   = nan(numSeeds,1);
        extXS   = nan(numSeeds,1);
        nseXS   = nan(numSeeds,1);

        invS  = nan(numSeeds,1);
        mdvS  = nan(numSeeds,1);
        sdS   = nan(numSeeds,1);

        methodName = methodNames{iM};

        parfor (s = 1:numSeeds, wCap)

            seedValue = exp10Seeds(s);

            cfg = applyExp10Point(pt, iS, seedValue);

            sdS(s) = seedValue;

            % ------------------------------------------------
            % Realization provenance available before the run.
            % The channel and phase hashes come back FROM the
            % run itself, so they attest to what was consumed
            % rather than to what the script re-derived.
            % ------------------------------------------------

            if isfield(cfg,'fault') && ~isempty(cfg.fault)

                fltHS(s) = cfg.fault.hash;

                g = graphConnectivity(cfg.fault.activeA, cfg.swarm.pin);

                connS(s) = g.connected;
                l2S(s)   = g.lambda2;
                isoS(s)  = cfg.fault.isolatedFollowers;
                degS(s)  = cfg.fault.activeInDegreeMin;

            end

            if isfield(cfg,'blackout') && ~isempty(cfg.blackout)

                blkHS(s) = cfg.blackout.hash;

                connS(s) = cfg.blackout.connected;
                l2S(s)   = cfg.blackout.lambda2;
                isoS(s)  = cfg.blackout.isolatedFollowers;
                degS(s)  = cfg.blackout.activeInDegreeMin;

            end

            if isfield(cfg,'extForce') && ~isempty(cfg.extForce)
                extHS(s) = cfg.extForce.hash;
                extXS(s) = cfg.extForce.hashExact;
            end

            if isfield(cfg,'estimator') && ~isempty(cfg.estimator)
                nseHS(s) = cfg.estimator.noise.hash;
                nseXS(s) = cfg.estimator.noise.hashExact;
            end


            out = simSwarm6DOF(cfg, methodName);

            fwdHS(s) = out.traceHash;
            ackHS(s) = out.ackTraceHash;
            fwdXS(s) = out.traceHashExact;
            ackXS(s) = out.ackTraceHashExact;
            phHS(s)  = out.phaseHash;

            M = computeSwarmMetrics(out, cfg);
            Q = compute6DOFMetrics(out, cfg);

            mission = out.t(end) - out.t(1);

            misS(s) = mission;

            divS(s) = Q.diverged || any(~isfinite(out.P(:)));

            mrS(s) = Q.massRatio;
            drS(s) = Q.dragRatio;

            if all(isfinite(out.P(:)))
                dev = sqrt(sum((out.P - out.P(:,1,:)).^2, 3));
                mdvS(s) = max(dev(:));
            else
                mdvS(s) = inf;
            end

            % Traffic counters are recorded for every run, diverged or
            % not: a diverged run still transmitted, and dropping its
            % traffic would bias the cost of exactly the conditions
            % where a method fails.
            dataS(s)  = out.txCount;
            bcastS(s) = out.broadcastCount;

            if isfield(out,'ackTxCount')
                ackS(s) = out.ackTxCount;
            else
                % A method with no reverse channel emits zero ACKs. That
                % is zero, not missing: it is what makes the
                % ACK-inclusive cost model comparable across methods.
                ackS(s) = 0;
            end

            if isfield(out,'invariantViolations')
                invS(s) = out.invariantViolations;
            else
                invS(s) = 0;
            end

            if isfield(out,'maxInterTxGap')
                gapS(s) = out.maxInterTxGap;
            end

            if divS(s)

                % A diverged run is a stability failure AND unsafe. Its
                % continuous metrics stay NaN so they cannot enter a
                % mean; DIVERGED labels them, so no NaN in this dataset
                % is unexplained.
                safeS(s) = true;

            else

                rmseS(s) = M.formationRMSE;
                msepS(s) = M.minSeparationEval;
                safeS(s) = M.minSeparationEval < safetyThreshold;

                idxEval = out.t >= 8;

                taoiS(s) = mean(out.meanAoI(idxEval));

                effS(s) = Q.controlEffort;
                satS(s) = Q.saturation;

                rollS(s) = Q.rollPeak;
                pitcS(s) = Q.pitchPeak;

                if isfield(out,'estimatedAoI')
                    ea = out.estimatedAoI(idxEval, :, :);
                    eaoiS(s) = mean(ea(isfinite(ea) & ea > 0));
                end

                if isfield(out,'hardInnovationRatio')
                    hrS(s) = out.hardInnovationRatio;
                    arS(s) = out.adaptiveNewInfoRatio;
                    rrS(s) = out.refreshRatio;
                end

            end

            if isfield(out,'est') && ~isempty(out.est) && out.est.errN > 0
                eerrS(s) = sqrt(out.est.errSq / out.est.errN);
            end

        end

        RMSE(:,iM,c)     = rmseS;
        MINSEP(:,iM,c)   = msepS;
        SAFEFAIL(:,iM,c) = safeS;
        DIVERGED(:,iM,c) = divS;

        DATACOUNT(:,iM,c)  = dataS;
        ACKCOUNT(:,iM,c)   = ackS;
        BCASTCOUNT(:,iM,c) = bcastS;
        MISSION(:,iM,c)    = misS;

        TRUEAOI(:,iM,c) = taoiS;
        ESTAOI(:,iM,c)  = eaoiS;

        HARDR(:,iM,c)    = hrS;
        ADAPTR(:,iM,c)   = arS;
        REFRESHR(:,iM,c) = rrS;
        MAXGAP(:,iM,c)   = gapS;

        SATURATE(:,iM,c) = satS;
        EFFORT(:,iM,c)   = effS;
        ROLLPK(:,iM,c)   = rollS;
        PITCHPK(:,iM,c)  = pitcS;
        MASSRAT(:,iM,c)  = mrS;
        DRAGRAT(:,iM,c)  = drS;
        ESTERR(:,iM,c)   = eerrS;

        CONNECTED(:,iM,c) = connS;
        LAMBDA2(:,iM,c)   = l2S;
        ISOLATED(:,iM,c)  = isoS;
        INDEGMIN(:,iM,c)  = degS;

        FWDHASH(:,iM,c)   = fwdHS;
        ACKHASH(:,iM,c)   = ackHS;
        FWDHASHX(:,iM,c)  = fwdXS;
        ACKHASHX(:,iM,c)  = ackXS;
        PHASEHASH(:,iM,c) = phHS;
        FAULTHASH(:,iM,c) = fltHS;
        BLACKHASH(:,iM,c) = blkHS;
        EXTHASH(:,iM,c)   = extHS;
        NOISEHASH(:,iM,c) = nseHS;
        EXTHASHX(:,iM,c)  = extXS;
        NOISEHASHX(:,iM,c) = nseXS;

        INVARIANTS(:,iM,c) = invS;
        MAXDEV(:,iM,c)     = mdvS;

        SEEDVALUE(:,iM,c) = sdS;

        fprintf(' done\n');

    end

end

fprintf('\nSweep completed in %.1f min\n', toc(tSweep)/60);


%% ============================================================
% Derived cost columns
%
% Accounting only, applied after the fact, exactly as EXP07C did. No
% policy, trigger, ACK or network behaviour depends on any of it.
% ============================================================

DATARATE  = DATACOUNT  ./ MISSION;
ACKRATE   = ACKCOUNT   ./ MISSION;
BCASTRATE = BCASTCOUNT ./ MISSION;

TOTAL = nan([sz numel(COST_W)]);

for iW = 1:numel(COST_W)
    TOTAL(:,:,:,iW) = (DATACOUNT + COST_W(iW)*ACKCOUNT) ./ MISSION;
end

TOTAL010 = TOTAL(:,:,:,1);
TOTAL025 = TOTAL(:,:,:,2);
TOTAL050 = TOTAL(:,:,:,3);

AIRTIME = (AIRTIME_DATA_BYTES*DATACOUNT + AIRTIME_ACK_BYTES*ACKCOUNT) ./ MISSION;

% Broadcast model, as EXP07C defined it: unique (tick, sender, payload
% class) DATA transmissions, with ACKs still unicast and priced at 1.
BROADCASTCOST = (BCASTCOUNT + ACKCOUNT) ./ MISSION;


%% ============================================================
% GATE 1 - realization hashes match where they should match
%
% The gate uses the EXACT hashes. The locked generator hashes are
% recorded and compared separately, below, with an explicit tolerance
% and an explicit reason: they sum millions of floats past 2^53, so
% MATLAB's multithreaded pairwise sum() groups them differently
% depending on thread count, and a pool worker runs single-threaded
% while the client does not. Gating on them would report a
% reproducibility failure that does not exist - the realization is the
% same, only the checksum moves in its last two digits.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EXP10A infrastructure gate\n');
fprintf('============================================================\n\n');

hashProblems = {};

for c = 1:nCell

    pt = pts(cellPoint(c));

    col = regCol(pt.N);

    for s = 1:numSeeds

        % --- forward trace: identical for all four methods, and equal
        %     to the value the registry fixed before the run ---
        fwd = FWDHASHX(s,:,c);

        if numel(unique(fwd)) ~= 1
            hashProblems{end+1} = sprintf( ...
                '%s seed %d: forward hash differs across methods', ...
                cellLabel{c}, exp10Seeds(s));                       %#ok<AGROW>
        elseif fwd(1) ~= reg.fwdX(s,col)
            hashProblems{end+1} = sprintf( ...
                '%s seed %d: forward hash is not the registry value', ...
                cellLabel{c}, exp10Seeds(s));                       %#ok<AGROW>
        end

        % --- reverse trace: only Causal-v3 has one. The baselines must
        %     report NaN, which is the audited form of "this method has
        %     no reverse channel" ---
        if ACKHASHX(s,IDX_CAUSAL,c) ~= reg.ackX(s,col)
            hashProblems{end+1} = sprintf( ...
                '%s seed %d: Causal reverse hash is not the registry value', ...
                cellLabel{c}, exp10Seeds(s));                       %#ok<AGROW>
        end

        if any(~isnan(ACKHASHX(s,[IDX_P10 IDX_P20 IDX_EVENT],c)))
            hashProblems{end+1} = sprintf( ...
                '%s seed %d: a baseline reported a reverse realization', ...
                cellLabel{c}, exp10Seeds(s));                       %#ok<AGROW>
        end

        % --- phase: the two periodic methods share one realization,
        %     the event-driven methods have none ---
        if PHASEHASH(s,IDX_P10,c) ~= reg.phase(s,col) || ...
                PHASEHASH(s,IDX_P20,c) ~= reg.phase(s,col)
            hashProblems{end+1} = sprintf( ...
                '%s seed %d: a periodic method used the wrong phase realization', ...
                cellLabel{c}, exp10Seeds(s));                       %#ok<AGROW>
        end

        if any(~isnan(PHASEHASH(s,[IDX_EVENT IDX_CAUSAL],c)))
            hashProblems{end+1} = sprintf( ...
                '%s seed %d: an event-driven method reported a phase realization', ...
                cellLabel{c}, exp10Seeds(s));                       %#ok<AGROW>
        end

        % --- perturbation realizations, where the point uses one ---
        hashProblems = localCheckPerturbHash(hashProblems, ...
            'link', FAULTHASH(s,:,c), reg.link(s,col), ...
            strcmp(pt.kind,'link'), cellLabel{c}, exp10Seeds(s));

        hashProblems = localCheckPerturbHash(hashProblems, ...
            'blackout', BLACKHASH(s,:,c), reg.blackout(s,col), ...
            strcmp(pt.kind,'node'), cellLabel{c}, exp10Seeds(s));

        hashProblems = localCheckPerturbHash(hashProblems, ...
            'external force', EXTHASHX(s,:,c), reg.extForceX(s,col), ...
            strcmp(pt.kind,'mismatch'), cellLabel{c}, exp10Seeds(s));

        hashProblems = localCheckPerturbHash(hashProblems, ...
            'estimator noise', NOISEHASHX(s,:,c), reg.noiseX(s,col), ...
            strcmp(pt.kind,'estimator'), cellLabel{c}, exp10Seeds(s));

    end

end

g1Hash = numel(hashProblems);

% ------------------------------------------------------------
% The locked generator hashes, reported not gated.
%
% Within this run every simulation executes on a pool worker, so the
% locked hashes should agree across methods too. Any disagreement here
% is worth seeing - it would mean some runs executed in the client -
% but it is not evidence about the realization, which the exact hashes
% above have already settled.
% ------------------------------------------------------------

lockedHashSpread = 0;

for c = 1:nCell
    for s = 1:numSeeds
        if numel(unique(FWDHASH(s,:,c))) ~= 1
            lockedHashSpread = lockedHashSpread + 1;
        end
    end
end

fprintf(['  Locked (non-thread-stable) forward hashes disagreeing ' ...
         'across\n  methods at the same seed: %d of %d seed-cells. ' ...
         'Reported, not\n  gated; see the note above GATE 1.\n\n'], ...
    lockedHashSpread, nCell*numSeeds);


%% ============================================================
% GATE 2 - no missing rows, every seed used exactly once
% ============================================================

g2Missing = 0;
g2SeedUse = 0;

for c = 1:nCell
    for iM = 1:nMethod

        used = SEEDVALUE(:,iM,c);

        g2Missing = g2Missing + nnz(isnan(used));

        if ~isequal(sort(used(:))', sort(exp10Seeds))
            g2SeedUse = g2SeedUse + 1;
        end

    end
end


%% ============================================================
% GATE 3 - no unlabelled NaN
%
% A NaN in a continuous metric is allowed only where DIVERGED is set.
% Anything else is a hole in the dataset masquerading as a result.
% ============================================================

nanUnlabelled = 0;

nanUnlabelled = nanUnlabelled + nnz(isnan(RMSE)   & ~DIVERGED);
nanUnlabelled = nanUnlabelled + nnz(isnan(MINSEP) & ~DIVERGED);
nanUnlabelled = nanUnlabelled + nnz(isnan(DATACOUNT));
nanUnlabelled = nanUnlabelled + nnz(isnan(ACKCOUNT));
nanUnlabelled = nanUnlabelled + nnz(isnan(MISSION));

g3Nan = nanUnlabelled;

nDivergedTotal = nnz(DIVERGED);

% Completeness of the DIVERGED labelling, reported rather than gated: a
% new divergence criterion is not something to introduce after the fact,
% but a run that left the 50 m ball while staying finite and therefore
% escaped the label must be visible.
unlabelledFarRuns = nnz(MAXDEV > 50 & ~DIVERGED);


%% ============================================================
% GATE 4 - protocol invariants
% ============================================================

g4Invariants = sum(INVARIANTS(:), 'omitnan');

% Baselines must emit no ACK traffic. If one did, the ACK-inclusive cost
% model would be pricing a channel that method does not have.
baselineAck = sum(ACKCOUNT(:,[IDX_P10 IDX_P20 IDX_EVENT],:), 'all', 'omitnan');

% The ACK point changes only the reverse channel, which the three
% baselines do not have. Their runs there must therefore be
% BIT-IDENTICAL to their NOMINAL runs at the same seed and scenario.
% This is a leak detector: if cfg.ack.loss reached a baseline through
% some path, this is where it shows.
cNomMod = localFindCell(cellPoint, cellScen, pts, 'NOMINAL', sc.MODERATE);
cNomStr = localFindCell(cellPoint, cellScen, pts, 'NOMINAL', sc.STRESSED);
cAckMod = localFindCell(cellPoint, cellScen, pts, 'ACK',     sc.MODERATE);
cAckStr = localFindCell(cellPoint, cellScen, pts, 'ACK',     sc.STRESSED);

baseIdx = [IDX_P10 IDX_P20 IDX_EVENT];

ackLeak = 0;

ackLeak = ackLeak + ~isequaln( ...
    RMSE(:,baseIdx,cNomMod), RMSE(:,baseIdx,cAckMod));
ackLeak = ackLeak + ~isequaln( ...
    RMSE(:,baseIdx,cNomStr), RMSE(:,baseIdx,cAckStr));
ackLeak = ackLeak + ~isequaln( ...
    DATACOUNT(:,baseIdx,cNomMod), DATACOUNT(:,baseIdx,cAckMod));
ackLeak = ackLeak + ~isequaln( ...
    DATACOUNT(:,baseIdx,cNomStr), DATACOUNT(:,baseIdx,cAckStr));
ackLeak = ackLeak + ~isequaln( ...
    MINSEP(:,baseIdx,cNomMod), MINSEP(:,baseIdx,cAckMod));
ackLeak = ackLeak + ~isequaln( ...
    MINSEP(:,baseIdx,cNomStr), MINSEP(:,baseIdx,cAckStr));

g4Protocol = g4Invariants + baselineAck + ackLeak;


%% ============================================================
% Paired statistics - K1, K2a, K2b
% ============================================================

fprintf('  Paired key claims, Nominal Stressed (N=5, 6-DOF, ring2)\n\n');

cK = cNomStr;

K1 = pairedCI(RMSE(:,IDX_CAUSAL,cK),      RMSE(:,IDX_P10,cK),      numSeeds);

K2aCount = pairedCI(DATACOUNT(:,IDX_CAUSAL,cK), DATACOUNT(:,IDX_P20,cK), numSeeds);
K2aRate  = pairedCI(DATARATE(:,IDX_CAUSAL,cK),  DATARATE(:,IDX_P20,cK),  numSeeds);

K2bCount = pairedCI( ...
    DATACOUNT(:,IDX_CAUSAL,cK) + 0.25*ACKCOUNT(:,IDX_CAUSAL,cK), ...
    DATACOUNT(:,IDX_P20,cK)    + 0.25*ACKCOUNT(:,IDX_P20,cK), numSeeds);

K2bRate = pairedCI(TOTAL025(:,IDX_CAUSAL,cK), TOTAL025(:,IDX_P20,cK), numSeeds);

claimNames = { ...
    'K1  RMSE(Causal - P10)      [m]'; ...
    'K2a DATA(Causal - P20)      [packets]'; ...
    'K2a DATA(Causal - P20)      [Hz]'; ...
    'K2b DATA+0.25ACK (C - P20)  [packets]'; ...
    'K2b DATA+0.25ACK (C - P20)  [Hz]'};

claimStats = {K1; K2aCount; K2aRate; K2bCount; K2bRate};

fprintf('    %-38s %10s %10s %10s %6s %s\n', ...
    'Claim','mean d','CI lo','CI hi','nPair','verdict');

for q = 1:numel(claimNames)

    S = claimStats{q};

    fprintf('    %-38s %10.4f %10.4f %10.4f %3d/%-3d %s\n', ...
        claimNames{q}, S.meanD, S.lo, S.hi, S.nPairs, S.nRequested, S.verdict);

end

fprintf('\n');

% ---- K1 directional verdict ----
%
% PASS only when the whole interval is below zero. A CI containing zero
% is INCONCLUSIVE, never "nearly passed", and the pre-registration
% forbids adding seeds to move it.

if ~K1.complete

    k1Verdict = 'INCONCLUSIVE';
    k1Reason  = sprintf(['only %d of the pre-registered %d pairs were ' ...
        'usable, so the interval is not the pre-registered sample'], ...
        K1.nPairs, K1.nRequested);

elseif K1.hi < 0

    k1Verdict = 'SUPPORTED';
    k1Reason  = 'the whole 95 % interval lies below zero';

elseif K1.crossesZero

    k1Verdict = 'INCONCLUSIVE AT 50 SEEDS';
    k1Reason  = 'the 95 % interval contains zero';

else

    k1Verdict = 'REJECTED';
    k1Reason  = 'the whole 95 % interval lies above zero';

end

fprintf('    K1 directional hypothesis RMSE(Causal - P10) < 0 : %s\n', k1Verdict);
fprintf('       %s\n', k1Reason);

fprintf('\n    K2a and K2b carry NO directional gate by pre-registration.\n');
fprintf('    A DATA saving that an ACK-inclusive total reverses is not a\n');
fprintf('    communication saving; EXP07C established that and it stands.\n');

if K2aRate.meanD < 0 && K2bRate.meanD > 0
    fprintf('\n    NOTE: DATA falls but the ACK-inclusive total RISES. No\n');
    fprintf('    communication-saving claim may be made from this cell.\n');
elseif K2aRate.meanD < 0 && K2bRate.meanD < 0
    fprintf('\n    NOTE: both DATA and the ACK-inclusive total fall.\n');
else
    fprintf('\n    NOTE: DATA does not fall against P20 in this cell.\n');
end

allClaimsHaveStats = all(cellfun(@(S) isfield(S,'lo') && ~isempty(S.lo), claimStats));


%% ============================================================
% Gate verdict
% ============================================================

gateNames = { ...
    'G1 realization hashes match where they must', ...
    'G2 no missing rows, every seed used once', ...
    'G3 no unlabelled NaN', ...
    'G4 protocol invariants zero', ...
    'G5 every key claim carries paired statistics'};

gatePass = [ ...
    g1Hash == 0, ...
    (g2Missing == 0) && (g2SeedUse == 0), ...
    g3Nan == 0, ...
    g4Protocol == 0, ...
    allClaimsHaveStats];

gateVals = { ...
    sprintf('%d mismatch(es) over %d runs', g1Hash, nRun), ...
    sprintf('%d missing, %d cell(s) with a bad seed set', g2Missing, g2SeedUse), ...
    sprintf('%d unlabelled, %d labelled DIVERGED, %d far-but-unlabelled', ...
        g3Nan, nDivergedTotal, unlabelledFarRuns), ...
    sprintf('%d causal, %d baseline ACK, %d ACK-point leak', ...
        g4Invariants, baselineAck, ackLeak), ...
    sprintf('%d of %d claims', ...
        nnz(cellfun(@(S) isfield(S,'lo'), claimStats)), numel(claimStats))};

fprintf('\n');

for q = 1:numel(gateNames)
    if gatePass(q)
        st = 'PASS';
    else
        st = 'FAIL';
    end
    fprintf('  [%-5s] %-46s %s\n', st, gateNames{q}, gateVals{q});
end

if g1Hash > 0
    fprintf('\n  Hash mismatches (first 20):\n');
    for q = 1:min(20, numel(hashProblems))
        fprintf('    %s\n', hashProblems{q});
    end
end

fprintf('\n');

if all(gatePass)
    fprintf('  EXP10A INFRASTRUCTURE GATE: PASS (%d/%d)\n', ...
        numel(gateNames), numel(gateNames));
else
    fprintf('  EXP10A INFRASTRUCTURE GATE: %d of %d FAILED\n', ...
        nnz(~gatePass), numel(gateNames));
end

fprintf('  EXP10A SCIENTIFIC CLAIM K1: %s\n', k1Verdict);
fprintf('  Per the pre-registration, a K1 verdict of any kind is not a\n');
fprintf('  reason to re-run, retune or change the matrix.\n');


%% ============================================================
% Cell overview
%
% Every cell that was run, unfiltered, including the cells where
% Causal-v3 loses. Plan section 9 forbids dropping any of them.
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('All cells, mean over non-diverged seeds\n');
fprintf('============================================================\n\n');

fprintf('%-26s %-12s %8s %8s %8s %8s %8s %8s %5s\n', ...
    'Cell','Method','RMSE','minSep','SafeF%','DATA Hz','ACK Hz','T.w025','nDiv');

for c = 1:nCell

    for iM = 1:nMethod

        d = DIVERGED(:,iM,c);

        fprintf('%-26s %-12s %8.4f %8.4f %8.1f %8.2f %8.2f %8.2f %5d\n', ...
            cellLabel{c}, methodNames{iM}, ...
            localMeanFinite(RMSE(~d,iM,c)), ...
            localMeanFinite(MINSEP(~d,iM,c)), ...
            100*mean(SAFEFAIL(:,iM,c)), ...
            localMeanFinite(DATARATE(:,iM,c)), ...
            localMeanFinite(ACKRATE(:,iM,c)), ...
            localMeanFinite(TOTAL025(:,iM,c)), ...
            nnz(d));

    end

    fprintf('\n');

end


%% ============================================================
% Adaptivity, on the nominal point
%
% Reported here and gated in EXP10B. The three cells share their seeds
% and their channel uniforms, so the ordering is a statement about the
% network quality and not about the draw.
% ============================================================

cNomCln = localFindCell(cellPoint, cellScen, pts, 'NOMINAL', sc.CLEAN);

fprintf('============================================================\n');
fprintf('Adaptivity on the nominal point, Causal-v3\n');
fprintf('============================================================\n\n');

fprintf('  %-10s %10s %10s %10s %10s\n', ...
    'Scenario','DATA Hz','ACK Hz','Total.025','RMSE');

adaptCells = [cNomCln cNomMod cNomStr];

for q = 1:numel(adaptCells)

    cc = adaptCells(q);
    d  = DIVERGED(:,IDX_CAUSAL,cc);

    fprintf('  %-10s %10.2f %10.2f %10.2f %10.4f\n', ...
        sc.names{cellScen(cc)}, ...
        localMeanFinite(DATARATE(:,IDX_CAUSAL,cc)), ...
        localMeanFinite(ACKRATE(:,IDX_CAUSAL,cc)), ...
        localMeanFinite(TOTAL025(:,IDX_CAUSAL,cc)), ...
        localMeanFinite(RMSE(~d,IDX_CAUSAL,cc)));

end

adaptData = arrayfun(@(cc) localMeanFinite(DATARATE(:,IDX_CAUSAL,cc)), adaptCells);

adaptOrdered = all(diff(adaptData) > 0);

fprintf('\n  Clean < Moderate < Stressed on Causal DATA : %s\n', ...
    localYesNo(adaptOrdered));


%% ============================================================
% Tidy dataset
%
% This file IS the EXP10 dataset. EXP10B reads it and runs no second
% stochastic experiment, so the unified matrix and every claim in it
% describe this realization and no other.
% ============================================================

[SG, MG, CG] = ndgrid(1:numSeeds, 1:nMethod, 1:nCell);

sIdx = SG(:);
mIdx = MG(:);
cIdx = CG(:);

pIdx = cellPoint(cIdx)';
scIdx = cellScen(cIdx)';

T = table();

T.point    = arrayfun(@(k) pts(k).id,       pIdx, 'UniformOutput', false);
T.pointN   = arrayfun(@(k) pts(k).N,        pIdx);
T.plant    = arrayfun(@(k) pts(k).plant,    pIdx, 'UniformOutput', false);
T.topology = arrayfun(@(k) pts(k).topology, pIdx, 'UniformOutput', false);
T.family   = arrayfun(@(k) pts(k).family,   pIdx, 'UniformOutput', false);
T.kind     = arrayfun(@(k) pts(k).kind,     pIdx, 'UniformOutput', false);

T.scenario = sc.names(scIdx);

T.method = methodNames(mIdx);

T.seedIndex = sIdx;
T.seed      = SEEDVALUE(:);

T.RMSE     = RMSE(:);
T.MINSEP   = MINSEP(:);
T.SAFEFAIL = double(SAFEFAIL(:));
T.DIVERGED = double(DIVERGED(:));

T.DATACOUNT  = DATACOUNT(:);
T.ACKCOUNT   = ACKCOUNT(:);
T.BCASTCOUNT = BCASTCOUNT(:);
T.MISSION    = MISSION(:);

T.DATARATE  = DATARATE(:);
T.ACKRATE   = ACKRATE(:);
T.BCASTRATE = BCASTRATE(:);

T.TOTAL010 = TOTAL010(:);
T.TOTAL025 = TOTAL025(:);
T.TOTAL050 = TOTAL050(:);

T.AIRTIME       = AIRTIME(:);
T.BROADCASTCOST = BROADCASTCOST(:);

T.TRUEAOI = TRUEAOI(:);
T.ESTAOI  = ESTAOI(:);

T.HARDRATIO    = HARDR(:);
T.ADAPTRATIO   = ADAPTR(:);
T.REFRESHRATIO = REFRESHR(:);
T.MAXINTERTXGAP = MAXGAP(:);

T.SATURATION = SATURATE(:);
T.EFFORT     = EFFORT(:);
T.ROLLPEAK   = ROLLPK(:);
T.PITCHPEAK  = PITCHPK(:);
T.MASSRATIO  = MASSRAT(:);
T.DRAGRATIO  = DRAGRAT(:);
T.ESTERR     = ESTERR(:);

T.CONNECTED = double(CONNECTED(:));
T.LAMBDA2   = LAMBDA2(:);
T.ISOLATED  = ISOLATED(:);
T.INDEGMIN  = INDEGMIN(:);

T.FWDHASH    = FWDHASH(:);
T.ACKHASH    = ACKHASH(:);
T.FWDHASHX   = FWDHASHX(:);
T.ACKHASHX   = ACKHASHX(:);
T.PHASEHASH  = PHASEHASH(:);
T.FAULTHASH  = FAULTHASH(:);
T.BLACKHASH  = BLACKHASH(:);
T.EXTHASH    = EXTHASH(:);
T.NOISEHASH  = NOISEHASH(:);
T.EXTHASHX   = EXTHASHX(:);
T.NOISEHASHX = NOISEHASHX(:);

T.INVARIANTS = INVARIANTS(:);
T.MAXDEV     = MAXDEV(:);

writetable(T, fullfile(expRun.dir,'tidy.csv'));

fprintf('\ntidy.csv : %d rows x %d columns\n', height(T), width(T));

if height(T) ~= nRun
    fprintf(2, 'ROW COUNT MISMATCH: %d rows for %d runs\n', height(T), nRun);
end


%% ============================================================
% Figures
% ============================================================

figure('Name','EXP10A K1 paired difference');
dK1 = RMSE(:,IDX_CAUSAL,cNomStr) - RMSE(:,IDX_P10,cNomStr);
histogram(dK1, 12);
hold on;
xline(0,'k--','LineWidth',1.2);
xline(K1.meanD,'r-','LineWidth',1.5);
xline(K1.lo,'r:','LineWidth',1.2);
xline(K1.hi,'r:','LineWidth',1.2);
grid on;
xlabel('RMSE(Causal-v3) - RMSE(P10)  [m], per seed');
ylabel('seeds');
title(sprintf('K1 Nominal Stressed: mean %.4f, CI [%.4f, %.4f]', ...
    K1.meanD, K1.lo, K1.hi));

figure('Name','EXP10A K2 paired difference');
dK2a = DATARATE(:,IDX_CAUSAL,cNomStr) - DATARATE(:,IDX_P20,cNomStr);
dK2b = TOTAL025(:,IDX_CAUSAL,cNomStr) - TOTAL025(:,IDX_P20,cNomStr);
plot(1:numSeeds, dK2a, 'o-', 'LineWidth',1.0); hold on;
plot(1:numSeeds, dK2b, 's-', 'LineWidth',1.0);
yline(0,'k--','LineWidth',1.2);
grid on;
xlabel('seed index');
ylabel('paired difference vs P20  [Hz]');
legend({'K2a DATA','K2b DATA + 0.25 ACK'},'Location','best');
title('K2 Nominal Stressed: DATA versus ACK-inclusive total');

figure('Name','EXP10A cost versus error, all cells');
markers = {'o','s','^','d'};
for iM = 1:nMethod
    xs = zeros(nCell,1);
    ys = zeros(nCell,1);
    for c = 1:nCell
        d = DIVERGED(:,iM,c);
        xs(c) = localMeanFinite(TOTAL025(:,iM,c));
        ys(c) = localMeanFinite(RMSE(~d,iM,c));
    end
    plot(xs, ys, markers{iM}, 'MarkerSize',7, 'LineWidth',1.2, ...
        'DisplayName', methodNames{iM});
    hold on;
end
grid on;
xlabel('cost, DATA + 0.25 ACK  [Hz]');
ylabel('formation RMSE  [m]');
legend('Location','best');
title('EXP10A every cell, no filtering');


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
%LOCALMEANFINITE Mean over the finite entries, NaN when there are none.

v = v(isfinite(v));

if isempty(v)
    m = NaN;
else
    m = mean(v);
end

end


function s = localYesNo(tf)

if tf
    s = 'yes';
else
    s = 'NO';
end

end


function c = localFindCell(cellPoint, cellScen, pts, pointId, iScenario)
%LOCALFINDCELL Index of the (point, scenario) cell, or an error.
%
% An error rather than an empty result: a claim that silently pointed at
% no cell would report NaN statistics that looked like a finding.

ids = arrayfun(@(k) pts(k).id, cellPoint, 'UniformOutput', false);

hit = find(strcmp(ids, pointId) & cellScen == iScenario);

if numel(hit) ~= 1
    error('exp10a:cellLookup', ...
        'Expected exactly one %s cell at scenario %d, found %d.', ...
        pointId, iScenario, numel(hit));
end

c = hit;

end


function problems = localCheckPerturbHash( ...
    problems, name, observed, expected, pointUsesIt, label, seedValue)
%LOCALCHECKPERTURBHASH One perturbation realization, across the methods.
%
% Two distinct failures are separated here:
%
%   a point that USES the perturbation must show the registry hash on
%   every one of its four methods - otherwise the methods did not meet
%   the same fault
%
%   a point that does NOT use it must show NaN - otherwise a
%   perturbation leaked into a cell that was supposed to be clean, which
%   would be invisible in the metrics

if pointUsesIt

    if any(observed ~= expected) || any(isnan(observed))
        problems{end+1} = sprintf( ...
            '%s seed %d: %s realization is not the registry value on all methods', ...
            label, seedValue, name);
    end

else

    if any(~isnan(observed))
        problems{end+1} = sprintf( ...
            '%s seed %d: %s realization leaked into a point that does not use it', ...
            label, seedValue, name);
    end

end

end
