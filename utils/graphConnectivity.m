function info = graphConnectivity(A, pin)
%GRAPHCONNECTIVITY Structural properties of the communication graph.
%
%   info = graphConnectivity(A, pin)
%
% A is the directed adjacency used by the simulators: A(i,j) means receiver
% i is fed by transmitter j. pin marks followers that additionally receive
% the leader directly.
%
% Per docs/PREREGISTRATION.md section 2.4 the graph is symmetrised before
% any structural claim: edge (i,j) exists if A(i,j) or A(j,i), plus edge
% (1,i) for every pinned follower i. Connectivity is then decided by the
% second-smallest Laplacian eigenvalue.
%
%   connected  <=>  lambda2 > 1e-9
%
% A condition whose graph is disconnected belongs to the connectivity
% impossibility region and is excluded from pass-rate arithmetic. A policy
% is not judged to have failed because the network fell apart.
%
% Returns numEdges, meanDegree, minDegree, lambda2 and connected.

N = size(A,1);


%% ============================================================
% Symmetrise, and fold in the leader pinning
% ============================================================

Adj = (A ~= 0) | (A ~= 0)';

for i = 1:N
    if i >= 2 && pin(i)
        Adj(1,i) = true;
        Adj(i,1) = true;
    end
end

Adj = Adj & ~eye(N);

Adj = double(Adj);


%% ============================================================
% Degree statistics
% ============================================================

deg = sum(Adj, 2);

info.numEdges   = nnz(Adj) / 2;
info.meanDegree = mean(deg);
info.minDegree  = min(deg);
info.maxDegree  = max(deg);


%% ============================================================
% Algebraic connectivity
% ============================================================

L = diag(deg) - Adj;

ev = sort(eig(L));

if N >= 2
    info.lambda2 = ev(2);
else
    info.lambda2 = 0;
end

info.connected = info.lambda2 > 1e-9;

info.adjacency = Adj;

end
