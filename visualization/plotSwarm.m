function plotSwarm(out)
%PLOTSWARM Plot 3D trajectories and formation error trend.
P = out.P;
N = out.cfg.swarm.N;

figure('Name','Swarm Trajectories');
hold on; grid on; axis equal;
for i = 1:N
    plot3(squeeze(P(1,i,:)), squeeze(P(2,i,:)), squeeze(P(3,i,:)), 'LineWidth', 1.2);
end
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
title(sprintf('Distributed formation | loss=%.0f%%, delay=%.0f ms', ...
    100*out.cfg.net.packetLoss, 1000*out.cfg.net.delaySec));
legend(arrayfun(@(i) sprintf('UAV %d',i), 1:N, 'UniformOutput', false), 'Location','best');
view(3);

% Pairwise formation error over time.
err = zeros(numel(out.t),1);
for k = 1:numel(out.t)
    acc = 0; n = 0;
    for i = 1:N
        for j = i+1:N
            desired = out.cfg.swarm.offsets(:,i)-out.cfg.swarm.offsets(:,j);
            actual = out.P(:,i,k)-out.P(:,j,k);
            acc = acc + norm(actual-desired)^2;
            n = n + 1;
        end
    end
    err(k) = sqrt(acc/max(n,1));
end
figure('Name','Formation Error');
plot(out.t, err, 'LineWidth', 1.2); grid on;
xlabel('Time [s]'); ylabel('Pairwise formation RMSE [m]');
title('Formation convergence');
end
