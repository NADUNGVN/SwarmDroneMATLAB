function xdot = quad6dofDynamics(x, u, quad, disturbance)
%QUAD6DOFDYNAMICS 12-state rigid-body quadrotor dynamics.
% State: [p_world(3); v_world(3); roll; pitch; yaw; omega_body(3)]
% Input: u.thrust [N], u.torque [N*m]
% Optional disturbance.forceWorld [N], disturbance.torqueBody [N*m].

if nargin < 4 || isempty(disturbance)
    disturbance.forceWorld = zeros(3,1);
    disturbance.torqueBody = zeros(3,1);
else
    if ~isfield(disturbance, 'forceWorld')
        disturbance.forceWorld = zeros(3,1);
    end
    if ~isfield(disturbance, 'torqueBody')
        disturbance.torqueBody = zeros(3,1);
    end
end

v = x(4:6);
eul = x(7:9);
omega = x(10:12);

R = rotmZYX(eul);
T = min(max(u.thrust, 0), quad.maxThrust);
tau = min(max(u.torque, -quad.maxTorque), quad.maxTorque);

pDot = v;
gravity = [0; 0; -quad.g];
thrustWorld = R * [0; 0; T];
vDot = gravity + thrustWorld / quad.m ...
    - (quad.linearDrag / quad.m) * v ...
    + disturbance.forceWorld / quad.m;

eulDot = eulerRatesZYX(eul, omega);
omegaDot = quad.J \ (tau + disturbance.torqueBody ...
    - cross(omega, quad.J * omega) ...
    - quad.angularDrag * omega);

xdot = [pDot; vDot; eulDot; omegaDot];
end
