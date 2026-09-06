function conflict=buildSenderConflictGraph(neighbor,interference)
%BUILDSENDERCONFLICTGRAPH Exact sender conflicts for DATA delivery model.
%
% neighbor(receiver,sender) marks an intended DATA link.  An intended link
% is necessarily detectable by the receiver even when a separately supplied
% physical-interference graph omits that pair.  This matches dataDelivery,
% whose detectable set is interference OR reach.

N=size(neighbor,1);
if ~isequal(size(neighbor),[N N]) || ...
        ~isequal(size(interference),[N N])
    error('buildSenderConflictGraph: matrices must be square and equal.');
end
neighbor=logical(neighbor);
interference=logical(interference);
detectable=interference | neighbor;
conflict=false(N);
for a=1:N
    receiversA=neighbor(:,a);
    for b=a+1:N
        receiversB=neighbor(:,b);
        edge=neighbor(b,a) || neighbor(a,b) || ...
            any(detectable(receiversA,b)) || ...
            any(detectable(receiversB,a));
        conflict(a,b)=edge;
        conflict(b,a)=edge;
    end
end

end
