function plotSingleDrone(out)
%PLOTSINGLEDRONE Plot hover response.
figure('Name','Single Drone Hover');
plot(out.t, out.X(:,1:3), 'LineWidth', 1.1);
grid on;
xlabel('Time [s]'); ylabel('Position [m]');
legend('x','y','z','Location','best');
title(sprintf('6-DOF hover | final error = %.4f m', out.finalPositionError));

figure('Name','Single Drone Attitude');
plot(out.t, rad2deg(out.X(:,7:9)), 'LineWidth', 1.1);
grid on;
xlabel('Time [s]'); ylabel('Angle [deg]');
legend('roll','pitch','yaw','Location','best');
title('Attitude response');
end
