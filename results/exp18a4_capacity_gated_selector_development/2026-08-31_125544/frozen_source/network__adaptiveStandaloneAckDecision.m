function [allow,nextDue,info] = adaptiveStandaloneAckDecision( ...
    net,node,tk,cfg)
%ADAPTIVESTANDALONEACKDECISION Causal standalone-ACK fallback decision.

if node<1 || node>net.N || node~=floor(node)
    error('adaptiveStandaloneAckDecision: node is out of range.');
end
if ~isscalar(tk) || ~isfinite(tk) || tk<0
    error('adaptiveStandaloneAckDecision: tk must be nonnegative.');
end
if isempty(net.pendingAck{node}) || ~isfinite(net.pendingAckSince(node))
    error('adaptiveStandaloneAckDecision: node has no pending ACK obligation.');
end

policy=macAwarePolicyConfig(cfg);
context=contextAwarePolicyConfig(cfg);
if context.enabled
    if strcmp(context.routeRule,'capacity-gated-mac')
        [allow,nextDue,info]=capacityGatedStandaloneAckDecision( ...
            net,node,tk,cfg);
    else
        [allow,nextDue,info]=contextAwareStandaloneAckDecision( ...
            net,node,tk,cfg);
    end
    return;
end
mac=sharedMediumConfig(cfg);
age=max(tk-net.pendingAckSince(node),0);
busy=net.localBusyEWMA(node);
if ~isfinite(busy) || busy<0 || busy>1+1e-12
    error('adaptiveStandaloneAckDecision: invalid local busy estimate.');
end

if strcmpi(mac.type,'aloha')
    minDelay=policy.alohaMinAckDelay;
else
    minDelay=policy.csmaMinAckDelay;
end

allow=false;
forced=false;
reason='minimum-delay';
nextDue=net.pendingAckSince(node)+minDelay;
if age+1e-12>=minDelay
    if busy<=policy.ackBusyCeiling+1e-12
        allow=true;
        reason='ordinary';
        nextDue=inf;
    elseif age+1e-12>=policy.maxAckDeferral && ...
            busy<=policy.ackForceBusyCeiling+1e-12
        allow=true;
        forced=true;
        reason='max-deferral';
        nextDue=inf;
    else
        reason='busy-defer';
        nextDue=tk+policy.ackRecheckInterval;
    end
end

info=struct('allow',allow,'forced',forced,'reason',reason, ...
    'pendingAge',age,'localBusy',busy,'minimumDelay',minDelay);

end
