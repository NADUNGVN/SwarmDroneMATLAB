function A = tcnsInformationLimitsActionMap( ...
    model,linkClass,receiver,sender,commandCorrection,candidatePayload)
%TCNSINFORMATIONLIMITSACTIONMAP Affine Gate-3 cross-term for a fixed action.
%
% The receiver-memory payload fixed by the hypothesis is substituted into
% the augmented state and removed from the free coordinates.

linkClass = lower(string(linkClass));
validateattributes(receiver,{'numeric'}, ...
    {'real','finite','integer','scalar'},mfilename,'receiver',3);
validateattributes(sender,{'numeric'}, ...
    {'real','finite','integer','scalar'},mfilename,'sender',4);
commandCorrection = localVector(commandCorrection,'commandCorrection');
requiredPayload = {'pos','vel'};
for q = 1:numel(requiredPayload)
    if ~isfield(candidatePayload,requiredPayload{q})
        error('tcnsInformationLimitsActionMap:Payload', ...
            'candidatePayload.%s is required.',requiredPayload{q});
    end
end
candidatePosition = localVector(candidatePayload.pos,'candidatePayload.pos');
candidateVelocity = localVector(candidatePayload.vel,'candidatePayload.vel');

fi = find(model.followers==receiver,1);
if isempty(fi)
    error('tcnsInformationLimitsActionMap:Receiver', ...
        'The action receiver must be a Gate-3 follower.');
end
switch linkClass
    case "ordinary"
        linkIndex = find(model.edgeReceiver==receiver & ...
            model.edgeSender==sender,1);
        if isempty(linkIndex)
            error('tcnsInformationLimitsActionMap:Link', ...
                'The requested ordinary link is not active.');
        end
        targetAxis = [model.index.ordinaryPosition(linkIndex), ...
            model.index.ordinaryVelocityStep(linkIndex)];
        targetValueAxis = [candidatePosition; ...
            model.h*candidateVelocity];
        candidateAcceleration = [NaN NaN NaN];
    case "pinned-leader"
        if sender~=1
            error('tcnsInformationLimitsActionMap:Link', ...
                'A pinned-leader payload must have sender 1.');
        end
        linkIndex = find(model.pinReceiver==receiver,1);
        if isempty(linkIndex)
            error('tcnsInformationLimitsActionMap:Link', ...
                'The requested receiver is not pinned.');
        end
        if ~isfield(candidatePayload,'acc')
            error('tcnsInformationLimitsActionMap:Payload', ...
                'candidatePayload.acc is required for a pin payload.');
        end
        candidateAcceleration = localVector( ...
            candidatePayload.acc,'candidatePayload.acc');
        targetAxis = [model.index.pinPosition(linkIndex), ...
            model.index.pinVelocityStep(linkIndex), ...
            model.index.pinAccelerationStep(linkIndex)];
        targetValueAxis = [candidatePosition;model.h*candidateVelocity; ...
            model.h^2*candidateAcceleration];
    otherwise
        error('tcnsInformationLimitsActionMap:Class', ...
            'linkClass must be ordinary or pinned-leader.');
end

scalarResponse = reshape(model.kernel.positionResponse(:,:,fi), ...
    model.horizonSamples,model.m);
g = zeros(3*model.horizonSamples*model.m,1);
blockLength = model.horizonSamples*model.m;
for axis = 1:3
    response = scalarResponse*commandCorrection(axis);
    g((axis-1)*blockLength+(1:blockLength)) = ...
        reshape(response.',[],1);
end
fullEll = model.F'*g;
fullConstant = model.r'*g;

targetIndex = zeros(numel(targetAxis)*3,1);
targetValue = zeros(size(targetIndex));
q = 0;
for axis = 1:3
    base = (axis-1)*model.nAxis;
    for v = 1:numel(targetAxis)
        q = q+1;
        targetIndex(q) = base+targetAxis(v);
        targetValue(q) = targetValueAxis(v,axis);
    end
end
keepIndex = setdiff((1:model.nState)',targetIndex,'stable');
ell = fullEll(keepIndex);
constant = fullConstant+fullEll(targetIndex)'*targetValue;
energy = g'*g;
successProbability = model.successProbability;
if isempty(successProbability) || ~isfinite(successProbability) || ...
        successProbability<0 || successProbability>1
    error('tcnsInformationLimitsActionMap:SuccessProbability', ...
        'The information model must provide a finite success probability.');
end

A.linkClass = linkClass;
A.receiver = receiver;
A.sender = sender;
A.linkIndex = linkIndex;
A.receiverFollowerIndex = fi;
A.commandCorrection = commandCorrection;
A.candidatePosition = candidatePosition;
A.candidateVelocity = candidateVelocity;
A.candidateAcceleration = candidateAcceleration;
A.actionResponse = g;
A.actionResponseEnergy = energy;
A.fullCrossTermCoefficient = fullEll;
A.fullCrossTermConstant = fullConstant;
A.targetIndex = targetIndex;
A.targetValue = targetValue;
A.keepIndex = keepIndex;
A.crossTermCoefficient = ell;
A.crossTermConstant = constant;
A.valueCoefficient = -2*successProbability/model.m*ell;
A.valueConstant = successProbability/model.m*(-2*constant-energy);
A.successProbability = successProbability;
A.exactFixedHypothesis = true;

end


function value = localVector(value,label)

value = double(value(:)');
if numel(value)~=3 || any(~isfinite(value))
    error('tcnsInformationLimitsActionMap:Vector', ...
        '%s must be a finite three-vector.',label);
end

end
