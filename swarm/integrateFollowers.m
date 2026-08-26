function [P, V, six] = integrateFollowers(P, V, accCmd, six, cfg)
%INTEGRATEFOLLOWERS Advance followers one outer step.
%
%   [P, V, six] = integrateFollowers(P, V, accCmd, six, cfg)
%
% Two modes, selected by cfg.sixdof.enable:
%
%   false (default)  the locked semi-implicit Euler double integrator,
%                    reproduced EXACTLY as it was written inline in each
%                    simulator. Nothing about the outer loop changes, and
%                    test_lock_regression proves bit-identity.
%
%   true             each follower is a 6-DOF quadrotor. The outer step is
%                    divided into cfg.sixdof.ratio inner steps; on each of
%                    those the controller is evaluated ONCE and its output
%                    is held across all four RK4 stages.
%
% The reference handed to the controller comes from setpointFromAccel: the
% commanded acceleration is held and the position/velocity references are
% its analytic integrals from the outer sample. See that file for why the
% reference must not be frozen at the sample instant.
%
% The controller and u are evaluated at the START of each inner step and
% held across the RK4 stages. Re-evaluating them at stage times would model
% a continuous-time controller that does not exist and would flatter the
% result.
%
% P and V returned in 6-DOF mode are the vehicle's actual position and
% velocity, so the network transmits what the drone really is, not what the
% double-integrator model would have predicted.
%
% six is the 12 x N state [p; v; eul; omega], plus the saturation and
% divergence bookkeeping. It is created lazily on the first call.

N  = size(P,1);
dt = cfg.swarm.dt;


%% ============================================================
% Locked path
% ============================================================

if ~isfield(cfg,'sixdof') || ~isfield(cfg.sixdof,'enable') || ~cfg.sixdof.enable

    for i = 2:N

        V(i,:) = V(i,:) + dt*accCmd(i,:);

        P(i,:) = P(i,:) + dt*V(i,:);

    end

    return;

end


%% ============================================================
% 6-DOF path
% ============================================================

ratio = cfg.sixdof.ratio;

dtIn = dt / ratio;

if isempty(six) || ~isfield(six,'x')

    six.x = zeros(12, N);

    for i = 1:N
        six.x(1:3,i)  = P(i,:)';
        six.x(4:6,i)  = V(i,:)';
    end

    six.thrustSatCount = zeros(N,1);
    six.torqueSatCount = zeros(N,1);
    six.sampleCount    = 0;

    six.rollPeak  = 0;
    six.pitchPeak = 0;

    six.thrustSq  = 0;
    six.torqueSq  = 0;
    six.effortN   = 0;

    six.diverged  = false;

end

thrustTol = 1e-6;
torqueTol = 1e-6;

maxThrust = cfg.quad.maxThrust;
maxTorque = cfg.quad.maxTorque(:);

for m = 1:ratio

    tau0 = (m-1) * dtIn;

    six.sampleCount = six.sampleCount + 1;

    for i = 2:N

        x = six.x(:,i);

        ref = setpointFromAccel(P(i,:), V(i,:), accCmd(i,:), tau0, 0);

        u = quadCascadedController(x, ref, cfg);

        % Saturation accounting, on the command actually issued.
        if u.thrust <= thrustTol || u.thrust >= maxThrust - thrustTol
            six.thrustSatCount(i) = six.thrustSatCount(i) + 1;
        end

        if any(abs(abs(u.torque(:)) - maxTorque) <= torqueTol)
            six.torqueSatCount(i) = six.torqueSatCount(i) + 1;
        end

        six.thrustSq = six.thrustSq + u.thrust^2;
        six.torqueSq = six.torqueSq + sum((u.torque(:) ./ maxTorque).^2);
        six.effortN  = six.effortN + 1;

        % RK4 with u held constant across all four stages.
        k1 = quad6dofDynamics(x,             u, cfg.quad);
        k2 = quad6dofDynamics(x + dtIn/2*k1, u, cfg.quad);
        k3 = quad6dofDynamics(x + dtIn/2*k2, u, cfg.quad);
        k4 = quad6dofDynamics(x + dtIn*k3,   u, cfg.quad);

        x = x + (dtIn/6) * (k1 + 2*k2 + 2*k3 + k4);

        six.x(:,i) = x;

        six.rollPeak  = max(six.rollPeak,  abs(x(7)));
        six.pitchPeak = max(six.pitchPeak, abs(x(8)));

    end

end


%% ============================================================
% Publish the real vehicle state, and check divergence
% ============================================================

for i = 2:N

    P(i,:) = six.x(1:3,i)';
    V(i,:) = six.x(4:6,i)';

end

if any(~isfinite(six.x(:)))
    six.diverged = true;
end

if six.rollPeak > deg2rad(80) || six.pitchPeak > deg2rad(80)
    six.diverged = true;
end

for i = 2:N
    if norm(P(i,:) - P(1,:)) > 50
        six.diverged = true;
    end
end

end
