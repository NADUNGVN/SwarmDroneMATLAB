function Q=buildElcsWitnessContinuousSchedule(C,T,horizonSec)
%BUILDELSCWITNESSCONTINUOUSSCHEDULE Map ELCS-W to one physical PHY.

if ~isscalar(horizonSec) || ~isfinite(horizonSec) || horizonSec<=0
    error('buildElcsWitnessContinuousSchedule: invalid horizon.');
end
K=simulateElcsWitnessScheduling(C,T);
N=C.N;
Ddata=8*C.dataBytes/C.phyRateBps;
Dclaim=8*C.claimBytes/C.phyRateBps;
responseBytes=C.certificateHeaderBytes+ ...
    K.witnessMap.responseEntryLoad*C.certificateEntryBytes;
responseBytes(K.witnessMap.responseEntryLoad==0)=0;
Dresponse=8*responseBytes/C.phyRateBps;
Sdata=Ddata+C.guardSec;
Sclaim=Dclaim+C.guardSec;
claimPhaseDuration=N*Sclaim;
responseOffset=zeros(N,1);
cursor=claimPhaseDuration;
for witness=1:N
    responseOffset(witness)=cursor;
    if responseBytes(witness)>0
        cursor=cursor+Dresponse(witness)+C.guardSec;
    end
end
responsePhaseDuration=cursor-claimPhaseDuration;
dataOffset=cursor;
frameDuration=dataOffset+(C.fallbackSlots+C.frameLength)*Sdata;
frameStart=(0:C.maxFrames-1)'*frameDuration;
frameEnd=frameStart+frameDuration;
if frameEnd(end)<horizonSec-1e-12
    error(['buildElcsWitnessContinuousSchedule: kernel covers %.6g s, ' ...
        'shorter than horizon %.6g s.'],frameEnd(end),horizonSec);
end
used=find(frameEnd<=horizonSec+1e-12);

controlStart=zeros(0,1); controlNode=zeros(0,1);
controlSlot=zeros(0,1); controlFrame=zeros(0,1);
controlKind=strings(0,1); controlAttemptBytes=zeros(0,1);
controlAttemptAirtime=zeros(0,1);
controlGroupStart=zeros(0,1); controlGroupEnd=zeros(0,1);
controlGroupFrame=zeros(0,1); controlGroupSlot=zeros(0,1);
controlGroupAttempts=zeros(0,1); controlGroupAirtime=zeros(0,1);
controlGroupRecipientAttempts=zeros(0,1);
controlGroupRecipientSuccess=zeros(0,1);
controlGroupRecipientErasure=zeros(0,1);
controlGroupRecipientCollision=zeros(0,1);
controlGroupCollision=false(0,1);
dataStart=zeros(0,1); dataNode=zeros(0,1); dataSlot=zeros(0,1);
dataFrame=zeros(0,1); dataGroup=zeros(0,1); dataKind=strings(0,1);
dataSuccess=false(0,N); dataErasure=false(0,N);
dataCollision=false(0,N); nextDataGroup=0;

for frame=reshape(used,1,[])
    fs=frameStart(frame);
    claimNodes=find(K.debug.claimTx(frame,:));
    for node=reshape(claimNodes,1,[])
        tk=fs+(node-1)*Sclaim;
        appendControl(frame,node,node,'claim',tk,C.claimBytes, ...
            squeeze(K.debug.claimSuccess(frame,:,:)), ...
            squeeze(K.debug.claimErasure(frame,:,:)), ...
            squeeze(K.debug.claimCollision(frame,:,:)));
    end
    responseNodes=find(K.debug.certificateTx(frame,:));
    for node=reshape(responseNodes,1,[])
        bytes=K.debug.certificateBytes(frame,node);
        if bytes<=0 || bytes>responseBytes(node)
            error(['buildElcsWitnessContinuousSchedule: response bytes ' ...
                'violate reserved witness slot.']);
        end
        tk=fs+responseOffset(node);
        appendControl(frame,node,N+node,'response',tk,bytes, ...
            squeeze(K.debug.certificateSuccess(frame,:,:)), ...
            squeeze(K.debug.certificateErasure(frame,:,:)), ...
            squeeze(K.debug.certificateCollision(frame,:,:)));
    end
    fallbackBase=fs+dataOffset;
    for fallbackSlot=1:C.fallbackSlots
        nodes=find(squeeze(K.debug.fallbackTx(frame,fallbackSlot,:)))';
        tk=fallbackBase+(fallbackSlot-1)*Sdata;
        appendData(frame,fallbackSlot,'fallback',tk,nodes, ...
            squeeze(K.debug.fallbackSuccess(frame,fallbackSlot,:,:)), ...
            squeeze(K.debug.fallbackErasure(frame,fallbackSlot,:,:)), ...
            squeeze(K.debug.fallbackCollision(frame,fallbackSlot,:,:)));
    end
    scheduledBase=fallbackBase+C.fallbackSlots*Sdata;
    for scheduledSlot=1:C.frameLength
        nodes=find(K.debug.active(frame,:) & ...
            K.debug.slot(frame,:)==scheduledSlot);
        tk=scheduledBase+(scheduledSlot-1)*Sdata;
        appendData(frame,C.fallbackSlots+scheduledSlot, ...
            'scheduled',tk,nodes, ...
            squeeze(K.debug.scheduledSuccess(frame,:,:)), ...
            squeeze(K.debug.scheduledErasure(frame,:,:)), ...
            squeeze(K.debug.scheduledCollision(frame,:,:)));
    end
end

if ~isempty(controlStart)
    [~,order]=sortrows([controlStart controlNode],[1 2]);
    controlStart=controlStart(order); controlNode=controlNode(order);
    controlSlot=controlSlot(order); controlFrame=controlFrame(order);
    controlKind=controlKind(order); controlAttemptBytes=controlAttemptBytes(order);
    controlAttemptAirtime=controlAttemptAirtime(order);
end
if ~isempty(dataStart)
    [~,order]=sortrows([dataStart dataNode],[1 2]);
    dataStart=dataStart(order); dataNode=dataNode(order);
    dataSlot=dataSlot(order); dataFrame=dataFrame(order);
    dataGroup=dataGroup(order); dataKind=dataKind(order);
    dataSuccess=dataSuccess(order,:); dataErasure=dataErasure(order,:);
    dataCollision=dataCollision(order,:);
end

Q=struct('version','ELCS-W-CONTINUOUS-SCHEDULE-v1', ...
    'horizonSec',horizonSec,'airtimeSec',Ddata, ...
    'controlAirtimeSec',max([Dclaim;Dresponse]), ...
    'guardSec',C.guardSec,'slotDurationSec',Sdata, ...
    'controlSlotDurationSec',max([Sclaim;Dresponse+C.guardSec]), ...
    'frameDurationSec',frameDuration,'frameStartTime',frameStart(used), ...
    'frameEndTime',frameEnd(used),'claimPhaseDurationSec',claimPhaseDuration, ...
    'responsePhaseDurationSec',responsePhaseDuration, ...
    'responseReservedBytes',responseBytes, ...
    'dataStartTime',dataStart,'dataNode',dataNode,'dataSlot',dataSlot, ...
    'dataFrame',dataFrame,'dataGroup',dataGroup,'dataKind',dataKind, ...
    'dataSuccessMask',dataSuccess,'dataErasureMask',dataErasure, ...
    'dataCollisionMask',dataCollision, ...
    'dataCompletesByHorizon',true(size(dataStart)), ...
    'controlStartTime',controlStart,'controlNode',controlNode, ...
    'controlSlot',controlSlot,'controlFrame',controlFrame, ...
    'controlKind',controlKind,'controlAttemptBytes',controlAttemptBytes, ...
    'controlAttemptAirtimeSec',controlAttemptAirtime, ...
    'controlGroupStartTime',controlGroupStart, ...
    'controlGroupEndTime',controlGroupEnd, ...
    'controlGroupFrame',controlGroupFrame, ...
    'controlGroupSlot',controlGroupSlot, ...
    'controlGroupAttempts',controlGroupAttempts, ...
    'controlGroupAirtimeSec',controlGroupAirtime, ...
    'controlGroupRecipientAttempts',controlGroupRecipientAttempts, ...
    'controlGroupRecipientSuccess',controlGroupRecipientSuccess, ...
    'controlGroupRecipientErasure',controlGroupRecipientErasure, ...
    'controlGroupRecipientCollision',controlGroupRecipientCollision, ...
    'controlGroupCollision',controlGroupCollision, ...
    'kernel',K,'kernelConfigHash',K.configHash, ...
    'kernelTraceHash',K.traceHash,'futureRandomReads',K.futureRandomReads, ...
    'receiverTruthDecisionReads',K.receiverTruthDecisionReads);
Q.expectedManagementAttempts=sum(controlGroupAttempts);
Q.expectedManagementAirtime=sum(controlGroupAirtime);
Q.expectedManagementRecipientAttempts=sum(controlGroupRecipientAttempts);
Q.expectedManagementRecipientSuccess=sum(controlGroupRecipientSuccess);
Q.expectedManagementRecipientErasure=sum(controlGroupRecipientErasure);
Q.expectedManagementRecipientCollision=sum(controlGroupRecipientCollision);
Q.expectedDataCollisionFrames=nnz(any(dataCollision,2));
Q.expectedDataRecipientSuccess=nnz(dataSuccess);
Q.expectedDataRecipientErasure=nnz(dataErasure);
Q.expectedDataRecipientCollision=nnz(dataCollision);
Q.expectedCompletedDataCollisionFrames=Q.expectedDataCollisionFrames;
Q.expectedCompletedDataRecipientSuccess=Q.expectedDataRecipientSuccess;
Q.expectedCompletedDataRecipientErasure=Q.expectedDataRecipientErasure;
Q.expectedCompletedDataRecipientCollision=Q.expectedDataRecipientCollision;
Q.firstConvergenceTimeSec=NaN;
if isfinite(K.firstAllCertifiedFrame) && ...
        K.firstAllCertifiedFrame<=numel(used)
    Q.firstConvergenceTimeSec=frameEnd(K.firstAllCertifiedFrame);
end
dataLogical=[dataFrame dataSlot dataNode double(dataKind=="scheduled")];
controlLogical=[controlFrame controlSlot controlNode controlAttemptBytes];
Q.logicalOpportunityHashExact=realizationHash([dataLogical(:);controlLogical(:)]);
Q.hashExact=realizationHash([horizonSec;Ddata;Dclaim;Dresponse; ...
    responseBytes;C.guardSec;frameStart(used);frameEnd(used); ...
    dataStart;dataNode;dataSlot;dataFrame;dataGroup; ...
    double(dataKind=="scheduled");double(dataSuccess(:)); ...
    double(dataErasure(:));double(dataCollision(:));controlStart; ...
    controlNode;controlSlot;controlFrame;controlAttemptBytes; ...
    controlAttemptAirtime;double(controlKind=="response"); ...
    controlGroupStart;controlGroupEnd;controlGroupFrame; ...
    controlGroupSlot;controlGroupAttempts;controlGroupAirtime; ...
    controlGroupRecipientAttempts;controlGroupRecipientSuccess; ...
    controlGroupRecipientErasure;controlGroupRecipientCollision; ...
    double(controlGroupCollision);K.configHash;K.traceHash]);
validateSchedule(Q,C);

    function appendControl(frameIndex,node,slotIndex,kind,tk,bytes, ...
            successMask,erasureMask,collisionMask)
        duration=8*bytes/C.phyRateBps;
        controlStart(end+1,1)=tk;
        controlNode(end+1,1)=node;
        controlSlot(end+1,1)=slotIndex;
        controlFrame(end+1,1)=frameIndex;
        controlKind(end+1,1)=string(kind);
        controlAttemptBytes(end+1,1)=bytes;
        controlAttemptAirtime(end+1,1)=duration;
        controlGroupStart(end+1,1)=tk;
        controlGroupEnd(end+1,1)=tk+duration;
        controlGroupFrame(end+1,1)=frameIndex;
        controlGroupSlot(end+1,1)=slotIndex;
        controlGroupAttempts(end+1,1)=1;
        controlGroupAirtime(end+1,1)=duration;
        outcome=outcomeCounts(node,successMask,erasureMask,collisionMask);
        controlGroupRecipientAttempts(end+1,1)=outcome.attempts;
        controlGroupRecipientSuccess(end+1,1)=outcome.success;
        controlGroupRecipientErasure(end+1,1)=outcome.erasure;
        controlGroupRecipientCollision(end+1,1)=outcome.collision;
        controlGroupCollision(end+1,1)=outcome.collision>0;
    end

    function appendData(frameIndex,slotIndex,kind,tk,nodes, ...
            successMask,erasureMask,collisionMask)
        if isempty(nodes), return; end
        nextDataGroup=nextDataGroup+1;
        for sender=reshape(nodes,1,[])
            dataStart(end+1,1)=tk; dataNode(end+1,1)=sender;
            dataSlot(end+1,1)=slotIndex; dataFrame(end+1,1)=frameIndex;
            dataGroup(end+1,1)=nextDataGroup; dataKind(end+1,1)=string(kind);
            dataSuccess(end+1,:)=reshape(successMask(:,sender),1,[]);
            dataErasure(end+1,:)=reshape(erasureMask(:,sender),1,[]);
            dataCollision(end+1,:)=reshape(collisionMask(:,sender),1,[]);
        end
    end

end


function a=outcomeCounts(node,success,erasure,collision)

a=struct('success',nnz(success(:,node)), ...
    'erasure',nnz(erasure(:,node)), ...
    'collision',nnz(collision(:,node)));
a.attempts=a.success+a.erasure+a.collision;

end


function validateSchedule(Q,C)

if any(diff(Q.dataStartTime)<-1e-12) || ...
        any(diff(Q.controlStartTime)<-1e-12)
    error('buildElcsWitnessContinuousSchedule: event starts not monotone.');
end
if any(Q.controlAttemptBytes<=0 | ...
        Q.controlAttemptBytes>C.maxControlPacketBytes)
    error('buildElcsWitnessContinuousSchedule: invalid control payload.');
end
if sum(Q.controlGroupAttempts)~=numel(Q.controlStartTime) || ...
        abs(sum(Q.controlGroupAirtimeSec)- ...
        sum(Q.controlAttemptAirtimeSec))>1e-12 || ...
        sum(Q.controlGroupRecipientAttempts)~= ...
        sum(Q.controlGroupRecipientSuccess)+ ...
        sum(Q.controlGroupRecipientErasure)+ ...
        sum(Q.controlGroupRecipientCollision)
    error('buildElcsWitnessContinuousSchedule: control accounting fails.');
end
partition=double(Q.dataSuccessMask)+double(Q.dataErasureMask)+ ...
    double(Q.dataCollisionMask);
if any(partition(:)>1) || ...
        ~isequal(size(Q.dataSuccessMask),[numel(Q.dataStartTime) C.N])
    error('buildElcsWitnessContinuousSchedule: malformed DATA outcomes.');
end

end
