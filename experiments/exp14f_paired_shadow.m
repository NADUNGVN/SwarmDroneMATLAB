function exp14f_paired_shadow()
%EXP14F_PAIRED_SHADOW Generation-matched standalone-ACK value study.

startup;
close all;
R=exp14fRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=20176987 || registryLeaves~=25
    error('exp14f: frozen development registry mismatch.');
end
runScriptIsolated('test_exp14f_shadow_contracts');

expRun=startExperiment('exp14f_paired_shadow', ...
    ['Development paired-shadow study of generation-matched confirmation ' ...
     'lead; no confirmatory claim or threshold tuning.']);
snapshotSource(expRun.dir);
writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
locked=struct('lockedAt',char(datetime('now', ...
    'Format','yyyy-MM-dd HH:mm:ss')), ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'firstSeed',R.seeds(1),'lastSeed',R.seeds(end), ...
    'matrixMayChange',false,'matchingRuleMayChange',false, ...
    'performanceGateDefined',false,'confirmatoryClaimPermitted',false);
writeJson(fullfile(expRun.dir,'design_locked.json'),locked);

[groupSeed,groupCell]=groups(R);
nGroup=numel(groupSeed); batchSize=12;
runRows=repmat(exp14fEmptyRunRow(),0,1);
leadRows=repmat(exp14fEmptyLeadRow(),0,1);
fprintf('EXP14F development matrix: %d paired groups, %d runs.\n', ...
    nGroup,R.expectedRuns);

for first=1:batchSize:nGroup
    last=min(first+batchSize-1,nGroup);
    indices=first:last;
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),12)
        g=indices(q);
        batch{q}=runGroup(groupSeed(g),groupCell(g),R);
    end
    for q=1:numel(batch)
        runRows=[runRows; batch{q}.runs(:)]; %#ok<AGROW>
        leadRows=[leadRows; batch{q}.leads(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(runRows), ...
        fullfile(expRun.dir,'tidy_runs_checkpoint.csv'));
    writeTableAtomic(struct2table(leadRows), ...
        fullfile(expRun.dir,'lead_events_checkpoint.csv'));
    fprintf('  groups %3d--%3d / %3d; runs %3d / %3d; events %d\n', ...
        first,last,nGroup,numel(runRows),R.expectedRuns,numel(leadRows));
end

T=struct2table(runRows);
L=struct2table(leadRows);
writetable(T,fullfile(expRun.dir,'tidy_runs.csv'));
writetable(L,fullfile(expRun.dir,'lead_events.csv'));
gates=integrityGates(T,L,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
integrity=struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'totalRuns',height(T),'totalLeadEvents',height(L), ...
    'performanceIsIntegrityGate',false,'negativeResultsRetained',true);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrity);

fprintf('\nEXP14F integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-31s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp14FResults(expRun.dir);
    fprintf('\nGeneration-matched confirmation lead\n');
    disp(analysis.leadSummary);
else
    analysis=struct();
    fprintf('\nEXP14F analysis withheld because integrity failed.\n');
end

save(fullfile(expRun.dir,'workspace.mat'),'T','L','gates', ...
    'integrity','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp14f_paired_shadow: integrity gates failed.');
end

end


function result=runGroup(seedValue,cellIndex,R)

cellDef=R.cells(cellIndex);
base=applyExp14FCell(cellDef.id,seedValue);
trace=generateSharedMediumTrace(base);
outputs=cell(numel(R.arms),1);
runs=repmat(exp14fEmptyRunRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label]=applyExp14FArm(base,arm);
    outputs{k}=simSwarmSharedMedium(cfg,method,trace);
    runs(k)=flattenRun(outputs{k},cfg,method,label,cellDef,arm);
end

actual=outputs{strcmp({R.arms.id},R.actualArm)};
shadow=outputs{strcmp({R.arms.id},R.shadowArm)};
matches=matchAckValueEvents(actual.ackValueLog,shadow.ackValueLog,base.swarm.T);
leads=repmat(exp14fEmptyLeadRow(),numel(matches),1);
for k=1:numel(matches)
    m=matches(k); row=exp14fEmptyLeadRow();
    row.seed=seedValue; row.scenario=cellDef.id;
    row.scenarioLabel=cellDef.label; row.N=base.swarm.N;
    row.horizon=base.swarm.T;
    names=fieldnames(m);
    for f=1:numel(names), row.(names{f})=m.(names{f}); end
    row.actualTraceHash=actual.traceHashExact;
    row.shadowTraceHash=shadow.traceHashExact;
    row.actualChannelHash=actual.channelStateHash;
    row.shadowChannelHash=shadow.channelStateHash;
    leads(k)=row;
end
result=struct('runs',runs,'leads',leads);

end


function row=flattenRun(out,cfg,method,label,cellDef,arm)

M=computeSharedMediumMetrics(out,cfg);
Q=compute6DOFMetrics(out,cfg);
E=out.ackValueLog;
transport=string({E.transport});
row=exp14fEmptyRunRow();
row.stage='development'; row.seed=cfg.net.seed;
row.scenario=cellDef.id; row.scenarioLabel=cellDef.label;
row.arm=arm.id; row.role=cfg.exp14f.role;
row.method=method; row.methodLabel=label;
row.feedbackMode=out.feedbackMode; row.N=cfg.swarm.N;
row.plant=ternary(Q.sixdof,'6dof','di'); row.macType=cfg.mac.type;
row.horizon=cfg.swarm.T; row.pAccess=out.pAccess;
row.historySize=cfg.mac.historySize;
row.RMSE=M.formationRMSE; row.MINSEP=M.minSeparationEval;
row.SAFEFAIL=double(M.safeFailure || Q.diverged);
row.DIVERGED=double(Q.diverged);
row.MEAN_TRUE_AOI=M.meanTrueAoI; row.MEAN_EST_AOI=M.meanEstimatedAoI;
row.DATA_GENERATED=M.dataFramesGenerated;
row.DATA_ATTEMPTED=M.dataFramesAttempted;
row.DATA_DELIVERED=M.dataFramesDeliveredAny;
row.ACK_ATTEMPTED=M.ackFramesAttempted;
row.ACK_ENTRIES_DELIVERED=M.ackEntriesDelivered;
row.DATA_RECIPIENT_ATTEMPTS=M.dataRecipientAttempts;
row.DATA_RECIPIENT_SUCCESS=M.dataRecipientSuccess;
row.DATA_RECIPIENT_LOSS=M.dataRecipientLoss;
row.ACK_RECIPIENT_ATTEMPTS=M.ackRecipientAttempts;
row.ACK_RECIPIENT_SUCCESS=M.ackRecipientSuccess;
row.ACK_RECIPIENT_LOSS=M.ackRecipientLoss;
row.TERMINAL_DATA_INFLIGHT=M.terminalDataRecipientAttempts;
row.TERMINAL_ACK_INFLIGHT=M.terminalAckRecipientAttempts;
row.COLLISION_FRAMES=M.collisionFrames;
row.MAX_QUEUE=M.maxQueueDepth; row.MAX_HISTORY=M.maxHistoryDepth;
row.ACK_STANDALONE=M.ackFramesStandalone;
row.CHANNEL_UTIL=M.channelUtilization;
row.OFFERED_UTIL=M.offeredAirtimeUtilization;
row.DATA_AIRTIME=M.dataAirtime; row.ACK_AIRTIME=M.ackAirtime;
row.PIGGYBACK_AIRTIME=M.piggybackOverheadAirtime;
row.ENERGY_PROXY_J=M.energyProxyJ;
row.CONFIRMATION_EVENTS=numel(E);
row.STANDALONE_CONFIRMATION_EVENTS=sum(transport=="ack");
row.PIGGYBACK_CONFIRMATION_EVENTS=sum(transport=="data");
row.NETWORK_RUNTIME_SEC=M.networkRuntimeSec;
row.INVARIANT_VIOLATIONS=M.invariantViolations;
row.TRACE_HASH_EXACT=out.traceHashExact;
row.CHANNEL_STATE_HASH=out.channelStateHash;
row.CONFIG_HASH=configHash(cfg);

end


function gates=integrityGates(T,L,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
add('registry_contract',registryHash==20176987 && registryLeaves==25, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
keys=string(T.seed)+"|"+T.scenario+"|"+T.arm;
add('matrix_completeness',height(T)==R.expectedRuns && ...
    numel(unique(keys))==R.expectedRuns,sprintf('%d unique runs',height(T)));

paired=true;
for seed=R.seeds'
    for c=R.cells
        Q=T(T.seed==seed & T.scenario==string(c.id),:);
        paired=paired && height(Q)==2 && ...
            isequal(sort(string(Q.arm)),sort(string({R.arms.id}))');
    end
end
add('complete_paired_groups',paired,'both declared arms occur once per group');

eligible=T.DIVERGED==0;
add('finite_eligible_outputs',all(isfinite(T.RMSE(eligible))) && ...
    all(isfinite(T.MINSEP(eligible))) && ...
    all(isfinite(T.MEAN_TRUE_AOI(eligible))), ...
    'nondivergent control and freshness outcomes are finite');
add('causal_conservatism',all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI>=T.MEAN_TRUE_AOI-1e-12), ...
    sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));
add('bounded_memory',all(T.MAX_QUEUE<=4) && ...
    all(T.MAX_HISTORY<=T.historySize), ...
    sprintf('max queue=%d, history=%d',max(T.MAX_QUEUE),max(T.MAX_HISTORY)));
physical=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT==T.ACK_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=1+1e-12);
add('physical_accounting',physical,'terminal recipient accounting closes');

crn=true;
for seed=R.seeds'
    for c=R.cells
        idx=T.seed==seed & T.scenario==string(c.id);
        crn=crn && isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.CHANNEL_STATE_HASH(idx)));
    end
end
add('paired_absolute_trace',crn,'one absolute trace per seed/cell pair');
actual=string(T.arm)==string(R.actualArm);
shadow=string(T.arm)==string(R.shadowArm);
armOk=all(string(T.role(actual))=="actual") && ...
    all(string(T.method(actual))=="mac-aware-broadcast") && ...
    all(string(T.feedbackMode(actual))=="adaptive") && ...
    all(string(T.role(shadow))=="shadow") && ...
    all(string(T.method(shadow))=="causal-broadcast") && ...
    all(string(T.feedbackMode(shadow))=="piggyback");
add('arm_semantics',armOk,'adaptive actual and piggyback-only shadow');
eventAccounting=all(T.CONFIRMATION_EVENTS==T.ACK_ENTRIES_DELIVERED) && ...
    all(T.STANDALONE_CONFIRMATION_EVENTS(shadow)==0) && ...
    height(L)==sum(T.STANDALONE_CONFIRMATION_EVENTS(actual));
add('event_accounting',eventAccounting, ...
    sprintf('%d selected standalone confirmation events',height(L)));

if isempty(L)
    leadOk=false;
else
    leadOk=all(ismember(L.seed,R.seeds)) && ...
        all(ismember(L.scenario,string({R.cells.id}))) && ...
        all(L.actualGenTime<=L.actualTime+1e-12) && ...
        all(L.leadSeconds>=0 & ...
        L.leadSeconds<=L.horizon-L.actualTime+1e-12) && ...
        all(L.actualTraceHash==L.shadowTraceHash) && ...
        all(L.actualChannelHash==L.shadowChannelHash) && ...
        all(isnan(L.shadowGenTime(L.censored))) && ...
        all(L.shadowGenTime(~L.censored)>= ...
        L.actualGenTime(~L.censored)-1e-12);
end
add('lead_matching_contract',leadOk, ...
    'generation threshold, horizon cap and censor metadata are valid');
add('divergence_accounting',all(ismember(T.DIVERGED,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED), ...
    sprintf('%d divergences retained',sum(T.DIVERGED)));

gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

    function add(name,flag,textValue)
        names{end+1,1}=name;
        passed(end+1,1)=logical(flag);
        detail{end+1,1}=textValue;
    end

end


function [seeds,cells]=groups(R)

n=numel(R.seeds)*numel(R.cells);
seeds=zeros(n,1); cells=zeros(n,1); q=0;
for i=1:numel(R.seeds)
    for j=1:numel(R.cells)
        q=q+1; seeds(q)=R.seeds(i); cells(q)=j;
    end
end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP14F_PAIRED_SHADOW_PLAN.md', ...
    'utils/exp14fRegistry.m','utils/applyExp14FCell.m', ...
    'utils/applyExp14FArm.m','utils/exp14fEmptyRunRow.m', ...
    'utils/exp14fEmptyLeadRow.m','utils/matchAckValueEvents.m', ...
    'network/ackValueLoggingConfig.m','network/initSharedMediumState.m', ...
    'network/applySharedMediumDeliveries.m', ...
    'simulation/simSwarmSharedMedium.m', ...
    'experiments/analyzeExp14FResults.m', ...
    'experiments/exp14f_paired_shadow.m', ...
    'tests/test_ack_value_instrumentation.m', ...
    'tests/test_exp14f_shadow_contracts.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14f: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
