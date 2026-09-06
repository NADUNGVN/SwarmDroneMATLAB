function B=elcsControlAttemptBound(C)
%ELCSCONTROLATTEMPTBOUND Zero-loss event-driven control-attempt envelope.

required={'N','maxFrames','statusPeriodFrames','leaseFrames', ...
    'refreshLeadFrames','leaseFenceFrames','conflictGraph'};
if ~isstruct(C) || ~all(isfield(C,required))
    error('elcsControlAttemptBound: incomplete ELCS configuration.');
end
J=C.leaseFrames-C.refreshLeadFrames-C.leaseFenceFrames;
if J<=0
    error('elcsControlAttemptBound: renewal interval must be positive.');
end
lowerDegree=zeros(C.N,1);
for node=1:C.N
    lowerDegree(node)=nnz(C.conflictGraph(node,1:node-1));
end
cycles=ceil(C.maxFrames/J);
discovery=C.N*ceil(C.maxFrames/C.statusPeriodFrames);
requesting=lowerDegree>0;
requests=cycles*nnz(requesting);
grants=cycles*sum(lowerDegree);
B=struct('total',discovery+requests+grants, ...
    'discovery',discovery,'requests',requests,'grants',grants, ...
    'renewalIntervalFrames',J,'renewalCycles',cycles, ...
    'lowerDegree',lowerDegree);

end
