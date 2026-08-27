function cfg = applyExp10Point(pt, iScenario, seedValue)
%APPLYEXP10POINT Build the complete config for one EXP10 run.
%
%   cfg = applyExp10Point(pt, iScenario, seedValue)
%
% pt is one entry of exp10Points(). Everything that is frozen for EXP10
% lives here, in one place, so a point cannot be configured differently
% by EXP10A, by EXP10B's re-derivation or by the reproducibility check.
% The method is NOT set here: it is passed to simSwarm6DOF, which is the
% only thing that differs between the four arms of a cell.
%
% SEED CONVENTION - THIS IS AN AMENDMENT AND IS DELIBERATE
%
% EXP07-EXP09 folded the scenario, topology and N indices into
% cfg.net.seed, so each cell had its own realization. EXP10 does not:
%
%   cfg.net.seed = seedValue          exactly, one of the 50 holdout seeds
%
% The seed alone therefore determines all six master realizations, which
% is what plan section 5 asks for. Two consequences, both intended:
%
%   - Clean, Moderate and Stressed at one seed share one set of channel
%     uniforms. The scenario changes the THRESHOLDS applied to those
%     uniforms (loss probability, delay), not the draw. That is common
%     random numbers across scenarios, and it makes a scenario-to-
%     scenario difference attributable to the network quality rather
%     than to the draw.
%   - The forward and reverse traces are shaped (K x N x N), so their
%     hashes differ between the N = 5, N = 20 and N = 50 points at the
%     same seed. Hash equality is therefore required WITHIN a point and
%     scenario across methods, never across points of different N.
%
% Locked parameter values below are the EXP09 values, unchanged. The one
% behavioural change EXP10 makes on purpose is the transmission phase.

sc = exp10Scenarios();


%% ============================================================
% Baseline geometry and graph
% ============================================================

cfg = applyTopologyConfig(defaultConfig(), pt.N, pt.topology);

% Original controller, as in every EXP08 and EXP09 run. The
% degree-normalised variant stays the EXP08A-D diagnostic it was.
cfg.swarm.normalizeConsensusDegree = false;


%% ============================================================
% Network scenario
% ============================================================

cfg.net.packetLoss = sc.loss(iScenario);
cfg.net.delay      = sc.delay(iScenario);
cfg.net.jitterStd  = 0;

cfg.net.seed = seedValue;

cfg.net.useTrace = true;


%% ============================================================
% Transmission phase - the one deliberate behavioural change
%
% Historical locked results ran every periodic sender on one global
% clock. EXP10 gives each (physical sender, payload class) its own
% deterministic offset inside its period. See generatePhaseTrace for
% why the draw is per sender and not per directed link, and why P10 and
% P20 share one phase realization.
%
% The legacy cfg.net.phaseOffset flag is left off and is inert; it never
% had an effect. See network/simSwarmNetworkQueued.m.
% ============================================================

cfg.net.phaseOffset        = false;
cfg.net.phaseOffsetEnabled = true;


%% ============================================================
% Locked trigger parameters
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
cfg.event.maxSilence   = maxSilenceValue();


%% ============================================================
% Reverse ACK channel
%
% Reliable and symmetric with the forward path by default. The ACK
% point overrides the loss below.
% ============================================================

cfg.ack.loss      = 0.0;
cfg.ack.delay     = sc.delay(iScenario);
cfg.ack.jitterStd = 0;
cfg.ack.useTrace  = true;

cfg.ack.assertInvariants = true;


%% ============================================================
% Causal-v3, frozen
% ============================================================

cfg.causal.useAdaptiveScale   = true;
cfg.causal.useAckFeedback     = true;
cfg.causal.innovationPriority = true;


%% ============================================================
% Plant
% ============================================================

switch lower(pt.plant)

    case '6dof'
        cfg.sixdof.enable = true;
        cfg.sixdof.ratio  = 10;

    case 'di'
        cfg.sixdof.enable = false;
        cfg.sixdof.ratio  = 10;

    otherwise
        error('applyExp10Point: unknown plant "%s".', pt.plant);

end


%% ============================================================
% Point-specific perturbation
%
% Exactly one of these per point, at the pre-registered value. Nothing
% is swept: EXP10 is validation at selected points, not a new sweep.
% ============================================================

switch lower(pt.kind)

    case 'nominal'

        % Nothing further. cfg.fault, cfg.blackout, cfg.extForce and
        % cfg.estimator are absent, and every consumer treats an absent
        % field as inert.

    case 'ack'

        % EXP07B reference impairment: 10 % reverse loss, reverse delay
        % equal to the forward DATA delay for this scenario, no jitter.
        cfg.ack.loss      = 0.10;
        cfg.ack.delay     = sc.delay(iScenario);
        cfg.ack.jitterStd = 0;

    case 'mismatch'

        % EXP09B arm B7, verbatim.
        arm = struct( ...
            'wind',       0.5, ...
            'massFactor', 1.10, ...
            'dragFactor', 1.20, ...
            'lagTau',     0);

        cfg = applyPlantPerturbation(cfg, arm);

    case 'estimator'

        % EXP09C arm C3, verbatim.
        cfg.estimator.latency = 0.050;
        cfg.estimator.noise   = generateNoiseTrace(cfg, 0.03, 0.05);

    case 'link'

        % EXP08B permanent directed-link removal at 20 %. Modelled at
        % the delivery layer: cfg.swarm.A is never touched, so the
        % controller keeps using a dead link and the channel count -
        % the cost denominator - stays fixed.
        cfg.fault = generateFaultRealization(cfg, 'permanent', 0.20);

    case 'node'

        % EXP08C single-follower blackout, 5 s from t = 12 s. The node's
        % radio is off in both directions; its dynamics keep running.
        cfg.blackout = generateBlackoutRealization(cfg, 1, 5.0);

    otherwise
        error('applyExp10Point: unknown kind "%s".', pt.kind);

end

end


%% ============================================================
% LOCAL FUNCTION
%
% The state-event maxSilence, held apart only to make it obvious that
% it is the same 0.50 s the AoI branch uses and not a second value that
% drifted.
% ============================================================

function v = maxSilenceValue()

v = 0.50;

end
