function W=buildConflictWitnessMap(conflict,managementReach)
%BUILDCONFLICTWITNESSMAP Deterministic one-hop witnesses for conflict edges.
%
% Matrix orientation follows the shared-medium convention:
% managementReach(receiver,sender) is true when receiver can decode sender.
% An endpoint is allowed to witness its own incident direct edge.  A third
% node is eligible only when CLAIM and CERT traffic can traverse both
% directions between the witness and each endpoint.

N=size(conflict,1);
if ~isequal(size(conflict),[N N]) || ...
        ~isequal(size(managementReach),[N N])
    error('buildConflictWitnessMap: matrices must be square and equal.');
end
conflict=logical(conflict);
reach=logical(managementReach);
if any(diag(conflict)) || ~isequal(conflict,conflict')
    error('buildConflictWitnessMap: conflict graph must be symmetric simple.');
end
reach(1:N+1:end)=true;
exchange=reach & reach';
witness=zeros(N);
eligibleCount=zeros(N);
load=zeros(N,1);
for a=1:N
    for b=a+1:N
        if ~conflict(a,b), continue; end
        eligible=find(exchange(:,a) & exchange(:,b));
        eligibleCount(a,b)=numel(eligible);
        eligibleCount(b,a)=numel(eligible);
        if isempty(eligible), continue; end
        ranking=[load(eligible) eligible];
        [~,order]=sortrows(ranking,[1 2]);
        w=eligible(order(1));
        witness(a,b)=w;
        witness(b,a)=w;
        load(w)=load(w)+1;
    end
end
edgeMask=triu(conflict,1);
uncovered=triu(conflict & witness==0,1);
responseLoad=load;
W=struct('version','CONFLICT-WITNESS-MAP-v1','N',N, ...
    'assignmentRule','lexicographic-edge-greedy-min-load-then-id', ...
    'witness',witness,'eligibleCount',eligibleCount, ...
    'edgeCount',nnz(edgeMask),'coveredEdgeCount', ...
    nnz(edgeMask)-nnz(uncovered),'uncoveredEdgeMask',uncovered, ...
    'uncoveredEdgeCount',nnz(uncovered),'witnessEdgeLoad',load, ...
    'responseEntryLoad',responseLoad, ...
    'allCovered',nnz(uncovered)==0, ...
    'hashExact',realizationHash([double(conflict(:)); ...
    double(managementReach(:));witness(:);eligibleCount(:)]));

end
