function [cfg,method,label,details]=applyExp18Arm(cfg,arm)
%APPLYEXP18ARM Apply one development decomposition arm.

required={'id','label','accessDesign','ackDesign'};
if ~isstruct(arm) || ~all(isfield(arm,required))
    error('applyExp18Arm: arm does not satisfy the registry contract.');
end

macType=lower(strtrim(char(cfg.mac.type)));
cfg.shared.macAware=macAwarePolicyConfig(cfg);
cfg.shared.macAware.loadGuardEnabled=false;
cfg.shared.macAware.accessScalingEnabled=false;
cfg.shared.contextAware=struct('enabled',false);

switch arm.id
    case 'legacy-selector'
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
        if strcmp(macType,'aloha')
            method='mac-aware-broadcast';
            cfg.shared.feedbackMode='adaptive';
            cfg.shared.macAware.accessScalingEnabled=true;
            route='adaptive';
        else
            method='causal-broadcast';
            cfg.shared.feedbackMode='piggyback';
            route='piggyback';
        end

    case 'frame-piggyback'
        cfg.mac.pAccess=frameAwareP(cfg);
        method='causal-broadcast';
        cfg.shared.feedbackMode='piggyback';
        route='piggyback';

    case 'frame-adaptive'
        cfg.mac.pAccess=frameAwareP(cfg);
        method='mac-aware-broadcast';
        cfg.shared.feedbackMode='adaptive';
        route='adaptive';

    case 'context-aware'
        method='context-aware-broadcast';
        cfg.shared.feedbackMode='adaptive';
        cfg.shared.contextAware=struct('enabled',true, ...
            'accessRule','frame-aware', ...
            'calibrationSource','declared-stationary-profile');
        if isfield(cfg,'exp18') && contains(cfg.exp18.cell,'reverse')
            nominal=study2Exp14Config(cfg.net.seed,'moderate');
            nominal.shared.contextAware=struct('enabled',true, ...
                'accessRule','frame-aware');
            nominalPolicy=contextAwarePolicyConfig(nominal);
            cfg.shared.contextAware.ackSuccessEstimate= ...
                nominalPolicy.ackSuccessEstimate;
            cfg.shared.contextAware.calibrationSource= ...
                'nominal-moderate-mismatch';
        end
        cfg.shared.contextAware=contextAwarePolicyConfig(cfg);
        cfg.mac.pAccess=contextAwareAccessProbability(cfg);
        route='context-aware';

    otherwise
        error('applyExp18Arm: unknown arm "%s".',arm.id);
end

label=char(arm.label);
cfg.exp18.arm=char(arm.id);
cfg.exp18.accessDesign=char(arm.accessDesign);
cfg.exp18.ackDesign=char(arm.ackDesign);
cfg.exp18.route=route;
cfg.mac=sharedMediumConfig(cfg);
details=struct('route',route,'accessDesign',char(arm.accessDesign), ...
    'ackDesign',char(arm.ackDesign),'pAccess',cfg.mac.pAccess);

end


function p=frameAwareP(cfg)

tmp=cfg;
tmp.shared.contextAware=struct('enabled',true, ...
    'accessRule','frame-aware', ...
    'calibrationSource','declared-stationary-profile');
tmp.shared.contextAware=contextAwarePolicyConfig(tmp);
p=contextAwareAccessProbability(tmp);

end
