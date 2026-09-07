function Q = tcnsOracleQuadraticCrossTerm(out,cfg,horizonSamples)
%TCNSORACLEQUADRATICCROSSTERM Centralized fixed-future-input value audit.
%
%   Q = tcnsOracleQuadraticCrossTerm(out,cfg,H)
%
% For every controller-relevant current-state update, form the exact Gate-3
% action response G and combine it with the logged no-action formation-error
% trajectory Z. The expected quadratic action benefit under one independent
% delivery attempt is
%
%   p_s * (||Z||^2 - ||Z+G||^2) / m
%     = -2*p_s*<Z,G>/m - p_s*||G||^2/m.
%
% This is a centralized receiver-truth diagnostic. Future network inputs and
% payloads are frozen to the logged baseline, and the candidate correction
% persists through the horizon. It is not an online policy or a true
% closed-loop branch replay.

required = {'t','P','V','A','desiredOffsets', ...
    'receiverNeighborPosition','receiverNeighborVelocity', ...
    'receiverLeaderPosition','receiverLeaderVelocity', ...
    'receiverLeaderAcceleration'};
for q = 1:numel(required)
    if ~isfield(out,required{q})
        error('tcnsOracleQuadraticCrossTerm:MissingLog', ...
            'out.%s is required.',required{q});
    end
end
validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',3);
if isfield(cfg.net,'regime') && ~isempty(cfg.net.regime)
    error('tcnsOracleQuadraticCrossTerm:TimeVaryingChannel', ...
        'The first cross-term audit requires a static forward channel.');
end
if isfield(cfg.net,'jitterStd') && cfg.net.jitterStd~=0
    error('tcnsOracleQuadraticCrossTerm:JitterOutOfScope', ...
        'The first cross-term audit requires deterministic delay.');
end

np = netParamsAt(cfg,out.t(1));
h = cfg.swarm.dt;
delaySamples = max(0,ceil((np.delay-1e-12)/h));
kernel = tcnsFiniteHorizonLinkValueKernel( ...
    cfg,horizonSamples,delaySamples);
successProbability = 1-np.packetLoss;
certificate = formationTheoryCertificate(cfg);

N = cfg.swarm.N;
m = numel(certificate.followers);
Ktime = numel(out.t);
ordinaryIsolated = nan(Ktime,N,N);
ordinaryCross = nan(Ktime,N,N);
ordinaryBenefit = nan(Ktime,N,N);
leaderIsolated = nan(Ktime,N);
leaderCross = nan(Ktime,N);
leaderBenefit = nan(Ktime,N);

position = reshape(out.P,Ktime,N,3);
offset = reshape(out.desiredOffsets,Ktime,N,3);
leaderPosition = position(:,1,:);
formationError = position(:,certificate.followers,:) - ...
    leaderPosition - offset(:,certificate.followers,:);

maxResidual = 0;
candidateCount = 0;
lastDecisionIndex = Ktime-horizonSamples;
for k = 1:lastDecisionIndex
    baseline = formationError(k+(1:horizonSamples),:,:);
    for fi = 1:m
        i = certificate.followers(fi);
        scale = certificate.degreeScale(fi);
        scalarResponse = reshape( ...
            kernel.positionResponse(:,:,fi),horizonSamples,m);

        for j = 1:N
            if cfg.swarm.A(i,j)==0
                continue;
            end
            currentP = reshape(out.P(k,j,:),1,3);
            currentV = reshape(out.V(k,j,:),1,3);
            heldP = reshape( ...
                out.receiverNeighborPosition(k,i,j,:),1,3);
            heldV = reshape( ...
                out.receiverNeighborVelocity(k,i,j,:),1,3);
            correction = cfg.swarm.Kp*scale*(currentP-heldP) + ...
                cfg.swarm.Kv*scale*(currentV-heldV);
            [isolated,crossContribution,benefit,residual] = ...
                localValue(baseline,scalarResponse,correction, ...
                successProbability,m);
            ordinaryIsolated(k,i,j) = isolated;
            ordinaryCross(k,i,j) = crossContribution;
            ordinaryBenefit(k,i,j) = benefit;
            maxResidual = max(maxResidual,residual);
            candidateCount = candidateCount+1;
        end

        if cfg.swarm.pin(i)>0
            currentP = reshape(out.P(k,1,:),1,3);
            currentV = reshape(out.V(k,1,:),1,3);
            currentA = reshape(out.A(k,1,:),1,3);
            heldP = reshape(out.receiverLeaderPosition(k,i,:),1,3);
            heldV = reshape(out.receiverLeaderVelocity(k,i,:),1,3);
            heldA = reshape(out.receiverLeaderAcceleration(k,i,:),1,3);
            correction = cfg.swarm.KpLeader*(currentP-heldP) + ...
                cfg.swarm.KvLeader*(currentV-heldV) + (currentA-heldA);
            [isolated,crossContribution,benefit,residual] = ...
                localValue(baseline,scalarResponse,correction, ...
                successProbability,m);
            leaderIsolated(k,i) = isolated;
            leaderCross(k,i) = crossContribution;
            leaderBenefit(k,i) = benefit;
            maxResidual = max(maxResidual,residual);
            candidateCount = candidateCount+1;
        end
    end
end

Q.time_s = out.t;
Q.lastDecisionIndex = lastDecisionIndex;
Q.formationError = formationError;
Q.ordinaryIsolatedResponseEnergy = ordinaryIsolated;
Q.ordinaryCrossContribution = ordinaryCross;
Q.ordinaryExpectedBenefit = ordinaryBenefit;
Q.leaderIsolatedResponseEnergy = leaderIsolated;
Q.leaderCrossContribution = leaderCross;
Q.leaderExpectedBenefit = leaderBenefit;
Q.kernel = kernel;
Q.successProbability = successProbability;
Q.delaySamples = delaySamples;
Q.candidateCount = candidateCount;
Q.maxDecompositionResidual = maxResidual;
Q.oracle = true;
Q.onlinePolicyAdmissible = false;
Q.trueClosedLoopBranch = false;
Q.futureInputContract = 'logged baseline inputs frozen; persistent correction';
Q.interpretation = [ ...
    'Centralized fixed-future-input quadratic marginal-value audit; ' ...
    'not an online policy or a true endogenous branch replay.'];

end


function [isolated,crossContribution,benefit,residual] = ...
    localValue(baseline,scalarResponse,correction,successProbability,m)

actionResponse = scalarResponse .* reshape(correction,1,1,3);
energy = sum(actionResponse.^2,'all');
crossInnerProduct = sum(baseline.*actionResponse,'all');
isolated = successProbability*energy/m;
crossContribution = -2*successProbability*crossInnerProduct/m;
benefit = crossContribution-isolated;
direct = successProbability*(sum(baseline.^2,'all') - ...
    sum((baseline+actionResponse).^2,'all'))/m;
residual = abs(benefit-direct);

end
