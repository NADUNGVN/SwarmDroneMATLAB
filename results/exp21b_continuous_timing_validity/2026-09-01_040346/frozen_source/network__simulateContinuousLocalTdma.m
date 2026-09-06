function out=simulateContinuousLocalTdma(cfg)
%SIMULATECONTINUOUSLOCALTDMA Continuous-time local-clock TDMA intervals.
%
% This infrastructure kernel contains no formation controller, admission
% policy, feedback decision, or random-number generator.  Callers provide all
% clock realizations explicitly.  Intervals are half open.

C=validateConfig(cfg);
N=C.N;
D=C.dataAirtimeSec;
G=C.guardTimeSec;
Tslot=D+G;
Tframe=C.frameSlots*Tslot;
epochs=epochBoundaries(C.horizonSec,C.syncPeriodSec);
Q=numel(epochs)-1;
offsets=expandOffsets(C.clockOffsetSec,N,Q);
drift=C.clockDriftPpm(:)*1e-6;

starts=zeros(0,1);
ends=zeros(0,1);
senders=zeros(0,1);
localBoundaries=zeros(0,1);
epochIndex=zeros(0,1);
slotOrdinal=zeros(0,1);
equationResidual=zeros(0,1);
tol=1e-12;

for q=1:Q
    tau=epochs(q);
    epochEnd=epochs(q+1);
    epochSpan=epochEnd-tau;
    for sender=1:N
        assigned=C.assignedSlot(sender);
        if assigned<=0, continue; end
        first=(assigned-1)*Tslot+C.epochLeadTimeSec;
        kMax=ceil((epochSpan+abs(offsets(sender,q))+Tframe)/Tframe)+1;
        for k=0:kMax
            b=first+k*Tframe;
            start=tau+(b-offsets(sender,q))/(1+drift(sender));
            if start<tau-tol || start>=epochEnd-tol || ...
                    start+D>epochEnd+tol || start>=C.horizonSec-tol
                continue;
            end
            starts(end+1,1)=max(start,tau); %#ok<AGROW>
            ends(end+1,1)=start+D; %#ok<AGROW>
            senders(end+1,1)=sender; %#ok<AGROW>
            localBoundaries(end+1,1)=b; %#ok<AGROW>
            epochIndex(end+1,1)=q; %#ok<AGROW>
            slotOrdinal(end+1,1)=k; %#ok<AGROW>
            solved=offsets(sender,q)+(1+drift(sender))*(start-tau);
            equationResidual(end+1,1)=solved-b; %#ok<AGROW>
        end
    end
end

if ~isempty(starts)
    [~,order]=sortrows([starts senders],[1 2]);
    starts=starts(order); ends=ends(order); senders=senders(order);
    localBoundaries=localBoundaries(order); epochIndex=epochIndex(order);
    slotOrdinal=slotOrdinal(order); equationResidual=equationResidual(order);
end

nTx=numel(starts);
collisionMask=false(nTx,N);
overlapPairs=zeros(0,2);
overlapDuration=zeros(0,1);
for a=1:nTx
    for b=a+1:nTx
        if starts(b)>=ends(a)-tol
            break;
        end
        overlap=min(ends(a),ends(b))-max(starts(a),starts(b));
        if overlap<=tol, continue; end
        overlapPairs(end+1,:)=[a b]; %#ok<AGROW>
        overlapDuration(end+1,1)=overlap; %#ok<AGROW>
        senderA=senders(a); senderB=senders(b);
        intendedA=find(C.topology(:,senderA));
        intendedB=find(C.topology(:,senderB));
        corruptA=intendedA(C.interferenceMatrix(intendedA,senderB));
        corruptB=intendedB(C.interferenceMatrix(intendedB,senderA));
        collisionMask(a,corruptA)=true;
        collisionMask(b,corruptB)=true;
    end
end

collisionFrame=any(collisionMask,2);
collisionWitnessValid=validateCollisionWitnesses( ...
    collisionMask,overlapPairs,senders,C);
[busyTime,mergedIntervals]=intervalUnion(starts,ends,C.horizonSec);
out=struct();
out.N=N;
out.horizonSec=C.horizonSec;
out.dataAirtimeSec=D;
out.guardTimeSec=G;
out.slotDurationSec=Tslot;
out.frameDurationSec=Tframe;
out.syncPeriodSec=C.syncPeriodSec;
out.epochBoundaries=epochs;
out.clockOffsetSec=offsets;
out.clockDriftPpm=C.clockDriftPpm(:);
out.startTime=starts;
out.endTime=ends;
out.sender=senders;
out.localBoundary=localBoundaries;
out.epochIndex=epochIndex;
out.slotOrdinal=slotOrdinal;
out.clockEquationResidual=equationResidual;
out.collisionMask=collisionMask;
out.collisionFrame=collisionFrame;
out.collisionFrames=nnz(collisionFrame);
out.overlapPairs=overlapPairs;
out.overlapDurationSec=overlapDuration;
out.temporalOverlapPairs=size(overlapPairs,1);
out.collisionWitnessValid=collisionWitnessValid;
out.offeredAirtimeSec=nTx*D;
out.busyTimeSec=busyTime;
out.offeredUtilization=out.offeredAirtimeSec/C.horizonSec;
out.channelUtilization=busyTime/C.horizonSec;
out.mergedBusyIntervals=mergedIntervals;
out.maxClockEquationResidual=max([0;abs(equationResidual)]);
out.configHash=configHash(C);
out.realizationHash=realizationHash([starts;ends;senders; ...
    localBoundaries;epochIndex;slotOrdinal;collisionMask(:)]);

end


function valid=validateCollisionWitnesses(mask,pairs,senders,C)

valid=true;
for tx=1:size(mask,1)
    receivers=find(mask(tx,:));
    for receiver=receivers
        pairRows=find(pairs(:,1)==tx | pairs(:,2)==tx);
        witnessed=false;
        for row=reshape(pairRows,1,[])
            pair=pairs(row,:);
            other=pair(pair~=tx);
            if C.topology(receiver,senders(tx)) && ...
                    C.interferenceMatrix(receiver,senders(other))
                witnessed=true;
                break;
            end
        end
        if ~witnessed
            valid=false;
            return;
        end
    end
end

end


function C=validateConfig(cfg)

required={'N','horizonSec','dataAirtimeSec','guardTimeSec', ...
    'frameSlots','assignedSlot','clockOffsetSec','clockDriftPpm', ...
    'syncPeriodSec','topology','interferenceMatrix'};
for k=1:numel(required)
    if ~isfield(cfg,required{k})
        error('simulateContinuousLocalTdma: cfg lacks %s.',required{k});
    end
end
C=cfg;
if ~isfield(C,'epochLeadTimeSec'), C.epochLeadTimeSec=0; end
positiveInteger(C.N,'N');
positiveScalar(C.horizonSec,'horizonSec');
positiveScalar(C.dataAirtimeSec,'dataAirtimeSec');
nonnegativeScalar(C.guardTimeSec,'guardTimeSec');
positiveInteger(C.frameSlots,'frameSlots');
nonnegativeScalar(C.epochLeadTimeSec,'epochLeadTimeSec');
if ~isequal(size(C.assignedSlot),[C.N 1]) && ...
        ~isequal(size(C.assignedSlot),[1 C.N])
    error('simulateContinuousLocalTdma: assignedSlot must have N entries.');
end
C.assignedSlot=C.assignedSlot(:);
if any(~isfinite(C.assignedSlot) | C.assignedSlot<0 | ...
        C.assignedSlot~=round(C.assignedSlot) | ...
        C.assignedSlot>C.frameSlots)
    error('simulateContinuousLocalTdma: assigned slots must lie in 0:F.');
end
if numel(C.clockDriftPpm)~=C.N || ...
        any(~isfinite(C.clockDriftPpm(:))) || ...
        any(abs(C.clockDriftPpm(:))*1e-6>=1)
    error('simulateContinuousLocalTdma: clockDriftPpm must have N finite entries.');
end
if ~(isinf(C.syncPeriodSec) || ...
        (isscalar(C.syncPeriodSec) && isfinite(C.syncPeriodSec) && ...
        C.syncPeriodSec>0))
    error('simulateContinuousLocalTdma: syncPeriodSec must be positive or inf.');
end
if ~isequal(size(C.topology),[C.N C.N]) || ...
        any(~ismember(C.topology(:),[0 1]))
    error('simulateContinuousLocalTdma: topology must be binary N-by-N.');
end
if ~isequal(size(C.interferenceMatrix),[C.N C.N]) || ...
        any(~ismember(C.interferenceMatrix(:),[0 1]))
    error(['simulateContinuousLocalTdma: interferenceMatrix must be ' ...
        'binary N-by-N.']);
end
C.topology=logical(C.topology);
C.interferenceMatrix=logical(C.interferenceMatrix);
expandOffsets(C.clockOffsetSec,C.N, ...
    numel(epochBoundaries(C.horizonSec,C.syncPeriodSec))-1);

end


function offsets=expandOffsets(x,N,Q)

if isvector(x) && numel(x)==N
    offsets=repmat(x(:),1,Q);
elseif isequal(size(x),[N Q])
    offsets=x;
else
    error(['simulateContinuousLocalTdma: clockOffsetSec must be N entries ' ...
        'or N-by-numberOfEpochs.']);
end
if any(~isfinite(offsets(:)))
    error('simulateContinuousLocalTdma: clock offsets must be finite.');
end

end


function e=epochBoundaries(horizon,syncPeriod)

if isinf(syncPeriod) || syncPeriod>=horizon
    e=[0 horizon];
    return;
end
e=(0:syncPeriod:horizon)';
if e(end)<horizon-1e-12, e(end+1,1)=horizon; end

end


function [total,merged]=intervalUnion(starts,ends,horizon)

if isempty(starts)
    total=0; merged=zeros(0,2); return;
end
clipped=[max(starts,0) min(ends,horizon)];
clipped=clipped(clipped(:,2)>clipped(:,1),:);
if isempty(clipped)
    total=0; merged=zeros(0,2); return;
end
clipped=sortrows(clipped,1);
merged=clipped(1,:);
for k=2:size(clipped,1)
    if clipped(k,1)<=merged(end,2)+1e-12
        merged(end,2)=max(merged(end,2),clipped(k,2));
    else
        merged(end+1,:)=clipped(k,:); %#ok<AGROW>
    end
end
total=sum(merged(:,2)-merged(:,1));

end


function positiveScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x<=0
    error('simulateContinuousLocalTdma: %s must be positive finite.',name);
end

end


function nonnegativeScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x<0
    error('simulateContinuousLocalTdma: %s must be nonnegative finite.',name);
end

end


function positiveInteger(x,name)

positiveScalar(x,name);
if x~=round(x)
    error('simulateContinuousLocalTdma: %s must be an integer.',name);
end

end
