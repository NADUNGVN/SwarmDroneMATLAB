function [allow,info] = macAwareLoadGuard( ...
    requested,branch,localBusy,queueDepth,cfg)
%MACAWARELOADGUARD Causal branch-aware DATA admission decision.
%
% The guard reads only locally carrier-sensed busy state and local queue
% depth. Hard innovation (branches 1/2) and max-silence recovery (branch 5)
% are protected. Collision and receiver-delivery truth are not inputs.

if ~isscalar(requested) || ...
        ~(islogical(requested) || any(requested==[0 1]))
    error('macAwareLoadGuard: requested must be scalar logical.');
end
if ~isscalar(branch) || ~isfinite(branch) || branch~=floor(branch) || ...
        branch<0 || branch>5
    error('macAwareLoadGuard: branch must be an integer in [0,5].');
end
if ~isscalar(localBusy) || ~isfinite(localBusy) || ...
        localBusy<0 || localBusy>1+1e-12
    error('macAwareLoadGuard: localBusy must lie in [0,1].');
end
if ~isscalar(queueDepth) || ~isfinite(queueDepth) || ...
        queueDepth<0 || queueDepth~=floor(queueDepth)
    error('macAwareLoadGuard: queueDepth must be a nonnegative integer.');
end

policy=macAwarePolicyConfig(cfg);
info=struct('requested',logical(requested),'branch',branch, ...
    'localBusy',localBusy,'queueDepth',queueDepth, ...
    'blockedByBusy',false,'blockedByQueue',false, ...
    'protectedBranch',false,'reason','not-requested');
allow=logical(requested);

if ~requested
    return;
end
if branch==0
    error('macAwareLoadGuard: a requested transmission must name a branch.');
end
if ~policy.loadGuardEnabled
    info.reason='guard-disabled';
    return;
end

if any(branch==[1 2 5])
    info.protectedBranch=true;
    info.reason='protected';
    return;
end

if branch==3
    ceiling=policy.newInfoBusyCeiling;
else
    ceiling=policy.refreshBusyCeiling;
end
info.blockedByBusy=localBusy>ceiling;
info.blockedByQueue=queueDepth>0;
allow=~info.blockedByBusy && ~info.blockedByQueue;
if allow
    info.reason='allowed';
elseif info.blockedByBusy && info.blockedByQueue
    info.reason='busy-and-queued';
elseif info.blockedByBusy
    info.reason='busy';
else
    info.reason='queued';
end

end
