function A=auditLegacyManagementFloodDetectability(plan)
%AUDITLEGACYMANAGEMENTFLOODDETECTABILITY Independent old/new collision audit.
%
% Reconstruct the legacy coloring that treated only selected tree edges as
% decodable, then evaluate both legacy and current slots against an oracle
% using full direct reach, physical interference, and half duplex.

required={'N','admissible','children','depth','transmitterMask', ...
    'transmitterSlot','physicalInterference','directReach','hashExact'};
if ~isstruct(plan)||~isscalar(plan)||~all(isfield(plan,required))|| ...
        ~plan.admissible
    error('auditLegacyManagementFloodDetectability: invalid plan.');
end
N=plan.N;
legacyConflict=buildSenderConflictGraph( ...
    plan.children,plan.physicalInterference);
legacySlot=zeros(N,1); slotOffset=0;
maxDepth=max([0;plan.depth(plan.transmitterMask&isfinite(plan.depth))]);
for depth=0:maxDepth
    transmitters=find(plan.transmitterMask&plan.depth==depth);
    if isempty(transmitters), continue; end
    local=legacyConflict(transmitters,transmitters);
    color=elcsWitnessPriorityColor(local);
    legacySlot(transmitters)=slotOffset+color;
    slotOffset=slotOffset+max(color);
end
[legacyCollisions,legacyCollisionSlots]=oracleCollisions(plan,legacySlot);
[currentCollisions,currentCollisionSlots]=oracleCollisions( ...
    plan,plan.transmitterSlot);
A=struct('version','LEGACY-ROUTE-DETECTABILITY-AUDIT-v1', ...
    'planHash',plan.hashExact,'legacyConflictGraph',legacyConflict, ...
    'legacyTransmitterSlot',legacySlot, ...
    'legacyReservedSlotCount',slotOffset, ...
    'currentReservedSlotCount',max(plan.transmitterSlot), ...
    'legacyOracleCollisionRecipients',legacyCollisions, ...
    'legacyOracleCollisionSlots',legacyCollisionSlots, ...
    'currentOracleCollisionRecipients',currentCollisions, ...
    'currentOracleCollisionSlots',currentCollisionSlots, ...
    'legacyInvalid',double(legacyCollisions>0), ...
    'currentValid',double(currentCollisions==0), ...
    'additionalSlots',max(plan.transmitterSlot)-slotOffset, ...
    'hashExact',realizationHash([plan.hashExact; ...
    double(legacyConflict(:));legacySlot;slotOffset;legacyCollisions; ...
    legacyCollisionSlots;currentCollisions;currentCollisionSlots]));

end


function [collisions,collisionSlots]=oracleCollisions(plan,slot)

collisions=0; collisionSlotMask=false(max([0;slot]),1);
for slotIndex=1:numel(collisionSlotMask)
    active=find(slot==slotIndex);
    for sender=reshape(active,1,[])
        for receiver=reshape(find(plan.children(:,sender)),1,[])
            other=active(active~=sender);
            detectable=reshape(plan.physicalInterference( ...
                receiver,other)|plan.directReach(receiver,other),[],1);
            collision=any(other==receiver|detectable);
            collisions=collisions+collision;
            collisionSlotMask(slotIndex)= ...
                collisionSlotMask(slotIndex)|collision;
        end
    end
end
collisionSlots=nnz(collisionSlotMask);

end
