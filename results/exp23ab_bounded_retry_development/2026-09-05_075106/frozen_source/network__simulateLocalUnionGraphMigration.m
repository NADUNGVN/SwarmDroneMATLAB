function O=simulateLocalUnionGraphMigration(M,C,T)
%SIMULATELOCALUNIONGRAPHMIGRATION Packet-level one-sender transition.

validateInputs(M,C,T);
if localUnionMigrationTraceHash(T)~=T.hashExact
    error('simulateLocalUnionGraphMigration: trace hash mismatch.');
end
N=M.N; F=C.maxFrames; node=M.transitionNode;
reach=logical(M.managementReach); reach(1:N+1:end)=false;
[claimOpportunity,retryPolicy]=localUnionMigrationClaimSchedule(C);
claimP=probability(C,'claimErasureProbability');
proofP=probability(C,'lockProofErasureProbability');
responseP=probability(C,'responseErasureProbability');
revokeP=probability(C,'revokeErasureProbability');
neighbors=reshape(M.incidentNodes,[],1);
witnesses=reshape(M.incidentWitness,[],1);
E=numel(neighbors);

active=true(N,1); suppressed=false(N,1); currentSlot=M.oldSlot;
version=ones(N,1); claimSeq=0; transactionActive=false;
neighborSeen=false(E,1); receipt=false(E,1);
reacquired=false; firstReacquiredFrame=NaN; eventFrame=NaN;
unsupportedConcurrentMigration=false;

claimAttempts=0; proofAttempts=0; responseAttempts=0; revokeAttempts=0;
claimBytes=0; proofBytes=0; responseBytes=0; revokeBytes=0;
recipientAttempts=0; recipientSuccess=0; recipientErasure=0;
responseEntriesAttempted=0; acceptedResponseEntries=0;
scheduledCollisionFrames=0; scheduledCollisionEdges=0;
unsafeReuseFrames=0; actualSubsetUnion=true;
debugActive=false(F,N); debugSuppressed=false(F,N);
debugSlot=zeros(F,N); debugClaim=false(F,1); debugProof=false(F,N);
debugResponse=false(F,N); debugReceipt=false(F,E);
debugCollision=false(F,1); debugReacquired=false(F,1);
debugRevoke=false(F,N); debugResponseEntries=zeros(F,N);
debugResponseBytes=zeros(F,N);

for frame=1:F
    requested=find(logical(T.selfRevoke(frame,:)));
    if ~isempty(requested)
        if numel(requested)~=1 || requested~=node || isfinite(eventFrame)
            unsupportedConcurrentMigration=true;
            suppressed(requested)=true; active(requested)=false;
        else
            eventFrame=frame; suppressed(node)=true; active(node)=false;
            version(node)=version(node)+1;
            debugRevoke(frame,node)=true;
            revokeAttempts=revokeAttempts+1;
            revokeBytes=revokeBytes+M.config.revokeBytes;
            A=controlAttempt(node,squeeze(T.revokeDeliveryU(frame,:,:)), ...
                reach,revokeP);
            [recipientAttempts,recipientSuccess,recipientErasure]=accumulate( ...
                recipientAttempts,recipientSuccess,recipientErasure,A);
        end
    end

    eligible=isfinite(eventFrame) && frame>=C.eligibleFrame && ...
        suppressed(node) && ~unsupportedConcurrentMigration && M.admissible;
    if eligible && ~transactionActive && claimSeq==0
        claimSeq=1; transactionActive=true;
    end
    currentMigrateSeen=false(E,1);
    if transactionActive && claimOpportunity(frame)
        debugClaim(frame)=true;
        claimAttempts=claimAttempts+1;
        claimBytes=claimBytes+M.config.claimBytes;
        A=controlAttempt(node,squeeze(T.claimDeliveryU(frame,:,:)), ...
            reach,claimP);
        [recipientAttempts,recipientSuccess,recipientErasure]=accumulate( ...
            recipientAttempts,recipientSuccess,recipientErasure,A);
        for e=1:E
            w=witnesses(e);
            if w==node || A.success(w)
                currentMigrateSeen(e)=true;
            end
        end
    end

    proofWindow=isfinite(eventFrame) && frame>=C.eligibleFrame && ...
        frame<C.eligibleFrame+C.lockProofRepeatFrames && ...
        ~unsupportedConcurrentMigration && M.admissible;
    if proofWindow
        proofSenders=unique(neighbors);
        for sender=reshape(proofSenders,1,[])
            debugProof(frame,sender)=true;
            proofAttempts=proofAttempts+1;
            proofBytes=proofBytes+M.config.claimBytes;
            A=controlAttempt(sender, ...
                squeeze(T.lockProofDeliveryU(frame,:,:)),reach,proofP);
            [recipientAttempts,recipientSuccess,recipientErasure]=accumulate( ...
                recipientAttempts,recipientSuccess,recipientErasure,A);
            for e=reshape(find(neighbors==sender),1,[])
                w=witnesses(e);
                if w==sender || A.success(w), neighborSeen(e)=true; end
            end
        end
    end

    if transactionActive
        % A witness responds only to a CLAIM received in this frame. Once
        % the revoker stops its local retry, witnesses stop causally without
        % reading the revoker's private receipt state. Neighbor LOCK-PROOF
        % attempts follow the fixed window above for the same reason.
        ready=currentMigrateSeen & neighborSeen & ~receipt;
        for w=reshape(unique(witnesses(ready)),1,[])
            entries=find(ready & witnesses==w);
            if isempty(entries), continue; end
            debugResponse(frame,w)=true;
            responseAttempts=responseAttempts+1;
            packetBytes=M.config.certificateHeaderBytes+ ...
                numel(entries)*M.config.certificateEntryBytes;
            responseBytes=responseBytes+packetBytes;
            responseEntriesAttempted=responseEntriesAttempted+numel(entries);
            debugResponseEntries(frame,w)=numel(entries);
            debugResponseBytes(frame,w)=packetBytes;
            A=controlAttempt(w,squeeze(T.responseDeliveryU(frame,:,:)), ...
                reach,responseP);
            [recipientAttempts,recipientSuccess,recipientErasure]=accumulate( ...
                recipientAttempts,recipientSuccess,recipientErasure,A);
            delivered=w==node || A.success(node);
            metadataOk=T.responseVersion(frame,w)==version(node) && ...
                T.responseClaimSeq(frame,w)==claimSeq;
            if delivered && metadataOk
                receipt(entries)=true;
                acceptedResponseEntries=acceptedResponseEntries+numel(entries);
            end
        end
        if all(receipt)
            transactionActive=false; suppressed(node)=false; active(node)=true;
            currentSlot(node)=M.newSlot; reacquired=true;
            firstReacquiredFrame=frame; debugReacquired(frame)=true;
        end
    end

    actual=logical(squeeze(T.actualGraph(frame,:,:)));
    actualSubsetUnion=actualSubsetUnion && ...
        ~any(triu(actual & ~M.unionGraph,1),'all');
    collision=false; collisionEdges=0;
    [a,b]=find(triu(actual,1));
    for e=1:numel(a)
        if active(a(e)) && active(b(e)) && ...
                currentSlot(a(e))==currentSlot(b(e))
            collision=true; collisionEdges=collisionEdges+1;
        end
    end
    scheduledCollisionFrames=scheduledCollisionFrames+double(collision);
    scheduledCollisionEdges=scheduledCollisionEdges+collisionEdges;
    debugCollision(frame)=collision;
    if active(node)
        incident=find(actual(:,node));
        unsafe=any(currentSlot(incident)==currentSlot(node));
        unsafeReuseFrames=unsafeReuseFrames+double(unsafe);
    end
    debugActive(frame,:)=active;
    debugSuppressed(frame,:)=suppressed;
    debugSlot(frame,:)=currentSlot;
    debugReceipt(frame,:)=receipt;
end

retryFrames=nnz(claimOpportunity);
horizonFrames=max(0,F-C.eligibleFrame+1);
uniqueWitnesses=numel(unique(witnesses));
proofFrames=min(C.lockProofRepeatFrames,horizonFrames);
attemptBound=1+retryFrames*(1+uniqueWitnesses)+ ...
    proofFrames*numel(unique(neighbors));
responseBytesPerRetry=0;
for w=reshape(unique(witnesses),1,[])
    responseBytesPerRetry=responseBytesPerRetry+ ...
        M.config.certificateHeaderBytes+ ...
        nnz(witnesses==w)*M.config.certificateEntryBytes;
end
byteBound=M.config.revokeBytes+retryFrames*( ...
    M.config.claimBytes+responseBytesPerRetry)+proofFrames* ...
    numel(unique(neighbors))*M.config.claimBytes;
controlAttempts=claimAttempts+proofAttempts+responseAttempts+revokeAttempts;
controlBytes=claimBytes+proofBytes+responseBytes+revokeBytes;
retryBudgetExhausted=retryPolicy.enabled && transactionActive && ...
    claimAttempts==retryPolicy.opportunityCount;
O=struct('version','LOCAL-UNION-MIGRATION-KERNEL-v1', ...
    'traceHash',T.hashExact,'selectorHash',M.hashExact, ...
    'eventFrame',eventFrame,'eligibleFrame',C.eligibleFrame, ...
    'newGraphActivationFrame',C.newGraphActivationFrame, ...
    'lockProofRepeatFrames',C.lockProofRepeatFrames, ...
    'reacquired',double(reacquired), ...
    'firstReacquiredFrame',firstReacquiredFrame, ...
    'finalSuppressed',double(suppressed(node)), ...
    'finalSlot',currentSlot(node),'oldSlot',M.oldSlot(node), ...
    'newSlot',M.newSlot,'slotChanged',M.slotChanged, ...
    'transactionOpen',double(transactionActive), ...
    'acceptedResponseEntries',acceptedResponseEntries, ...
    'requiredResponseEntries',E, ...
    'responseEntriesAttempted',responseEntriesAttempted, ...
    'unsupportedConcurrentMigration',double(unsupportedConcurrentMigration), ...
    'actualSubsetUnion',double(actualSubsetUnion), ...
    'scheduledCollisionFrames',scheduledCollisionFrames, ...
    'scheduledCollisionEdges',scheduledCollisionEdges, ...
    'unsafeReuseFrames',unsafeReuseFrames, ...
    'claimAttempts',claimAttempts,'lockProofAttempts',proofAttempts, ...
    'responseAttempts',responseAttempts,'revokeAttempts',revokeAttempts, ...
    'claimBackoffEnabled',double(retryPolicy.enabled), ...
    'claimDenseRetryFrames',retryPolicy.denseRetryFrames, ...
    'claimMaxBackoffFrames',retryPolicy.maxBackoffFrames, ...
    'claimRetryAttemptLimit',retryPolicy.attemptLimit, ...
    'claimOpportunityCount',retryPolicy.opportunityCount, ...
    'claimScheduleHashExact',retryPolicy.scheduleHashExact, ...
    'retryBudgetExhausted',double(retryBudgetExhausted), ...
    'claimBytes',claimBytes,'lockProofBytes',proofBytes, ...
    'responseBytes',responseBytes,'revokeBytes',revokeBytes, ...
    'controlAttempts',controlAttempts,'controlBytes',controlBytes, ...
    'controlAirtimeSec',controlBytes*8/C.phyRateBps, ...
    'recipientAttempts',recipientAttempts, ...
    'recipientSuccess',recipientSuccess, ...
    'recipientErasure',recipientErasure, ...
    'recipientCollision',0,'controlAttemptBound',attemptBound, ...
    'controlByteBound',byteBound, ...
    'controlAttemptBoundRatio',controlAttempts/attemptBound, ...
    'controlByteBoundRatio',controlBytes/byteBound, ...
    'futureRandomReads',0,'receiverTruthReads',0, ...
    'debug',struct('active',debugActive,'suppressed',debugSuppressed, ...
    'slot',debugSlot,'claimTx',debugClaim,'lockProofTx',debugProof, ...
    'responseTx',debugResponse,'receipt',debugReceipt, ...
    'revokeTx',debugRevoke,'claimOpportunity',claimOpportunity, ...
    'responseEntries',debugResponseEntries, ...
    'responseBytes',debugResponseBytes, ...
    'collision',debugCollision,'reacquired',debugReacquired));
O.stateHashExact=realizationHash([double(debugActive(:)); ...
    double(debugSuppressed(:));debugSlot(:);double(debugReceipt(:)); ...
    double(debugRevoke(:));debugResponseEntries(:);debugResponseBytes(:); ...
    double(claimOpportunity);retryPolicy.scheduleHashExact; ...
    version;claimSeq;controlAttempts;controlBytes]);

end


function A=controlAttempt(sender,draw,reach,erasureProbability)

receivers=find(reach(:,sender));
success=false(size(reach,1),1);
if ~isempty(receivers)
    success(receivers)=draw(receivers,sender)>erasureProbability;
end
A=struct('recipientAttempts',numel(receivers), ...
    'recipientSuccess',nnz(success), ...
    'recipientErasure',numel(receivers)-nnz(success),'success',success);

end


function [attempts,success,erasure]=accumulate(attempts,success,erasure,A)

attempts=attempts+A.recipientAttempts;
success=success+A.recipientSuccess;
erasure=erasure+A.recipientErasure;

end


function p=probability(C,name)

p=0;
if isfield(C,name), p=C.(name); end
if ~isscalar(p) || ~isfinite(p) || p<0 || p>1
    error('simulateLocalUnionGraphMigration: invalid %s.',name);
end

end


function validateInputs(M,C,T)

requiredM={'N','transitionNode','oldGraph','newGraph','unionGraph', ...
    'oldSlot','newSlot','incidentNodes','incidentWitness', ...
    'managementReach','config','admissible','hashExact'};
for k=1:numel(requiredM)
    if ~isfield(M,requiredM{k})
        error('simulateLocalUnionGraphMigration: missing M.%s.',requiredM{k});
    end
end
requiredConfig={'maxFrames','transitionFrame','eligibleFrame', ...
    'newGraphActivationFrame','lockProofRepeatFrames','phyRateBps'};
for k=1:numel(requiredConfig)
    if ~isfield(C,requiredConfig{k}) || ~isscalar(C.(requiredConfig{k})) || ...
            ~isfinite(C.(requiredConfig{k})) || C.(requiredConfig{k})<=0
        error('simulateLocalUnionGraphMigration: invalid C.%s.', ...
            requiredConfig{k});
    end
end
if C.lockProofRepeatFrames~=floor(C.lockProofRepeatFrames)
    error('simulateLocalUnionGraphMigration: lockProofRepeatFrames integer required.');
end
N=M.N; F=C.maxFrames;
arrays={'claimDeliveryU','lockProofDeliveryU','responseDeliveryU', ...
    'revokeDeliveryU','actualGraph'};
for k=1:numel(arrays)
    if ~isfield(T,arrays{k}) || ~isequal(size(T.(arrays{k})),[F N N])
        error('simulateLocalUnionGraphMigration: invalid T.%s.',arrays{k});
    end
end
if ~isfield(T,'selfRevoke') || ~isequal(size(T.selfRevoke),[F N]) || ...
        ~isfield(T,'responseVersion') || ...
        ~isequal(size(T.responseVersion),[F N]) || ...
        ~isfield(T,'responseClaimSeq') || ...
        ~isequal(size(T.responseClaimSeq),[F N]) || ...
        ~isfield(T,'hashExact')
    error('simulateLocalUnionGraphMigration: invalid trace metadata.');
end
if C.transitionFrame>C.eligibleFrame || ...
        C.transitionFrame>C.newGraphActivationFrame || ...
        max([C.eligibleFrame C.newGraphActivationFrame])>F
    error('simulateLocalUnionGraphMigration: invalid transition ordering.');
end

end
