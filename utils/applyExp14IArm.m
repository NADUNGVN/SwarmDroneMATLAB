function [cfg,method,label,route]=applyExp14IArm(cfg,arm)
%APPLYEXP14IARM Apply one frozen EXP14I feedback arm.

if ~isstruct(cfg) || ~isfield(cfg,'mac') || ~isfield(cfg.mac,'type')
    error('applyExp14IArm: cfg.mac.type is required.');
end
if ~isstruct(arm) || ~all(isfield(arm,{'id','label'}))
    error('applyExp14IArm: arm does not satisfy the registry contract.');
end
id=lower(strtrim(char(arm.id)));
macType=lower(strtrim(char(cfg.mac.type)));
switch id
    case 'mac-selective-scaled'
        switch macType
            case 'csma'
                [cfg,method,route]=applyRoute(cfg,'piggyback');
            case 'aloha'
                [cfg,method,route]=applyRoute(cfg,'adaptive');
            otherwise
                error('applyExp14IArm: MAC-selective route is undefined for "%s".', ...
                    macType);
        end
    case 'fixed-adaptive-scaled'
        [cfg,method,route]=applyRoute(cfg,'adaptive');
    case 'fixed-piggyback-scaled'
        [cfg,method,route]=applyRoute(cfg,'piggyback');
    case 'access-only-scaled'
        [cfg,method,route]=applyRoute(cfg,'access-only');
    otherwise
        error('applyExp14IArm: unknown arm "%s".',id);
end

label=char(arm.label);
cfg.exp14i.arm=id;
cfg.exp14i.route=route;
cfg.exp14i.mappingInput='mac.type';
cfg.mac=sharedMediumConfig(cfg);

end


function [cfg,method,route]=applyRoute(cfg,route)

switch route
    case 'adaptive'
        factor=struct('id','exp14i-adaptive','adaptiveAck',true, ...
            'loadGuard',false,'accessScaling',true);
        [cfg,method]=applyExp14DArm(cfg,factor);
    case 'piggyback'
        method='causal-broadcast';
        cfg.shared.feedbackMode='piggyback';
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    case 'access-only'
        factor=struct('id','exp14i-access-only','adaptiveAck',false, ...
            'loadGuard',false,'accessScaling',true);
        [cfg,method]=applyExp14DArm(cfg,factor);
    otherwise
        error('applyExp14IArm: internal route "%s" is invalid.',route);
end

end
