function [cfg,method,label]=applyExp14CArm(cfg,armId)
%APPLYEXP14CARM Apply one closed MAC-aware mechanism ablation.

armId=lower(strtrim(char(armId)));
cfg.shared.macAware=macAwarePolicyConfig(cfg);

switch armId
    case 'frozen-hybrid'
        method='causal-broadcast';
        label='Frozen hybrid';
        cfg.shared.feedbackMode='hybrid';

    case 'frozen-piggyback'
        method='causal-broadcast';
        label='Frozen piggyback';
        cfg.shared.feedbackMode='piggyback';

    case 'adaptive-only'
        method='mac-aware-broadcast';
        label='Adaptive ACK only';
        cfg.shared.feedbackMode='adaptive';
        cfg.shared.macAware.loadGuardEnabled=false;
        cfg.shared.macAware.accessScalingEnabled=false;

    case 'access-only'
        method='causal-broadcast';
        label='Access scaling only';
        cfg.shared.feedbackMode='hybrid';
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);

    case 'guarded-adaptive'
        method='mac-aware-broadcast';
        label='Adaptive ACK + guard';
        cfg.shared.feedbackMode='adaptive';
        cfg.shared.macAware.loadGuardEnabled=true;
        cfg.shared.macAware.accessScalingEnabled=false;

    case 'full-v2'
        method='mac-aware-broadcast';
        label='Full MAC-aware v2';
        cfg.shared.feedbackMode='adaptive';
        cfg.shared.macAware.loadGuardEnabled=true;
        cfg.shared.macAware.accessScalingEnabled=true;

    otherwise
        error('applyExp14CArm: unknown arm "%s".',armId);
end

cfg.exp14c.arm=armId;
cfg.mac=sharedMediumConfig(cfg);

end
