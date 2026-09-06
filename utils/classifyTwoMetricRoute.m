function label=classifyTwoMetricRoute(rmseLo,rmseHi,loadLo,loadHi)
%CLASSIFYTWOMETRICROUTE Descriptive paired-CI route classification.
%
% Inputs are 95% intervals for piggyback minus adaptive. Lower is better.
% This helper produces no p-value and no confirmatory claim.

values=[rmseLo rmseHi loadLo loadHi];
if ~isnumeric(values) || any(~isfinite(values)) || ...
        rmseLo>rmseHi || loadLo>loadHi
    error('classifyTwoMetricRoute: finite ordered intervals are required.');
end
if rmseHi<0 && loadHi<0
    label='PIGGYBACK_DOMINATES';
elseif rmseLo>0 && loadLo>0
    label='ADAPTIVE_DOMINATES';
else
    label='MIXED_OR_UNRESOLVED';
end

end
