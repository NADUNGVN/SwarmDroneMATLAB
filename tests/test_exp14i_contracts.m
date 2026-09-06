%% TEST_EXP14I_CONTRACTS Frozen MAC-selective design checks without holdout seeds.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp14i_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

R=exp14iRegistry();
[registryHash,registryLeaves]=configHash(R);
checks(end+1,:)={registryHash==84940762 && registryLeaves==52 && ...
    R.expectedRuns==1600 && R.primaryFamilySize==6, ...
    'registry hash, leaves, matrix and Holm family are frozen'};

known=[exp14Registry().seeds; exp14cRegistry().seeds; ...
    exp14dRegistry().seeds; exp14eRegistry().seeds; exp14fRegistry().seeds; ...
    exp14gRegistry().seeds; exp14hRegistry().seeds; ...
    (25000001:25000050)'];
checks(end+1,:)={numel(unique(R.seeds))==100 && ...
    isempty(intersect(R.seeds,known)), ...
    '100 holdout seeds are unique and disjoint from known blocks'};

expectedHashes=[104375075 113323631 139135489 104815675];
for k=1:numel(R.cells)
    cfg=applyExp14ICell(R.cells(k).id,0);
    [h,nLeaf]=configHash(cfg);
    checks(end+1,:)={h==expectedHashes(k) && nLeaf>=104, ...
        sprintf('%s seed-zero base configuration is frozen',R.cells(k).label)};
end

checks(end+1,:)={isequal(R.primaryCells, ...
    {'n5-csma','n10-ring2','n5-aloha'}) && ...
    isequal(R.boundaryCells,{'n20-ring2'}) && ...
    ~R.n20CausalClaimPermitted && ~R.equivalenceClaimPermitted && ...
    ~R.universalMacClaimPermitted, ...
    'claim family and N20/universal ceilings are frozen'};

% Smoke and exact-route identity use a development seed, never holdout seeds.
for c=1:numel(R.cells)
    base=applyExp14ICell(R.cells(c).id,16020999);
    base.swarm.T=0.30; base.shared.evalStart=0;
    trace=generateSharedMediumTrace(base);
    out=cell(numel(R.arms),1); routes=strings(numel(R.arms),1);
    modes=strings(numel(R.arms),1); methods=strings(numel(R.arms),1);
    for k=1:numel(R.arms)
        [cfg,method,~,route]=applyExp14IArm(base,R.arms(k));
        out{k}=simSwarmSharedMedium(cfg,method,trace);
        routes(k)=route; modes(k)=out{k}.feedbackMode; methods(k)=method;
    end
    candidate=out{1};
    if strcmp(R.cells(c).macType,'csma')
        reference=out{3}; expectedRoute="piggyback";
    else
        reference=out{2}; expectedRoute="adaptive";
    end
    exact=isequaln(candidate.P,reference.P) && ...
        isequaln(candidate.V,reference.V) && ...
        isequaln(candidate.dataAttemptLog,reference.dataAttemptLog) && ...
        isequaln(candidate.ackAttemptLog,reference.ackAttemptLog) && ...
        candidate.traceHashExact==reference.traceHashExact && ...
        candidate.invariantViolations==0;
    checks(end+1,:)={routes(1)==expectedRoute && exact, ...
        sprintf('%s candidate is the exact routed reference',R.cells(c).label)};
    checks(end+1,:)={routes(2)=="adaptive" && modes(2)=="adaptive" && ...
        routes(3)=="piggyback" && modes(3)=="piggyback" && ...
        routes(4)=="access-only" && modes(4)=="hybrid" && ...
        (methods(1)=="causal-broadcast" || ...
        methods(1)=="mac-aware-broadcast"), ...
        sprintf('%s comparator feedback contracts execute',R.cells(c).label)};
end

unknownArm=false;
try
    cfg=applyExp14ICell('n5-csma',16020999);
    fake=R.arms(1); fake.id='post-hoc-arm';
    applyExp14IArm(cfg,fake);
catch
    unknownArm=true;
end
checks(end+1,:)={unknownArm,'unknown arms fail at the interface boundary'};

unknownMac=false;
try
    cfg=applyExp14ICell('n5-csma',16020999);
    cfg.mac.type='tdma';
    applyExp14IArm(cfg,R.arms(1));
catch
    unknownMac=true;
end
checks(end+1,:)={unknownMac, ...
    'selector refuses an unregistered MAC rather than extrapolating'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp14i_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp14i_contracts: PASS (%d checks)\n',numel(flags));
