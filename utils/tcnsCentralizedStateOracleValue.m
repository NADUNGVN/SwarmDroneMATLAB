function Q = tcnsCentralizedStateOracleValue( ...
    P,V,leader,net,tk,cfg,horizonSamples,precomputed)
%TCNSCENTRALIZEDSTATEORACLEVALUE Non-anticipative current-truth link values.
%
% Uses current plant truth and current receiver-held payload truth to form
% the exact current communication-induced command residual. The no-action
% formation response is propagated through the Gate-3 sampled model while
% holding CURRENT formation offsets, leader acceleration and communication
% residual fixed. No future reference, disturbance, trajectory or channel
% outcome is read.
%
% For link action response G_ij and frozen-current no-action response Z,
%
%   q_ij = p_s * (||Z||_F^2 - ||Z+G_ij||_F^2) / (N-1).
%
% This is a privileged centralized diagnostic value, not a distributed or
% implementable sender policy.

validateattributes(tk,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'tk',5);
validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',7);
N = cfg.swarm.N;
if ~isequal(size(P),[N 3]) || ~isequal(size(V),[N 3]) || ...
        any(~isfinite(P),'all') || any(~isfinite(V),'all')
    error('tcnsCentralizedStateOracleValue:State', ...
        'P and V must be finite N-by-3 current plant states.');
end
if isfield(cfg,'sixdof') && isfield(cfg.sixdof,'enable') && ...
        cfg.sixdof.enable
    error('tcnsCentralizedStateOracleValue:PlantScope', ...
        'O1 is restricted to the exact Gate-3 double-integrator model.');
end
h = cfg.swarm.dt;
np = netParamsAt(cfg,tk);
delaySamples = max(0,ceil((np.delay-1e-12)/h));
successProbability = 1-np.packetLoss;
if nargin < 8 || isempty(precomputed)
    certificate = tcnsFormationRobustnessCertificate(cfg);
    formationCertificate = formationTheoryCertificate(cfg);
    kernel = tcnsFiniteHorizonLinkValueKernel( ...
        cfg,horizonSamples,delaySamples);
else
    requiredModel = {'certificate','formationCertificate','kernel'};
    for q = 1:numel(requiredModel)
        if ~isfield(precomputed,requiredModel{q})
            error('tcnsCentralizedStateOracleValue:Precomputed', ...
                'precomputed.%s is required.',requiredModel{q});
        end
    end
    certificate = precomputed.certificate;
    formationCertificate = precomputed.formationCertificate;
    kernel = precomputed.kernel;
    if kernel.horizonSamples~=horizonSamples || ...
            kernel.delaySamples~=delaySamples
        error('tcnsCentralizedStateOracleValue:Precomputed', ...
            'Precomputed O1 model does not match current horizon/delay.');
    end
end
followers = certificate.followers;
m = numel(followers);

offsetsNow = tcnsFormationOffsetsAt(cfg,tk);
leaderPosition = reshape(leader.pos,1,3);
leaderVelocity = reshape(leader.vel,1,3);
leaderAcceleration = reshape(leader.acc,1,3);
positionError = P(followers,:) - leaderPosition - offsetsNow(followers,:);
velocityError = V(followers,:) - leaderVelocity;

communicationResidual = zeros(m,3);
ordinaryCorrection = nan(N,N,3);
ordinaryPositionResidual = nan(N,N);
ordinaryVelocityResidual = nan(N,N);
leaderCorrection = nan(N,3);
leaderPositionResidual = nan(N,1);
leaderVelocityResidual = nan(N,1);

for fi = 1:m
    i = followers(fi);
    scale = certificate.degreeScale(fi);
    for j = 1:N
        if cfg.swarm.A(i,j)==0
            continue;
        end
        heldP = reshape(net.Pij(i,j,:),1,3);
        heldV = reshape(net.Vij(i,j,:),1,3);
        dp = P(j,:)-heldP;
        dv = V(j,:)-heldV;
        correction = cfg.swarm.Kp*scale*dp + cfg.swarm.Kv*scale*dv;
        ordinaryCorrection(i,j,:) = reshape(correction,1,1,3);
        ordinaryPositionResidual(i,j) = norm(dp);
        ordinaryVelocityResidual(i,j) = norm(dv);
        communicationResidual(fi,:) = ...
            communicationResidual(fi,:)-correction;
    end

    if cfg.swarm.pin(i)>0
        dp = P(1,:)-net.leaderPos(i,:);
        dv = V(1,:)-net.leaderVel(i,:);
        da = leaderAcceleration-net.leaderAcc(i,:);
        correction = cfg.swarm.KpLeader*dp + ...
            cfg.swarm.KvLeader*dv + da;
        leaderCorrection(i,:) = correction;
        leaderPositionResidual(i) = norm(dp);
        leaderVelocityResidual(i) = norm(dv);
        communicationResidual(fi,:) = ...
            communicationResidual(fi,:)-correction;
    end
end

% Current-information, non-anticipative no-action prediction. Constant
% leader acceleration gives relative acceleration (pin_i-1)*a_L. No future
% call to the reference, formation schedule or disturbance process occurs.
pinFollower = double(cfg.swarm.pin(followers)>0);
frozenInput = communicationResidual + ...
    (pinFollower-ones(m,1))*leaderAcceleration;
state = [positionError;h*velocityError];
baselineResponse = zeros(horizonSamples,m,3);
predictedCommandMagnitude = zeros(horizonSamples,m);
for r = 1:horizonSamples
    predictedPositionError = state(1:m,:);
    predictedVelocityError = state(m+1:end,:)/h;
    predictedCommand = ...
        -formationCertificate.Hp*predictedPositionError ...
        -formationCertificate.Hv*predictedVelocityError ...
        +pinFollower*leaderAcceleration ...
        +communicationResidual;
    predictedCommandMagnitude(r,:) = ...
        reshape(vecnorm(predictedCommand,2,2),1,m);
    state = certificate.Ah*state + certificate.Bc*frozenInput;
    baselineResponse(r,:,:) = reshape(state(1:m,:),1,m,3);
end

ordinaryValue = nan(N,N);
ordinaryIsolated = nan(N,N);
ordinaryCross = nan(N,N);
ordinaryResponse = cell(N,N);
leaderValue = nan(N,1);
leaderIsolated = nan(N,1);
leaderCross = nan(N,1);
leaderResponse = cell(N,1);

for fi = 1:m
    i = followers(fi);
    scalarResponse = reshape( ...
        kernel.positionResponse(:,:,fi),horizonSamples,m);
    for j = 1:N
        if cfg.swarm.A(i,j)==0
            continue;
        end
        correction = reshape(ordinaryCorrection(i,j,:),1,3);
        actionResponse = scalarResponse .* reshape(correction,1,1,3);
        [ordinaryValue(i,j),ordinaryIsolated(i,j), ...
            ordinaryCross(i,j)] = localValue( ...
            baselineResponse,actionResponse,successProbability,m);
        ordinaryResponse{i,j} = actionResponse;
    end
    if cfg.swarm.pin(i)>0
        correction = leaderCorrection(i,:);
        actionResponse = scalarResponse .* reshape(correction,1,1,3);
        [leaderValue(i),leaderIsolated(i),leaderCross(i)] = ...
            localValue(baselineResponse,actionResponse, ...
            successProbability,m);
        leaderResponse{i} = actionResponse;
    end
end

Q.time_s = tk;
Q.horizonSamples = horizonSamples;
Q.delaySamples = delaySamples;
Q.successProbability = successProbability;
Q.baselineResponse = baselineResponse;
Q.communicationResidual = communicationResidual;
Q.predictedCommandMagnitude = predictedCommandMagnitude;
Q.predictedSaturationFraction = mean( ...
    predictedCommandMagnitude>=cfg.swarm.maxAccel-1e-10,'all');
Q.ordinaryValue = ordinaryValue;
Q.ordinaryIsolatedResponseEnergy = ordinaryIsolated;
Q.ordinaryCrossContribution = ordinaryCross;
Q.ordinaryActionResponse = ordinaryResponse;
Q.ordinaryPositionResidual = ordinaryPositionResidual;
Q.ordinaryVelocityResidual = ordinaryVelocityResidual;
Q.leaderValue = leaderValue;
Q.leaderIsolatedResponseEnergy = leaderIsolated;
Q.leaderCrossContribution = leaderCross;
Q.leaderActionResponse = leaderResponse;
Q.leaderPositionResidual = leaderPositionResidual;
Q.leaderVelocityResidual = leaderVelocityResidual;
Q.centralizedStateOracle = true;
Q.onlineNonanticipative = true;
Q.usesCurrentReceiverTruth = true;
Q.usesFutureChannelOutcome = false;
Q.usesFutureDisturbance = false;
Q.usesFutureFormationChange = false;
Q.usesFutureTrajectory = false;
Q.interpretation = [ ...
    'Current-truth Gate-3 cross-term value under a frozen-current ' ...
    'no-action prediction; privileged but non-anticipative.'];

end


function [value,isolated,crossContribution] = ...
    localValue(baseline,actionResponse,successProbability,m)

energy = sum(actionResponse.^2,'all');
crossInnerProduct = sum(baseline.*actionResponse,'all');
isolated = successProbability*energy/m;
crossContribution = -2*successProbability*crossInnerProduct/m;
value = crossContribution-isolated;

end
