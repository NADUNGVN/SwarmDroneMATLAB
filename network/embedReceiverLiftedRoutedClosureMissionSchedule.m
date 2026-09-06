function Q=embedReceiverLiftedRoutedClosureMissionSchedule(nativeQ,M,P)
%EMBEDRECEIVERLIFTEDROUTEDCLOSUREMISSIONSCHEDULE Add plant mission DATA.
%
% The routed transaction is not rescheduled.  Its management events and
% in-transaction scheduled DATA tuples are shifted by requestTimeSec exactly.
% Old-schedule DATA is added before the request, terminal schedule DATA after
% the transaction, and optional protected DATA whenever an affected node is
% suppressed.

requiredP={'missionSec','requestTimeSec','emergencyEnabled','emergencySlots'};
requiredQ={'version','horizonSec','airtimeSec','guardSec','slotDurationSec', ...
    'frameStartTime','frameEndTime','frameControlDurationSec', ...
    'dataStartTime','dataNode','dataSlot','dataFrame','dataKind', ...
    'controlStartTime','controlNode','controlSlot','controlFrame', ...
    'controlAttemptAirtimeSec','controlGroupStartTime', ...
    'controlGroupEndTime','controlGroupFrame','kernel','hashExact'};
if ~isstruct(nativeQ)||~isscalar(nativeQ)||~all(isfield(nativeQ,requiredQ))|| ...
        ~isstruct(M)||~isscalar(M)||~isfield(M,'N')|| ...
        ~isstruct(P)||~isscalar(P)||~all(isfield(P,requiredP))
    error('embedReceiverLiftedRoutedClosureMissionSchedule: input.');
end
mission=double(P.missionSec); request=double(P.requestTimeSec);
slots=reshape(double(P.emergencySlots),[],1);
if ~isfinite(mission)||~isfinite(request)||request<=0||request>=mission|| ...
        isempty(slots)||any(~isfinite(slots)|slots<1|slots~=floor(slots))|| ...
        numel(unique(slots))~=numel(slots)|| ...
        ~isscalar(P.emergencyEnabled)
    error('embedReceiverLiftedRoutedClosureMissionSchedule: mission spec.');
end
N=M.N; K=nativeQ.kernel; Ftxn=numel(nativeQ.frameStartTime);
if size(K.debug.active,1)~=Ftxn||size(K.debug.active,2)~=N|| ...
        request+nativeQ.frameEndTime(end)>mission+1e-12
    error('embedReceiverLiftedRoutedClosureMissionSchedule: transaction.');
end
affected=reshape(M.affectedNodes,[],1);
if numel(slots)<numel(affected)||any(slots>M.config.maxDataSlots)|| ...
        any(ismember(slots,M.oldSlot))||any(ismember(slots,M.candidateSlot))
    error('embedReceiverLiftedRoutedClosureMissionSchedule: emergency slots.');
end

dataFrameDuration=M.config.maxDataSlots*nativeQ.slotDurationSec;
[preStart,preEnd]=plainFrames(0,request,dataFrameDuration);
txnStart=request+nativeQ.frameStartTime;
txnEnd=request+nativeQ.frameEndTime;
[postStart,postEnd]=plainFrames(txnEnd(end),mission,dataFrameDuration);
frameStart=[preStart;txnStart;postStart];
frameEnd=[preEnd;txnEnd;postEnd];
nPre=numel(preStart); nPost=numel(postStart); F=numel(frameStart);
controlDuration=[zeros(nPre,1);nativeQ.frameControlDurationSec;zeros(nPost,1)];
frameKind=[repmat("pre",nPre,1);repmat("transaction",Ftxn,1); ...
    repmat("post",nPost,1)];
transactionFrame=[zeros(nPre,1);(1:Ftxn)';zeros(nPost,1)];

active=false(F,N); suppressed=false(F,N); slot=zeros(F,N);
graphActivated=false(F,1);
active(1:nPre,:)=true; slot(1:nPre,:)=repmat(M.oldSlot',nPre,1);
txn=(nPre+1):(nPre+Ftxn);
active(txn,:)=logical(K.debug.active);
suppressed(txn,:)=logical(K.debug.suppressed);
slot(txn,:)=K.debug.slot;
if isfinite(K.graphActivationFrame)
    graphActivated(txn(K.graphActivationFrame:end))=true;
end
if nPost>0
    active(txn(end)+(1:nPost),:)=repmat(logical(K.debug.active(end,:)),nPost,1);
    suppressed(txn(end)+(1:nPost),:)= ...
        repmat(logical(K.debug.suppressed(end,:)),nPost,1);
    slot(txn(end)+(1:nPost),:)=repmat(K.debug.slot(end,:),nPost,1);
    graphActivated(txn(end)+(1:nPost))=isfinite(K.graphActivationFrame);
end

dataStart=zeros(0,1); dataNode=zeros(0,1); dataSlot=zeros(0,1);
dataFrame=zeros(0,1); dataGroup=zeros(0,1); dataKind=strings(0,1);
nextGroup=0; emergencyFrames=zeros(0,1); emergencyNodes=zeros(0,1);
emergencyUsedSlots=zeros(0,1); suppressedDemand=0;
for frame=1:F
    for slotIndex=1:M.config.maxDataSlots
        senders=find(active(frame,:)'&slot(frame,:)'==slotIndex);
        emergencyNodesHere=zeros(0,1);
        if logical(P.emergencyEnabled)
            selected=find(suppressed(frame,affected));
            emergencyNodesHere=affected(selected(slots(selected)==slotIndex));
        end
        nodes=[reshape(senders,[],1);reshape(emergencyNodesHere,[],1)];
        if isempty(nodes), continue; end
        tk=frameStart(frame)+controlDuration(frame)+ ...
            (slotIndex-1)*nativeQ.slotDurationSec;
        if tk+nativeQ.airtimeSec>frameEnd(frame)+1e-12, continue; end
        nextGroup=nextGroup+1;
        for node=reshape(nodes,1,[])
            dataStart(end+1,1)=tk; dataNode(end+1,1)=node; %#ok<AGROW>
            dataSlot(end+1,1)=slotIndex; dataFrame(end+1,1)=frame; %#ok<AGROW>
            dataGroup(end+1,1)=nextGroup; %#ok<AGROW>
            if any(emergencyNodesHere==node)
                dataKind(end+1,1)="emergency"; %#ok<AGROW>
                emergencyFrames(end+1,1)=frame; %#ok<AGROW>
                emergencyNodes(end+1,1)=node; %#ok<AGROW>
                emergencyUsedSlots(end+1,1)=slotIndex; %#ok<AGROW>
            else
                dataKind(end+1,1)="scheduled"; %#ok<AGROW>
            end
        end
    end
    if logical(P.emergencyEnabled)
        selected=find(suppressed(frame,affected));
        feasible=frameStart(frame)+controlDuration(frame)+ ...
            (slots(selected)-1)*nativeQ.slotDurationSec+ ...
            nativeQ.airtimeSec<=frameEnd(frame)+1e-12;
        suppressedDemand=suppressedDemand+nnz(feasible);
    end
end

transactionRows=frameKind(dataFrame)=="transaction"&dataKind=="scheduled";
embedded=[dataStart(transactionRows) dataNode(transactionRows) ...
    dataSlot(transactionRows) dataFrame(transactionRows)-nPre];
native=[request+nativeQ.dataStartTime nativeQ.dataNode ...
    nativeQ.dataSlot nativeQ.dataFrame];
transactionExact=isequal(size(embedded),size(native))&& ...
    all(abs(embedded-native)<1e-12,'all');
if ~transactionExact
    error(['embedReceiverLiftedRoutedClosureMissionSchedule: transaction ' ...
        'DATA changed.']);
end

Q=nativeQ;
Q.version='RECEIVER-LIFTED-ROUTED-CLOSURE-MISSION-v1';
Q.horizonSec=mission;
Q.frameStartTime=frameStart; Q.frameEndTime=frameEnd;
Q.frameControlDurationSec=controlDuration;
Q.frameDurationSec=NaN;
Q.dataStartTime=dataStart; Q.dataNode=dataNode; Q.dataSlot=dataSlot;
Q.dataFrame=dataFrame; Q.dataGroup=dataGroup; Q.dataKind=dataKind;
Q.dataSuccessMask=false(numel(dataStart),N);
Q.dataErasureMask=false(numel(dataStart),N);
Q.dataCollisionMask=false(numel(dataStart),N);
Q.dataCompletesByHorizon=true(numel(dataStart),1);
Q.controlStartTime=request+nativeQ.controlStartTime;
Q.controlFrame=nPre+nativeQ.controlFrame;
Q.controlGroupStartTime=request+nativeQ.controlGroupStartTime;
Q.controlGroupEndTime=request+nativeQ.controlGroupEndTime;
Q.controlGroupFrame=nPre+nativeQ.controlGroupFrame;
Q.firstConvergenceTimeSec=request+nativeQ.firstConvergenceTimeSec;
Q.missionFrameKind=frameKind;
Q.missionTransactionFrame=transactionFrame;
Q.missionActive=active; Q.missionSuppressed=suppressed;
Q.missionSlot=slot; Q.missionGraphActivated=graphActivated;
Q.transactionMissionEmbeddingExact=double(transactionExact&& ...
    isequal(Q.controlStartTime,request+nativeQ.controlStartTime)&& ...
    isequal(Q.controlAttemptBytes,nativeQ.controlAttemptBytes));
opportunities=zeros(N,1);
for node=reshape(affected,1,[])
    opportunities(node)=nnz(emergencyNodes==node);
end
Q.emergencyData=struct('version','ROUTED-CLOSURE-PROTECTED-DATA-v1', ...
    'enabled',double(logical(P.emergencyEnabled)),'mode','parallel', ...
    'slots',slots,'affectedNodes',affected, ...
    'opportunities',numel(emergencyNodes), ...
    'nodeOpportunities',opportunities, ...
    'suppressedDemand',suppressedDemand, ...
    'mappingExact',double((logical(P.emergencyEnabled)&& ...
        numel(emergencyNodes)==suppressedDemand)|| ...
        (~logical(P.emergencyEnabled)&&isempty(emergencyNodes))), ...
    'scheduleHashExact',realizationHash([emergencyFrames; ...
        emergencyNodes;emergencyUsedSlots]));
Q.expectedDataCollisionFrames=0;
Q.expectedDataRecipientSuccess=0;
Q.expectedDataRecipientErasure=0;
Q.expectedDataRecipientCollision=0;
Q.expectedCompletedDataCollisionFrames=0;
Q.expectedCompletedDataRecipientSuccess=0;
Q.expectedCompletedDataRecipientErasure=0;
Q.expectedCompletedDataRecipientCollision=0;
Q.kernelConfigHash=hashScalar(struct('native',nativeQ.kernelConfigHash, ...
    'missionSec',mission,'requestTimeSec',request, ...
    'emergencyEnabled',double(logical(P.emergencyEnabled)), ...
    'emergencySlots',slots));
Q.logicalOpportunityHashExact=realizationHash([dataFrame;dataSlot;dataNode; ...
    Q.controlFrame;double(Q.controlSlot);Q.controlNode; ...
    Q.controlAttemptBytes]);
Q.hashExact=realizationHash([nativeQ.hashExact;mission;request; ...
    frameStart;frameEnd;controlDuration;dataStart;dataNode;dataSlot; ...
    dataFrame;dataGroup;double(dataKind=="emergency"); ...
    Q.controlStartTime;Q.controlFrame;Q.controlGroupStartTime; ...
    Q.controlGroupEndTime;Q.emergencyData.scheduleHashExact; ...
    Q.kernelConfigHash]);
validateMission(Q,nativeQ,M,P);

end


function [start,finish]=plainFrames(first,last,duration)

start=zeros(0,1); finish=zeros(0,1); cursor=first;
while cursor<last-1e-12
    start(end+1,1)=cursor; %#ok<AGROW>
    finish(end+1,1)=min(last,cursor+duration); %#ok<AGROW>
    cursor=finish(end);
end

end


function validateMission(Q,nativeQ,M,P)

if ~Q.transactionMissionEmbeddingExact|| ...
        Q.expectedManagementAttempts~=nativeQ.expectedManagementAttempts|| ...
        Q.expectedManagementBytes~=nativeQ.expectedManagementBytes|| ...
        Q.expectedManagementAirtime~=nativeQ.expectedManagementAirtime|| ...
        any(Q.controlStartTime<Q.frameStartTime(1)-1e-12)|| ...
        any(Q.controlStartTime+Q.controlAttemptAirtimeSec>P.missionSec+1e-12)|| ...
        any(Q.dataStartTime<0)|| ...
        any(Q.dataStartTime+Q.airtimeSec>P.missionSec+1e-12)
    error('embedReceiverLiftedRoutedClosureMissionSchedule: invariant.');
end
for frame=1:numel(Q.frameStartTime)
    control=Q.controlFrame==frame; data=Q.dataFrame==frame;
    if any(control)&&any(data)&&max(Q.controlStartTime(control)+ ...
            Q.controlAttemptAirtimeSec(control))> ...
            min(Q.dataStartTime(data))+1e-12
        error('embedReceiverLiftedRoutedClosureMissionSchedule: overlap.');
    end
end
if logical(P.emergencyEnabled)&& ...
        any(ismember(P.emergencySlots,[M.oldSlot;M.candidateSlot]))
    error('embedReceiverLiftedRoutedClosureMissionSchedule: slot conflict.');
end

end


function value=hashScalar(S)
[value,~]=configHash(S);
end
