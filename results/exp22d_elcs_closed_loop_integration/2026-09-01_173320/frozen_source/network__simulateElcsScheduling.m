function out=simulateElcsScheduling(cfg,trace)
%SIMULATEELCSSCHEDULING Isolated ELCS-F edge-lease scheduling kernel.

C=validateConfig(cfg);
T=validateTrace(trace,C);
N=C.N;
F=C.maxFrames;
epoch=1;

slot=zeros(N,1);
ready=false(N,1);
slot(1)=1;
ready(1)=true;
knownLowerSlot=zeros(N,N);
lastStatusSlot=zeros(N,N);
grantExpiry=zeros(N,N);
grantOwnerSlot=zeros(N,N);
grantClientSlot=zeros(N,N);
grantVersion=zeros(N,N);
ownerLockExpiry=zeros(N,N);
ownerLockedSlot=zeros(N,N);
ownerVersion=zeros(N,N);

firstAllCertifiedFrame=NaN;
recoveryFrame=NaN;
falseValidEdgeFrames=0;
scheduledCollisionFrames=0;
fallbackCollisionFrames=0;
scheduledAttempts=0;
fallbackAttempts=0;
scheduledRecipientAttempts=0;
scheduledRecipientSuccess=0;
scheduledRecipientErasure=0;
scheduledRecipientCollision=0;
fallbackRecipientAttempts=0;
fallbackRecipientSuccess=0;
fallbackRecipientErasure=0;
fallbackRecipientCollision=0;
statusAttempts=0;
grantFrameAttempts=0;
grantEntriesAttempted=0;
statusBusySlots=0;
grantBusySlots=0;
scheduledBusySlots=0;
fallbackBusySlots=0;
managementRecipientAttempts=0;
managementRecipientSuccess=0;
managementRecipientErasure=0;
managementRecipientCollision=0;
ownerLockViolations=0;
staleGrantAccepts=0;
futureGrantAccepts=0;
tupleChangePending=false(N,1);
tupleChangeReleaseFence=-inf(N,1);
tupleDesiredSlot=zeros(N,1);
reconfigurationAppliedFrame=NaN;
reconfigurationReleaseFence=NaN;
automaticRecolorCount=0;

debugReady=false(F,N);
debugActive=false(F,N);
debugSlot=zeros(F,N);
debugStatusTx=false(F,N);
debugGrantTx=false(F,N);
debugScheduledTx=false(F,N);
debugFallbackTx=false(F,C.fallbackSlots,N);
debugGrantExpiry=zeros(F,N,N);
debugStatusChoice=zeros(F,N);
debugGrantChoice=zeros(F,N);
debugStatusSuccess=false(F,N,N);
debugStatusErasure=false(F,N,N);
debugStatusCollision=false(F,N,N);
debugGrantSuccess=false(F,N,N);
debugGrantErasure=false(F,N,N);
debugGrantCollision=false(F,N,N);
debugScheduledSuccess=false(F,N,N);
debugScheduledErasure=false(F,N,N);
debugScheduledCollision=false(F,N,N);
debugFallbackSuccess=false(F,C.fallbackSlots,N,N);
debugFallbackErasure=false(F,C.fallbackSlots,N,N);
debugFallbackCollision=false(F,C.fallbackSlots,N,N);

for frame=1:F
    if C.reconfigurationEnabled && frame==C.reconfigurationFrame
        node=C.reconfigurationNode;
        tupleChangePending(node)=true;
        tupleDesiredSlot(node)=C.reconfigurationSlot;
        tupleChangeReleaseFence(node)=max([ ...
            frame+C.leaseFrames+C.leaseFenceFrames; ...
            ownerLockExpiry(node,:)'; ...
            grantExpiry(node,:)'+C.leaseFenceFrames]);
        reconfigurationReleaseFence=tupleChangeReleaseFence(node);
    end
    applyNodes=find(tupleChangePending & frame>tupleChangeReleaseFence);
    for node=reshape(applyNodes,1,[])
        lower=find(C.conflictGraph(node,:) & (1:N)<node);
        desired=tupleDesiredSlot(node);
        if desired==0
            unavailable=unique(knownLowerSlot(node,lower));
            desired=1;
            while any(unavailable==desired), desired=desired+1; end
        end
        if desired>C.frameLength || ...
                any(knownLowerSlot(node,lower)==desired)
            error(['simulateElcsScheduling: requested reconfiguration slot ' ...
                'conflicts with a lower-ID neighbor.']);
        end
        slot(node)=desired;
        ready(node)=true;
        grantExpiry(node,:)=0;
        grantOwnerSlot(node,:)=0;
        grantClientSlot(node,:)=0;
        grantVersion(node,:)=0;
        if node==C.reconfigurationNode && C.reconfigurationEnabled
            reconfigurationAppliedFrame=frame;
        else
            automaticRecolorCount=automaticRecolorCount+1;
        end
        tupleChangePending(node)=false;
        tupleDesiredSlot(node)=0;
    end

    % A complete local state loss erases only the selected client's evidence.
    if C.stateLossEnabled && frame==C.stateLossFrame
        node=C.stateLossNode;
        if any(ownerLockExpiry(node,:)>frame)
            % Locks owned by the failed node are nonvolatile protocol
            % obligations in this mechanism model.  Client evidence and
            % coloring state are the state reconstructed on rejoin.
        end
        ready(node)=false;
        slot(node)=0;
        knownLowerSlot(node,:)=0;
        grantExpiry(node,:)=0;
        grantOwnerSlot(node,:)=0;
        grantClientSlot(node,:)=0;
        grantVersion(node,:)=0;
    end

    refreshNeeded=false(N,1);
    for node=1:N
        lower=find(C.conflictGraph(node,:) & (1:N)<node);
        if ready(node) && ~isempty(lower)
            refreshNeeded(node)=any(grantExpiry(node,lower)-frame<= ...
                C.refreshLeadFrames+C.leaseFenceFrames);
        end
    end
    periodic=mod(frame-1,C.statusPeriodFrames)==0;
    statusTx=ready & (periodic | refreshNeeded);
    statusTx(tupleChangePending)=false;
    if C.deterministicControlSlots
        statusChoice=(1:N)';
    else
        statusChoice=1+floor(T.statusSlotU(frame,:)'*C.controlSlots);
        statusChoice=min(statusChoice,C.controlSlots);
    end
    Astatus=phaseDelivery(find(statusTx),statusChoice, ...
        C.managementReach,C.interferenceMatrix, ...
        squeeze(T.statusDeliveryU(frame,:,:)), ...
        C.managementErasureProbability);
    statusAttempts=statusAttempts+Astatus.attempts;
    statusBusySlots=statusBusySlots+Astatus.busySlots;
    managementRecipientAttempts=managementRecipientAttempts+ ...
        Astatus.recipientAttempts;
    managementRecipientSuccess=managementRecipientSuccess+ ...
        Astatus.recipientSuccess;
    managementRecipientErasure=managementRecipientErasure+ ...
        Astatus.recipientErasure;
    managementRecipientCollision=managementRecipientCollision+ ...
        Astatus.recipientCollision;
    debugStatusSuccess(frame,:,:)=Astatus.successMask;
    debugStatusErasure(frame,:,:)=Astatus.erasureMask;
    debugStatusCollision(frame,:,:)=Astatus.collisionMask;

    % Decoded lower STATUS supplies coloring input.  It is not sufficient
    % for activation; only a later owner GRANT can create client validity.
    for receiver=1:N
        senders=find(Astatus.successMask(receiver,:));
        for sender=reshape(senders,1,[])
            lastStatusSlot(receiver,sender)=slot(sender);
            if C.conflictGraph(receiver,sender) && sender<receiver
                previous=knownLowerSlot(receiver,sender);
                knownLowerSlot(receiver,sender)=lastStatusSlot(receiver,sender);
                if previous>0 && previous~=knownLowerSlot(receiver,sender)
                    grantExpiry(receiver,sender)=0;
                    grantOwnerSlot(receiver,sender)=0;
                    grantClientSlot(receiver,sender)=0;
                    if ready(receiver) && ...
                            slot(receiver)==knownLowerSlot(receiver,sender) && ...
                            ~tupleChangePending(receiver)
                        tupleChangePending(receiver)=true;
                        tupleDesiredSlot(receiver)=0;
                        tupleChangeReleaseFence(receiver)=max([ ...
                            frame+C.leaseFrames+C.leaseFenceFrames; ...
                            ownerLockExpiry(receiver,:)'; ...
                            grantExpiry(receiver,:)'+C.leaseFenceFrames]);
                    end
                end
            end
        end
    end

    % Fixed-priority coloring.  A failed node reconstructs the same tuple.
    for node=2:N
        if ready(node), continue; end
        lower=find(C.conflictGraph(node,:) & (1:N)<node);
        if isempty(lower) || all(knownLowerSlot(node,lower)>0)
            unavailable=unique(knownLowerSlot(node,lower));
            candidate=1;
            while any(unavailable==candidate), candidate=candidate+1; end
            if candidate>C.frameLength
                error('simulateElcsScheduling: fixed frame cannot be colored.');
            end
            slot(node)=candidate;
            ready(node)=true;
        end
    end

    % Every owner that decodes a ready higher-ID STATUS may issue a matching
    % aggregated GRANT.  Attempting it creates the owner lock even if the
    % client does not decode the frame.
    pending=false(N,N); % owner, client
    for owner=1:N
        if tupleChangePending(owner)
            continue;
        end
        clients=find(Astatus.successMask(owner,:) & ...
            C.conflictGraph(owner,:) & (1:N)>owner);
        for client=reshape(clients,1,[])
            clientClaim=lastStatusSlot(owner,client);
            if slot(owner)>0 && clientClaim>0 && slot(owner)~=clientClaim
                pending(owner,client)=true;
            end
        end
    end
    grantTx=any(pending,2);
    if C.deterministicControlSlots
        grantChoice=(1:N)';
    else
        grantChoice=1+floor(T.grantSlotU(frame,:)'*C.controlSlots);
        grantChoice=min(grantChoice,C.controlSlots);
    end
    Agrant=phaseDelivery(find(grantTx),grantChoice, ...
        C.managementReach,C.interferenceMatrix, ...
        squeeze(T.grantDeliveryU(frame,:,:)), ...
        C.managementErasureProbability);
    grantFrameAttempts=grantFrameAttempts+Agrant.attempts;
    grantBusySlots=grantBusySlots+Agrant.busySlots;

    for owner=find(grantTx)'
        clients=find(pending(owner,:));
        for client=reshape(clients,1,[])
            nextVersion=ownerVersion(owner,client)+1;
            expiry=frame+C.leaseFrames;
            if ownerVersion(owner,client)>0 && ...
                    slot(owner)~=ownerLockedSlot(owner,client) && ...
                    frame<=ownerLockExpiry(owner,client)
                ownerLockViolations=ownerLockViolations+1;
                continue;
            end
            ownerVersion(owner,client)=nextVersion;
            ownerLockedSlot(owner,client)=slot(owner);
            ownerLockExpiry(owner,client)=max( ...
                ownerLockExpiry(owner,client), ...
                expiry+C.leaseFenceFrames);
            grantEntriesAttempted=grantEntriesAttempted+1;
            if ~Agrant.successMask(client,owner), continue; end
            state=clientState(client,epoch,C.frameLength,slot(client), ...
                grantExpiry,grantOwnerSlot,grantClientSlot,grantVersion);
            message=struct('owner',owner,'client',client,'epoch',epoch, ...
                'frameLength',C.frameLength,'ownerSlot',slot(owner), ...
                'clientSlot',lastStatusSlot(owner,client), ...
                'activationFrame',frame, ...
                'expiryFrame',expiry,'version',nextVersion);
            [accepted,state,reason]=elcsAcceptGrant( ...
                state,message,frame,C);
            if accepted
                grantExpiry(client,:)=state.grantExpiry;
                grantOwnerSlot(client,:)=state.grantOwnerSlot;
                grantClientSlot(client,:)=state.grantClientSlot;
                grantVersion(client,:)=state.lastGrantVersion;
            elseif strcmp(reason,'stale-epoch')
                staleGrantAccepts=staleGrantAccepts+1;
            elseif strcmp(reason,'future-epoch')
                futureGrantAccepts=futureGrantAccepts+1;
            end
        end
    end
    managementRecipientAttempts=managementRecipientAttempts+ ...
        Agrant.recipientAttempts;
    managementRecipientSuccess=managementRecipientSuccess+ ...
        Agrant.recipientSuccess;
    managementRecipientErasure=managementRecipientErasure+ ...
        Agrant.recipientErasure;
    managementRecipientCollision=managementRecipientCollision+ ...
        Agrant.recipientCollision;
    debugGrantSuccess(frame,:,:)=Agrant.successMask;
    debugGrantErasure(frame,:,:)=Agrant.erasureMask;
    debugGrantCollision(frame,:,:)=Agrant.collisionMask;

    active=false(N,1);
    for node=1:N
        if ~ready(node), continue; end
        lower=find(C.conflictGraph(node,:) & (1:N)<node);
        valid=true;
        for owner=reshape(lower,1,[])
            valid=valid && grantExpiry(node,owner)-frame> ...
                C.leaseFenceFrames && ...
                grantOwnerSlot(node,owner)>0 && ...
                grantOwnerSlot(node,owner)~=grantClientSlot(node,owner) && ...
                grantClientSlot(node,owner)==slot(node);
        end
        active(node)=valid;
    end

    % Runtime audit of the local validity predicate and edge orientation.
    falseEdge=0;
    for client=find(active)'
        lower=find(C.conflictGraph(client,:) & (1:N)<client);
        localInvalid=grantExpiry(client,lower)-frame<= ...
            C.leaseFenceFrames | ...
            grantOwnerSlot(client,lower)<=0 | ...
            grantOwnerSlot(client,lower)==grantClientSlot(client,lower) | ...
            grantClientSlot(client,lower)~=slot(client);
        activeOwnerMismatch=reshape(active(lower),1,[]) & ...
            grantOwnerSlot(client,lower)~=reshape(slot(lower),1,[]);
        falseEdge=falseEdge+nnz(localInvalid | activeOwnerMismatch);
    end
    falseValidEdgeFrames=falseValidEdgeFrames+falseEdge;

    % Certified scheduled region.
    for dataSlot=1:C.frameLength
        tx=find(active & slot==dataSlot);
        if isempty(tx), continue; end
        scheduledBusySlots=scheduledBusySlots+1;
        scheduledAttempts=scheduledAttempts+numel(tx);
        A=dataDelivery(tx,C.neighborGraph,C.interferenceMatrix, ...
            squeeze(T.scheduledDeliveryU(frame,:,:)), ...
            C.dataErasureProbability);
        scheduledRecipientAttempts=scheduledRecipientAttempts+ ...
            A.recipientAttempts;
        scheduledRecipientSuccess=scheduledRecipientSuccess+A.recipientSuccess;
        scheduledRecipientErasure=scheduledRecipientErasure+A.recipientErasure;
        scheduledRecipientCollision=scheduledRecipientCollision+ ...
            A.recipientCollision;
        debugScheduledSuccess(frame,:,:)=reshape( ...
            squeeze(debugScheduledSuccess(frame,:,:)) | A.successMask,N,N);
        debugScheduledErasure(frame,:,:)=reshape( ...
            squeeze(debugScheduledErasure(frame,:,:)) | A.erasureMask,N,N);
        debugScheduledCollision(frame,:,:)=reshape( ...
            squeeze(debugScheduledCollision(frame,:,:)) | A.collisionMask,N,N);
        scheduledCollisionFrames=scheduledCollisionFrames+ ...
            nnz(any(A.collisionMask,1));
    end

    % Invalid nodes use only the disjoint fallback region.
    invalid=~active;
    for fallbackSlot=1:C.fallbackSlots
        tx=find(invalid & squeeze( ...
            T.fallbackAccessU(frame,fallbackSlot,:))<= ...
            C.fallbackAccessProbability);
        debugFallbackTx(frame,fallbackSlot,tx)=true;
        if isempty(tx), continue; end
        fallbackBusySlots=fallbackBusySlots+1;
        fallbackAttempts=fallbackAttempts+numel(tx);
        A=dataDelivery(tx,C.neighborGraph,C.interferenceMatrix, ...
            squeeze(T.fallbackDeliveryU(frame,fallbackSlot,:,:)), ...
            C.dataErasureProbability);
        fallbackRecipientAttempts=fallbackRecipientAttempts+A.recipientAttempts;
        fallbackRecipientSuccess=fallbackRecipientSuccess+A.recipientSuccess;
        fallbackRecipientErasure=fallbackRecipientErasure+A.recipientErasure;
        fallbackRecipientCollision=fallbackRecipientCollision+ ...
            A.recipientCollision;
        debugFallbackSuccess(frame,fallbackSlot,:,:)=A.successMask;
        debugFallbackErasure(frame,fallbackSlot,:,:)=A.erasureMask;
        debugFallbackCollision(frame,fallbackSlot,:,:)=A.collisionMask;
        fallbackCollisionFrames=fallbackCollisionFrames+ ...
            nnz(any(A.collisionMask,1));
    end

    if all(active) && isnan(firstAllCertifiedFrame)
        firstAllCertifiedFrame=frame;
    end
    if C.stateLossEnabled && frame>=C.stateLossFrame && ...
            active(C.stateLossNode) && isnan(recoveryFrame)
        recoveryFrame=frame-C.stateLossFrame;
    end
    debugReady(frame,:)=ready;
    debugActive(frame,:)=active;
    debugSlot(frame,:)=slot;
    debugStatusTx(frame,:)=statusTx;
    debugGrantTx(frame,:)=grantTx;
    debugStatusChoice(frame,:)=statusChoice;
    debugGrantChoice(frame,:)=grantChoice;
    debugScheduledTx(frame,:)=active;
    debugGrantExpiry(frame,:,:)=grantExpiry;
end

controlAttempts=statusAttempts+grantFrameAttempts;
dataAttempts=scheduledAttempts+fallbackAttempts;
frameAirtime=8*C.dataBytes/C.phyRateBps;
controlAirtime=8*C.controlBytes/C.phyRateBps;
frameDuration=2*C.controlSlots*controlAirtime+ ...
    (C.fallbackSlots+C.frameLength)*frameAirtime+ ...
    (2*C.controlSlots+C.fallbackSlots+C.frameLength)*C.guardSec;
out=struct();
out.version='ELCS-F-KERNEL-v1';
out.N=N;
out.maxFrames=F;
out.frameLength=C.frameLength;
out.slot=slot;
out.ready=ready;
out.active=debugActive(end,:)';
out.firstAllCertifiedFrame=firstAllCertifiedFrame;
out.recoveryFrame=recoveryFrame;
out.finalAllCertified=all(out.active);
out.certifiedNodeFrameFraction=nnz(debugActive)/(F*N);
out.finalScheduledCollisionFree=scheduledCollisionFrames==0;
out.falseValidEdgeFrames=falseValidEdgeFrames;
out.ownerLockViolations=ownerLockViolations;
out.staleGrantAccepts=staleGrantAccepts;
out.futureGrantAccepts=futureGrantAccepts;
out.reconfigurationAppliedFrame=reconfigurationAppliedFrame;
out.reconfigurationReleaseFence=reconfigurationReleaseFence;
out.automaticRecolorCount=automaticRecolorCount;
out.statusAttempts=statusAttempts;
out.grantAttempts=grantFrameAttempts;
out.grantEntriesAttempted=grantEntriesAttempted;
out.controlAttempts=controlAttempts;
out.managementRecipientAttempts=managementRecipientAttempts;
out.managementRecipientSuccess=managementRecipientSuccess;
out.managementRecipientErasure=managementRecipientErasure;
out.managementRecipientCollision=managementRecipientCollision;
out.scheduledAttempts=scheduledAttempts;
out.fallbackAttempts=fallbackAttempts;
out.dataAttempts=dataAttempts;
out.scheduledRecipientAttempts=scheduledRecipientAttempts;
out.scheduledRecipientSuccess=scheduledRecipientSuccess;
out.scheduledRecipientErasure=scheduledRecipientErasure;
out.scheduledRecipientCollision=scheduledRecipientCollision;
out.fallbackRecipientAttempts=fallbackRecipientAttempts;
out.fallbackRecipientSuccess=fallbackRecipientSuccess;
out.fallbackRecipientErasure=fallbackRecipientErasure;
out.fallbackRecipientCollision=fallbackRecipientCollision;
out.scheduledCollisionFrames=scheduledCollisionFrames;
out.fallbackCollisionFrames=fallbackCollisionFrames;
out.ownerLockExpiry=ownerLockExpiry;
out.ownerLockedSlot=ownerLockedSlot;
out.grantExpiry=grantExpiry;
out.frameDurationSec=frameDuration;
out.elapsedSec=F*frameDuration;
out.offeredAirtimeSec=controlAttempts*controlAirtime+ ...
    dataAttempts*frameAirtime;
out.offeredUtilization=out.offeredAirtimeSec/out.elapsedSec;
out.busyAirtimeSec=(statusBusySlots+grantBusySlots)*controlAirtime+ ...
    (scheduledBusySlots+fallbackBusySlots)*frameAirtime;
out.channelUtilization=out.busyAirtimeSec/out.elapsedSec;
out.accountingCloses=managementRecipientAttempts== ...
    managementRecipientSuccess+managementRecipientErasure+ ...
    managementRecipientCollision && ...
    scheduledRecipientAttempts==scheduledRecipientSuccess+ ...
    scheduledRecipientErasure+scheduledRecipientCollision && ...
    fallbackRecipientAttempts==fallbackRecipientSuccess+ ...
    fallbackRecipientErasure+fallbackRecipientCollision;
out.futureRandomReads=0;
out.receiverTruthDecisionReads=0;
out.traceHash=T.hashExact;
out.configHash=realizationHash(configVector(C));
out.realizationHash=realizationHash([slot;ready;out.active; ...
    firstAllCertifiedFrame;falseValidEdgeFrames;ownerLockViolations; ...
    controlAttempts;grantEntriesAttempted;dataAttempts; ...
    scheduledCollisionFrames; ...
    fallbackCollisionFrames;grantExpiry(:);ownerLockExpiry(:)]);
out.scheduleStateHash=realizationHash([double(debugReady(:)); ...
    double(debugActive(:));debugSlot(:);grantExpiry(:); ...
    ownerLockExpiry(:);ownerLockedSlot(:)]);
out.debug=struct('ready',debugReady,'active',debugActive, ...
    'slot',debugSlot,'statusTx',debugStatusTx,'grantTx',debugGrantTx, ...
    'scheduledTx',debugScheduledTx,'fallbackTx',debugFallbackTx, ...
    'grantExpiry',debugGrantExpiry, ...
    'statusChoice',debugStatusChoice,'grantChoice',debugGrantChoice, ...
    'statusSuccess',debugStatusSuccess, ...
    'statusErasure',debugStatusErasure, ...
    'statusCollision',debugStatusCollision, ...
    'grantSuccess',debugGrantSuccess, ...
    'grantErasure',debugGrantErasure, ...
    'grantCollision',debugGrantCollision, ...
    'scheduledSuccess',debugScheduledSuccess, ...
    'scheduledErasure',debugScheduledErasure, ...
    'scheduledCollision',debugScheduledCollision, ...
    'fallbackSuccess',debugFallbackSuccess, ...
    'fallbackErasure',debugFallbackErasure, ...
    'fallbackCollision',debugFallbackCollision);

end


function state=clientState(node,epoch,L,slot,expiry,ownerSlot,clientSlot,v)

state=struct('node',node,'epoch',epoch,'frameLength',L, ...
    'slot',slot,'grantExpiry',expiry(node,:), ...
    'grantOwnerSlot',ownerSlot(node,:), ...
    'grantClientSlot',clientSlot(node,:), ...
    'lastGrantVersion',v(node,:));

end


function A=phaseDelivery(tx,choice,reach,interference,draws,pLoss)

N=size(reach,1);
A=emptyOutcome(N);
for minislot=1:max([0;choice(tx)])
    senders=tx(choice(tx)==minislot);
    if isempty(senders), continue; end
    B=dataDelivery(senders,reach,interference,draws,pLoss);
    A=mergeOutcome(A,B);
end
A.attempts=numel(tx);

end


function A=dataDelivery(tx,reach,interference,draws,pLoss)

N=size(reach,1);
A=emptyOutcome(N);
if isempty(tx), return; end
tx=reshape(tx,1,[]);
txMask=false(N,1); txMask(tx)=true;
for sender=tx
    A.recipientAttempts=A.recipientAttempts+nnz(reach(:,sender) & ~txMask);
end
for receiver=1:N
    if txMask(receiver), continue; end
    intended=tx(reach(receiver,tx));
    detectable=tx(interference(receiver,tx) | reach(receiver,tx));
    if isempty(detectable), continue; end
    if isscalar(intended)
        sender=intended(1);
        other=detectable(detectable~=sender);
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

A=struct('attempts',0,'busySlots',0, ...
    'recipientAttempts',0,'recipientSuccess',0, ...
    'recipientErasure',0,'recipientCollision',0, ...
    'successMask',false(N),'erasureMask',false(N), ...
    'collisionMask',false(N));

end


function A=mergeOutcome(A,B)

A.recipientAttempts=A.recipientAttempts+B.recipientAttempts;
A.busySlots=A.busySlots+1;
A.recipientSuccess=A.recipientSuccess+B.recipientSuccess;
A.recipientErasure=A.recipientErasure+B.recipientErasure;
A.recipientCollision=A.recipientCollision+B.recipientCollision;
A.successMask=A.successMask | B.successMask;
A.erasureMask=A.erasureMask | B.erasureMask;
A.collisionMask=A.collisionMask | B.collisionMask;

end


function C=validateConfig(C)

required={'N','maxFrames','frameLength','controlSlots','fallbackSlots', ...
    'leaseFrames','refreshLeadFrames','leaseFenceFrames', ...
    'statusPeriodFrames','fallbackAccessProbability','dataBytes', ...
    'deterministicControlSlots', ...
    'controlBytes','phyRateBps','guardSec','dataErasureProbability', ...
    'managementErasureProbability','neighborGraph','managementReach', ...
    'interferenceMatrix','conflictGraph','stateLossEnabled', ...
    'stateLossFrame','stateLossNode','reconfigurationEnabled', ...
    'reconfigurationFrame','reconfigurationNode','reconfigurationSlot'};
if ~isstruct(C) || ~isscalar(C) || ~all(isfield(C,required))
    error('simulateElcsScheduling: incomplete configuration.');
end
ints={'N','maxFrames','frameLength','controlSlots','fallbackSlots', ...
    'leaseFrames','refreshLeadFrames','leaseFenceFrames', ...
    'statusPeriodFrames','stateLossFrame','stateLossNode', ...
    'reconfigurationFrame','reconfigurationNode','reconfigurationSlot'};
for k=1:numel(ints)
    x=C.(ints{k});
    if ~isscalar(x) || ~isfinite(x) || x<1 || x~=floor(x)
        error('simulateElcsScheduling: %s must be positive integer.',ints{k});
    end
end
if C.frameLength<C.N || C.refreshLeadFrames+C.leaseFenceFrames>= ...
        C.leaseFrames
    error('simulateElcsScheduling: invalid frame/lease dimensions.');
end
if ~isscalar(C.deterministicControlSlots) || ...
        ~ismember(C.deterministicControlSlots,[0 1]) || ...
        (C.deterministicControlSlots && C.controlSlots<C.N)
    error('simulateElcsScheduling: invalid deterministic control map.');
end
C.deterministicControlSlots=logical(C.deterministicControlSlots);
prob={'fallbackAccessProbability','dataErasureProbability', ...
    'managementErasureProbability'};
for k=1:numel(prob)
    x=C.(prob{k});
    if ~isscalar(x) || ~isfinite(x) || x<0 || x>1
        error('simulateElcsScheduling: invalid probability %s.',prob{k});
    end
end
positive={'dataBytes','controlBytes','phyRateBps'};
for k=1:numel(positive)
    x=C.(positive{k});
    if ~isscalar(x) || ~isfinite(x) || x<=0
        error('simulateElcsScheduling: %s must be positive.',positive{k});
    end
end
if ~isscalar(C.guardSec) || ~isfinite(C.guardSec) || C.guardSec<0
    error('simulateElcsScheduling: guardSec must be nonnegative.');
end
matrices={'neighborGraph','managementReach','interferenceMatrix', ...
    'conflictGraph'};
for k=1:numel(matrices)
    x=C.(matrices{k});
    if ~isequal(size(x),[C.N C.N]) || any(~isfinite(x(:))) || ...
            any(x(:)~=0 & x(:)~=1)
        error('simulateElcsScheduling: invalid %s.',matrices{k});
    end
    C.(matrices{k})=logical(x);
end
C.neighborGraph(1:C.N+1:end)=false;
C.managementReach(1:C.N+1:end)=false;
C.interferenceMatrix(1:C.N+1:end)=false;
C.conflictGraph(1:C.N+1:end)=false;
if ~isequal(C.conflictGraph,C.conflictGraph')
    error('simulateElcsScheduling: conflictGraph must be symmetric.');
end
physicalConflict=buildSenderConflictGraph( ...
    C.neighborGraph,C.interferenceMatrix);
if any(physicalConflict(:) & ~C.conflictGraph(:))
    error(['simulateElcsScheduling: conflict envelope omits a physical ' ...
        'sender-conflict edge.']);
end
if ~isscalar(C.stateLossEnabled) || ...
        ~ismember(C.stateLossEnabled,[0 1]) || C.stateLossNode>C.N
    error('simulateElcsScheduling: invalid state-loss declaration.');
end
C.stateLossEnabled=logical(C.stateLossEnabled);
if ~isscalar(C.reconfigurationEnabled) || ...
        ~ismember(C.reconfigurationEnabled,[0 1]) || ...
        C.reconfigurationNode>C.N || C.reconfigurationSlot>C.frameLength
    error('simulateElcsScheduling: invalid reconfiguration declaration.');
end
C.reconfigurationEnabled=logical(C.reconfigurationEnabled);

end


function T=validateTrace(T,C)

sizes=struct('statusSlotU',[C.maxFrames C.N], ...
    'grantSlotU',[C.maxFrames C.N], ...
    'statusDeliveryU',[C.maxFrames C.N C.N], ...
    'grantDeliveryU',[C.maxFrames C.N C.N], ...
    'scheduledDeliveryU',[C.maxFrames C.N C.N], ...
    'fallbackAccessU',[C.maxFrames C.fallbackSlots C.N], ...
    'fallbackDeliveryU',[C.maxFrames C.fallbackSlots C.N C.N]);
names=fieldnames(sizes);
for k=1:numel(names)
    name=names{k};
    expected=sizes.(name);
    if ~isfield(T,name)
        error('simulateElcsScheduling: missing trace field %s.',name);
    end
    x=T.(name);
    if ~isequal(size(x),expected) || any(~isfinite(x(:))) || ...
            any(x(:)<0) || any(x(:)>1)
        error('simulateElcsScheduling: invalid trace field %s.',name);
    end
end
if ~isfield(T,'hashExact')
    T.hashExact=realizationHash([T.statusSlotU(:);T.grantSlotU(:); ...
        T.statusDeliveryU(:);T.grantDeliveryU(:); ...
        T.scheduledDeliveryU(:);T.fallbackAccessU(:); ...
        T.fallbackDeliveryU(:)]);
end

end


function v=configVector(C)

v=[C.N;C.maxFrames;C.frameLength;C.controlSlots;C.fallbackSlots; ...
    C.leaseFrames;C.refreshLeadFrames;C.leaseFenceFrames; ...
    C.statusPeriodFrames;C.fallbackAccessProbability;C.dataBytes; ...
    double(C.deterministicControlSlots); ...
    C.controlBytes;C.phyRateBps;C.guardSec;C.dataErasureProbability; ...
    C.managementErasureProbability;double(C.neighborGraph(:)); ...
    double(C.managementReach(:));double(C.interferenceMatrix(:)); ...
    double(C.conflictGraph(:));double(C.stateLossEnabled); ...
    C.stateLossFrame;C.stateLossNode; ...
    double(C.reconfigurationEnabled);C.reconfigurationFrame; ...
    C.reconfigurationNode;C.reconfigurationSlot];

end
