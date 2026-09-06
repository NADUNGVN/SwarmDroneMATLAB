function B=buildSweptBroadcastConflictSupergraph(startPosition, ...
    endPosition,trackingRadius,interferenceRadius,dataNeighborGraph)
%BUILDSWEPTBROADCASTCONFLICTSUPERGRAPH Lift command capsules to senders.
%
% Node i is certified to remain in a radius r_i capsule around the public
% segment q_i(alpha)=(1-alpha)p0_i+alpha*p1_i, alpha in [0,1].  A physical
% edge is included whenever two synchronized nominal segments can approach
% within the interference radius plus both capsule radii.  The result is
% then lifted through intended broadcast receivers.

p0=double(startPosition); p1=double(endPosition);
if ~ismatrix(p0)||isempty(p0)||~isequal(size(p0),size(p1))|| ...
        any(~isfinite(p0),'all')||any(~isfinite(p1),'all')
    error('buildSweptBroadcastConflictSupergraph: invalid positions.');
end
N=size(p0,1);
if ~isequal(size(dataNeighborGraph),[N N])
    error('buildSweptBroadcastConflictSupergraph: invalid neighbor graph.');
end
if isequal(size(trackingRadius),[N N])
    pairRadius=double(trackingRadius);
    if any(~isfinite(pairRadius),'all')||any(pairRadius<0,'all')|| ...
            any(diag(pairRadius))|| ...
            max(abs(pairRadius-pairRadius'),[],'all')>1e-12
        error(['buildSweptBroadcastConflictSupergraph: pairwise radius ' ...
            'must be finite, nonnegative, symmetric and zero diagonal.']);
    end
    radiusMode='pairwise-relative'; nodeRadius=nan(N,1);
else
    nodeRadius=double(trackingRadius(:));
    if isscalar(nodeRadius), nodeRadius=repmat(nodeRadius,N,1); end
    if numel(nodeRadius)~=N||any(~isfinite(nodeRadius))||any(nodeRadius<0)
        error('buildSweptBroadcastConflictSupergraph: invalid node radii.');
    end
    pairRadius=nodeRadius+nodeRadius'; pairRadius(1:N+1:end)=0;
    radiusMode='independent-node';
end
if ~isscalar(interferenceRadius)||~isfinite(interferenceRadius)|| ...
        interferenceRadius<0
    error('buildSweptBroadcastConflictSupergraph: invalid radii.');
end

physical=false(N); alphaStar=zeros(N); nominalMin=inf(N);
clearance=inf(N);
for i=1:N
    nominalMin(i,i)=0; clearance(i,i)=0;
    for j=i+1:N
        relative0=p0(i,:)-p0(j,:);
        relativeStep=(p1(i,:)-p1(j,:))-relative0;
        denominator=sum(relativeStep.^2);
        if denominator<=eps
            alpha=0;
        else
            alpha=-dot(relative0,relativeStep)/denominator;
            alpha=min(1,max(0,alpha));
        end
        distance=norm(relative0+alpha*relativeStep);
        margin=distance-interferenceRadius-pairRadius(i,j);
        physical(i,j)=margin<=0; physical(j,i)=physical(i,j);
        alphaStar(i,j)=alpha; alphaStar(j,i)=alpha;
        nominalMin(i,j)=distance; nominalMin(j,i)=distance;
        clearance(i,j)=margin; clearance(j,i)=margin;
    end
end
neighbor=logical(dataNeighborGraph); neighbor(1:N+1:end)=false;
sender=buildSenderConflictGraph(neighbor,physical);
B=struct('version','SWEPT-BROADCAST-CONFLICT-SUPERGRAPH-v1', ...
    'N',N,'dimension',size(p0,2),'startPosition',p0, ...
    'endPosition',p1,'trackingRadiusMode',radiusMode, ...
    'nodeTrackingRadius',nodeRadius, ...
    'pairwiseTrackingRadius',pairRadius, ...
    'interferenceRadius',interferenceRadius, ...
    'dataNeighborGraph',neighbor,'potentialInterferenceGraph',physical, ...
    'senderConflictGraph',sender,'closestProgress',alphaStar, ...
    'nominalMinimumDistance',nominalMin,'clearance',clearance, ...
    'physicalEdgeCount',nnz(triu(physical,1)), ...
    'senderEdgeCount',nnz(triu(sender,1)), ...
    'causalInputsOnly',true,'futureActualReads',0);
B.hashExact=realizationHash([p0(:);p1(:);pairRadius(:); ...
    interferenceRadius; ...
    double(neighbor(:));double(physical(:));double(sender(:)); ...
    alphaStar(:);nominalMin(:)]);

end
