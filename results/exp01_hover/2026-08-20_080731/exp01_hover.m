% EXP01_HOVER Single-drone 6-DOF hover baseline.
startup;

%% ============================================================
% Result persistence
%
% Creates results/exp01_hover/<runId>/ and captures every line printed
% below into console.log. Paired with the save block at the end.
% ============================================================

expRun = startExperiment('exp01_hover');


cfg = defaultConfig();
out = simSingleDrone(cfg);
plotSingleDrone(out);

fprintf('\nEXP01 hover results\n');
fprintf('  Position RMSE      : %.4f m\n', out.positionRMSE);
fprintf('  Final position err : %.4f m\n', out.finalPositionError);


%% ============================================================
% Persist results
%
% save() with no variable list stores the ENTIRE script workspace,
% so every sweep axis and result array is preserved without having
% to enumerate names.
% ============================================================

save(fullfile(expRun.dir,'workspace.mat'));

saveAllFigures(expRun);

finishExperiment(expRun);
