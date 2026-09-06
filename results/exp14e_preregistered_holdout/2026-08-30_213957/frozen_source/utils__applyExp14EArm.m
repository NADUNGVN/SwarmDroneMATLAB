function [cfg,method,label]=applyExp14EArm(cfg,arm)
%APPLYEXP14EARM Apply one frozen selected/comparator holdout arm.

required={'id','label','scaledAccess','historicalReference'};
if ~isstruct(arm) || ~all(isfield(arm,required))
    error('applyExp14EArm: arm does not satisfy the registry contract.');
end
id=lower(strtrim(char(arm.id)));
switch id
    case 'selected-adaptive-scaled'
        f=factorArm(id,true,false,true);
        [cfg,method]=applyExp14DArm(cfg,f);
    case 'access-only'
        f=factorArm(id,false,false,true);
        [cfg,method]=applyExp14DArm(cfg,f);
    case 'historical-hybrid'
        f=factorArm(id,false,false,false);
        [cfg,method]=applyExp14DArm(cfg,f);
    case 'piggyback-scaled'
        method='causal-broadcast';
        cfg.shared.feedbackMode='piggyback';
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    case 'state-scaled'
        [cfg,method]=applyExp14FrontierPoint(cfg,'state',1);
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    case 'belief-scaled'
        [cfg,method]=applyExp14FrontierPoint(cfg,'belief',0.12);
        cfg.shared.feedbackMode='hybrid';
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    case 'periodic-p10-scaled'
        [cfg,method]=applyExp14FrontierPoint(cfg,'periodic',10);
        cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
    otherwise
        error('applyExp14EArm: unknown arm "%s".',id);
end

label=char(arm.label);
cfg.exp14e.arm=id;
cfg.exp14e.scaledAccess=logical(arm.scaledAccess);
cfg.exp14e.historicalReference=logical(arm.historicalReference);
cfg.mac=sharedMediumConfig(cfg);

end


function arm=factorArm(id,A,G,S)

arm=struct('id',id,'adaptiveAck',logical(A), ...
    'loadGuard',logical(G),'accessScaling',logical(S));

end
