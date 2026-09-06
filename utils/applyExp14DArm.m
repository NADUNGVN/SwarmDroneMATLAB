function [cfg,method,label]=applyExp14DArm(cfg,arm)
%APPLYEXP14DARM Apply one declared A-by-G-by-S factor combination.

required={'id','adaptiveAck','loadGuard','accessScaling'};
if ~isstruct(arm) || ~all(isfield(arm,required))
    error('applyExp14DArm: arm must contain the registered factor fields.');
end
factors=[arm.adaptiveAck arm.loadGuard arm.accessScaling];
if any(~ismember(factors,[0 1])) || any(size(factors)~=[1 3])
    error('applyExp14DArm: factor values must be scalar logical/binary.');
end
A=logical(arm.adaptiveAck);
G=logical(arm.loadGuard);
S=logical(arm.accessScaling);

cfg.shared.macAware=macAwarePolicyConfig(cfg);
cfg.shared.macAware.loadGuardEnabled=G;
cfg.shared.macAware.accessScalingEnabled=S;
if A
    method='mac-aware-broadcast';
    cfg.shared.feedbackMode='adaptive';
elseif G
    method='load-guarded-broadcast';
    cfg.shared.feedbackMode='hybrid';
else
    method='causal-broadcast';
    cfg.shared.feedbackMode='hybrid';
    if S
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    end
end

label=sprintf('A%d G%d S%d',A,G,S);
cfg.exp14d.arm=char(arm.id);
cfg.exp14d.adaptiveAck=A;
cfg.exp14d.loadGuard=G;
cfg.exp14d.accessScaling=S;
cfg.mac=sharedMediumConfig(cfg);

end
