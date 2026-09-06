function Q=addLocalMigrationEmergencyData(Q,M,C,emergencySlot)
%ADDLOCALMIGRATIONEMERGENCYDATA Add protected DATA while lease is silent.
%
% The emergency slot must be outside both retiring and candidate colorings.
% It carries only the transition node, so it does not authorize reuse of an
% uncertified shared slot. Receiver outcomes are bound separately afterwards.

required={'frameStartTime','frameDurationSec','claimPhaseDurationSec', ...
    'responsePhaseDurationSec','slotDurationSec','dataStartTime', ...
    'dataNode','dataSlot','dataFrame','dataGroup','dataKind','kernel', ...
    'logicalOpportunityHashExact','hashExact'};
if ~isstruct(Q) || ~isscalar(Q) || ~all(isfield(Q,required)) || ...
        ~isscalar(emergencySlot) || emergencySlot<1 || ...
        emergencySlot~=floor(emergencySlot)
    error('addLocalMigrationEmergencyData: invalid input.');
end
node=M.transitionNode;
if emergencySlot>M.config.maxDataSlots || ...
        any(M.oldSlot==emergencySlot) || any(M.candidateSlot==emergencySlot)
    error(['addLocalMigrationEmergencyData: emergency slot must be ' ...
        'outside both certified colorings.']);
end
F=numel(Q.frameStartTime);
if size(Q.kernel.debug.suppressed,1)<F || C.maxFrames<F
    error('addLocalMigrationEmergencyData: kernel coverage is incomplete.');
end
frames=find(Q.kernel.debug.suppressed(1:F,node));
if isempty(frames)
    Q.emergencyData=emptyCertificate(emergencySlot,node);
    return;
end
dataOffset=Q.claimPhaseDurationSec+Q.responsePhaseDurationSec;
start=Q.frameStartTime(frames)+dataOffset+ ...
    (emergencySlot-1)*Q.slotDurationSec;
if any(start+Q.airtimeSec>Q.horizonSec+1e-12)
    error('addLocalMigrationEmergencyData: emergency DATA exceeds horizon.');
end
next=max([0;Q.dataGroup])+1;
groups=(next:next+numel(frames)-1)';
Q.dataStartTime=[Q.dataStartTime;start];
Q.dataNode=[Q.dataNode;repmat(node,numel(frames),1)];
Q.dataSlot=[Q.dataSlot;repmat(emergencySlot,numel(frames),1)];
Q.dataFrame=[Q.dataFrame;frames(:)];
Q.dataGroup=[Q.dataGroup;groups];
Q.dataKind=[Q.dataKind;repmat("emergency",numel(frames),1)];
N=M.N;
Q.dataSuccessMask=[Q.dataSuccessMask;false(numel(frames),N)];
Q.dataErasureMask=[Q.dataErasureMask;false(numel(frames),N)];
Q.dataCollisionMask=[Q.dataCollisionMask;false(numel(frames),N)];
Q.dataCompletesByHorizon=[Q.dataCompletesByHorizon;true(numel(frames),1)];
[~,order]=sortrows([Q.dataStartTime Q.dataNode],[1 2]);
fields={'dataStartTime','dataNode','dataSlot','dataFrame','dataGroup', ...
    'dataKind','dataCompletesByHorizon'};
for k=1:numel(fields), Q.(fields{k})=Q.(fields{k})(order,:); end
Q.dataSuccessMask=Q.dataSuccessMask(order,:);
Q.dataErasureMask=Q.dataErasureMask(order,:);
Q.dataCollisionMask=Q.dataCollisionMask(order,:);
Q.emergencyData=struct('version','LOCAL-MIGRATION-EMERGENCY-DATA-v1', ...
    'enabled',true,'slot',emergencySlot,'node',node, ...
    'opportunities',numel(frames),'firstFrame',frames(1), ...
    'lastFrame',frames(end),'frameHashExact', ...
    realizationHash(frames(:)));
Q.logicalOpportunityHashExact=realizationHash([ ...
    Q.logicalOpportunityHashExact;frames(:);emergencySlot;node]);
Q.hashExact=realizationHash([Q.hashExact;start;frames(:); ...
    emergencySlot;node;Q.emergencyData.frameHashExact]);

end


function E=emptyCertificate(slot,node)
E=struct('version','LOCAL-MIGRATION-EMERGENCY-DATA-v1', ...
    'enabled',true,'slot',slot,'node',node,'opportunities',0, ...
    'firstFrame',NaN,'lastFrame',NaN,'frameHashExact', ...
    realizationHash(zeros(0,1)));
end
