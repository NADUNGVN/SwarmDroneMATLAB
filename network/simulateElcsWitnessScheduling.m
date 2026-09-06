function out=simulateElcsWitnessScheduling(C,T)
%SIMULATEELCSWITNESSSCHEDULING Local witness-certified lease kernel v1.

validateInputs(C,T);
N=C.N; F=C.maxFrames;
cumulativeRetry=isfield(C,'cumulativeReceiptRetry') && ...
    logical(C.cumulativeReceiptRetry);
coherenceEnabled=isfield(C,'coherenceLeaseEnabled') && ...
    logical(C.coherenceLeaseEnabled);
dynamicRevocation=coherenceEnabled && ...
    isfield(C,'dynamicRevocationEnabled') && ...
    logical(C.dynamicRevocationEnabled);
witnessConfirmedReactivation=dynamicRevocation && ...
    isfield(C,'witnessConfirmedEarlyReactivation') && ...
    logical(C.witnessConfirmedEarlyReactivation);
coherenceAdmissible=true;
if coherenceEnabled
    coherenceAdmissible=isfield(C,'coherenceLeaseAdmissible') && ...
        logical(C.coherenceLeaseAdmissible);
    if ~cumulativeRetry
        error(['simulateElcsWitnessScheduling: coherence lease ' ...
            'requires cumulative receipts.']);
    end
    if coherenceAdmissible && (~isfield(C,'coherenceHorizonFrames') || ...
            C.coherenceHorizonFrames~=C.leaseFrames)
        error(['simulateElcsWitnessScheduling: coherence ' ...
            'horizon/lease mismatch.']);
    end
end
if dynamicRevocation
    if ~coherenceAdmissible || ~C.deterministicControlSlots || ...
            ~isfield(C,'coherenceRevokeBytes')
        error(['simulateElcsWitnessScheduling: dynamic revocation ' ...
            'requires an admissible deterministic coherence lease.']);
    end
end
if witnessConfirmedReactivation && (~isfield(C,'migrationUnionGraphCertified') || ...
        ~logical(C.migrationUnionGraphCertified))
    error(['simulateElcsWitnessScheduling: early reactivation requires ' ...
        'a certified old/new union conflict graph.']);
end
W=buildConflictWitnessMap(C.conflictGraph,C.managementReach);
if ~W.allCovered
    error('simulateElcsWitnessScheduling: uncovered conflict edge.');
end
B=conflictWitnessPayloadBound(W,C.claimBytes, ...
    C.certificateHeaderBytes,C.certificateEntryBytes, ...
    C.maxControlPacketBytes);
if B.maxTransmittedEntriesAtWitness>B.entriesPerPacket
    error(['simulateElcsWitnessScheduling: v0 requires at most one ' ...
        'certificate fragment per witness and epoch.']);
end
[edgeOwner,edgeClient]=find(triu(logical(C.conflictGraph),1));
E=numel(edgeOwner);
edgeWitness=zeros(E,1);
for e=1:E, edgeWitness(e)=W.witness(edgeOwner(e),edgeClient(e)); end

slot=elcsWitnessPriorityColor(C.conflictGraph);
version=ones(N,1);
selfLockExpiry=zeros(N,1);
seenOwnerSlot=zeros(E,1); seenClientSlot=zeros(E,1);
seenOwnerVersion=zeros(E,1); seenClientVersion=zeros(E,1);
seenOwnerLock=zeros(E,1); seenClientLock=zeros(E,1);
seenOwnerClaimSeq=zeros(E,1); seenClientClaimSeq=zeros(E,1);
certOwnerSlot=zeros(E,1); certClientSlot=zeros(E,1);
certOwnerVersion=zeros(E,1); certClientVersion=zeros(E,1);
certExpiry=zeros(E,1);
claimSeq=zeros(N,1); forceClaim=false(N,1);
transactionActive=false(N,1);
ownerReceiptSeq=zeros(E,1); clientReceiptSeq=zeros(E,1);
claimTransactionStarts=0;
localSuppressed=false(N,1); reacquireReady=false(N,1);
claimSeqAtRevoke=zeros(N,1); revokeFenceUntil=zeros(N,1);
lastRevocationFrame=zeros(N,1); reacquisitionLatency=zeros(N,1);

claimAttempts=0; certificateAttempts=0;
claimBytes=0; certificateBytes=0;
revokeAttempts=0; revokeBytes=0; selfRevocationCount=0;
revokeRecipientAttempts=0; revokeRecipientSuccess=0;
revokeRecipientErasure=0; revokeRecipientCollision=0;
revokeAcceptedClears=0; revokeIgnoredDeliveries=0;
revokeWitnessClears=0;
reacquisitionCount=0;
managementRecipientAttempts=0; managementRecipientSuccess=0;
managementRecipientErasure=0; managementRecipientCollision=0;
certificateEntriesAttempted=0; responseEntriesAttempted=0;
localCertificateEntries=0; retryClaimAttempts=0;
certificateWithoutFreshClaims=0; falseValidEdgeFrames=0;
scheduledAttempts=0; fallbackAttempts=0;
scheduledRecipientAttempts=0; scheduledRecipientSuccess=0;
scheduledRecipientErasure=0; scheduledRecipientCollision=0;
fallbackRecipientAttempts=0; fallbackRecipientSuccess=0;
fallbackRecipientErasure=0; fallbackRecipientCollision=0;
scheduledCollisionFrames=0; fallbackCollisionFrames=0;
firstAllCertifiedFrame=NaN;

debugClaimTx=false(F,N); debugCertificateTx=false(F,N);
debugActive=false(F,N); debugSlot=repmat(slot',F,1);
debugClaimSuccess=false(F,N,N); debugCertificateSuccess=false(F,N,N);
debugClaimErasure=false(F,N,N); debugClaimCollision=false(F,N,N);
debugRevokeSuccess=false(F,N,N); debugRevokeErasure=false(F,N,N);
debugRevokeCollision=false(F,N,N);
debugCertificateErasure=false(F,N,N);
debugCertificateCollision=false(F,N,N);
debugScheduledSuccess=false(F,N,N);
debugScheduledErasure=false(F,N,N);
debugScheduledCollision=false(F,N,N);
debugFallbackTx=false(F,C.fallbackSlots,N);
debugFallbackSuccess=false(F,C.fallbackSlots,N,N);
debugFallbackErasure=false(F,C.fallbackSlots,N,N);
debugFallbackCollision=false(F,C.fallbackSlots,N,N);
debugCertificateEntries=zeros(F,N);
debugCertificateBytes=zeros(F,N);
debugForceClaim=false(F,N);
debugRevokeTx=false(F,N); debugSuppressed=false(F,N);
debugVersion=zeros(F,N); debugReacquired=false(F,N);

for frame=1:F
    revokeTx=false(N,1); revokeOldVersion=zeros(N,1);
    if dynamicRevocation
        requested=logical(T.selfRevoke(frame,:))';
        revokeTx=requested & ~localSuppressed;
        for node=find(revokeTx)'
            revokeOldVersion(node)=version(node);
            revokeFenceUntil(node)=max(frame,selfLockExpiry(node));
            lastRevocationFrame(node)=frame;
            claimSeqAtRevoke(node)=claimSeq(node);
            localSuppressed(node)=true;
            reacquireReady(node)=false;
            transactionActive(node)=false;
            forceClaim(node)=false;
            version(node)=version(node)+1;
            selfRevocationCount=selfRevocationCount+1;
            % The revoker immediately clears its own client-side cache.
            for e=reshape(find(edgeClient==node),1,[])
                if certClientVersion(e)==revokeOldVersion(node)
                    certExpiry(e)=0;
                    revokeAcceptedClears=revokeAcceptedClears+1;
                end
            end
        end
        eligible=logical(T.reacquireEligible(frame,:))' & localSuppressed;
        reacquireReady=reacquireReady | eligible;
        forceClaim(eligible)=true;
    end
    claimPermitted=~localSuppressed | reacquireReady;
    periodicClaim=coherenceAdmissible && ...
        mod(frame-1,C.renewalPeriodFrames)==0;
    periodicClaim=repmat(periodicClaim,N,1) & claimPermitted & ~revokeTx;
    if cumulativeRetry
        startTransaction=(periodicClaim | (forceClaim & claimPermitted)) & ...
            ~revokeTx & ...
            ~transactionActive;
        retry=transactionActive & claimPermitted & ~revokeTx;
        claimTx=startTransaction | retry;
        retryClaimAttempts=retryClaimAttempts+nnz(retry);
        debugForceClaim(frame,:)=retry;
        forceClaim(claimTx)=false;
        claimSeq(startTransaction)=claimSeq(startTransaction)+1;
        transactionActive(startTransaction)=true;
        claimTransactionStarts=claimTransactionStarts+nnz(startTransaction);
    else
        requestedForce=forceClaim & claimPermitted & ~revokeTx;
        retryClaimAttempts=retryClaimAttempts+nnz( ...
            requestedForce & ~periodicClaim);
        claimTx=periodicClaim | requestedForce;
        debugForceClaim(frame,:)=requestedForce;
        forceClaim(claimTx)=false;
        claimSeq(claimTx)=claimSeq(claimTx)+1;
        claimTransactionStarts=claimTransactionStarts+nnz(claimTx);
    end
    selfLockExpiry(claimTx)=max(selfLockExpiry(claimTx), ...
        frame+C.leaseFrames+C.leaseFenceFrames);
    if C.deterministicControlSlots
        claimChoice=(1:N)';
    else
        claimChoice=1+floor(T.claimSlotU(frame,:)'*C.controlSlots);
    end
    Aclaim=phaseDelivery(find(claimTx),claimChoice, ...
        C.managementReach,C.interferenceMatrix, ...
        squeeze(T.claimDeliveryU(frame,:,:)), ...
        C.claimErasureProbability);
    claimAttempts=claimAttempts+Aclaim.attempts;
    claimBytes=claimBytes+Aclaim.attempts*C.claimBytes;
    managementRecipientAttempts=managementRecipientAttempts+ ...
        Aclaim.recipientAttempts;
    managementRecipientSuccess=managementRecipientSuccess+ ...
        Aclaim.recipientSuccess;
    managementRecipientErasure=managementRecipientErasure+ ...
        Aclaim.recipientErasure;
    managementRecipientCollision=managementRecipientCollision+ ...
        Aclaim.recipientCollision;

    Arevoke=phaseDelivery(find(revokeTx),(1:N)', ...
        C.managementReach,C.interferenceMatrix, ...
        dynamicRevokeDraws(T,frame,N),0);
    revokeAttempts=revokeAttempts+Arevoke.attempts;
    if dynamicRevocation
        revokeBytes=revokeBytes+Arevoke.attempts*C.coherenceRevokeBytes;
    end
    revokeRecipientAttempts=revokeRecipientAttempts+Arevoke.recipientAttempts;
    revokeRecipientSuccess=revokeRecipientSuccess+Arevoke.recipientSuccess;
    revokeRecipientErasure=revokeRecipientErasure+Arevoke.recipientErasure;
    revokeRecipientCollision=revokeRecipientCollision+Arevoke.recipientCollision;
    managementRecipientAttempts=managementRecipientAttempts+ ...
        Arevoke.recipientAttempts;
    managementRecipientSuccess=managementRecipientSuccess+ ...
        Arevoke.recipientSuccess;
    managementRecipientErasure=managementRecipientErasure+ ...
        Arevoke.recipientErasure;
    managementRecipientCollision=managementRecipientCollision+ ...
        Arevoke.recipientCollision;
    for node=find(revokeTx)'
        incident=find(edgeOwner==node | edgeClient==node);
        for e=reshape(incident,1,[])
            client=edgeClient(e);
            if client==node, continue; end
            if ~Arevoke.successMask(client,node), continue; end
            if edgeOwner(e)==node
                cachedVersion=certOwnerVersion(e);
            else
                cachedVersion=certClientVersion(e);
            end
            decision=coherenceRevokeCacheDecision(cachedVersion, ...
                revokeOldVersion(node),version(node),true);
            if decision.accept
                certExpiry(e)=0;
                revokeAcceptedClears=revokeAcceptedClears+1;
            else
                revokeIgnoredDeliveries=revokeIgnoredDeliveries+1;
            end
        end
        for e=reshape(incident,1,[])
            witness=edgeWitness(e);
            delivered=witness==node || Arevoke.successMask(witness,node);
            if ~delivered, continue; end
            if edgeOwner(e)==node
                decision=coherenceRevokeCacheDecision( ...
                    seenOwnerVersion(e),revokeOldVersion(node), ...
                    version(node),true);
                if decision.accept
                    seenOwnerSlot(e)=0; seenOwnerVersion(e)=0;
                    seenOwnerLock(e)=0; seenOwnerClaimSeq(e)=0;
                    ownerReceiptSeq(e)=0;
                    revokeWitnessClears=revokeWitnessClears+1;
                end
            else
                decision=coherenceRevokeCacheDecision( ...
                    seenClientVersion(e),revokeOldVersion(node), ...
                    version(node),true);
                if decision.accept
                    seenClientSlot(e)=0; seenClientVersion(e)=0;
                    seenClientLock(e)=0; seenClientClaimSeq(e)=0;
                    clientReceiptSeq(e)=0;
                    revokeWitnessClears=revokeWitnessClears+1;
                end
            end
        end
    end

    for e=1:E
        a=edgeOwner(e); b=edgeClient(e); w=edgeWitness(e);
        if claimTx(a) && (w==a || Aclaim.successMask(w,a))
            seenOwnerSlot(e)=slot(a); seenOwnerVersion(e)=version(a);
            seenOwnerLock(e)=selfLockExpiry(a);
            seenOwnerClaimSeq(e)=claimSeq(a);
        end
        if claimTx(b) && (w==b || Aclaim.successMask(w,b))
            seenClientSlot(e)=slot(b); seenClientVersion(e)=version(b);
            seenClientLock(e)=selfLockExpiry(b);
            seenClientClaimSeq(e)=claimSeq(b);
        end
    end

    fresh=seenOwnerLock-frame>C.leaseFenceFrames & ...
        seenClientLock-frame>C.leaseFenceFrames;
    distinct=seenOwnerSlot>0 & seenClientSlot>0 & ...
        seenOwnerSlot~=seenClientSlot;
    ownerEvidence=claimTx(edgeOwner) & ...
        seenOwnerClaimSeq==claimSeq(edgeOwner);
    clientEvidence=claimTx(edgeClient) & ...
        seenClientClaimSeq==claimSeq(edgeClient);
    responseEvidence=ownerEvidence | clientEvidence;
    pending=fresh & distinct & responseEvidence;
    certificateWithoutFreshClaims=certificateWithoutFreshClaims+ ...
        nnz(pending & ~fresh);
    entries=zeros(N,1);
    for e=find(responseEvidence)'
        w=edgeWitness(e);
        entries(w)=entries(w)+1;
    end
    certificateTx=entries>0;
    if C.deterministicControlSlots
        certificateChoice=(1:N)';
    else
        certificateChoice=1+floor( ...
            T.certificateSlotU(frame,:)'*C.controlSlots);
    end
    Acert=phaseDelivery(find(certificateTx),certificateChoice, ...
        C.managementReach,C.interferenceMatrix, ...
        squeeze(T.certificateDeliveryU(frame,:,:)), ...
        C.certificateErasureProbability);
    certificateAttempts=certificateAttempts+Acert.attempts;
    frameCertificateBytes=zeros(N,1);
    frameCertificateBytes(certificateTx)= ...
        C.certificateHeaderBytes+entries(certificateTx)* ...
        C.certificateEntryBytes;
    certificateBytes=certificateBytes+sum(frameCertificateBytes);
    responseEntriesAttempted=responseEntriesAttempted+sum(entries);
    certificateEntriesAttempted=certificateEntriesAttempted+nnz(pending);
    managementRecipientAttempts=managementRecipientAttempts+ ...
        Acert.recipientAttempts;
    managementRecipientSuccess=managementRecipientSuccess+ ...
        Acert.recipientSuccess;
    managementRecipientErasure=managementRecipientErasure+ ...
        Acert.recipientErasure;
    managementRecipientCollision=managementRecipientCollision+ ...
        Acert.recipientCollision;

    for e=find(pending)'
        w=edgeWitness(e); b=edgeClient(e);
        local=(w==b);
        if local, localCertificateEntries=localCertificateEntries+1; end
        delivered=local || Acert.successMask(b,w);
        if ~delivered, continue; end
        certOwnerSlot(e)=seenOwnerSlot(e);
        certClientSlot(e)=seenClientSlot(e);
        certOwnerVersion(e)=seenOwnerVersion(e);
        certClientVersion(e)=seenClientVersion(e);
        certExpiry(e)=min(seenOwnerLock(e),seenClientLock(e))- ...
            C.leaseFenceFrames;
    end

    % A sender retries until each incident witness acknowledges its CLAIM.
    % v1 starts a new sequence and requires all receipts in one frame. The
    % cumulative mode keeps one sequence and retains receipts across frames.
    if cumulativeRetry
        for e=1:E
            w=edgeWitness(e); a=edgeOwner(e); b=edgeClient(e);
            if ownerEvidence(e) && (w==a || Acert.successMask(a,w))
                ownerReceiptSeq(e)=claimSeq(a);
            end
            if clientEvidence(e) && (w==b || Acert.successMask(b,w))
                clientReceiptSeq(e)=claimSeq(b);
            end
        end
        for node=find(transactionActive)'
            incident=find(edgeOwner==node | edgeClient==node);
            complete=true;
            for e=reshape(incident,1,[])
                if edgeOwner(e)==node
                    complete=complete && ...
                        ownerReceiptSeq(e)==claimSeq(node);
                else
                    complete=complete && ...
                        clientReceiptSeq(e)==claimSeq(node);
                end
            end
            if complete, transactionActive(node)=false; end
        end
    else
        for node=find(claimTx)'
            incident=find(edgeOwner==node | edgeClient==node);
            for e=reshape(incident,1,[])
                w=edgeWitness(e);
                if edgeOwner(e)==node
                    witnessed=seenOwnerClaimSeq(e)==claimSeq(node);
                else
                    witnessed=seenClientClaimSeq(e)==claimSeq(node);
                end
                receipt=responseEvidence(e) && ...
                    (w==node || Acert.successMask(node,w));
                if ~(witnessed && receipt)
                    forceClaim(node)=true;
                    break;
                end
            end
        end
    end

    if dynamicRevocation
        for node=find(localSuppressed & reacquireReady)'
            freshClaim=claimSeq(node)>claimSeqAtRevoke(node);
            fenceSatisfied=frame>revokeFenceUntil(node) || ...
                witnessConfirmedReactivation;
            if freshClaim && ~transactionActive(node) && fenceSatisfied
                localSuppressed(node)=false;
                reacquireReady(node)=false;
                reacquisitionCount=reacquisitionCount+1;
                reacquisitionLatency(node)=frame-lastRevocationFrame(node);
                debugReacquired(frame,node)=true;
            end
        end
    end

    active=true(N,1);
    if coherenceEnabled && ~coherenceAdmissible
        active=false(N,1);
    end
    for node=2:N
        if coherenceEnabled && ~coherenceAdmissible, break; end
        incident=find(edgeClient==node);
        if isempty(incident), continue; end
        active(node)=all(certExpiry(incident)-frame> ...
            C.leaseFenceFrames & ...
            certOwnerSlot(incident)==slot(edgeOwner(incident)) & ...
            certClientSlot(incident)==slot(node) & ...
            certClientVersion(incident)==version(node));
        if any(certExpiry(incident)-frame<= ...
                C.refreshLeadFrames+C.leaseFenceFrames)
            if ~cumulativeRetry || ~transactionActive(node)
                forceClaim(node)=true;
            end
        end
    end
    active(localSuppressed)=false;

    for e=1:E
        b=edgeClient(e);
        if ~active(b), continue; end
        valid=certExpiry(e)-frame>C.leaseFenceFrames && ...
            certOwnerSlot(e)==slot(edgeOwner(e)) && ...
            certClientSlot(e)==slot(b) && ...
            certOwnerSlot(e)~=certClientSlot(e) && ...
            selfLockExpiry(edgeOwner(e))>= ...
            certExpiry(e)+C.leaseFenceFrames && ...
            selfLockExpiry(b)>=certExpiry(e)+C.leaseFenceFrames;
        falseValidEdgeFrames=falseValidEdgeFrames+double(~valid);
    end

    for dataSlot=1:C.frameLength
        tx=find(active & slot==dataSlot);
        if isempty(tx), continue; end
        A=dataDelivery(tx,C.neighborGraph, ...
            frameDataInterference(C,T,frame), ...
            squeeze(T.scheduledDeliveryU(frame,:,:)), ...
            C.dataErasureProbability);
        scheduledAttempts=scheduledAttempts+A.attempts;
        scheduledRecipientAttempts=scheduledRecipientAttempts+A.recipientAttempts;
        scheduledRecipientSuccess=scheduledRecipientSuccess+A.recipientSuccess;
        scheduledRecipientErasure=scheduledRecipientErasure+A.recipientErasure;
        scheduledRecipientCollision=scheduledRecipientCollision+A.recipientCollision;
        scheduledCollisionFrames=scheduledCollisionFrames+ ...
            double(any(A.collisionMask,'all'));
        debugScheduledSuccess(frame,:,:)=reshape( ...
            squeeze(debugScheduledSuccess(frame,:,:)) | A.successMask,N,N);
        debugScheduledErasure(frame,:,:)=reshape( ...
            squeeze(debugScheduledErasure(frame,:,:)) | A.erasureMask,N,N);
        debugScheduledCollision(frame,:,:)=reshape( ...
            squeeze(debugScheduledCollision(frame,:,:)) | A.collisionMask,N,N);
    end

    invalid=~active; attempted=false(N,1);
    for fallbackSlot=1:C.fallbackSlots
        tx=find(invalid & ~attempted & squeeze( ...
            T.fallbackAccessU(frame,fallbackSlot,:))<= ...
            C.fallbackAccessProbability);
        attempted(tx)=true;
        debugFallbackTx(frame,fallbackSlot,tx)=true;
        if isempty(tx), continue; end
        A=dataDelivery(tx,C.neighborGraph, ...
            frameDataInterference(C,T,frame), ...
            squeeze(T.fallbackDeliveryU(frame,fallbackSlot,:,:)), ...
            C.dataErasureProbability);
        fallbackAttempts=fallbackAttempts+A.attempts;
        fallbackRecipientAttempts=fallbackRecipientAttempts+A.recipientAttempts;
        fallbackRecipientSuccess=fallbackRecipientSuccess+A.recipientSuccess;
        fallbackRecipientErasure=fallbackRecipientErasure+A.recipientErasure;
        fallbackRecipientCollision=fallbackRecipientCollision+A.recipientCollision;
        fallbackCollisionFrames=fallbackCollisionFrames+ ...
            double(any(A.collisionMask,'all'));
        debugFallbackSuccess(frame,fallbackSlot,:,:)=A.successMask;
        debugFallbackErasure(frame,fallbackSlot,:,:)=A.erasureMask;
        debugFallbackCollision(frame,fallbackSlot,:,:)=A.collisionMask;
    end
    if all(active) && isnan(firstAllCertifiedFrame)
        firstAllCertifiedFrame=frame;
    end
    debugClaimTx(frame,:)=claimTx;
    debugCertificateTx(frame,:)=certificateTx;
    debugClaimSuccess(frame,:,:)=Aclaim.successMask;
    debugClaimErasure(frame,:,:)=Aclaim.erasureMask;
    debugClaimCollision(frame,:,:)=Aclaim.collisionMask;
    debugRevokeSuccess(frame,:,:)=Arevoke.successMask;
    debugRevokeErasure(frame,:,:)=Arevoke.erasureMask;
    debugRevokeCollision(frame,:,:)=Arevoke.collisionMask;
    debugCertificateSuccess(frame,:,:)=Acert.successMask;
    debugCertificateErasure(frame,:,:)=Acert.erasureMask;
    debugCertificateCollision(frame,:,:)=Acert.collisionMask;
    debugActive(frame,:)=active;
    debugCertificateEntries(frame,:)=entries;
    debugCertificateBytes(frame,:)=frameCertificateBytes;
    debugRevokeTx(frame,:)=revokeTx;
    debugSuppressed(frame,:)=localSuppressed;
    debugVersion(frame,:)=version;
end

epochs=ceil(F/C.renewalPeriodFrames);
nominalAttemptBound=epochs*B.totalAttemptsPerEpoch;
nominalByteBound=epochs*B.totalBytesPerEpoch;
maximumRevokeAttempts=double(dynamicRevocation)*F*N;
attemptBound=F*B.totalAttemptsPerEpoch+maximumRevokeAttempts;
maximumRevokeBytes=0;
if dynamicRevocation
    maximumRevokeBytes=maximumRevokeAttempts*C.coherenceRevokeBytes;
end
byteBound=F*B.totalBytesPerEpoch+maximumRevokeBytes;
scheduledStateHash=realizationHash([slot;version;claimSeq; ...
    double(transactionActive);ownerReceiptSeq;clientReceiptSeq; ...
    certOwnerSlot; ...
    certClientSlot;certOwnerVersion;certClientVersion;certExpiry; ...
    double(localSuppressed);revokeFenceUntil;reacquisitionLatency; ...
    double(debugActive(:));double(debugRevokeTx(:)); ...
    double(debugSuppressed(:))]);
kernelVersion='ELCS-W-KERNEL-v1';
if cumulativeRetry, kernelVersion='ELCS-W-KERNEL-CUMULATIVE-v2'; end
if dynamicRevocation, kernelVersion='ELCS-W-COHERENCE-REVOCATION-v3'; end
out=struct('version',kernelVersion,'N',N,'maxFrames',F, ...
    'slot',slot,'finalActive',debugActive(end,:)', ...
    'finalAllCertified',all(debugActive(end,:)), ...
    'firstAllCertifiedFrame',firstAllCertifiedFrame, ...
    'witnessMap',W,'payloadBound',B, ...
    'claimAttempts',claimAttempts,'certificateAttempts',certificateAttempts, ...
    'controlAttempts',claimAttempts+certificateAttempts+revokeAttempts, ...
    'claimBytes',claimBytes,'certificateBytes',certificateBytes, ...
    'controlBytes',claimBytes+certificateBytes+revokeBytes, ...
    'nominalControlAttemptBound',nominalAttemptBound, ...
    'nominalControlByteBound',nominalByteBound, ...
    'controlAttemptBound',attemptBound,'controlByteBound',byteBound, ...
    'controlAttemptBoundRatio',(claimAttempts+certificateAttempts+ ...
    revokeAttempts)/attemptBound, ...
    'controlByteBoundRatio',(claimBytes+certificateBytes+revokeBytes)/byteBound, ...
    'certificateEntriesAttempted',certificateEntriesAttempted, ...
    'responseEntriesAttempted',responseEntriesAttempted, ...
    'localCertificateEntries',localCertificateEntries, ...
    'retryClaimAttempts',retryClaimAttempts, ...
    'claimTransactionStarts',claimTransactionStarts, ...
    'cumulativeReceiptRetry',double(cumulativeRetry), ...
    'coherenceLeaseEnabled',double(coherenceEnabled), ...
    'coherenceLeaseAdmissible',double(coherenceAdmissible), ...
    'coherenceHorizonFrames',coherenceHorizonFrames(C), ...
    'dynamicRevocationEnabled',double(dynamicRevocation), ...
    'witnessConfirmedEarlyReactivation', ...
    double(witnessConfirmedReactivation), ...
    'selfRevocationCount',selfRevocationCount, ...
    'revokeAttempts',revokeAttempts,'revokeBytes',revokeBytes, ...
    'revokeRecipientAttempts',revokeRecipientAttempts, ...
    'revokeRecipientSuccess',revokeRecipientSuccess, ...
    'revokeRecipientErasure',revokeRecipientErasure, ...
    'revokeRecipientCollision',revokeRecipientCollision, ...
    'revokeAcceptedClears',revokeAcceptedClears, ...
    'revokeIgnoredDeliveries',revokeIgnoredDeliveries, ...
    'revokeWitnessClears',revokeWitnessClears, ...
    'reacquisitionCount',reacquisitionCount, ...
    'reacquisitionLatencyFrames',reacquisitionLatency, ...
    'revokeFenceUntilFrame',revokeFenceUntil, ...
    'lastRevocationFrame',lastRevocationFrame, ...
    'finalSuppressed',localSuppressed,'finalVersion',version, ...
    'finalOpenClaimTransactions',nnz(transactionActive), ...
    'certificateWithoutFreshClaims',certificateWithoutFreshClaims, ...
    'managementRecipientAttempts',managementRecipientAttempts, ...
    'managementRecipientSuccess',managementRecipientSuccess, ...
    'managementRecipientErasure',managementRecipientErasure, ...
    'managementRecipientCollision',managementRecipientCollision, ...
    'falseValidEdgeFrames',falseValidEdgeFrames, ...
    'scheduledAttempts',scheduledAttempts,'fallbackAttempts',fallbackAttempts, ...
    'scheduledRecipientAttempts',scheduledRecipientAttempts, ...
    'scheduledRecipientSuccess',scheduledRecipientSuccess, ...
    'scheduledRecipientErasure',scheduledRecipientErasure, ...
    'scheduledRecipientCollision',scheduledRecipientCollision, ...
    'fallbackRecipientAttempts',fallbackRecipientAttempts, ...
    'fallbackRecipientSuccess',fallbackRecipientSuccess, ...
    'fallbackRecipientErasure',fallbackRecipientErasure, ...
    'fallbackRecipientCollision',fallbackRecipientCollision, ...
    'scheduledCollisionFrames',scheduledCollisionFrames, ...
    'fallbackCollisionFrames',fallbackCollisionFrames, ...
    'scheduleStateHash',scheduledStateHash,'traceHash',T.hashExact, ...
    'configHash',configHash(C),'futureRandomReads',0, ...
    'receiverTruthDecisionReads',0, ...
    'debug',struct('claimTx',debugClaimTx, ...
    'certificateTx',debugCertificateTx,'revokeTx',debugRevokeTx, ...
    'active',debugActive,'suppressed',debugSuppressed, ...
    'version',debugVersion,'reacquired',debugReacquired, ...
    'slot',debugSlot,'claimSuccess',debugClaimSuccess, ...
    'claimErasure',debugClaimErasure, ...
    'claimCollision',debugClaimCollision, ...
    'revokeSuccess',debugRevokeSuccess, ...
    'revokeErasure',debugRevokeErasure, ...
    'revokeCollision',debugRevokeCollision, ...
    'certificateSuccess',debugCertificateSuccess, ...
    'certificateErasure',debugCertificateErasure, ...
    'certificateCollision',debugCertificateCollision, ...
    'certificateEntries',debugCertificateEntries, ...
    'certificateBytes',debugCertificateBytes, ...
    'forceClaim',debugForceClaim, ...
    'scheduledSuccess',debugScheduledSuccess, ...
    'scheduledErasure',debugScheduledErasure, ...
    'scheduledCollision',debugScheduledCollision, ...
    'fallbackTx',debugFallbackTx,'fallbackSuccess',debugFallbackSuccess, ...
    'fallbackErasure',debugFallbackErasure, ...
    'fallbackCollision',debugFallbackCollision));

end


function validateInputs(C,T)

required={'N','maxFrames','frameLength','controlSlots','fallbackSlots', ...
    'leaseFrames','refreshLeadFrames','leaseFenceFrames', ...
    'renewalPeriodFrames','fallbackAccessProbability','claimBytes', ...
    'certificateHeaderBytes','certificateEntryBytes', ...
    'maxControlPacketBytes','claimErasureProbability', ...
    'certificateErasureProbability','dataErasureProbability', ...
    'neighborGraph','managementReach','interferenceMatrix','conflictGraph'};
if ~isstruct(C) || ~all(isfield(C,required))
    error('simulateElcsWitnessScheduling: incomplete configuration.');
end
N=C.N; F=C.maxFrames; W=C.fallbackSlots;
if C.renewalPeriodFrames>C.leaseFrames-C.refreshLeadFrames- ...
        C.leaseFenceFrames
    error('simulateElcsWitnessScheduling: renewal period violates lease slack.');
end
for field={'neighborGraph','managementReach','interferenceMatrix','conflictGraph'}
    if ~isequal(size(C.(field{1})),[N N])
        error('simulateElcsWitnessScheduling: invalid graph dimension.');
    end
end
for p=[C.fallbackAccessProbability C.claimErasureProbability ...
        C.certificateErasureProbability C.dataErasureProbability]
    if ~isfinite(p) || p<0 || p>1
        error('simulateElcsWitnessScheduling: invalid probability.');
    end
end
dims=struct('claimSlotU',[F N],'certificateSlotU',[F N], ...
    'claimDeliveryU',[F N N],'certificateDeliveryU',[F N N], ...
    'scheduledDeliveryU',[F N N], ...
    'fallbackAccessU',[F W N], ...
    'fallbackDeliveryU',[F W N N]);
for field=fieldnames(dims)'
    name=field{1};
    if ~isfield(T,name) || ~isequal(size(T.(name)),dims.(name))
        error('simulateElcsWitnessScheduling: invalid trace field %s.',name);
    end
end
if ~isfield(T,'hashExact')
    error('simulateElcsWitnessScheduling: trace hash missing.');
end
if T.hashExact~=elcsWitnessTraceHash(T)
    error('simulateElcsWitnessScheduling: trace hash mismatch.');
end
dynamic=isfield(C,'dynamicRevocationEnabled') && ...
    logical(C.dynamicRevocationEnabled);
if dynamic
    dynamicDims=struct('revokeDeliveryU',[F N N], ...
        'selfRevoke',[F N],'reacquireEligible',[F N], ...
        'actualInterference',[F N N]);
    for field=fieldnames(dynamicDims)'
        name=field{1};
        if ~isfield(T,name) || ~isequal(size(T.(name)),dynamicDims.(name))
            error(['simulateElcsWitnessScheduling: invalid dynamic ' ...
                'trace field %s.'],name);
        end
    end
    if any(~isfinite(double(T.selfRevoke(:)))) || ...
            any(~ismember(double(T.selfRevoke(:)),[0 1])) || ...
            any(~isfinite(double(T.reacquireEligible(:)))) || ...
            any(~ismember(double(T.reacquireEligible(:)),[0 1]))
        error('simulateElcsWitnessScheduling: invalid dynamic event mask.');
    end
    actual=logical(T.actualInterference);
    for frame=1:F
        graph=squeeze(actual(frame,:,:));
        if any(diag(graph)) || ~isequal(graph,graph')
            error(['simulateElcsWitnessScheduling: actual interference ' ...
                'must be a symmetric simple graph.']);
        end
    end
end

end


function value=coherenceHorizonFrames(C)
value=NaN;
if isfield(C,'coherenceHorizonFrames')
    value=C.coherenceHorizonFrames;
end
end


function draws=dynamicRevokeDraws(T,frame,N)

draws=ones(N);
if isfield(T,'revokeDeliveryU')
    draws=squeeze(T.revokeDeliveryU(frame,:,:));
end

end


function interference=frameDataInterference(C,T,frame)

interference=C.interferenceMatrix;
if isfield(C,'dynamicRevocationEnabled') && ...
        logical(C.dynamicRevocationEnabled)
    interference=squeeze(T.actualInterference(frame,:,:));
end

end


function A=phaseDelivery(tx,choice,reach,interference,draws,pLoss)

N=size(reach,1); A=emptyOutcome(N);
for minislot=1:max([0;choice(tx)])
    senders=tx(choice(tx)==minislot);
    if isempty(senders), continue; end
    A=mergeOutcome(A,dataDelivery( ...
        senders,reach,interference,draws,pLoss));
end
A.attempts=numel(tx);

end


function A=dataDelivery(tx,reach,interference,draws,pLoss)

N=size(reach,1); A=emptyOutcome(N);
if isempty(tx), return; end
tx=reshape(tx,1,[]); txMask=false(N,1); txMask(tx)=true;
A.attempts=numel(tx);
for sender=tx
    A.recipientAttempts=A.recipientAttempts+nnz(reach(:,sender) & ~txMask);
end
for receiver=1:N
    if txMask(receiver), continue; end
    intended=tx(reach(receiver,tx));
    detectable=tx(interference(receiver,tx) | reach(receiver,tx));
    if isempty(detectable), continue; end
    if isscalar(intended)
        sender=intended(1); other=detectable(detectable~=sender);
        if isempty(other)
            if draws(receiver,sender)>pLoss
                A.successMask(receiver,sender)=true;
                A.recipientSuccess=A.recipientSuccess+1;
            else
                A.erasureMask(receiver,sender)=true;
                A.recipientErasure=A.recipientErasure+1;
            end
            continue;
        end
    end
    if ~isempty(intended)
        A.collisionMask(receiver,intended)=true;
        A.recipientCollision=A.recipientCollision+numel(intended);
    end
end

end


function A=emptyOutcome(N)

A=struct('attempts',0,'recipientAttempts',0,'recipientSuccess',0, ...
    'recipientErasure',0,'recipientCollision',0, ...
    'successMask',false(N),'erasureMask',false(N), ...
    'collisionMask',false(N));

end


function A=mergeOutcome(A,B)

A.recipientAttempts=A.recipientAttempts+B.recipientAttempts;
A.recipientSuccess=A.recipientSuccess+B.recipientSuccess;
A.recipientErasure=A.recipientErasure+B.recipientErasure;
A.recipientCollision=A.recipientCollision+B.recipientCollision;
A.successMask=A.successMask | B.successMask;
A.erasureMask=A.erasureMask | B.erasureMask;
A.collisionMask=A.collisionMask | B.collisionMask;

end
