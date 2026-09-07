function arms = tcnsO1FrontierArms( ...
    periodSamples,lambdaSweep,h,horizonSamples)
%TCNSO1FRONTIERARMS Frozen periodic and centralized-oracle arm schema.

validateattributes(periodSamples,{'numeric'}, ...
    {'real','finite','vector','integer','positive'},mfilename,'periodSamples',1);
validateattributes(lambdaSweep,{'numeric'}, ...
    {'real','finite','vector','nonnegative'},mfilename,'lambdaSweep',2);
validateattributes(h,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'h',3);
validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',4);
if numel(unique(periodSamples))~=numel(periodSamples) || ...
        numel(unique(lambdaSweep))~=numel(lambdaSweep)
    error('tcnsO1FrontierArms:DuplicateParameter', ...
        'O1 frontier parameters must be unique.');
end

nP = numel(periodSamples);
nO = numel(lambdaSweep);
prototype = struct('id',"",'family',"",'label',"",'kind',"", ...
    'parameterName',"",'parameterValue',NaN,'period_s',NaN, ...
    'epsilon_m',NaN,'retry_s',NaN,'oracleLambda',NaN, ...
    'oracleHorizonSamples',NaN);
arms = repmat(prototype,nP+nO,1);

for q = 1:nP
    arms(q).id = "PS"+compose('%03d',periodSamples(q));
    arms(q).family = "Periodic";
    arms(q).label = "Periodic-"+string(periodSamples(q))+"step";
    arms(q).kind = "periodic";
    arms(q).parameterName = "periodSamples";
    arms(q).parameterValue = periodSamples(q);
    arms(q).period_s = periodSamples(q)*h;
end
for q = 1:nO
    k = nP+q;
    arms(k).id = "O1L"+compose('%02d',q);
    arms(k).family = "Centralized state oracle";
    arms(k).label = "centralized_state_oracle";
    arms(k).kind = "centralized-state-oracle";
    arms(k).parameterName = "lambda";
    arms(k).parameterValue = lambdaSweep(q);
    arms(k).oracleLambda = lambdaSweep(q);
    arms(k).oracleHorizonSamples = horizonSamples;
end

end
