% EXP01_HOVER Single-drone 6-DOF hover baseline.
startup;
cfg = defaultConfig();
out = simSingleDrone(cfg);
plotSingleDrone(out);

fprintf('\nEXP01 hover results\n');
fprintf('  Position RMSE      : %.4f m\n', out.positionRMSE);
fprintf('  Final position err : %.4f m\n', out.finalPositionError);
