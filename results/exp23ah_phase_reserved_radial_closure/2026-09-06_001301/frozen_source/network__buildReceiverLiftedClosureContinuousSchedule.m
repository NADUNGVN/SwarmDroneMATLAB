function Q=buildReceiverLiftedClosureContinuousSchedule(M,C,T,P)
%BUILDRECEIVERLIFTEDCLOSURECONTINUOUSSCHEDULE Map closure kernel to one PHY.

required={'guardSec','dataBytes','horizonSec'};
if ~isstruct(P)||~isscalar(P)||~all(isfield(P,required))|| ...
        any(~isfinite([P.guardSec P.dataBytes P.horizonSec]))|| ...
        P.guardSec<0||P.dataBytes<=0||P.dataBytes~=floor(P.dataBytes)|| ...
        P.horizonSec<=0
    error('buildReceiverLiftedClosureContinuousSchedule: physical spec.');
end
K=simulateReceiverLiftedClosureMigration(M,C,T);
if ~K.revokePiggybacked || any(K.debug.revokeTx,'all')
    error(['buildReceiverLiftedClosureContinuousSchedule: common-PHY ' ...
        'mapping requires PREPARE/QUIESCENT revoke piggybacking.']);
end
N=M.N; F=C.maxFrames; rate=C.phyRateBps;
Dcontrol=8*M.config.maxControlPacketBytes/rate;
Ddata=8*P.dataBytes/rate;
Scontrol=Dcontrol+P.guardSec; Sdata=Ddata+P.guardSec;
phase1Duration=N*Scontrol; phase2Duration=N*Scontrol;
commitPhaseDuration=Scontrol;
dataOffset=phase1Duration+phase2Duration+commitPhaseDuration;
frameDuration=dataOffset+M.config.maxDataSlots*Sdata;
frameStart=(0:F-1)'*frameDuration; frameEnd=frameStart+frameDuration;
if frameEnd(end)>P.horizonSec+1e-12
    error('buildReceiverLiftedClosureContinuousSchedule: horizon short.');
end
reach=logical(M.managementReach); reach(1:N+1:end)=false;

controlStart=zeros(0,1); controlNode=zeros(0,1); controlSlot=zeros(0,1);
controlFrame=zeros(0,1); controlKind=strings(0,1);
controlBytes=zeros(0,1); controlAirtime=zeros(0,1);
groupStart=zeros(0,1); groupEnd=zeros(0,1); groupFrame=zeros(0,1);
groupSlot=zeros(0,1); groupAttempts=zeros(0,1); groupAirtime=zeros(0,1);
groupRecipientAttempts=zeros(0,1); groupRecipientSuccess=zeros(0,1);
groupRecipientErasure=zeros(0,1); groupRecipientCollision=zeros(0,1);
groupCollision=false(0,1);
dataStart=zeros(0,1); dataNode=zeros(0,1); dataSlot=zeros(0,1);
dataFrame=zeros(0,1); dataGroup=zeros(0,1); dataKind=strings(0,1);
dataSuccess=false(0,N); dataErasure=false(0,N); dataCollision=false(0,N);
nextDataGroup=0;

for frame=1:F
    fs=frameStart(frame);
    if K.debug.prepareTx(frame)
        sender=M.initiator;
        appendControl(frame,sender,sender,'prepare', ...
            fs+(sender-1)*Scontrol,M.prepareBytes, ...
            squeeze(T.prepareDeliveryU(frame,:,:)), ...
            probability(C,'prepareErasureProbability'));
    end
    for sender=find(K.debug.claimTx(frame,:))
        appendControl(frame,sender,sender,'claim', ...
            fs+(sender-1)*Scontrol,M.config.claimBytes, ...
            squeeze(T.claimDeliveryU(frame,:,:)), ...
            probability(C,'claimErasureProbability'));
    end
    for sender=find(K.debug.lockProofTx(frame,:))
        appendControl(frame,sender,sender,'lock-proof', ...
            fs+(sender-1)*Scontrol,M.config.lockProofBytes, ...
            squeeze(T.lockProofDeliveryU(frame,:,:)), ...
            probability(C,'lockProofErasureProbability'));
    end
    for sender=find(K.debug.quietTx(frame,:))
        appendControl(frame,sender,N+sender,'quiescent', ...
            fs+phase1Duration+(sender-1)*Scontrol,M.config.quietBytes, ...
            squeeze(T.quietDeliveryU(frame,:,:)), ...
            probability(C,'quietErasureProbability'));
    end
    for sender=find(K.debug.responseTx(frame,:))
        packetBytes=K.debug.responseBytes(frame,sender);
        appendControl(frame,sender,N+sender,'response', ...
            fs+phase1Duration+(sender-1)*Scontrol,packetBytes, ...
            squeeze(T.responseDeliveryU(frame,:,:)), ...
            probability(C,'responseErasureProbability'));
    end
    if K.debug.commitTx(frame)
        sender=M.initiator;
        appendControl(frame,sender,2*N+1,'commit', ...
            fs+phase1Duration+phase2Duration,M.config.commitBytes, ...
            squeeze(T.commitDeliveryU(frame,:,:)), ...
            probability(C,'commitErasureProbability'));
    end

    actual=logical(squeeze(K.debug.actualGraph(frame,:,:)));
    active=logical(K.debug.active(frame,:))';
    slots=K.debug.slot(frame,:)';
    for slotIndex=1:M.config.maxDataSlots
        senders=find(active&slots==slotIndex);
        if isempty(senders), continue; end
        nextDataGroup=nextDataGroup+1;
        tk=fs+dataOffset+(slotIndex-1)*Sdata;
        for sender=reshape(senders,1,[])
            dataStart(end+1,1)=tk; dataNode(end+1,1)=sender; %#ok<AGROW>
            dataSlot(end+1,1)=slotIndex; dataFrame(end+1,1)=frame; %#ok<AGROW>
            dataGroup(end+1,1)=nextDataGroup; dataKind(end+1,1)="scheduled"; %#ok<AGROW>
            dataSuccess(end+1,1:N)=false; dataErasure(end+1,1:N)=false; %#ok<AGROW>
            mask=false(1,N); peers=senders(senders~=sender);
            mask(peers)=actual(peers,sender);
            dataCollision(end+1,1:N)=mask; %#ok<AGROW>
        end
    end
end

if ~isempty(controlStart)
    [~,order]=sortrows([controlStart controlNode],[1 2]);
    controlStart=controlStart(order); controlNode=controlNode(order);
    controlSlot=controlSlot(order); controlFrame=controlFrame(order);
    controlKind=controlKind(order); controlBytes=controlBytes(order);
    controlAirtime=controlAirtime(order); groupStart=groupStart(order);
    groupEnd=groupEnd(order); groupFrame=groupFrame(order);
    groupSlot=groupSlot(order); groupAttempts=groupAttempts(order);
    groupAirtime=groupAirtime(order);
    groupRecipientAttempts=groupRecipientAttempts(order);
    groupRecipientSuccess=groupRecipientSuccess(order);
    groupRecipientErasure=groupRecipientErasure(order);
    groupRecipientCollision=groupRecipientCollision(order);
    groupCollision=groupCollision(order);
end

Q=struct('version','RECEIVER-LIFTED-CLOSURE-CONTINUOUS-v1', ...
    'horizonSec',P.horizonSec,'airtimeSec',Ddata, ...
    'controlAirtimeSec',Dcontrol,'guardSec',P.guardSec, ...
    'slotDurationSec',Sdata,'controlSlotDurationSec',Scontrol, ...
    'frameDurationSec',frameDuration,'frameStartTime',frameStart, ...
    'frameEndTime',frameEnd,'phase1DurationSec',phase1Duration, ...
    'phase2DurationSec',phase2Duration, ...
    'commitPhaseDurationSec',commitPhaseDuration, ...
    'dataStartTime',dataStart,'dataNode',dataNode,'dataSlot',dataSlot, ...
    'dataFrame',dataFrame,'dataGroup',dataGroup,'dataKind',dataKind, ...
    'dataSuccessMask',dataSuccess,'dataErasureMask',dataErasure, ...
    'dataCollisionMask',dataCollision, ...
    'dataCompletesByHorizon',true(size(dataStart)), ...
    'controlStartTime',controlStart,'controlNode',controlNode, ...
    'controlSlot',controlSlot,'controlFrame',controlFrame, ...
    'controlKind',controlKind,'controlAttemptBytes',controlBytes, ...
    'controlAttemptAirtimeSec',controlAirtime, ...
    'controlGroupStartTime',groupStart,'controlGroupEndTime',groupEnd, ...
    'controlGroupFrame',groupFrame,'controlGroupSlot',groupSlot, ...
    'controlGroupAttempts',groupAttempts, ...
    'controlGroupAirtimeSec',groupAirtime, ...
    'controlGroupRecipientAttempts',groupRecipientAttempts, ...
    'controlGroupRecipientSuccess',groupRecipientSuccess, ...
    'controlGroupRecipientErasure',groupRecipientErasure, ...
    'controlGroupRecipientCollision',groupRecipientCollision, ...
    'controlGroupCollision',groupCollision,'kernel',K, ...
    'kernelConfigHash',configHashScalar(struct('migration',M,'kernel',C, ...
    'physical',P)),'kernelTraceHash',T.hashExact, ...
    'futureRandomReads',K.futureRandomReads, ...
    'receiverTruthDecisionReads',K.receiverTruthDecisionReads);
Q.expectedManagementAttempts=sum(groupAttempts);
Q.expectedManagementAirtime=sum(groupAirtime);
Q.expectedManagementRecipientAttempts=sum(groupRecipientAttempts);
Q.expectedManagementRecipientSuccess=sum(groupRecipientSuccess);
Q.expectedManagementRecipientErasure=sum(groupRecipientErasure);
Q.expectedManagementRecipientCollision=sum(groupRecipientCollision);
Q.expectedDataCollisionFrames=numel(unique(dataFrame(any(dataCollision,2))));
Q.expectedDataRecipientSuccess=nnz(dataSuccess);
Q.expectedDataRecipientErasure=nnz(dataErasure);
Q.expectedDataRecipientCollision=nnz(dataCollision);
Q.expectedCompletedDataCollisionFrames=Q.expectedDataCollisionFrames;
Q.expectedCompletedDataRecipientSuccess=Q.expectedDataRecipientSuccess;
Q.expectedCompletedDataRecipientErasure=Q.expectedDataRecipientErasure;
Q.expectedCompletedDataRecipientCollision=Q.expectedDataRecipientCollision;
Q.firstConvergenceTimeSec=NaN;
if K.allAffectedReactivated
    frame=find(all(~K.debug.suppressed(:,M.affectedNodes),2)& ...
        (1:F)'>=K.graphActivationFrame,1);
    if ~isempty(frame), Q.firstConvergenceTimeSec=frameEnd(frame); end
end
Q.logicalOpportunityHashExact=realizationHash([dataFrame;dataSlot;dataNode; ...
    controlFrame;controlSlot;controlNode;controlBytes]);
Q.hashExact=realizationHash([P.horizonSec;P.guardSec;P.dataBytes; ...
    frameStart;frameEnd;dataStart;dataNode;dataSlot;dataFrame;dataGroup; ...
    double(dataCollision(:));controlStart;controlNode;controlSlot; ...
    controlFrame;controlBytes;controlAirtime;groupStart;groupEnd; ...
    groupRecipientAttempts;groupRecipientSuccess;groupRecipientErasure; ...
    K.stateHashExact;T.hashExact;Q.kernelConfigHash]);
validateSchedule(Q,K,M,C,P);

    function appendControl(frameIndex,sender,slotIndex,kind,tk,packetBytes,draw,p)
        if packetBytes<=0||packetBytes>M.config.maxControlPacketBytes
            error('buildReceiverLiftedClosureContinuousSchedule: payload.');
        end
        duration=8*packetBytes/rate;
        receivers=find(reach(:,sender));
        nSuccess=nnz(draw(receivers,sender)>p);
        nAttempts=numel(receivers); nErasure=nAttempts-nSuccess;
        controlStart(end+1,1)=tk; controlNode(end+1,1)=sender;
        controlSlot(end+1,1)=slotIndex; controlFrame(end+1,1)=frameIndex;
        controlKind(end+1,1)=string(kind); controlBytes(end+1,1)=packetBytes;
        controlAirtime(end+1,1)=duration; groupStart(end+1,1)=tk;
        groupEnd(end+1,1)=tk+duration; groupFrame(end+1,1)=frameIndex;
        groupSlot(end+1,1)=slotIndex; groupAttempts(end+1,1)=1;
        groupAirtime(end+1,1)=duration;
        groupRecipientAttempts(end+1,1)=nAttempts;
        groupRecipientSuccess(end+1,1)=nSuccess;
        groupRecipientErasure(end+1,1)=nErasure;
        groupRecipientCollision(end+1,1)=0; groupCollision(end+1,1)=false;
    end

end


function validateSchedule(Q,K,M,C,P)

if numel(Q.controlStartTime)~=K.controlAttempts|| ...
        sum(Q.controlAttemptBytes)~=K.controlBytes|| ...
        abs(sum(Q.controlAttemptAirtimeSec)-K.controlAirtimeSec)>1e-12|| ...
        sum(Q.controlGroupRecipientAttempts)~=K.recipientAttempts|| ...
        sum(Q.controlGroupRecipientSuccess)~=K.recipientSuccess|| ...
        sum(Q.controlGroupRecipientErasure)~=K.recipientErasure
    error('buildReceiverLiftedClosureContinuousSchedule: accounting.');
end
if Q.expectedDataCollisionFrames~=K.scheduledCollisionFrames
    error('buildReceiverLiftedClosureContinuousSchedule: collision count.');
end
if any(Q.controlAttemptBytes>M.config.maxControlPacketBytes)|| ...
        any(diff(Q.controlStartTime)<-1e-12)||any(diff(Q.dataStartTime)<-1e-12)
    error('buildReceiverLiftedClosureContinuousSchedule: ordering.');
end
for frame=1:C.maxFrames
    control=Q.controlFrame==frame; data=Q.dataFrame==frame;
    if any(control)&&any(data)&&max(Q.controlStartTime(control)+ ...
            Q.controlAttemptAirtimeSec(control))> ...
            min(Q.dataStartTime(data))+1e-12
        error('buildReceiverLiftedClosureContinuousSchedule: overlap.');
    end
end
if max(Q.frameEndTime)>P.horizonSec+1e-12
    error('buildReceiverLiftedClosureContinuousSchedule: horizon overflow.');
end

end


function p=probability(C,name)
p=0; if isfield(C,name), p=C.(name); end
end


function value=configHashScalar(S)
[value,~]=configHash(S);
end
