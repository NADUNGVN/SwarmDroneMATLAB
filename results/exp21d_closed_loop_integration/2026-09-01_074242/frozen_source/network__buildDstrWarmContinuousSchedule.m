function Q=buildDstrWarmContinuousSchedule(nativeQ,horizonSec)
%BUILDDSTRWARMCONTINUOUSSCHEDULE Oracle-warm D-STR cost decomposition arm.
%
% The terminal collision-free D-STR assignment is installed at time zero.
% Five idle management slots remain in every superframe, so this reference
% removes acquisition/control attempts without changing D-STR frame geometry.

if ~isstruct(nativeQ) || ~isscalar(nativeQ) || ...
        ~isfield(nativeQ,'kernel') || ~isfield(nativeQ,'slotDurationSec')
    error('buildDstrWarmContinuousSchedule: invalid native schedule.');
end
if nargin<2 || isempty(horizonSec), horizonSec=nativeQ.horizonSec; end
if ~isscalar(horizonSec) || ~isfinite(horizonSec) || horizonSec<=0
    error('buildDstrWarmContinuousSchedule: invalid horizonSec.');
end
K=nativeQ.kernel;
assigned=K.assignedSlot(:);
if ~K.finalAllResolved || ~K.finalCollisionFree || ...
        any(assigned<=0) || ~K.finalFrameAgreement
    error(['buildDstrWarmContinuousSchedule: native terminal schedule is ' ...
        'not a valid oracle-warm assignment.']);
end

slotDuration=nativeQ.slotDurationSec;
frameSlots=max(K.localDataSlots);
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

Q=nativeQ;
Q.version='DSTR-WARM-CONTINUOUS-SCHEDULE-v1';
Q.horizonSec=horizonSec;
Q.frameStartTime=frameStart;
Q.frameEndTime=frameEnd;
Q.dataStartTime=dataStart;
Q.dataNode=dataNode;
Q.dataSlot=dataSlot;
Q.dataFrame=dataFrame;
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
Q.expectedDataCollisionFrames=0;
Q.firstConvergenceTimeSec=0;
Q.hashExact=realizationHash([horizonSec;Q.airtimeSec;Q.guardSec; ...
    frameStart;frameEnd;dataStart;dataNode;dataSlot;dataFrame; ...
    Q.kernelConfigHash;Q.kernelTraceHash]);

end
