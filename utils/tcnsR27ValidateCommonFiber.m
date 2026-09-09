function V = tcnsR27ValidateCommonFiber(left,right,options)
%TCNSR27VALIDATECOMMONFIBER Validate a jointly replayed multi-action pair.

if nargin<3, options = struct(); end
options = localOptions(options);

V.senderInformationResidual = norm( ...
    right.senderObservation-left.senderObservation,inf);
V.dynamicResidual = max( ...
    left.affineTrajectoryResidual,right.affineTrajectoryResidual);
V.minimumSaturationMargin = min( ...
    left.saturationMargin,right.saturationMargin);
V.sameSender = left.sender==right.sender;
V.sameActionCount = height(left.catalog)==height(right.catalog);
V.sameActionIdentity = V.sameActionCount && isequal( ...
    left.catalog.actionId,right.catalog.actionId) && isequal( ...
    left.catalog.linkClass,right.catalog.linkClass) && isequal( ...
    left.catalog.receiver,right.catalog.receiver) && isequal( ...
    left.catalog.sender,right.catalog.sender);

p = min(height(left.catalog),height(right.catalog));
V.actionResponseResiduals = inf(p,1);
V.correctionResiduals = inf(p,1);
V.payloadResiduals = inf(p,1);
V.targetValueResiduals = inf(p,1);
V.targetIdentitySame = false(p,1);
for a = 1:p
    V.actionResponseResiduals(a) = norm( ...
        right.actionResponses{a}-left.actionResponses{a},inf);
    V.correctionResiduals(a) = norm( ...
        right.commandCorrections(a,:)-left.commandCorrections(a,:),inf);
    V.payloadResiduals(a) = localPayloadResidual( ...
        left.candidatePayloads{a},right.candidatePayloads{a});
    leftMap = left.actionMaps{a};
    rightMap = right.actionMaps{a};
    V.targetIdentitySame(a) = isequal( ...
        leftMap.targetIndex,rightMap.targetIndex);
    V.targetValueResiduals(a) = norm( ...
        rightMap.targetValue-leftMap.targetValue,inf);
end
V.maximumActionResponseResidual = localMaximum( ...
    V.actionResponseResiduals);
V.maximumCorrectionResidual = localMaximum(V.correctionResiduals);
V.maximumPayloadResidual = localMaximum(V.payloadResiduals);
V.maximumTargetValueResidual = localMaximum(V.targetValueResiduals);
V.maximumOracleResponseResidual = max([ ...
    left.oracleResponseResiduals;right.oracleResponseResiduals],[], ...
    'omitnan');
V.maximumAffineOracleMismatch = max([ ...
    left.oracleValueResiduals;right.oracleValueResiduals],[], ...
    'omitnan');
V.q0Included = ~isempty(left.qAugmented) && ...
    ~isempty(right.qAugmented) && left.qAugmented(1)==0 && ...
    right.qAugmented(1)==0;
V.leftArgmax = localArgmax(left.qAugmented,options.decisionTolerance);
V.rightArgmax = localArgmax(right.qAugmented,options.decisionTolerance);
V.argmaxIntersection = intersect(V.leftArgmax,V.rightArgmax,'stable');
V.disjointArgmax = isempty(V.argmaxIntersection);
V.leftWinnerMargin = localWinnerMargin( ...
    left.qAugmented,V.leftArgmax);
V.rightWinnerMargin = localWinnerMargin( ...
    right.qAugmented,V.rightArgmax);

reasons = strings(0,1);
if ~V.sameSender || V.senderInformationResidual>options.informationTolerance
    reasons(end+1,1) = "INFORMATION_MISMATCH";
end
if ~V.sameActionIdentity || any(~V.targetIdentitySame) || ...
        V.maximumActionResponseResidual>options.responseTolerance || ...
        V.maximumCorrectionResidual>options.responseTolerance || ...
        V.maximumPayloadResidual>options.responseTolerance || ...
        V.maximumTargetValueResidual>options.responseTolerance || ...
        V.maximumOracleResponseResidual>options.responseTolerance
    reasons(end+1,1) = "JOINT_RESPONSE_MISMATCH";
end
if V.dynamicResidual>options.reachabilityTolerance
    reasons(end+1,1) = "DYNAMIC_MISMATCH";
end
if V.minimumSaturationMargin<=options.saturationMarginTolerance || ...
        ~left.controllerUnsaturated || ~right.controllerUnsaturated
    reasons(end+1,1) = "SATURATION_OR_BRANCH_MISMATCH";
end
if V.maximumAffineOracleMismatch>options.oracleTolerance
    reasons(end+1,1) = "ORACLE_MISMATCH";
end
if ~V.q0Included
    reasons(end+1,1) = "NO_TRANSMISSION_ACTION_MISSING";
end
V.passCommonFiber = isempty(reasons);
if V.passCommonFiber
    V.failureReason = "NONE";
else
    V.failureReason = strjoin(reasons,';');
end
V.options = options;

end


function options = localOptions(options)

defaults.informationTolerance = 1e-9;
defaults.reachabilityTolerance = 1e-9;
defaults.responseTolerance = 1e-9;
defaults.oracleTolerance = 1e-9;
defaults.saturationMarginTolerance = 1e-6;
defaults.decisionTolerance = 1e-10;
names = fieldnames(defaults);
for q = 1:numel(names)
    if ~isfield(options,names{q}) || isempty(options.(names{q}))
        options.(names{q}) = defaults.(names{q});
    end
end

end


function residual = localPayloadResidual(left,right)

fields = union(fieldnames(left),fieldnames(right));
residual = 0;
for q = 1:numel(fields)
    name = fields{q};
    if ~isfield(left,name) || ~isfield(right,name)
        residual = Inf;
        return;
    end
    residual = max(residual,norm( ...
        double(left.(name))-double(right.(name)),inf));
end

end


function value = localMaximum(x)

if isempty(x), value = 0; else, value = max(x,[],'omitnan'); end

end


function set = localArgmax(q,tolerance)

set = find(q>=max(q)-tolerance)-1;

end


function margin = localWinnerMargin(q,argmaxSet)

if numel(argmaxSet)~=1
    margin = 0;
    return;
end
index = argmaxSet+1;
other = setdiff(1:numel(q),index);
if isempty(other)
    margin = Inf;
else
    margin = q(index)-max(q(other));
end

end
