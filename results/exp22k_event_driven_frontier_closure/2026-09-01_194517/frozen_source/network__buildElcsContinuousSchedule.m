function Q=buildElcsContinuousSchedule(C,T,horizonSec)
%BUILDELCScONTINUOUSSCHEDULE Translate ELCS-F kernel to physical time.

if ~isscalar(horizonSec) || ~isfinite(horizonSec) || horizonSec<=0
    error('buildElcsContinuousSchedule: horizon must be positive finite.');
end
K=simulateElcsScheduling(C,T);
Ddata=8*C.dataBytes/C.phyRateBps;
Dcontrol=8*C.controlBytes/C.phyRateBps;
Sdata=Ddata+C.guardSec;
Scontrol=Dcontrol+C.guardSec;
frameDuration=2*C.controlSlots*Scontrol+ ...
    (C.fallbackSlots+C.frameLength)*Sdata;
F=C.maxFrames;
frameStart=(0:F-1)'*frameDuration;
frameEnd=frameStart+frameDuration;
if frameEnd(end)<horizonSec-1e-12
    error(['buildElcsContinuousSchedule: kernel covers %.6g s, shorter ' ...
        'than horizon %.6g s.'],frameEnd(end),horizonSec);
end
used=find(frameStart<horizonSec-1e-12);
N=C.N;

controlStart=zeros(0,1);
controlNode=zeros(0,1);
controlSlot=zeros(0,1);
controlFrame=zeros(0,1);
controlKind=strings(0,1);
controlGroupStart=zeros(0,1);
controlGroupEnd=zeros(0,1);
controlGroupFrame=zeros(0,1);
controlGroupSlot=zeros(0,1);
controlGroupAttempts=zeros(0,1);
controlGroupRecipientAttempts=zeros(0,1);
controlGroupRecipientSuccess=zeros(0,1);
controlGroupRecipientErasure=zeros(0,1);
controlGroupRecipientCollision=zeros(0,1);
controlGroupCollision=false(0,1);

dataStart=zeros(0,1);
dataNode=zeros(0,1);
dataSlot=zeros(0,1);
dataFrame=zeros(0,1);
dataGroup=zeros(0,1);
dataKind=strings(0,1);
dataSuccess=false(0,N);
dataErasure=false(0,N);
dataCollision=false(0,N);
nextDataGroup=0;

for frame=reshape(used,1,[])
    fs=frameStart(frame);
    appendControl(frame,'status',0,K.debug.statusTx(frame,:), ...
        K.debug.statusChoice(frame,:), ...
        squeeze(K.debug.statusSuccess(frame,:,:)), ...
        squeeze(K.debug.statusErasure(frame,:,:)), ...
        squeeze(K.debug.statusCollision(frame,:,:)));
    appendControl(frame,'grant',C.controlSlots*Scontrol, ...
        K.debug.grantTx(frame,:),K.debug.grantChoice(frame,:), ...
        squeeze(K.debug.grantSuccess(frame,:,:)), ...
        squeeze(K.debug.grantErasure(frame,:,:)), ...
        squeeze(K.debug.grantCollision(frame,:,:)));

    fallbackBase=fs+2*C.controlSlots*Scontrol;
    for fallbackSlot=1:C.fallbackSlots
        tx=find(squeeze(K.debug.fallbackTx(frame,fallbackSlot,:)))';
        tk=fallbackBase+(fallbackSlot-1)*Sdata;
        appendData(frame,fallbackSlot,'fallback',tk,tx, ...
            squeeze(K.debug.fallbackSuccess(frame,fallbackSlot,:,:)), ...
            squeeze(K.debug.fallbackErasure(frame,fallbackSlot,:,:)), ...
            squeeze(K.debug.fallbackCollision(frame,fallbackSlot,:,:)));
    end
    scheduledBase=fallbackBase+C.fallbackSlots*Sdata;
    for scheduledSlot=1:C.frameLength
        tx=find(K.debug.active(frame,:) & ...
            K.debug.slot(frame,:)==scheduledSlot);
        tk=scheduledBase+(scheduledSlot-1)*Sdata;
        appendData(frame,C.fallbackSlots+scheduledSlot, ...
            'scheduled',tk,tx, ...
            squeeze(K.debug.scheduledSuccess(frame,:,:)), ...
            squeeze(K.debug.scheduledErasure(frame,:,:)), ...
            squeeze(K.debug.scheduledCollision(frame,:,:)));
    end
end

if ~isempty(controlStart)
    [~,order]=sortrows([controlStart controlNode],[1 2]);
    controlStart=controlStart(order);
    controlNode=controlNode(order);
    controlSlot=controlSlot(order);
    controlFrame=controlFrame(order);
    controlKind=controlKind(order);
end
if ~isempty(dataStart)
    [~,order]=sortrows([dataStart dataNode],[1 2]);
    dataStart=dataStart(order);
    dataNode=dataNode(order);
    dataSlot=dataSlot(order);
    dataFrame=dataFrame(order);
    dataGroup=dataGroup(order);
    dataKind=dataKind(order);
    dataSuccess=dataSuccess(order,:);
    dataErasure=dataErasure(order,:);
    dataCollision=dataCollision(order,:);
end
complete=dataStart+Ddata<=horizonSec+1e-12;
Q=struct();
Q.version='ELCS-F-CONTINUOUS-SCHEDULE-v1';
Q.horizonSec=horizonSec;
Q.airtimeSec=Ddata;
Q.controlAirtimeSec=Dcontrol;
Q.guardSec=C.guardSec;
Q.slotDurationSec=Sdata;
Q.controlSlotDurationSec=Scontrol;
Q.frameDurationSec=frameDuration;
Q.frameStartTime=frameStart(used);
Q.frameEndTime=frameEnd(used);
Q.dataStartTime=dataStart;
Q.dataNode=dataNode;
Q.dataSlot=dataSlot;
Q.dataFrame=dataFrame;
Q.dataGroup=dataGroup;
Q.dataKind=dataKind;
Q.dataSuccessMask=dataSuccess;
Q.dataErasureMask=dataErasure;
Q.dataCollisionMask=dataCollision;
Q.dataCompletesByHorizon=complete;
Q.controlStartTime=controlStart;
Q.controlNode=controlNode;
Q.controlSlot=controlSlot;
Q.controlFrame=controlFrame;
Q.controlKind=controlKind;
Q.controlGroupStartTime=controlGroupStart;
Q.controlGroupEndTime=controlGroupEnd;
Q.controlGroupFrame=controlGroupFrame;
Q.controlGroupSlot=controlGroupSlot;
Q.controlGroupAttempts=controlGroupAttempts;
Q.controlGroupRecipientAttempts=controlGroupRecipientAttempts;
Q.controlGroupRecipientSuccess=controlGroupRecipientSuccess;
Q.controlGroupRecipientErasure=controlGroupRecipientErasure;
Q.controlGroupRecipientCollision=controlGroupRecipientCollision;
Q.controlGroupCollision=controlGroupCollision;
Q.managementReach=logical(C.managementReach);
Q.neighborGraph=logical(C.neighborGraph);
Q.interferenceMatrix=logical(C.interferenceMatrix);
Q.kernel=K;
Q.kernelConfigHash=K.configHash;
Q.kernelTraceHash=K.traceHash;
controlBound=elcsControlAttemptBound(C);
Q.controlAttemptBound=controlBound.total;
Q.futureRandomReads=K.futureRandomReads;
Q.receiverTruthDecisionReads=K.receiverTruthDecisionReads;
Q.expectedDataCollisionFrames=nnz(any(dataCollision,2));
Q.expectedDataRecipientSuccess=nnz(dataSuccess);
Q.expectedDataRecipientErasure=nnz(dataErasure);
Q.expectedDataRecipientCollision=nnz(dataCollision);
Q.expectedCompletedDataCollisionFrames= ...
    nnz(any(dataCollision(complete,:),2));
Q.expectedCompletedDataRecipientSuccess=nnz(dataSuccess(complete,:));
Q.expectedCompletedDataRecipientErasure=nnz(dataErasure(complete,:));
Q.expectedCompletedDataRecipientCollision=nnz(dataCollision(complete,:));
Q.expectedManagementAttempts=sum(controlGroupAttempts);
Q.expectedManagementRecipientAttempts=sum(controlGroupRecipientAttempts);
Q.expectedManagementRecipientSuccess=sum(controlGroupRecipientSuccess);
Q.expectedManagementRecipientErasure=sum(controlGroupRecipientErasure);
Q.expectedManagementRecipientCollision=sum(controlGroupRecipientCollision);
Q.firstConvergenceTimeSec=NaN;
if isfinite(K.firstAllCertifiedFrame) && ...
        K.firstAllCertifiedFrame<=numel(frameEnd)
    Q.firstConvergenceTimeSec=frameEnd(K.firstAllCertifiedFrame);
end
Q.hashExact=realizationHash([horizonSec;Ddata;Dcontrol;C.guardSec; ...
    frameStart(used);frameEnd(used);dataStart;dataNode;dataSlot; ...
    dataFrame;dataGroup;double(dataKind=="scheduled"); ...
    double(dataSuccess(:)); ...
    double(dataErasure(:));double(dataCollision(:));double(complete); ...
    controlStart;controlNode;controlSlot;controlFrame; ...
    double(controlKind=="grant");controlGroupStart;controlGroupEnd; ...
    controlGroupFrame;controlGroupSlot;controlGroupAttempts; ...
    controlGroupRecipientAttempts;controlGroupRecipientSuccess; ...
    controlGroupRecipientErasure;controlGroupRecipientCollision; ...
    double(controlGroupCollision);K.configHash;K.traceHash]);
validateSchedule(Q,C);

    function appendControl(frameIndex,kind,phaseOffset,txMask,choice, ...
            successMask,erasureMask,collisionMask)
        tx=find(txMask);
        for minislot=1:C.controlSlots
            nodes=tx(choice(tx)==minislot);
            if isempty(nodes), continue; end
            tk=fs+phaseOffset+(minislot-1)*Scontrol;
            if tk>=horizonSec-1e-12, continue; end
            count=numel(nodes);
            controlStart(end+1:end+count,1)=tk;
            controlNode(end+1:end+count,1)=nodes(:);
            controlSlot(end+1:end+count,1)= ...
                (strcmp(kind,'grant')*C.controlSlots)+minislot;
            controlFrame(end+1:end+count,1)=frameIndex;
            controlKind(end+1:end+count,1)=string(kind);
            controlGroupStart(end+1,1)=tk;
            controlGroupEnd(end+1,1)=tk+Dcontrol;
            controlGroupFrame(end+1,1)=frameIndex;
            controlGroupSlot(end+1,1)= ...
                (strcmp(kind,'grant')*C.controlSlots)+minislot;
            controlGroupAttempts(end+1,1)=count;
            outcome=outcomeCounts(nodes,successMask, ...
                erasureMask,collisionMask);
            controlGroupRecipientAttempts(end+1,1)=outcome.attempts;
            controlGroupRecipientSuccess(end+1,1)=outcome.success;
            controlGroupRecipientErasure(end+1,1)=outcome.erasure;
            controlGroupRecipientCollision(end+1,1)=outcome.collision;
            controlGroupCollision(end+1,1)=outcome.collision>0;
        end
    end

    function appendData(frameIndex,slotIndex,kind,tk,nodes, ...
            successMask,erasureMask,collisionMask)
        if isempty(nodes) || tk>=horizonSec-1e-12, return; end
        nextDataGroup=nextDataGroup+1;
        for node=reshape(nodes,1,[])
            dataStart(end+1,1)=tk;
            dataNode(end+1,1)=node;
            dataSlot(end+1,1)=slotIndex;
            dataFrame(end+1,1)=frameIndex;
            dataGroup(end+1,1)=nextDataGroup;
            dataKind(end+1,1)=string(kind);
            dataSuccess(end+1,:)=reshape(successMask(:,node),1,[]);
            dataErasure(end+1,:)=reshape(erasureMask(:,node),1,[]);
            dataCollision(end+1,:)=reshape(collisionMask(:,node),1,[]);
        end
    end

end


function a=outcomeCounts(nodes,success,erasure,collision)

mask=false(size(success));
mask(:,nodes)=true;
a=struct('success',nnz(success & mask), ...
    'erasure',nnz(erasure & mask), ...
    'collision',nnz(collision & mask));
a.attempts=a.success+a.erasure+a.collision;

end


function validateSchedule(Q,C)

if any(diff(Q.dataStartTime)<-1e-12) || ...
        any(diff(Q.controlStartTime)<-1e-12)
    error('buildElcsContinuousSchedule: event starts are not monotone.');
end
if any(Q.dataStartTime<0 | Q.dataStartTime>=Q.horizonSec) || ...
        any(Q.controlStartTime<0 | Q.controlStartTime>=Q.horizonSec)
    error('buildElcsContinuousSchedule: event lies outside horizon.');
end
partition=double(Q.dataSuccessMask)+double(Q.dataErasureMask)+ ...
    double(Q.dataCollisionMask);
if any(partition(:)>1) || ...
        ~isequal(size(Q.dataSuccessMask),[numel(Q.dataStartTime) C.N])
    error('buildElcsContinuousSchedule: malformed DATA outcomes.');
end
if sum(Q.controlGroupAttempts)~=numel(Q.controlStartTime) || ...
        sum(Q.controlGroupRecipientAttempts)~= ...
        sum(Q.controlGroupRecipientSuccess)+ ...
        sum(Q.controlGroupRecipientErasure)+ ...
        sum(Q.controlGroupRecipientCollision)
    error('buildElcsContinuousSchedule: management prefix does not close.');
end

end
