function policy=contextAwarePolicyConfig(cfg)
%CONTEXTAWAREPOLICYCONFIG Validate feasibility-first feedback configuration.
%
% The default is inert.  When enabled, all numerical quantities come from
% declared frame geometry, the existing semantic trigger, the acceleration
% bound and a stationary/calibrated reverse-link success estimate.

policy=struct();
if isfield(cfg,'shared') && isfield(cfg.shared,'contextAware') && ...
        ~isempty(cfg.shared.contextAware)
    policy=cfg.shared.contextAware;
end

policy=setDefault(policy,'enabled',false);
policy=setDefault(policy,'accessRule','frame-aware');
policy=setDefault(policy,'calibrationSource','declared-stationary-profile');

policy.enabled=validateLogical(policy.enabled,'enabled');
policy.accessRule=lower(strtrim(char(policy.accessRule)));
if ~any(strcmp(policy.accessRule,{'legacy-n','frame-aware'}))
    error(['contextAwarePolicyConfig: accessRule must be legacy-n or ' ...
        'frame-aware.']);
end
policy.calibrationSource=strtrim(char(policy.calibrationSource));
if isempty(policy.calibrationSource)
    error('contextAwarePolicyConfig: calibrationSource must be nonempty.');
end
if ~policy.enabled
    policy=setDefault(policy,'semanticPositionBudget',NaN);
    policy=setDefault(policy,'maxSilence',NaN);
    policy=setDefault(policy,'accelerationBound',NaN);
    policy=setDefault(policy,'ackSuccessEstimate',NaN);
    return;
end

if ~isfield(cfg,'aoiEvent') || ...
        ~isfield(cfg.aoiEvent,'posThreshold') || ...
        ~isfield(cfg.aoiEvent,'maxSilence')
    error(['contextAwarePolicyConfig: aoiEvent.posThreshold and ' ...
        'aoiEvent.maxSilence are required.']);
end
if ~isfield(cfg,'swarm') || ~isfield(cfg.swarm,'maxAccel') || ...
        ~isfield(cfg.swarm,'N')
    error(['contextAwarePolicyConfig: swarm.N and swarm.maxAccel are ' ...
        'required.']);
end

policy=setDefault(policy,'semanticPositionBudget', ...
    cfg.aoiEvent.posThreshold);
policy=setDefault(policy,'maxSilence',cfg.aoiEvent.maxSilence);
policy=setDefault(policy,'accelerationBound',cfg.swarm.maxAccel);
if ~isfield(policy,'ackSuccessEstimate') || ...
        isempty(policy.ackSuccessEstimate)
    policy.ackSuccessEstimate=stationaryAckSuccess(cfg);
end

positive={'semanticPositionBudget','maxSilence','accelerationBound'};
for k=1:numel(positive)
    x=policy.(positive{k});
    if ~isscalar(x) || ~isfinite(x) || x<=0
        error('contextAwarePolicyConfig: %s must be positive.',positive{k});
    end
end

N=cfg.swarm.N;
s=policy.ackSuccessEstimate;
if ~(isscalar(s) || isequal(size(s),[N N])) || ...
        any(~isfinite(s(:)) | s(:)<0 | s(:)>1)
    error(['contextAwarePolicyConfig: ackSuccessEstimate must be a ' ...
        'probability scalar or N-by-N map.']);
end

end


function success=stationaryAckSuccess(cfg)

mac=sharedMediumConfig(cfg);
N=cfg.swarm.N;
goodLoss=expandMap(mac.burst.ackGoodLoss,N);
badLoss=expandMap(mac.burst.ackBadLoss,N);
goodToBad=expandMap(mac.burst.ackGoodToBad,N);
badToGood=expandMap(mac.burst.ackBadToGood,N);
denominator=goodToBad+badToGood;
stationaryBad=zeros(N);
moving=denominator>0;
stationaryBad(moving)=goodToBad(moving)./denominator(moving);
meanLoss=(1-stationaryBad).*goodLoss+stationaryBad.*badLoss;
success=1-meanLoss;

end


function y=expandMap(x,N)

if isscalar(x)
    y=repmat(x,N,N);
else
    y=x;
end

end


function value=validateLogical(value,name)

if ~isscalar(value) || ~(islogical(value) || any(value==[0 1]))
    error('contextAwarePolicyConfig: %s must be scalar logical.',name);
end
value=logical(value);

end


function s=setDefault(s,name,value)

if ~isfield(s,name) || isempty(s.(name))
    s.(name)=value;
end

end
