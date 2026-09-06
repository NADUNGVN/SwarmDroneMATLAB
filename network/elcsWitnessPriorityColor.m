function color=elcsWitnessPriorityColor(conflict)
%ELCSWITNESSPRIORITYCOLOR Deterministic node-order greedy coloring.

N=size(conflict,1);
if ~isequal(size(conflict),[N N]) || any(diag(conflict)) || ...
        ~isequal(logical(conflict),logical(conflict)')
    error('elcsWitnessPriorityColor: conflict graph must be symmetric simple.');
end
conflict=logical(conflict);
color=zeros(N,1);
for node=1:N
    lowerMask=conflict(node,:) & (1:N)<node;
    unavailable=unique(color(lowerMask));
    candidate=1;
    while any(unavailable==candidate), candidate=candidate+1; end
    color(node)=candidate;
end

end
