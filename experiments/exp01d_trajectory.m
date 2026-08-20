% EXP01D_TRAJECTORY Smooth ascent followed by circular trajectory tracking.
startup;

%% ============================================================
% Result persistence
%
% Creates results/exp01d_trajectory/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

R = startExperiment('exp01d_trajectory');


cfg = defaultConfig();
cfg.single.T = 18.0;
cfg.single.referenceFcn = @circleReference;

out = simSingleDrone(cfg);

trackMask = out.t >= 2.0;
trackErr = out.X(trackMask,1:3) - out.RefPos(trackMask,:);
trackingRMSE = sqrt(mean(sum(trackErr.^2,2)));
maxTrackingError = max(vecnorm(trackErr,2,2));

% ---- 3-D trajectory ----
figure('Name','EXP01D 3D Trajectory');
plot3(out.RefPos(:,1), out.RefPos(:,2), out.RefPos(:,3), '--', 'LineWidth', 1.2);
hold on;
plot3(out.X(:,1), out.X(:,2), out.X(:,3), 'LineWidth', 1.4);
grid on; axis equal;
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
legend('reference','actual','Location','best');
title(sprintf('EXP01D circle tracking | RMSE = %.4f m', trackingRMSE));

% ---- Position versus time ----
figure('Name','EXP01D Position Tracking');
plot(out.t, out.X(:,1:3), 'LineWidth', 1.1);
hold on;
plot(out.t, out.RefPos, '--', 'LineWidth', 1.0);
grid on;
xlabel('Time [s]'); ylabel('Position [m]');
legend('x','y','z','x ref','y ref','z ref','Location','best');
title('EXP01D time-domain position tracking');

% ---- Attitude ----
figure('Name','EXP01D Attitude');
plot(out.t, rad2deg(out.X(:,7:9)), 'LineWidth', 1.1);
grid on;
xlabel('Time [s]'); ylabel('Angle [deg]');
legend('roll','pitch','yaw','Location','best');
title('EXP01D attitude during trajectory tracking');

fprintf('\nEXP01D trajectory-tracking results\n');
fprintf('  Tracking RMSE (t>=2 s) : %.4f m\n', trackingRMSE);
fprintf('  Max tracking error      : %.4f m\n', maxTrackingError);
fprintf('  Final position error    : %.4f m\n', out.finalPositionError);
fprintf('  Peak |roll| / |pitch|   : %.2f / %.2f deg\n', ...
    out.peakRollPitchDeg(1), out.peakRollPitchDeg(2));
fprintf('  Thrust saturation       : %.2f %%\n', out.thrustSaturationPct);
fprintf('  Torque saturation       : %.2f %%\n', out.torqueSaturationPct);

pass = trackingRMSE < 0.03 ...
    && maxTrackingError < 0.08 ...
    && out.torqueSaturationPct < 5.0;
if pass
    fprintf('  STATUS                  : PASS\n');
else
    fprintf('  STATUS                  : CHECK / RETUNE\n');
end

function ref = circleReference(t)
% First 2 s: smooth minimum-jerk-like cubic ascent to z = 1 m.
% Then: circle of radius 0.5 m, starting continuously from [0,0,1].
if t < 2.0
    Tasc = 2.0;
    s = t / Tasc;
    z = 3*s^2 - 2*s^3;
    zd = (6*s - 6*s^2) / Tasc;
    zdd = (6 - 12*s) / Tasc^2;

    ref.pos = [0;0;z];
    ref.vel = [0;0;zd];
    ref.acc = [0;0;zdd];
    ref.yaw = 0;
    return;
end

tau = t - 2.0;
r = 0.50;
w = 0.35;
theta = w * tau;

% Circle center is [r,0,1], so theta=0 starts at [0,0,1].
ref.pos = [r*(1-cos(theta)); r*sin(theta); 1.0];
ref.vel = [r*w*sin(theta); r*w*cos(theta); 0];
ref.acc = [r*w^2*cos(theta); -r*w^2*sin(theta); 0];
ref.yaw = 0;
end


%% ============================================================
% Persist results
%
% save() with no variable list stores the ENTIRE script workspace,
% so every sweep axis and result array is preserved without having
% to enumerate names.
% ============================================================

save(fullfile(R.dir,'workspace.mat'));

saveAllFigures(R);

finishExperiment(R);
