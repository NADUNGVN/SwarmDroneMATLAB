function Q=addReceiverClosureEmergencyData(Q,M,emergencySlot)
%ADDRECEIVERCLOSUREEMERGENCYDATA Protected closure service.
%
% A scalar slot selects capacity-saving round robin. A vector with at least
% one entry per affected node assigns a distinct protected slot to every
% currently suppressed sender in every frame. Protected slots are outside
% every retiring and candidate color, so no uncertified reuse is implied.

required={'frameStartTime','phase1DurationSec','phase2DurationSec', ...
    'commitPhaseDurationSec','slotDurationSec','dataStartTime', ...
    'dataNode','dataSlot','dataFrame','dataGroup','dataKind', ...
    'dataSuccessMask','dataErasureMask','dataCollisionMask', ...
    'dataCompletesByHorizon','kernel','logicalOpportunityHashExact', ...
    'hashExact'};
slots=reshape(double(emergencySlot),[],1);
if ~isstruct(Q)||~isscalar(Q)||~all(isfield(Q,required))|| ...
        isempty(slots)||any(~isfinite(slots))||any(slots<1)|| ...
        any(slots~=floor(slots))||numel(unique(slots))~=numel(slots)
    error('addReceiverClosureEmergencyData: invalid input.');
end
if any(slots>M.config.maxDataSlots)|| ...
        any(ismember(slots,M.oldSlot))|| ...
        any(ismember(slots,M.candidateSlot))
    error(['addReceiverClosureEmergencyData: protected slot must be ' ...
        'outside retiring and candidate colorings.']);
end
affected=reshape(M.affectedNodes,[],1); S=numel(affected);
parallel=numel(slots)>=S;
F=numel(Q.frameStartTime);
if size(Q.kernel.debug.suppressed,1)<F
    error('addReceiverClosureEmergencyData: kernel history incomplete.');
end

frames=zeros(0,1); nodes=zeros(0,1); usedSlots=zeros(0,1); cursor=1;
for frame=1:F
    suppressed=logical(Q.kernel.debug.suppressed(frame,affected));
    if ~any(suppressed), continue; end
    if parallel
        chosen=find(suppressed);
        frames=[frames;repmat(frame,numel(chosen),1)]; %#ok<AGROW>
        nodes=[nodes;affected(chosen)]; %#ok<AGROW>
        usedSlots=[usedSlots;slots(chosen)]; %#ok<AGROW>
    else
        order=mod((cursor-1:cursor+S-2),S)+1;
        chosen=order(find(suppressed(order),1));
        frames(end+1,1)=frame; nodes(end+1,1)=affected(chosen); %#ok<AGROW>
        usedSlots(end+1,1)=slots(1); %#ok<AGROW>
        cursor=mod(chosen,S)+1;
    end
end
if isempty(frames)
    Q.emergencyData=emptyCertificate(slots,affected,parallel);
    return;
end
dataOffset=Q.phase1DurationSec+Q.phase2DurationSec+ ...
    Q.commitPhaseDurationSec;
start=Q.frameStartTime(frames)+dataOffset+ ...
    (usedSlots-1)*Q.slotDurationSec;
if any(start+Q.airtimeSec>Q.horizonSec+1e-12)
    error('addReceiverClosureEmergencyData: horizon overflow.');
end
next=max([0;Q.dataGroup])+1;
groups=(next:next+numel(frames)-1)'; N=M.N;
Q.dataStartTime=[Q.dataStartTime;start];
Q.dataNode=[Q.dataNode;nodes];
Q.dataSlot=[Q.dataSlot;usedSlots];
Q.dataFrame=[Q.dataFrame;frames]; Q.dataGroup=[Q.dataGroup;groups];
Q.dataKind=[Q.dataKind;repmat("emergency",numel(frames),1)];
Q.dataSuccessMask=[Q.dataSuccessMask;false(numel(frames),N)];
Q.dataErasureMask=[Q.dataErasureMask;false(numel(frames),N)];
Q.dataCollisionMask=[Q.dataCollisionMask;false(numel(frames),N)];
Q.dataCompletesByHorizon=[Q.dataCompletesByHorizon;true(numel(frames),1)];
[~,index]=sortrows([Q.dataStartTime Q.dataNode],[1 2]);
fields={'dataStartTime','dataNode','dataSlot','dataFrame','dataGroup', ...
    'dataKind','dataCompletesByHorizon'};
for k=1:numel(fields), Q.(fields{k})=Q.(fields{k})(index,:); end
Q.dataSuccessMask=Q.dataSuccessMask(index,:);
Q.dataErasureMask=Q.dataErasureMask(index,:);
Q.dataCollisionMask=Q.dataCollisionMask(index,:);

opportunities=zeros(N,1);
for node=reshape(affected,1,[]), opportunities(node)=nnz(nodes==node); end
Q.emergencyData=struct('version', ...
    'RECEIVER-CLOSURE-PROTECTED-EMERGENCY-v2', ...
    'enabled',true,'mode',ternary(parallel,'parallel','round-robin'), ...
    'slots',slots,'affectedNodes',affected, ...
    'opportunities',numel(frames),'nodeOpportunities',opportunities, ...
    'firstFrame',frames(1),'lastFrame',frames(end), ...
    'maximumNominalServiceGapFrames',ternary(parallel,1,S), ...
    'scheduleHashExact',realizationHash([frames;nodes;usedSlots]));
Q.logicalOpportunityHashExact=realizationHash([ ...
    Q.logicalOpportunityHashExact;frames;nodes;usedSlots]);
Q.hashExact=realizationHash([Q.hashExact;start;frames;nodes; ...
    usedSlots;Q.emergencyData.scheduleHashExact]);

end


function E=emptyCertificate(slots,affected,parallel)

E=struct('version','RECEIVER-CLOSURE-PROTECTED-EMERGENCY-v2', ...
    'enabled',true,'mode',ternary(parallel,'parallel','round-robin'), ...
    'slots',slots,'affectedNodes',affected, ...
    'opportunities',0,'nodeOpportunities',zeros(max(affected),1), ...
    'firstFrame',NaN,'lastFrame',NaN, ...
    'maximumNominalServiceGapFrames', ...
    ternary(parallel,1,numel(affected)), ...
    'scheduleHashExact',realizationHash(zeros(0,1)));

end


function value=ternary(condition,a,b)
if condition, value=a; else, value=b; end
end
