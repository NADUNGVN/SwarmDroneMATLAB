function cfg = tcnsR2RegistryConfiguration(seed,N,graphId,pinId)
%TCNSR2REGISTRYCONFIGURATION Reconstruct one preregistered R2 configuration.
%
% This helper does not expand the R2 registry.  It exposes the exact
% configuration law that was frozen in R2_GENERALIZATION_WITNESS_PROTOCOL.md
% so that the R2.5 adversarial audit can rebuild and cross-check every cell.

[cfg,~] = tcnsGate6Scenario(seed,'S1');
cfg = applyTopologyConfig(cfg,N,char(string(graphId)));
cfg.swarm.normalizeConsensusDegree = false;
cfg.swarm.Kp = 1.8;
cfg.swarm.Kv = 2.2;
cfg.swarm.KpLeader = 1.5;
cfg.swarm.KvLeader = 1.8;

pin = zeros(N,1);
switch lower(string(pinId))
    case "even"
        pin(2:2:N) = 1;
    case "odd"
        pin(3:2:N) = 1;
    otherwise
        error('tcnsR2RegistryConfiguration:PinRegistry', ...
            'Unknown pin registry entry %s.',string(pinId));
end
cfg.swarm.pin = pin;

end
