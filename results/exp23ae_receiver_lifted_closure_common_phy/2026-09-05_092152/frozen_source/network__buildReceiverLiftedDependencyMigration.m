function M=buildReceiverLiftedDependencyMigration(oldGraph,newGraph, ...
    oldSlot,initiator,managementReach,config)
%BUILDRECEIVERLIFTEDDEPENDENCYMIGRATION Close and recolor changed endpoints.

N=size(oldGraph,1);
validateGraph(oldGraph,N,'oldGraph',true);
validateGraph(newGraph,N,'newGraph',true);
validateGraph(managementReach,N,'managementReach',false);
if ~isnumeric(oldSlot) || ~isequal(size(oldSlot),[N 1]) || ...
        any(~isfinite(oldSlot)) || any(oldSlot<1) || ...
        any(oldSlot~=floor(oldSlot))
    error('buildReceiverLiftedDependencyMigration: invalid oldSlot.');
end
if ~isscalar(initiator) || initiator<1 || initiator>N || ...
        initiator~=floor(initiator)
    error('buildReceiverLiftedDependencyMigration: invalid initiator.');
end
required={'maxDataSlots','maxAffectedNodes','prepareHeaderBytes', ...
    'affectedEntryBytes','claimBytes','certificateHeaderBytes', ...
    'certificateEntryBytes','maxControlPacketBytes','revokeBytes'};
for k=1:numel(required)
    if ~isfield(config,required{k})
        error('buildReceiverLiftedDependencyMigration: missing config.%s.', ...
            required{k});
    end
    value=config.(required{k});
    if ~isscalar(value) || ...
            ~isfinite(value) || value<=0 || value~=floor(value)
        error('buildReceiverLiftedDependencyMigration: invalid config.%s.', ...
            required{k});
    end
end
if any(oldSlot>config.maxDataSlots)
    error('buildReceiverLiftedDependencyMigration: oldSlot exceeds slots.');
end

F0=logical(oldGraph); F1=logical(newGraph); FU=F0|F1;
delta=xor(F0,F1);
[a,b]=find(triu(delta,1));
endpointMask=false(N,1); endpointMask(unique([a;b]))=true;
affectedMask=endpointMask; affectedMask(initiator)=true;
affected=find(affectedMask); outside=find(~affectedMask);
outsideDelta=delta;
outsideDelta(affected,:)=false; outsideDelta(:,affected)=false;
outsideUnchanged=~any(outsideDelta,'all');
oldProper=isProper(F0,oldSlot);

degree=sum(FU,2);
orderTable=[-degree(affected) affected];
orderTable=sortrows(orderTable,[1 2]);
order=orderTable(:,2);
candidate=oldSlot;
candidate(affected)=0;
slotAvailable=true;
for node=reshape(order,1,[])
    neighbors=find(FU(:,node));
    used=unique(candidate(neighbors)); used(used==0)=[];
    available=setdiff((1:config.maxDataSlots)',used,'stable');
    if isempty(available)
        slotAvailable=false; break;
    end
    candidate(node)=available(1);
end
candidateProper=slotAvailable && all(candidate>0) && isProper(FU,candidate);

reach=logical(managementReach); reach(1:N+1:end)=false;
remote=affected(affected~=initiator);
prepareCovered=all(reach(remote,initiator));
quietCovered=all(reach(initiator,remote));
W=buildConflictWitnessMap(FU,reach);
incidentMask=triu(FU & (affectedMask|affectedMask'),1);
[ea,eb]=find(incidentMask);
edgeWitness=zeros(numel(ea),1);
for k=1:numel(ea), edgeWitness(k)=W.witness(ea(k),eb(k)); end
witnessCovered=all(edgeWitness>0);
witnessLoad=zeros(N,1);
for w=reshape(edgeWitness(edgeWitness>0),1,[])
    witnessLoad(w)=witnessLoad(w)+1;
end
maxEntries=max([0;witnessLoad]);
prepareBytes=config.prepareHeaderBytes+ ...
    numel(affected)*config.affectedEntryBytes;
maxResponseBytes=config.certificateHeaderBytes+ ...
    maxEntries*config.certificateEntryBytes;
if maxEntries==0, maxResponseBytes=0; end
payloadAdmissible=prepareBytes<=config.maxControlPacketBytes && ...
    config.claimBytes<=config.maxControlPacketBytes && ...
    maxResponseBytes<=config.maxControlPacketBytes;
affectedBound=numel(affected)<=config.maxAffectedNodes;
changed=~isempty(a);
admissible=changed&&outsideUnchanged&&oldProper&&slotAvailable&& ...
    candidateProper&&prepareCovered&&quietCovered&&witnessCovered&& ...
    payloadAdmissible&&affectedBound;
reason='admissible';
if ~changed, reason='no_sender_graph_change';
elseif ~outsideUnchanged, reason='closure_incomplete';
elseif ~oldProper, reason='retiring_coloring_invalid';
elseif ~slotAvailable || ~candidateProper, reason='insufficient_slots';
elseif ~affectedBound, reason='affected_set_above_bound';
elseif ~prepareCovered, reason='prepare_path_missing';
elseif ~quietCovered, reason='quiescent_path_missing';
elseif ~witnessCovered, reason='union_witness_uncovered';
elseif ~payloadAdmissible, reason='control_payload_exceeds_mtu';
end

M=struct('version','RECEIVER-LIFTED-DEPENDENCY-MIGRATION-v1', ...
    'N',N,'initiator',initiator,'oldGraph',F0,'newGraph',F1, ...
    'unionGraph',FU,'changedGraph',delta, ...
    'changedEdgeCount',numel(a),'changedEdgeA',a,'changedEdgeB',b, ...
    'changedEdgeEndpointMask',endpointMask, ...
    'affectedMask',affectedMask,'affectedNodes',affected, ...
    'affectedCount',numel(affected),'outsideNodes',outside, ...
    'outsideSubgraphUnchanged',double(outsideUnchanged), ...
    'oldSlot',oldSlot,'candidateSlot',candidate, ...
    'recolorOrder',order,'oldColoringProper',double(oldProper), ...
    'candidateUnionColoringProper',double(candidateProper), ...
    'slotAvailable',double(slotAvailable), ...
    'changedSlotCount',nnz(candidate~=oldSlot), ...
    'managementReach',reach,'prepareCovered',double(prepareCovered), ...
    'quiescentAckCovered',double(quietCovered), ...
    'unionWitnessMap',W,'incidentEdgeA',ea,'incidentEdgeB',eb, ...
    'incidentEdgeWitness',edgeWitness, ...
    'incidentUnionEdgeCount',numel(ea), ...
    'witnessLoad',witnessLoad,'maxWitnessEntries',maxEntries, ...
    'prepareBytes',prepareBytes,'maxResponseBytes',maxResponseBytes, ...
    'payloadAdmissible',double(payloadAdmissible), ...
    'affectedBoundSatisfied',double(affectedBound), ...
    'config',config,'admissible',double(admissible),'reason',reason);
M.hashExact=realizationHash([double(F0(:));double(F1(:));oldSlot; ...
    initiator;double(reach(:));double(affectedMask);candidate;order; ...
    edgeWitness;prepareBytes;maxResponseBytes;double(admissible)]);

end


function validateGraph(value,N,name,symmetric)

if ~(isnumeric(value)||islogical(value)) || ...
        ~isequal(size(value),[N N]) || any(diag(value))
    error('buildReceiverLiftedDependencyMigration: invalid %s.',name);
end
if symmetric && ~isequal(logical(value),logical(value)')
    error('buildReceiverLiftedDependencyMigration: %s not symmetric.',name);
end

end


function proper=isProper(graph,slot)

[a,b]=find(triu(logical(graph),1));
proper=all(slot(a)~=slot(b));

end
