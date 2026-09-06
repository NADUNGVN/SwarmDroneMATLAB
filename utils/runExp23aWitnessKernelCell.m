function row=runExp23aWitnessKernelCell(seedValue,cellInfo,condition,R)
%RUNEXP23AWITNESSKERNELCELL Execute and flatten one EXP23A kernel row.

base=applyExp21dClosedLoopCell(cellInfo.exp21dCell,seedValue);
probe=elcsWitnessKernelConfig(base.swarm.N,R.maxFrames);
baseTrace=generateElcsWitnessTrace(seedValue,probe);
[C,T,meta]=applyExp23aWitnessCondition(base,condition,baseTrace,R);
O=simulateElcsWitnessScheduling(C,T);
row=exp23aWitnessKernelEmptyRow();
row.seed=seedValue; row.scenario=cellInfo.id;
row.scenarioLabel=cellInfo.label; row.condition=condition.id;
row.conditionLabel=condition.label; row.conditionKind=condition.kind;
row.N=C.N; row.BASE_TRACE_HASH_EXACT=baseTrace.hashExact;
row.CONDITION_TRACE_HASH_EXACT=T.hashExact; row.CONFIG_HASH=O.configHash;
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
row.CLAIM_BYTES=O.claimBytes; row.CERTIFICATE_BYTES=O.certificateBytes;
row.CONTROL_BYTES=O.controlBytes; row.CONTROL_BYTE_BOUND=O.controlByteBound;
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
row.MAX_FALLBACK_ATTEMPTS_PER_NODE_FRAME=max(sum(O.debug.fallbackTx,2), ...
    [],'all');
row.BLACKOUT_OWNER=meta.blackoutOwner;
row.BLACKOUT_CLIENT=meta.blackoutClient;
row.BLACKOUT_WITNESS=meta.blackoutWitness;
if isfinite(meta.blackoutClient)
    row.BLACKOUT_CLIENT_FINAL_ACTIVE=double( ...
        O.finalActive(meta.blackoutClient));
end
row.ACCOUNTING_CLOSES=double( ...
    O.managementRecipientSuccess+O.managementRecipientErasure+ ...
    O.managementRecipientCollision==O.managementRecipientAttempts && ...
    O.scheduledRecipientSuccess+O.scheduledRecipientErasure+ ...
    O.scheduledRecipientCollision==O.scheduledRecipientAttempts && ...
    O.fallbackRecipientSuccess+O.fallbackRecipientErasure+ ...
    O.fallbackRecipientCollision==O.fallbackRecipientAttempts);
row.FUTURE_RANDOM_READS=O.futureRandomReads;
row.RECEIVER_TRUTH_READS=O.receiverTruthDecisionReads;

end
