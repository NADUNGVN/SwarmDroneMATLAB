function Q=buildLocalUnionMigrationContinuousSchedule(M,C,T,P)
%BUILDLOCALUNIONMIGRATIONCONTINUOUSSCHEDULE Map migration to one PHY.

required={'guardSec','dataBytes','horizonSec'};
if ~isstruct(P) || ~all(isfield(P,required)) || ...
        any(~isfinite([P.guardSec P.dataBytes P.horizonSec])) || ...
        P.guardSec<0 || P.dataBytes<=0 || P.dataBytes~=floor(P.dataBytes) || ...
        P.horizonSec<=0
    error('buildLocalUnionMigrationContinuousSchedule: invalid physical spec.');
end
K=simulateLocalUnionGraphMigration(M,C,T);
N=M.N; F=C.maxFrames; rate=C.phyRateBps;
Dcontrol=8*M.config.maxControlPacketBytes/rate;
Ddata=8*P.dataBytes/rate;
Scontrol=Dcontrol+P.guardSec; Sdata=Ddata+P.guardSec;
claimPhaseDuration=N*Scontrol;
responsePhaseDuration=N*Scontrol;
dataOffset=claimPhaseDuration+responsePhaseDuration;
frameDuration=dataOffset+M.config.maxDataSlots*Sdata;
frameStart=(0:F-1)'*frameDuration;
frameEnd=frameStart+frameDuration;
if frameEnd(end)>P.horizonSec+1e-12
    error('buildLocalUnionMigrationContinuousSchedule: horizon too short.');
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
    for sender=find(K.debug.revokeTx(frame,:))
        appendControl(frame,sender,sender,'revoke', ...
            fs+(sender-1)*Scontrol,M.config.revokeBytes, ...
            squeeze(T.revokeDeliveryU(frame,:,:)), ...
            probability(C,'revokeErasureProbability'));
    end
    if K.debug.claimTx(frame)
        sender=M.transitionNode;
        appendControl(frame,sender,sender,'claim', ...
            fs+(sender-1)*Scontrol,M.config.claimBytes, ...
            squeeze(T.claimDeliveryU(frame,:,:)), ...
            probability(C,'claimErasureProbability'));
    end
    for sender=find(K.debug.lockProofTx(frame,:))
        appendControl(frame,sender,sender,'lock-proof', ...
            fs+(sender-1)*Scontrol,M.config.claimBytes, ...
            squeeze(T.lockProofDeliveryU(frame,:,:)), ...
            probability(C,'lockProofErasureProbability'));
    end
    for witness=find(K.debug.responseTx(frame,:))
        bytes=K.debug.responseBytes(frame,witness);
        appendControl(frame,witness,N+witness,'response', ...
            fs+claimPhaseDuration+(witness-1)*Scontrol,bytes, ...
            squeeze(T.responseDeliveryU(frame,:,:)), ...
            probability(C,'responseErasureProbability'));
    end

    actual=logical(squeeze(T.actualGraph(frame,:,:)));
    active=logical(K.debug.active(frame,:))';
    slots=K.debug.slot(frame,:)';
    for slot=1:M.config.maxDataSlots
        senders=find(active & slots==slot);
        if isempty(senders), continue; end
        nextDataGroup=nextDataGroup+1;
        tk=fs+dataOffset+(slot-1)*Sdata;
        for sender=reshape(senders,1,[])
            dataStart(end+1,1)=tk; dataNode(end+1,1)=sender; %#ok<AGROW>
            dataSlot(end+1,1)=slot; dataFrame(end+1,1)=frame; %#ok<AGROW>
            dataGroup(end+1,1)=nextDataGroup; %#ok<AGROW>
            dataKind(end+1,1)="scheduled"; %#ok<AGROW>
            dataSuccess(end+1,1:N)=false; dataErasure(end+1,1:N)=false; %#ok<AGROW>
            mask=false(1,N);
            peers=senders(senders~=sender);
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

Q=struct('version','LOCAL-UNION-MIGRATION-CONTINUOUS-v1', ...
    'horizonSec',P.horizonSec,'airtimeSec',Ddata, ...
    'controlAirtimeSec',Dcontrol,'guardSec',P.guardSec, ...
    'slotDurationSec',Sdata,'controlSlotDurationSec',Scontrol, ...
    'frameDurationSec',frameDuration,'frameStartTime',frameStart, ...
    'frameEndTime',frameEnd,'claimPhaseDurationSec',claimPhaseDuration, ...
    'responsePhaseDurationSec',responsePhaseDuration, ...
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
    'receiverTruthDecisionReads',K.receiverTruthReads);
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
if K.reacquired
    Q.firstConvergenceTimeSec=frameEnd(K.firstReacquiredFrame);
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

    function appendControl(frameIndex,sender,slotIndex,kind,tk,bytes,draw,p)
        if bytes<=0 || bytes>M.config.maxControlPacketBytes
            error('buildLocalUnionMigrationContinuousSchedule: invalid payload.');
        end
        duration=8*bytes/rate;
        receivers=find(reach(:,sender));
        success=nnz(draw(receivers,sender)>p);
        attempts=numel(receivers); erasures=attempts-success;
        controlStart(end+1,1)=tk;
        controlNode(end+1,1)=sender;
        controlSlot(end+1,1)=slotIndex;
        controlFrame(end+1,1)=frameIndex;
        controlKind(end+1,1)=string(kind);
        controlBytes(end+1,1)=bytes;
        controlAirtime(end+1,1)=duration;
        groupStart(end+1,1)=tk; groupEnd(end+1,1)=tk+duration;
        groupFrame(end+1,1)=frameIndex; groupSlot(end+1,1)=slotIndex;
        groupAttempts(end+1,1)=1; groupAirtime(end+1,1)=duration;
        groupRecipientAttempts(end+1,1)=attempts;
        groupRecipientSuccess(end+1,1)=success;
        groupRecipientErasure(end+1,1)=erasures;
        groupRecipientCollision(end+1,1)=0; groupCollision(end+1,1)=false;
    end

end


function validateSchedule(Q,K,M,C,P)

if numel(Q.controlStartTime)~=K.controlAttempts || ...
        sum(Q.controlAttemptBytes)~=K.controlBytes || ...
        abs(sum(Q.controlAttemptAirtimeSec)-K.controlAirtimeSec)>1e-12 || ...
        sum(Q.controlGroupRecipientAttempts)~=K.recipientAttempts || ...
        sum(Q.controlGroupRecipientSuccess)~=K.recipientSuccess || ...
        sum(Q.controlGroupRecipientErasure)~=K.recipientErasure
    error('buildLocalUnionMigrationContinuousSchedule: accounting mismatch.');
end
if Q.expectedDataCollisionFrames~=K.scheduledCollisionFrames
    error('buildLocalUnionMigrationContinuousSchedule: collision mismatch.');
end
if any(Q.controlAttemptBytes>M.config.maxControlPacketBytes) || ...
        any(diff(Q.controlStartTime)<-1e-12) || ...
        any(diff(Q.dataStartTime)<-1e-12)
    error('buildLocalUnionMigrationContinuousSchedule: malformed ordering.');
end
for frame=1:C.maxFrames
    control=Q.controlFrame==frame; data=Q.dataFrame==frame;
    if any(control) && any(data) && max(Q.controlStartTime(control)+ ...
            Q.controlAttemptAirtimeSec(control))>min(Q.dataStartTime(data))+1e-12
        error('buildLocalUnionMigrationContinuousSchedule: cross-plane overlap.');
    end
end
if max(Q.frameEndTime)>P.horizonSec+1e-12
    error('buildLocalUnionMigrationContinuousSchedule: horizon overflow.');
end

end


function p=probability(C,name)

p=0; if isfield(C,name), p=C.(name); end

end


function value=configHashScalar(S)

[value,~]=configHash(S);

end
