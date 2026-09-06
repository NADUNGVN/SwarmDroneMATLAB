function B = tcnsControlAwareBudget(cfg,epsilonPosition)
%TCNSCONTROLAWAREBUDGET Allocate a theorem-derived distributed link budget.
%
%   B = tcnsControlAwareBudget(cfg,epsilonPosition)
%
% epsilonPosition is the requested uniform ultimate bound [m] on the
% communication-induced follower-position degradation. The Gate-3
% structured certificate first maps it to one uniform follower command
% disturbance budget. That receiver budget is then divided equally among
% the controller-relevant incoming payload channels. Controller gains and
% graph weights remain inside each channel's measured contribution, so this
% allocation introduces no fitted AoI/state weights.
%
% This is a sufficient conditional allocation. It does not claim that a
% stochastic lossy channel will keep every link contribution below budget.

validateattributes(epsilonPosition,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'epsilonPosition',2);

certificate = tcnsFormationRobustnessCertificate(cfg);
N = cfg.swarm.N;
m = N-1;

uniformReceiver = ones(m,1);
positionCoefficient = certificate.positionPartialGain*uniformReceiver + ...
    certificate.positionTailCoefficient*sqrt(m);
worstPositionCoefficient = max(positionCoefficient);

if ~(isfinite(worstPositionCoefficient) && worstPositionCoefficient>0)
    error('tcnsControlAwareBudget:InvalidCertificate', ...
        'The Gate-3 position coefficient must be finite and positive.');
end

receiverCommandBudget = epsilonPosition/worstPositionCoefficient;
linkBudget = nan(N,N);
leaderBudget = nan(N,1);
channelCount = zeros(N,1);

ordinaryPositionGain = zeros(N,N);
ordinaryVelocityGain = zeros(N,N);
leaderPositionGain = zeros(N,1);
leaderVelocityGain = zeros(N,1);
leaderAccelerationGain = zeros(N,1);

for fi = 1:m
    i = certificate.followers(fi);
    activeOrdinary = find(cfg.swarm.A(i,:)~=0);
    q = numel(activeOrdinary) + double(cfg.swarm.pin(i)>0);
    if q==0
        error('tcnsControlAwareBudget:UncontrolledFollower', ...
            'Follower %d has no controller-relevant incoming channel.',i);
    end

    channelCount(i) = q;
    localBudget = receiverCommandBudget/q;
    scale = certificate.degreeScale(fi);

    for j = activeOrdinary
        linkBudget(i,j) = localBudget;
        ordinaryPositionGain(i,j) = ...
            cfg.swarm.Kp*scale*abs(cfg.swarm.A(i,j));
        ordinaryVelocityGain(i,j) = ...
            cfg.swarm.Kv*scale*abs(cfg.swarm.A(i,j));
    end

    if cfg.swarm.pin(i)>0
        leaderBudget(i) = localBudget;
        leaderPositionGain(i) = cfg.swarm.KpLeader*abs(cfg.swarm.pin(i));
        leaderVelocityGain(i) = cfg.swarm.KvLeader*abs(cfg.swarm.pin(i));
        leaderAccelerationGain(i) = abs(cfg.swarm.pin(i));
    end
end

certifiedPositionBound = ...
    certificate.positionPartialGain*(receiverCommandBudget*ones(m,1)) + ...
    certificate.positionTailCoefficient*receiverCommandBudget*sqrt(m);

if any(certifiedPositionBound>epsilonPosition+1e-12)
    error('tcnsControlAwareBudget:AllocationFailure', ...
        'The derived receiver budget does not satisfy its certificate.');
end

B.version = 'gate4-equal-link-v1';
B.scope = certificate.scope;
B.conditional = true;
B.epsilonPosition = double(epsilonPosition);
B.positionCoefficient = positionCoefficient;
B.worstPositionCoefficient = worstPositionCoefficient;
B.receiverCommandBudget = receiverCommandBudget;
B.certifiedPositionBound = certifiedPositionBound;
B.followerIds = certificate.followers;
B.receiverChannelCount = channelCount;
B.linkBudget = linkBudget;
B.leaderBudget = leaderBudget;
B.ordinaryPositionGain = ordinaryPositionGain;
B.ordinaryVelocityGain = ordinaryVelocityGain;
B.leaderPositionGain = leaderPositionGain;
B.leaderVelocityGain = leaderVelocityGain;
B.leaderAccelerationGain = leaderAccelerationGain;
B.certificateBlockLength = certificate.blockLength;
B.certificateContraction = certificate.blockContraction;
B.proofContract = [ ...
    'If every controller-relevant local contribution is no larger than ' ...
    'its allocation at every in-scope sample, the Gate-3 position UUB is ' ...
    'no larger than epsilonPosition.'];

end
