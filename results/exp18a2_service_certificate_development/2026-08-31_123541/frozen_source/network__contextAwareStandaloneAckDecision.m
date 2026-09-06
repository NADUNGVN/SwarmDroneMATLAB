function [allow,nextDue,info]=contextAwareStandaloneAckDecision( ...
    net,node,tk,cfg)
%CONTEXTAWARESTANDALONEACKDECISION Causal feasibility/value ACK decision.

if node<1 || node>net.N || node~=floor(node)
    error('contextAwareStandaloneAckDecision: node is out of range.');
end
if ~isscalar(tk) || ~isfinite(tk) || tk<0
    error('contextAwareStandaloneAckDecision: tk must be nonnegative.');
end
if isempty(net.pendingAck{node}) || ~isfinite(net.pendingAckSince(node))
    error(['contextAwareStandaloneAckDecision: node has no pending ACK ' ...
        'obligation.']);
end

policy=contextAwarePolicyConfig(cfg);
if ~policy.enabled
    error('contextAwareStandaloneAckDecision: policy is not enabled.');
end
aware=macAwarePolicyConfig(cfg);
mac=sharedMediumConfig(cfg);
pendingAge=max(tk-net.pendingAckSince(node),0);
busy=net.localBusyEWMA(node);
if ~isfinite(busy) || busy<0 || busy>1+1e-12
    error('contextAwareStandaloneAckDecision: invalid local busy estimate.');
end

if strcmpi(mac.type,'aloha')
    minimumDelay=aware.alohaMinAckDelay;
else
    minimumDelay=aware.csmaMinAckDelay;
end

entries=net.pendingAck{node};
nEntries=numel(entries);
dataSlots=frameSlots(mac.dataBytes,mac);
ackBytes=mac.ackBaseBytes+mac.ackEntryBytes*nEntries;
ackSlots=frameSlots(ackBytes,mac);
dataAirtime=dataSlots*mac.slotTime;
ackAirtime=ackSlots*mac.slotTime;
reservedDataLoad=net.N*dataAirtime/policy.maxSilence;
serviceSlack=1-busy-reservedDataLoad;
queueDepth=numel(net.queues{node});
queueFeasible=queueDepth<mac.queueCapacity;
capacity=contextAwareServiceCertificate(cfg);

semanticDrift=zeros(nEntries,1);
redundancyScore=zeros(nEntries,1);
successEstimate=zeros(nEntries,1);
benefitTerms=zeros(nEntries,1);
for k=1:nEntries
    target=entries(k).targetSender;
    if target<1 || target>net.N || target~=floor(target)
        error(['contextAwareStandaloneAckDecision: pending entry has an ' ...
            'invalid target sender.']);
    end
    sampleAge=max(tk-entries(k).genTime,0);
    velocity=reshape(net.Vij(node,target,:),1,[]);
    semanticDrift(k)=norm(velocity)*sampleAge+ ...
        0.5*policy.accelerationBound*sampleAge^2;
    redundancyScore(k)=max(0,1-semanticDrift(k)/ ...
        policy.semanticPositionBudget);
    successEstimate(k)=mapValue(policy.ackSuccessEstimate,target,node,net.N);
    benefitTerms(k)=successEstimate(k)*dataAirtime*redundancyScore(k);
end

estimatedBenefit=sum(benefitTerms);
if serviceSlack>0
    estimatedCost=ackAirtime/serviceSlack;
else
    estimatedCost=inf;
end
feasible=capacity.feasible && serviceSlack>0 && queueFeasible;
valueMargin=estimatedBenefit-estimatedCost;
valuePositive=feasible && valueMargin>=-1e-12;

allow=false;
forced=false;
evaluated=false;
reason='minimum-delay';
nextDue=net.pendingAckSince(node)+minimumDelay;
if pendingAge+1e-12>=minimumDelay
    evaluated=true;
    if ~feasible
        reason='service-infeasible';
        nextDue=tk+aware.ackRecheckInterval;
    elseif ~valuePositive
        reason='nonpositive-value';
        nextDue=tk+aware.ackRecheckInterval;
    else
        allow=true;
        reason='positive-value';
        nextDue=inf;
    end
end

info=struct('allow',allow,'forced',forced,'reason',reason, ...
    'rule','feasibility-value','evaluated',evaluated, ...
    'pendingAge',pendingAge,'localBusy',busy, ...
    'minimumDelay',minimumDelay,'nEntries',nEntries, ...
    'queueDepth',queueDepth,'queueFeasible',queueFeasible, ...
    'dataSlots',dataSlots,'ackSlots',ackSlots, ...
    'dataAirtime',dataAirtime,'ackAirtime',ackAirtime, ...
    'reservedDataLoad',reservedDataLoad,'serviceSlack',serviceSlack, ...
    'capacityFeasible',capacity.feasible, ...
    'successfulUpdateRateHz',capacity.successfulUpdateRateHz, ...
    'requiredUpdateRateHz',capacity.requiredUpdateRateHz, ...
    'serviceRatio',capacity.serviceRatio, ...
    'semanticDriftMax',max(semanticDrift), ...
    'redundancyScoreMean',mean(redundancyScore), ...
    'ackSuccessEstimateMean',mean(successEstimate), ...
    'estimatedBenefit',estimatedBenefit,'estimatedCost',estimatedCost, ...
    'valueMargin',valueMargin,'feasible',feasible, ...
    'valuePositive',valuePositive);

end


function n=frameSlots(bytes,mac)

n=max(1,ceil((8*bytes/mac.phyRateBps)/mac.slotTime));

end


function y=mapValue(x,receiver,sender,N)

if isscalar(x)
    y=x;
elseif isequal(size(x),[N N])
    y=x(receiver,sender);
else
    error('contextAwareStandaloneAckDecision: invalid probability map.');
end

end
