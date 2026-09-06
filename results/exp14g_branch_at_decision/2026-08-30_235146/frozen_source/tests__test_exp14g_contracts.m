%% TEST_EXP14G_CONTRACTS Registry, outcome-blind selection and pair smoke.

startup;
R=exp14gRegistry();
[registryHash,registryLeaves]=configHash(R);
assert(registryHash==52831592 && registryLeaves==31 && ...
    R.expectedPilotRuns==240 && R.maximumReplayPairs==80, ...
    'EXP14G registry hash, leaves and dimensions must remain frozen.');

known=[exp14Registry().seeds; exp14cRegistry().seeds; ...
    exp14dRegistry().seeds; exp14eRegistry().seeds; exp14fRegistry().seeds];
assert(numel(unique(R.seeds))==60 && isempty(intersect(R.seeds,known)), ...
    'EXP14G seeds must be unique and disjoint from all prior blocks.');
assert(~R.confirmatoryClaimPermitted && ~R.thresholdTuningPermitted && ...
    ~R.predictorFittingPermitted && ~R.selectionUsesOutcome, ...
    'EXP14G must remain outcome-blind development instrumentation.');

for k=1:numel(R.cells)
    [cfg,method]=applyExp14GCell(R.cells(k).id,0);
    assert(cfg.shared.ackBranchReplay.enabled && ...
        strcmp(cfg.shared.ackBranchReplay.mode,'observe') && ...
        strcmp(method,'mac-aware-broadcast'), ...
        'Every EXP14G pilot cell must observe the selected adaptive arm.');
end

% Synthetic selection has more eligible candidates than the fixed cap.
rows=repmat(exp14gEmptyCandidateRow(),25,1);
for k=1:25
    rows(k).seed=R.seeds(k); rows(k).scenario='n5-csma';
    rows(k).scenarioLabel='N5 CSMA'; rows(k).N=5;
    rows(k).candidateOrdinal=mod(k,4)+1;
    rows(k).decisionTime=8.2+0.01*k; rows(k).node=mod(k,5)+1;
    rows(k).nEntries=1+mod(k,2); rows(k).entryHash=k;
    rows(k).pendingAge=0.1+0.02*mod(k,3);
    rows(k).localBusy=0.1+0.2*mod(k,4); rows(k).forced=mod(k,7)==0;
    rows(k).queueDepth=mod(k,3); rows(k).preNetworkHash=100+k;
    rows(k).preContextHash=200+k; rows(k).physicalAdmitted=true;
end
C=struct2table(rows);
S1=selectExp14GCandidates(C,R);
S2=selectExp14GCandidates(C,R);
assert(height(S1)==R.targetEventsPerCell && ...
    numel(unique(S1.seed))==height(S1) && isequal(S1,S2) && ...
    isequal(S1.selectionRank,(1:height(S1))'), ...
    'Selection must be deterministic, capped and one-event-per-seed/cell.');

% Real replay smoke on an unregistered development seed.
[base,method]=applyExp14GCell('n5-csma',16019998);
base.swarm.T=4.0; base.shared.evalStart=0;
trace=generateSharedMediumTrace(base);
pilot=simSwarmSharedMedium(base,method,trace);
cellDef=R.cells(strcmp({R.cells.id},'n5-csma'));
candidates=flattenExp14GCandidates(pilot,base,cellDef);
q=find([candidates.physicalAdmitted],1);
assert(~isempty(q),'EXP14G smoke seed produced no admitted ACK candidate.');
selection=candidates(q); selection.selectionRank=1;
endTime=ceil((selection.decisionTime+R.localHorizon)/base.swarm.dt-1e-12) ...
    *base.swarm.dt;
realized=endTime-selection.decisionTime;

actual=base; actual.swarm.T=endTime;
actual=applyExp14GReplay(actual,'admit-target', ...
    selection.candidateOrdinal,realized);
shadow=base; shadow.swarm.T=endTime;
shadow=applyExp14GReplay(shadow,'suppress-target', ...
    selection.candidateOrdinal,realized);
outA=simSwarmSharedMedium(actual,method,trace);
outS=simSwarmSharedMedium(shadow,method,trace);
pair=analyzeAckBranchPair(outA,outS,actual,selection);
assert(pair.actualTargetReached && pair.shadowTargetReached && ...
    pair.actualTargetAdmitted && ~pair.shadowTargetAdmitted && ...
    pair.suppressedEntries==pair.nEntries && ...
    abs(pair.accountingResidual)<1e-12 && ...
    pair.realizedHorizon>=R.localHorizon-1e-12, ...
    'Real branch pair violates target, accounting or horizon semantics.');

bad=false;
try
    applyExp14GReplay(base,'remove-all-feedback',1,R.localHorizon);
catch
    bad=true;
end
assert(bad,'Unknown replay actions must fail at the interface boundary.');

fprintf(['test_exp14g_contracts: PASS ' ...
    '(registry, deterministic sampling, causal branch pair)\n']);
