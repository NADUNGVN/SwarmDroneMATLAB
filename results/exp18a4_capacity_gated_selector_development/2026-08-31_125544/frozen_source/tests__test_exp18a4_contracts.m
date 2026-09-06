%% TEST_EXP18A4_CONTRACTS Exact fixed-route alias contracts.

startup;

fprintf('\n============================================================\n');
fprintf('test_exp18a4_contracts\n');
fprintf('============================================================\n\n');

checks=cell(0,2);
R=exp18a4Registry();
checks(end+1,:)={R.expectedRuns==400 && R.requireExactAlias && ...
    numel(R.aliasFields)==17 && ~R.confirmatory, ...
    'v4 is a development-only exact-alias selector contract'};

cases={ ...
    'n5-moderate-bg0','csma','frame-piggyback'; ...
    'n5-moderate-bg0','aloha','frame-adaptive'; ...
    'n10-moderate-bg0','aloha','frame-piggyback'};
for k=1:size(cases,1)
    cellId=cases{k,1}; macType=cases{k,2}; referenceArm=cases{k,3};
    base=applyExp18Cell(cellId,R.seeds(1));
    base.mac.type=macType; base.mac.pAccess=min(0.20,1/base.swarm.N);
    base.swarm.T=0.8; base.shared.evalStart=0; base.sixdof.enable=false;
    trace=generateSharedMediumTrace(base);
    [cfg,method,label,details,cert]=applyExp18A4Arm(base);
    meta=struct('stage','development-amendment-4','scenario',cellId, ...
        'scenarioLabel',cellId,'family','EXP18A4 test', ...
        'arm',R.arm.id,'pointIndex',1,'parameterValue',0, ...
        'role','core','channel','moderate','modifier','nominal', ...
        'basePAccess',base.mac.pAccess);
    candidate=runExp18A4Cell(cfg,method,label,meta,trace,details,cert);
    E=exp18Registry(); refArm=E.arms(strcmp({E.arms.id},referenceArm));
    [refCfg,refMethod,refLabel,refDetails]=applyExp18Arm(base,refArm);
    refMeta=meta; refMeta.arm=referenceArm;
    reference=runExp18Cell(refCfg,refMethod,refLabel, ...
        refMeta,trace,refDetails);
    d=0;
    for f=1:numel(R.aliasFields)
        name=R.aliasFields{f};
        d=max(d,abs(candidate.(name)-reference.(name)));
    end
    checks(end+1,:)={d==0 && ...
        isequal(fieldnames(candidate),fieldnames(exp18a4EmptyRow())), ...
        sprintf('%s/%s aliases %s exactly',cellId,macType,referenceArm)};
end

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp18a4_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp18a4_contracts: PASS (%d checks)\n',numel(flags));
