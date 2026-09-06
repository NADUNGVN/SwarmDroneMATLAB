function O=simulateReceiverLiftedRoutedClosureMigration(M,C,T,routeSpec)
%SIMULATERECEIVERLIFTEDROUTEDCLOSUREMIGRATION Causal routed state machine.
%
% Each phase first determines its logical packets from past receiver state.
% Those packets are then scheduled on one common PHY and replayed hop by
% hop.  Only the resulting semantic destination states may update the
% migration protocol.

validateInputs(M,C,T,routeSpec);
if receiverLiftedRoutedClosureTraceHash(T)~=T.hashExact
    error('simulateReceiverLiftedRoutedClosureMigration: trace hash.');
end
N=M.N; F=C.maxFrames; initiator=M.initiator;
direct=logical(routeSpec.directReach);
physical=logical(routeSpec.physicalInterference);
p=routeSpec.linkErasureProbability; r=routeSpec.repetitionsPerHop;
affected=reshape(M.affectedNodes,[],1); affectedMask=logical(M.affectedMask);
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

counterNames={'prepare','quiescent','claim','lockproof','response','commit'};
for k=1:numel(counterNames)
    logicalPackets.(counterNames{k})=0;
    routedPackets.(counterNames{k})=0;
    localOnlyPackets.(counterNames{k})=0;
    physicalAttempts.(counterNames{k})=0;
    physicalBytes.(counterNames{k})=0;
end
bundleLog=repmat(emptyBundleLog(),0,1);
collisionRecipients=0; crossPacketStateWrites=0; forbiddenReads=0;
actualSubsetOld=true; actualSubsetUnion=true;
collisionFrames=0; collisionEdges=0; prematureActivationFrames=0;
debugActive=false(F,N); debugSuppressed=false(F,N); debugSlot=zeros(F,N);
debugPrepare=false(F,1); debugQuiet=false(F,N); debugClaim=false(F,N);
debugProof=false(F,N); debugResponse=false(F,N); debugCommit=false(F,1);
debugPrepared=false(F,N); debugQuietReceipt=false(F,N);
debugEdgeReceipt=false(F,M.incidentUnionEdgeCount);
debugBarrier=false(F,1); debugAuthorized=false(F,1); debugCollision=false(F,1);
debugResponseBytes=zeros(F,N); debugActualGraph=false(F,N,N);

for frame=1:F
    if frame==C.prepareFrame
        suppressNode(initiator); prepared(initiator)=true;
        quietReceipt(initiator)=true;
    end

    if ~barrierClosed&&prepareDue(frame)
        debugPrepare(frame)=true;
        packet=makePacket('prepare',initiator,M.prepareBytes);
        [~,~,received]=runBundle('prepare',packet,frame);
        metadataOk=T.prepareVersion(frame)==transactionVersion&& ...
            T.prepareDigest(frame)==M.hashExact;
        if metadataOk
            mask=reshape(received(1,:),[],1);
            for node=reshape(affected,1,[])
                if node==initiator||mask(node)
                    if ~prepared(node)
                        prepared(node)=true; suppressNode(node);
                    end
                end
            end
        end

        quietPackets=repmat(emptyPacket(),0,1); quietNodes=zeros(0,1);
        for node=reshape(affected(affected~=initiator),1,[])
            if prepared(node)&&~quietReceipt(node)
                debugQuiet(frame,node)=true;
                quietPackets(end+1,1)=makePacket( ...
                    'quiescent',node,M.config.quietBytes); %#ok<AGROW>
                quietNodes(end+1,1)=node; %#ok<AGROW>
            end
        end
        if ~isempty(quietPackets)
            [delivered,~]=runBundle('quiescent',quietPackets,frame);
            for k=1:numel(quietNodes)
                node=quietNodes(k);
                metadataOk=T.quietVersion(frame,node)== ...
                    transactionVersion&&T.quietDigest(frame,node)==M.hashExact;
                if delivered(k)&&metadataOk, quietReceipt(node)=true; end
            end
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
    if ~barrierClosed&&frame>=preparePolicy.lastOpportunityFrame&& ...
            logicalPackets.prepare==preparePolicy.opportunityCount
        prepareBudgetExhausted=true;
    end

    graphActivated=barrierClosed&&frame>=activationFrame;
    if graphActivated
        actual=logical(squeeze(T.actualGraphAfter(frame,:,:)));
        actualSubsetUnion=actualSubsetUnion&& ...
            ~any(triu(actual&~M.unionGraph,1),'all');
    else
        actual=M.oldGraph;
        actualSubsetOld=actualSubsetOld&& ...
            ~any(triu(actual&~M.oldGraph,1),'all');
    end
    if ~barrierClosed&&~isequal(actual,M.oldGraph)
        prematureActivationFrames=prematureActivationFrames+1;
    end

    claimWindow=graphActivated&&frame>=claimEligibleFrame&& ...
        claimDue(frame)&&~commitReady;
    proofWindow=graphActivated&&isfinite(claimEligibleFrame)&& ...
        frame>=claimEligibleFrame&& ...
        frame<claimEligibleFrame+C.lockProofRepeatFrames;
    evidencePackets=repmat(emptyPacket(),0,1);
    evidenceRole=strings(0,1); evidenceNode=zeros(0,1);
    if claimWindow
        for node=reshape(affected,1,[])
            debugClaim(frame,node)=true;
            evidencePackets(end+1,1)=makePacket( ...
                'claim',node,M.config.claimBytes); %#ok<AGROW>
            evidenceRole(end+1,1)="claim"; %#ok<AGROW>
            evidenceNode(end+1,1)=node; %#ok<AGROW>
        end
    end
    if proofWindow
        outsideProof=unique([ ...
            M.incidentEdgeA(~affectedMask(M.incidentEdgeA)); ...
            M.incidentEdgeB(~affectedMask(M.incidentEdgeB))]);
        for node=reshape(outsideProof,1,[])
            debugProof(frame,node)=true;
            evidencePackets(end+1,1)=makePacket( ...
                'lock-proof',node,M.config.lockProofBytes); %#ok<AGROW>
            evidenceRole(end+1,1)="lock-proof"; %#ok<AGROW>
            evidenceNode(end+1,1)=node; %#ok<AGROW>
        end
    end
    if ~isempty(evidencePackets)
        [~,~,received]=runBundle( ...
            'evidence',evidencePackets,frame);
        for k=1:numel(evidencePackets)
            node=evidenceNode(k);
            if evidenceRole(k)=="claim"
                metadataOk=T.claimVersion(frame,node)==transactionVersion&& ...
                    T.claimDigest(frame,node)==M.hashExact;
            else
                metadataOk=T.lockProofVersion(frame,node)== ...
                    transactionVersion&& ...
                    T.lockProofDigest(frame,node)==M.hashExact;
            end
            if metadataOk
                markEndpointSeen(node,reshape(received(k,:),[],1));
            end
        end
    end

    if claimWindow
        ready=all(endpointSeen,2)&~edgeReceipt;
        witnesses=unique(M.incidentEdgeWitness(ready));
        responsePackets=repmat(emptyPacket(),0,1);
        responseWitness=zeros(0,1); responseEntries=cell(0,1);
        for w=reshape(witnesses,1,[])
            entries=find(ready&M.incidentEdgeWitness==w);
            if isempty(entries), continue; end
            debugResponse(frame,w)=true;
            responseBytes=M.config.certificateHeaderBytes+ ...
                numel(entries)*M.config.certificateEntryBytes;
            debugResponseBytes(frame,w)=responseBytes;
            responsePackets(end+1,1)=makePacket( ...
                'response',w,responseBytes); %#ok<AGROW>
            responseWitness(end+1,1)=w; %#ok<AGROW>
            responseEntries{end+1,1}=entries; %#ok<AGROW>
        end
        if ~isempty(responsePackets)
            [delivered,~]=runBundle('response',responsePackets,frame);
            for k=1:numel(responsePackets)
                w=responseWitness(k);
                metadataOk=T.responseVersion(frame,w)== ...
                    transactionVersion&& ...
                    T.responseDigest(frame,w)==M.hashExact;
                if delivered(k)&&metadataOk
                    edgeReceipt(responseEntries{k})=true;
                end
            end
        end
        if all(edgeReceipt)
            commitReady=true; commitReadyFrame=frame;
        end
    end

    if commitReady&&~all(commitReceived(affected))&& ...
            logicalPackets.commit<C.commitRetryAttemptLimit
        debugCommit(frame)=true;
        packet=makePacket('commit',initiator,M.config.commitBytes);
        [~,~,received]=runBundle('commit',packet,frame);
        metadataOk=T.commitVersion(frame)==transactionVersion&& ...
            T.commitDigest(frame)==M.hashExact;
        if metadataOk
            mask=reshape(received(1,:),[],1);
            commitReceived(initiator)=true;
            for node=reshape(affected(affected~=initiator),1,[])
                if mask(node), commitReceived(node)=true; end
            end
        end
        for node=reshape(affected(commitReceived(affected)),1,[])
            suppressed(node)=false; active(node)=true;
            slot(node)=M.candidateSlot(node);
        end
    end
    if commitReady&&~all(commitReceived(affected))&& ...
            logicalPackets.commit>=C.commitRetryAttemptLimit
        commitBudgetExhausted=true;
    end

    [collision,edges]=collisionCount(actual,active,slot);
    collisionFrames=collisionFrames+double(collision);
    collisionEdges=collisionEdges+edges; debugCollision(frame)=collision;
    debugActualGraph(frame,:,:)=actual; debugActive(frame,:)=active;
    debugSuppressed(frame,:)=suppressed; debugSlot(frame,:)=slot;
    debugPrepared(frame,:)=prepared; debugQuietReceipt(frame,:)=quietReceipt;
    debugEdgeReceipt(frame,:)=edgeReceipt; debugBarrier(frame)=barrierClosed;
    debugAuthorized(frame)=motionAuthorized;
end

totalLogical=sum(struct2array(logicalPackets));
totalRouted=sum(struct2array(routedPackets));
totalLocal=sum(struct2array(localOnlyPackets));
totalAttempts=sum(struct2array(physicalAttempts));
totalBytes=sum(struct2array(physicalBytes));
outsideSafe=isProper(M.unionGraph,slot,active);
bundleHashes=reshape([bundleLog.scheduleHash],[],1);
replayHashes=reshape([bundleLog.replayHash],[],1);
O=struct('version','RECEIVER-LIFTED-ROUTED-CLOSURE-KERNEL-v1', ...
    'traceHash',T.hashExact,'selectorHash',M.hashExact, ...
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
    'logicalPackets',logicalPackets,'routedPackets',routedPackets, ...
    'localOnlyPackets',localOnlyPackets, ...
    'physicalAttemptsByKind',physicalAttempts, ...
    'physicalBytesByKind',physicalBytes, ...
    'logicalPacketCount',totalLogical,'routedPacketCount',totalRouted, ...
    'localOnlyPacketCount',totalLocal, ...
    'physicalControlAttempts',totalAttempts, ...
    'physicalControlBytes',totalBytes, ...
    'physicalControlAirtimeSec',8*totalBytes/C.phyRateBps, ...
    'routedBundleCount',numel(bundleLog), ...
    'routeCollisionRecipients',collisionRecipients, ...
    'crossPacketStateWrites',crossPacketStateWrites, ...
    'futureRandomReads',forbiddenReads, ...
    'receiverTruthDecisionReads',0, ...
    'prepareOpportunityCount',preparePolicy.opportunityCount, ...
    'claimOpportunityCount',claimPolicy.opportunityCount, ...
    'bundleLog',bundleLog, ...
    'debug',struct('active',debugActive,'suppressed',debugSuppressed, ...
    'slot',debugSlot,'prepareTx',debugPrepare,'quietTx',debugQuiet, ...
    'claimTx',debugClaim,'lockProofTx',debugProof, ...
    'responseTx',debugResponse,'commitTx',debugCommit, ...
    'prepared',debugPrepared,'quietReceipt',debugQuietReceipt, ...
    'edgeReceipt',debugEdgeReceipt,'responseBytes',debugResponseBytes, ...
    'actualGraph',debugActualGraph,'barrierClosed',debugBarrier, ...
    'motionAuthorized',debugAuthorized,'collision',debugCollision));
O.stateHashExact=realizationHash([double(debugActive(:)); ...
    double(debugSuppressed(:));debugSlot(:);double(debugPrepared(:)); ...
    double(debugQuietReceipt(:));double(debugEdgeReceipt(:)); ...
    double(debugBarrier);double(debugAuthorized);totalLogical;totalRouted; ...
    totalAttempts;totalBytes;bundleHashes;replayHashes]);

    function packet=makePacket(kind,sender,bytes)
        packet=emptyPacket(); packet.kind=string(kind);
        packet.sender=sender; packet.bytes=bytes;
        packet.recipients=receiverLiftedClosureControlRecipients( ...
            M,kind,sender);
        packet.id=packet.kind+'-'+string(sender);
    end

    function [delivered,logIndex,received]=runBundle( ...
            phase,packets,frameIndex)
        packets=reshape(packets,[],1); K=numel(packets);
        delivered=false(K,1); received=false(K,N);
        plans=cell(0,1); bytes=zeros(0,1);
        ids=strings(0,1); map=zeros(0,1); draws=cell(0,1);
        for packetIndex=1:K
            key=counterField(packets(packetIndex).kind);
            logicalPackets.(key)=logicalPackets.(key)+1;
            if ~any(packets(packetIndex).recipients)
                localOnlyPackets.(key)=localOnlyPackets.(key)+1;
                delivered(packetIndex)=true;
                received(packetIndex,packets(packetIndex).sender)=true;
                continue;
            end
            routedPackets.(key)=routedPackets.(key)+1;
            plans{end+1,1}=buildSlottedManagementFloodPlan( ...
                direct,physical,packets(packetIndex).sender, ...
                packets(packetIndex).recipients,N-1); %#ok<AGROW>
            bytes(end+1,1)=packets(packetIndex).bytes; %#ok<AGROW>
            ids(end+1,1)=packets(packetIndex).id; %#ok<AGROW>
            map(end+1,1)=packetIndex; %#ok<AGROW>
            field=traceField(packets(packetIndex).kind);
            draws{end+1,1}=reshape(T.linkUniform.(field)( ...
                frameIndex,packets(packetIndex).sender,:,:,:),N,N,r); %#ok<AGROW>
        end
        log=emptyBundleLog(); log.frame=frameIndex;
        log.phase=string(phase); log.logicalPacketCount=K;
        log.routedPacketCount=numel(plans); log.localOnlyPacketCount=K-numel(plans);
        if isempty(plans)
            log.allPacketsDelivered=1; logIndex=numel(bundleLog)+1;
            bundleLog(logIndex,1)=log; return;
        end
        schedule=buildMultiOriginRoutedControlSchedule( ...
            plans,repmat(r,numel(plans),1),ids);
        replay=simulateMultiOriginRoutedControl(schedule,draws,p,bytes, ...
            C.phyRateBps,routeSpec.safeGuardSec,max(bytes));
        delivered(map)=logical(replay.packetDelivered);
        for routedIndex=1:numel(map)
            packetIndex=map(routedIndex);
            received(packetIndex,:)=replay.knownPacketNode(routedIndex,:);
            key=counterField(packets(map(routedIndex)).kind);
            physicalAttempts.(key)=physicalAttempts.(key)+ ...
                replay.packetAttempts(routedIndex);
            physicalBytes.(key)=physicalBytes.(key)+ ...
                replay.packetPhysicalBytes(routedIndex);
        end
        collisionRecipients=collisionRecipients+replay.collisionRecipients;
        crossPacketStateWrites=crossPacketStateWrites+ ...
            replay.crossPacketStateWrites;
        forbiddenReads=forbiddenReads+replay.futureRandomReads+ ...
            replay.receiverTruthDecisionReads+replay.duplicateForwards;
        log.taskCount=schedule.taskCount;
        log.serialSlotCount=schedule.serialSlotCount;
        log.reservedSlotCount=schedule.reservedSlotCount;
        log.maximumPacketBytes=max(bytes);
        log.physicalAttempts=replay.attempts;
        log.physicalBytes=replay.physicalBytes;
        log.offeredAirtimeSec=replay.offeredAirtimeSec;
        log.allPacketsDelivered=replay.allPacketsDelivered;
        log.collisionRecipients=replay.collisionRecipients;
        log.scheduleHash=schedule.hashExact; log.replayHash=replay.hashExact;
        log.schedule=schedule; log.replay=replay;
        log.packetKind=reshape([packets(map).kind],[],1);
        log.packetSender=reshape([packets(map).sender],[],1);
        log.packetBytes=bytes; log.packetMap=map; log.linkUniform=draws;
        logIndex=numel(bundleLog)+1; bundleLog(logIndex,1)=log;
    end

    function markEndpointSeen(node,mask)
        for edge=1:M.incidentUnionEdgeCount
            witness=M.incidentEdgeWitness(edge);
            if M.incidentEdgeA(edge)==node&& ...
                    (witness==node||mask(witness))
                endpointSeen(edge,1)=true;
            end
            if M.incidentEdgeB(edge)==node&& ...
                    (witness==node||mask(witness))
                endpointSeen(edge,2)=true;
            end
        end
    end

    function suppressNode(node)
        suppressed(node)=true; active(node)=false;
    end

end


function packet=emptyPacket()

packet=struct('kind',"",'sender',0,'bytes',0,'recipients',false(0,1), ...
    'id',"");

end


function log=emptyBundleLog()

log=struct('frame',0,'phase',"",'logicalPacketCount',0, ...
    'routedPacketCount',0,'localOnlyPacketCount',0,'taskCount',0, ...
    'serialSlotCount',0,'reservedSlotCount',0,'maximumPacketBytes',0, ...
    'physicalAttempts',0,'physicalBytes',0,'offeredAirtimeSec',0, ...
    'allPacketsDelivered',0,'collisionRecipients',0, ...
    'scheduleHash',NaN,'replayHash',NaN,'schedule',[], ...
    'replay',[],'packetKind',strings(0,1),'packetSender',zeros(0,1), ...
    'packetBytes',zeros(0,1),'packetMap',zeros(0,1), ...
    'linkUniform',{cell(0,1)});

end


function field=counterField(kind)

field=char(lower(strrep(string(kind),'-','')));

end


function field=traceField(kind)

field=counterField(kind);

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


function [collision,count]=collisionCount(graph,active,slot)

[a,b]=find(triu(logical(graph),1));
hit=active(a)&active(b)&slot(a)==slot(b);
count=nnz(hit); collision=count>0;

end


function proper=isProper(graph,slot,active)

[a,b]=find(triu(logical(graph),1)); keep=active(a)&active(b);
proper=all(slot(a(keep))~=slot(b(keep)));

end


function validateInputs(M,C,T,routeSpec)

if ~isstruct(M)||~isscalar(M)||~isfield(M,'admissible')||~M.admissible
    error('simulateReceiverLiftedRoutedClosureMigration: migration.');
end
requiredC={'maxFrames','prepareFrame','transactionVersion', ...
    'prepareDenseRetryFrames','prepareMaxBackoffFrames', ...
    'prepareRetryAttemptLimit','claimEligibilityDelayFrames', ...
    'lockProofRepeatFrames','claimBackoffEnabled','claimDenseRetryFrames', ...
    'claimMaxBackoffFrames','claimRetryAttemptLimit', ...
    'commitRetryAttemptLimit','phyRateBps'};
if ~isstruct(C)||~isscalar(C)||~all(isfield(C,requiredC))
    error('simulateReceiverLiftedRoutedClosureMigration: kernel config.');
end
values=cellfun(@(x) double(C.(x)),requiredC);
if any(~isfinite(values))||any(values<0)||C.maxFrames<1|| ...
        C.prepareFrame<1||C.prepareFrame>C.maxFrames|| ...
        C.prepareRetryAttemptLimit<1||C.claimRetryAttemptLimit<1|| ...
        C.commitRetryAttemptLimit<1||C.phyRateBps<=0
    error('simulateReceiverLiftedRoutedClosureMigration: kernel values.');
end
requiredRoute={'directReach','physicalInterference', ...
    'linkErasureProbability','repetitionsPerHop','safeGuardSec'};
if ~isstruct(routeSpec)||~isscalar(routeSpec)|| ...
        ~all(isfield(routeSpec,requiredRoute))
    error('simulateReceiverLiftedRoutedClosureMigration: route spec.');
end
N=M.N; F=C.maxFrames; r=routeSpec.repetitionsPerHop;
if ~isequal(size(routeSpec.directReach),[N N])|| ...
        ~isequal(size(routeSpec.physicalInterference),[N N])|| ...
        ~isscalar(routeSpec.linkErasureProbability)|| ...
        ~isfinite(routeSpec.linkErasureProbability)|| ...
        routeSpec.linkErasureProbability<0|| ...
        routeSpec.linkErasureProbability>1||~isscalar(r)||~isfinite(r)|| ...
        r<1||r~=floor(r)||~isscalar(routeSpec.safeGuardSec)|| ...
        ~isfinite(routeSpec.safeGuardSec)||routeSpec.safeGuardSec<0
    error('simulateReceiverLiftedRoutedClosureMigration: route values.');
end
if ~isstruct(T)||~isscalar(T)||~isfield(T,'linkUniform')|| ...
        ~isfield(T,'repetitionsPerHop')||T.repetitionsPerHop~=r
    error('simulateReceiverLiftedRoutedClosureMigration: trace metadata.');
end
kinds={'prepare','quiescent','claim','lockproof','response','commit'};
for k=1:numel(kinds)
    if ~isfield(T.linkUniform,kinds{k})
        error('simulateReceiverLiftedRoutedClosureMigration: trace kind.');
    end
    value=T.linkUniform.(kinds{k});
    if size(value,1)~=F||size(value,2)~=N||size(value,3)~=N|| ...
            size(value,4)~=N||size(value,5)~=r||ndims(value)>5|| ...
            any(~isfinite(value),'all')||any(value<0|value>1,'all')
        error('simulateReceiverLiftedRoutedClosureMigration: routed draws.');
    end
end
fields={'actualGraphAfter','prepareVersion','prepareDigest', ...
    'quietVersion','quietDigest','claimVersion','claimDigest', ...
    'lockProofVersion','lockProofDigest','responseVersion', ...
    'responseDigest','commitVersion','commitDigest','hashExact'};
if ~all(isfield(T,fields))||size(T.actualGraphAfter,1)~=F|| ...
        size(T.actualGraphAfter,2)~=N||size(T.actualGraphAfter,3)~=N
    error('simulateReceiverLiftedRoutedClosureMigration: trace state.');
end

end
