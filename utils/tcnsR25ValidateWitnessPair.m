function V = tcnsR25ValidateWitnessPair(minusRun,plusRun,options)
%TCNSR25VALIDATEWITNESSPAIR Validate one independently replayed witness pair.

if nargin<3, options = struct(); end
options = localOptions(options);

V.informationHistoryResidual = norm( ...
    plusRun.senderObservation-minusRun.senderObservation,inf);
V.correctionResidual = norm( ...
    plusRun.commandCorrection-minusRun.commandCorrection,inf);
V.responseResidual = norm( ...
    plusRun.actionResponse-minusRun.actionResponse,inf);
V.oracleResponseResidual = max( ...
    minusRun.oracleResponseResidual,plusRun.oracleResponseResidual);
V.dynamicResidual = max( ...
    minusRun.affineTrajectoryResidual,plusRun.affineTrajectoryResidual);
V.minimumSaturationMargin = min( ...
    minusRun.saturationMargin,plusRun.saturationMargin);
V.affineOracleMismatch = max( ...
    minusRun.oracleValueResidual,plusRun.oracleValueResidual);
V.targetIndexSame = isequal( ...
    minusRun.actionMap.targetIndex,plusRun.actionMap.targetIndex);
V.targetValueResidual = norm( ...
    minusRun.actionMap.targetValue-plusRun.actionMap.targetValue,inf);
V.packetSemanticsSame = localPayloadResidual( ...
    minusRun.candidatePayload,plusRun.candidatePayload)<= ...
    options.responseTolerance;
V.controllerBranchSame = minusRun.controllerUnsaturated && ...
    plusRun.controllerUnsaturated;
V.signCrossing = minusRun.oracleValue<-options.signTolerance && ...
    plusRun.oracleValue>options.signTolerance;

reasons = strings(0,1);
if V.informationHistoryResidual>options.informationTolerance
    reasons(end+1,1) = "INFORMATION_MISMATCH";
end
if V.correctionResidual>options.responseTolerance || ...
        V.responseResidual>options.responseTolerance || ...
        V.oracleResponseResidual>options.responseTolerance || ...
        ~V.targetIndexSame || ...
        V.targetValueResidual>options.responseTolerance || ...
        ~V.packetSemanticsSame
    reasons(end+1,1) = "RESPONSE_MISMATCH";
end
if V.dynamicResidual>options.reachabilityTolerance
    reasons(end+1,1) = "DYNAMIC_MISMATCH";
end
if V.minimumSaturationMargin<=options.saturationMarginTolerance || ...
        ~V.controllerBranchSame
    reasons(end+1,1) = "SATURATION_OR_BRANCH_MISMATCH";
end
if V.affineOracleMismatch>options.oracleTolerance
    reasons(end+1,1) = "ORACLE_MISMATCH";
end
if ~V.signCrossing
    reasons(end+1,1) = "NO_SIGN_CROSSING";
end

V.pass = isempty(reasons);
if V.pass
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
defaults.signTolerance = 1e-12;
defaults.saturationMarginTolerance = 1e-6;
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
