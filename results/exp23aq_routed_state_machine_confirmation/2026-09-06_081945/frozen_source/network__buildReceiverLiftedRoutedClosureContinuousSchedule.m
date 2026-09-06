function Q=buildReceiverLiftedRoutedClosureContinuousSchedule( ...
    M,C,T,P,routeSpec)
%BUILDRECEIVERLIFTEDROUTEDCLOSURECONTINUOUSSCHEDULE Map relays to one PHY.

required={'guardSec','dataBytes','horizonSec'};
if ~isstruct(P)||~isscalar(P)||~all(isfield(P,required))|| ...
        any(~isfinite([P.guardSec P.dataBytes P.horizonSec]))|| ...
        P.guardSec<0||P.dataBytes<1||P.dataBytes~=floor(P.dataBytes)|| ...
        P.horizonSec<=0
    error('buildReceiverLiftedRoutedClosureContinuousSchedule: PHY spec.');
end
K=simulateReceiverLiftedRoutedClosureMigration(M,C,T,routeSpec);
N=M.N; F=C.maxFrames; rate=C.phyRateBps;
dataAirtime=8*P.dataBytes/rate;
dataSlotDuration=dataAirtime+P.guardSec;

controlStart=zeros(0,1); controlNode=zeros(0,1);
controlSlot=zeros(0,1); controlFrame=zeros(0,1);
controlKind=strings(0,1); controlBytes=zeros(0,1);
controlAirtime=zeros(0,1); controlPacketSource=zeros(0,1);
controlPacketId=strings(0,1);
groupStart=zeros(0,1); groupEnd=zeros(0,1); groupFrame=zeros(0,1);
groupSlot=zeros(0,1); groupAttempts=zeros(0,1);
groupAirtime=zeros(0,1); groupBytes=zeros(0,1);
groupRecipientAttempts=zeros(0,1); groupRecipientSuccess=zeros(0,1);
groupRecipientErasure=zeros(0,1); groupRecipientCollision=zeros(0,1);
groupCollision=false(0,1);
dataStart=zeros(0,1); dataNode=zeros(0,1); dataSlot=zeros(0,1);
dataFrame=zeros(0,1); dataGroup=zeros(0,1); dataKind=strings(0,1);
dataSuccess=false(0,N); dataErasure=false(0,N); dataCollision=false(0,N);
frameStart=zeros(F,1); frameEnd=zeros(F,1); frameControlDuration=zeros(F,1);
nextDataGroup=0; nextControlSlot=0; time=0;

for frame=1:F
    frameStart(frame)=time; controlOffset=0;
    logs=find([K.bundleLog.frame]==frame);
    for logIndex=reshape(logs,1,[])
        B=K.bundleLog(logIndex);
        if B.routedPacketCount==0, continue; end
        S=B.schedule; replay=B.replay; bytes=B.packetBytes;
        draws=B.linkUniform; slotDuration= ...
            8*B.maximumPacketBytes/rate+P.guardSec;
        for slotIndex=1:S.reservedSlotCount
            scheduled=find(S.slotTaskMask(slotIndex,:));
            activeTasks=scheduled(replay.taskActive(scheduled));
            if isempty(activeTasks), continue; end
            nextControlSlot=nextControlSlot+1;
            tk=time+controlOffset+(slotIndex-1)*slotDuration;
            attempts=0; byteCount=0; airtime=0;
            recipientAttempts=0; recipientSuccess=0;
            recipientErasure=0; recipientCollision=0;
            maximumEnd=tk;
            for task=reshape(activeTasks,1,[])
                packetIndex=S.taskPacket(task); sender=S.taskSender(task);
                packetBytes=bytes(packetIndex);
                duration=8*packetBytes/rate;
                repetition=slotIndex-S.taskStartSlot(task)+1;
                receivers=find(S.taskChildren(:,task));
                successes=0; erasures=0; collisions=0;
                for receiver=reshape(receivers,1,[])
                    otherTasks=activeTasks(activeTasks~=task);
                    otherSenders=S.taskSender(otherTasks);
                    detectable=reshape(S.physicalInterference( ...
                        receiver,otherSenders)|S.directReach( ...
                        receiver,otherSenders),[],1);
                    collision=any(otherSenders==receiver|detectable);
                    if collision
                        collisions=collisions+1;
                    elseif draws{packetIndex}(receiver,sender,repetition)> ...
                            routeSpec.linkErasureProbability
                        successes=successes+1;
                    else
                        erasures=erasures+1;
                    end
                end
                controlStart(end+1,1)=tk; %#ok<AGROW>
                controlNode(end+1,1)=sender; %#ok<AGROW>
                controlSlot(end+1,1)=nextControlSlot; %#ok<AGROW>
                controlFrame(end+1,1)=frame; %#ok<AGROW>
                controlKind(end+1,1)=B.packetKind(packetIndex); %#ok<AGROW>
                controlBytes(end+1,1)=packetBytes; %#ok<AGROW>
                controlAirtime(end+1,1)=duration; %#ok<AGROW>
                controlPacketSource(end+1,1)=B.packetSender(packetIndex); %#ok<AGROW>
                controlPacketId(end+1,1)= ...
                    S.packetId(packetIndex); %#ok<AGROW>
                attempts=attempts+1; byteCount=byteCount+packetBytes;
                airtime=airtime+duration;
                recipientAttempts=recipientAttempts+numel(receivers);
                recipientSuccess=recipientSuccess+successes;
                recipientErasure=recipientErasure+erasures;
                recipientCollision=recipientCollision+collisions;
                maximumEnd=max(maximumEnd,tk+duration);
            end
            groupStart(end+1,1)=tk; groupEnd(end+1,1)=maximumEnd; %#ok<AGROW>
            groupFrame(end+1,1)=frame; %#ok<AGROW>
            groupSlot(end+1,1)=nextControlSlot; %#ok<AGROW>
            groupAttempts(end+1,1)=attempts; %#ok<AGROW>
            groupAirtime(end+1,1)=airtime; %#ok<AGROW>
            groupBytes(end+1,1)=byteCount; %#ok<AGROW>
            groupRecipientAttempts(end+1,1)=recipientAttempts; %#ok<AGROW>
            groupRecipientSuccess(end+1,1)=recipientSuccess; %#ok<AGROW>
            groupRecipientErasure(end+1,1)=recipientErasure; %#ok<AGROW>
            groupRecipientCollision(end+1,1)=recipientCollision; %#ok<AGROW>
            groupCollision(end+1,1)=recipientCollision>0; %#ok<AGROW>
        end
        controlOffset=controlOffset+S.reservedSlotCount*slotDuration;
    end
    frameControlDuration(frame)=controlOffset;
    actual=logical(squeeze(K.debug.actualGraph(frame,:,:)));
    active=logical(K.debug.active(frame,:))';
    slots=K.debug.slot(frame,:)';
    for dataSlotIndex=1:M.config.maxDataSlots
        senders=find(active&slots==dataSlotIndex);
        if isempty(senders), continue; end
        nextDataGroup=nextDataGroup+1;
        tk=time+controlOffset+(dataSlotIndex-1)*dataSlotDuration;
        for sender=reshape(senders,1,[])
            dataStart(end+1,1)=tk; dataNode(end+1,1)=sender; %#ok<AGROW>
            dataSlot(end+1,1)=dataSlotIndex; dataFrame(end+1,1)=frame; %#ok<AGROW>
            dataGroup(end+1,1)=nextDataGroup; %#ok<AGROW>
            dataKind(end+1,1)="scheduled"; %#ok<AGROW>
            dataSuccess(end+1,1:N)=false; dataErasure(end+1,1:N)=false; %#ok<AGROW>
            peers=senders(senders~=sender); mask=false(1,N);
            mask(peers)=actual(peers,sender);
            dataCollision(end+1,1:N)=mask; %#ok<AGROW>
        end
    end
    time=time+controlOffset+M.config.maxDataSlots*dataSlotDuration;
    frameEnd(frame)=time;
end
if time>P.horizonSec+1e-12
    error(['buildReceiverLiftedRoutedClosureContinuousSchedule: routed ' ...
        'transaction exceeds horizon.']);
end

Q=struct('version','RECEIVER-LIFTED-ROUTED-CLOSURE-CONTINUOUS-v1', ...
    'horizonSec',P.horizonSec,'airtimeSec',dataAirtime, ...
    'controlAirtimeSec',8*M.config.maxControlPacketBytes/rate, ...
    'guardSec',P.guardSec,'slotDurationSec',dataSlotDuration, ...
    'controlSlotDurationSec',NaN,'frameDurationSec',NaN, ...
    'frameStartTime',frameStart,'frameEndTime',frameEnd, ...
    'frameControlDurationSec',frameControlDuration, ...
    'phase1DurationSec',NaN,'phase2DurationSec',NaN, ...
    'commitPhaseDurationSec',NaN, ...
    'dataStartTime',dataStart,'dataNode',dataNode,'dataSlot',dataSlot, ...
    'dataFrame',dataFrame,'dataGroup',dataGroup,'dataKind',dataKind, ...
    'dataSuccessMask',dataSuccess,'dataErasureMask',dataErasure, ...
    'dataCollisionMask',dataCollision, ...
    'dataCompletesByHorizon',true(size(dataStart)), ...
    'controlStartTime',controlStart,'controlNode',controlNode, ...
    'controlSlot',controlSlot,'controlFrame',controlFrame, ...
    'controlKind',controlKind,'controlAttemptBytes',controlBytes, ...
    'controlAttemptAirtimeSec',controlAirtime, ...
    'controlPacketSource',controlPacketSource, ...
    'controlPacketId',controlPacketId, ...
    'controlGroupStartTime',groupStart,'controlGroupEndTime',groupEnd, ...
    'controlGroupFrame',groupFrame,'controlGroupSlot',groupSlot, ...
    'controlGroupAttempts',groupAttempts, ...
    'controlGroupBytes',groupBytes, ...
    'controlGroupAirtimeSec',groupAirtime, ...
    'controlGroupRecipientAttempts',groupRecipientAttempts, ...
    'controlGroupRecipientSuccess',groupRecipientSuccess, ...
    'controlGroupRecipientErasure',groupRecipientErasure, ...
    'controlGroupRecipientCollision',groupRecipientCollision, ...
    'controlGroupCollision',groupCollision,'kernel',K, ...
    'kernelConfigHash',configHashScalar(struct('migration',M, ...
    'kernel',C,'physical',P,'route',routeSpec)), ...
    'kernelTraceHash',T.hashExact,'futureRandomReads',K.futureRandomReads, ...
    'receiverTruthDecisionReads',K.receiverTruthDecisionReads);
Q.expectedManagementAttempts=sum(groupAttempts);
Q.expectedManagementBytes=sum(groupBytes);
Q.controlPhyRateBps=rate;
Q.expectedManagementAirtime=8*Q.expectedManagementBytes/rate;
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
    complete=find(all(~K.debug.suppressed(:,M.affectedNodes),2)& ...
        (1:F)'>=K.graphActivationFrame,1);
    if ~isempty(complete), Q.firstConvergenceTimeSec=frameEnd(complete); end
end
Q.logicalOpportunityHashExact=realizationHash([dataFrame;dataSlot;dataNode; ...
    controlFrame;controlSlot;controlNode;controlBytes;controlPacketSource]);
Q.hashExact=realizationHash([P.horizonSec;P.guardSec;P.dataBytes; ...
    frameStart;frameEnd;frameControlDuration;dataStart;dataNode;dataSlot; ...
    dataFrame;dataGroup;double(dataCollision(:));controlStart;controlNode; ...
    controlSlot;controlFrame;controlBytes;controlAirtime; ...
    controlPacketSource;groupStart;groupEnd;groupBytes; ...
    groupRecipientAttempts;groupRecipientSuccess;groupRecipientErasure; ...
    groupRecipientCollision;K.stateHashExact;T.hashExact;Q.kernelConfigHash]);
validateSchedule(Q,K,P,time);

end


function validateSchedule(Q,K,P,totalDuration)

if Q.expectedManagementAttempts~=K.physicalControlAttempts|| ...
        Q.expectedManagementBytes~=K.physicalControlBytes|| ...
        Q.expectedManagementAirtime~=K.physicalControlAirtimeSec|| ...
        Q.expectedManagementRecipientCollision~=K.routeCollisionRecipients
    error('buildReceiverLiftedRoutedClosureContinuousSchedule: accounting.');
end
if any(Q.controlAttemptBytes<1)|| ...
        any(Q.controlAttemptBytes~=floor(Q.controlAttemptBytes))|| ...
        any(diff(Q.controlStartTime)<-1e-12)|| ...
        any(diff(Q.dataStartTime)<-1e-12)|| ...
        any(Q.controlGroupCollision)|| ...
        totalDuration>P.horizonSec+1e-12
    error('buildReceiverLiftedRoutedClosureContinuousSchedule: schedule.');
end
for frame=1:numel(Q.frameStartTime)
    control=Q.controlFrame==frame; data=Q.dataFrame==frame;
    if any(control)&&any(data)&&max(Q.controlStartTime(control)+ ...
            Q.controlAttemptAirtimeSec(control))> ...
            min(Q.dataStartTime(data))+1e-12
        error('buildReceiverLiftedRoutedClosureContinuousSchedule: overlap.');
    end
end

end


function value=configHashScalar(S)

[value,~]=configHash(S);

end
