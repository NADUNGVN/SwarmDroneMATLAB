function exp18a_context_aware_development()
%EXP18A_CONTEXT_AWARE_DEVELOPMENT Development-only policy decomposition.

startup;
close all;
runScriptIsolated('test_context_aware_policy');
runScriptIsolated('test_exp18_contracts');
R=exp18Registry();
[registryHash,registryLeaves]=configHash(R);
expRun=startExperiment('exp18a_context_aware_development', ...
    ['Development-only frame-aware access plus causal feasibility/value ' ...
    'feedback; no confirmatory or hardware claim.']);
if exist(expRun.figDir,'dir')~=7, mkdir(expRun.figDir); end
writeJson(fullfile(expRun.dir,'development_registry.json'),R);
writeJson(fullfile(expRun.dir,'development_opened.json'),struct( ...
    'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'developmentOnly',true,'confirmatoryClaimPermitted',false, ...
    'futureHoldoutOpened',false,'exp17UsedAsDevelopmentEvidence',true));
snapshotSource(expRun.dir);

[groupSeed,groupCell,groupMac]=groups(R);
rows=repmat(exp18EmptyRow(),0,1);
batchSize=16;
for first=1:batchSize:numel(groupSeed)
    last=min(first+batchSize-1,numel(groupSeed));
    indices=first:last;
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),16)
        g=indices(q);
        batch{q}=runGroup(groupSeed(g),groupCell(g), ...
            groupMac(g),R);
    end
    for q=1:numel(batch)
        rows=[rows; batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows), ...
        fullfile(expRun.dir,'tidy_checkpoint.csv'));
    fprintf('  groups %4d--%4d / %4d; rows %4d / %4d\n', ...
        first,last,numel(groupSeed),numel(rows),R.expectedRuns);
end

tidy=struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
gates=integrityGates(tidy,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
integrityVerdict=struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'totalRuns',height(tidy),'developmentOnly',true, ...
    'performanceIsIntegrityGate',false,'futureHoldoutOpened',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP18A integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-36s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp18ADevelopment(expRun.dir);
    fprintf('\nEXP18A DEVELOPMENT VERDICT: %s (%d/%d gates)\n', ...
        analysis.verdict.status,analysis.verdict.gatesPassed, ...
        analysis.verdict.gatesTotal);
else
    analysis=struct();
    fprintf('\nEXP18A analysis not opened: integrity failure.\n');
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp18a_context_aware_development: integrity gates failed.');
end

end


function rows=runGroup(seedValue,cellIndex,macIndex,R)

c=R.cells(cellIndex);
base=applyExp18Cell(c.id,seedValue);
base.mac.type=R.macTypes{macIndex};
base.mac.pAccess=min(0.20,1/base.swarm.N);
base.mac=sharedMediumConfig(base);
trace=generateSharedMediumTrace(base);
rows=repmat(exp18EmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label,details]=applyExp18Arm(base,arm);
    meta=struct('stage','development','scenario',c.id, ...
        'scenarioLabel',c.label,'family','EXP18A context-aware', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',c.background, ...
        'role',c.role,'channel',c.channel,'modifier',c.modifier, ...
        'basePAccess',base.mac.pAccess);
    rows(k)=runExp18Cell(cfg,method,label,meta,trace,details);
end

end


function [seeds,cells,macs]=groups(R)

n=numel(R.seeds)*numel(R.cells)*numel(R.macTypes);
seeds=zeros(n,1); cells=zeros(n,1); macs=zeros(n,1); q=0;
for i=1:numel(R.seeds)
    for j=1:numel(R.cells)
        for m=1:numel(R.macTypes)
            q=q+1; seeds(q)=R.seeds(i); cells(q)=j; macs(q)=m;
        end
    end
end

end


function gates=integrityGates(T,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
[names,passed,detail]=addGate(names,passed,detail,'registry_recorded', ...
    isfinite(registryHash) && registryLeaves>0, ...
    sprintf('development hash %.0f over %d leaves', ...
    registryHash,registryLeaves));
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d development runs',height(T)));
keys=string(T.seed)+"|"+T.scenario+"|"+T.macType+"|"+T.arm;
[names,passed,detail]=addGate(names,passed,detail,'unique_rows', ...
    numel(unique(keys))==height(T),'one row per seed/context/MAC/arm');

crn=true; complete=true;
declaredArms=sort(string({R.arms.id}))';
for seed=R.seeds'
    for c=R.cells
        Qall=T(T.seed==seed & T.scenario==string(c.id),:);
        crn=crn && isscalar(unique(Qall.TRACE_HASH_EXACT)) && ...
            isscalar(unique(Qall.CHANNEL_STATE_HASH)) && ...
            isscalar(unique(Qall.ESTIMATOR_HASH_EXACT));
        for m=1:numel(R.macTypes)
            Q=Qall(Qall.macType==string(R.macTypes{m}),:);
            complete=complete && height(Q)==numel(R.arms) && ...
                isequal(sort(Q.arm),declaredArms);
        end
    end
end
[names,passed,detail]=addGate(names,passed,detail,'complete_groups', ...
    complete,'all four arms occur once per seed/context/MAC');
[names,passed,detail]=addGate(names,passed,detail,'absolute_trace_crn', ...
    crn,'both MAC types and four arms share one absolute realization');

finite=all(isfinite(T.RMSE) & isfinite(T.OFFERED_UTIL) & ...
    isfinite(T.MEAN_TRUE_AOI));
[names,passed,detail]=addGate(names,passed,detail,'finite_outputs',finite, ...
    'all development outcomes are finite');
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

arm=string(T.arm); macType=string(T.macType);
feedbackMode=string(T.feedbackMode); method=string(T.method);
legacy=arm=="legacy-selector"; piggy=arm=="frame-piggyback";
adaptive=arm=="frame-adaptive"; context=arm=="context-aware";
semantics=all(feedbackMode(piggy)=="piggyback") && ...
    all(method(piggy)=="causal-broadcast") && ...
    all(feedbackMode(adaptive)=="adaptive") && ...
    all(method(adaptive)=="mac-aware-broadcast") && ...
    all(feedbackMode(context)=="adaptive") && ...
    all(method(context)=="context-aware-broadcast") && ...
    all(feedbackMode(legacy & macType=="csma")=="piggyback") && ...
    all(feedbackMode(legacy & macType=="aloha")=="adaptive");
[names,passed,detail]=addGate(names,passed,detail,'arm_semantics',semantics, ...
    'legacy, fixed-route and context-aware contracts are exact');

expectedN=1./T.N;
expectedFrame=1./(T.N.*(2*T.dataFrameSlots-1));
accessOk=all(abs(T.pAccess(macType=="csma")- ...
    expectedN(macType=="csma"))<1e-12) && ...
    all(abs(T.pAccess(macType=="aloha" & legacy)- ...
    expectedN(macType=="aloha" & legacy))<1e-12) && ...
    all(abs(T.pAccess(macType=="aloha" & ~legacy)- ...
    expectedFrame(macType=="aloha" & ~legacy))<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'access_geometry',accessOk, ...
    'CSMA/legacy use 1/N; frame-aware ALOHA uses 1/[N(2L-1)]');

decisionOk=all(T.CONTEXT_ACK_EVALUATED(context)== ...
    T.CONTEXT_ACK_PERMITTED(context)+ ...
    T.CONTEXT_ACK_BLOCKED_FEASIBILITY(context)+ ...
    T.CONTEXT_ACK_BLOCKED_VALUE(context)) && ...
    all(T.CONTEXT_ACK_EVALUATED(~context)==0) && ...
    all(T.CONTEXT_ACK_PERMITTED(~context)==0);
[names,passed,detail]=addGate(names,passed,detail,'decision_accounting', ...
    decisionOk,'context decisions close and fixed arms remain inert');

gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP18_CONTEXT_AWARE_DEVELOPMENT_PLAN.md', ...
    'utils/exp18Registry.m','utils/applyExp18Cell.m', ...
    'utils/applyExp18Arm.m','utils/exp18EmptyRow.m', ...
    'utils/runExp18Cell.m','network/contextAwarePolicyConfig.m', ...
    'network/contextAwareAccessProbability.m', ...
    'network/contextAwareStandaloneAckDecision.m', ...
    'network/adaptiveStandaloneAckDecision.m', ...
    'network/advanceSharedMedium.m','simulation/simSwarmSharedMedium.m', ...
    'tests/test_context_aware_policy.m','tests/test_exp18_contracts.m', ...
    'tests/test_exp18_analysis_contracts.m', ...
    'experiments/analyzeExp18ADevelopment.m', ...
    'experiments/exp18a_context_aware_development.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function [names,passed,detail]=addGate(names,passed,detail,name,flag,textValue)

names{end+1,1}=name;
passed(end+1,1)=logical(flag);
detail{end+1,1}=textValue;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp18a: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
