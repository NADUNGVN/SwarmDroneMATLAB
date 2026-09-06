function [cfg,method,label]=applyExp14FArm(cfg,arm)
%APPLYEXP14FARM Apply an EXP14F actual or shadow arm.

if ~isstruct(arm) || ~isscalar(arm) || ...
        ~all(isfield(arm,{'id','label'}))
    error('applyExp14FArm: arm does not satisfy the registry contract.');
end
R=exp14eRegistry();
id=lower(strtrim(char(arm.id)));
source=find(strcmp({R.arms.id},id),1);
if isempty(source) || ~ismember(id, ...
        {'selected-adaptive-scaled','piggyback-scaled'})
    error('applyExp14FArm: unknown arm "%s".',id);
end
[cfg,method,label]=applyExp14EArm(cfg,R.arms(source));
cfg.exp14f.arm=id;
cfg.exp14f.role=char(roleForArm(id));
cfg.shared.ackValueLogging=struct( ...
    'enabled',true,'schema','ACK-VALUE-EVENT-v1');
cfg.mac=sharedMediumConfig(cfg);

end


function role=roleForArm(id)

if strcmp(id,'selected-adaptive-scaled')
    role="actual";
else
    role="shadow";
end

end
