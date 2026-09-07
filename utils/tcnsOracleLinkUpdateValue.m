function V = tcnsOracleLinkUpdateValue(out,cfg,horizonSamples)
%TCNSORACLELINKUPDATEVALUE Receiver-truth one-shot information-value probe.
%
%   V = tcnsOracleLinkUpdateValue(out,cfg,H)
%
% For each controller-relevant payload and time, compute the exact command
% correction that would result if the current sender state replaced the
% receiver's held payload. Multiply its isolated finite-horizon formation
% energy by the probability that one newly sent packet is not lost. Static
% deterministic delay is represented exactly through the Gate-3 kernel.
%
% This diagnostic intentionally reads receiver truth and therefore MUST NOT
% be used by an online policy. It is a necessary-headroom test before the
% more difficult causal belief problem is attempted. It also ignores useful
% packets already in flight and later updates, so it is not a global or exact
% marginal VoI certificate.

required = {'t','P','V','A','receiverNeighborPosition', ...
    'receiverNeighborVelocity','receiverLeaderPosition', ...
    'receiverLeaderVelocity','receiverLeaderAcceleration'};
for q = 1:numel(required)
    if ~isfield(out,required{q})
        error('tcnsOracleLinkUpdateValue:MissingLog', ...
            'out.%s is required.',required{q});
    end
end
validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',3);
if isfield(cfg.net,'regime') && ~isempty(cfg.net.regime)
    error('tcnsOracleLinkUpdateValue:TimeVaryingChannel', ...
        ['The first one-shot diagnostic is intentionally restricted to ' ...
         'a static forward channel.']);
end
if isfield(cfg.net,'jitterStd') && cfg.net.jitterStd~=0
    error('tcnsOracleLinkUpdateValue:JitterOutOfScope', ...
        'The first one-shot diagnostic requires deterministic delay.');
end

np = netParamsAt(cfg,out.t(1));
h = cfg.swarm.dt;
delaySamples = ceil((np.delay-1e-12)/h);
delaySamples = max(delaySamples,0);
kernel = tcnsFiniteHorizonLinkValueKernel( ...
    cfg,horizonSamples,delaySamples);
successProbability = 1-np.packetLoss;

certificate = formationTheoryCertificate(cfg);
N = cfg.swarm.N;
Ktime = numel(out.t);
ordinary = nan(Ktime,N,N);
pinnedLeader = nan(Ktime,N);
totalByReceiver = zeros(Ktime,N-1);

for fi = 1:N-1
    i = certificate.followers(fi);
    scale = certificate.degreeScale(fi);
    for j = 1:N
        if cfg.swarm.A(i,j)==0
            continue;
        end
        currentP = reshape(out.P(:,j,:),Ktime,3);
        currentV = reshape(out.V(:,j,:),Ktime,3);
        heldP = reshape(out.receiverNeighborPosition(:,i,j,:),Ktime,3);
        heldV = reshape(out.receiverNeighborVelocity(:,i,j,:),Ktime,3);
        correction = cfg.swarm.Kp*scale*(currentP-heldP) + ...
            cfg.swarm.Kv*scale*(currentV-heldV);
        value = successProbability*kernel.positionMseGain(fi) .* ...
            sum(correction.^2,2);
        ordinary(:,i,j) = value;
        totalByReceiver(:,fi) = totalByReceiver(:,fi)+value;
    end

    if cfg.swarm.pin(i)>0
        currentP = reshape(out.P(:,1,:),Ktime,3);
        currentV = reshape(out.V(:,1,:),Ktime,3);
        currentA = reshape(out.A(:,1,:),Ktime,3);
        heldP = reshape(out.receiverLeaderPosition(:,i,:),Ktime,3);
        heldV = reshape(out.receiverLeaderVelocity(:,i,:),Ktime,3);
        heldA = reshape(out.receiverLeaderAcceleration(:,i,:),Ktime,3);
        correction = cfg.swarm.KpLeader*(currentP-heldP) + ...
            cfg.swarm.KvLeader*(currentV-heldV) + (currentA-heldA);
        value = successProbability*kernel.positionMseGain(fi) .* ...
            sum(correction.^2,2);
        pinnedLeader(:,i) = value;
        totalByReceiver(:,fi) = totalByReceiver(:,fi)+value;
    end
end

V.time_s = out.t;
V.ordinary = ordinary;
V.pinnedLeader = pinnedLeader;
V.totalByReceiver = totalByReceiver;
V.total = sum(totalByReceiver,2);
V.kernel = kernel;
V.successProbability = successProbability;
V.delaySamples = delaySamples;
V.oracle = true;
V.onlinePolicyAdmissible = false;
V.interpretation = [ ...
    'Expected isolated formation-MSE separation removed by a single ' ...
    'current-state delivery, ignoring in-flight/later updates and ' ...
    'multi-link cross terms.'];

end
