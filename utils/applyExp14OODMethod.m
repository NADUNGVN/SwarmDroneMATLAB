function [cfg,method,label] = applyExp14OODMethod(cfg,arm)
%APPLYEXP14OODMETHOD Apply one frozen fixed-point method in EXP14 OOD.

if ~isstruct(arm) || ~all(isfield(arm, ...
        {'id','label','method','periodHz','feedbackMode'}))
    error('applyExp14OODMethod: arm does not satisfy the registry contract.');
end

method = char(arm.method);
label = char(arm.label);
if isfinite(arm.periodHz)
    cfg.net.commPeriod = 1/arm.periodHz;
end
if any(strcmp(method,{'causal-broadcast','causal-unicast'}))
    cfg.shared.feedbackMode = char(arm.feedbackMode);
end

end
