function row=runExp23pCoherencePacketCell( ...
    base,geometryCondition,geometryIndex,networkCondition,networkIndex,R)
%RUNEXP23PCOHERENCEPACKETCELL Bind geometry and execute one packet kernel.

N=base.N;
ep=geometryCondition.positionError*ones(N,1);
ev=geometryCondition.velocityError*ones(N,1);
aa=R.accelerationBound*geometryCondition.accelerationScale*ones(N,1);
nominalV=base.v*geometryCondition.speedScale;
state=struct('p',base.p,'v',nominalV,'positionError',ep, ...
    'velocityError',ev,'accelerationBound',aa);
distance=pairDistance(base.p);
neighbor=distance<=R.dataNeighborRadius;
neighbor(1:N+1:end)=false;
management=distance<=geometryCondition.managementRadius;
management(1:N+1:end)=false;

C=elcsWitnessKernelConfig(N,R.maxFrames);
C.guardSec=R.missionSafeGuardSec;
C.neighborGraph=neighbor;
C.managementReach=management;
C.interferenceMatrix=distance<=R.interferenceRadius;
C.interferenceMatrix(1:N+1:end)=false;
C.conflictGraph=buildSenderConflictGraph( ...
    C.neighborGraph,C.interferenceMatrix);
selectorConfig=struct('interferenceRadius',R.interferenceRadius, ...
    'managementReach',management,'maxDataSlots',N, ...
    'claimBytes',28,'certificateHeaderBytes',16, ...
    'certificateEntryBytes',10,'maxControlPacketBytes',96, ...
    'mandatoryConflictGraph',false(N), ...
    'dataNeighborGraph',neighbor);
selector=selectCoherenceLeaseHorizon(state,R.horizonsSec,selectorConfig);
[C,binding]=applyCoherenceLeaseConfig(C,selector);
C.claimErasureProbability=networkCondition.claimLoss;
C.certificateErasureProbability=networkCondition.responseLoss;

T=generateElcsWitnessTrace(base.seed,C);
baseTraceHash=T.hashExact;
background=sharedBackground(base.seed,N,R);
backgroundOverlayHash=NaN; backgroundHits=0;
if networkCondition.backgroundLoad>0
    spec=struct('clockOffsetSec',background.clockOffsetSec, ...
        'clockDriftPpm',background.clockDriftPpm, ...
        'leadTimeSec',R.clockLeadTimeSec);
    [T,B]=applySharedBackgroundToElcsWitnessTrace( ...
        T,C,background.trace,spec,networkCondition.backgroundLoad);
    backgroundOverlayHash=B.hashExact;
    backgroundHits=B.totalPotentialAttemptHits;
end

blackoutApplied=0;
if strcmp(networkCondition.id,R.blackoutCondition) && ...
        C.coherenceLeaseAdmissible
    W=buildConflictWitnessMap(C.conflictGraph,C.managementReach);
    [a,b]=find(triu(C.conflictGraph,1));
    target=find(arrayfun(@(q) W.witness(a(q),b(q))~=b(q), ...
        1:numel(a)),1);
    if ~isempty(target)
        client=b(target); witness=W.witness(a(target),client);
        T.certificateDeliveryU(:)=1;
        T.certificateDeliveryU(:,client,witness)=0;
        T.hashExact=elcsWitnessTraceHash(T);
        blackoutApplied=1;
    end
end
O=simulateElcsWitnessScheduling(C,T);

row=exp23pCoherencePacketEmptyRow();
row.seed=base.seed; row.N=N;
row.scenario=geometryCondition.id;
row.scenarioLabel=geometryCondition.id;
row.geometryCondition=geometryCondition.id;
row.geometryIndex=geometryIndex;
row.condition=networkCondition.id;
row.conditionLabel=networkCondition.id;
row.conditionKind=networkCondition.id;
row.networkCondition=networkCondition.id;
row.networkIndex=networkIndex;
row.retryMode='coherence-cumulative';
row.BASE_TRACE_HASH_EXACT=baseTraceHash;
row.CONDITION_TRACE_HASH_EXACT=T.hashExact;
row.CONFIG_HASH=O.configHash;
row.SCHEDULE_STATE_HASH=O.scheduleStateHash;
row.WITNESS_HASH_EXACT=O.witnessMap.hashExact;
row.CONFLICT_EDGES=O.witnessMap.edgeCount;
row.HIDDEN_CONFLICT_EDGES=nnz(triu(C.conflictGraph & ...
    ~(C.managementReach | C.managementReach'),1));
row.MAX_WITNESS_LOAD=max(O.witnessMap.witnessEdgeLoad);
row.FINAL_ALL_CERTIFIED=double(O.finalAllCertified);
row.FIRST_ALL_CERTIFIED_FRAME=O.firstAllCertifiedFrame;
row.CERTIFIED_NODE_FRAME_FRACTION=mean(O.debug.active,'all');
row.FALSE_VALID_EDGE_FRAMES=O.falseValidEdgeFrames;
row.SCHEDULED_COLLISION_FRAMES=O.scheduledCollisionFrames;
row.FALLBACK_COLLISION_FRAMES=O.fallbackCollisionFrames;
row.CLAIM_ATTEMPTS=O.claimAttempts;
row.CERTIFICATE_ATTEMPTS=O.certificateAttempts;
row.CONTROL_ATTEMPTS=O.controlAttempts;
row.CONTROL_ATTEMPT_BOUND=O.controlAttemptBound;
row.CONTROL_ATTEMPT_BOUND_RATIO=O.controlAttemptBoundRatio;
row.NOMINAL_CONTROL_ATTEMPT_BOUND=O.nominalControlAttemptBound;
row.CLAIM_BYTES=O.claimBytes;
row.CERTIFICATE_BYTES=O.certificateBytes;
row.CONTROL_BYTES=O.controlBytes;
row.CONTROL_BYTE_BOUND=O.controlByteBound;
row.CONTROL_BYTE_BOUND_RATIO=O.controlByteBoundRatio;
row.NOMINAL_CONTROL_BYTE_BOUND=O.nominalControlByteBound;
row.CERTIFICATE_ENTRIES_ATTEMPTED=O.certificateEntriesAttempted;
row.RESPONSE_ENTRIES_ATTEMPTED=O.responseEntriesAttempted;
row.RETRY_CLAIM_ATTEMPTS=O.retryClaimAttempts;
row.LOCAL_CERTIFICATE_ENTRIES=O.localCertificateEntries;
row.CERTIFICATE_WITHOUT_FRESH_CLAIMS=O.certificateWithoutFreshClaims;
row.MANAGEMENT_RECIPIENT_ATTEMPTS=O.managementRecipientAttempts;
row.MANAGEMENT_RECIPIENT_SUCCESS=O.managementRecipientSuccess;
row.MANAGEMENT_RECIPIENT_ERASURE=O.managementRecipientErasure;
row.MANAGEMENT_RECIPIENT_COLLISION=O.managementRecipientCollision;
row.SCHEDULED_ATTEMPTS=O.scheduledAttempts;
row.FALLBACK_ATTEMPTS=O.fallbackAttempts;
row.SCHEDULED_RECIPIENT_ATTEMPTS=O.scheduledRecipientAttempts;
row.SCHEDULED_RECIPIENT_SUCCESS=O.scheduledRecipientSuccess;
row.SCHEDULED_RECIPIENT_ERASURE=O.scheduledRecipientErasure;
row.SCHEDULED_RECIPIENT_COLLISION=O.scheduledRecipientCollision;
row.FALLBACK_RECIPIENT_ATTEMPTS=O.fallbackRecipientAttempts;
row.FALLBACK_RECIPIENT_SUCCESS=O.fallbackRecipientSuccess;
row.FALLBACK_RECIPIENT_ERASURE=O.fallbackRecipientErasure;
row.FALLBACK_RECIPIENT_COLLISION=O.fallbackRecipientCollision;
row.MAX_FALLBACK_ATTEMPTS_PER_NODE_FRAME=max( ...
    sum(O.debug.fallbackTx,2),[],'all');
row.ACCOUNTING_CLOSES=double( ...
    O.managementRecipientSuccess+O.managementRecipientErasure+ ...
    O.managementRecipientCollision==O.managementRecipientAttempts && ...
    O.scheduledRecipientSuccess+O.scheduledRecipientErasure+ ...
    O.scheduledRecipientCollision==O.scheduledRecipientAttempts && ...
    O.fallbackRecipientSuccess+O.fallbackRecipientErasure+ ...
    O.fallbackRecipientCollision==O.fallbackRecipientAttempts);
row.FUTURE_RANDOM_READS=O.futureRandomReads;
row.RECEIVER_TRUTH_READS=O.receiverTruthDecisionReads;
row.CUMULATIVE_RECEIPT_RETRY=O.cumulativeReceiptRetry;
row.CLAIM_TRANSACTION_STARTS=O.claimTransactionStarts;
row.FINAL_OPEN_CLAIM_TRANSACTIONS=O.finalOpenClaimTransactions;
row.BACKGROUND_LOAD=networkCondition.backgroundLoad;
row.BACKGROUND_TRACE_HASH_EXACT=background.trace.hashExact;
row.BACKGROUND_OVERLAY_HASH_EXACT=backgroundOverlayHash;
row.BACKGROUND_POTENTIAL_HITS=backgroundHits;
row.BASE_GEOMETRY_HASH=base.hashExact;
row.DATA_NEIGHBOR_GRAPH_HASH=realizationHash(double(neighbor(:)));
row.MANAGEMENT_GRAPH_HASH=realizationHash(double(management(:)));
row.SELECTOR_HASH_EXACT=selector.hashExact;
row.SELECTED_HORIZON_SEC=selector.selectedHorizonSec;
row.SELECTED_HORIZON_INDEX=selector.selectedIndex;
selectedConflict=false(N);
if selector.selectedIndex>0
    selectedConflict=selector.selectedGraph.senderConflictGraph;
end
row.SELECTED_CONFLICT_EDGES=nnz(triu(selectedConflict,1));
row.SELECTED_HIDDEN_EDGES=nnz(triu(selectedConflict & ...
    ~(management | management'),1));
row.COHERENCE_ENABLED=O.coherenceLeaseEnabled;
row.COHERENCE_ADMISSIBLE=O.coherenceLeaseAdmissible;
row.COHERENCE_HORIZON_FRAMES=O.coherenceHorizonFrames;
row.RENEWAL_PERIOD_FRAMES=C.renewalPeriodFrames;
row.LEASE_FRAMES=C.leaseFrames;
row.CLAIM_PACKET_BYTES=C.claimBytes;
row.CERTIFICATE_HEADER_BYTES=C.certificateHeaderBytes;
row.CERTIFICATE_ENTRY_BYTES=C.certificateEntryBytes;
row.REVOKE_PACKET_BYTES=C.coherenceRevokeBytes;
row.MAX_RESPONSE_PACKET_BYTES=max(O.debug.certificateBytes,[],'all');
row.PACKET_MTU_VIOLATIONS=nnz(O.debug.certificateBytes> ...
    C.maxControlPacketBytes)+double(C.claimBytes>C.maxControlPacketBytes);
row.BLACKOUT_APPLIED=blackoutApplied;
row.SELF_REVOCATIONS=O.selfRevocationCount;
row.REVOKE_ATTEMPTS=O.revokeAttempts;
row.REVOKE_BYTES=O.revokeBytes;
row.bindingReason=binding.reason;

end


function B=sharedBackground(seedValue,N,R)
stream=RandStream('mrg32k3a','Seed',mod(seedValue+31001*N,2^32));
K=ceil(R.backgroundHorizonSec/R.backgroundSlotSec);
stream.Substream=1; u=rand(stream,K,1);
stream.Substream=2; offsetU=rand(stream,N,1);
stream.Substream=3; driftU=rand(stream,N,1);
hash=realizationHash([seedValue;N;R.backgroundSlotSec;u]);
B=struct('trace',struct('backgroundU',u, ...
    'slotTime',R.backgroundSlotSec,'hashExact',hash), ...
    'clockOffsetSec',(2*offsetU-1)*R.maxOffsetSec, ...
    'clockDriftPpm',(2*driftU-1)*R.maxDriftPpm);
end


function D=pairDistance(p)
N=size(p,1); D=zeros(N);
for i=1:N
    for j=i+1:N
        D(i,j)=norm(p(i,:)-p(j,:)); D(j,i)=D(i,j);
    end
end
end
