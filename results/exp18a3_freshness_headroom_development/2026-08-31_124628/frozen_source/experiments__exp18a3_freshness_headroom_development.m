function exp18a3_freshness_headroom_development()
%EXP18A3_FRESHNESS_HEADROOM_DEVELOPMENT Development-only v3 amendment.

startup;
close all;
runScriptIsolated('test_context_aware_policy');
runScriptIsolated('test_exp18a3_contracts');
runScriptIsolated('test_exp18a3_analysis_contracts');
R=exp18a3Registry();
referencePath=fullfile(R.referenceRun,'tidy.csv');
if exist(referencePath,'file')~=2
    error('exp18a3: canonical EXP18A reference is missing.');
end
[registryHash,registryLeaves]=configHash(R);
expRun=startExperiment('exp18a3_freshness_headroom_development', ...
    ['Development amendment: service abstention plus parameter-free ' ...
    'freshness-headroom marginal ACK value.']);
writeJson(fullfile(expRun.dir,'development_registry.json'),R);
writeJson(fullfile(expRun.dir,'development_opened.json'),struct( ...
    'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'developmentOnly',true,'confirmatoryClaimPermitted',false, ...
    'referenceRun',R.referenceRun,'futureHoldoutOpened',false));
snapshotSource(expRun.dir);

[groupSeed,groupCell,groupMac]=groups(R);
rows=repmat(exp18a3EmptyRow(),0,1);
batchSize=16;
for first=1:batchSize:numel(groupSeed)
    last=min(first+batchSize-1,numel(groupSeed));
    indices=first:last;
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),16)
        g=indices(q);
        batch{q}=runGroup(groupSeed(g),groupCell(g),groupMac(g),R);
    end
    rows=[rows; vertcat(batch{:})]; %#ok<AGROW>
    writeTableAtomic(struct2table(rows), ...
        fullfile(expRun.dir,'tidy_checkpoint.csv'));
    fprintf('  groups %4d--%4d / %4d; rows %3d / %3d\n', ...
        first,last,numel(groupSeed),numel(rows),R.expectedRuns);
end

tidy=struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
reference=readtable(referencePath,'TextType','string');
gates=integrityGates(tidy,reference,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
integrityVerdict=struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'totalRuns',height(tidy),'developmentOnly',true, ...
    'futureHoldoutOpened',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP18A3 integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-38s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp18A3Development(expRun.dir);
    fprintf('\nEXP18A3 DEVELOPMENT VERDICT: %s (%d/%d gates)\n', ...
        analysis.verdict.status,analysis.verdict.gatesPassed, ...
        analysis.verdict.gatesTotal);
else
    analysis=struct();
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp18a3_freshness_headroom_development: integrity failure.');
end

end


function row=runGroup(seedValue,cellIndex,macIndex,R)

c=R.cells(cellIndex);
base=applyExp18Cell(c.id,seedValue);
base.mac.type=R.macTypes{macIndex};
base.mac.pAccess=min(0.20,1/base.swarm.N);
base.mac=sharedMediumConfig(base);
trace=generateSharedMediumTrace(base);
[cfg,method,label,details,certificate]=applyExp18A3Arm(base);
meta=struct('stage','development-amendment-3','scenario',c.id, ...
    'scenarioLabel',c.label,'family','EXP18A3 freshness headroom', ...
    'arm',R.arm.id,'pointIndex',1,'parameterValue',c.background, ...
    'role',c.role,'channel',c.channel,'modifier',c.modifier, ...
    'basePAccess',base.mac.pAccess);
row=runExp18A3Cell(cfg,method,label,meta,trace,details,certificate);

end


function [seeds,cells,macs]=groups(R)

n=R.expectedRuns;
seeds=zeros(n,1); cells=zeros(n,1); macs=zeros(n,1); q=0;
for i=1:numel(R.seeds)
    for j=1:numel(R.cells)
        for m=1:numel(R.macTypes)
            q=q+1; seeds(q)=R.seeds(i); cells(q)=j; macs(q)=m;
        end
    end
end

end


function gates=integrityGates(T,reference,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
E=exp18Registry();
[names,passed,detail]=addGate(names,passed,detail,'registry_recorded', ...
    isfinite(registryHash) && registryLeaves>0, ...
    sprintf('development hash %.0f over %d leaves', ...
    registryHash,registryLeaves));
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d amendment runs',height(T)));
keys=string(T.seed)+"|"+string(T.scenario)+"|"+string(T.macType);
[names,passed,detail]=addGate(names,passed,detail,'unique_rows', ...
    numel(unique(keys))==height(T),'one row per seed/context/MAC');

traceMatch=true;
for k=1:height(T)
    Q=reference(reference.seed==T.seed(k) & ...
        reference.scenario==string(T.scenario(k)) & ...
        reference.macType==string(T.macType(k)),:);
    traceMatch=traceMatch && height(Q)==numel(E.arms) && ...
        isscalar(unique(Q.TRACE_HASH_EXACT)) && ...
        T.TRACE_HASH_EXACT(k)==Q.TRACE_HASH_EXACT(1) && ...
        T.CHANNEL_STATE_HASH(k)==Q.CHANNEL_STATE_HASH(1) && ...
        T.ESTIMATOR_HASH_EXACT(k)==Q.ESTIMATOR_HASH_EXACT(1);
end
[names,passed,detail]=addGate(names,passed,detail,'exact_reference_trace', ...
    traceMatch,'candidate matches canonical EXP18A exogenous realizations');
finite=all(isfinite(T.RMSE) & isfinite(T.OFFERED_UTIL) & ...
    isfinite(T.MEAN_TRUE_AOI) & isfinite(T.serviceRatio));
[names,passed,detail]=addGate(names,passed,detail,'finite_outputs',finite, ...
    'all outcomes and certificate ratios are finite');
causal=all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI>=T.MEAN_TRUE_AOI-1e-12);
[names,passed,detail]=addGate(names,passed,detail,'causal_conservatism', ...
    causal,sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));
bounded=all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
[names,passed,detail]=addGate(names,passed,detail,'bounded_memory',bounded, ...
    sprintf('max queue=%d max history=%d',max(T.MAX_QUEUE),max(T.MAX_HISTORY)));
accounting=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT==T.ACK_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=1+1e-12);
[names,passed,detail]=addGate(names,passed,detail,'physical_accounting', ...
    accounting,'terminal recipient and busy-union accounting close');
semantics=all(string(T.method)=="context-aware-broadcast") && ...
    all(string(T.feedbackMode)=="adaptive") && ...
    all(string(T.route)=="context-aware-v3") && ...
    all(T.serviceCertificateEnabled==1) && ...
    all(T.freshnessHeadroomEnabled==1);
[names,passed,detail]=addGate(names,passed,detail,'candidate_semantics', ...
    semantics,'service certificate and freshness headroom are enabled');
expectedP=1./T.N; aloha=string(T.macType)=="aloha";
expectedP(aloha)=1./(T.N(aloha).*(2*T.dataFrameSlots(aloha)-1));
[names,passed,detail]=addGate(names,passed,detail,'access_geometry', ...
    all(abs(T.pAccess-expectedP)<1e-12), ...
    'CSMA 1/N and ALOHA 1/[N(2L-1)] are exact');
decisionOk=all(T.CONTEXT_ACK_EVALUATED== ...
    T.CONTEXT_ACK_PERMITTED+T.CONTEXT_ACK_BLOCKED_FEASIBILITY+ ...
    T.CONTEXT_ACK_BLOCKED_VALUE);
[names,passed,detail]=addGate(names,passed,detail,'decision_accounting', ...
    decisionOk,'every context decision has exactly one outcome');
staticOk=true;
for c=R.cells
    for m=1:numel(R.macTypes)
        Q=T(string(T.scenario)==string(c.id) & ...
            string(T.macType)==string(R.macTypes{m}),:);
        staticOk=staticOk && isscalar(unique(Q.serviceCertificateFeasible)) && ...
            max(Q.serviceRatio)-min(Q.serviceRatio)<1e-12;
    end
end
[names,passed,detail]=addGate(names,passed,detail,'static_certificate', ...
    staticOk,'certificate is seed-independent within context/MAC');
infeasible=T.serviceCertificateFeasible==0;
[names,passed,detail]=addGate(names,passed,detail,'infeasible_abstention', ...
    all(T.ACK_STANDALONE(infeasible)==0) && ...
    all(T.CONTEXT_ACK_PERMITTED(infeasible)==0), ...
    'certificate-infeasible trajectories emit no standalone ACK');
reverse=contains(string(T.scenario),'reverse');
[names,passed,detail]=addGate(names,passed,detail,'calibration_boundary', ...
    all(string(T.calibrationSource(reverse))== ...
    "nominal-moderate-mismatch"), ...
    'reverse boundary retains declared nominal mismatch');
gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP18A3_FRESHNESS_HEADROOM_PLAN.md', ...
    'utils/exp18a3Registry.m','utils/applyExp18A3Arm.m', ...
    'utils/exp18a3EmptyRow.m','utils/runExp18A3Cell.m', ...
    'network/contextAwarePolicyConfig.m', ...
    'network/contextAwareAccessProbability.m', ...
    'network/contextAwareServiceCertificate.m', ...
    'network/contextAwareStandaloneAckDecision.m', ...
    'network/adaptiveStandaloneAckDecision.m', ...
    'network/advanceSharedMedium.m','simulation/simSwarmSharedMedium.m', ...
    'tests/test_context_aware_policy.m','tests/test_exp18a3_contracts.m', ...
    'tests/test_exp18a3_analysis_contracts.m', ...
    'experiments/analyzeExp18A3Development.m', ...
    'experiments/exp18a3_freshness_headroom_development.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function [names,passed,detail]=addGate(names,passed,detail,name,flag,textValue)

names{end+1,1}=name; passed(end+1,1)=logical(flag);
detail{end+1,1}=textValue;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp18a3: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
