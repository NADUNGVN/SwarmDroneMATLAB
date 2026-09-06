function [cfg,method,label,details,certificate]=applyExp18BArm(base,arm)
%APPLYEXP18BARM Apply one of the four frozen EXP18B arms.

R=exp18bRegistry();
required={'id','label','accessDesign','ackDesign'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp18BArm: arm does not satisfy the frozen registry.');
end

% The screen is a property of the declared context and candidate access
% geometry. It is computed once identically for every paired arm.
[candidateCfg,candidateMethod,candidateLabel,candidateDetails,certificate]= ...
    applyExp18A4Arm(base);

switch char(arm.id)
    case R.candidate
        cfg=candidateCfg;
        method=candidateMethod;
        label=candidateLabel;
        details=candidateDetails;
        routeRule='capacity-gated-mac';
    otherwise
        E=exp18Registry();
        idx=find(strcmp({E.arms.id},char(arm.id)),1);
        if isempty(idx)
            error('applyExp18BArm: comparator is not an EXP18 fixed arm.');
        end
        [cfg,method,label,details]=applyExp18Arm(base,E.arms(idx));
        routeRule='fixed-comparator';
        if strcmp(arm.id,'legacy-selector')
            routeRule='legacy-mac-only';
        end
end

if certificate.feasible && strcmpi(base.mac.type,'aloha')
    routedReference='frame-adaptive';
else
    routedReference='frame-piggyback';
end
cfg.exp18b.version=R.version;
cfg.exp18b.arm=char(arm.id);
cfg.exp18b.routeRule=routeRule;
details.routeRule=routeRule;
details.routedReference=routedReference;
details.candidateFlag=double(strcmp(arm.id,R.candidate));

end
