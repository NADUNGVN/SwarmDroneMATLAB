function Q=buildDstrWarmContinuousSchedule( ...
    nativeQ,horizonSec,dataDeliveryU,dataErasureProbability)
%BUILDDSTRWARMCONTINUOUSSCHEDULE Oracle-warm D-STR cost decomposition arm.
%
% A deterministic centralized conflict-graph coloring is installed at time zero.
% Five idle management slots remain in every superframe, so this reference
% removes acquisition/control attempts without changing D-STR frame geometry.

if ~isstruct(nativeQ) || ~isscalar(nativeQ) || ...
        ~isfield(nativeQ,'kernel') || ~isfield(nativeQ,'slotDurationSec')
    error('buildDstrWarmContinuousSchedule: invalid native schedule.');
end
if nargin<2 || isempty(horizonSec), horizonSec=nativeQ.horizonSec; end
if nargin<3, dataDeliveryU=[]; end
if nargin<4 || isempty(dataErasureProbability), dataErasureProbability=0; end
if ~isscalar(horizonSec) || ~isfinite(horizonSec) || horizonSec<=0
    error('buildDstrWarmContinuousSchedule: invalid horizonSec.');
end
if ~isscalar(dataErasureProbability) || ...
        ~isfinite(dataErasureProbability) || ...
        dataErasureProbability<0 || dataErasureProbability>1
    error(['buildDstrWarmContinuousSchedule: dataErasureProbability ' ...
        'must lie in [0,1].']);
end
assigned=greedyConflictColoring( ...
    nativeQ.neighborGraph,nativeQ.interferenceMatrix);

slotDuration=nativeQ.slotDurationSec;
frameSlots=max(assigned);
frameDuration=(5+frameSlots)*slotDuration;
frameStart=(0:frameDuration:horizonSec-1e-12)';
frameEnd=frameStart+frameDuration;
N=numel(assigned);
dataStart=zeros(numel(frameStart)*N,1);
dataNode=zeros(numel(dataStart),1);
dataSlot=zeros(numel(dataStart),1);
dataFrame=zeros(numel(dataStart),1);
q=0;
for frame=1:numel(frameStart)
    for node=1:N
        tk=frameStart(frame)+(5+assigned(node)-1)*slotDuration;
        if tk>=horizonSec-1e-12, continue; end
        q=q+1;
        dataStart(q)=tk;
        dataNode(q)=node;
        dataSlot(q)=assigned(node);
        dataFrame(q)=frame;
    end
end
dataStart=dataStart(1:q);
dataNode=dataNode(1:q);
dataSlot=dataSlot(1:q);
dataFrame=dataFrame(1:q);
if ~isempty(dataStart)
    [~,order]=sortrows([dataStart dataNode],[1 2]);
    dataStart=dataStart(order);
    dataNode=dataNode(order);
    dataSlot=dataSlot(order);
    dataFrame=dataFrame(order);
end
[dataSuccessMask,dataErasureMask,dataCollisionMask]=warmOutcomeMasks( ...
    dataStart,dataNode,dataFrame,nativeQ.neighborGraph, ...
    nativeQ.interferenceMatrix,dataDeliveryU,dataErasureProbability);

Q=nativeQ;
Q.version='DSTR-WARM-CONTINUOUS-SCHEDULE-v1';
Q.horizonSec=horizonSec;
Q.frameStartTime=frameStart;
Q.frameEndTime=frameEnd;
Q.maxPrefixFrameDisagreement=0;
Q.prefixFrameAgreement=true;
Q.dataStartTime=dataStart;
Q.dataNode=dataNode;
Q.dataSlot=dataSlot;
Q.dataFrame=dataFrame;
Q.dataSuccessMask=dataSuccessMask;
Q.dataErasureMask=dataErasureMask;
Q.dataCollisionMask=dataCollisionMask;
Q.dataCompletesByHorizon=dataStart+Q.airtimeSec<=horizonSec+1e-12;
Q.controlStartTime=zeros(0,1);
Q.controlNode=zeros(0,1);
Q.controlSlot=zeros(0,1,'uint8');
Q.controlFrame=zeros(0,1);
Q.controlGroupStartTime=zeros(0,1);
Q.controlGroupFrame=zeros(0,1);
Q.controlGroupSlot=zeros(0,1,'uint8');
Q.controlGroupAttempts=zeros(0,1);
Q.controlGroupRecipientAttempts=zeros(0,1);
Q.controlGroupRecipientSuccess=zeros(0,1);
Q.controlGroupRecipientErasure=zeros(0,1);
Q.controlGroupRecipientCollision=zeros(0,1);
Q.controlGroupCollision=false(0,1);
Q.expectedDataCollisionFrames=collisionFrameCount( ...
    dataStart,dataCollisionMask);
Q.expectedDataRecipientSuccess=nnz(dataSuccessMask);
Q.expectedDataRecipientErasure=nnz(dataErasureMask);
Q.expectedDataRecipientCollision=nnz(dataCollisionMask);
Q.expectedCompletedDataCollisionFrames=collisionFrameCount( ...
    dataStart(Q.dataCompletesByHorizon), ...
    dataCollisionMask(Q.dataCompletesByHorizon,:));
Q.expectedCompletedDataRecipientSuccess= ...
    nnz(dataSuccessMask(Q.dataCompletesByHorizon,:));
Q.expectedCompletedDataRecipientErasure= ...
    nnz(dataErasureMask(Q.dataCompletesByHorizon,:));
Q.expectedCompletedDataRecipientCollision= ...
    nnz(dataCollisionMask(Q.dataCompletesByHorizon,:));
Q.warmAssignedSlot=assigned;
Q.firstConvergenceTimeSec=0;
Q.hashExact=realizationHash([horizonSec;Q.airtimeSec;Q.guardSec; ...
    frameStart;frameEnd;dataStart;dataNode;dataSlot;dataFrame; ...
    double(dataSuccessMask(:));double(dataErasureMask(:)); ...
    double(dataCollisionMask(:));double(Q.dataCompletesByHorizon); ...
    assigned;Q.kernelConfigHash;Q.kernelTraceHash]);

end


function [success,erasure,collision]=warmOutcomeMasks( ...
    startTime,node,frame,neighbor,interference,draws,pLoss)

N=size(neighbor,1);
E=numel(startTime);
success=false(E,N);
erasure=false(E,N);
collision=false(E,N);
if pLoss>0
    if isempty(draws) || size(draws,2)~=N || size(draws,3)~=N || ...
            size(draws,1)<max([0;frame])
        error(['buildDstrWarmContinuousSchedule: DATA draws do not cover ' ...
            'the warm schedule.']);
    end
end
first=1;
tol=1e-12;
while first<=E
    last=first;
    while last<E && abs(startTime(last+1)-startTime(first))<=tol
        last=last+1;
    end
    tx=reshape(node(first:last),1,[]);
    txMask=false(N,1); txMask(tx)=true;
    for index=first:last
        sender=node(index);
        receivers=find(neighbor(:,sender) & ~txMask);
        for receiver=reshape(receivers,1,[])
            other=tx(tx~=sender & (interference(receiver,tx) | ...
                neighbor(receiver,tx)));
            if ~isempty(other)
                collision(index,receiver)=true;
            elseif pLoss>0 && draws(frame(index),receiver,sender)<=pLoss
                erasure(index,receiver)=true;
            else
                success(index,receiver)=true;
            end
        end
    end
    first=last+1;
end

end


function count=collisionFrameCount(startTime,collisionMask)

count=0;
first=1;
tol=1e-12;
while first<=numel(startTime)
    last=first;
    while last<numel(startTime) && ...
            abs(startTime(last+1)-startTime(first))<=tol
        last=last+1;
    end
    count=count+nnz(any(collisionMask(first:last,:),2));
    first=last+1;
end

end


function assigned=greedyConflictColoring(neighbor,interference)

N=size(neighbor,1);
if ~isequal(size(neighbor),[N N]) || ~isequal(size(interference),[N N])
    error('buildDstrWarmContinuousSchedule: invalid conflict matrices.');
end
conflict=false(N);
for a=1:N
    receiversA=neighbor(:,a);
    for b=a+1:N
        receiversB=neighbor(:,b);
        ab=neighbor(b,a) || neighbor(a,b) || ...
            any(interference(receiversA,b)) || ...
            any(interference(receiversB,a));
        conflict(a,b)=ab;
        conflict(b,a)=ab;
    end
end
assigned=zeros(N,1);
for node=1:N
    unavailable=unique(assigned(conflict(node,:) & assigned'>0));
    slot=1;
    while any(unavailable==slot), slot=slot+1; end
    assigned(node)=slot;
end
for a=1:N
    for b=a+1:N
        if conflict(a,b) && assigned(a)==assigned(b)
            error('buildDstrWarmContinuousSchedule: coloring is invalid.');
        end
    end
end

end
