function cfg = study2SharedMediumConfig()
%STUDY2SHAREDMEDIUMCONFIG Declared development default for EXP12/Study 2.
%
% This is a development configuration, not a frozen holdout configuration.
% The primary p-persistent access probability is the analytical value
% 1/(N-1+1)=1/5 for the N=5 fully-conflicting domain.  Hardware-dependent
% quantities remain explicit so EXP15 can replace them after measurement.

cfg = defaultConfig();

cfg.swarm.T = 12.0;

cfg.event.posThreshold = 0.05;
cfg.event.velThreshold = 0.10;
cfg.event.maxSilence   = 0.50;

cfg.aoiEvent.posThreshold      = 0.05;
cfg.aoiEvent.velThreshold      = 0.10;
cfg.aoiEvent.aoiThreshold      = 0.12;
cfg.aoiEvent.maxSilence        = 0.50;
cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
cfg.aoiEvent.aoiMinInterTx     = 0.10;
cfg.aoiEvent.aoiStateScaleBase = 0.50;
cfg.aoiEvent.aoiStateScaleMin  = 0.20;
cfg.aoiEvent.aoiAdaptRange     = 1.00;

cfg.mac.type            = 'csma';
cfg.mac.slotTime        = 1e-3;
cfg.mac.queueCapacity   = 4;
cfg.mac.dataBytes       = 48;
cfg.mac.ackBaseBytes    = 12;
cfg.mac.ackEntryBytes   = 8;
cfg.mac.phyRateBps      = 1e6;
cfg.mac.ackDeadline     = 0.02;
cfg.mac.pAccess         = 0.20;
cfg.mac.historySize     = 32;
cfg.mac.residualLoss    = 0.0;
% Legacy iid behavior remains the default. EXP14 explicitly enables the
% extended, independent DATA/ACK trace and Gilbert-Elliott model.
cfg.mac.lossModel       = 'iid';
cfg.mac.separateAckTrace = false;
cfg.mac.seedOffset      = 31012026;
cfg.mac.maxRetries      = 2;
cfg.mac.txPowerW        = 0.20;
cfg.mac.backgroundLoad  = 0.0;
cfg.mac.interferenceMatrix = true(cfg.swarm.N);
cfg.mac.carrierSenseMatrix = true(cfg.swarm.N);

% The end-to-end simulator requires delivery/ACK application at the MAC event
% time.  Low-level micro-tests leave this false and apply returned events
% explicitly; simSwarmSharedMedium sets it true at its boundary.
cfg.mac.applyDeliveriesInline = true;

cfg.shared.method = 'causal-broadcast';
cfg.shared.feedbackEnabled = true;
cfg.shared.feedbackMode = 'hybrid';
cfg.shared.assertInvariants = true;
cfg.shared.evalStart = 8.0;

% EXP13 causal baseline defaults.  These are development parameters and do
% not read realized receiver state or MAC outcomes.
cfg.shared.aociRiskThreshold = 1.0;
cfg.shared.beliefAgeThreshold = cfg.aoiEvent.aoiThreshold;
cfg.shared.beliefParticleCount = 64;
cfg.shared.beliefDeliveryProbability = 0.65;

end
