function [cfg,method,label]=applyExp17Arm(cfg,arm)
%APPLYEXP17ARM Apply a fixed MAC-by-feedback-route arm.

required={'id','label','macType','route'};
if ~isstruct(arm) || ~all(isfield(arm,required))
    error('applyExp17Arm: arm does not satisfy the registry contract.');
end
macType=lower(strtrim(char(arm.macType)));
if ~any(strcmp(macType,{'csma','aloha'}))
    error('applyExp17Arm: MAC factor must be csma or aloha.');
end
cfg.mac.type=macType;
cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);

route=lower(strtrim(char(arm.route)));
switch route
    case 'adaptive'
        factor=struct('id','exp17-adaptive','adaptiveAck',true, ...
            'loadGuard',false,'accessScaling',true);
        [cfg,method]=applyExp14DArm(cfg,factor);
    case 'piggyback'
        method='causal-broadcast';
        cfg.shared.feedbackMode='piggyback';
    otherwise
        error('applyExp17Arm: unknown route "%s".',route);
end

label=char(arm.label);
cfg.exp17.arm=char(arm.id);
cfg.exp17.macType=macType;
cfg.exp17.route=route;
cfg.mac=sharedMediumConfig(cfg);

end

