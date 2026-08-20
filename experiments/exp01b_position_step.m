% EXP01B_POSITION_STEP Full 6-DOF position + yaw step test.
startup;

%% ============================================================
% Result persistence
%
% Creates results/exp01b_position_step/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

R = startExperiment('exp01b_position_step');


cfg = defaultConfig();
cfg.single.T = 10.0;
cfg.single.referenceFcn = @stepReference;

out = simSingleDrone(cfg);

% ---- Metrics ----
posErrNorm = vecnorm(out.X(:,1:3) - out.RefPos, 2, 2);
steadyMask = out.t >= 6.0;
steadyRMSE = sqrt(mean(posErrNorm(steadyMask).^2));
settlingTime = computeSettlingTime(out.t, posErrNorm, 0.03);

% ---- Position plot ----
figure('Name','EXP01B Position Step');
plot(out.t, out.X(:,1:3), 'LineWidth', 1.2);
hold on;
plot(out.t, out.RefPos, '--', 'LineWidth', 1.0);
grid on;
xlabel('Time [s]'); ylabel('Position [m]');
legend('x','y','z','x ref','y ref','z ref','Location','best');
title(sprintf('EXP01B position step | final error = %.4f m', out.finalPositionError));

% ---- Attitude plot ----
figure('Name','EXP01B Attitude');
plot(out.t, rad2deg(out.X(:,7:9)), 'LineWidth', 1.2);
hold on;
plot(out.t, rad2deg(out.RefYaw), '--', 'LineWidth', 1.0);
grid on;
xlabel('Time [s]'); ylabel('Angle [deg]');
legend('roll','pitch','yaw','yaw ref','Location','best');
title('EXP01B attitude response');

fprintf('\nEXP01B position-step results\n');
fprintf('  Position RMSE (full)    : %.4f m\n', out.positionRMSE);
fprintf('  Position RMSE (t>=6 s) : %.4f m\n', steadyRMSE);
fprintf('  Final position error    : %.4f m\n', out.finalPositionError);
fprintf('  Final yaw error         : %.3f deg\n', out.finalYawErrorDeg);
fprintf('  Settling time (3 cm)    : %.3f s\n', settlingTime);
fprintf('  Peak |roll| / |pitch|   : %.2f / %.2f deg\n', ...
    out.peakRollPitchDeg(1), out.peakRollPitchDeg(2));
fprintf('  Thrust saturation       : %.2f %%\n', out.thrustSaturationPct);
fprintf('  Torque saturation       : %.2f %%\n', out.torqueSaturationPct);

pass = out.finalPositionError < 0.02 ...
    && out.finalYawErrorDeg < 2.0 ...
    && out.torqueSaturationPct < 5.0;
if pass
    fprintf('  STATUS                   : PASS\n');
else
    fprintf('  STATUS                   : CHECK / RETUNE\n');
end

function ref = stepReference(~)
ref.pos = [1.0; 0.8; 1.0];
ref.vel = [0;0;0];
ref.acc = [0;0;0];
ref.yaw = deg2rad(30);
end

function ts = computeSettlingTime(t, err, threshold)
lastOutside = find(err > threshold, 1, 'last');
if isempty(lastOutside)
    ts = 0;
elseif lastOutside >= numel(t)
    ts = NaN;
else
    ts = t(lastOutside + 1);
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
