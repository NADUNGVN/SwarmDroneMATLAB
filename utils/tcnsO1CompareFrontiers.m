function C = tcnsO1CompareFrontiers(aggregate,matchingGridSize,rule)
%TCNSO1COMPAREFRONTIERS Apply the frozen O1 matching/classification rule.

required = {'meaningfulRmseFraction','meaningfulCostFraction', ...
    'meaningfulRunLength','narrowRunLength'};
for q = 1:numel(required)
    if ~isfield(rule,required{q})
        error('tcnsO1CompareFrontiers:Rule', ...
            'rule.%s is required.',required{q});
    end
end

pMask = aggregate.methodFamily=="Periodic" & aggregate.failedRuns==0;
oMask = aggregate.methodFamily=="Centralized state oracle" & ...
    aggregate.failedRuns==0;
[periodic,pKeep] = tcnsParetoFrontier(aggregate(pMask,:), ...
    'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m');
[oracle,oKeep] = tcnsParetoFrontier(aggregate(oMask,:), ...
    'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m');
matched = tcnsMatchFrontiers(oracle,periodic, ...
    'meanEvaluationCost025PerChannel_Hz','meanPrimaryFormationRMSE_m', ...
    matchingGridSize);

budgetStats = localStats(matched.budgetMatched.errorDifferenceAminusB, ...
    matched.budgetMatched.formationErrorB,rule.meaningfulRmseFraction);
performanceStats = localStats( ...
    matched.performanceMatched.costDifferenceAminusB, ...
    matched.performanceMatched.communicationCostB, ...
    rule.meaningfulCostFraction);
convincing = localBasicSupport(budgetStats) && ...
    localBasicSupport(performanceStats) && ...
    budgetStats.longestMeaningfulRun>=rule.meaningfulRunLength && ...
    performanceStats.longestMeaningfulRun>=rule.meaningfulRunLength;
marginal = ~convincing && (( ...
    budgetStats.longestMeaningfulRun>=rule.narrowRunLength && ...
    performanceStats.longestMeaningfulRun>=rule.narrowRunLength) || ...
    (localBasicSupport(budgetStats) && ...
     localBasicSupport(performanceStats)));

budget = matched.budgetMatched;
budget.relativeAdvantageO1 = ...
    -budget.errorDifferenceAminusB./budget.formationErrorB;
budget.meaningfulO1Advantage = ...
    budget.relativeAdvantageO1>=rule.meaningfulRmseFraction;
performance = matched.performanceMatched;
performance.relativeAdvantageO1 = ...
    -performance.costDifferenceAminusB./performance.communicationCostB;
performance.meaningfulO1Advantage = ...
    performance.relativeAdvantageO1>=rule.meaningfulCostFraction;

C.periodicFrontier = periodic;
C.oracleFrontier = oracle;
C.periodicKeep = pKeep;
C.oracleKeep = oKeep;
C.matched = matched;
C.budgetMatched = budget;
C.performanceMatched = performance;
C.budgetStats = budgetStats;
C.performanceStats = performanceStats;
C.convincing = convincing;
C.marginalOrNarrow = marginal;
if convincing
    C.classification = "CONVINCING";
elseif marginal
    C.classification = "MARGINAL_OR_NARROW";
else
    C.classification = "NO_HEADROOM";
end

end


function S = localStats(difference,reference,meaningfulFraction)

difference = double(difference(:));
reference = double(reference(:));
relativeAdvantage = -difference./reference;
S.meanDifference = mean(difference);
S.medianDifference = median(difference);
S.fractionFavoring = mean(difference<0);
S.maximumAdvantage = max(0,-min(difference));
S.maximumDisadvantage = max(0,max(difference));
nonzeroSign = sign(difference);
nonzeroSign = nonzeroSign(nonzeroSign~=0);
S.crossings = nnz(nonzeroSign(2:end)~=nonzeroSign(1:end-1));
S.longestFavoringRun = localLongestRun(difference<0);
S.longestMeaningfulRun = localLongestRun( ...
    relativeAdvantage>=meaningfulFraction);

end


function pass = localBasicSupport(S)

pass = S.meanDifference<0 && S.medianDifference<0 && ...
    S.fractionFavoring>0.5;

end


function longest = localLongestRun(mask)

mask = logical(mask(:));
if isempty(mask) || ~any(mask)
    longest = 0;
    return;
end
edges = diff([false;mask;false]);
starts = find(edges==1);
stops = find(edges==-1)-1;
longest = max(stops-starts+1);

end
