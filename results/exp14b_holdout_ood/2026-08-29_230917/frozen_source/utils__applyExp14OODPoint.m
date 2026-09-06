function cfg = applyExp14OODPoint(pointId,seedValue)
%APPLYEXP14OODPOINT Build one frozen EXP14 secondary/OOD configuration.

pointId = lower(strtrim(char(pointId)));
cfg = study2Exp14Config(seedValue,'moderate');

switch pointId
    case 'n10-ring2'
        cfg = resizeSwarm(cfg,10,'ring2');
        cfg.sixdof.enable = false;

    case 'n20-ring2'
        cfg = resizeSwarm(cfg,20,'ring2');
        cfg.sixdof.enable = false;

    case 'n10-sparse4'
        cfg = resizeSwarm(cfg,10,'sparse4');
        cfg.sixdof.enable = false;

    case 'background030'
        cfg.mac.backgroundLoad = 0.30;

    case 'hidden-terminal'
        % Physical interference remains global, but each transmitter senses
        % only itself and its two ring neighbours.  Non-neighbour concurrent
        % transmitters are therefore genuine hidden interferers.
        cfg.mac.carrierSenseMatrix = ringCarrierSense(cfg.swarm.N);

    case 'reverse-asymmetric'
        % DATA remains Moderate.  Standalone ACKs meet a worse independently
        % varying reverse process; piggyback entries still follow DATA.
        cfg.mac.burst.ackGoodLoss = 0.15;
        cfg.mac.burst.ackBadLoss = 0.95;
        cfg.mac.burst.ackGoodToBad = 0.008;
        cfg.mac.burst.ackBadToGood = 0.022;

    case 'estimator-c3'
        cfg.estimator.latency = 0.050;
        cfg.estimator.noise = generateNoiseTrace(cfg,0.03,0.05);

    case 'aloha-p020'
        cfg.mac.type = 'aloha';

    otherwise
        error('applyExp14OODPoint: unknown point "%s".',pointId);
end

cfg.exp14.oodPoint = pointId;
cfg.mac = sharedMediumConfig(cfg);

end


function cfg = resizeSwarm(cfg,N,topology)

cfg = applyTopologyConfig(cfg,N,topology);
cfg.mac.interferenceMatrix = true(N);
cfg.mac.carrierSenseMatrix = true(N);

end


function C = ringCarrierSense(N)

C = eye(N)>0;
for node = 1:N
    C(node,mod(node-2,N)+1)=true;
    C(node,mod(node,N)+1)=true;
end

end
