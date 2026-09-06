%% TEST_EXP17_CONTRACTS Frozen envelope checks without holdout seeds.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp17_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

R=exp17Registry();
[registryHash,registryLeaves]=configHash(R);
checks(end+1,:)={registryHash==123727884 && registryLeaves==122 && ...
    R.expectedRuns==4000 && R.primaryFamilySize==48, ...
    'registry hash, 4000-run matrix and 48-test family are frozen'};

known=[exp14Registry().seeds; exp14cRegistry().seeds; ...
    exp14dRegistry().seeds; exp14eRegistry().seeds; exp14fRegistry().seeds; ...
    exp14gRegistry().seeds; exp14hRegistry().seeds; exp14iRegistry().seeds; ...
    exp16Registry().seeds; (25000001:25000050)'];
checks(end+1,:)={numel(unique(R.seeds))==100 && ...
    isempty(intersect(R.seeds,known)) && ...
    ~ismember(R.developmentSeed,R.seeds), ...
    'holdout seeds are unique/disjoint and smoke seed is excluded'};

checks(end+1,:)={numel(R.coreCells)==8 && numel(R.boundaryCells)==2 && ...
    numel(R.arms)==4 && R.continuation.minCoreSupported==6, ...
    'eight core, two boundary and frozen continuation rule are declared'};

expectedHashes=[105942160 106159387 104215912 104433139 ...
    114729584 114946869 113003364 113220649 106651714 105963343];
for k=1:numel(R.cells)
    cfg=applyExp17Cell(R.cells(k).id,R.developmentSeed);
    [h,nLeaf]=configHash(cfg);
    checks(end+1,:)={h==expectedHashes(k) && nLeaf==107, ...
        sprintf('%s development configuration is frozen',R.cells(k).label)};
end

% Short semantic smoke cases use only the development seed.
for c=1:numel(R.cells)
    base=applyExp17Cell(R.cells(c).id,R.developmentSeed);
    base.swarm.T=0.25; base.shared.evalStart=0;
    trace=generateSharedMediumTrace(base);
    hashes=zeros(numel(R.arms),1); states=zeros(numel(R.arms),1);
    for k=1:numel(R.arms)
        arm=R.arms(k);
        [cfg,method]=applyExp17Arm(base,arm);
        out=simSwarmSharedMedium(cfg,method,trace);
        hashes(k)=out.traceHashExact; states(k)=out.channelStateHash;
        if strcmp(arm.route,'adaptive')
            routeOk=strcmp(out.feedbackMode,'adaptive') && ...
                strcmp(out.method,'mac-aware-broadcast');
        else
            routeOk=strcmp(out.feedbackMode,'piggyback') && ...
                strcmp(out.method,'causal-broadcast') && ...
                out.netStats.ackFramesStandalone==0;
        end
        checks(end+1,:)={routeOk && strcmp(cfg.mac.type,arm.macType) && ...
            abs(out.pAccess-min(0.20,1/cfg.swarm.N))<1e-12 && ...
            out.invariantViolations==0, ...
            sprintf('%s/%s executes exact factor semantics', ...
            R.cells(c).id,arm.id)};
    end
    checks(end+1,:)={isscalar(unique(hashes)) && isscalar(unique(states)), ...
        sprintf('%s shares one trace across both MAC levels',R.cells(c).id)};
end

unknown=false;
try
    applyExp17Cell('post-hoc-context',R.developmentSeed);
catch
    unknown=true;
end
checks(end+1,:)={unknown,'unknown contexts fail closed'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp17_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp17_contracts: PASS (%d checks)\n',numel(flags));

