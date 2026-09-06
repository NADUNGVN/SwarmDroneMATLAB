function S=selectCoherenceLeaseHorizon(state,candidateHorizonsSec,C)
%SELECTCOHERENCELEASEHORIZON Largest locally certifiable motion horizon.

required={'interferenceRadius','managementReach','maxDataSlots', ...
    'claimBytes','certificateHeaderBytes','certificateEntryBytes', ...
    'maxControlPacketBytes'};
if ~isstruct(C) || ~all(isfield(C,required))
    error('selectCoherenceLeaseHorizon: incomplete configuration.');
end
h=double(candidateHorizonsSec(:));
if isempty(h) || any(~isfinite(h)) || any(h<0) || ...
        any(diff(h)<=0)
    error('selectCoherenceLeaseHorizon: horizons must increase strictly.');
end
N=size(state.p,1);
if ~isequal(size(C.managementReach),[N N]) || ...
        ~isscalar(C.maxDataSlots) || C.maxDataSlots<1
    error('selectCoherenceLeaseHorizon: invalid reach/slot configuration.');
end
mandatory=false(N);
if isfield(C,'mandatoryConflictGraph')
    mandatory=logical(C.mandatoryConflictGraph);
end

feasible=false(numel(h),1); colors=zeros(numel(h),1);
covered=false(numel(h),1); payloadFits=false(numel(h),1);
edgeCount=zeros(numel(h),1); graphHash=zeros(numel(h),1);
graphs=cell(numel(h),1); witness=cell(numel(h),1);
for k=1:numel(h)
    if isfield(C,'dataNeighborGraph')
        G=buildReachableBroadcastConflictSupergraph( ...
            state,h(k),C.interferenceRadius,C.dataNeighborGraph,mandatory);
    else
        G=buildReachableConflictSupergraph( ...
            state,h(k),C.interferenceRadius,mandatory);
    end
    W=buildConflictWitnessMap(G.potentialGraph,C.managementReach);
    color=elcsWitnessPriorityColor(G.potentialGraph);
    colorCount=max(color);
    entriesPerPacket=floor((C.maxControlPacketBytes- ...
        C.certificateHeaderBytes)/C.certificateEntryBytes);
    fit=W.allCovered && max(W.responseEntryLoad)<=entriesPerPacket;
    feasible(k)=W.allCovered && fit && colorCount<=C.maxDataSlots;
    colors(k)=colorCount; covered(k)=W.allCovered; payloadFits(k)=fit;
    edgeCount(k)=G.edgeCount; graphHash(k)=G.hashExact;
    graphs{k}=G; witness{k}=W;
end

selected=find(feasible,1,'last');
if isempty(selected)
    selected=0;
    selectedHorizon=0; selectedGraph=[]; selectedWitness=[];
    selectedColor=zeros(N,1);
else
    selectedHorizon=h(selected); selectedGraph=graphs{selected};
    selectedWitness=witness{selected};
    selectedColor=elcsWitnessPriorityColor( ...
        selectedGraph.potentialGraph);
end
S=struct('version','COHERENCE-LEASE-SELECTOR-v1', ...
    'candidateHorizonsSec',h,'feasible',feasible, ...
    'colorCount',colors,'witnessCovered',covered, ...
    'payloadFitsSingleResponse',payloadFits,'edgeCount',edgeCount, ...
    'graphHashExact',graphHash,'selectedIndex',selected, ...
    'selectedHorizonSec',selectedHorizon,'selectedGraph',selectedGraph, ...
    'selectedWitnessMap',selectedWitness,'selectedColor',selectedColor, ...
    'causalStateOnly',true,'futureRandomReads',0, ...
    'receiverTruthDecisionReads',0);
S.hashExact=realizationHash([h;double(feasible);colors; ...
    double(covered);double(payloadFits);edgeCount;graphHash; ...
    selectedHorizon;selectedColor]);

end
