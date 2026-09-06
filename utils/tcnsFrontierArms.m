function arms = tcnsFrontierArms(periodSamples,epsilonSweep,h,retryInterval,includeLegacy)
%TCNSFRONTIERARMS Stable arm contract for TCNS frontier experiments.
%
% Each returned discriminated struct has kind periodic, control-aware, or
% legacy. Variant-specific parameters remain explicit and inapplicable fields
% are NaN. The constructor validates all experiment-boundary inputs once.

if nargin < 5
    includeLegacy = true;
end
validateattributes(periodSamples,{'numeric'}, ...
    {'real','finite','vector','integer','positive'},mfilename,'periodSamples',1);
validateattributes(epsilonSweep,{'numeric'}, ...
    {'real','finite','vector','positive'},mfilename,'epsilonSweep',2);
validateattributes(h,{'numeric'}, ...
    {'real','finite','scalar','positive'},mfilename,'h',3);
validateattributes(retryInterval,{'numeric'}, ...
    {'real','finite','scalar','positive'},mfilename,'retryInterval',4);
validateattributes(includeLegacy,{'logical'}, ...
    {'scalar'},mfilename,'includeLegacy',5);
if numel(unique(periodSamples))~=numel(periodSamples) || ...
        numel(unique(epsilonSweep))~=numel(epsilonSweep)
    error('tcnsFrontierArms:DuplicateParameter', ...
        'Frontier sweep parameters must be unique.');
end

nP = numel(periodSamples);
nC = numel(epsilonSweep);
n = nP+nC+double(includeLegacy);
prototype = struct('id',"",'family',"",'label',"",'kind',"", ...
    'parameterName',"",'parameterValue',NaN,'period_s',NaN, ...
    'epsilon_m',NaN,'retry_s',NaN);
arms = repmat(prototype,n,1);

for q = 1:nP
    arms(q).id = "PS"+compose('%03d',periodSamples(q));
    arms(q).family = "Periodic";
    arms(q).label = "Periodic-"+string(periodSamples(q))+"step";
    arms(q).kind = "periodic";
    arms(q).parameterName = "periodSamples";
    arms(q).parameterValue = periodSamples(q);
    arms(q).period_s = periodSamples(q)*h;
end
for q = 1:nC
    k = nP+q;
    arms(k).id = "CA"+compose('%02d',q);
    arms(k).family = "Control-aware";
    arms(k).label = "Control-aware";
    arms(k).kind = "control-aware";
    arms(k).parameterName = "epsilonPosition_m";
    arms(k).parameterValue = epsilonSweep(q);
    arms(k).epsilon_m = epsilonSweep(q);
    arms(k).retry_s = retryInterval;
end
if includeLegacy
    k = nP+nC+1;
    arms(k).id = "CAUSALV3";
    arms(k).family = "Historical reference";
    arms(k).label = "Causal-v3 frozen";
    arms(k).kind = "legacy";
    arms(k).parameterName = "frozen";
end

end
