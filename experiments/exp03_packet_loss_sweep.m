% EXP03_PACKET_LOSS_SWEEP Repeatable packet-loss ablation.
startup;
base = defaultConfig();
losses = [0 0.10 0.20 0.30 0.40 0.50];
seeds = 1:5;

rows = [];
for p = losses
    for s = seeds
        cfg = base;
        cfg.net.packetLoss = p;
        cfg.seed = s;
        out = simSwarm(cfg);
        m = out.metrics;
        rows = [rows; p, s, m.formationRMSE, m.minSeparation, ... %#ok<AGROW>
            m.velocityDisagreement, m.leaderTrackingRMSE, m.PDR, m.meanAoI, double(m.collisionOccurred)];
    end
end

T = array2table(rows, 'VariableNames', { ...
    'PacketLoss','Seed','FormationRMSE_m','MinSeparation_m', ...
    'VelocityDisagreement_mps','LeaderTrackingRMSE_m','PDR','MeanAoI_s','Collision'});

disp(T);
rootDir = fileparts(fileparts(mfilename('fullpath')));
outFile = fullfile(rootDir, 'results', 'packet_loss_sweep.csv');
writetable(T, outFile);
fprintf('Saved: %s\n', outFile);

% Mean formation RMSE by packet-loss level.
meanRmse = zeros(size(losses));
for i = 1:numel(losses)
    meanRmse(i) = mean(T.FormationRMSE_m(T.PacketLoss == losses(i)));
end
figure('Name','Packet Loss Ablation');
plot(100*losses, meanRmse, '-o', 'LineWidth', 1.2);
grid on;
xlabel('Packet loss [%]'); ylabel('Mean formation RMSE [m]');
title('Communication robustness baseline');
