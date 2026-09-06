function policy = macAwarePolicyConfig(cfg)
%MACAWAREPOLICYCONFIG Validate the additive MAC-aware policy contract.

policy=struct();
if isfield(cfg,'shared') && isfield(cfg.shared,'macAware') && ...
        ~isempty(cfg.shared.macAware)
    policy=cfg.shared.macAware;
end

policy=setDefault(policy,'busyWindow',0.25);
policy=setDefault(policy,'csmaMinAckDelay',0.10);
policy=setDefault(policy,'alohaMinAckDelay',0.02);
policy=setDefault(policy,'maxAckDeferral',0.50);
policy=setDefault(policy,'ackRecheckInterval',0.02);
policy=setDefault(policy,'ackBusyCeiling',0.75);
policy=setDefault(policy,'ackForceBusyCeiling',0.90);
policy=setDefault(policy,'newInfoBusyCeiling',0.80);
policy=setDefault(policy,'refreshBusyCeiling',0.65);
policy=setDefault(policy,'loadGuardEnabled',true);
policy=setDefault(policy,'accessScalingEnabled',true);

positive={'busyWindow','csmaMinAckDelay','alohaMinAckDelay', ...
    'maxAckDeferral','ackRecheckInterval'};
for k=1:numel(positive)
    value=policy.(positive{k});
    if ~isscalar(value) || ~isfinite(value) || value<=0
        error('macAwarePolicyConfig: %s must be positive.',positive{k});
    end
end

probability={'ackBusyCeiling','ackForceBusyCeiling', ...
    'newInfoBusyCeiling','refreshBusyCeiling'};
for k=1:numel(probability)
    value=policy.(probability{k});
    if ~isscalar(value) || ~isfinite(value) || value<0 || value>1
        error('macAwarePolicyConfig: %s must lie in [0,1].',probability{k});
    end
end

if max(policy.csmaMinAckDelay,policy.alohaMinAckDelay) > ...
        policy.maxAckDeferral
    error(['macAwarePolicyConfig: minimum ACK delays must not exceed ' ...
        'maxAckDeferral.']);
end
if policy.ackForceBusyCeiling < policy.ackBusyCeiling
    error(['macAwarePolicyConfig: ackForceBusyCeiling must not be below ' ...
        'ackBusyCeiling.']);
end

policy.loadGuardEnabled=validateLogical( ...
    policy.loadGuardEnabled,'loadGuardEnabled');
policy.accessScalingEnabled=validateLogical( ...
    policy.accessScalingEnabled,'accessScalingEnabled');

end


function value=validateLogical(value,name)

if ~isscalar(value) || ~(islogical(value) || any(value==[0 1]))
    error('macAwarePolicyConfig: %s must be scalar logical.',name);
end
value=logical(value);

end


function s=setDefault(s,name,value)

if ~isfield(s,name) || isempty(s.(name))
    s.(name)=value;
end

end
