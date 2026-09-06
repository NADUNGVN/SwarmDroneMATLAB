function exp20a_prior_art_baseline_closure(resumeDir)
%EXP20A_PRIOR_ART_BASELINE_CLOSURE Two-panel development falsification.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp20aRegistry();
[registryHash,registryLeaves]=configHash(R);

if isempty(resumeDir)
    runScriptIsolated('test_service_scheduler_contracts');
    runScriptIsolated('test_exp20a_delta_contracts');
    runScriptIsolated('test_exp20a_formation_contracts');
    expRun=startExperiment('exp20a_prior_art_baseline_closure', ...
        ['Development/falsification prior-art closure; no candidate tuning, ' ...
        'confirmatory claim, manuscript promotion or hardware promotion.']);
    writeJson(fullfile(expRun.dir,'development_registry.json'),R);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'developmentFalsificationOnly',true, ...
        'candidateOptimizationAllowed',false, ...
        'confirmatoryClaimPermitted',false, ...
        'manuscriptClaimPermitted',false, ...
        'hardwarePolicyValidationPermitted',false, ...
        'upstreamDeltaUrl',R.upstreamDeltaUrl, ...
        'upstreamDeltaCommit',R.upstreamDeltaCommit);
    writeJson(fullfile(expRun.dir,'development_opened.json'),opened);
    snapshotSource(expRun.dir);
else
    expRun=resumeRun(resumeDir,registryHash,registryLeaves);
end

[nativeRows,nativeComplete]=loadNativeCheckpoint(expRun.dir,R);
[formationRows,formationComplete]=loadFormationCheckpoint(expRun.dir,R);

nativeRows=runNativePanel(expRun.dir,R,nativeRows,nativeComplete);
formationRows=runFormationPanel( ...
    expRun.dir,R,formationRows,formationComplete);

nativeT=struct2table(nativeRows);
formationT=struct2table(formationRows);
writetable(nativeT,fullfile(expRun.dir,'native_tidy.csv'));
writetable(formationT,fullfile(expRun.dir,'formation_tidy.csv'));

gates=integrityGates(formationT,nativeT,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'integrity_gates.csv'));
integrityVerdict=struct('status',ternary(all(gates.passed==1), ...
    'PASS','FAIL'),'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates), ...
    'formationRuns',height(formationT),'nativeRuns',height(nativeT), ...
    'developmentFalsificationOnly',true, ...
    'performanceIsIntegrityGate',false, ...
    'candidateOptimizationAllowed',false, ...
    'negativeResultsRetained',true);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP20A integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-42s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
if all(gates.passed==1)
    analysis=analyzeExp20AResults(expRun.dir);
    fprintf('\nEXP20A DEVELOPMENT VERDICT: %s\n', ...
        analysis.verdict.status);
else
    analysis=struct();
    fprintf('\nEXP20A performance analysis NOT OPENED: integrity failure.\n');
end
save(fullfile(expRun.dir,'workspace.mat'),'nativeT','formationT', ...
    'gates','integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp20a_prior_art_baseline_closure: integrity failure.');
end

end


function rows=runNativePanel(runDir,R,rows,completed)

[groupSeed,groupCell]=nativeGroups(R);
pending=find(~completed);
checkpoint=fullfile(runDir,'native_checkpoint.csv');
batchSize=12;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    selectedSeeds=groupSeed(indices);
    selectedCells=groupCell(indices);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),12)
        batch{q}=runNativeGroup( ...
            selectedSeeds(q),selectedCells(q),R);
    end
    for q=1:numel(batch)
        rows=[rows;batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  native groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        indices(1),indices(end),numel(groupSeed),numel(rows), ...
        R.expectedNativeRuns);
end

end


function rows=runFormationPanel(runDir,R,rows,completed)

[groupSeed,groupCell]=formationGroups(R);
pending=find(~completed);
checkpoint=fullfile(runDir,'formation_checkpoint.csv');
batchSize=12;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    selectedSeeds=groupSeed(indices);
    selectedCells=groupCell(indices);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),12)
        batch{q}=runFormationGroup( ...
            selectedSeeds(q),selectedCells(q),R);
    end
    for q=1:numel(batch)
        rows=[rows;batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  formation groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        indices(1),indices(end),numel(groupSeed),numel(rows), ...
        R.expectedFormationRuns);
end

end


function rows=runNativeGroup(seedValue,cellIndex,R)

c=R.nativeCells(cellIndex);
cfg=struct('N',c.N,'rho',c.rho,'epsilon',c.epsilon, ...
    'slots',R.nativeSlots,'burnIn',R.nativeBurnIn, ...
    'feedbackLoss',R.privateFeedbackLoss, ...
    'feedbackDelaySlots',R.privateFeedbackDelaySlots);
rows=repmat(exp20aNativeEmptyRow(),numel(R.nativeArms),1);
for k=1:numel(R.nativeArms)
    out=simulateDeltaInformationStructure(cfg,R.nativeArms{k},seedValue);
    row=exp20aNativeEmptyRow();
    row.cell=c.id;
    names=fieldnames(out);
    for q=1:numel(names)
        if isfield(row,names{q})
            row.(names{q})=out.(names{q});
        end
    end
    rows(k)=row;
end

end


function rows=runFormationGroup(seedValue,cellIndex,R)

c=R.cells(cellIndex);
base=applyExp20ACell(c.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp20aFormationEmptyRow(),numel(R.formationArms),1);
for k=1:numel(R.formationArms)
    arm=R.formationArms(k);
    [cfg,method,label,details]=applyExp20AArm(base,arm);
    meta=struct('stage','development-falsification', ...
        'scenario',c.id,'scenarioLabel',c.label, ...
        'family','EXP20A prior-art baseline closure', ...
        'arm',arm.id,'pointIndex',k, ...
        'parameterValue',arm.periodicRateHz);
    rows(k)=runExp20AFormationCell( ...
        cfg,method,label,meta,trace,details);
end

end


function gates=integrityGates(F,N,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
add('registry_recorded',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));

fkeys=string(F.seed)+'|'+string(F.scenario)+'|'+string(F.arm);
fmatrix=height(F)==R.expectedFormationRuns && ...
    numel(unique(fkeys))==height(F);
add('formation_matrix_complete_unique',fmatrix, ...
    sprintf('%d/%d unique rows',height(F),R.expectedFormationRuns));
nkeys=string(N.seed)+'|'+string(N.cell)+'|'+string(N.arm);
nmatrix=height(N)==R.expectedNativeRuns && ...
    numel(unique(nkeys))==height(N);
add('native_matrix_complete_unique',nmatrix, ...
    sprintf('%d/%d unique rows',height(N),R.expectedNativeRuns));

add('exact_formation_seeds',isequal(unique(F.seed),R.formationSeeds), ...
    'all and only 30 declared formation seeds');
add('exact_native_seeds',isequal(unique(N.seed),R.nativeSeeds), ...
    'all and only 30 declared native seeds');

paired=true;
for seed=R.formationSeeds'
    for c=R.cells
        idx=F.seed==seed & string(F.scenario)==string(c.id);
        paired=paired && nnz(idx)==numel(R.formationArms) && ...
            isscalar(unique(F.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(F.CHANNEL_STATE_HASH(idx))) && ...
            isscalar(unique(F.ESTIMATOR_HASH_EXACT(idx)));
    end
end
add('paired_formation_absolute_traces',paired, ...
    'channel, state and estimator hashes match within every group');

nativePaired=true;
for seed=R.nativeSeeds'
    for cellIndex=1:numel(R.nativeCells)
        c=R.nativeCells(cellIndex);
        idx=N.seed==seed & string(N.cell)==string(c.id);
        nativePaired=nativePaired && nnz(idx)==numel(R.nativeArms) && ...
            isscalar(unique(N.DRAW_HASH_EXACT(idx)));
    end
end
add('paired_native_absolute_draws',nativePaired, ...
    'all native arms share the same seed/cell draw tensor');

privateFormation=ismember(string(F.arm), ...
    ["frame-piggyback","collision-free-rr-piggyback", ...
    "chen-age-gain-private","delta-private-projection"]);
causal=all(F.INVARIANT_VIOLATIONS==0) && ...
    all(F.MEAN_EST_AOI(privateFormation)>= ...
    F.MEAN_TRUE_AOI(privateFormation)-1e-12);
add('private_feedback_causality',causal, ...
    sprintf('%d formation protocol violations',sum(F.INVARIANT_VIOLATIONS)));

future=all(F.FUTURE_RANDOM_READS==0) && ...
    all(N.FUTURE_FEEDBACK_READS==0);
add('no_future_information_reads',future, ...
    'formation random draws and native feedback are present/past only');

bounded=all(F.MAX_QUEUE<=4) && all(F.MAX_HISTORY<=F.historySize) && ...
    all(N.MAX_FEEDBACK_QUEUE<=R.privateFeedbackDelaySlots(2)+1);
add('bounded_memory',bounded,sprintf( ...
    'formation queue/history %d/%d; native feedback queue %d', ...
    max(F.MAX_QUEUE),max(F.MAX_HISTORY),max(N.MAX_FEEDBACK_QUEUE)));

physical=all(F.DATA_RECIPIENT_SUCCESS+F.DATA_RECIPIENT_LOSS+ ...
    F.TERMINAL_DATA_INFLIGHT==F.DATA_RECIPIENT_ATTEMPTS) && ...
    all(F.ACK_RECIPIENT_SUCCESS+F.ACK_RECIPIENT_LOSS+ ...
    F.TERMINAL_ACK_INFLIGHT==F.ACK_RECIPIENT_ATTEMPTS) && ...
    all(F.CHARGED_OFFERED_UTIL>=F.OFFERED_UTIL-1e-12) && ...
    all(N.ATTEMPTS>=N.SUCCESSES) && all(N.ATTEMPTS>=N.COLLISIONS);
add('physical_and_feedback_accounting',physical, ...
    'recipient, terminal, charged-utilization and native counts close');

pub=string(F.arm)=='delta-public-projection';
priv=string(F.arm)=='delta-private-projection';
age=string(F.arm)=='chen-age-gain-private';
zmac=string(F.arm)=='zmac-like-hybrid';
dtsaCommon=string(F.arm)=='dtsa-common-view';
dtsaPrivate=string(F.arm)=='dtsa-private-view';
activated=all(F.PUBLIC_FEEDBACK_COUNT(pub)>0) && ...
    all(F.PUBLIC_FEEDBACK_AIRTIME(pub)>0) && ...
    all(F.ACK_ENTRIES_PIGGYBACKED(priv)>0) && ...
    all(F.AGE_GAIN_ELIGIBLE(age)>0) && ...
    all(F.ZMAC_OWNER_ATTEMPTS(zmac)>0) && ...
    all(F.ZMAC_CONTENTION_ATTEMPTS(zmac)>0) && ...
    all(F.DTSA_DECISIONS(dtsaCommon|dtsaPrivate)>0) && ...
    sum(F.DTSA_DISAGREEMENTS(dtsaPrivate))>0;
add('named_mechanisms_activated',activated, ...
    'public/private feedback, age gain, Z-MAC and DTSA paths exercised');

finiteEligible=all(isfinite(F.RMSE(F.DIVERGED==0))) && ...
    all(isfinite(F.CHARGED_OFFERED_UTIL(F.DIVERGED==0))) && ...
    all(isfinite(N.MEAN_AOII)) && all(ismember(F.SAFEFAIL,[0 1])) && ...
    all(F.SAFEFAIL>=F.DIVERGED);
add('finite_outputs_and_failures_retained',finiteEligible, ...
    sprintf('%d unsafe and %d diverged formation runs retained', ...
    sum(F.SAFEFAIL),sum(F.DIVERGED)));

gates=table(string(names),double(passed),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(name,flag,textValue)
        names{end+1,1}=name;
        passed(end+1,1)=logical(flag);
        detail{end+1,1}=textValue;
    end

end


function [rows,completed]=loadNativeCheckpoint(runDir,R)

[groupSeed,groupCell]=nativeGroups(R);
path=fullfile(runDir,'native_checkpoint.csv');
if exist(path,'file')~=2
    rows=repmat(exp20aNativeEmptyRow(),0,1);
    completed=false(numel(groupSeed),1);
    return;
end
T=readtable(path,'TextType','string');
if ~isequal(T.Properties.VariableNames(:),fieldnames(exp20aNativeEmptyRow()))
    error('exp20a: native checkpoint schema mismatch.');
end
rows=table2struct(T);
completed=checkpointGroups(T,groupSeed,groupCell,R.nativeCells,R.nativeArms,'cell');

end


function [rows,completed]=loadFormationCheckpoint(runDir,R)

[groupSeed,groupCell]=formationGroups(R);
path=fullfile(runDir,'formation_checkpoint.csv');
if exist(path,'file')~=2
    rows=repmat(exp20aFormationEmptyRow(),0,1);
    completed=false(numel(groupSeed),1);
    return;
end
T=readtable(path,'TextType','string');
if ~isequal(T.Properties.VariableNames(:),fieldnames(exp20aFormationEmptyRow()))
    error('exp20a: formation checkpoint schema mismatch.');
end
rows=table2struct(T);
completed=checkpointGroups(T,groupSeed,groupCell,R.cells, ...
    {R.formationArms.id},'scenario');

end


function completed=checkpointGroups(T,groupSeed,groupCell,cells,arms,cellField)

completed=false(numel(groupSeed),1);
declared=sort(string(arms(:)));
for g=1:numel(groupSeed)
    c=cells(groupCell(g));
    idx=T.seed==groupSeed(g) & string(T.(cellField))==string(c.id);
    if nnz(idx)==0, continue; end
    if nnz(idx)~=numel(arms) || ...
            ~isequal(sort(string(T.arm(idx))),declared)
        error('exp20a: checkpoint contains an incomplete group.');
    end
    completed(g)=true;
end
if nnz(completed)*numel(arms)~=height(T)
    error('exp20a: checkpoint contains undeclared rows.');
end

end


function [seeds,cells]=nativeGroups(R)

[seeds,cells]=groups(R.nativeSeeds,numel(R.nativeCells));

end


function [seeds,cells]=formationGroups(R)

[seeds,cells]=groups(R.formationSeeds,numel(R.cells));

end


function [seeds,cells]=groups(seedBlock,nCells)

n=numel(seedBlock)*nCells;
seeds=zeros(n,1); cells=zeros(n,1); q=0;
for i=1:numel(seedBlock)
    for j=1:nCells
        q=q+1;
        seeds(q)=seedBlock(i);
        cells(q)=j;
    end
end

end


function expRun=resumeRun(runDir,registryHash,registryLeaves)

runDir=char(runDir);
if ~isfolder(runDir), error('exp20a: resume directory is missing.'); end
record=jsondecode(fileread(fullfile(runDir,'development_opened.json')));
if record.registryHash~=registryHash || ...
        record.registryLeaves~=registryLeaves
    error('exp20a: resume registry mismatch.');
end
[expRoot,runId]=fileparts(runDir);
expRun=struct('name','exp20a_prior_art_baseline_closure', ...
    'runId',runId,'expRoot',expRoot,'dir',runDir, ...
    'figDir',fullfile(runDir,'figures'),'t0',tic);
v=ver;
v=v(strcmp({v.Name},'MATLAB'));
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',record.openedAt, ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed development/falsification run','sourceFile','');
expRun.logFile=fullfile(runDir,'console.log');
diary(expRun.logFile); diary on;

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP20A_PRIOR_ART_BASELINE_CLOSURE_PLAN.md', ...
    'docs/POST_EXP19_LITERATURE_MECHANISM_AUDIT_2026-08-31.md', ...
    'network/simulateDeltaInformationStructure.m', ...
    'network/serviceSchedulerConfig.m','network/selectScheduledService.m', ...
    'network/initSharedMediumState.m','network/advanceSharedMedium.m', ...
    'network/enqueueBroadcastState.m','simulation/simSwarmSharedMedium.m', ...
    'utils/exp20aRegistry.m','utils/applyExp20ACell.m', ...
    'utils/applyExp20AArm.m','utils/exp20aNativeEmptyRow.m', ...
    'utils/exp20aFormationEmptyRow.m', ...
    'utils/runExp20AFormationCell.m','utils/pairedBootstrapCI.m', ...
    'tests/test_exp20a_delta_contracts.m', ...
    'tests/test_exp20a_formation_contracts.m', ...
    'experiments/analyzeExp20AResults.m', ...
    'experiments/exp20a_prior_art_baseline_closure.m'};
freeze=fullfile(target,'frozen_source');
if ~isfolder(freeze), mkdir(freeze); end
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp20a: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
