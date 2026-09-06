function rows=flattenExp14GCandidates(out,cfg,cellDef)
%FLATTENEXP14GCANDIDATES Convert admission logs to scalar pre-decision rows.

if ~isstruct(cellDef) || ~all(isfield(cellDef,{'id','label'}))
    error('flattenExp14GCandidates: invalid cell definition.');
end
E=out.ackAdmissionLog;
rows=repmat(exp14gEmptyCandidateRow(),numel(E),1);
R=exp14gRegistry();
for k=1:numel(E)
    e=E(k); row=exp14gEmptyCandidateRow();
    row.seed=cfg.net.seed; row.scenario=char(cellDef.id);
    row.scenarioLabel=char(cellDef.label); row.N=cfg.swarm.N;
    row.candidateOrdinal=e.candidateOrdinal;
    row.decisionTime=e.time; row.node=e.node; row.nEntries=e.nEntries;
    row.entryHash=entryHash(e);
    row.pendingAge=e.pendingAge; row.localBusy=e.localBusy;
    row.forced=logical(e.forced); row.queueDepth=e.queueDepth;
    row.preNetworkHash=e.preNetworkHash;
    row.preContextHash=e.preContextHash;
    row.physicalAdmitted=logical(e.physicalAdmitted);
    endTime=ceil((e.time+R.localHorizon)/cfg.swarm.dt-1e-12) ...
        *cfg.swarm.dt;
    row.eligible=row.physicalAdmitted && ...
        e.time>=R.eligibleStart-1e-12 && endTime<=cfg.swarm.T+1e-12;
    rows(k)=row;
end

end


function h=entryHash(e)

payload=[e.nEntries; e.targetSenders(:); -1; e.seqs(:); -2; ...
    e.genTimes(:)];
h=realizationHash(double(payload));

end
