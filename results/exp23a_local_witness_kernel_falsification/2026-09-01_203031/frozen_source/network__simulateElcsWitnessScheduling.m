function out=simulateElcsWitnessScheduling(C,T)
%SIMULATEELCSWITNESSSCHEDULING Local witness-certified lease kernel v0.

validateInputs(C,T);
N=C.N; F=C.maxFrames;
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

slot=priorityColor(C.conflictGraph);
version=ones(N,1);
selfLockExpiry=zeros(N,1);
seenOwnerSlot=zeros(E,1); seenClientSlot=zeros(E,1);
seenOwnerVersion=zeros(E,1); seenClientVersion=zeros(E,1);
seenOwnerLock=zeros(E,1); seenClientLock=zeros(E,1);
certOwnerSlot=zeros(E,1); certClientSlot=zeros(E,1);
certOwnerVersion=zeros(E,1); certClientVersion=zeros(E,1);
certExpiry=zeros(E,1);

claimAttempts=0; certificateAttempts=0;
claimBytes=0; certificateBytes=0;
managementRecipientAttempts=0; managementRecipientSuccess=0;
managementRecipientErasure=0; managementRecipientCollision=0;
certificateEntriesAttempted=0; localCertificateEntries=0;
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
debugScheduledSuccess=false(F,N,N);
debugScheduledErasure=false(F,N,N);
debugScheduledCollision=false(F,N,N);
debugFallbackTx=false(F,C.fallbackSlots,N);
debugFallbackSuccess=false(F,C.fallbackSlots,N,N);
debugFallbackErasure=false(F,C.fallbackSlots,N,N);
debugFallbackCollision=false(F,C.fallbackSlots,N,N);
debugCertificateEntries=zeros(F,N);
debugCertificateBytes=zeros(F,N);

for frame=1:F
    claimTx=mod(frame-1,C.renewalPeriodFrames)==0;
    claimTx=repmat(claimTx,N,1);
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

    for e=1:E
        a=edgeOwner(e); b=edgeClient(e); w=edgeWitness(e);
        if claimTx(a) && (w==a || Aclaim.successMask(w,a))
            seenOwnerSlot(e)=slot(a); seenOwnerVersion(e)=version(a);
            seenOwnerLock(e)=selfLockExpiry(a);
        end
        if claimTx(b) && (w==b || Aclaim.successMask(w,b))
            seenClientSlot(e)=slot(b); seenClientVersion(e)=version(b);
            seenClientLock(e)=selfLockExpiry(b);
        end
    end

    fresh=seenOwnerLock-frame>C.leaseFenceFrames & ...
        seenClientLock-frame>C.leaseFenceFrames;
    distinct=seenOwnerSlot>0 & seenClientSlot>0 & ...
        seenOwnerSlot~=seenClientSlot;
    renewalEvidence=claimTx(edgeOwner) | claimTx(edgeClient);
    pending=fresh & distinct & renewalEvidence;
    certificateWithoutFreshClaims=certificateWithoutFreshClaims+ ...
        nnz(pending & ~fresh);
    entries=zeros(N,1);
    for e=find(pending)'
        w=edgeWitness(e); b=edgeClient(e);
        if w~=b, entries(w)=entries(w)+1; end
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
    certificateEntriesAttempted=certificateEntriesAttempted+sum(entries);
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

    active=true(N,1);
    for node=2:N
        incident=find(edgeClient==node);
        if isempty(incident), continue; end
        active(node)=all(certExpiry(incident)-frame> ...
            C.leaseFenceFrames & ...
            certOwnerSlot(incident)==slot(edgeOwner(incident)) & ...
            certClientSlot(incident)==slot(node) & ...
            certOwnerVersion(incident)==version(edgeOwner(incident)) & ...
            certClientVersion(incident)==version(node));
    end

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
        A=dataDelivery(tx,C.neighborGraph,C.interferenceMatrix, ...
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
        A=dataDelivery(tx,C.neighborGraph,C.interferenceMatrix, ...
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
    debugCertificateSuccess(frame,:,:)=Acert.successMask;
    debugActive(frame,:)=active;
    debugCertificateEntries(frame,:)=entries;
    debugCertificateBytes(frame,:)=frameCertificateBytes;
end

epochs=ceil(F/C.renewalPeriodFrames);
attemptBound=epochs*B.totalAttemptsPerEpoch;
byteBound=epochs*B.totalBytesPerEpoch;
scheduledStateHash=realizationHash([slot;version;certOwnerSlot; ...
    certClientSlot;certOwnerVersion;certClientVersion;certExpiry; ...
    double(debugActive(:))]);
out=struct('version','ELCS-W-KERNEL-v0','N',N,'maxFrames',F, ...
    'slot',slot,'finalActive',debugActive(end,:)', ...
    'finalAllCertified',all(debugActive(end,:)), ...
    'firstAllCertifiedFrame',firstAllCertifiedFrame, ...
    'witnessMap',W,'payloadBound',B, ...
    'claimAttempts',claimAttempts,'certificateAttempts',certificateAttempts, ...
    'controlAttempts',claimAttempts+certificateAttempts, ...
    'claimBytes',claimBytes,'certificateBytes',certificateBytes, ...
    'controlBytes',claimBytes+certificateBytes, ...
    'controlAttemptBound',attemptBound,'controlByteBound',byteBound, ...
    'controlAttemptBoundRatio',(claimAttempts+certificateAttempts)/attemptBound, ...
    'controlByteBoundRatio',(claimBytes+certificateBytes)/byteBound, ...
    'certificateEntriesAttempted',certificateEntriesAttempted, ...
    'localCertificateEntries',localCertificateEntries, ...
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
    'certificateTx',debugCertificateTx,'active',debugActive, ...
    'slot',debugSlot,'claimSuccess',debugClaimSuccess, ...
    'certificateSuccess',debugCertificateSuccess, ...
    'certificateEntries',debugCertificateEntries, ...
    'certificateBytes',debugCertificateBytes, ...
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

end


function color=priorityColor(conflict)

N=size(conflict,1); color=zeros(N,1);
for node=1:N
    lowerMask=conflict(node,:) & (1:N)<node;
    unavailable=unique(color(lowerMask)); candidate=1;
    while any(unavailable==candidate), candidate=candidate+1; end
    color(node)=candidate;
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
