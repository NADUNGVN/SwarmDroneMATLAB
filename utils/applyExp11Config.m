function cfg = applyExp11Config(seedValue, regime)
%APPLYEXP11CONFIG Build the complete config for one EXP11 run.
%
%   cfg = applyExp11Config(seedValue)
%   cfg = applyExp11Config(seedValue, networkRegimeSchedule('exp11'))
%
% Everything frozen for EXP11 lives here, in one place, so the driver, the
% debug run and the semantics test cannot configure the scenario
% differently. The METHOD is not set here: it is passed to simSwarmExp11.
%
% WHAT IS INHERITED UNCHANGED FROM THE FROZEN NOMINAL POINT
%
% N = 5, ring2 topology, 6-DOF followers at the locked inner ratio, the
% original (non-degree-normalised) controller, outer dt 0.02 s, inner dt
% 0.002 s, and every trigger threshold, cooldown, max-silence bound and
% adaptive-scale parameter at its locked value. These are copied from the
% EXP10 NOMINAL point verbatim. EXP11 changes the CHANNEL over time and
% nothing else; it is not permitted to touch Causal-v3, the controller, the
% plant or any threshold.
%
% WHAT IS NEW
%
%   - cfg.swarm.T = 83 s, the mission length the regime schedule needs.
%   - cfg.net.regime and cfg.ack.regime, the piecewise-constant channel.
%   - cfg.net.packetLoss / delay are set to the FIRST segment's values.
%     They are only a fallback: with a regime attached, netParamsAt
%     resolves the values per instant and these are never consulted after
%     t = 0. They are set to consistent values anyway so that a reader
%     inspecting cfg does not see a Clean run mislabelled.
%
% THE REVERSE CHANNEL DEGRADES WITH THE FORWARD CHANNEL
%
% The frozen nominal ACK semantics are: zero reverse loss, reverse delay
% equal to the forward DATA delay, no jitter. EXP11 keeps that
% relationship at every instant, which means the ACK delay follows the
% schedule while ACK loss stays zero throughout. Stated here rather than
% derived inside ackParamsAt, so the coupling is visible where the scenario
% is defined.

if nargin < 2 || isempty(regime)
    regime = networkRegimeSchedule('exp11');
end


%% ============================================================
% Baseline geometry and graph - the frozen NOMINAL point
% ============================================================

cfg = applyTopologyConfig(defaultConfig(), 5, 'ring2');

cfg.swarm.normalizeConsensusDegree = false;

cfg.swarm.T = regime.tEnd;


%% ============================================================
% Time-varying forward channel
% ============================================================

cfg.net.packetLoss = regime.loss(1);
cfg.net.delay      = regime.delay(1);
cfg.net.jitterStd  = 0;

cfg.net.regime = regime;

cfg.net.seed     = seedValue;
cfg.net.useTrace = true;


%% ============================================================
% Transmission phase, EXP10 semantics
%
% One deterministic offset per (physical sender, payload class), drawn
% independently of the period so that every rate on the ladder shares one
% phase realization. See generatePhaseTrace.
% ============================================================

cfg.net.phaseOffset        = false;
cfg.net.phaseOffsetEnabled = true;


%% ============================================================
% Locked trigger parameters - EXP10 NOMINAL values, verbatim
% ============================================================

epsP = 0.05;
epsV = 0.10;

cfg.aoiEvent.posThreshold      = epsP;
cfg.aoiEvent.velThreshold      = epsV;
cfg.aoiEvent.aoiThreshold      = 0.12;
cfg.aoiEvent.maxSilence        = 0.50;
cfg.aoiEvent.minInterTx        = cfg.swarm.dt;
cfg.aoiEvent.aoiMinInterTx     = 0.10;
cfg.aoiEvent.aoiStateScaleBase = 0.50;
cfg.aoiEvent.aoiStateScaleMin  = 0.20;
cfg.aoiEvent.aoiAdaptRange     = 1.00;

cfg.event.posThreshold = epsP;
cfg.event.velThreshold = epsV;
cfg.event.maxSilence   = localMaxSilenceValue();


%% ============================================================
% Time-varying reverse ACK channel
% ============================================================

ackRegime.tStart    = regime.tStart;
ackRegime.loss      = zeros(1, numel(regime.tStart));
ackRegime.delay     = regime.delay;
ackRegime.jitterStd = zeros(1, numel(regime.tStart));
ackRegime.label     = regime.label;

cfg.ack.loss      = ackRegime.loss(1);
cfg.ack.delay     = ackRegime.delay(1);
cfg.ack.jitterStd = 0;
cfg.ack.useTrace  = true;

cfg.ack.regime = ackRegime;

cfg.ack.assertInvariants = true;


%% ============================================================
% Causal-v3, frozen
% ============================================================

cfg.causal.useAdaptiveScale   = true;
cfg.causal.useAckFeedback     = true;
cfg.causal.innovationPriority = true;


%% ============================================================
% Plant - 6-DOF at the locked inner ratio
% ============================================================

cfg.sixdof.enable = true;
cfg.sixdof.ratio  = 10;

end


%% ============================================================
% LOCAL FUNCTION
%
% The state-event maxSilence, held apart for the same reason
% applyExp10Point holds it apart: to make it obvious that it is the same
% 0.50 s the AoI branch uses and not a second value that drifted.
% ============================================================

function v = localMaxSilenceValue()

v = 0.50;

end
