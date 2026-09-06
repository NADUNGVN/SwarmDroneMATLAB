function G=buildReachableConflictSupergraph(state,horizonSec,interferenceRadius,mandatoryGraph)
%BUILDREACHABLECONFLICTSUPERGRAPH Conservative motion-tube conflict graph.
%
% state fields are p, v, positionError, velocityError and accelerationBound.
% Rows of p and v are nodes. Error/bound fields are scalar or N-by-1.

required={'p','v','positionError','velocityError','accelerationBound'};
if ~isstruct(state) || ~all(isfield(state,required))
    error('buildReachableConflictSupergraph: incomplete state.');
end
p=double(state.p); v=double(state.v);
if ~ismatrix(p) || isempty(p) || ~isequal(size(p),size(v)) || ...
        any(~isfinite(p),'all') || any(~isfinite(v),'all')
    error('buildReachableConflictSupergraph: invalid p/v arrays.');
end
N=size(p,1);
ep=expandBound(state.positionError,N,'positionError');
ev=expandBound(state.velocityError,N,'velocityError');
aa=expandBound(state.accelerationBound,N,'accelerationBound');
if ~isscalar(horizonSec) || ~isfinite(horizonSec) || horizonSec<0 || ...
        ~isscalar(interferenceRadius) || ~isfinite(interferenceRadius) || ...
        interferenceRadius<0
    error('buildReachableConflictSupergraph: invalid horizon/radius.');
end
if nargin<4 || isempty(mandatoryGraph), mandatoryGraph=false(N); end
if ~isequal(size(mandatoryGraph),[N N]) || any(diag(mandatoryGraph)) || ...
        ~isequal(logical(mandatoryGraph),logical(mandatoryGraph)')
    error('buildReachableConflictSupergraph: invalid mandatory graph.');
end
mandatoryGraph=logical(mandatoryGraph);

potential=mandatoryGraph;
closestTime=zeros(N);
nominalMinDistance=inf(N);
uncertaintyRadius=zeros(N);
clearance=inf(N);
for i=1:N
    nominalMinDistance(i,i)=0;
    clearance(i,i)=0;
    for j=i+1:N
        relativePosition=p(i,:)-p(j,:);
        relativeVelocity=v(i,:)-v(j,:);
        speed2=sum(relativeVelocity.^2);
        if speed2<=eps
            tau=0;
        else
            tau=-dot(relativePosition,relativeVelocity)/speed2;
            tau=min(horizonSec,max(0,tau));
        end
        distance=norm(relativePosition+relativeVelocity*tau);
        uncertainty=ep(i)+ep(j)+(ev(i)+ev(j))*horizonSec+ ...
            0.5*(aa(i)+aa(j))*horizonSec^2;
        margin=distance-interferenceRadius-uncertainty;
        edge=mandatoryGraph(i,j) || margin<=0;
        potential(i,j)=edge; potential(j,i)=edge;
        closestTime(i,j)=tau; closestTime(j,i)=tau;
        nominalMinDistance(i,j)=distance;
        nominalMinDistance(j,i)=distance;
        uncertaintyRadius(i,j)=uncertainty;
        uncertaintyRadius(j,i)=uncertainty;
        clearance(i,j)=margin; clearance(j,i)=margin;
    end
end

G=struct('version','REACHABLE-CONFLICT-SUPERGRAPH-v1', ...
    'N',N,'dimension',size(p,2),'horizonSec',horizonSec, ...
    'interferenceRadius',interferenceRadius, ...
    'potentialGraph',potential,'mandatoryGraph',mandatoryGraph, ...
    'closestApproachTimeSec',closestTime, ...
    'nominalMinimumDistance',nominalMinDistance, ...
    'uncertaintyRadius',uncertaintyRadius,'clearance',clearance, ...
    'edgeCount',nnz(triu(potential,1)), ...
    'hashExact',realizationHash([horizonSec;interferenceRadius;p(:);v(:); ...
    ep;ev;aa;double(mandatoryGraph(:));double(potential(:)); ...
    closestTime(:);nominalMinDistance(:);uncertaintyRadius(:)]));

end


function value=expandBound(value,N,name)
value=double(value(:));
if isscalar(value), value=repmat(value,N,1); end
if numel(value)~=N || any(~isfinite(value)) || any(value<0)
    error('buildReachableConflictSupergraph: invalid %s.',name);
end
end
