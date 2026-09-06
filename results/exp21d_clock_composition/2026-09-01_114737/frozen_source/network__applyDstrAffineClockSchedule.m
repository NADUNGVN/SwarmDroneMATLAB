function Q=applyDstrAffineClockSchedule(nativeQ,spec)
%APPLYDSTRAFFINECLOCKSCHEDULE Map D-STR boundaries through local clocks.
%
% Each node n has the single-epoch affine clock
%
%   ell_n(t) = offset_n + (1 + drift_n) (t - lead),
%
% and transmits when ell_n(t) reaches the nominal D-STR boundary.  The
% schedule is trimmed at one common, outcome-blind nominal cutoff derived
% from the declared worst-case offset/drift bounds.  Hence zero-clock and
% impaired-clock arms consume exactly the same logical opportunities.

required={'horizonSec','airtimeSec','guardSec','dataStartTime', ...
    'dataNode','dataSlot','dataFrame','dataSuccessMask', ...
    'dataErasureMask','dataCollisionMask','controlStartTime', ...
    'controlNode','controlSlot','controlFrame','controlGroupStartTime', ...
    'controlGroupFrame','controlGroupSlot','controlGroupAttempts', ...
    'controlGroupRecipientAttempts','controlGroupRecipientSuccess', ...
    'controlGroupRecipientErasure','controlGroupRecipientCollision', ...
    'controlGroupCollision','kernelConfigHash','kernelTraceHash','hashExact'};
if ~isstruct(nativeQ) || ~isscalar(nativeQ) || ...
        ~all(isfield(nativeQ,required))
    error('applyDstrAffineClockSchedule: invalid native schedule.');
end
requiredSpec={'clockOffsetSec','clockDriftPpm','maxOffsetSec', ...
    'maxDriftPpm','leadTimeSec','safeGuardSec'};
if ~isstruct(spec) || ~isscalar(spec) || ~all(isfield(spec,requiredSpec))
    error('applyDstrAffineClockSchedule: invalid clock specification.');
end

N=size(nativeQ.dataSuccessMask,2);
offset=reshape(spec.clockOffsetSec,[],1);
driftPpm=reshape(spec.clockDriftPpm,[],1);
if numel(offset)~=N || numel(driftPpm)~=N || ...
        any(~isfinite(offset)) || any(~isfinite(driftPpm))
    error('applyDstrAffineClockSchedule: clock vectors must have N entries.');
end
validateNonnegative(spec.maxOffsetSec,'maxOffsetSec');
validateNonnegative(spec.maxDriftPpm,'maxDriftPpm');
validateNonnegative(spec.leadTimeSec,'leadTimeSec');
validateNonnegative(spec.safeGuardSec,'safeGuardSec');
if any(abs(offset)>spec.maxOffsetSec+1e-15) || ...
        any(abs(driftPpm)>spec.maxDriftPpm+1e-12)
    error('applyDstrAffineClockSchedule: realized clock exceeds its bound.');
end
delta=spec.maxDriftPpm*1e-6;
drift=driftPpm*1e-6;
if delta>=1 || any(1+drift<=0)
    error('applyDstrAffineClockSchedule: invalid fractional clock drift.');
end
if any(abs(offset)>0) || any(abs(driftPpm)>0)
    if nativeQ.guardSec<spec.safeGuardSec-1e-12
        error(['applyDstrAffineClockSchedule: impaired clock requires the ' ...
            'declared sufficient guard.']);
    end
end

H=nativeQ.horizonSec;
D=nativeQ.airtimeSec;
lead=spec.leadTimeSec;
cutoff=(H-lead-D)*(1-delta)-spec.maxOffsetSec;
if cutoff<=0
    error('applyDstrAffineClockSchedule: no complete common horizon remains.');
end

Q=nativeQ;
Q.version='DSTR-AFFINE-CLOCK-SCHEDULE-v1';
Q.clockApplied=double(any(abs(offset)>0) || any(abs(driftPpm)>0));
Q.clockOffsetSec=offset;
Q.clockDriftPpm=driftPpm;
Q.clockMaxOffsetSec=spec.maxOffsetSec;
Q.clockMaxDriftPpm=spec.maxDriftPpm;
Q.clockLeadTimeSec=lead;
Q.clockSafeGuardSec=spec.safeGuardSec;
Q.clockNominalCutoffSec=cutoff;
Q.baseScheduleHashExact=nativeQ.hashExact;

% DATA attempts: retain whole logical co-slot groups, then sort their
% physical starts.  Group identity lets the event engine enforce half duplex
% across transmitters whose starts are no longer numerically simultaneous.
[baseGroup,groupNominal]=logicalDataGroups(nativeQ);
keepGroup=groupNominal<=cutoff+1e-12;
keep=keepGroup(baseGroup);
nominal=nativeQ.dataStartTime(keep);
node=nativeQ.dataNode(keep);
group=baseGroup(keep);
actual=clockInverse(nominal,node,offset,drift,lead);
if any(actual< -1e-12) || any(actual+D>H+1e-12)
    error('applyDstrAffineClockSchedule: DATA left the certified horizon.');
end
Q.dataNominalStartTime=nominal;
Q.dataStartTime=max(actual,0);
Q.dataNode=node;
Q.dataSlot=nativeQ.dataSlot(keep);
Q.dataFrame=nativeQ.dataFrame(keep);
Q.dataGroup=group;
Q.dataSuccessMask=nativeQ.dataSuccessMask(keep,:);
Q.dataErasureMask=nativeQ.dataErasureMask(keep,:);
Q.dataCollisionMask=nativeQ.dataCollisionMask(keep,:);
if ~isempty(Q.dataStartTime)
    [~,order]=sortrows([Q.dataStartTime Q.dataNode],[1 2]);
    fields={'dataNominalStartTime','dataStartTime','dataNode','dataSlot', ...
        'dataFrame','dataGroup'};
    for k=1:numel(fields), Q.(fields{k})=Q.(fields{k})(order,:); end
    Q.dataSuccessMask=Q.dataSuccessMask(order,:);
    Q.dataErasureMask=Q.dataErasureMask(order,:);
    Q.dataCollisionMask=Q.dataCollisionMask(order,:);
end
Q.dataCompletesByHorizon=true(size(Q.dataStartTime));

% Management attempts retain whole logical groups.  A group occupies the
% exact union envelope [min start, max end); charged attempt-airtime remains
% count times D and is kept separate from busy-union time.
G=numel(nativeQ.controlGroupStartTime);
keepControl=nativeQ.controlGroupStartTime<=cutoff+1e-12;
groupStart=zeros(nnz(keepControl),1);
groupEnd=zeros(nnz(keepControl),1);
controlNominal=zeros(0,1);
controlActual=zeros(0,1);
controlNode=zeros(0,1);
controlSlot=zeros(0,1,'uint8');
controlFrame=zeros(0,1);
q=0;
keptIndices=find(keepControl);
for outIndex=1:numel(keptIndices)
    sourceIndex=keptIndices(outIndex);
    member=nativeQ.controlFrame==nativeQ.controlGroupFrame(sourceIndex) & ...
        nativeQ.controlSlot==nativeQ.controlGroupSlot(sourceIndex);
    nominalStarts=nativeQ.controlStartTime(member);
    nodes=nativeQ.controlNode(member);
    starts=clockInverse(nominalStarts,nodes,offset,drift,lead);
    if isempty(starts) || any(starts< -1e-12) || any(starts+D>H+1e-12)
        error(['applyDstrAffineClockSchedule: management group left the ' ...
            'certified horizon.']);
    end
    groupStart(outIndex)=min(starts);
    groupEnd(outIndex)=max(starts)+D;
    m=numel(starts);
    controlNominal(q+1:q+m,1)=nominalStarts;
    controlActual(q+1:q+m,1)=max(starts,0);
    controlNode(q+1:q+m,1)=nodes;
    controlSlot(q+1:q+m,1)=nativeQ.controlSlot(member);
    controlFrame(q+1:q+m,1)=nativeQ.controlFrame(member);
    q=q+m;
end
if ~isempty(controlActual)
    [~,order]=sortrows([controlActual double(controlSlot) controlNode], ...
        [1 2 3]);
    controlActual=controlActual(order);
    controlNominal=controlNominal(order);
    controlNode=controlNode(order);
    controlSlot=controlSlot(order);
    controlFrame=controlFrame(order);
end
Q.controlNominalStartTime=controlNominal;
Q.controlStartTime=controlActual;
Q.controlNode=controlNode;
Q.controlSlot=controlSlot;
Q.controlFrame=controlFrame;
Q.controlGroupNominalStartTime= ...
    nativeQ.controlGroupStartTime(keepControl);
Q.controlGroupStartTime=max(groupStart,0);
Q.controlGroupEndTime=groupEnd;
groupFields={'controlGroupFrame','controlGroupSlot', ...
    'controlGroupAttempts','controlGroupRecipientAttempts', ...
    'controlGroupRecipientSuccess','controlGroupRecipientErasure', ...
    'controlGroupRecipientCollision','controlGroupCollision'};
for k=1:numel(groupFields)
    Q.(groupFields{k})=nativeQ.(groupFields{k})(keepControl,:);
end
if numel(Q.controlGroupStartTime)~=nnz(keepControl) || G<nnz(keepControl)
    error('applyDstrAffineClockSchedule: management group trim failed.');
end

% Safe-guard certificate on the actual union envelopes.
[timingSafe,minGap,maxSkew]=timingCertificate(Q,D);
Q.clockTimingConflictFree=double(timingSafe);
Q.clockMinimumIntergroupGapSec=minGap;
Q.clockMaximumIntragroupSkewSec=maxSkew;
Q.clockEquationMaxResidualSec=max([0; ...
    clockResidual(Q.dataNominalStartTime,Q.dataStartTime,Q.dataNode, ...
        offset,drift,lead); ...
    clockResidual(Q.controlNominalStartTime,Q.controlStartTime, ...
        Q.controlNode,offset,drift,lead)]);
if ~timingSafe
    error(['applyDstrAffineClockSchedule: declared safe schedule contains ' ...
        'an inter-group overlap.']);
end

Q.expectedDataCollisionFrames=nnz(any(Q.dataCollisionMask,2));
Q.expectedDataRecipientSuccess=nnz(Q.dataSuccessMask);
Q.expectedDataRecipientErasure=nnz(Q.dataErasureMask);
Q.expectedDataRecipientCollision=nnz(Q.dataCollisionMask);
Q.expectedCompletedDataCollisionFrames=Q.expectedDataCollisionFrames;
Q.expectedCompletedDataRecipientSuccess=Q.expectedDataRecipientSuccess;
Q.expectedCompletedDataRecipientErasure=Q.expectedDataRecipientErasure;
Q.expectedCompletedDataRecipientCollision=Q.expectedDataRecipientCollision;
Q.firstConvergenceTimeSec=min(H,lead+nativeQ.firstConvergenceTimeSec);
dataLogical=[Q.dataFrame Q.dataSlot Q.dataNode ...
    double(Q.dataSuccessMask) double(Q.dataErasureMask) ...
    double(Q.dataCollisionMask)];
controlLogical=[Q.controlFrame double(Q.controlSlot) Q.controlNode];
Q.logicalOpportunityHashExact=realizationHash([ ...
    reshape(sortrows(dataLogical,[1 2 3]),[],1); ...
    reshape(sortrows(controlLogical,[1 2 3]),[],1)]);
Q.hashExact=realizationHash([nativeQ.hashExact;H;D;nativeQ.guardSec; ...
    offset;driftPpm;spec.maxOffsetSec;spec.maxDriftPpm;lead; ...
    spec.safeGuardSec;cutoff;Q.dataNominalStartTime;Q.dataStartTime; ...
    Q.dataNode;Q.dataSlot;Q.dataFrame;Q.dataGroup; ...
    double(Q.dataSuccessMask(:));double(Q.dataErasureMask(:)); ...
    double(Q.dataCollisionMask(:));Q.controlNominalStartTime; ...
    Q.controlStartTime;Q.controlNode;double(Q.controlSlot); ...
    Q.controlFrame;Q.controlGroupNominalStartTime; ...
    Q.controlGroupStartTime;Q.controlGroupEndTime; ...
    Q.controlGroupAttempts;Q.controlGroupRecipientAttempts; ...
    Q.controlGroupRecipientSuccess;Q.controlGroupRecipientErasure; ...
    Q.controlGroupRecipientCollision;double(Q.controlGroupCollision); ...
    Q.clockEquationMaxResidualSec;Q.clockMinimumIntergroupGapSec; ...
    Q.clockMaximumIntragroupSkewSec;nativeQ.kernelConfigHash; ...
    nativeQ.kernelTraceHash]);

end


function actual=clockInverse(nominal,node,offset,drift,lead)

actual=lead+(nominal-offset(node))./(1+drift(node));

end


function residual=clockResidual(nominal,actual,node,offset,drift,lead)

if isempty(nominal), residual=zeros(0,1); return; end
solved=offset(node)+(1+drift(node)).*(actual-lead);
residual=abs(solved-nominal);

end


function [group,nominal]=logicalDataGroups(Q)

E=numel(Q.dataStartTime);
group=zeros(E,1);
nominal=zeros(0,1);
g=0;
lastFrame=NaN;
lastSlot=NaN;
for index=1:E
    if index==1 || Q.dataFrame(index)~=lastFrame || ...
            Q.dataSlot(index)~=lastSlot
        g=g+1;
        nominal(g,1)=Q.dataStartTime(index);
        lastFrame=Q.dataFrame(index);
        lastSlot=Q.dataSlot(index);
    elseif abs(Q.dataStartTime(index)-nominal(g))>1e-12
        error('applyDstrAffineClockSchedule: malformed logical DATA group.');
    end
    group(index)=g;
end

end


function [safe,minGap,maxSkew]=timingCertificate(Q,D)

start=zeros(0,1);
finish=zeros(0,1);
maxSkew=0;
groups=unique(Q.dataGroup,'stable')';
for g=groups
    index=Q.dataGroup==g;
    starts=Q.dataStartTime(index);
    start(end+1,1)=min(starts); %#ok<AGROW>
    finish(end+1,1)=max(starts)+D; %#ok<AGROW>
    maxSkew=max(maxSkew,max(starts)-min(starts));
    if max(starts)-min(starts)>=D-1e-12
        safe=false; minGap=-inf; return;
    end
end
for g=1:numel(Q.controlGroupStartTime)
    start(end+1,1)=Q.controlGroupStartTime(g); %#ok<AGROW>
    finish(end+1,1)=Q.controlGroupEndTime(g); %#ok<AGROW>
    maxSkew=max(maxSkew,finish(end)-start(end)-D);
end
if isempty(start)
    safe=true; minGap=inf; return;
end
[start,order]=sort(start);
finish=finish(order);
if isscalar(start)
    minGap=inf;
else
    minGap=min(start(2:end)-finish(1:end-1));
end
safe=minGap>=-1e-12;

end


function validateNonnegative(x,name)

if ~isscalar(x) || ~isfinite(x) || x<0
    error('applyDstrAffineClockSchedule: %s must be nonnegative finite.',name);
end

end
