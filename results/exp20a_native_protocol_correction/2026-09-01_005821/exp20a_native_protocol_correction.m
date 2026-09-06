function exp20a_native_protocol_correction(parentRunDir,resumeDir)
%EXP20A_NATIVE_PROTOCOL_CORRECTION Correct and supersede EXP20A Panel N.

arguments
    parentRunDir (1,:) char
    resumeDir (1,:) char = ''
end

startup;
R=exp20aRegistry();
validateParent(parentRunDir,R);
runScriptIsolated('test_exp20a_delta_contracts');

if isempty(resumeDir)
    expRun=startExperiment('exp20a_native_protocol_correction', ...
        ['Protocol-fidelity correction of EXP20A Panel N; original native ' ...
        'artifact retained and superseded, Panel F reused without change.']);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')), ...
        'parentRunDir',parentRunDir, ...
        'parentFormationRows',R.expectedFormationRuns, ...
        'supersededNativeFile',fullfile(parentRunDir,'native_tidy.csv'), ...
        'scientificRegistryChanged',false, ...
        'nativeProtocolImplementationCorrected',true, ...
        'formationPanelChanged',false, ...
        'candidateOptimizationAllowed',false, ...
        'confirmatoryClaimPermitted',false);
    writeJson(fullfile(expRun.dir,'correction_opened.json'),opened);
    snapshotCorrection(expRun.dir);
else
    expRun=resumeCorrection(resumeDir,parentRunDir);
end

[taskSeed,taskCell,taskArm]=nativeTasks(R);
[rows,completed]=loadCheckpoint(expRun.dir,R,taskSeed,taskCell,taskArm);
pending=find(~completed);
checkpoint=fullfile(expRun.dir,'native_corrected_checkpoint.csv');
batchSize=64;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    selectedSeed=taskSeed(indices);
    selectedCell=taskCell(indices);
    selectedArm=taskArm(indices);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),16)
        batch{q}=runTask(selectedSeed(q),selectedCell(q), ...
            selectedArm(q),R);
    end
    for q=1:numel(batch)
        rows(end+1,1)=batch{q}; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  corrected native tasks %4d--%4d / %4d; rows %4d\n', ...
        first,last,numel(pending),numel(rows));
end

N=sortrows(struct2table(rows),{'seed','cell','arm'});
writetable(N,fullfile(expRun.dir,'native_tidy.csv'));
copyfile(fullfile(parentRunDir,'formation_tidy.csv'), ...
    fullfile(expRun.dir,'formation_tidy.csv'));

gates=correctionGates(N,parentRunDir,R);
writetable(gates,fullfile(expRun.dir,'integrity_gates.csv'));
fprintf('\nEXP20A native correction integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-38s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
if ~all(gates.passed==1)
    save(fullfile(expRun.dir,'workspace.mat'),'N','gates','R','-v7.3');
    finishExperiment(expRun);
    error('exp20a_native_protocol_correction: integrity failure.');
end

A=analyzeExp20AResults(expRun.dir);
supersession=struct('status','SUPERSEDES_EXP20A_NATIVE_PANEL', ...
    'parentRunDir',parentRunDir, ...
    'supersededNativeFile',fullfile(parentRunDir,'native_tidy.csv'), ...
    'correctedNativeFile',fullfile(expRun.dir,'native_tidy.csv'), ...
    'formationSourceFile',fullfile(parentRunDir,'formation_tidy.csv'), ...
    'formationCopiedWithoutRecomputation',true, ...
    'correctedVerdict',A.verdict.status, ...
    'originalVerdictMayNotBeUsedForNativeClaims',true, ...
    'manuscriptClaimPermitted',false, ...
    'hardwarePolicyValidationPermitted',false);
writeJson(fullfile(expRun.dir,'supersession.json'),supersession);
save(fullfile(expRun.dir,'workspace.mat'),'N','gates','A','R', ...
    'supersession','-v7.3');
fprintf('\nCORRECTED EXP20A DEVELOPMENT VERDICT: %s\n',A.verdict.status);
finishExperiment(expRun);

end


function row=runTask(seedValue,cellIndex,armIndex,R)

c=R.nativeCells(cellIndex);
cfg=struct('N',c.N,'rho',c.rho,'epsilon',c.epsilon, ...
    'slots',R.nativeSlots,'burnIn',R.nativeBurnIn, ...
    'feedbackLoss',R.privateFeedbackLoss, ...
    'feedbackDelaySlots',R.privateFeedbackDelaySlots);
out=simulateDeltaInformationStructure(cfg,R.nativeArms{armIndex},seedValue);
row=exp20aNativeEmptyRow();
row.cell=c.id;
names=fieldnames(out);
for k=1:numel(names)
    if isfield(row,names{k}), row.(names{k})=out.(names{k}); end
end

end


function [seeds,cells,arms]=nativeTasks(R)

n=R.expectedNativeRuns;
seeds=zeros(n,1); cells=zeros(n,1); arms=zeros(n,1); q=0;
% Interleave arms within a cell and cells within a seed. Task-level parfor
% balances the expensive N=20/private runs without changing any trajectory.
for seedIndex=1:numel(R.nativeSeeds)
    for cellIndex=1:numel(R.nativeCells)
        for armIndex=1:numel(R.nativeArms)
            q=q+1;
            seeds(q)=R.nativeSeeds(seedIndex);
            cells(q)=cellIndex;
            arms(q)=armIndex;
        end
    end
end

end


function [rows,completed]=loadCheckpoint(runDir,R,seeds,cells,arms)

path=fullfile(runDir,'native_corrected_checkpoint.csv');
taskKeys=string(seeds)+'|'+string({R.nativeCells(cells).id})'+'|'+ ...
    string(R.nativeArms(arms))';
if exist(path,'file')~=2
    rows=repmat(exp20aNativeEmptyRow(),0,1);
    completed=false(numel(seeds),1);
    return;
end
T=readtable(path,'TextType','string');
if ~isequal(T.Properties.VariableNames(:),fieldnames(exp20aNativeEmptyRow()))
    error('exp20a native correction: checkpoint schema mismatch.');
end
keys=string(T.seed)+'|'+string(T.cell)+'|'+string(T.arm);
if numel(unique(keys))~=height(T) || any(~ismember(keys,taskKeys))
    error('exp20a native correction: invalid checkpoint keys.');
end
completed=ismember(taskKeys,keys);
rows=table2struct(T);
for k=1:numel(rows)
    rows(k).cell=char(rows(k).cell);
    rows(k).arm=char(rows(k).arm);
end

end


function gates=correctionGates(N,parentRunDir,R)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
parent=readtable(fullfile(parentRunDir,'integrity_gates.csv'), ...
    'TextType','string');
add('parent_formation_integrity',all(parent.passed==1), ...
    sprintf('%d/%d parent gates pass',sum(parent.passed),height(parent)));

keys=string(N.seed)+'|'+string(N.cell)+'|'+string(N.arm);
add('corrected_native_matrix_complete_unique', ...
    height(N)==R.expectedNativeRuns && numel(unique(keys))==height(N), ...
    sprintf('%d/%d unique corrected rows',height(N),R.expectedNativeRuns));
add('exact_corrected_native_seeds',isequal(unique(N.seed),R.nativeSeeds), ...
    'all and only 30 frozen native seeds');

paired=true;
for seed=R.nativeSeeds'
    for cellIndex=1:numel(R.nativeCells)
        c=R.nativeCells(cellIndex);
        idx=N.seed==seed & string(N.cell)==string(c.id);
        paired=paired && nnz(idx)==numel(R.nativeArms) && ...
            isscalar(unique(N.DRAW_HASH_EXACT(idx)));
    end
end
add('corrected_native_absolute_draw_pairing',paired, ...
    'five arms share one absolute draw tensor in every group');

causal=all(N.FUTURE_FEEDBACK_READS==0) && ...
    all(N.MAX_FEEDBACK_QUEUE<=R.privateFeedbackDelaySlots(2)+1);
add('corrected_private_feedback_causality',causal, ...
    sprintf('future reads %d; max queue %d', ...
    sum(N.FUTURE_FEEDBACK_READS),max(N.MAX_FEEDBACK_QUEUE)));

accounting=all(N.ATTEMPTS>=N.SUCCESSES) && ...
    all(N.ATTEMPTS>=N.COLLISIONS) && all(isfinite(N.MEAN_AOII)) && ...
    all(N.MEAN_AOII>=0);
add('corrected_native_accounting_finite',accounting, ...
    'attempt/success/collision ordering and finite AoII hold');

pub=string(N.arm)=='delta-public';
priv=string(N.arm)=='delta-private-delayed';
active=all(N.FEEDBACK_GENERATED(pub)>0) && ...
    all(N.FEEDBACK_GENERATED(priv)>0) && ...
    sum(N.FEEDBACK_DROPPED(priv))>0 && max(N.MAX_FEEDBACK_QUEUE(priv))>0;
add('corrected_feedback_paths_activated',active, ...
    'public and delayed/lossy private feedback paths exercised');

gates=table(string(names),double(passed),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(name,flag,textValue)
        names{end+1,1}=name;
        passed(end+1,1)=logical(flag);
        detail{end+1,1}=textValue;
    end

end


function validateParent(parentRunDir,R)

required={'formation_tidy.csv','integrity_gates.csv', ...
    'development_registry.json','native_tidy.csv'};
for k=1:numel(required)
    if exist(fullfile(parentRunDir,required{k}),'file')~=2
        error('exp20a native correction: parent missing %s.',required{k});
    end
end
F=readtable(fullfile(parentRunDir,'formation_tidy.csv'),'TextType','string');
if height(F)~=R.expectedFormationRuns
    error('exp20a native correction: parent formation matrix incomplete.');
end

end


function snapshotCorrection(target)

root=projectRoot();
files={'docs/EXP20A_PRIOR_ART_BASELINE_CLOSURE_PLAN.md', ...
    'docs/EXP20A_NATIVE_PROTOCOL_CORRECTION_2026-09-01.md', ...
    'network/simulateDeltaInformationStructure.m', ...
    'utils/exp20aRegistry.m','utils/exp20aNativeEmptyRow.m', ...
    'utils/pairedBootstrapCI.m','tests/test_exp20a_delta_contracts.m', ...
    'experiments/analyzeExp20AResults.m', ...
    'experiments/validateExp20ADeltaUpstream.m', ...
    'experiments/exp20a_native_protocol_correction.m'};
freeze=fullfile(target,'corrected_source');
if ~isfolder(freeze), mkdir(freeze); end
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function expRun=resumeCorrection(runDir,parentRunDir)

record=jsondecode(fileread(fullfile(runDir,'correction_opened.json')));
if ~strcmp(record.parentRunDir,parentRunDir)
    error('exp20a native correction: resume parent mismatch.');
end
[expRoot,runId]=fileparts(runDir);
expRun=struct('name','exp20a_native_protocol_correction', ...
    'runId',runId,'expRoot',expRoot,'dir',runDir, ...
    'figDir',fullfile(runDir,'figures'),'t0',tic);
v=ver; v=v(strcmp({v.Name},'MATLAB'));
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',record.openedAt, ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed EXP20A native protocol correction','sourceFile','');
expRun.logFile=fullfile(runDir,'console.log');
diary(expRun.logFile); diary on;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp20a native correction: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
