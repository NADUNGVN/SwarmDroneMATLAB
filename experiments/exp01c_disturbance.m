% EXP01C_DISTURBANCE Hover disturbance-rejection test.
startup;

%% ============================================================
% Result persistence
%
% Creates results/exp01c_disturbance/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

R = startExperiment('exp01c_disturbance');


cfg = defaultConfig();
cfg.single.T = 10.0;
cfg.single.disturbanceFcn = @gustDisturbance;

out = simSingleDrone(cfg);

% Disturbance interval.
tOn = 5.00;
tOff = 5.35;
posErrNorm = vecnorm(out.X(:,1:3) - out.RefPos, 2, 2);
afterOn = out.t >= tOn;
maxDeviation = max(posErrNorm(afterOn));
recoveryTime = computeRecoveryTime(out.t, posErrNorm, tOff, 0.02, 0.50);

% ---- Position plot ----
figure('Name','EXP01C Disturbance Rejection');
plot(out.t, out.X(:,1:3), 'LineWidth', 1.2);
hold on;
plot(out.t, out.RefPos, '--', 'LineWidth', 1.0);
xline(tOn, ':');
xline(tOff, ':');
grid on;
xlabel('Time [s]'); ylabel('Position [m]');
legend('x','y','z','x ref','y ref','z ref','Location','best');
title(sprintf('EXP01C disturbance rejection | max deviation = %.3f m', maxDeviation));

% ---- Disturbance plot ----
figure('Name','EXP01C Applied Disturbance');
plot(out.t, out.DistForce, 'LineWidth', 1.2);
hold on;
plot(out.t, 100*out.DistTorque(:,3), '--', 'LineWidth', 1.1);
grid on;
xlabel('Time [s]');
ylabel('Force [N] / 100 x yaw torque [N m]');
legend('F_x','F_y','F_z','100 \tau_z','Location','best');
title('Applied external disturbance');

fprintf('\nEXP01C disturbance-rejection results\n');
fprintf('  Disturbance interval    : %.2f -- %.2f s\n', tOn, tOff);
fprintf('  Max position deviation  : %.4f m\n', maxDeviation);
fprintf('  Recovery to 2 cm        : %.3f s after disturbance\n', recoveryTime);
fprintf('  Final position error    : %.4f m\n', out.finalPositionError);
fprintf('  Peak |roll| / |pitch|   : %.2f / %.2f deg\n', ...
    out.peakRollPitchDeg(1), out.peakRollPitchDeg(2));
fprintf('  Torque saturation       : %.2f %%\n', out.torqueSaturationPct);

pass = maxDeviation < 0.15 ...
    && recoveryTime < 3.5 ...
    && out.finalPositionError < 0.02 ...
    && out.torqueSaturationPct < 5.0;
if pass
    fprintf('  STATUS                  : PASS\n');
else
    fprintf('  STATUS                  : CHECK / RETUNE\n');
end

function disturbance = gustDisturbance(t, ~)
disturbance.forceWorld = zeros(3,1);
disturbance.torqueBody = zeros(3,1);

if t >= 5.00 && t <= 5.35
    disturbance.forceWorld = [0.08; -0.04; 0.00]; % N
    disturbance.torqueBody = [0; 0; 6.0e-4];      % N*m
end
end

function tr = computeRecoveryTime(t, err, tOff, threshold, holdTime)
idx0 = find(t >= tOff, 1, 'first');
dt = median(diff(t));
windowN = max(1, round(holdTime / dt));
tr = NaN;

for i = idx0:(numel(t)-windowN+1)
    if all(err(i:i+windowN-1) <= threshold)
        tr = t(i) - tOff;
        return;
    end
end
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
