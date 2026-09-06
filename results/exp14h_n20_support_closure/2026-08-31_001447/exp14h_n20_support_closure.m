function exp14h_n20_support_closure()
%EXP14H_N20_SUPPORT_CLOSURE Fixed N20-only causal support closure.

startup; close all;
R=exp14hRegistry(); [registryHash,registryLeaves]=configHash(R);
if registryHash~=142973713 || registryLeaves~=25
    error('exp14h: frozen registry mismatch.');
end
runScriptIsolated('test_ack_branch_replay');
runScriptIsolated('test_exp14h_contracts');
expRun=startExperiment('exp14h_n20_support_closure', ...
    ['N20-only branch-at-decision support closure; unchanged estimand, ' ...
     'outcome-blind selection, no predictor fitting.']);
snapshotSource(expRun.dir);
writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
locked=struct('lockedAt',char(datetime('now', ...
    'Format','yyyy-MM-dd HH:mm:ss')), ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'firstSeed',R.seeds(1),'lastSeed',R.seeds(end), ...
    'exp14gVerdictMayChange',false,'selectionUsesOutcome',false, ...
    'predictorFittingPermitted',false,'designMayChange',false);
writeJson(fullfile(expRun.dir,'design_locked.json'),locked);

batchSize=16;
pilotRows=repmat(exp14gEmptyPilotRow(),0,1);
candidateRows=repmat(exp14gEmptyCandidateRow(),0,1);
fprintf('EXP14H N20 pilot: %d new fixed seeds.\n',numel(R.seeds));
for first=1:batchSize:numel(R.seeds)
    last=min(first+batchSize-1,numel(R.seeds));
    seeds=R.seeds(first:last);
    batch=cell(numel(seeds),1);
    parfor (q=1:numel(seeds),12)
        batch{q}=runPilot(seeds(q),R);
    end
    for q=1:numel(batch)
        pilotRows(end+1,1)=batch{q}.pilot; %#ok<AGROW>
        candidateRows=[candidateRows; batch{q}.candidates(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(pilotRows), ...
        fullfile(expRun.dir,'pilot_runs_checkpoint.csv'));
    writeTableAtomic(struct2table(candidateRows), ...
        fullfile(expRun.dir,'pilot_candidates_checkpoint.csv'));
    fprintf('  pilot %3d--%3d / %3d; candidates %d; eligible %d\n', ...
        first,last,numel(R.seeds),numel(candidateRows),sum([candidateRows.eligible]));
end
pilot=struct2table(pilotRows); candidates=struct2table(candidateRows);
writetable(pilot,fullfile(expRun.dir,'pilot_runs.csv'));
writetable(candidates,fullfile(expRun.dir,'pilot_candidates.csv'));
selection=selectExp14GCandidates(candidates,R);
[selectionHash,selectionLeaves]=configHash(table2struct(selection));
writetable(selection,fullfile(expRun.dir,'selected_events.csv'));
selectionLock=struct('lockedAt',char(datetime('now', ...
    'Format','yyyy-MM-dd HH:mm:ss')), ...
    'selectionHash',selectionHash,'selectionLeaves',selectionLeaves, ...
    'selectedEvents',height(selection),'minimumRequired',R.minimumEventsPerCell, ...
    'outcomesInspected',false,'selectionChangedAfterPilot',false);
writeJson(fullfile(expRun.dir,'selection_locked.json'),selectionLock);
fprintf('\nEXP14H selection hash %.0f: %d events from %d seeds.\n', ...
    selectionHash,height(selection),numel(unique(selection.seed)));

if height(selection)<R.minimumEventsPerCell
    preflight=table("selection_support",0, ...
        string(sprintf('%d selected; minimum %d', ...
        height(selection),R.minimumEventsPerCell)), ...
        'VariableNames',{'gate','passed','detail'});
    writetable(preflight,fullfile(expRun.dir,'preflight_gates.csv'));
    save(fullfile(expRun.dir,'workspace.mat'),'pilot','candidates', ...
        'selection','R','-v7.3');
    finishExperiment(expRun);
    error('exp14h: support preflight failed before any outcome replay.');
end

selected=table2struct(selection);
pairs=repmat(exp14gEmptyPairRow(),0,1);
fprintf('EXP14H replay: %d pairs, %d full-grid simulations.\n', ...
    numel(selected),2*numel(selected));
for first=1:batchSize:numel(selected)
    last=min(first+batchSize-1,numel(selected));
    index=first:last; batch=cell(numel(index),1);
    parfor (q=1:numel(index),12)
        batch{q}=runReplay(selected(index(q)),R);
    end
    for q=1:numel(batch), pairs(end+1,1)=batch{q}; end %#ok<AGROW>
    writeTableAtomic(struct2table(pairs), ...
        fullfile(expRun.dir,'branch_pairs_checkpoint.csv'));
    fprintf('  replay pairs %2d--%2d / %2d\n',first,last,numel(selected));
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
    'exp14gVerdictChanged',false,'performanceIsIntegrityGate',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrity);
fprintf('\nEXP14H integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-31s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp14HResults(expRun.dir);
    fprintf('\nEXP14H causal summary\n'); disp(analysis.summary); disp(analysis.effects);
else
    analysis=struct();
end
save(fullfile(expRun.dir,'workspace.mat'),'pilot','candidates', ...
    'selection','pairTable','gates','integrity','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1), error('exp14h: integrity gates failed.'); end

end


function result=runPilot(seedValue,R)

[cfg,method]=applyExp14HCell(seedValue);
trace=generateSharedMediumTrace(cfg);
out=simSwarmSharedMedium(cfg,method,trace);
M=computeSharedMediumMetrics(out,cfg); Q=compute6DOFMetrics(out,cfg);
C=flattenExp14GCandidates(out,cfg,R.cells);
row=exp14gEmptyPilotRow(); row.seed=seedValue;
row.scenario=R.cells.id; row.scenarioLabel=R.cells.label; row.N=cfg.swarm.N;
row.candidateCount=numel(C); row.admittedCandidateCount=sum([C.physicalAdmitted]);
row.eligibleCandidateCount=sum([C.eligible]);
row.ACK_STANDALONE=M.ackFramesStandalone;
row.ACK_ENTRIES_DELIVERED=M.ackEntriesDelivered;
row.ADAPTIVE_ACK_PERMITTED=M.adaptiveAckPermitted;
row.DIVERGED=double(Q.diverged); row.INVARIANT_VIOLATIONS=M.invariantViolations;
row.MAX_QUEUE=M.maxQueueDepth; row.MAX_HISTORY=M.maxHistoryDepth;
row.TRACE_HASH_EXACT=out.traceHashExact;
row.CHANNEL_STATE_HASH=out.channelStateHash;
row.CONFIG_HASH=configHash(cfg);
result=struct('pilot',row,'candidates',C);

end


function row=runReplay(selection,R)

[base,method]=applyExp14HCell(selection.seed);
trace=generateSharedMediumTrace(base);
endTime=ceil((selection.decisionTime+R.localHorizon)/base.swarm.dt-1e-12) ...
    *base.swarm.dt;
realized=endTime-selection.decisionTime;
actual=applyExp14HReplay(base,'admit-target', ...
    selection.candidateOrdinal,realized);
shadow=applyExp14HReplay(base,'suppress-target', ...
    selection.candidateOrdinal,realized);
outA=simSwarmSharedMedium(actual,method,trace);
outS=simSwarmSharedMedium(shadow,method,trace);
row=analyzeAckBranchPair(outA,outS,actual,selection);

end


function gates=integrityGates(P,C,S,B,R,registryHash,registryLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
add('registry_contract',registryHash==142973713 && registryLeaves==25, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
add('pilot_matrix',height(P)==R.expectedPilotRuns && ...
    numel(unique(P.seed))==R.expectedPilotRuns, ...
    sprintf('%d unique N20 pilot runs',height(P)));
add('pilot_integrity',all(P.DIVERGED==0) && ...
    all(P.INVARIANT_VIOLATIONS==0) && all(P.MAX_QUEUE<=4) && ...
    all(P.MAX_HISTORY<=32),'finite causal bounded pilot runs');
add('candidate_accounting',height(C)==sum(P.candidateCount) && ...
    all(P.candidateCount==P.ADAPTIVE_ACK_PERMITTED), ...
    sprintf('%d permitted-decision rows',height(C)));
add('selection_reproducible',isequaln(S,selectExp14GCandidates(C,R)), ...
    'selection recomputes from pre-decision covariates');
add('selection_support',height(S)>=R.minimumEventsPerCell && ...
    height(S)<=R.targetEventsPerCell && numel(unique(S.seed))==height(S), ...
    sprintf('%d distinct parent seeds; minimum %d', ...
    height(S),R.minimumEventsPerCell));
pairKeys=string(B.seed)+"|"+string(B.candidateOrdinal);
selectedKeys=string(S.seed)+"|"+string(S.candidateOrdinal);
add('replay_completeness',height(B)==height(S) && ...
    isequal(sort(pairKeys),sort(selectedKeys)),sprintf('%d branch pairs',height(B)));
add('shared_predecision_state',all(B.preNetworkHash>0) && ...
    all(B.preContextHash>0) && all(B.actualTargetReached) && ...
    all(B.shadowTargetReached),'all target hashes matched');
add('intervention_semantics',all(B.actualTargetAdmitted) && ...
    all(~B.shadowTargetAdmitted) && all(B.suppressedEntries==B.nEntries), ...
    'target obligations alone excluded from standalone service');
finiteFields={'meanLeadSeconds','ackAirtimeCost','dataAirtimeSaved', ...
    'netAirtimeBenefit','trueAoIIntegralBenefit','controlLossIntegralBenefit'};
finite=true;
for k=1:numel(finiteFields), finite=finite && all(isfinite(B.(finiteFields{k}))); end
add('finite_pair_outputs',finite,'all causal effects finite');
add('causal_protocol',all(B.actualInvariantViolations==0) && ...
    all(B.shadowInvariantViolations==0) && all(B.actualDiverged==0) && ...
    all(B.shadowDiverged==0),'zero divergence and protocol violations');
add('airtime_identity',max(abs(B.accountingResidual))<1e-12, ...
    sprintf('max residual %.3g s',max(abs(B.accountingResidual))));
leadOk=all(B.positiveLeadEntries<=B.nEntries) && ...
    all(B.meanLeadSeconds>=0 & B.meanLeadSeconds<=B.realizedHorizon+1e-12) && ...
    all(B.maxLeadSeconds>=B.meanLeadSeconds-1e-12 & ...
    B.maxLeadSeconds<=B.realizedHorizon+1e-12);
add('lead_contract',leadOk,'entry leads remain horizon-capped');
add('claim_boundary',~R.confirmatoryClaimPermitted && ...
    ~R.thresholdTuningPermitted && ~R.predictorFittingPermitted, ...
    'support closure cannot tune or validate a policy');
gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

    function add(name,flag,textValue)
        names{end+1,1}=name; passed(end+1,1)=logical(flag);
        detail{end+1,1}=char(textValue);
    end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP14H_N20_SUPPORT_CLOSURE_PLAN.md', ...
    'utils/exp14hRegistry.m','utils/applyExp14HCell.m', ...
    'utils/applyExp14HReplay.m','utils/selectExp14GCandidates.m', ...
    'utils/flattenExp14GCandidates.m','utils/analyzeAckBranchPair.m', ...
    'network/ackBranchReplayConfig.m','network/advanceSharedMedium.m', ...
    'simulation/simSwarmSharedMedium.m', ...
    'experiments/analyzeExp14HResults.m', ...
    'experiments/exp14h_n20_support_closure.m', ...
    'tests/test_ack_branch_replay.m','tests/test_exp14h_contracts.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14h: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
