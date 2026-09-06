function M=buildLocalUnionGraphMigration(oldGraph,newGraph,oldSlot,node, ...
    managementReach,config)
%BUILDLOCALUNIONGRAPHMIGRATION Certify one-sender union-graph recoloring.

N=size(oldGraph,1);
validateGraph(oldGraph,N,'oldGraph');
validateGraph(newGraph,N,'newGraph');
validateGraph(managementReach,N,'managementReach',false);
if ~isnumeric(oldSlot) || ~isequal(size(oldSlot),[N 1]) || ...
        any(~isfinite(oldSlot)) || any(oldSlot<1) || ...
        any(oldSlot~=floor(oldSlot))
    error('buildLocalUnionGraphMigration: oldSlot must be N integer slots.');
end
if ~isscalar(node) || node<1 || node>N || node~=floor(node)
    error('buildLocalUnionGraphMigration: node must be a valid index.');
end
required={'maxDataSlots','claimBytes','certificateHeaderBytes', ...
    'certificateEntryBytes','maxControlPacketBytes','revokeBytes'};
for k=1:numel(required)
    if ~isfield(config,required{k}) || ~isscalar(config.(required{k})) || ...
            ~isfinite(config.(required{k})) || config.(required{k})<=0 || ...
            config.(required{k})~=floor(config.(required{k}))
        error('buildLocalUnionGraphMigration: invalid config.%s.',required{k});
    end
end
if any(oldSlot>config.maxDataSlots)
    error('buildLocalUnionGraphMigration: oldSlot exceeds maxDataSlots.');
end

oldGraph=logical(oldGraph); newGraph=logical(newGraph);
managementReach=logical(managementReach);
unionGraph=oldGraph | newGraph;
changed=xor(oldGraph,newGraph);
outside=true(N); outside(node,:)=false; outside(:,node)=false;
nonlocalChanged=triu(changed & outside,1);
localOnly=~any(nonlocalChanged,'all');
oldProper=isProper(oldGraph,oldSlot);

neighbors=find(unionGraph(:,node));
blockedSlots=unique(oldSlot(neighbors));
available=setdiff((1:config.maxDataSlots)',blockedSlots,'stable');
slotAvailable=~isempty(available);
newSlot=NaN; candidateSlot=oldSlot;
if slotAvailable
    newSlot=available(1);
    candidateSlot(node)=newSlot;
end
unionProper=slotAvailable && isProper(unionGraph,candidateSlot);

W=buildConflictWitnessMap(unionGraph,managementReach);
incident=find(unionGraph(:,node));
incidentWitness=zeros(numel(incident),1);
for k=1:numel(incident)
    incidentWitness(k)=W.witness(node,incident(k));
end
incidentCovered=all(incidentWitness>0);
localLoad=zeros(N,1);
for w=reshape(incidentWitness(incidentWitness>0),1,[])
    localLoad(w)=localLoad(w)+1;
end
maxLocalEntries=max(localLoad);
maxResponseBytes=config.certificateHeaderBytes+ ...
    maxLocalEntries*config.certificateEntryBytes;
if maxLocalEntries==0, maxResponseBytes=0; end
payloadAdmissible=config.claimBytes<=config.maxControlPacketBytes && ...
    maxResponseBytes<=config.maxControlPacketBytes;

admissible=localOnly && oldProper && slotAvailable && unionProper && ...
    W.allCovered && incidentCovered && payloadAdmissible;
reason='admissible';
if ~localOnly, reason='nonlocal_graph_change';
elseif ~oldProper, reason='retiring_coloring_invalid';
elseif ~slotAvailable, reason='no_union_safe_slot';
elseif ~unionProper, reason='candidate_union_coloring_invalid';
elseif ~W.allCovered || ~incidentCovered, reason='union_witness_uncovered';
elseif ~payloadAdmissible, reason='migration_response_exceeds_mtu';
end

added=triu(newGraph & ~oldGraph,1);
removed=triu(oldGraph & ~newGraph,1);
M=struct('version','LOCAL-UNION-GRAPH-MIGRATION-v1','N',N, ...
    'transitionNode',node,'oldGraph',oldGraph,'newGraph',newGraph, ...
    'unionGraph',unionGraph,'oldSlot',oldSlot, ...
    'managementReach',managementReach,'config',config, ...
    'candidateSlot',candidateSlot,'newSlot',newSlot, ...
    'slotChanged',double(slotAvailable && newSlot~=oldSlot(node)), ...
    'localOnly',double(localOnly),'oldColoringProper',double(oldProper), ...
    'candidateUnionColoringProper',double(unionProper), ...
    'slotAvailable',double(slotAvailable), ...
    'addedEdgeCount',nnz(added),'removedEdgeCount',nnz(removed), ...
    'incidentUnionEdgeCount',numel(incident), ...
    'unionWitnessMap',W,'incidentNodes',incident, ...
    'incidentWitness',incidentWitness,'incidentWitnessLoad',localLoad, ...
    'maxIncidentEntriesAtWitness',maxLocalEntries, ...
    'maxMigrationResponseBytes',maxResponseBytes, ...
    'payloadAdmissible',double(payloadAdmissible), ...
    'admissible',double(admissible),'reason',reason);
M.hashExact=realizationHash([double(oldGraph(:));double(newGraph(:)); ...
    oldSlot;node;double(managementReach(:));config.maxDataSlots; ...
    config.claimBytes;config.certificateHeaderBytes; ...
    config.certificateEntryBytes;config.maxControlPacketBytes; ...
    config.revokeBytes; ...
    candidateSlot;incidentWitness;localLoad;double(admissible)]);

end


function validateGraph(value,N,name,symmetric)

if nargin<4, symmetric=true; end
if ~(isnumeric(value) || islogical(value)) || ...
        ~isequal(size(value),[N N]) || any(diag(value))
    error('buildLocalUnionGraphMigration: %s must be square simple.',name);
end
if symmetric && ~isequal(logical(value),logical(value)')
    error('buildLocalUnionGraphMigration: %s must be symmetric.',name);
end

end


function proper=isProper(graph,slot)

[a,b]=find(triu(logical(graph),1));
proper=all(slot(a)~=slot(b));

end
