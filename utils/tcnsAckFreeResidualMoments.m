function M = tcnsAckFreeResidualMoments( ...
    currentPosition,currentVelocity,currentAcceleration,belief, ...
    positionGain,velocityGain,accelerationGain)
%TCNSACKFREERESIDUALMOMENTS Moments of controller correction under a PMF.
%
% The candidate-wise correction is
%   Kp*(p-p_s) + Kv*(v-v_s) + Ka*(a-a_s).
% Set Ka=0 and pass [] for currentAcceleration on an ordinary neighbor link.

required = {'candidatePos','candidateVel','candidateAcc','probability'};
for q = 1:numel(required)
    if ~isfield(belief,required{q})
        error('tcnsAckFreeResidualMoments:MissingBeliefField', ...
            'belief.%s is required.',required{q});
    end
end
position = localVector(currentPosition,'currentPosition');
velocity = localVector(currentVelocity,'currentVelocity');
validateattributes(positionGain,{'numeric'}, ...
    {'real','finite','scalar'},mfilename,'positionGain',5);
validateattributes(velocityGain,{'numeric'}, ...
    {'real','finite','scalar'},mfilename,'velocityGain',6);
validateattributes(accelerationGain,{'numeric'}, ...
    {'real','finite','scalar'},mfilename,'accelerationGain',7);

probability = double(belief.probability(:));
n = numel(probability);
if size(belief.candidatePos,1)~=n || size(belief.candidatePos,2)~=3 || ...
        size(belief.candidateVel,1)~=n || size(belief.candidateVel,2)~=3 || ...
        size(belief.candidateAcc,1)~=n || size(belief.candidateAcc,2)~=3 || ...
        any(~isfinite(probability)) || any(probability<0) || ...
        abs(sum(probability)-1)>1e-12
    error('tcnsAckFreeResidualMoments:InvalidBelief', ...
        'Belief candidates/probabilities are inconsistent.');
end

candidatePosition = double(belief.candidatePos);
candidateVelocity = double(belief.candidateVel);
correction = positionGain*(position-candidatePosition) + ...
    velocityGain*(velocity-candidateVelocity);
if accelerationGain~=0
    acceleration = localVector(currentAcceleration,'currentAcceleration');
    candidateAcceleration = double(belief.candidateAcc);
    if any(~isfinite(candidateAcceleration),'all')
        error('tcnsAckFreeResidualMoments:MissingAcceleration', ...
            'Finite candidate accelerations are required when Ka is nonzero.');
    end
    correction = correction + ...
        accelerationGain*(acceleration-candidateAcceleration);
end

candidateSquaredNorm = sum(correction.^2,2);
candidateNorm = sqrt(candidateSquaredNorm);
expectedCorrection = probability'*correction;
secondRawMoment = correction'*(probability.*correction);
covariance = secondRawMoment-expectedCorrection'*expectedCorrection;
covariance = (covariance+covariance')/2;

M.candidateCorrection = correction;
M.candidateNorm = candidateNorm;
M.candidateSquaredNorm = candidateSquaredNorm;
M.expectedCorrection = expectedCorrection;
M.expectedNorm = sum(probability.*candidateNorm);
M.expectedSquaredNorm = sum(probability.*candidateSquaredNorm);
M.secondRawMoment = secondRawMoment;
M.covariance = covariance;
M.varianceTrace = trace(covariance);
M.identityResidual = abs(M.expectedSquaredNorm - ...
    (sum(expectedCorrection.^2)+M.varianceTrace));

end


function value = localVector(value,label)

value = double(value(:)');
if numel(value)~=3 || any(~isfinite(value))
    error('tcnsAckFreeResidualMoments:InvalidVector', ...
        '%s must be a finite three-vector.',label);
end

end

