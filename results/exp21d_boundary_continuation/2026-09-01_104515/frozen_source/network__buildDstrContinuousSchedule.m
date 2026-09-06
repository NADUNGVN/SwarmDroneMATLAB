function schedule=buildDstrContinuousSchedule(kernelCfg,kernelTrace,horizonSec)
%BUILDDSTRCONTINUOUSSCHEDULE Map causal D-STR logical frames to physical time.
%
% schedule=buildDstrContinuousSchedule(kernelCfg,kernelTrace,horizonSec)
%
% The complete kernel may be evaluated ahead of the closed-loop replay because
% it is independent of controller state.  Consumers must nevertheless advance
% the returned DATA and management cursors monotonically and expose only starts
% that are due on the current event interval.

if ~isscalar(horizonSec) || ~isfinite(horizonSec) || horizonSec<=0
    error('buildDstrContinuousSchedule: horizonSec must be positive finite.');
end

kernel=simulateDstrScheduling(kernelCfg,kernelTrace);
required={'txTG','txTGn','txTS','txTSo','txTSn','txSlotThis', ...
    'dataSuccess','dataErasure','dataCollision'};
for k=1:numel(required)
    if ~isfield(kernel.debug,required{k})
        error('buildDstrContinuousSchedule: kernel debug lacks %s.', ...
            required{k});
    end
end

airtime=8*kernelCfg.frameBytes/kernelCfg.phyRateBps;
slotDuration=airtime+kernelCfg.guardSec;
F=numel(kernel.frameLog);
frameStart=zeros(F,1);
frameEnd=zeros(F,1);
for frame=1:F
    if frame>1, frameStart(frame)=frameEnd(frame-1); end
    frameEnd(frame)=frameStart(frame)+ ...
        (5+kernel.frameLog(frame).maxLocalDataSlots)*slotDuration;
end
if frameEnd(end)<horizonSec-1e-12
    error(['buildDstrContinuousSchedule: maxFrames covers %.6g s, shorter ' ...
        'than the requested %.6g s horizon.'],frameEnd(end),horizonSec);
end

controlMasks=cat(3,kernel.debug.txTG,kernel.debug.txTGn, ...
    kernel.debug.txTS,kernel.debug.txTSo,kernel.debug.txTSn);
controlStart=zeros(0,1);
controlNode=zeros(0,1);
controlSlot=zeros(0,1,'uint8');
controlFrame=zeros(0,1);
controlGroupStart=zeros(0,1);
controlGroupFrame=zeros(0,1);
controlGroupSlot=zeros(0,1,'uint8');
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
dataSuccessMask=false(0,kernelCfg.N);
dataErasureMask=false(0,kernelCfg.N);
dataCollisionMask=false(0,kernelCfg.N);

usedFrames=find(frameStart<horizonSec-1e-12);
prefixRows=kernel.frameLog(usedFrames);
prefixDisagreement=max([prefixRows.maxLocalDataSlots]- ...
    [prefixRows.minLocalDataSlots]);
for frame=reshape(usedFrames,1,[])
    for slot=1:5
        tk=frameStart(frame)+(slot-1)*slotDuration;
        if tk>=horizonSec-1e-12, continue; end
        nodes=find(controlMasks(frame,:,slot));
        count=numel(nodes);
        if count==0, continue; end
        controlStart(end+1:end+count,1)=tk;
        controlNode(end+1:end+count,1)=nodes(:);
        controlSlot(end+1:end+count,1)=uint8(slot);
        controlFrame(end+1:end+count,1)=frame;
        outcome=managementOutcome(nodes,frame,slot,kernelCfg,kernelTrace);
        controlGroupStart(end+1,1)=tk; %#ok<AGROW>
        controlGroupFrame(end+1,1)=frame; %#ok<AGROW>
        controlGroupSlot(end+1,1)=uint8(slot); %#ok<AGROW>
        controlGroupAttempts(end+1,1)=count; %#ok<AGROW>
        controlGroupRecipientAttempts(end+1,1)= ...
            outcome.recipientAttempts; %#ok<AGROW>
        controlGroupRecipientSuccess(end+1,1)= ...
            outcome.recipientSuccess; %#ok<AGROW>
        controlGroupRecipientErasure(end+1,1)= ...
            outcome.recipientErasure; %#ok<AGROW>
        controlGroupRecipientCollision(end+1,1)= ...
            outcome.recipientCollision; %#ok<AGROW>
        controlGroupCollision(end+1,1)=outcome.collision; %#ok<AGROW>
    end
    txSlot=kernel.debug.txSlotThis(frame,:);
    nodes=find(txSlot>0);
    for node=reshape(nodes,1,[])
        slot=txSlot(node);
        tk=frameStart(frame)+(5+slot-1)*slotDuration;
        if tk>=horizonSec-1e-12, continue; end
        dataStart(end+1,1)=tk; %#ok<AGROW>
        dataNode(end+1,1)=node; %#ok<AGROW>
        dataSlot(end+1,1)=slot; %#ok<AGROW>
        dataFrame(end+1,1)=frame; %#ok<AGROW>
        dataSuccessMask(end+1,:)=reshape( ...
            kernel.debug.dataSuccess(frame,:,node),1,[]); %#ok<AGROW>
        dataErasureMask(end+1,:)=reshape( ...
            kernel.debug.dataErasure(frame,:,node),1,[]); %#ok<AGROW>
        dataCollisionMask(end+1,:)=reshape( ...
            kernel.debug.dataCollision(frame,:,node),1,[]); %#ok<AGROW>
    end
end

if ~isempty(dataStart)
    [~,order]=sortrows([dataStart dataNode],[1 2]);
    dataStart=dataStart(order);
    dataNode=dataNode(order);
    dataSlot=dataSlot(order);
    dataFrame=dataFrame(order);
    dataSuccessMask=dataSuccessMask(order,:);
    dataErasureMask=dataErasureMask(order,:);
    dataCollisionMask=dataCollisionMask(order,:);
end
if ~isempty(controlStart)
    [~,order]=sortrows([controlStart double(controlSlot) controlNode],[1 2 3]);
    controlStart=controlStart(order);
    controlNode=controlNode(order);
    controlSlot=controlSlot(order);
    controlFrame=controlFrame(order);
end
expectedDataCollisionFrames=dataCollisionFrames( ...
    dataStart,dataNode,kernelCfg);
dataCompletesByHorizon=dataStart+airtime<=horizonSec+1e-12;
expectedCompletedDataCollisionFrames=dataCollisionFrames( ...
    dataStart(dataCompletesByHorizon),dataNode(dataCompletesByHorizon), ...
    kernelCfg);

schedule=struct();
schedule.version='DSTR-CONTINUOUS-SCHEDULE-v1';
schedule.horizonSec=horizonSec;
schedule.airtimeSec=airtime;
schedule.guardSec=kernelCfg.guardSec;
schedule.slotDurationSec=slotDuration;
schedule.frameStartTime=frameStart(usedFrames);
schedule.frameEndTime=frameEnd(usedFrames);
schedule.maxPrefixFrameDisagreement=prefixDisagreement;
schedule.prefixFrameAgreement=prefixDisagreement==0;
schedule.dataStartTime=dataStart;
schedule.dataNode=dataNode;
schedule.dataSlot=dataSlot;
schedule.dataFrame=dataFrame;
schedule.dataSuccessMask=dataSuccessMask;
schedule.dataErasureMask=dataErasureMask;
schedule.dataCollisionMask=dataCollisionMask;
schedule.dataCompletesByHorizon=dataCompletesByHorizon;
schedule.controlStartTime=controlStart;
schedule.controlNode=controlNode;
schedule.controlSlot=controlSlot;
schedule.controlFrame=controlFrame;
schedule.controlType={'TG','TGn','TS','TSo','TSn'};
schedule.controlGroupStartTime=controlGroupStart;
schedule.controlGroupFrame=controlGroupFrame;
schedule.controlGroupSlot=controlGroupSlot;
schedule.controlGroupAttempts=controlGroupAttempts;
schedule.controlGroupRecipientAttempts=controlGroupRecipientAttempts;
schedule.controlGroupRecipientSuccess=controlGroupRecipientSuccess;
schedule.controlGroupRecipientErasure=controlGroupRecipientErasure;
schedule.controlGroupRecipientCollision=controlGroupRecipientCollision;
schedule.controlGroupCollision=controlGroupCollision;
schedule.managementReach=logical(kernelCfg.managementReach);
schedule.neighborGraph=logical(kernelCfg.neighborGraph);
schedule.interferenceMatrix=logical(kernelCfg.interferenceMatrix);
schedule.kernel=kernel;
schedule.kernelConfigHash=kernel.configHash;
schedule.kernelTraceHash=kernel.traceHash;
schedule.futureRandomReads=kernel.futureRandomReads;
schedule.receiverTruthDecisionReads=kernel.receiverTruthDecisionReads;
schedule.expectedDataCollisionFrames=expectedDataCollisionFrames;
schedule.expectedDataRecipientSuccess=nnz(dataSuccessMask);
schedule.expectedDataRecipientErasure=nnz(dataErasureMask);
schedule.expectedDataRecipientCollision=nnz(dataCollisionMask);
schedule.expectedCompletedDataCollisionFrames= ...
    expectedCompletedDataCollisionFrames;
schedule.expectedCompletedDataRecipientSuccess= ...
    nnz(dataSuccessMask(dataCompletesByHorizon,:));
schedule.expectedCompletedDataRecipientErasure= ...
    nnz(dataErasureMask(dataCompletesByHorizon,:));
schedule.expectedCompletedDataRecipientCollision= ...
    nnz(dataCollisionMask(dataCompletesByHorizon,:));
schedule.firstConvergenceTimeSec=NaN;
if isfinite(kernel.firstConvergenceFrame) && ...
        kernel.firstConvergenceFrame<=numel(schedule.frameEndTime)
    schedule.firstConvergenceTimeSec= ...
        schedule.frameEndTime(kernel.firstConvergenceFrame);
end
schedule.hashExact=realizationHash([horizonSec;airtime;kernelCfg.guardSec; ...
    frameStart(usedFrames);frameEnd(usedFrames);prefixDisagreement; ...
    dataStart;dataNode; ...
    dataSlot;dataFrame;double(dataSuccessMask(:)); ...
    double(dataErasureMask(:));double(dataCollisionMask(:)); ...
    double(dataCompletesByHorizon); ...
    controlStart;controlNode;double(controlSlot); ...
    controlFrame;controlGroupStart;controlGroupFrame; ...
    double(controlGroupSlot);controlGroupAttempts; ...
    controlGroupRecipientAttempts;controlGroupRecipientSuccess; ...
    controlGroupRecipientErasure;controlGroupRecipientCollision; ...
    double(controlGroupCollision);expectedDataCollisionFrames; ...
    expectedCompletedDataCollisionFrames; ...
    kernel.configHash;kernel.traceHash]);

validateSchedule(schedule,kernelCfg);

end


function count=dataCollisionFrames(startTime,node,C)

count=0;
first=1;
tol=1e-12;
while first<=numel(startTime)
    last=first;
    while last<numel(startTime) && ...
            abs(startTime(last+1)-startTime(first))<=tol
        last=last+1;
    end
    tx=reshape(node(first:last),1,[]);
    txMask=false(C.N,1);
    txMask(tx)=true;
    for sender=tx
        receivers=find(C.neighborGraph(:,sender) & ~txMask);
        senderCollision=false;
        for receiver=reshape(receivers,1,[])
            other=tx(tx~=sender & (C.interferenceMatrix(receiver,tx) | ...
                C.neighborGraph(receiver,tx)));
            if ~isempty(other), senderCollision=true; break; end
        end
        count=count+double(senderCollision);
    end
    first=last+1;
end

end


function a=managementOutcome(tx,frame,slot,C,T)

N=C.N;
tx=tx(:)';
txMask=false(N,1);
txMask(tx)=true;
draws=squeeze(T.managementDeliveryU(frame,slot,:,:));
a=struct('recipientAttempts',0,'recipientSuccess',0, ...
    'recipientErasure',0,'recipientCollision',0,'collision',false);
for sender=tx
    a.recipientAttempts=a.recipientAttempts+ ...
        nnz(C.managementReach(:,sender) & ~txMask);
end
for receiver=1:N
    if txMask(receiver), continue; end
    intended=tx(C.managementReach(receiver,tx));
    detectable=tx(C.interferenceMatrix(receiver,tx) | ...
        C.managementReach(receiver,tx));
    if isempty(detectable), continue; end
    if isscalar(intended)
        sender=intended(1);
        other=detectable(detectable~=sender);
        if isempty(other)
            if draws(receiver,sender)>C.managementErasureProbability
                a.recipientSuccess=a.recipientSuccess+1;
            else
                a.recipientErasure=a.recipientErasure+1;
            end
            continue;
        end
    end
    if ~isempty(intended)
        a.recipientCollision=a.recipientCollision+numel(intended);
        a.collision=true;
    end
end

end


function validateSchedule(S,C)

tol=1e-12;
if any(diff(S.dataStartTime)<-tol) || any(diff(S.controlStartTime)<-tol)
    error('buildDstrContinuousSchedule: event starts are not monotone.');
end
if any(S.dataStartTime<0) || any(S.dataStartTime>=S.horizonSec) || ...
        any(S.controlStartTime<0) || ...
        any(S.controlStartTime>=S.horizonSec)
    error('buildDstrContinuousSchedule: event start lies outside horizon.');
end
if any(S.dataNode<1 | S.dataNode>C.N) || ...
        any(S.controlNode<1 | S.controlNode>C.N)
    error('buildDstrContinuousSchedule: event node lies outside 1:N.');
end
if ~isequal(size(S.dataSuccessMask),[numel(S.dataStartTime) C.N]) || ...
        ~isequal(size(S.dataErasureMask),[numel(S.dataStartTime) C.N]) || ...
        ~isequal(size(S.dataCollisionMask),[numel(S.dataStartTime) C.N])
    error('buildDstrContinuousSchedule: malformed DATA outcome masks.');
end
partition=double(S.dataSuccessMask)+double(S.dataErasureMask)+ ...
    double(S.dataCollisionMask);
if any(partition(:)>1)
    error('buildDstrContinuousSchedule: DATA outcome masks overlap.');
end
if any(S.dataSlot<1) || any(S.controlSlot<1 | S.controlSlot>5)
    error('buildDstrContinuousSchedule: invalid logical slot index.');
end
if any(S.dataStartTime-S.frameStartTime(S.dataFrame) < ...
        5*S.slotDurationSec-tol)
    error('buildDstrContinuousSchedule: DATA overlaps management prefix.');
end

end
