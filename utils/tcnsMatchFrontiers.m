function M = tcnsMatchFrontiers(A,B,costVariable,errorVariable,nGrid)
%TCNSMATCHFRONTIERS Automatic budget- and performance-matched comparison.
%
%   M = tcnsMatchFrontiers(A,B,'cost','error',101)
%
% A and B must be lower-left Pareto frontiers. Linear interpolation is used
% only inside their shared observed domains; extrapolation is prohibited.
% Differences are always A minus B, so negative values favor A.

if nargin < 5 || isempty(nGrid)
    nGrid = 101;
end
validateattributes(nGrid,{'numeric'}, ...
    {'real','finite','integer','>=',2,'scalar'},mfilename,'nGrid',5);

costVariable = char(costVariable);
errorVariable = char(errorVariable);
localValidateFrontier(A,costVariable,errorVariable,'A');
localValidateFrontier(B,costVariable,errorVariable,'B');

costA = double(A.(costVariable));
costB = double(B.(costVariable));
errorA = double(A.(errorVariable));
errorB = double(B.(errorVariable));

budgetLow = max(min(costA),min(costB));
budgetHigh = min(max(costA),max(costB));
if budgetHigh<=budgetLow
    error('tcnsMatchFrontiers:NoBudgetOverlap', ...
        'Frontiers do not share a nonzero communication-budget interval.');
end
budgetGrid = linspace(budgetLow,budgetHigh,nGrid)';
matchedErrorA = interp1(costA,errorA,budgetGrid,'linear');
matchedErrorB = interp1(costB,errorB,budgetGrid,'linear');
errorDifference = matchedErrorA-matchedErrorB;

performanceLow = max(min(errorA),min(errorB));
performanceHigh = min(max(errorA),max(errorB));
if performanceHigh<=performanceLow
    error('tcnsMatchFrontiers:NoPerformanceOverlap', ...
        'Frontiers do not share a nonzero formation-error interval.');
end
performanceGrid = linspace(performanceLow,performanceHigh,nGrid)';
matchedCostA = interp1(flip(errorA),flip(costA), ...
    performanceGrid,'linear');
matchedCostB = interp1(flip(errorB),flip(costB), ...
    performanceGrid,'linear');
costDifference = matchedCostA-matchedCostB;

M.differenceConvention = 'A minus B; negative favors A';
M.interpolation = 'piecewise linear, shared observed domain, no extrapolation';
M.budgetMatched = table(budgetGrid,matchedErrorA,matchedErrorB, ...
    errorDifference,'VariableNames',{'communicationBudget', ...
    'formationErrorA','formationErrorB','errorDifferenceAminusB'});
M.performanceMatched = table(performanceGrid,matchedCostA,matchedCostB, ...
    costDifference,'VariableNames',{'formationErrorTarget', ...
    'communicationCostA','communicationCostB','costDifferenceAminusB'});
M.budgetOverlap = [budgetLow budgetHigh];
M.performanceOverlap = [performanceLow performanceHigh];
M.meanBudgetMatchedErrorDifference = mean(errorDifference);
M.meanPerformanceMatchedCostDifference = mean(costDifference);
M.fractionBudgetGridFavoringA = mean(errorDifference<0);
M.fractionPerformanceGridFavoringA = mean(costDifference<0);

end


function localValidateFrontier(F,costVariable,errorVariable,label)

if ~istable(F) || height(F)<2 || ...
        ~ismember(costVariable,F.Properties.VariableNames) || ...
        ~ismember(errorVariable,F.Properties.VariableNames)
    error('tcnsMatchFrontiers:InvalidFrontier', ...
        'Frontier %s must contain at least two cost/error rows.',label);
end
cost = F.(costVariable);
performanceError = F.(errorVariable);
if any(~isfinite(cost)) || any(~isfinite(performanceError)) || ...
        any(diff(cost)<=0) || any(diff(performanceError)>=0)
    error('tcnsMatchFrontiers:NotLowerLeft', ...
        'Frontier %s must have increasing cost and decreasing error.',label);
end

end
