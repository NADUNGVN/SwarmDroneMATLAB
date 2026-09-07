function M = tcnsInformationLimitsModel(cfg,horizonSamples,delaySamples,tk)
%TCNSINFORMATIONLIMITSMODEL Exact affine Gate-3/O1 information model.
%
% One-axis primitive state (all velocity/acceleration entries are scaled to
% position units) is
%   [e; h*w; pL; h*vL; h^2*aL;
%    ordinary held p; ordinary h*held v;
%    pin held p; pin h*held v; pin h^2*held a].
% The 3-D state stacks the x, y and z one-axis states.

if nargin<4, tk = 0; end
validateattributes(tk,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'tk',4);
if isfield(cfg,'sixdof') && isfield(cfg.sixdof,'enable') && ...
        cfg.sixdof.enable
    error('tcnsInformationLimitsModel:PlantScope', ...
        'The information-limits model is restricted to the Gate-3 DI plant.');
end
certificate = formationTheoryCertificate(cfg);
if ~certificate.primaryTheoremApplicable || ~certificate.isSchur
    error('tcnsInformationLimitsModel:TheoremScope', ...
        'The fixed symmetric grounded Schur Gate-3 scope is required.');
end
kernel = tcnsFiniteHorizonLinkValueKernel( ...
    cfg,horizonSamples,delaySamples);
networkParameters = netParamsAt(cfg,tk);
successProbability = 1-networkParameters.packetLoss;
h = cfg.swarm.dt;
N = cfg.swarm.N;
followers = certificate.followers(:);
m = numel(followers);
offsets = tcnsFormationOffsetsAt(cfg,tk);

[edgeReceiver,edgeSender] = find(cfg.swarm.A);
active = ismember(edgeReceiver,followers);
edgeReceiver = edgeReceiver(active);
edgeSender = edgeSender(active);
nEdges = numel(edgeReceiver);
pinReceiver = find(cfg.swarm.pin(:)>0 & (1:N)'>=2);
nPins = numel(pinReceiver);

q = 0;
idx.e = q+(1:m); q = q+m;
idx.velocityStep = q+(1:m); q = q+m;
idx.leaderPosition = q+1; q = q+1;
idx.leaderVelocityStep = q+1; q = q+1;
idx.leaderAccelerationStep = q+1; q = q+1;
idx.ordinaryPosition = q+(1:nEdges); q = q+nEdges;
idx.ordinaryVelocityStep = q+(1:nEdges); q = q+nEdges;
idx.pinPosition = q+(1:nPins); q = q+nPins;
idx.pinVelocityStep = q+(1:nPins); q = q+nPins;
idx.pinAccelerationStep = q+(1:nPins); q = q+nPins;
nAxis = q;

stateNames = strings(nAxis,1);
for fi = 1:m
    i = followers(fi);
    stateNames(idx.e(fi)) = sprintf('e_%d',i);
    stateNames(idx.velocityStep(fi)) = sprintf('h_w_%d',i);
end
stateNames(idx.leaderPosition) = "p_L";
stateNames(idx.leaderVelocityStep) = "h_v_L";
stateNames(idx.leaderAccelerationStep) = "h2_a_L";
for a = 1:nEdges
    stateNames(idx.ordinaryPosition(a)) = sprintf( ...
        'pHat_%d_from_%d',edgeReceiver(a),edgeSender(a));
    stateNames(idx.ordinaryVelocityStep(a)) = sprintf( ...
        'h_vHat_%d_from_%d',edgeReceiver(a),edgeSender(a));
end
for a = 1:nPins
    stateNames(idx.pinPosition(a)) = sprintf( ...
        'pHatPin_%d',pinReceiver(a));
    stateNames(idx.pinVelocityStep(a)) = sprintf( ...
        'h_vHatPin_%d',pinReceiver(a));
    stateNames(idx.pinAccelerationStep(a)) = sprintf( ...
        'h2_aHatPin_%d',pinReceiver(a));
end

positionErrorMap = zeros(m,nAxis);
positionErrorMap(:,idx.e) = eye(m);
velocityErrorStepMap = zeros(m,nAxis);
velocityErrorStepMap(:,idx.velocityStep) = eye(m);
initialYMap = [positionErrorMap;velocityErrorStepMap];

% h^2*d^c, reconstructed exactly from primitive receiver memories.
communicationStepMap = zeros(m,nAxis);
communicationStepOffset = zeros(m,3);
for a = 1:nEdges
    i = edgeReceiver(a);
    j = edgeSender(a);
    fi = find(followers==i,1);
    scale = certificate.degreeScale(fi);
    [sourcePositionMap,sourcePositionOffset,sourceVelocityStepMap] = ...
        localSourceMaps(j,followers,idx,nAxis,offsets);
    deltaPositionMap = sourcePositionMap;
    deltaPositionMap(idx.ordinaryPosition(a)) = ...
        deltaPositionMap(idx.ordinaryPosition(a))-1;
    deltaVelocityStepMap = sourceVelocityStepMap;
    deltaVelocityStepMap(idx.ordinaryVelocityStep(a)) = ...
        deltaVelocityStepMap(idx.ordinaryVelocityStep(a))-1;
    communicationStepMap(fi,:) = communicationStepMap(fi,:) ...
        -h^2*cfg.swarm.Kp*scale*deltaPositionMap ...
        -h*cfg.swarm.Kv*scale*deltaVelocityStepMap;
    communicationStepOffset(fi,:) = communicationStepOffset(fi,:) ...
        -h^2*cfg.swarm.Kp*scale*sourcePositionOffset;
end
for a = 1:nPins
    i = pinReceiver(a);
    fi = find(followers==i,1);
    deltaPositionMap = zeros(1,nAxis);
    deltaPositionMap(idx.leaderPosition) = 1;
    deltaPositionMap(idx.pinPosition(a)) = -1;
    deltaVelocityStepMap = zeros(1,nAxis);
    deltaVelocityStepMap(idx.leaderVelocityStep) = 1;
    deltaVelocityStepMap(idx.pinVelocityStep(a)) = -1;
    accelerationErrorMap = zeros(1,nAxis);
    accelerationErrorMap(idx.pinAccelerationStep(a)) = 1;
    accelerationErrorMap(idx.leaderAccelerationStep) = -1;
    communicationStepMap(fi,:) = communicationStepMap(fi,:) ...
        -h^2*cfg.swarm.KpLeader*deltaPositionMap ...
        -h*cfg.swarm.KvLeader*deltaVelocityStepMap ...
        +accelerationErrorMap;
end

pinFollower = double(cfg.swarm.pin(followers)>0);
relativeInputStepMap = communicationStepMap;
relativeInputStepMap(:,idx.leaderAccelerationStep) = ...
    relativeInputStepMap(:,idx.leaderAccelerationStep) + ...
    pinFollower-ones(m,1);
relativeInputStepOffset = communicationStepOffset;

% Exact unsaturated current command h^2*u_F. This is also used to build
% the no-delivery/held-memory dynamics for reachable-history witnesses.
commandStepMap = communicationStepMap ...
    -h^2*certificate.Hp*positionErrorMap ...
    -h*certificate.Hv*velocityErrorStepMap;
commandStepMap(:,idx.leaderAccelerationStep) = ...
    commandStepMap(:,idx.leaderAccelerationStep)+pinFollower;
commandStepOffset = communicationStepOffset;

A = certificate.sampledAcl;
Bstep = [eye(m);eye(m)];
Cposition = [eye(m),zeros(m)];
stateMap = initialYMap;
stateOffset = zeros(2*m,3);
FAxis = zeros(horizonSamples*m,nAxis);
rAxis = zeros(horizonSamples*m,3);
for r = 1:horizonSamples
    stateMap = A*stateMap+Bstep*relativeInputStepMap;
    stateOffset = A*stateOffset+Bstep*relativeInputStepOffset;
    rows = (r-1)*m+(1:m);
    FAxis(rows,:) = Cposition*stateMap;
    rAxis(rows,:) = Cposition*stateOffset;
end

% Exact affine dynamics while all receiver memories are held and the leader
% follows the same semi-implicit constant-acceleration sampled dynamics.
% The reachability witness uses the constant-velocity subspace a_L=0.
holdA = eye(nAxis);
holdOffset = zeros(nAxis,3);
holdA(idx.e,:) = positionErrorMap+velocityErrorStepMap+commandStepMap;
holdA(idx.velocityStep,:) = velocityErrorStepMap+commandStepMap;
holdA(idx.e,idx.leaderAccelerationStep) = ...
    holdA(idx.e,idx.leaderAccelerationStep)-1;
holdA(idx.velocityStep,idx.leaderAccelerationStep) = ...
    holdA(idx.velocityStep,idx.leaderAccelerationStep)-1;
holdOffset(idx.e,:) = commandStepOffset;
holdOffset(idx.velocityStep,:) = commandStepOffset;
holdA(idx.leaderPosition,:) = 0;
holdA(idx.leaderPosition,idx.leaderPosition) = 1;
holdA(idx.leaderPosition,idx.leaderVelocityStep) = 1;
holdA(idx.leaderPosition,idx.leaderAccelerationStep) = 1;
holdA(idx.leaderVelocityStep,:) = 0;
holdA(idx.leaderVelocityStep,idx.leaderVelocityStep) = 1;
holdA(idx.leaderVelocityStep,idx.leaderAccelerationStep) = 1;
holdA(idx.leaderAccelerationStep,:) = 0;
holdA(idx.leaderAccelerationStep,idx.leaderAccelerationStep) = 1;

% Consistent-initialization perturbation map. A follower's initial physical
% perturbation is copied into every ordinary receiver memory holding that
% follower, exactly as initQueuedNetworkState does at t=0.
initialConsistencyMap = zeros(nAxis,2*m);
initialConsistencyMap(idx.e,1:m) = eye(m);
initialConsistencyMap(idx.velocityStep,m+(1:m)) = eye(m);
for a = 1:nEdges
    j = edgeSender(a);
    fj = find(followers==j,1);
    if isempty(fj), continue; end
    initialConsistencyMap(idx.ordinaryPosition(a),fj) = 1;
    initialConsistencyMap(idx.ordinaryVelocityStep(a),m+fj) = 1;
end

M.schemaVersion = 1;
M.scope = [ ...
    'Gate-3 fixed symmetric grounded exact-state unsaturated DI model; ' ...
    'O1 frozen-current finite-horizon baseline'];
M.N = N;
M.m = m;
M.h = h;
M.time_s = tk;
M.horizonSamples = horizonSamples;
M.delaySamples = delaySamples;
M.successProbability = successProbability;
M.config.Kp = cfg.swarm.Kp;
M.config.Kv = cfg.swarm.Kv;
M.config.KpLeader = cfg.swarm.KpLeader;
M.config.KvLeader = cfg.swarm.KvLeader;
M.followers = followers;
M.offsets = offsets;
M.edgeReceiver = edgeReceiver;
M.edgeSender = edgeSender;
M.pinReceiver = pinReceiver;
M.nOrdinaryLinks = nEdges;
M.nPinnedLinks = nPins;
M.nAxis = nAxis;
M.nState = 3*nAxis;
M.index = idx;
M.stateNamesAxis = stateNames;
M.initialYMap = initialYMap;
M.communicationStepMap = communicationStepMap;
M.communicationStepOffset = communicationStepOffset;
M.relativeInputStepMap = relativeInputStepMap;
M.relativeInputStepOffset = relativeInputStepOffset;
M.commandStepMap = commandStepMap;
M.commandStepOffset = commandStepOffset;
M.FAxis = FAxis;
M.rAxis = rAxis;
M.F = kron(eye(3),FAxis);
M.r = [rAxis(:,1);rAxis(:,2);rAxis(:,3)];
M.holdA = holdA;
M.holdOffset = holdOffset;
M.holdA3 = kron(eye(3),holdA);
M.holdOffset3 = [holdOffset(:,1);holdOffset(:,2);holdOffset(:,3)];
M.commandStepMap3 = kron(eye(3),commandStepMap);
M.commandStepOffset3 = [commandStepOffset(:,1); ...
    commandStepOffset(:,2);commandStepOffset(:,3)];
M.initialConsistencyMap = initialConsistencyMap;
M.initialConsistencyMap3 = kron(eye(3),initialConsistencyMap);
M.kernel = kernel;
M.certificate = certificate;
M.outputVectorization = [ ...
    'coordinate blocks; within each coordinate, follower vector at k+1, ' ...
    'then follower vector at k+2, through k+H'];

end


function [positionMap,positionOffset,velocityStepMap] = ...
    localSourceMaps(sender,followers,idx,nAxis,offsets)

positionMap = zeros(1,nAxis);
velocityStepMap = zeros(1,nAxis);
if sender==1
    positionMap(idx.leaderPosition) = 1;
    velocityStepMap(idx.leaderVelocityStep) = 1;
    positionOffset = zeros(1,3);
else
    fj = find(followers==sender,1);
    if isempty(fj)
        error('tcnsInformationLimitsModel:Sender', ...
            'An ordinary sender must be the leader or a follower.');
    end
    positionMap(idx.e(fj)) = 1;
    positionMap(idx.leaderPosition) = 1;
    velocityStepMap(idx.velocityStep(fj)) = 1;
    velocityStepMap(idx.leaderVelocityStep) = 1;
    positionOffset = offsets(sender,:);
end

end
