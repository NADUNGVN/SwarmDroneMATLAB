function [allow,nextDue,info]=capacityGatedStandaloneAckDecision( ...
    net,node,tk,cfg)
%CAPACITYGATEDSTANDALONEACKDECISION Fixed route after capacity abstention.

if node<1 || node>net.N || node~=floor(node) || ...
        ~isscalar(tk) || ~isfinite(tk) || tk<0
    error('capacityGatedStandaloneAckDecision: invalid node or time.');
end
if isempty(net.pendingAck{node}) || ~isfinite(net.pendingAckSince(node))
    error('capacityGatedStandaloneAckDecision: no pending ACK obligation.');
end
policy=contextAwarePolicyConfig(cfg);
if ~policy.enabled || ~strcmp(policy.routeRule,'capacity-gated-mac')
    error('capacityGatedStandaloneAckDecision: route is not enabled.');
end
aware=macAwarePolicyConfig(cfg);
mac=sharedMediumConfig(cfg);
capacity=contextAwareServiceCertificate(cfg);
pendingAge=max(tk-net.pendingAckSince(node),0);
busy=net.localBusyEWMA(node);
if strcmpi(mac.type,'aloha')
    minimumDelay=aware.alohaMinAckDelay;
else
    minimumDelay=aware.csmaMinAckDelay;
end

allow=false; forced=false; evaluated=false;
feasible=capacity.feasible;
valuePositive=false;
reason='minimum-delay';
nextDue=net.pendingAckSince(node)+minimumDelay;
if pendingAge+1e-12>=minimumDelay
    evaluated=true;
    if ~capacity.feasible
        reason='capacity-abstain';
        nextDue=tk+aware.ackRecheckInterval;
    elseif ~strcmpi(mac.type,'aloha')
        reason='feasible-piggyback-route';
        nextDue=tk+aware.ackRecheckInterval;
    elseif busy<=aware.ackBusyCeiling+1e-12
        allow=true; valuePositive=true; reason='feasible-aloha-adaptive';
        nextDue=inf;
    elseif pendingAge+1e-12>=aware.maxAckDeferral && ...
            busy<=aware.ackForceBusyCeiling+1e-12
        allow=true; forced=true; valuePositive=true;
        reason='feasible-aloha-forced'; nextDue=inf;
    else
        reason='feasible-aloha-busy-defer';
        nextDue=tk+aware.ackRecheckInterval;
    end
end

info=struct('allow',allow,'forced',forced,'reason',reason, ...
    'rule','capacity-gated-mac','contextDecision',true, ...
    'evaluated',evaluated,'pendingAge',pendingAge,'localBusy',busy, ...
    'minimumDelay',minimumDelay,'feasible',feasible, ...
    'valuePositive',valuePositive, ...
    'capacityFeasible',capacity.feasible, ...
    'successfulUpdateRateHz',capacity.successfulUpdateRateHz, ...
    'requiredUpdateRateHz',capacity.requiredUpdateRateHz, ...
    'serviceRatio',capacity.serviceRatio);

end
