function M = tcnsPredictiveVoiModel(cfg,horizonSamples)
%TCNSPREDICTIVEVOIMODEL Precompute controller gains and value kernel.

validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',2);

np = netParamsAt(cfg,0);
h = cfg.swarm.dt;
delaySamples = max(0,ceil((np.delay-1e-12)/h));
kernel = tcnsFiniteHorizonLinkValueKernel( ...
    cfg,horizonSamples,delaySamples);
certificate = formationTheoryCertificate(cfg);
N = cfg.swarm.N;

ordinaryPositionGain = zeros(N,N);
ordinaryVelocityGain = zeros(N,N);
leaderPositionGain = zeros(N,1);
leaderVelocityGain = zeros(N,1);
leaderAccelerationGain = zeros(N,1);

for fi = 1:numel(certificate.followers)
    i = certificate.followers(fi);
    scale = certificate.degreeScale(fi);
    for j = find(cfg.swarm.A(i,:)~=0)
        ordinaryPositionGain(i,j) = ...
            cfg.swarm.Kp*scale*abs(cfg.swarm.A(i,j));
        ordinaryVelocityGain(i,j) = ...
            cfg.swarm.Kv*scale*abs(cfg.swarm.A(i,j));
    end
    if cfg.swarm.pin(i)>0
        leaderPositionGain(i) = cfg.swarm.KpLeader*abs(cfg.swarm.pin(i));
        leaderVelocityGain(i) = cfg.swarm.KvLeader*abs(cfg.swarm.pin(i));
        leaderAccelerationGain(i) = abs(cfg.swarm.pin(i));
    end
end

M.version = 'post-gate6-causal-one-shot-v1';
M.horizonSamples = double(horizonSamples);
M.horizon_s = horizonSamples*h;
M.delaySamples = delaySamples;
M.kernel = kernel;
M.ordinaryPositionGain = ordinaryPositionGain;
M.ordinaryVelocityGain = ordinaryVelocityGain;
M.leaderPositionGain = leaderPositionGain;
M.leaderVelocityGain = leaderVelocityGain;
M.leaderAccelerationGain = leaderAccelerationGain;
M.scope = [ ...
    'Gate-3 DI model plus exact static-IID/deterministic-delay/reliable-ACK ' ...
    'belief scope'];

end
