function row=runExp23qBroadcastGraphRepairCell(base,condition,conditionIndex,R)
%RUNEXP23QBROADCASTGRAPHREPAIRCELL Use an independent DATA-delivery oracle.

row=runExp23oBroadcastCoherenceCell(base,condition,conditionIndex,R);
N=base.N;
ep=condition.positionError*ones(N,1);
ev=condition.velocityError*ones(N,1);
aa=R.accelerationBound*condition.accelerationScale*ones(N,1);
nominalV=base.v*condition.speedScale;
state=struct('p',base.p,'v',nominalV,'positionError',ep, ...
    'velocityError',ev,'accelerationBound',aa);
distance=pairDistance(base.p);
neighbor=distance<=R.dataNeighborRadius;
neighbor(1:N+1:end)=false;
pError=base.pDirection.*(base.pFraction.*ep);
vError=base.vDirection.*(base.vFraction.*ev);
actualAcceleration=base.aDirection.*(base.aFraction.* ...
    R.accelerationBound*condition.accelerationScale);

subsetViolations=0; colorViolations=0;
reachOnlyEdges=0; directDeliveryViolations=0;
for h=R.horizonsSec
    B=buildReachableBroadcastConflictSupergraph( ...
        state,h,R.interferenceRadius,neighbor,false(N));
    color=elcsWitnessPriorityColor(B.senderConflictGraph);
    for tau=linspace(0,h,R.timeSamplesPerHorizon)
        actual=base.p+pError+(nominalV+vError)*tau+ ...
            0.5*actualAcceleration*tau^2;
        actualDistance=pairDistance(actual);
        physical=actualDistance<=R.interferenceRadius;
        physical(1:N+1:end)=false;
        exact=enumerateSenderConflict(neighbor,physical,true);
        physicalOnly=enumerateSenderConflict(neighbor,physical,false);
        subsetViolations=subsetViolations+nnz(triu( ...
            exact & ~B.senderConflictGraph,1));
        sameColor=color==color';
        colorViolations=colorViolations+nnz(triu(exact & sameColor,1));
        reachOnlyEdges=reachOnlyEdges+nnz(triu(exact & ~physicalOnly,1));
        directDeliveryViolations=directDeliveryViolations+ ...
            countReceiverCollisions(color,neighbor,physical);
    end
end
row.actualSubsetViolations=subsetViolations;
row.sameColorConflictViolations=colorViolations;
row.reachOnlyActualConflictEdges=reachOnlyEdges;
row.directDeliveryCollisionViolations=directDeliveryViolations;

end


function conflict=enumerateSenderConflict(neighbor,physical,includeReach)

N=size(neighbor,1);
detectable=logical(physical);
if includeReach, detectable=detectable | logical(neighbor); end
conflict=false(N);
for a=1:N
    for b=a+1:N
        edge=neighbor(b,a) || neighbor(a,b);
        for receiver=1:N
            edge=edge || (neighbor(receiver,a) && detectable(receiver,b)) || ...
                (neighbor(receiver,b) && detectable(receiver,a));
        end
        conflict(a,b)=edge; conflict(b,a)=edge;
    end
end

end


function count=countReceiverCollisions(color,neighbor,physical)

N=numel(color); count=0;
for c=unique(color)'
    tx=find(color==c)'; txMask=false(N,1); txMask(tx)=true;
    for receiver=1:N
        if txMask(receiver), continue; end
        intended=tx(neighbor(receiver,tx));
        detectable=tx(physical(receiver,tx) | neighbor(receiver,tx));
        if isempty(intended), continue; end
        if numel(intended)>1 || any(~ismember(detectable,intended))
            count=count+1;
        end
    end
end

end


function D=pairDistance(p)

N=size(p,1); D=zeros(N);
for i=1:N
    for j=i+1:N
        D(i,j)=norm(p(i,:)-p(j,:)); D(j,i)=D(i,j);
    end
end

end
