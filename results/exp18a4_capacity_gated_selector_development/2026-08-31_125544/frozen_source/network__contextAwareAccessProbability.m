function [p,info]=contextAwareAccessProbability(cfg)
%CONTEXTAWAREACCESSPROBABILITY Analytical frame-aware access design point.

mac=sharedMediumConfig(cfg);
policy=contextAwarePolicyConfig(cfg);
N=cfg.swarm.N;
dataSlots=max(1,ceil((8*mac.dataBytes/mac.phyRateBps)/mac.slotTime));

switch lower(mac.type)
    case 'csma'
        denominator=N;
        rationale='one-of-N idle-slot contention';
    case 'aloha'
        if strcmp(policy.accessRule,'frame-aware')
            denominator=N*(2*dataSlots-1);
            rationale='multi-slot vulnerable period';
        else
            denominator=N;
            rationale='legacy one-of-N scaling';
        end
    case 'tdma'
        denominator=1;
        rationale='scheduled access';
    otherwise
        error('contextAwareAccessProbability: unsupported MAC type.');
end

p=min(mac.pAccess,1/denominator);
info=struct('configuredPAccess',mac.pAccess,'effectivePAccess',p, ...
    'dataSlots',dataSlots,'denominator',denominator, ...
    'accessRule',policy.accessRule,'rationale',rationale);

end
