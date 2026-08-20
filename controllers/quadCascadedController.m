function u = quadCascadedController(x, ref, cfg)
%QUADCASCADEDCONTROLLER Position outer loop + geometric attitude inner loop.

p = x(1:3);
v = x(4:6);
eul = x(7:9);
omega = x(10:12);
R = rotmZYX(eul);

% Outer-loop desired force in world frame.
ep = ref.pos - p;
ev = ref.vel - v;
aCmd = ref.acc + cfg.ctrl.KpPos .* ep + cfg.ctrl.KdPos .* ev + [0;0;cfg.quad.g];

% Feed-forward compensation for the linear drag model used by dynamics.
% This term is zero for hover/step references and removes steady lag during
% non-zero-velocity trajectory tracking.
Fdes = cfg.quad.m * aCmd + cfg.quad.linearDrag * ref.vel;

if norm(Fdes) < 1e-9
    zbDes = [0;0;1];
else
    zbDes = Fdes / norm(Fdes);
end

% Desired yaw defines a horizontal heading direction.
xc = [cos(ref.yaw); sin(ref.yaw); 0];
ybDes = cross(zbDes, xc);
if norm(ybDes) < 1e-8
    ybDes = [0;1;0];
else
    ybDes = ybDes / norm(ybDes);
end
xbDes = cross(ybDes, zbDes);
xbDes = xbDes / max(norm(xbDes), 1e-9);
Rd = [xbDes, ybDes, zbDes];

% Geometric attitude error on SO(3).
eRmat = 0.5 * (Rd' * R - R' * Rd);
eR = vee(eRmat);

% Project desired force onto current thrust axis.
thrust = dot(Fdes, R(:,3));
thrust = min(max(thrust, 0), cfg.quad.maxThrust);

% Inner-loop torque with gyroscopic compensation.
torque = -cfg.ctrl.Kr .* eR - cfg.ctrl.Kw .* omega + cross(omega, cfg.quad.J*omega);
torque = min(max(torque, -cfg.quad.maxTorque), cfg.quad.maxTorque);

u.thrust = thrust;
u.torque = torque;
u.posError = ep;
u.attError = eR;
end
