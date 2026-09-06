function row=runExp23hCumulativeReceiptCell( ...
    seedValue,cellInfo,condition,mode,R)
%RUNEXP23HCUMULATIVERECEIPTCELL Execute one paired kernel comparison.

base=applyExp21dClosedLoopCell(cellInfo.exp21dCell,seedValue);
base.mac.backgroundLoad=condition.backgroundLoad;
base.mac=sharedMediumConfig(base);
sharedTrace=generateSharedMediumTrace(base);
N=base.swarm.N;
C=elcsWitnessKernelConfig(N,R.maxFrames);
C.guardSec=R.missionSafeGuardSec;
C.neighborGraph=logical(base.swarm.A);
C.managementReach=C.neighborGraph;
C.interferenceMatrix=logical(base.mac.interferenceMatrix);
C.conflictGraph=buildSenderConflictGraph( ...
    C.neighborGraph,C.interferenceMatrix);
C.claimBytes=R.claimBytes;
C.certificateHeaderBytes=R.certificateHeaderBytes;
C.certificateEntryBytes=R.certificateEntryBytes;
C.maxControlPacketBytes=R.maxControlPacketBytes;
C.claimErasureProbability=condition.claimLoss;
C.certificateErasureProbability=condition.responseLoss;
C.cumulativeReceiptRetry=mode.cumulativeReceiptRetry;
T=generateElcsWitnessTrace(seedValue,C);
baseTraceHash=T.hashExact;
backgroundHash=NaN; backgroundHits=0;
if condition.backgroundLoad>0
    offset=(2*reshape(sharedTrace.exp21cClockOffsetU(1,:),[],1)-1)* ...
        R.maxOffsetSec;
    drift=(2*reshape(sharedTrace.exp21cClockDriftU,[],1)-1)* ...
        R.maxDriftPpm;
    spec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
        'leadTimeSec',R.clockLeadTimeSec);
    [T,B]=applySharedBackgroundToElcsWitnessTrace( ...
        T,C,sharedTrace,spec,condition.backgroundLoad);
    backgroundHash=B.hashExact;
    backgroundHits=B.totalPotentialAttemptHits;
elseif strcmp(condition.id,R.blackoutCondition)
    W=buildConflictWitnessMap(C.conflictGraph,C.managementReach);
    [aa,bb]=find(triu(C.conflictGraph,1));
    target=find(arrayfun(@(q) W.witness(aa(q),bb(q))~=bb(q), ...
        1:numel(aa)),1);
    if isempty(target), error('runExp23h: no transmitted response edge.'); end
    client=bb(target); witness=W.witness(aa(target),client);
    T.certificateDeliveryU(:)=1;
    T.certificateDeliveryU(:,client,witness)=0;
    T.hashExact=elcsWitnessTraceHash(T);
end
O=simulateElcsWitnessScheduling(C,T);

row=exp23hCumulativeReceiptEmptyRow();
row.seed=seedValue; row.scenario=cellInfo.id;
row.scenarioLabel=cellInfo.label; row.condition=condition.id;
row.conditionLabel=condition.label; row.conditionKind=condition.kind;
row.retryMode=mode.id; row.N=N;
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
row.BACKGROUND_LOAD=condition.backgroundLoad;
row.BACKGROUND_TRACE_HASH_EXACT=sharedTrace.hashExact;
row.BACKGROUND_OVERLAY_HASH_EXACT=backgroundHash;
row.BACKGROUND_POTENTIAL_HITS=backgroundHits;

end
