%% RUN_ALL Run the full experiment suite in dependency order.
%
% Every experiment writes a timestamped folder under results/ containing
% console.log, workspace.mat, tidy.csv (Monte-Carlo experiments), figures
% and meta.json. Nothing is overwritten between runs.
%
% Rough cost on a 32-thread machine with the parallel pool available:
%
%   groups 1-2   under a minute each
%   group  3     a few minutes each
%   group  4     the scalability sweep, the longest single experiment
%
% To run one group only, copy the relevant lines.

startup;

suite = {
    % ---- Group 1: single vehicle, deterministic, seconds ----
    'exp01_hover'
    'exp01b_position_step'
    'exp01c_disturbance'
    'exp01d_trajectory'

    % ---- Group 2: nominal swarm and single-factor network sweeps ----
    'exp02_formation'
    'exp03a_packet_loss'
    'exp03b_delay'

    % ---- Group 3: multi-factor sweeps and policy comparison ----
    'exp03c_loss_delay'
    'exp03d_jitter'
    'exp04a_comm_rate'
    'exp04b_rate_impairment'
    'exp05a_event_triggered'
    'exp05b_aoi_aware'
    'exp05c_ablation'
    'exp05d_pareto_frontier'

    % ---- Group 4: swarm-size scalability ----
    'exp06a_scalability'
};

% NOTE: exp03_packet_loss_sweep is deliberately excluded. It is superseded
% by exp03a_packet_loss and no longer runs; see the header of that file.

nExp = numel(suite);

failed = {};

tAll = tic;

for k = 1:nExp

    name = suite{k};

    fprintf('\n');
    fprintf('############################################################\n');
    fprintf('# [%d/%d] %s\n', k, nExp, name);
    fprintf('############################################################\n');

    try
        evalin('base', name);
    catch err
        fprintf(2, 'FAILED: %s -- %s\n', name, err.message);
        failed{end+1} = name; %#ok<SAGROW>
    end

end

fprintf('\n');
fprintf('############################################################\n');
fprintf('# Suite finished in %.1f min\n', toc(tAll)/60);

if isempty(failed)
    fprintf('# All %d experiments completed.\n', nExp);
else
    fprintf('# %d failed: %s\n', numel(failed), strjoin(failed, ', '));
end

fprintf('# Run log: results/INDEX.md\n');
fprintf('############################################################\n');
