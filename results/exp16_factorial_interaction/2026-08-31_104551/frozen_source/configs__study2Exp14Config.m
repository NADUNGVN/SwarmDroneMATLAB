function cfg = study2Exp14Config(seedValue,scenarioId)
%STUDY2EXP14CONFIG Frozen N=5/6-DOF primary configuration for EXP14.
%
%   cfg = study2Exp14Config(seedValue,scenarioId)
%
% scenarioId is one closed identifier returned by exp14ChannelScenarios.
% Hardware-dependent PHY quantities are an abstract multi-slot calibration,
% not measured radio parameters.

if nargin < 1 || isempty(seedValue)
    seedValue = 0;
end
if nargin < 2 || isempty(scenarioId)
    scenarioId = 'moderate';
end
if ~isscalar(seedValue) || ~isfinite(seedValue) || ...
        seedValue < 0 || seedValue ~= floor(seedValue)
    error('study2Exp14Config: seedValue must be a nonnegative integer.');
end

scenarios = exp14ChannelScenarios();
scenarioId = lower(strtrim(char(scenarioId)));
idx = find(strcmp({scenarios.id},scenarioId),1);
if isempty(idx)
    error('study2Exp14Config: unknown channel scenario "%s".',scenarioId);
end
sc = scenarios(idx);

cfg = study2SharedMediumConfig();
cfg = applyTopologyConfig(cfg,5,'ring2');
cfg.net.seed = seedValue;

cfg.sixdof.enable = true;
cfg.sixdof.ratio = 10;

% EXP13B multi-slot calibration: bare DATA spans four 1-ms slots.
cfg.mac.dataBytes = 96;
cfg.mac.ackBaseBytes = 16;
cfg.mac.ackEntryBytes = 8;
cfg.mac.phyRateBps = 250e3;
cfg.mac.slotTime = 1e-3;
cfg.mac.type = 'csma';
cfg.mac.pAccess = 0.20;
cfg.mac.backgroundLoad = 0;
cfg.mac.interferenceMatrix = true(cfg.swarm.N);
cfg.mac.carrierSenseMatrix = true(cfg.swarm.N);

cfg.mac.lossModel = 'gilbert-elliott';
cfg.mac.separateAckTrace = true;
cfg.mac.residualLoss = 0;
cfg.mac.dataResidualLoss = 0;
cfg.mac.ackResidualLoss = 0;
cfg.mac.burst.dataGoodLoss = sc.dataGoodLoss;
cfg.mac.burst.dataBadLoss = sc.dataBadLoss;
cfg.mac.burst.dataGoodToBad = sc.dataGoodToBad;
cfg.mac.burst.dataBadToGood = sc.dataBadToGood;
cfg.mac.burst.ackGoodLoss = sc.ackGoodLoss;
cfg.mac.burst.ackBadLoss = sc.ackBadLoss;
cfg.mac.burst.ackGoodToBad = sc.ackGoodToBad;
cfg.mac.burst.ackBadToGood = sc.ackBadToGood;

cfg.exp14.version = 'EXP14-FROZEN-v1';
cfg.exp14.scenario = sc.id;
cfg.exp14.scenarioLabel = sc.label;

% Re-validate the complete public MAC contract now, rather than permitting a
% malformed OOD override to fail only after a long holdout job has started.
cfg.mac = sharedMediumConfig(cfg);

end
