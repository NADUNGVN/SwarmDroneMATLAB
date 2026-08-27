function reg = exp10Registry(seedList, Nlist, verbose)
%EXP10REGISTRY Master CRN realizations for the EXP10 holdout seeds.
%
%   reg = exp10Registry(seedList, Nlist)
%
% Plan section 5: every EXP10 seed carries ONE immutable set of master
% realizations - forward network trace, reverse ACK trace, transmission
% phase, link-fault realization, node-blackout realization, external-
% force trace and estimator-noise trace - and every method that runs at
% that seed must meet exactly those.
%
% This function computes the hash of each of them, ONCE per (N, seed),
% before any simulation runs. EXP10A then compares the hash each run
% actually consumed against this table. That ordering matters: the check
% is against a value fixed in advance, not against a value re-derived
% from the same code inside the same loop, which would only prove the
% code is deterministic.
%
% Every realization is computed for every seed, whether or not the point
% that uses that seed needs it. Plan section 5 allows exactly this: an
% unused realization may exist provided it cannot perturb another one.
% Each generator draws from its own RandStream seeded by cfg.net.seed
% plus a distinct offset, so drawing an unused trace consumes nothing
% from any other, and assertExp10Seeds proves the offsets keep the seven
% streams disjoint.
%
% WHY THE TABLE IS KEYED BY N AS WELL AS BY SEED
%
% The forward and reverse traces are shaped (K x N x N) and the fault
% and blackout realizations are drawn over the graph, so a given seed
% produces a DIFFERENT realization at N = 5, N = 20 and N = 50. Hash
% equality is therefore required within a point across methods, and is
% meaningless across points of different N. Keying the table by N makes
% that explicit rather than leaving it to be remembered.

if nargin < 2 || isempty(Nlist)
    Nlist = unique([exp10Points().N]);
end

if nargin < 3 || isempty(verbose)
    verbose = true;
end

seedList = seedList(:);
Nlist    = unique(Nlist(:));

nSeed = numel(seedList);
nN    = numel(Nlist);

reg.seeds = seedList;
reg.N     = Nlist;

types = {'fwd','ack','phase','link','blackout','extForce','noise', ...
         'fwdX','ackX','extForceX','noiseX','master'};

% The 'X' columns are the EXACT hashes. The plain fwd/ack/extForce/noise
% columns are the LOCKED generator hashes, which are not thread-stable
% because they sum millions of floats past 2^53 - the same realization
% hashes differently in the multithreaded client than on a
% single-threaded pool worker. EXP10 gates on the X columns and reports
% the locked ones. phase, link and blackout have only one hash each,
% already exact, because they were added with EXP10.

for c = 1:numel(types)
    reg.(types{c}) = nan(nSeed, nN);
end

% The perturbation magnitudes the registry draws at. They must match
% applyExp10Point exactly, or the registry would be a table of
% realizations nothing ever used.
LINK_FRACTION  = 0.20;
BLACKOUT_NODES = 1;
BLACKOUT_SECS  = 5.0;
EXT_LEVEL      = 0.5;
NOISE_POS      = 0.03;
NOISE_VEL      = 0.05;

if verbose
    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('EXP10 master realization registry\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('  %d seeds x %d swarm sizes, 7 realization types\n', nSeed, nN);
end

for iN = 1:nN

    N = Nlist(iN);

    fwdH  = nan(nSeed,1);
    ackH  = nan(nSeed,1);
    phH   = nan(nSeed,1);
    lnkH  = nan(nSeed,1);
    blkH  = nan(nSeed,1);
    extH  = nan(nSeed,1);
    nseH  = nan(nSeed,1);
    fwdXH = nan(nSeed,1);
    ackXH = nan(nSeed,1);
    extXH = nan(nSeed,1);
    nseXH = nan(nSeed,1);
    mstH  = nan(nSeed,1);

    parfor s = 1:nSeed

        cfg = applyTopologyConfig(defaultConfig(), N, 'ring2');

        cfg.net.seed = seedList(s);

        fwd = generateNetworkTrace(cfg);
        rev = generateAckTrace(cfg);
        ph  = generatePhaseTrace(cfg);

        lnk = generateFaultRealization(cfg, 'permanent', LINK_FRACTION);
        blk = generateBlackoutRealization(cfg, BLACKOUT_NODES, BLACKOUT_SECS);
        ext = generateExternalForceTrace(cfg, EXT_LEVEL);
        nse = generateNoiseTrace(cfg, NOISE_POS, NOISE_VEL);

        fwdH(s) = fwd.hash;
        ackH(s) = rev.hash;
        phH(s)  = ph.hash;
        lnkH(s) = lnk.hash;
        blkH(s) = blk.hash;
        extH(s) = ext.hash;
        nseH(s) = nse.hash;

        fwdXH(s) = fwd.hashExact;
        ackXH(s) = rev.hashExact;
        extXH(s) = ext.hashExact;
        nseXH(s) = nse.hashExact;

        % The master hash folds only EXACT hashes, so it is itself
        % thread-stable and CSV-safe.
        mstH(s) = realizationHash([ ...
            fwd.hashExact; rev.hashExact; ph.hash; ...
            lnk.hash; blk.hash; ext.hashExact; nse.hashExact]);

    end

    reg.fwd(:,iN)      = fwdH;
    reg.ack(:,iN)      = ackH;
    reg.phase(:,iN)    = phH;
    reg.link(:,iN)     = lnkH;
    reg.blackout(:,iN) = blkH;
    reg.extForce(:,iN) = extH;
    reg.noise(:,iN)    = nseH;

    reg.fwdX(:,iN)      = fwdXH;
    reg.ackX(:,iN)      = ackXH;
    reg.extForceX(:,iN) = extXH;
    reg.noiseX(:,iN)    = nseXH;

    reg.master(:,iN)   = mstH;

    if verbose
        fprintf('  N = %-3d  master hashes drawn for %d seeds\n', N, nSeed);
    end

end


%% ============================================================
% Distinctness
%
% "A different seed gives a different realization" is a requirement for
% the CONTINUOUS realizations: two holdout seeds that produced the same
% channel trace would put a duplicate in the paired sample and the
% confidence interval would be narrower than the evidence justifies.
%
% It is NOT a requirement for the two DISCRETE realizations. Which links
% go down and which node goes dark are draws from a small finite set -
% at N = 5 the ring graph has 8 directed links and a 20 % removal downs
% exactly 2 of them, so there are only 28 possible link realizations at
% all. Two seeds landing on the same pattern is a property of the
% intervention, not a collision, and it duplicates nothing: those two
% seeds still meet different channels, different phase and different
% noise. Their cardinality is reported instead, so a suspiciously small
% number is visible rather than gated on the wrong side.
% ============================================================

% 'master' is deliberately NOT gated. It folds only seven numbers, so its
% range is far narrower than the per-type hashes it summarises and two
% seeds could collide in it while every underlying realization differs -
% a spurious failure. It exists as a one-line comparison for the
% environment manifest; the per-type hashes below are the actual check.
continuousTypes = {'fwdX','ackX','phase','extForceX','noiseX'};
discreteTypes   = {'link','blackout'};

reg.distinct = true;
reg.duplicateDetail = {};
reg.discreteDetail  = {};

for iN = 1:nN

    for c = 1:numel(continuousTypes)

        v = reg.(continuousTypes{c})(:,iN);

        if numel(unique(v)) < nSeed
            reg.duplicateDetail{end+1} = sprintf( ...
                'N=%d %s: %d distinct hashes over %d seeds', ...
                reg.N(iN), continuousTypes{c}, numel(unique(v)), nSeed);
            reg.distinct = false;
        end

    end

    for c = 1:numel(discreteTypes)

        v = reg.(discreteTypes{c})(:,iN);

        reg.discreteDetail{end+1} = sprintf( ...
            'N=%d %s: %d distinct pattern(s) over %d seeds', ...
            reg.N(iN), discreteTypes{c}, numel(unique(v)), nSeed);

    end

end

if verbose

    if reg.distinct
        fprintf('  [PASS ] every seed has a distinct continuous realization\n');
    else
        fprintf('  [FAIL ] continuous realization collisions:\n');
        for d = 1:numel(reg.duplicateDetail)
            fprintf('           %s\n', reg.duplicateDetail{d});
        end
    end

    fprintf('  [INFO ] discrete fault realizations draw from a finite set:\n');
    for d = 1:numel(reg.discreteDetail)
        fprintf('           %s\n', reg.discreteDetail{d});
    end

end

end
