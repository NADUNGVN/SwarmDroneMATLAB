function row=runExp23sDynamicRevocationCell(seedValue,N,condition,index,R)
%RUNEXP23SDYNAMICREVOCATIONCELL Execute one scripted dynamic lifecycle.

[C,T,eventFrame,eligibleFrame,withinFrames,outsideFrames]= ...
    dynamicFixture(seedValue,N,R);
C.claimErasureProbability=condition.claimLoss;
C.certificateErasureProbability=condition.responseLoss;
baseTraceHash=T.baseTraceHash;
dynamicBaseHash=T.hashExact;
if condition.revokeLoss>=1
    T.revokeDeliveryU(eventFrame,:,R.revokeNode)=0;
elseif condition.revokeLoss>0
    lost=T.revokeDeliveryU<=condition.revokeLoss;
    T.revokeDeliveryU(lost)=0;
end
if condition.blockReacquireResponse
    W=buildConflictWitnessMap(C.conflictGraph,C.managementReach);
    [a,b]=find(triu(C.conflictGraph,1));
    for e=1:numel(a)
        if a(e)==R.revokeNode || b(e)==R.revokeNode
            witness=W.witness(a(e),b(e));
            if witness~=R.revokeNode
                T.certificateDeliveryU(eligibleFrame:end, ...
                    R.revokeNode,witness)=0;
            end
        end
    end
end
T=rmfield(T,'baseTraceHash');
T.hashExact=elcsWitnessTraceHash(T);
O=simulateElcsWitnessScheduling(C,T);

firstReacquired=find(O.debug.reacquired(:,R.revokeNode),1);
if isempty(firstReacquired), firstReacquired=NaN; end
row=exp23sDynamicRevocationEmptyRow();
row.seed=seedValue; row.N=N; row.condition=condition.id;
row.conditionIndex=index;
row.BASE_TRACE_HASH_EXACT=baseTraceHash;
row.DYNAMIC_BASE_HASH_EXACT=dynamicBaseHash;
row.CONDITION_TRACE_HASH_EXACT=T.hashExact;
row.CONFIG_HASH=O.configHash;
row.SCHEDULE_STATE_HASH=O.scheduleStateHash;
row.WITNESS_HASH_EXACT=O.witnessMap.hashExact;
row.CONFLICT_EDGES=O.witnessMap.edgeCount;
row.MAX_WITNESS_LOAD=max(O.witnessMap.witnessEdgeLoad);
row.REVOKE_FRAME=eventFrame;
row.REACQUIRE_ELIGIBLE_FRAME=eligibleFrame;
row.CAPTURED_FENCE_FRAME=O.revokeFenceUntilFrame(R.revokeNode);
row.FIRST_REACQUIRED_FRAME=firstReacquired;
row.PRE_EVENT_ACTIVE=double(O.debug.active(eventFrame-1,R.revokeNode));
row.EVENT_FRAME_SUPPRESSED=double( ...
    O.debug.suppressed(eventFrame,R.revokeNode) && ...
    ~O.debug.active(eventFrame,R.revokeNode));
row.UNSAFE_WINDOW_SUPPRESSED=double(all( ...
    O.debug.suppressed(outsideFrames,R.revokeNode)) && all( ...
    ~O.debug.active(outsideFrames,R.revokeNode)));
row.SUPPRESSION_HASH_EXACT=realizationHash(double( ...
    O.debug.suppressed(:,R.revokeNode)));
row.REACQUIRED_HASH_EXACT=realizationHash(double( ...
    O.debug.reacquired(:,R.revokeNode)));
row.OUTSIDE_SENDER_EDGE_CERTIFIED=double( ...
    C.conflictGraph(1,R.revokeNode));
row.OUTSIDE_PAIR_SAME_COLOR=double(O.slot(1)==O.slot(R.revokeNode));
row.SELF_REVOCATIONS=O.selfRevocationCount;
row.REACQUISITIONS=O.reacquisitionCount;
row.FINAL_SUPPRESSED=double(O.finalSuppressed(R.revokeNode));
row.FINAL_REVOKE_VERSION=O.finalVersion(R.revokeNode);
row.SCHEDULED_COLLISION_FRAMES=O.scheduledCollisionFrames;
row.FALSE_VALID_EDGE_FRAMES=O.falseValidEdgeFrames;
row.FALLBACK_COLLISION_FRAMES=O.fallbackCollisionFrames;
row.WITHIN_SUPERGRAPH_EDGE_FRAMES=numel(withinFrames);
row.OUTSIDE_SUPERGRAPH_EDGE_FRAMES=numel(outsideFrames);
row.EDGE_REMOVAL_STIMULATED=double(eligibleFrame<=C.maxFrames);
row.CLAIM_ATTEMPTS=O.claimAttempts;
row.CERTIFICATE_ATTEMPTS=O.certificateAttempts;
row.REVOKE_ATTEMPTS=O.revokeAttempts;
row.CONTROL_ATTEMPTS=O.controlAttempts;
row.CLAIM_BYTES=O.claimBytes;
row.CERTIFICATE_BYTES=O.certificateBytes;
row.REVOKE_BYTES=O.revokeBytes;
row.CONTROL_BYTES=O.controlBytes;
row.REVOKE_RECIPIENT_ATTEMPTS=O.revokeRecipientAttempts;
row.REVOKE_RECIPIENT_SUCCESS=O.revokeRecipientSuccess;
row.REVOKE_RECIPIENT_ERASURE=O.revokeRecipientErasure;
row.REVOKE_RECIPIENT_COLLISION=O.revokeRecipientCollision;
row.REVOKE_WITNESS_CLEARS=O.revokeWitnessClears;
row.REVOKE_ACCEPTED_CLEARS=O.revokeAcceptedClears;
row.RETRY_CLAIM_ATTEMPTS=O.retryClaimAttempts;
row.CONTROL_ATTEMPT_BOUND_RATIO=O.controlAttemptBoundRatio;
row.CONTROL_BYTE_BOUND_RATIO=O.controlByteBoundRatio;
row.MANAGEMENT_RECIPIENT_ATTEMPTS=O.managementRecipientAttempts;
row.MANAGEMENT_RECIPIENT_SUCCESS=O.managementRecipientSuccess;
row.MANAGEMENT_RECIPIENT_ERASURE=O.managementRecipientErasure;
row.MANAGEMENT_RECIPIENT_COLLISION=O.managementRecipientCollision;
row.FUTURE_RANDOM_READS=O.futureRandomReads;
row.RECEIVER_TRUTH_READS=O.receiverTruthDecisionReads;
row.CLAIM_PACKET_BYTES=C.claimBytes;
row.CERTIFICATE_HEADER_BYTES=C.certificateHeaderBytes;
row.CERTIFICATE_ENTRY_BYTES=C.certificateEntryBytes;
row.REVOKE_PACKET_BYTES=C.coherenceRevokeBytes;
row.MAX_RESPONSE_PACKET_BYTES=max(O.debug.certificateBytes,[],'all');
row.PACKET_MTU_VIOLATIONS=nnz( ...
    O.debug.certificateBytes>C.maxControlPacketBytes)+ ...
    double(C.claimBytes>C.maxControlPacketBytes)+ ...
    double(C.coherenceRevokeBytes>C.maxControlPacketBytes);

end


function [C,T,eventFrame,eligibleFrame,withinFrames,outsideFrames]= ...
    dynamicFixture(seedValue,N,R)

C=elcsWitnessKernelConfig(N,R.maxFrames);
neighbor=false(N); neighbor(2,1)=true; neighbor(4,3)=true;
potential=false(N); potential(1,2)=true; potential(2,1)=true;
potential(3,4)=true; potential(4,3)=true;
potential(2,4)=true; potential(4,2)=true;
management=false(N); management(1,2)=true; management(2,1)=true;
for node=[1 2 3 4]
    management(5,node)=true; management(node,5)=true;
end
C.neighborGraph=neighbor;
C.managementReach=management;
C.interferenceMatrix=potential;
C.conflictGraph=buildSenderConflictGraph(neighbor,potential);
C.cumulativeReceiptRetry=true;
C.coherenceLeaseEnabled=true;
C.coherenceLeaseAdmissible=true;
C.coherenceHorizonFrames=C.leaseFrames;
C.dynamicRevocationEnabled=true;
C.claimBytes=R.claimBytes;
C.certificateHeaderBytes=R.certificateHeaderBytes;
C.certificateEntryBytes=R.certificateEntryBytes;
C.coherenceRevokeBytes=R.revokeBytes;
C.maxControlPacketBytes=R.maxControlPacketBytes;

T=generateElcsWitnessTrace(seedValue,C);
T.baseTraceHash=T.hashExact;
stream=RandStream('mrg32k3a','Seed', ...
    mod(seedValue+41173+1000*N,2^32));
stream.Substream=8; T.revokeDeliveryU=rand(stream,R.maxFrames,N,N);
eventFrame=R.revokeFrameBase+mod(seedValue,3);
eligibleFrame=eventFrame+R.reacquireDelayFrames;
T.selfRevoke=false(R.maxFrames,N);
T.selfRevoke(eventFrame,R.revokeNode)=true;
T.reacquireEligible=false(R.maxFrames,N);
T.reacquireEligible(eligibleFrame,R.revokeNode)=true;
actual=false(R.maxFrames,N,N);
baseline=false(N); baseline(1,2)=true; baseline(2,1)=true;
baseline(3,4)=true; baseline(4,3)=true;
for frame=1:R.maxFrames, actual(frame,:,:)=baseline; end
withinFrames=5:(eventFrame-2);
actual(withinFrames,2,4)=true; actual(withinFrames,4,2)=true;
outsideFrames=(eventFrame+1):(eligibleFrame-1);
actual(outsideFrames,2,3)=true; actual(outsideFrames,3,2)=true;
T.actualInterference=actual;
hashTrace=rmfield(T,'baseTraceHash');
T.hashExact=elcsWitnessTraceHash(hashTrace);

end
