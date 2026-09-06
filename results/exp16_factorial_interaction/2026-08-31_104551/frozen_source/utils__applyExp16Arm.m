function [cfg,method,label]=applyExp16Arm(cfg,arm)
%APPLYEXP16ARM Apply one registered MAC-by-feedback-route arm.

required={'id','label','macType','route','primaryFactorial'};
if ~isstruct(arm) || ~all(isfield(arm,required))
    error('applyExp16Arm: arm does not satisfy the registry contract.');
end
macType=lower(strtrim(char(arm.macType)));
if ~any(strcmp(macType,{'csma','aloha'}))
    error('applyExp16Arm: MAC factor must be csma or aloha.');
end
cfg.mac.type=macType;
cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);

route=lower(strtrim(char(arm.route)));
switch route
    case 'adaptive'
        factor=struct('id','exp16-adaptive','adaptiveAck',true, ...
            'loadGuard',false,'accessScaling',true);
        [cfg,method]=applyExp14DArm(cfg,factor);
    case 'piggyback'
        method='causal-broadcast';
        cfg.shared.feedbackMode='piggyback';
    case 'fixed-hybrid'
        factor=struct('id','exp16-fixed-hybrid','adaptiveAck',false, ...
            'loadGuard',false,'accessScaling',true);
        [cfg,method]=applyExp14DArm(cfg,factor);
    otherwise
        error('applyExp16Arm: unknown feedback route "%s".',route);
end

label=char(arm.label);
cfg.exp16.arm=char(arm.id);
cfg.exp16.macType=macType;
cfg.exp16.route=route;
cfg.exp16.primaryFactorial=logical(arm.primaryFactorial);
cfg.mac=sharedMediumConfig(cfg);

end

