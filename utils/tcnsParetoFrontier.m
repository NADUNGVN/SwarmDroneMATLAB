function [F,isFrontier] = tcnsParetoFrontier(T,costVariable,errorVariable)
%TCNSPARETOFRONTIER Exact lower-left frontier for a table of operating points.
%
%   [F,isFrontier] = tcnsParetoFrontier(T,'cost','error')
%
% Lower cost and lower error are preferred. Conventional weak Pareto
% dominance is used; the historical paper's separate 1% reporting margin is
% deliberately not imported into frontier construction. At duplicate costs,
% only the point with minimum error is eligible. Output is sorted by
% increasing cost and has strictly decreasing error.

if ~istable(T)
    error('tcnsParetoFrontier:Type','Input must be a table.');
end
costVariable = char(costVariable);
errorVariable = char(errorVariable);
if ~ismember(costVariable,T.Properties.VariableNames) || ...
        ~ismember(errorVariable,T.Properties.VariableNames)
    error('tcnsParetoFrontier:MissingVariable', ...
        'Both cost and error variables must exist in the input table.');
end

cost = T.(costVariable);
performanceError = T.(errorVariable);
if ~isnumeric(cost) || ~isnumeric(performanceError) || ...
        ~isvector(cost) || ~isvector(performanceError)
    error('tcnsParetoFrontier:Shape', ...
        'Cost and error variables must be numeric vectors.');
end

valid = isfinite(cost) & isfinite(performanceError);
candidateIndex = find(valid);
if isempty(candidateIndex)
    error('tcnsParetoFrontier:NoFinitePoint', ...
        'No finite cost/error operating point is available.');
end

ordered = sortrows(table(cost(valid),performanceError(valid),candidateIndex, ...
    'VariableNames',{'cost','error','index'}),{'cost','error'}, ...
    {'ascend','ascend'});

keepOrdered = false(height(ordered),1);
bestError = inf;
lastCost = -inf;
for k = 1:height(ordered)
    % Because error is the secondary ascending key, later entries at an
    % identical cost cannot improve on the first one.
    if ordered.cost(k)==lastCost
        continue;
    end
    lastCost = ordered.cost(k);
    if ordered.error(k)<bestError
        keepOrdered(k) = true;
        bestError = ordered.error(k);
    end
end

selected = ordered.index(keepOrdered);
isFrontier = false(height(T),1);
isFrontier(selected) = true;
F = T(selected,:);
F = sortrows(F,costVariable,'ascend');

if height(F)>1 && (any(diff(F.(costVariable))<=0) || ...
        any(diff(F.(errorVariable))>=0))
    error('tcnsParetoFrontier:InternalOrdering', ...
        'Constructed frontier is not strictly lower-left ordered.');
end

end
