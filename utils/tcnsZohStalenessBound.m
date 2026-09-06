function B = tcnsZohStalenessBound(physicalAge, payloadSpeed, ...
    maxAcceleration, sampleTime, payloadPositionError, payloadVelocityError)
%TCNSZOHSTALENESSBOUND Exact-grid ZOH state-error envelope for Gate 2.
%
%   B = tcnsZohStalenessBound(age,speed,aBar,h)
%   B = tcnsZohStalenessBound(age,speed,aBar,h,etaP,etaV)
%
% The sender follows the semi-implicit sampled double integrator
%
%   v(k+1) = v(k) + h*u(k)
%   p(k+1) = p(k) + h*v(k+1),       ||u(k)|| <= aBar.
%
% A receiver holds the payload generated q samples ago. PAYLOADSPEED is
% the norm of the velocity carried by that accepted payload. PHYSICALAGE
% is t(k)-t(g), without the simulator's +h/2 logging convention. The
% returned deterministic bounds are
%
%   ||v(k)-v_hat(g)|| <= etaV + q*h*aBar
%
%   ||p(k)-p_hat(g)|| <= etaP + q*h*(speed+etaV)
%                         + h^2*aBar*q*(q+1)/2.
%
% etaP and etaV bound payload error at generation. They default to zero,
% which is the exact-state Gate-2 configuration. Inputs may be scalars or
% compatible arrays; scalar bounds are expanded implicitly by MATLAB.
%
% This function refuses off-grid ages. Silently rounding an arbitrary AoI
% would turn an exact sampled statement into an undocumented approximation.

if nargin < 5 || isempty(payloadPositionError)
    payloadPositionError = 0;
end

if nargin < 6 || isempty(payloadVelocityError)
    payloadVelocityError = 0;
end

validateattributes(physicalAge,{'numeric'}, ...
    {'real','finite','nonnegative'},mfilename,'physicalAge',1);
validateattributes(payloadSpeed,{'numeric'}, ...
    {'real','finite','nonnegative'},mfilename,'payloadSpeed',2);
validateattributes(maxAcceleration,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'maxAcceleration',3);
validateattributes(sampleTime,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'sampleTime',4);
validateattributes(payloadPositionError,{'numeric'}, ...
    {'real','finite','nonnegative'},mfilename,'payloadPositionError',5);
validateattributes(payloadVelocityError,{'numeric'}, ...
    {'real','finite','nonnegative'},mfilename,'payloadVelocityError',6);

qRaw = physicalAge ./ sampleTime;
q = round(qRaw);
gridResidual = abs(qRaw-q);

gridTolerance = 1e-9;
if any(gridResidual(:) > gridTolerance)
    error('tcnsZohStalenessBound:OffGridAge', ...
        ['physicalAge must be an integer multiple of sampleTime; ' ...
         'maximum normalized residual is %.3e.'],max(gridResidual(:)));
end

B.sampleCount = q;
B.physicalAge = q .* sampleTime;
B.gridResidualSamples = gridResidual;
B.velocity = payloadVelocityError + ...
    q .* sampleTime .* maxAcceleration;
B.position = payloadPositionError + ...
    q .* sampleTime .* (payloadSpeed + payloadVelocityError) + ...
    sampleTime^2 .* maxAcceleration .* q .* (q+1) ./ 2;
B.payloadSpeed = payloadSpeed;
B.payloadPositionError = payloadPositionError;
B.payloadVelocityError = payloadVelocityError;
B.maxAcceleration = maxAcceleration;
B.sampleTime = sampleTime;

end
