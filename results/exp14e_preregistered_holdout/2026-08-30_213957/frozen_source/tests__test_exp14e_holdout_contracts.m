%% TEST_EXP14E_HOLDOUT_CONTRACTS Frozen design checks without holdout seeds.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp14e_holdout_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

R=exp14eRegistry();
[registryHash,registryLeaves]=configHash(R);
checks(end+1,:)={registryHash==87778193 && registryLeaves==58 && ...
    R.expectedRuns==2800,'registry hash, leaves and run count are frozen'};

R14=exp14Registry(); C=exp14cRegistry(); D=exp14dRegistry();
disjoint=isempty(intersect(R.seeds,R14.seeds)) && ...
    isempty(intersect(R.seeds,C.seeds)) && ...
    isempty(intersect(R.seeds,D.seeds)) && ...
    isempty(intersect(R.seeds,(25000001:25000050)'));
checks(end+1,:)={numel(unique(R.seeds))==100 && disjoint, ...
    '100 holdout seeds are unique and disjoint from known blocks'};

expectedHashes=[104373580 113322136 139133994 104814180];
for k=1:numel(R.cells)
    cfg=applyExp14ECell(R.cells(k).id,0);
    [h,nLeaf]=configHash(cfg);
    checks(end+1,:)={h==expectedHashes(k) && nLeaf>=104, ...
        sprintf('%s seed-zero base configuration is frozen',R.cells(k).label)};
end

checks(end+1,:)={numel(R.primaryCells)*numel(R.primaryMetrics)==6 && ...
    R.familywiseAlpha==0.05 && R.bootstrapReplicates==10000, ...
    'six primary Holm tests and deterministic bootstrap are frozen'};

holmInput=[0.03 0.001 0.01 NaN];
holmExpected=[0.06 0.004 0.03 1];
checks(end+1,:)={max(abs(holmAdjustP(holmInput)-holmExpected))<1e-12, ...
    'Holm step-down adjustment is deterministic and shape preserving'};

unknown=false;
try
    x=applyExp14ECell('n5-csma',16017999);
    fake=R.arms(1); fake.id='post-hoc-arm';
    applyExp14EArm(x,fake);
catch
    unknown=true;
end
checks(end+1,:)={unknown,'unknown holdout arms fail at the boundary'};

% Smoke every arm only on a development seed. One absolute trace is reused.
base=applyExp14ECell('n20-ring2',16017999);
base.swarm.T=0.25; base.shared.evalStart=0;
trace=generateSharedMediumTrace(base);
actualP=nan(numel(R.arms),1); modes=strings(numel(R.arms),1);
methods=strings(numel(R.arms),1); finiteRun=true;
guardCount=nan(numel(R.arms),1);
for k=1:numel(R.arms)
    [cfg,method]=applyExp14EArm(base,R.arms(k));
    out=simSwarmSharedMedium(cfg,method,trace);
    actualP(k)=out.pAccess; modes(k)=out.feedbackMode; methods(k)=method;
    guardCount(k)=sum(out.policy.loadGuardBlockedByBranch);
    finiteRun=finiteRun && all(isfinite(out.P(:))) && ...
        out.invariantViolations==0;
end
expectedP=0.05*ones(numel(R.arms),1); expectedP(3)=0.20;
checks(end+1,:)={finiteRun && max(abs(actualP-expectedP))<1e-12, ...
    'all arms execute and only historical hybrid retains p=0.2 at N20'};
checks(end+1,:)={modes(1)=="adaptive" && modes(2)=="hybrid" && ...
    modes(3)=="hybrid" && modes(4)=="piggyback" && ...
    modes(5)=="none" && modes(6)=="hybrid" && modes(7)=="none", ...
    'all seven feedback contracts match the frozen registry'};
checks(end+1,:)={methods(1)=="mac-aware-broadcast" && ...
    methods(5)=="state-event" && methods(6)=="delayed-ack-belief" && ...
    methods(7)=="periodic" && guardCount(1)==0, ...
    'selected and literature-baseline method semantics are exact'};

selected=applyExp14ECell('n10-ring2',16017999);
[selected,~,~]=applyExp14EArm(selected,R.arms(1));
checks(end+1,:)={selected.shared.macAware.accessScalingEnabled && ...
    ~selected.shared.macAware.loadGuardEnabled && ...
    strcmp(selected.shared.feedbackMode,'adaptive'), ...
    'candidate is exactly EXP14D a1-g0-s1'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp14e_holdout_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp14e_holdout_contracts: PASS (%d checks)\n',numel(flags));
