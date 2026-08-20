startup;

cfg = defaultConfig();

out = simSwarm(cfg);

M = computeSwarmMetrics(out,cfg);


%% ============================================================
% Results
% ============================================================

fprintf('\nEXP02 ideal-communication formation results\n');

fprintf('  Formation RMSE (t>=8 s) : %.4f m\n', ...
    M.formationRMSE);

fprintf('  Max formation error     : %.4f m\n', ...
    M.maxFormationError);

fprintf('  Min inter-agent distance: %.4f m\n', ...
    M.minSeparation);

fprintf('  Velocity disagreement   : %.4f m/s\n', ...
    M.velocityDisagreementRMSE);

fprintf('  Formation settling time : %.3f s\n', ...
    M.settlingTime);


pass = ...
    M.formationRMSE < 0.05 && ...
    M.maxFormationError < 0.12 && ...
    M.minSeparation > 0.25;


if pass
    fprintf('  STATUS                  : PASS\n');
else
    fprintf('  STATUS                  : CHECK\n');
end


%% ============================================================
% 3-D trajectories
% ============================================================

figure;
hold on;
grid on;
axis equal;

N = cfg.swarm.N;

for i = 1:N

    Pi = squeeze(out.P(:,i,:));

    plot3( ...
        Pi(:,1), ...
        Pi(:,2), ...
        Pi(:,3), ...
        'LineWidth',1.3);

end

plot3( ...
    out.LeaderPos(:,1), ...
    out.LeaderPos(:,2), ...
    out.LeaderPos(:,3), ...
    'k--', ...
    'LineWidth',1.5);

xlabel('x [m]');
ylabel('y [m]');
zlabel('z [m]');

title('EXP02 distributed formation trajectories');

legend( ...
    'UAV 1', ...
    'UAV 2', ...
    'UAV 3', ...
    'UAV 4', ...
    'UAV 5', ...
    'leader reference');

view(3);


%% ============================================================
% Formation error
% ============================================================

figure;
hold on;
grid on;

for i = 2:N

    plot( ...
        out.t, ...
        M.formationError(:,i), ...
        'LineWidth',1.2);

end

yline(0.05,'--');

xlabel('Time [s]');
ylabel('Formation position error [m]');

title('EXP02 follower formation errors');

legend( ...
    'UAV 2', ...
    'UAV 3', ...
    'UAV 4', ...
    'UAV 5', ...
    '5 cm threshold');


%% ============================================================
% XY formation snapshots
% ============================================================

snapshotTimes = [5 15 25];

figure;

for s = 1:numel(snapshotTimes)

    [~,k] = min(abs(out.t-snapshotTimes(s)));

    subplot(1,3,s);

    pk = squeeze(out.P(k,:,:));

    plot( ...
        pk(:,1), ...
        pk(:,2), ...
        'o-', ...
        'LineWidth',1.3);

    grid on;
    axis equal;

    xlabel('x [m]');
    ylabel('y [m]');

    title(sprintf('t = %.0f s', ...
        snapshotTimes(s)));

end