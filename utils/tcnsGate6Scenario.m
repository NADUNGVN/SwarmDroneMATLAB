function [cfg,scenario] = tcnsGate6Scenario(seedValue,scenarioId)
%TCNSGATE6SCENARIO Frozen development scenarios for adaptivity falsification.
%
% S1 stationary Moderate control; S2 continuous formation switching; S3
% Gilbert-Elliott burst loss; S4 time-varying loss/delay/jitter; S5 temporary
% topology outage; S6 deterministic follower excitation. Every scenario is
% method-blind and uses a 30 s exact-DI mission.

sc = exp10Scenarios();
points = exp10Points();
pt = points(strcmp({points.id},'NOMINAL'));
cfg = applyExp10Point(pt,sc.MODERATE,seedValue);
cfg.sixdof.enable = false;
cfg.swarm.T = 30;

scenario.id = upper(char(scenarioId));
scenario.evaluationStart_s = 8;
scenario.eventWindows_s = zeros(0,2);
scenario.description = '';

switch scenario.id
    case 'S1'
        scenario.name = 'Stationary-Moderate';
        scenario.description = ...
            'Stationary IID Moderate channel and unchanged formation.';

    case 'S2'
        scenario.name = 'Formation-switching';
        scenario.description = ...
            'Continuous 90-degree formation rotation and return.';
        base = cfg.swarm.offsets;
        rotated = base;
        rotated(:,1:2) = base(:,1:2)*[0 1;-1 0];
        times = [0 10 14 20 24 30];
        values = zeros(numel(times),cfg.swarm.N,3);
        values(1,:,:) = reshape(base,1,cfg.swarm.N,3);
        values(2,:,:) = reshape(base,1,cfg.swarm.N,3);
        values(3,:,:) = reshape(rotated,1,cfg.swarm.N,3);
        values(4,:,:) = reshape(rotated,1,cfg.swarm.N,3);
        values(5,:,:) = reshape(base,1,cfg.swarm.N,3);
        values(6,:,:) = reshape(base,1,cfg.swarm.N,3);
        cfg.tcns.formationSchedule.time_s = times;
        cfg.tcns.formationSchedule.offsets = values;
        scenario.eventWindows_s = [10 14;20 24];

    case 'S3'
        scenario.name = 'Gilbert-Elliott-burst-loss';
        scenario.description = ...
            'Forward burst loss with stationary mean loss about 0.41.';
        cfg.net.lossModel.type = 'gilbert-elliott';
        cfg.net.lossModel.pGoodToBad = 0.04;
        cfg.net.lossModel.pBadToGood = 0.06;
        cfg.net.lossModel.lossGood = 0.05;
        cfg.net.lossModel.lossBad = 0.95;
        cfg.net.packetLoss = 0.41; % descriptive fallback; trace mask is authoritative
        scenario.eventWindows_s = [8 30];

    case 'S4'
        scenario.name = 'Time-varying-congestion';
        scenario.description = ...
            'Moderate to congested to clean and back, including jitter.';
        regime.tStart = [0 10 16 22];
        regime.loss = [0.20 0.40 0.10 0.20];
        regime.delay = [0.08 0.18 0.02 0.08];
        regime.jitterStd = [0 0.04 0.01 0];
        regime.label = {'Moderate','Congested','Clean','Moderate'};
        cfg.net.regime = regime;
        ackRegime = regime;
        ackRegime.loss = zeros(size(regime.loss));
        cfg.ack.regime = ackRegime;
        scenario.eventWindows_s = [10 16;16 22;22 30];

    case 'S5'
        scenario.name = 'Topology-perturbation';
        scenario.description = ...
            'Thirty percent of configured directed links unavailable for 6 s.';
        cfg.fault = generateFaultRealization(cfg,'burst',6.0);
        scenario.eventWindows_s = [cfg.fault.tStart cfg.fault.tEnd];

    case 'S6'
        scenario.name = 'Dynamic-excitation';
        scenario.description = ...
            'Two method-blind sine acceleration pulses on different followers.';
        D.tStart_s = [12 20];
        D.duration_s = [4 4];
        D.amplitude_mps2 = [0.8 0.8];
        D.axis = [1 0 0;0 1 0];
        D.nodeMask = zeros(2,cfg.swarm.N);
        D.nodeMask(1,3) = 1;
        D.nodeMask(2,4) = 1;
        cfg.tcns.diDisturbance = D;
        scenario.eventWindows_s = [12 16;20 24];

    otherwise
        error('tcnsGate6Scenario:UnknownScenario', ...
            'Unknown Gate-6 scenario "%s".',scenarioId);
end

scenario.seed = seedValue;
scenario.horizon_s = cfg.swarm.T;

end
