function B = tcnsLeaderStalenessBound(generationTime,currentTime)
%TCNSLEADERSTALENESSBOUND Stale-payload bounds for leaderReference.m.
%
%   B = tcnsLeaderStalenessBound(generationTime,currentTime)
%
% The present leader reference is a cubic vertical takeoff on [0,3),
% followed by a radius-1 circle at 0.2 rad/s. Position is continuous at
% the switch, but velocity and acceleration jump. Consequently, applying
% the follower double-integrator envelope across t=3 would be false.
%
% Direct differentiation of leaderReference gives the global segment
% envelopes
%
%   ||v_L|| <= 0.6,  ||a_L|| <= 0.8,  ||jerk_L|| <= 8/15,
%
% and switch jumps ||[v_L]||=0.2 and
% ||[a_L]||=sqrt(0.8^2+0.04^2). The returned bounds explicitly add each
% jump when the stale interval crosses the switch.

validateattributes(generationTime,{'numeric'}, ...
    {'real','finite','nonnegative'},mfilename,'generationTime',1);
validateattributes(currentTime,{'numeric'}, ...
    {'real','finite','nonnegative'},mfilename,'currentTime',2);

try
    age = currentTime-generationTime;
catch err
    error('tcnsLeaderStalenessBound:IncompatibleSize', ...
        'generationTime and currentTime must have compatible sizes: %s', ...
        err.message);
end

tol = 1e-12;
if any(age(:)<-tol)
    error('tcnsLeaderStalenessBound:FutureGeneration', ...
        'generationTime cannot exceed currentTime.');
end
age = max(age,0);

switchTime = 3.0;
crossesSwitch = generationTime<switchTime & currentTime>=switchTime;

velocityEnvelope = 0.6;
accelerationEnvelope = 0.8;
jerkEnvelope = 8/15;
velocityJump = 0.2;
accelerationJump = hypot(0.8,0.04);

B.age = age;
B.crossesSwitch = crossesSwitch;
B.position = velocityEnvelope.*age;
B.velocity = accelerationEnvelope.*age + ...
    velocityJump.*double(crossesSwitch);
B.acceleration = jerkEnvelope.*age + ...
    accelerationJump.*double(crossesSwitch);
B.constants = struct( ...
    'switchTime_s',switchTime, ...
    'velocityEnvelope_mps',velocityEnvelope, ...
    'accelerationEnvelope_mps2',accelerationEnvelope, ...
    'jerkEnvelope_mps3',jerkEnvelope, ...
    'velocityJump_mps',velocityJump, ...
    'accelerationJump_mps2',accelerationJump);

end
