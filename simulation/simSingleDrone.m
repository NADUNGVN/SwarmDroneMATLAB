function out = simSingleDrone(cfg)

% The generator is pinned explicitly. Parallel-pool workers default to a
% different generator than the client, so rng(seed) alone would make
% parfor results differ from the equivalent serial loop.
rng(cfg.seed, 'twister');

dt = cfg.single.dt;
t = (0:dt:cfg.single.T)';
K = numel(t);

if isfield(cfg.single, 'x0')
    x = cfg.single.x0(:);
else
    x = zeros(12,1);
end

X = zeros(K,12);
U = zeros(K,4);

RefPos = zeros(K,3);
RefVel = zeros(K,3);
RefAcc = zeros(K,3);
RefYaw = zeros(K,1);

DistForce = zeros(K,3);
DistTorque = zeros(K,3);

for k = 1:K
    tk = t(k);

    ref = getReference(cfg, tk);
    disturbance = getDisturbance(cfg, tk, x);

    X(k,:) = x';
    RefPos(k,:) = ref.pos';
    RefVel(k,:) = ref.vel';
    RefAcc(k,:) = ref.acc';
    RefYaw(k) = ref.yaw;

    DistForce(k,:) = disturbance.forceWorld';
    DistTorque(k,:) = disturbance.torqueBody';

    u = quadCascadedController(x, ref, cfg);
    U(k,:) = [u.thrust, u.torque'];

    if k == K
        break;
    end

    f = @(xx,tt) closedLoopDynamics(xx, tt, cfg);

    k1 = f(x, tk);
    k2 = f(x + 0.5*dt*k1, tk + 0.5*dt);
    k3 = f(x + 0.5*dt*k2, tk + 0.5*dt);
    k4 = f(x + dt*k3, tk + dt);

    x = x + (dt/6) * ...
        (k1 + 2*k2 + 2*k3 + k4);
end

% ============================================================
% Metrics
% ============================================================

posErr = X(:,1:3) - RefPos;

yawErr = atan2( ...
    sin(X(:,9) - RefYaw), ...
    cos(X(:,9) - RefYaw));


% ============================================================
% Outputs
% ============================================================

out.t = t;
out.X = X;
out.U = U;

out.RefPos = RefPos;
out.RefVel = RefVel;
out.RefAcc = RefAcc;
out.RefYaw = RefYaw;

out.DistForce = DistForce;
out.DistTorque = DistTorque;


% ============================================================
% Position metrics
% ============================================================

out.positionRMSE = sqrt( ...
    mean(sum(posErr.^2, 2)) );

out.finalPositionError = ...
    norm(posErr(end,:));

out.axisRMSE = ...
    sqrt(mean(posErr.^2, 1));


% ============================================================
% Yaw metrics
% ============================================================

out.yawRMSEdeg = ...
    rad2deg(sqrt(mean(yawErr.^2)));

out.finalYawErrorDeg = ...
    rad2deg(abs(yawErr(end)));


% ============================================================
% Attitude metrics
% ============================================================

out.peakRollPitchDeg = ...
    max(abs(rad2deg(X(:,7:8))), [], 1);


% ============================================================
% Actuator saturation metrics
% ============================================================

out.thrustSaturationPct = 100 * ...
    mean(U(:,1) >= 0.999 * cfg.quad.maxThrust);

out.torqueSaturationPct = 100 * ...
    mean(any( ...
        abs(U(:,2:4)) >= ...
        0.999 * cfg.quad.maxTorque', ...
        2));

end

function xdot = closedLoopDynamics(x, t, cfg)

ref = getReference(cfg, t);
disturbance = getDisturbance(cfg, t, x);

u = quadCascadedController(x, ref, cfg);

xdot = quad6dofDynamics(x, u, cfg.quad, disturbance);

end

function ref = getReference(cfg, t)

if isfield(cfg.single, 'referenceFcn') && ...
        ~isempty(cfg.single.referenceFcn)

    ref = cfg.single.referenceFcn(t);

else

    ref.pos = cfg.single.hoverPosition;
    ref.vel = [0;0;0];
    ref.acc = [0;0;0];
    ref.yaw = cfg.single.yaw;

end

ref.pos = ref.pos(:);
ref.vel = ref.vel(:);
ref.acc = ref.acc(:);

end

function disturbance = getDisturbance(cfg, t, x)

if isfield(cfg.single, 'disturbanceFcn') && ...
        ~isempty(cfg.single.disturbanceFcn)

    disturbance = cfg.single.disturbanceFcn(t, x);

else

    disturbance.forceWorld = zeros(3,1);
    disturbance.torqueBody = zeros(3,1);

end

if ~isfield(disturbance, 'forceWorld')
    disturbance.forceWorld = zeros(3,1);
end

if ~isfield(disturbance, 'torqueBody')
    disturbance.torqueBody = zeros(3,1);
end

disturbance.forceWorld = disturbance.forceWorld(:);
disturbance.torqueBody = disturbance.torqueBody(:);

end