function L = tcnsControlAwareLinkState( ...
    currentPos,currentVel,ackPos,ackVel,outstanding, ...
    sentPos,sentVel,positionGain,velocityGain,localBudget, ...
    currentAcc,ackAcc,sentAcc,accelerationGain)
%TCNSCONTROLAWARELINKSTATE Causal link uncertainty in controller units.
%
% The causal contribution is the controller-weighted maximum over the
% ACK-confirmed-plus-outstanding possible receiver-payload set. The
% latest-sent contribution answers a different question: whether the newest
% payload already put on the wire would satisfy the allocation if confirmed.
% Keeping these quantities separate prevents redundant transmissions while
% feedback is in flight.

if nargin < 11
    currentAcc = [];
    ackAcc = [];
    sentAcc = [];
    accelerationGain = 0;
end

validateattributes(positionGain,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'positionGain',8);
validateattributes(velocityGain,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'velocityGain',9);
validateattributes(localBudget,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'localBudget',10);
validateattributes(accelerationGain,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'accelerationGain',14);

if isempty(currentAcc)
    setBound = causalReceiverStateSetBound( ...
        currentPos,currentVel,ackPos,ackVel,outstanding);
    latestAccelerationError = 0;
    setAcceleration = 0;
else
    setBound = causalReceiverStateSetBound( ...
        currentPos,currentVel,ackPos,ackVel,outstanding,currentAcc,ackAcc);
    latestAccelerationError = norm(currentAcc(:)-sentAcc(:));
    setAcceleration = setBound.acceleration;
end

latestPositionError = norm(currentPos(:)-sentPos(:));
latestVelocityError = norm(currentVel(:)-sentVel(:));

L.setBound = setBound;
L.setContribution = positionGain*setBound.position + ...
    velocityGain*setBound.velocity + accelerationGain*setAcceleration;
L.latestSentContribution = positionGain*latestPositionError + ...
    velocityGain*latestVelocityError + ...
    accelerationGain*latestAccelerationError;
L.localBudget = double(localBudget);
L.normalizedContribution = L.setContribution/L.localBudget;
L.budgetViolated = L.setContribution>L.localBudget;
L.latestSentWouldSatisfy = L.latestSentContribution<=L.localBudget;
L.usesDropOutcome = false;

end
