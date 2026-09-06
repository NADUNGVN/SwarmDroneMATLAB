function O=simulateReceiverLiftedClosureMigration(M,C,T)
%SIMULATERECEIVERLIFTEDCLOSUREMIGRATION Quiesce, move, certify, commit.
% v2 retains QUIESCENT advertising after a valid PREPARE until receipt.

validateInputs(M,C,T);
if receiverLiftedClosureTraceHash(T)~=T.hashExact
    error('simulateReceiverLiftedClosureMigration: trace hash mismatch.');
end
N=M.N; F=C.maxFrames; initiator=M.initiator;
reach=logical(M.managementReach); reach(1:N+1:end)=false;
affected=reshape(M.affectedNodes,[],1); S=numel(affected);
affectedMask=logical(M.affectedMask);
[prepareDue,preparePolicy]=prepareSchedule(C);

active=true(N,1); suppressed=false(N,1); slot=M.oldSlot;
prepared=false(N,1); quietReceipt=false(N,1);
barrierClosed=false; barrierFrame=NaN; activationFrame=NaN;
motionAuthorized=false; transactionVersion=C.transactionVersion;
claimDue=false(F,1); claimPolicy=emptyPolicy(); claimEligibleFrame=NaN;
endpointSeen=false(M.incidentUnionEdgeCount,2);
edgeReceipt=false(M.incidentUnionEdgeCount,1);
commitReady=false; commitReadyFrame=NaN; commitReceived=false(N,1);
prepareBudgetExhausted=false; commitBudgetExhausted=false;

kindNames={'prepare','quiet','claim','lockProof','response','commit','revoke'};
for k=1:numel(kindNames)
    attempts.(kindNames{k})=0; bytes.(kindNames{k})=0;
end
recipientAttempts=0; recipientSuccess=0; recipientErasure=0;
actualSubsetOld=true; actualSubsetUnion=true;
collisionFrames=0; collisionEdges=0; prematureActivationFrames=0;
debugActive=false(F,N); debugSuppressed=false(F,N); debugSlot=zeros(F,N);
debugPrepare=false(F,1); debugQuiet=false(F,N); debugClaim=false(F,N);
debugProof=false(F,N); debugResponse=false(F,N); debugCommit=false(F,1);
debugRevoke=false(F,N); debugPrepared=false(F,N); debugQuietReceipt=false(F,N);
debugEdgeReceipt=false(F,M.incidentUnionEdgeCount);
debugBarrier=false(F,1); debugAuthorized=false(F,1); debugCollision=false(F,1);
debugResponseBytes=zeros(F,N); debugActualGraph=false(F,N,N);

for frame=1:F
    if frame==C.prepareFrame
        suppressNode(initiator,frame);
        prepared(initiator)=true; quietReceipt(initiator)=true;
    end

    if ~barrierClosed && prepareDue(frame)
        debugPrepare(frame)=true;
        sendControl(initiator,'prepare',M.prepareBytes, ...
            squeeze(T.prepareDeliveryU(frame,:,:)), ...
            probability(C,'prepareErasureProbability'));
        metadataOk=T.prepareVersion(frame)==transactionVersion && ...
            T.prepareDigest(frame)==M.hashExact;
        if metadataOk
            deliveredMask=deliveryVector(initiator, ...
                squeeze(T.prepareDeliveryU(frame,:,:)), ...
                probability(C,'prepareErasureProbability'));
            for node=reshape(affected,1,[])
                if node==initiator || deliveredMask(node)
                    if ~prepared(node)
                        prepared(node)=true; suppressNode(node,frame);
                    end
                end
            end
        end
        for node=reshape(affected(affected~=initiator),1,[])
            % PREPARE is a persistent local state. Once a node has entered
            % the quiescent closure, it keeps advertising that fact on every
            % remaining PREPARE retry opportunity until the initiator has a
            % positive receipt. It need not re-receive PREPARE in that frame.
            if ~prepared(node)||quietReceipt(node), continue; end
            debugQuiet(frame,node)=true;
            sendControl(node,'quiet',M.config.quietBytes, ...
                squeeze(T.quietDeliveryU(frame,:,:)), ...
                probability(C,'quietErasureProbability'));
            delivered=deliveryTo(node,initiator, ...
                squeeze(T.quietDeliveryU(frame,:,:)), ...
                probability(C,'quietErasureProbability'));
            metadataOk=T.quietVersion(frame,node)==transactionVersion && ...
                T.quietDigest(frame,node)==M.hashExact;
            if delivered && metadataOk, quietReceipt(node)=true; end
        end
        if all(quietReceipt(affected))
            barrierClosed=true; barrierFrame=frame;
            activationFrame=min(F+1,frame+1); motionAuthorized=true;
            claimEligibleFrame=activationFrame+C.claimEligibilityDelayFrames;
            if claimEligibleFrame<=F
                claimConfig=C; claimConfig.eligibleFrame=claimEligibleFrame;
                [claimDue,claimPolicy]=localUnionMigrationClaimSchedule( ...
                    claimConfig);
            end
        end
    end
    if ~barrierClosed && frame>=preparePolicy.lastOpportunityFrame && ...
            attempts.prepare==preparePolicy.opportunityCount
        prepareBudgetExhausted=true;
    end

    graphActivated=barrierClosed && frame>=activationFrame;
    if graphActivated
        actual=logical(squeeze(T.actualGraphAfter(frame,:,:)));
        actualSubsetUnion=actualSubsetUnion&& ...
            ~any(triu(actual&~M.unionGraph,1),'all');
    else
        actual=M.oldGraph;
        actualSubsetOld=actualSubsetOld&& ...
            ~any(triu(actual&~M.oldGraph,1),'all');
    end
    if ~barrierClosed && ~isequal(actual,M.oldGraph)
        prematureActivationFrames=prematureActivationFrames+1;
    end

    if graphActivated && frame>=claimEligibleFrame && claimDue(frame) && ...
            ~commitReady
        for node=reshape(affected,1,[])
            debugClaim(frame,node)=true;
            sendControl(node,'claim',M.config.claimBytes, ...
                squeeze(T.claimDeliveryU(frame,:,:)), ...
                probability(C,'claimErasureProbability'));
            metadataOk=T.claimVersion(frame,node)==transactionVersion && ...
                T.claimDigest(frame,node)==M.hashExact;
            if ~metadataOk, continue; end
            deliveredMask=deliveryVector(node,squeeze(T.claimDeliveryU(frame,:,:)), ...
                probability(C,'claimErasureProbability'));
            markEndpointSeen(node,deliveredMask);
        end
    end

    proofWindow=graphActivated && isfinite(claimEligibleFrame) && ...
        frame>=claimEligibleFrame && ...
        frame<claimEligibleFrame+C.lockProofRepeatFrames;
    if proofWindow
        outsideProof=unique([M.incidentEdgeA(~affectedMask(M.incidentEdgeA)); ...
            M.incidentEdgeB(~affectedMask(M.incidentEdgeB))]);
        for node=reshape(outsideProof,1,[])
            debugProof(frame,node)=true;
            sendControl(node,'lockProof',M.config.lockProofBytes, ...
                squeeze(T.lockProofDeliveryU(frame,:,:)), ...
                probability(C,'lockProofErasureProbability'));
            deliveredMask=deliveryVector(node, ...
                squeeze(T.lockProofDeliveryU(frame,:,:)), ...
                probability(C,'lockProofErasureProbability'));
            markEndpointSeen(node,deliveredMask);
        end
    end

    if graphActivated && isfinite(claimEligibleFrame) && claimDue(frame) && ...
            ~commitReady
        ready=all(endpointSeen,2)&~edgeReceipt;
        for w=reshape(unique(M.incidentEdgeWitness(ready)),1,[])
            entries=find(ready&M.incidentEdgeWitness==w);
            if isempty(entries), continue; end
            debugResponse(frame,w)=true;
            responseBytes=M.config.certificateHeaderBytes+ ...
                numel(entries)*M.config.certificateEntryBytes;
            debugResponseBytes(frame,w)=responseBytes;
            sendControl(w,'response',responseBytes, ...
                squeeze(T.responseDeliveryU(frame,:,:)), ...
                probability(C,'responseErasureProbability'));
            delivered=w==initiator || deliveryTo(w,initiator, ...
                squeeze(T.responseDeliveryU(frame,:,:)), ...
                probability(C,'responseErasureProbability'));
            metadataOk=T.responseVersion(frame,w)==transactionVersion&& ...
                T.responseDigest(frame,w)==M.hashExact;
            if delivered&&metadataOk, edgeReceipt(entries)=true; end
        end
        if all(edgeReceipt)
            commitReady=true; commitReadyFrame=frame;
        end
    end

    if commitReady && ~all(commitReceived(affected)) && ...
            attempts.commit<C.commitRetryAttemptLimit
        debugCommit(frame)=true;
        sendControl(initiator,'commit',M.config.commitBytes, ...
            squeeze(T.commitDeliveryU(frame,:,:)), ...
            probability(C,'commitErasureProbability'));
        metadataOk=T.commitVersion(frame)==transactionVersion && ...
            T.commitDigest(frame)==M.hashExact;
        if metadataOk
            deliveredMask=deliveryVector(initiator, ...
                squeeze(T.commitDeliveryU(frame,:,:)), ...
                probability(C,'commitErasureProbability'));
            commitReceived(initiator)=true;
            for node=reshape(affected(affected~=initiator),1,[])
                if deliveredMask(node), commitReceived(node)=true; end
            end
        end
        for node=reshape(affected(commitReceived(affected)),1,[])
            suppressed(node)=false; active(node)=true;
            slot(node)=M.candidateSlot(node);
        end
    end
    if commitReady && ~all(commitReceived(affected)) && ...
            attempts.commit>=C.commitRetryAttemptLimit
        commitBudgetExhausted=true;
    end

    [collision,edges]=collisionCount(actual,active,slot);
    collisionFrames=collisionFrames+double(collision);
    collisionEdges=collisionEdges+edges;
    debugCollision(frame)=collision;
    debugActualGraph(frame,:,:)=actual;
    debugActive(frame,:)=active; debugSuppressed(frame,:)=suppressed;
    debugSlot(frame,:)=slot; debugPrepared(frame,:)=prepared;
    debugQuietReceipt(frame,:)=quietReceipt;
    debugEdgeReceipt(frame,:)=edgeReceipt;
    debugBarrier(frame)=barrierClosed; debugAuthorized(frame)=motionAuthorized;
end

controlAttempts=sum(struct2array(attempts));
controlBytes=sum(struct2array(bytes));
[attemptBound,byteBound]=controlBounds(M,C,preparePolicy);
outsideSafe=isProper(M.unionGraph,slot,active);
O=struct('version','RECEIVER-LIFTED-CLOSURE-KERNEL-v2', ...
    'traceHash',T.hashExact,'selectorHash',M.hashExact, ...
    'affectedCount',S,'affectedNodes',affected, ...
    'barrierClosed',double(barrierClosed),'barrierFrame',barrierFrame, ...
    'motionAuthorized',double(motionAuthorized), ...
    'graphActivationFrame',activationFrame, ...
    'claimEligibleFrame',claimEligibleFrame, ...
    'commitReady',double(commitReady),'commitReadyFrame',commitReadyFrame, ...
    'allAffectedReactivated',double(all(commitReceived(affected))), ...
    'reactivatedCount',nnz(commitReceived(affected)), ...
    'finalSuppressedCount',nnz(suppressed(affected)), ...
    'prepareBudgetExhausted',double(prepareBudgetExhausted), ...
    'commitBudgetExhausted',double(commitBudgetExhausted), ...
    'edgeReceipts',nnz(edgeReceipt),'requiredEdgeReceipts',numel(edgeReceipt), ...
    'actualSubsetOld',double(actualSubsetOld), ...
    'actualSubsetUnion',double(actualSubsetUnion), ...
    'prematureActivationFrames',prematureActivationFrames, ...
    'scheduledCollisionFrames',collisionFrames, ...
    'scheduledCollisionEdges',collisionEdges, ...
    'finalActiveColoringProper',double(outsideSafe), ...
    'attempts',attempts,'bytes',bytes,'controlAttempts',controlAttempts, ...
    'controlBytes',controlBytes,'controlAirtimeSec',controlBytes*8/C.phyRateBps, ...
    'controlAttemptBound',attemptBound,'controlByteBound',byteBound, ...
    'controlAttemptBoundRatio',controlAttempts/attemptBound, ...
    'controlByteBoundRatio',controlBytes/byteBound, ...
    'recipientAttempts',recipientAttempts,'recipientSuccess',recipientSuccess, ...
    'recipientErasure',recipientErasure, ...
    'prepareOpportunityCount',preparePolicy.opportunityCount, ...
    'claimOpportunityCount',claimPolicy.opportunityCount, ...
    'revokePiggybacked',double(piggybackRevoke(C)), ...
    'futureRandomReads',0,'receiverTruthDecisionReads',0, ...
    'debug',struct('active',debugActive,'suppressed',debugSuppressed, ...
    'slot',debugSlot,'prepareTx',debugPrepare,'quietTx',debugQuiet, ...
    'claimTx',debugClaim,'lockProofTx',debugProof, ...
    'responseTx',debugResponse,'commitTx',debugCommit, ...
    'revokeTx',debugRevoke,'prepared',debugPrepared, ...
    'quietReceipt',debugQuietReceipt,'edgeReceipt',debugEdgeReceipt, ...
    'responseBytes',debugResponseBytes,'actualGraph',debugActualGraph, ...
    'barrierClosed',debugBarrier,'motionAuthorized',debugAuthorized, ...
    'collision',debugCollision));
O.stateHashExact=realizationHash([double(debugActive(:)); ...
    double(debugSuppressed(:));debugSlot(:);double(debugPrepared(:)); ...
    double(debugQuietReceipt(:));double(debugEdgeReceipt(:)); ...
    double(debugBarrier);double(debugAuthorized);controlAttempts;controlBytes]);

    function suppressNode(node,frameIndex)
        suppressed(node)=true; active(node)=false;
        if ~piggybackRevoke(C)
            debugRevoke(frameIndex,node)=true;
            sendControl(node,'revoke',M.config.revokeBytes, ...
                squeeze(T.revokeDeliveryU(frameIndex,:,:)), ...
                probability(C,'revokeErasureProbability'));
        end
    end

    function sendControl(sender,kind,packetBytes,draw,p)
        attempts.(kind)=attempts.(kind)+1;
        bytes.(kind)=bytes.(kind)+packetBytes;
        receivers=find(reach(:,sender));
        nDelivered=nnz(draw(receivers,sender)>p);
        recipientAttempts=recipientAttempts+numel(receivers);
        recipientSuccess=recipientSuccess+nDelivered;
        recipientErasure=recipientErasure+numel(receivers)-nDelivered;
    end

    function mask=deliveryVector(sender,draw,p)
        mask=false(N,1); receivers=find(reach(:,sender));
        mask(receivers)=draw(receivers,sender)>p;
        mask(sender)=true;
    end

    function delivered=deliveryTo(sender,receiver,draw,p)
        delivered=sender==receiver || ...
            (reach(receiver,sender)&&draw(receiver,sender)>p);
    end

    function markEndpointSeen(node,mask)
        for edge=1:M.incidentUnionEdgeCount
            edgeWitness=M.incidentEdgeWitness(edge);
            if M.incidentEdgeA(edge)==node && ...
                    (edgeWitness==node||mask(edgeWitness))
                endpointSeen(edge,1)=true;
            end
            if M.incidentEdgeB(edge)==node && ...
                    (edgeWitness==node||mask(edgeWitness))
                endpointSeen(edge,2)=true;
            end
        end
    end

end


function enabled=piggybackRevoke(C)

enabled=false;
if isfield(C,'piggybackRevoke'), enabled=C.piggybackRevoke; end
if ~isscalar(enabled)||~(islogical(enabled)|| ...
        (isnumeric(enabled)&&isfinite(enabled)&&any(enabled==[0 1])))
    error('simulateReceiverLiftedClosureMigration: invalid piggyback flag.');
end
enabled=logical(enabled);

end


function [attemptBound,byteBound]=controlBounds(M,C,preparePolicy)

S=M.affectedCount;
earliestEligible=C.prepareFrame+1+C.claimEligibilityDelayFrames;
claimOpportunities=0; proofFrames=0;
if earliestEligible<=C.maxFrames
    Q=C; Q.eligibleFrame=earliestEligible;
    [~,claimPolicy]=localUnionMigrationClaimSchedule(Q);
    claimOpportunities=claimPolicy.opportunityCount;
    proofFrames=min(C.lockProofRepeatFrames, ...
        C.maxFrames-earliestEligible+1);
end
affected=logical(M.affectedMask);
outsideProof=unique([M.incidentEdgeA(~affected(M.incidentEdgeA)); ...
    M.incidentEdgeB(~affected(M.incidentEdgeB))]);
witnesses=unique(M.incidentEdgeWitness);
revokeBound=S*double(~piggybackRevoke(C));
attemptBound=preparePolicy.opportunityCount+ ...
    preparePolicy.opportunityCount*max(0,S-1)+revokeBound+ ...
    claimOpportunities*S+proofFrames*numel(outsideProof)+ ...
    claimOpportunities*numel(witnesses)+C.commitRetryAttemptLimit;
responseBytesPerOpportunity=0;
for w=reshape(witnesses,1,[])
    responseBytesPerOpportunity=responseBytesPerOpportunity+ ...
        M.config.certificateHeaderBytes+ ...
        nnz(M.incidentEdgeWitness==w)*M.config.certificateEntryBytes;
end
byteBound=preparePolicy.opportunityCount*M.prepareBytes+ ...
    preparePolicy.opportunityCount*max(0,S-1)*M.config.quietBytes+ ...
    revokeBound*M.config.revokeBytes+ ...
    claimOpportunities*S*M.config.claimBytes+ ...
    proofFrames*numel(outsideProof)*M.config.lockProofBytes+ ...
    claimOpportunities*responseBytesPerOpportunity+ ...
    C.commitRetryAttemptLimit*M.config.commitBytes;

end


function [due,policy]=prepareSchedule(C)

P=struct('maxFrames',C.maxFrames,'eligibleFrame',C.prepareFrame, ...
    'claimBackoffEnabled',true, ...
    'claimDenseRetryFrames',C.prepareDenseRetryFrames, ...
    'claimMaxBackoffFrames',C.prepareMaxBackoffFrames, ...
    'claimRetryAttemptLimit',C.prepareRetryAttemptLimit);
[due,policy]=localUnionMigrationClaimSchedule(P);

end


function P=emptyPolicy()
P=struct('opportunityCount',0,'lastOpportunityFrame',NaN);
end


function p=probability(C,name)
p=0; if isfield(C,name), p=C.(name); end
if ~isscalar(p)||~isfinite(p)||p<0||p>1
    error('simulateReceiverLiftedClosureMigration: invalid %s.',name);
end
end


function [collision,count]=collisionCount(graph,active,slot)
[a,b]=find(triu(logical(graph),1));
hit=active(a)&active(b)&slot(a)==slot(b);
count=nnz(hit); collision=count>0;
end


function proper=isProper(graph,slot,active)
[a,b]=find(triu(logical(graph),1));
keep=active(a)&active(b);
proper=all(slot(a(keep))~=slot(b(keep)));
end


function validateInputs(M,C,T)

if ~isstruct(M)||~isscalar(M)||~isfield(M,'admissible')||~M.admissible
    error('simulateReceiverLiftedClosureMigration: admissible M required.');
end
required={'maxFrames','prepareFrame','transactionVersion', ...
    'prepareDenseRetryFrames','prepareMaxBackoffFrames', ...
    'prepareRetryAttemptLimit','claimEligibilityDelayFrames', ...
    'lockProofRepeatFrames','claimBackoffEnabled','claimDenseRetryFrames', ...
    'claimMaxBackoffFrames','claimRetryAttemptLimit', ...
    'commitRetryAttemptLimit','phyRateBps'};
for k=1:numel(required)
    if ~isfield(C,required{k})||~isscalar(C.(required{k}))|| ...
            ~isfinite(C.(required{k}))||C.(required{k})<0
        error('simulateReceiverLiftedClosureMigration: invalid C.%s.', ...
            required{k});
    end
end
if C.maxFrames<1||C.prepareFrame<1||C.prepareFrame>C.maxFrames|| ...
        C.prepareRetryAttemptLimit<1||C.claimRetryAttemptLimit<1|| ...
        C.commitRetryAttemptLimit<1||C.phyRateBps<=0
    error('simulateReceiverLiftedClosureMigration: invalid limits.');
end
F=C.maxFrames; N=M.N;
arrays={'prepareDeliveryU','quietDeliveryU','claimDeliveryU', ...
    'lockProofDeliveryU','responseDeliveryU','commitDeliveryU', ...
    'revokeDeliveryU','actualGraphAfter'};
for k=1:numel(arrays)
    if ~isfield(T,arrays{k})||~isequal(size(T.(arrays{k})),[F N N])
        error('simulateReceiverLiftedClosureMigration: invalid T.%s.',arrays{k});
    end
end
if ~isfield(T,'hashExact')
    error('simulateReceiverLiftedClosureMigration: missing trace hash.');
end

end
