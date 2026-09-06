function row=runExp23oBroadcastCoherenceCell(base,condition,conditionIndex,R)
%RUNEXP23OBROADCASTCOHERENCECELL Evaluate receiver-lifted motion safety.

N=base.N;
ep=condition.positionError*ones(N,1);
ev=condition.velocityError*ones(N,1);
aa=R.accelerationBound*condition.accelerationScale*ones(N,1);
nominalV=base.v*condition.speedScale;
state=struct('p',base.p,'v',nominalV,'positionError',ep, ...
    'velocityError',ev,'accelerationBound',aa);
initialDistance=pairDistance(base.p);
neighbor=initialDistance<=R.dataNeighborRadius;
neighbor(1:N+1:end)=false;
management=initialDistance<=condition.managementRadius;
management(1:N+1:end)=false;
C=struct('interferenceRadius',R.interferenceRadius, ...
    'managementReach',management,'maxDataSlots',N, ...
    'claimBytes',R.claimBytes, ...
    'certificateHeaderBytes',R.certificateHeaderBytes, ...
    'certificateEntryBytes',R.certificateEntryBytes, ...
    'maxControlPacketBytes',R.maxControlPacketBytes, ...
    'mandatoryConflictGraph',false(N), ...
    'dataNeighborGraph',neighbor);
selector=selectCoherenceLeaseHorizon(state,R.horizonsSec,C);

pError=base.pDirection.*(base.pFraction.*ep);
vError=base.vDirection.*(base.vFraction.*ev);
actualAcceleration=base.aDirection.*(base.aFraction.* ...
    R.accelerationBound*condition.accelerationScale);
subsetViolations=0; colorViolations=0; monotonicViolations=0;
hiddenEdges=0; previous=false(N);
for h=R.horizonsSec
    B=buildReachableBroadcastConflictSupergraph( ...
        state,h,R.interferenceRadius,neighbor,false(N));
    monotonicViolations=monotonicViolations+nnz(previous & ...
        ~B.senderConflictGraph);
    previous=B.senderConflictGraph;
    color=elcsWitnessPriorityColor(B.senderConflictGraph);
    hiddenEdges=hiddenEdges+nnz(triu(B.senderConflictGraph & ...
        ~(neighbor | neighbor'),1));
    for tau=linspace(0,h,R.timeSamplesPerHorizon)
        actual=base.p+pError+(nominalV+vError)*tau+ ...
            0.5*actualAcceleration*tau^2;
        actualDistance=pairDistance(actual);
        actualInterference=actualDistance<=R.interferenceRadius;
        actualInterference(1:N+1:end)=false;
        actualConflict=buildSenderConflictGraph( ...
            neighbor,actualInterference);
        subsetViolations=subsetViolations+nnz(triu( ...
            actualConflict & ~B.senderConflictGraph,1));
        sameColor=color==color';
        colorViolations=colorViolations+nnz(triu( ...
            actualConflict & sameColor,1));
    end
end

normalRevocations=0; violationMisses=0;
for node=1:N
    A=struct('p',base.p(node,:),'v',nominalV(node,:), ...
        'positionError',ep(node),'velocityError',ev(node), ...
        'accelerationBound',aa(node),'issuedAt',0, ...
        'expiryTime',R.horizonsSec(end),'tupleVersion',1);
    current=struct('p',base.p(node,:)+pError(node,:), ...
        'v',nominalV(node,:)+vError(node,:), ...
        'a',actualAcceleration(node,:),'time',0);
    D=coherenceSelfRevocationDecision(A,current,R.monitorStepSec);
    normalRevocations=normalRevocations+double(D.selfRevokeRequired);
    current.a=base.aDirection(node,:)*R.accelerationBound* ...
        R.violationAccelerationFactor;
    D=coherenceSelfRevocationDecision(A,current,R.monitorStepSec);
    violationMisses=violationMisses+double(~D.selfRevokeRequired);
end

selectedEdges=0; selectedPhysical=0; selectedColors=0;
selectedCovered=0; selectedFit=0;
if selector.selectedIndex>0
    selectedEdges=selector.selectedGraph.edgeCount;
    selectedPhysical=selector.selectedGraph.physicalEdgeCount;
    selectedColors=max(selector.selectedColor);
    selectedCovered=double(selector.selectedWitnessMap.allCovered);
    selectedFit=double(selector.payloadFitsSingleResponse( ...
        selector.selectedIndex));
end
row=exp23oBroadcastCoherenceEmptyRow();
row.seed=base.seed; row.N=N; row.condition=condition.id;
row.conditionIndex=conditionIndex;
row.positionError=condition.positionError;
row.velocityError=condition.velocityError;
row.speedScale=condition.speedScale;
row.accelerationScale=condition.accelerationScale;
row.managementRadius=condition.managementRadius;
row.BASE_REALIZATION_HASH=base.hashExact;
row.STATE_HASH_EXACT=realizationHash([base.hashExact;nominalV(:);ep;ev;aa]);
row.MANAGEMENT_GRAPH_HASH=realizationHash(double(management(:)));
row.DATA_NEIGHBOR_GRAPH_HASH=realizationHash(double(neighbor(:)));
row.dataNeighborEdges=nnz(triu(neighbor,1));
row.SELECTOR_HASH_EXACT=selector.hashExact;
row.selectedHorizonSec=selector.selectedHorizonSec;
row.selectedIndex=selector.selectedIndex;
row.selectedEdgeCount=selectedEdges;
row.selectedPhysicalEdges=selectedPhysical;
row.selectedColorCount=selectedColors;
row.selectedWitnessCovered=selectedCovered;
row.selectedPayloadFits=selectedFit;
row.hiddenSenderConflictEdges=hiddenEdges;
row.targetHorizonSelected=double( ...
    selector.selectedHorizonSec==R.horizonsSec(end));
row.noLeaseIssued=double(selector.selectedIndex==0);
row.infeasibleHorizonCount=nnz(~selector.feasible);
row.actualSubsetViolations=subsetViolations;
row.sameColorConflictViolations=colorViolations;
row.horizonMonotonicViolations=monotonicViolations;
row.normalSelfRevocations=normalRevocations;
row.injectedViolationMisses=violationMisses;
row.futureRandomReads=selector.futureRandomReads;
row.receiverTruthDecisionReads=selector.receiverTruthDecisionReads;

end


function D=pairDistance(p)
N=size(p,1); D=zeros(N);
for i=1:N
    for j=i+1:N
        D(i,j)=norm(p(i,:)-p(j,:)); D(j,i)=D(i,j);
    end
end
end
