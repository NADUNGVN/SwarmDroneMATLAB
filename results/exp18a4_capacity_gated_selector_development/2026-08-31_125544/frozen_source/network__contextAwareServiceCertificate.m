function cert=contextAwareServiceCertificate(cfg)
%CONTEXTAWARESERVICECERTIFICATE Screen access capacity against freshness need.
%
% This is an analytical operating-point screen under the declared symmetric
% independent-start approximation.  It is not a population-safety theorem.

policy=contextAwarePolicyConfig(cfg);
if ~policy.enabled
    error('contextAwareServiceCertificate: policy is not enabled.');
end
mac=sharedMediumConfig(cfg);
[p,access]=contextAwareAccessProbability(cfg);
N=cfg.swarm.N;
L=access.dataSlots;
backgroundSurvival=(1-mac.backgroundLoad)^L;
dataSuccess=topologyMinimum(policy.dataSuccessEstimate,cfg,N);

switch lower(mac.type)
    case 'aloha'
        vulnerableSlots=2*L-1;
        collisionFree=(1-p)^(N*vulnerableSlots-1);
        opportunityRate=p/mac.slotTime;
        successfulUpdateRate=opportunityRate*collisionFree* ...
            backgroundSurvival*dataSuccess;
        model='independent-start vulnerable-period ALOHA';
        cycleSlots=NaN;
    case 'csma'
        idleProbability=(1-p)^N;
        cycleSlots=idleProbability+(1-idleProbability)*L;
        taggedSuccessPerCycle=p*(1-p)^(N-1);
        successfulUpdateRate=taggedSuccessPerCycle/ ...
            (cycleSlots*mac.slotTime)*backgroundSurvival*dataSuccess;
        vulnerableSlots=1;
        collisionFree=(1-p)^(N-1);
        opportunityRate=p/(cycleSlots*mac.slotTime);
        model='symmetric p-persistent CSMA renewal approximation';
    case 'tdma'
        vulnerableSlots=1;
        collisionFree=1;
        cycleSlots=N*L;
        opportunityRate=1/(cycleSlots*mac.slotTime);
        successfulUpdateRate=opportunityRate*backgroundSurvival*dataSuccess;
        model='one scheduled DATA opportunity per TDMA cycle';
    otherwise
        error('contextAwareServiceCertificate: unsupported MAC type.');
end

requiredUpdateRate=1/cfg.aoiEvent.aoiThreshold;
serviceRatio=successfulUpdateRate/requiredUpdateRate;
feasible=~policy.serviceCertificateEnabled || serviceRatio>=1-1e-12;
cert=struct('enabled',policy.serviceCertificateEnabled, ...
    'feasible',logical(feasible),'model',model,'pAccess',p, ...
    'dataSlots',L,'vulnerableSlots',vulnerableSlots, ...
    'cycleSlots',cycleSlots,'collisionFreeFactor',collisionFree, ...
    'backgroundSurvival',backgroundSurvival, ...
    'dataSuccessEstimate',dataSuccess, ...
    'opportunityRateHz',opportunityRate, ...
    'successfulUpdateRateHz',successfulUpdateRate, ...
    'requiredUpdateRateHz',requiredUpdateRate, ...
    'serviceRatio',serviceRatio, ...
    'scope','analytical screen; not a safety theorem');

end


function y=topologyMinimum(x,cfg,N)

if isscalar(x)
    y=x;
    return;
end
if ~isequal(size(x),[N N])
    error('contextAwareServiceCertificate: invalid DATA success map.');
end
topology=logical(cfg.swarm.A);
if isfield(cfg.swarm,'pin')
    topology(logical(cfg.swarm.pin(:)),1)=true;
end
topology(1:N+1:end)=false;
values=x(topology);
if isempty(values)
    y=min(x(:));
else
    y=min(values);
end

end
