function S=selectExp14GCandidates(C,R)
%SELECTEXP14GCANDIDATES Deterministic outcome-blind stratified event sample.

if nargin<2 || isempty(R), R=exp14gRegistry(); end
required=fieldnames(exp14gEmptyCandidateRow());
if ~istable(C) || ~all(ismember(required,C.Properties.VariableNames))
    error('selectExp14GCandidates: candidate table schema mismatch.');
end
C.scenario=string(C.scenario);
C.scenarioLabel=string(C.scenarioLabel);
C.stratum=string(C.stratum);
if any(~ismember(C.scenario,string({R.cells.id}))) || ...
        any(~ismember(C.seed,R.seeds))
    error('selectExp14GCandidates: candidate outside the registry.');
end

C.eligible=logical(C.physicalAdmitted) & ...
    C.decisionTime>=R.eligibleStart-1e-12;
for k=1:height(C)
    cfg=applyExp14ECell(char(C.scenario(k)),0);
    endTime=ceil((C.decisionTime(k)+R.localHorizon)/cfg.swarm.dt-1e-12) ...
        *cfg.swarm.dt;
    C.eligible(k)=C.eligible(k) && endTime<=cfg.swarm.T+1e-12;
    busyBin=find(C.localBusy(k)<R.busyBinEdges(2:end),1);
    ageBin=find(C.pendingAge(k)<R.ageBinEdges(2:end),1);
    entryBin=1+double(C.nEntries(k)>1);
    C.stratum(k)=string(sprintf('b%d-a%d-e%d-f%d', ...
        busyBin,ageBin,entryBin,double(C.forced(k))));
    cellIndex=find(strcmp({R.cells.id},char(C.scenario(k))),1);
    C.priority(k)=realizationHash(double([R.selectionSalt; ...
        C.seed(k); C.candidateOrdinal(k); cellIndex]));
end

S=C([],required);
for c=1:numel(R.cells)
    Q=C(C.scenario==string(R.cells(c).id) & C.eligible,:);
    Q=sortrows(Q,{'priority','seed','candidateOrdinal'});
    chosen=false(height(Q),1);
    usedSeeds=zeros(0,1);
    usedStrata=strings(0,1);

    for k=1:height(Q)
        if numel(usedSeeds)>=R.targetEventsPerCell, break; end
        if ~ismember(Q.seed(k),usedSeeds) && ...
                ~ismember(Q.stratum(k),usedStrata)
            chosen(k)=true;
            usedSeeds(end+1,1)=Q.seed(k); %#ok<AGROW>
            usedStrata(end+1,1)=Q.stratum(k); %#ok<AGROW>
        end
    end
    for k=1:height(Q)
        if numel(usedSeeds)>=R.targetEventsPerCell, break; end
        if ~chosen(k) && ~ismember(Q.seed(k),usedSeeds)
            chosen(k)=true;
            usedSeeds(end+1,1)=Q.seed(k); %#ok<AGROW>
        end
    end
    selected=Q(chosen,required);
    selected=sortrows(selected,{'priority','seed','candidateOrdinal'});
    selected.selectionRank=(1:height(selected))';
    S=[S; selected]; %#ok<AGROW>
end

end
