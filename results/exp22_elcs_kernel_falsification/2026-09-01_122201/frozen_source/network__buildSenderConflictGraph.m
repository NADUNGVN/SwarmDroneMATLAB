function conflict=buildSenderConflictGraph(neighbor,interference)
%BUILDSENDERCONFLICTGRAPH Conservative transmitter-conflict graph.

N=size(neighbor,1);
if ~isequal(size(neighbor),[N N]) || ...
        ~isequal(size(interference),[N N])
    error('buildSenderConflictGraph: matrices must be square and equal.');
end
neighbor=logical(neighbor);
interference=logical(interference);
conflict=false(N);
for a=1:N
    receiversA=neighbor(:,a);
    for b=a+1:N
        receiversB=neighbor(:,b);
        edge=neighbor(b,a) || neighbor(a,b) || ...
            any(interference(receiversA,b)) || ...
            any(interference(receiversB,a));
        conflict(a,b)=edge;
        conflict(b,a)=edge;
    end
end

end
