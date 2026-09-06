function [accepted,state,reason]=elcsAcceptGrant(state,message,currentFrame,cfg)
%ELCSACCEPTGRANT Validate one client-side edge-lease GRANT.

requiredState={'node','epoch','frameLength','slot','grantExpiry', ...
    'grantOwnerSlot','grantClientSlot','lastGrantVersion'};
requiredMessage={'owner','client','epoch','frameLength','ownerSlot', ...
    'clientSlot','activationFrame','expiryFrame','version'};
if ~isstruct(state) || ~isscalar(state) || ...
        ~all(isfield(state,requiredState)) || ...
        ~isstruct(message) || ~isscalar(message) || ...
        ~all(isfield(message,requiredMessage))
    error('elcsAcceptGrant: malformed state or message.');
end
if ~isscalar(currentFrame) || ~isfinite(currentFrame) || currentFrame<1
    error('elcsAcceptGrant: currentFrame must be positive.');
end
accepted=false;
reason='';
owner=message.owner;
if message.client~=state.node
    reason='wrong-client'; return;
end
if owner<1 || owner>=state.node || owner>numel(state.grantExpiry)
    reason='wrong-owner'; return;
end
if message.epoch<state.epoch
    reason='stale-epoch'; return;
elseif message.epoch>state.epoch
    reason='future-epoch'; return;
end
if message.version<state.lastGrantVersion(owner)
    reason='stale-version'; return;
end
if message.frameLength~=state.frameLength || ...
        message.clientSlot~=state.slot || ...
        message.ownerSlot==message.clientSlot
    reason='tuple-mismatch'; return;
end
if message.activationFrame>currentFrame || ...
        message.expiryFrame-currentFrame<=cfg.leaseFenceFrames
    reason='outside-valid-window'; return;
end

state.grantExpiry(owner)=message.expiryFrame;
state.grantOwnerSlot(owner)=message.ownerSlot;
state.grantClientSlot(owner)=message.clientSlot;
state.lastGrantVersion(owner)=message.version;
accepted=true;
reason='accepted';

end
