function [P, V, six] = integrateFollowers(P, V, accCmd, six, cfg, tk)
%INTEGRATEFOLLOWERS Advance followers one outer step.
%
%   [P, V, six] = integrateFollowers(P, V, accCmd, six, cfg, tk)
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
% its analytic integrals from the outer sample.
%
% TRUE vs NOMINAL PLANT (EXP09B). The controller always reads the NOMINAL
% cfg.quad. The dynamics read cfg.quadTrue when present. Keeping the two
% separate is the whole point of the mismatch study: a controller retuned
% to the perturbed plant would measure the quality of the retuning instead
% of the robustness of the communication policy.
%
% Saturation is counted on the COMMAND, against the nominal limits, exactly
% as in EXP09A. Switching to actuator-state saturation would silently break
% comparability between the two experiments.
%
% ACTUATOR LAG (EXP09B). When cfg.actuator.tau > 0 the commanded thrust and
% torque pass through a first-order lag before reaching the plant. The
% controller command is still clipped to the physical limits BEFORE the
% lag, and no controller gain changes.

N  = size(P,1);
dt = cfg.swarm.dt;

if nargin < 6
    tk = 0;
end


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

% True plant for the dynamics; nominal cfg.quad for the controller.
if isfield(cfg,'quadTrue') && ~isempty(cfg.quadTrue)
    quadTrue = cfg.quadTrue;
else
    quadTrue = cfg.quad;
end

lagTau = 0;

if isfield(cfg,'actuator') && isfield(cfg.actuator,'tau')
    lagTau = cfg.actuator.tau;
end

hasForce = isfield(cfg,'extForce') && ~isempty(cfg.extForce) && cfg.extForce.level > 0;

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

    % Actuator state, initialised at the hover command so the first step
    % does not start from a spurious transient.
    six.actThrust = repmat(cfg.quad.m * cfg.quad.g, 1, N);
    six.actTorque = zeros(3, N);

    six.lagErrSum = 0;
    six.lagErrMax = 0;
    six.lagErrN   = 0;

end

thrustTol = 1e-6;
torqueTol = 1e-6;

maxThrust = cfg.quad.maxThrust;
maxTorque = cfg.quad.maxTorque(:);

if lagTau > 0
    lagAlpha = exp(-dtIn / lagTau);
else
    lagAlpha = 0;
end

for m = 1:ratio

    tau0 = (m-1) * dtIn;

    tNow = tk + tau0;

    six.sampleCount = six.sampleCount + 1;

    if hasForce
        aExt = lookupForce(cfg.extForce, tNow);
        dist.forceWorld = cfg.quad.m * aExt(:);
        dist.torqueBody = zeros(3,1);
    else
        dist = [];
    end

    for i = 2:N

        x = six.x(:,i);

        ref = setpointFromAccel(P(i,:), V(i,:), accCmd(i,:), tau0, 0);

        u = quadCascadedController(x, ref, cfg);

        % Saturation accounting, on the COMMAND, against nominal limits.
        if u.thrust <= thrustTol || u.thrust >= maxThrust - thrustTol
            six.thrustSatCount(i) = six.thrustSatCount(i) + 1;
        end

        if any(abs(abs(u.torque(:)) - maxTorque) <= torqueTol)
            six.torqueSatCount(i) = six.torqueSatCount(i) + 1;
        end

        six.thrustSq = six.thrustSq + u.thrust^2;
        six.torqueSq = six.torqueSq + sum((u.torque(:) ./ maxTorque).^2);
        six.effortN  = six.effortN + 1;

        % First-order actuator lag, applied AFTER the command is clipped.
        if lagTau > 0

            six.actThrust(i) = u.thrust + (six.actThrust(i) - u.thrust) * lagAlpha;

            six.actTorque(:,i) = u.torque(:) + ...
                (six.actTorque(:,i) - u.torque(:)) * lagAlpha;

            lagErr = abs(six.actThrust(i) - u.thrust) / max(u.thrust, eps) + ...
                sum(abs(six.actTorque(:,i) - u.torque(:)) ./ maxTorque);

            six.lagErrSum = six.lagErrSum + lagErr;
            six.lagErrMax = max(six.lagErrMax, lagErr);
            six.lagErrN   = six.lagErrN + 1;

            uApplied.thrust = six.actThrust(i);
            uApplied.torque = six.actTorque(:,i);

        else

            uApplied = u;

        end

        % RK4 with the applied command held constant across all four
        % stages, integrated on the TRUE plant.
        k1 = quad6dofDynamics(x,             uApplied, quadTrue, dist);
        k2 = quad6dofDynamics(x + dtIn/2*k1, uApplied, quadTrue, dist);
        k3 = quad6dofDynamics(x + dtIn/2*k2, uApplied, quadTrue, dist);
        k4 = quad6dofDynamics(x + dtIn*k3,   uApplied, quadTrue, dist);

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


%% ============================================================
% LOCAL FUNCTION
%
% Look the external-force proxy up by PHYSICAL TIME, so the realization
% a run meets does not depend on the method, on how often it transmits,
% or on the outer step size.
% ============================================================

function a = lookupForce(trace, t)

k = floor(t / trace.baseDt) + 1;

k = min(max(k, 1), trace.nSample);

a = trace.a(k,:);

end
