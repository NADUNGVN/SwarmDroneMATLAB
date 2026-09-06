function exp14g_branch_at_decision(resumeDir)
%EXP14G_BRANCH_AT_DECISION Prehistory-matched causal ACK replay study.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp14gRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=52831592 || registryLeaves~=31
    error('exp14g: frozen registry mismatch.');
end
runScriptIsolated('test_ack_branch_replay');
runScriptIsolated('test_exp14g_contracts');

batchSize=16;
if isempty(resumeDir)
    expRun=startExperiment('exp14g_branch_at_decision', ...
        ['Outcome-blind branch-at-decision ACK replay with identical ' ...
         'prehistory; development only, no predictor fitting.']);
    snapshotSource(expRun.dir);
    writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
    locked=struct('lockedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'firstSeed',R.seeds(1),'lastSeed',R.seeds(end), ...
        'selectionUsesOutcome',false,'predictorFittingPermitted',false, ...
        'performanceGateDefined',false,'designMayChange',false);
    writeJson(fullfile(expRun.dir,'design_locked.json'),locked);

    [groupSeed,groupCell]=groups(R);
    nGroup=numel(groupSeed);
    pilotRows=repmat(exp14gEmptyPilotRow(),0,1);
    candidateRows=repmat(exp14gEmptyCandidateRow(),0,1);
    fprintf('EXP14G pilot: %d selected-policy runs.\n',nGroup);
    for first=1:batchSize:nGroup
        last=min(first+batchSize-1,nGroup);
        index=first:last;
        batch=cell(numel(index),1);
        parfor (q=1:numel(index),12)
            g=index(q);
            batch{q}=runPilot(groupSeed(g),groupCell(g),R);
        end
        for q=1:numel(batch)
            pilotRows(end+1,1)=batch{q}.pilot; %#ok<AGROW>
            candidateRows=[candidateRows; batch{q}.candidates(:)]; %#ok<AGROW>
        end
        writeTableAtomic(struct2table(pilotRows), ...
            fullfile(expRun.dir,'pilot_runs_checkpoint.csv'));
        writeTableAtomic(struct2table(candidateRows), ...
            fullfile(expRun.dir,'pilot_candidates_checkpoint.csv'));
        fprintf('  pilot %3d--%3d / %3d; candidates %d\n', ...
            first,last,nGroup,numel(candidateRows));
    end

    pilot=struct2table(pilotRows);
    candidates=struct2table(candidateRows);
    writetable(pilot,fullfile(expRun.dir,'pilot_runs.csv'));
    writetable(candidates,fullfile(expRun.dir,'pilot_candidates.csv'));
    selection=selectExp14GCandidates(candidates,R);
    [selectionHash,selectionLeaves]=configHash(table2struct(selection));
    writetable(selection,fullfile(expRun.dir,'selected_events.csv'));
    selectionLock=struct('lockedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')), ...
        'selectionHash',selectionHash,'selectionLeaves',selectionLeaves, ...
        'selectedEvents',height(selection),'outcomesInspected',false, ...
        'selectionRule', ...
        'new-stratum/new-seed priority pass, then new-seed priority fill');
    writeJson(fullfile(expRun.dir,'selection_locked.json'),selectionLock);
    printSelection(selection,R,selectionHash);
else
    [expRun,pilot,candidates,selection]=resumeReplay( ...
        resumeDir,registryHash,registryLeaves,R);
end

selectedStruct=table2struct(selection);
pairs=repmat(exp14gEmptyPairRow(),0,1);
fprintf('\nEXP14G causal replay: %d pairs, %d simulations.\n', ...
    numel(selectedStruct),2*numel(selectedStruct));
for first=1:batchSize:numel(selectedStruct)
    last=min(first+batchSize-1,numel(selectedStruct));
    index=first:last;
    batch=cell(numel(index),1);
    parfor (q=1:numel(index),12)
        batch{q}=runReplay(selectedStruct(index(q)),R);
    end
    for q=1:numel(batch), pairs(end+1,1)=batch{q}; end %#ok<AGROW>
    writeTableAtomic(struct2table(pairs), ...
        fullfile(expRun.dir,'branch_pairs_checkpoint.csv'));
    fprintf('  replay pairs %3d--%3d / %3d\n', ...
        first,last,numel(selectedStruct));
end

pairTable=struct2table(pairs);
writetable(pairTable,fullfile(expRun.dir,'branch_pairs.csv'));
gates=integrityGates(pilot,candidates,selection,pairTable,R, ...
    registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
integrity=struct('status',ternary(all(gates.passed==1),'PASS','FAIL'), ...
    'gatesPassed',nnz(gates.passed),'gatesTotal',height(gates), ...
    'pilotRuns',height(pilot),'candidateEvents',height(candidates), ...
    'selectedEvents',height(selection),'branchPairs',height(pairTable), ...
    'performanceIsIntegrityGate',false,'negativeResultsRetained',true);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrity);

fprintf('\nEXP14G integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-31s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp14GResults(expRun.dir);
    fprintf('\nEXP14G causal summary\n'); disp(analysis.summary);
else
    analysis=struct();
    fprintf('\nEXP14G analysis withheld because integrity failed.\n');
end
save(fullfile(expRun.dir,'workspace.mat'),'pilot','candidates', ...
    'selection','pairTable','gates','integrity','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp14g_branch_at_decision: integrity gates failed.');
end

end


function result=runPilot(seedValue,cellIndex,R)

cellDef=R.cells(cellIndex);
[cfg,method]=applyExp14GCell(cellDef.id,seedValue);
trace=generateSharedMediumTrace(cfg);
out=simSwarmSharedMedium(cfg,method,trace);
M=computeSharedMediumMetrics(out,cfg);
Q=compute6DOFMetrics(out,cfg);
C=flattenExp14GCandidates(out,cfg,cellDef);
row=exp14gEmptyPilotRow();
row.seed=seedValue; row.scenario=cellDef.id;
row.scenarioLabel=cellDef.label; row.N=cfg.swarm.N;
row.candidateCount=numel(C);
row.admittedCandidateCount=sum([C.physicalAdmitted]);
row.eligibleCandidateCount=sum([C.eligible]);
row.ACK_STANDALONE=M.ackFramesStandalone;
row.ACK_ENTRIES_DELIVERED=M.ackEntriesDelivered;
row.ADAPTIVE_ACK_PERMITTED=M.adaptiveAckPermitted;
row.DIVERGED=double(Q.diverged);
row.INVARIANT_VIOLATIONS=M.invariantViolations;
row.MAX_QUEUE=M.maxQueueDepth; row.MAX_HISTORY=M.maxHistoryDepth;
row.TRACE_HASH_EXACT=out.traceHashExact;
row.CHANNEL_STATE_HASH=out.channelStateHash;
row.CONFIG_HASH=configHash(cfg);
result=struct('pilot',row,'candidates',C);

end


function row=runReplay(selection,R)

[base,method]=applyExp14GCell(char(selection.scenario),selection.seed);
trace=generateSharedMediumTrace(base);
endTime=ceil((selection.decisionTime+R.localHorizon)/base.swarm.dt-1e-12) ...
    *base.swarm.dt;
realized=endTime-selection.decisionTime;
actual=applyExp14GReplay(base,'admit-target', ...
    selection.candidateOrdinal,realized);
shadow=applyExp14GReplay(base,'suppress-target', ...
    selection.candidateOrdinal,realized);
outA=simSwarmSharedMedium(actual,method,trace);
outS=simSwarmSharedMedium(shadow,method,trace);
row=analyzeAckBranchPair(outA,outS,actual,selection);

end


function gates=integrityGates(P,C,S,B,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
add('registry_contract',registryHash==52831592 && registryLeaves==31, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
keys=string(P.seed)+"|"+P.scenario;
add('pilot_matrix',height(P)==R.expectedPilotRuns && ...
    numel(unique(keys))==R.expectedPilotRuns, ...
    sprintf('%d unique pilot runs',height(P)));
add('pilot_integrity',all(P.DIVERGED==0) && ...
    all(P.INVARIANT_VIOLATIONS==0) && all(P.MAX_QUEUE<=4) && ...
    all(P.MAX_HISTORY<=32),'finite causal bounded pilot runs');
add('candidate_accounting',height(C)==sum(P.candidateCount) && ...
    all(P.candidateCount==P.ADAPTIVE_ACK_PERMITTED), ...
    sprintf('%d permitted-decision rows',height(C)));

reselected=selectExp14GCandidates(C,R);
selectionExact=isequaln(S,reselected);
add('selection_reproducible',selectionExact, ...
    'selection recomputes exactly from pre-decision covariates');
support=true;
supportText=strings(numel(R.cells),1);
for c=1:numel(R.cells)
    Q=S(S.scenario==string(R.cells(c).id),:);
    support=support && height(Q)>=R.minimumEventsPerCell && ...
        height(Q)<=R.targetEventsPerCell && ...
        numel(unique(Q.seed))==height(Q);
    supportText(c)=sprintf('%s=%d',R.cells(c).id,height(Q));
end
add('selection_support',support,strjoin(supportText,', '));
pairKeys=string(B.seed)+"|"+B.scenario+"|"+string(B.candidateOrdinal);
selectedKeys=string(S.seed)+"|"+S.scenario+"|"+string(S.candidateOrdinal);
add('replay_completeness',height(B)==height(S) && ...
    isequal(sort(pairKeys),sort(selectedKeys)), ...
    sprintf('%d branch pairs',height(B)));
add('shared_predecision_state',all(B.preNetworkHash>0) && ...
    all(B.preContextHash>0) && all(B.actualTargetReached) && ...
    all(B.shadowTargetReached),'target hashes matched inside pair analyzer');
add('intervention_semantics',all(B.actualTargetAdmitted) && ...
    all(~B.shadowTargetAdmitted) && ...
    all(B.suppressedEntries==B.nEntries), ...
    'only target obligations are excluded from standalone service');
finiteFields={'meanLeadSeconds','ackAirtimeCost','dataAirtimeSaved', ...
    'netAirtimeBenefit','trueAoIIntegralBenefit', ...
    'controlLossIntegralBenefit'};
finite=true;
for k=1:numel(finiteFields), finite=finite && all(isfinite(B.(finiteFields{k}))); end
add('finite_pair_outputs',finite,'all causal effects are finite');
add('causal_protocol',all(B.actualInvariantViolations==0) && ...
    all(B.shadowInvariantViolations==0) && ...
    all(B.actualDiverged==0) && all(B.shadowDiverged==0), ...
    'zero divergence and invariant violations in both branches');
add('airtime_identity',max(abs(B.accountingResidual))<1e-12, ...
    sprintf('max residual %.3g s',max(abs(B.accountingResidual))));
leadOk=all(B.positiveLeadEntries<=B.nEntries) && ...
    all(B.actualConfirmedEntries<=B.nEntries) && ...
    all(B.shadowConfirmedEntries<=B.nEntries) && ...
    all(B.meanLeadSeconds>=0 & B.meanLeadSeconds<=B.realizedHorizon+1e-12) && ...
    all(B.maxLeadSeconds>=B.meanLeadSeconds-1e-12 & ...
    B.maxLeadSeconds<=B.realizedHorizon+1e-12);
add('lead_contract',leadOk,'entry leads respect censoring and local horizon');
add('development_claim_boundary',~R.confirmatoryClaimPermitted && ...
    ~R.thresholdTuningPermitted && ~R.predictorFittingPermitted, ...
    'performance is reported but never gates or fits a predictor');
gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

    function add(name,flag,textValue)
        names{end+1,1}=name;
        passed(end+1,1)=logical(flag);
        detail{end+1,1}=char(textValue);
    end

end


function printSelection(S,R,hash)

fprintf('\nOutcome-blind selection locked: hash %.0f, %d events.\n',hash,height(S));
for c=1:numel(R.cells)
    Q=S(S.scenario==string(R.cells(c).id),:);
    fprintf('  %-12s %2d events from %2d distinct seeds\n', ...
        R.cells(c).id,height(Q),numel(unique(Q.seed)));
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


function [expRun,pilot,candidates,selection]=resumeReplay( ...
    runDir,registryHash,registryLeaves,R)

runDir=char(runDir);
required={'design_locked.json','selection_locked.json','pilot_runs.csv', ...
    'pilot_candidates.csv','selected_events.csv'};
for k=1:numel(required)
    if exist(fullfile(runDir,required{k}),'file')~=2
        error('exp14g: recovery artifact %s is missing.',required{k});
    end
end
if exist(fullfile(runDir,'branch_pairs.csv'),'file')==2 || ...
        exist(fullfile(runDir,'branch_pairs_checkpoint.csv'),'file')==2
    error('exp14g: recovery requires zero previously written outcome rows.');
end
locked=jsondecode(fileread(fullfile(runDir,'design_locked.json')));
selectionLock=jsondecode(fileread(fullfile(runDir,'selection_locked.json')));
if locked.registryHash~=registryHash || ...
        locked.registryLeaves~=registryLeaves || locked.designMayChange || ...
        selectionLock.outcomesInspected
    error('exp14g: recovery lock mismatch.');
end
pilot=readtable(fullfile(runDir,'pilot_runs.csv'), ...
    'TextType','string','Delimiter',',');
candidates=readtable(fullfile(runDir,'pilot_candidates.csv'), ...
    'TextType','string','Delimiter',',');
selection=readtable(fullfile(runDir,'selected_events.csv'), ...
    'TextType','string','Delimiter',',');
[selectionHash,selectionLeaves]=configHash(table2struct(selection));
if selectionHash~=selectionLock.selectionHash || ...
        selectionLeaves~=selectionLock.selectionLeaves || ...
        height(pilot)~=R.expectedPilotRuns
    error('exp14g: recovery data or selection hash mismatch.');
end

amendment=struct( ...
    'status','RECOVERY_BEFORE_ANY_OUTCOME_ROW', ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'failure','shortening cfg.swarm.T changed colon-grid rounding and prehistory', ...
    'repair', ...
    ['retain the full 12 s branch grid and extract cumulative/local outcomes ' ...
     'at the frozen first-control-tick window end'], ...
    'selectionHash',selectionHash,'selectionChanged',false, ...
    'outcomeRowsPreviouslyWritten',false, ...
    'performanceOutcomeInspected',false);
writeJson(fullfile(runDir,'replay_recovery_amendment.json'),amendment);
recoverySource=fullfile(runDir,'recovery_source');
if ~exist(recoverySource,'dir'), mkdir(recoverySource); end
recoveryFiles={'experiments/exp14g_branch_at_decision.m', ...
    'utils/analyzeAckBranchPair.m','tests/test_exp14g_contracts.m', ...
    'docs/EXP14G_BRANCH_AT_DECISION_PLAN.md'};
for k=1:numel(recoveryFiles)
    name=replace(recoveryFiles{k},{'/' '\'},'__');
    copyfile(fullfile(projectRoot(),recoveryFiles{k}), ...
        fullfile(recoverySource,name));
end

[expRoot,runId]=fileparts(runDir); v=ver('MATLAB');
expRun.name='exp14g_branch_at_decision'; expRun.runId=runId;
expRun.expRoot=expRoot; expRun.dir=runDir;
expRun.figDir=fullfile(runDir,'figures');
expRun.logFile=fullfile(runDir,'console.log');
expRun.notes='Replay recovery after prehistory identity gate; selection unchanged.';
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',locked.lockedAt, ...
    'resumedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes',expRun.notes,'sourceFile',which(expRun.name));
expRun.t0=tic; diary(expRun.logFile); diary on;
fprintf('\nEXP14G REPLAY RECOVERY: %s\n',runId);
fprintf('Selection hash %.0f unchanged; zero prior outcome rows.\n',selectionHash);
printSelection(selection,R,selectionHash);

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP14G_BRANCH_AT_DECISION_PLAN.md', ...
    'utils/exp14gRegistry.m','utils/applyExp14GCell.m', ...
    'utils/applyExp14GReplay.m','utils/exp14gEmptyPilotRow.m', ...
    'utils/exp14gEmptyCandidateRow.m','utils/exp14gEmptyPairRow.m', ...
    'utils/selectExp14GCandidates.m','utils/flattenExp14GCandidates.m', ...
    'utils/analyzeAckBranchPair.m','network/ackBranchReplayConfig.m', ...
    'network/initSharedMediumState.m','network/advanceSharedMedium.m', ...
    'simulation/simSwarmSharedMedium.m', ...
    'experiments/analyzeExp14GResults.m', ...
    'experiments/exp14g_branch_at_decision.m', ...
    'tests/test_ack_branch_replay.m','tests/test_exp14g_contracts.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14g: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
