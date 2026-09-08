function W = tcnsInformationLimitsDynamicWitness( ...
    cfg,horizonSamples,delaySamples,linkClass,receiver,sender)
%TCNSINFORMATIONLIMITSDYNAMICWITNESS Reachable sender-indistinguishable pair.
%
% The witness uses the actual unsaturated formation controller and locked
% semi-implicit DI integrator.  A single leader packet is attempted and
% erased; hence both histories have the same ACK-free belief and receiver
% memory.  Follower initial conditions differ only along a direction that
% is invisible to the leader's complete local history.

if sender~=1
    error('tcnsInformationLimitsDynamicWitness:Sender', ...
        'The preregistered dynamic witness requires leader sender 1.');
end
cfg.sixdof.enable = false;
if isfield(cfg,'tcns') && isfield(cfg.tcns,'diDisturbance')
    cfg.tcns = rmfield(cfg.tcns,'diDisturbance');
end
linkClass = lower(string(linkClass));
h = cfg.swarm.dt;

% The structural action correction is fixed at 0.01 m/s^2 along x.
correctionTarget = 0.01;
dummyPayload.pos = [0 0 0];
dummyPayload.vel = [0 0 0];
if linkClass=="pinned-leader", dummyPayload.acc = [0 0 0]; end
model0 = tcnsInformationLimitsModel(cfg,horizonSamples,delaySamples,0);
dummyAction = tcnsInformationLimitsActionMap( ...
    model0,linkClass,receiver,sender,[correctionTarget 0 0],dummyPayload);
historyLength = numel(dummyAction.keepIndex)-1;
duration = historyLength*h;
fi = find(model0.followers==receiver,1);
if linkClass=="ordinary"
    velocityX = correctionTarget/( ...
        cfg.swarm.Kp*model0.certificate.degreeScale(fi)*duration);
else
    velocityX = correctionTarget/(cfg.swarm.KpLeader*duration);
end
leaderVelocity = [velocityX 0 0];

leader0 = localLeader(0,leaderVelocity);
P0 = leader0.pos'+cfg.swarm.offsets;
V0 = repmat(leaderVelocity,cfg.swarm.N,1);
net0 = initQueuedNetworkState(P0,V0,leader0,cfg);
model = tcnsInformationLimitsModel( ...
    cfg,horizonSamples,delaySamples,duration);
state0 = tcnsInformationLimitsState(model,P0,V0,leader0,net0);

initialPayload = localPayload(0,0,leader0);
sentLeader = localLeader(h,leaderVelocity);
sentHistory = localPayload(1,h,sentLeader);
belief = tcnsAckFreeReceiverBelief( ...
    initialPayload,sentHistory,duration,duration,cfg);
source = localSource(localLeader(duration,leaderVelocity));
expectedAction = tcnsInformationLimitsExpectedActionMap( ...
    model,linkClass,receiver,sender,source,belief);
actualMemoryAction = expectedAction.candidateMaps{1};
keep = expectedAction.keepIndex;
Ared = model.holdA3(keep,keep);
ared = model.holdOffset3(keep)+ ...
    model.holdA3(keep,actualMemoryAction.targetIndex)* ...
    actualMemoryAction.targetValue;
J = model.initialConsistencyMap3(keep,:);

Apower = Ared^historyLength;
hiddenGradient = J'*Apower'*expectedAction.expectedValueCoefficient;
gradientNorm = norm(hiddenGradient,2);
if gradientNorm<=1e-14
    error('tcnsInformationLimitsDynamicWitness:NoHiddenDirection', ...
        'The frozen link has no value-sensitive consistent hidden direction.');
end
direction = hiddenGradient/gradientNorm;

xNominal = state0.xi(keep);
for k = 1:historyLength
    xNominal = Ared*xNominal+ared;
end
qNominal = expectedAction.expectedValueCoefficient'*xNominal+ ...
    expectedAction.expectedValueConstant;
baseShift = -qNominal/gradientNorm;
epsilon = 1e-4;
uMinus = (baseShift-epsilon)*direction;
uPlus = (baseShift+epsilon)*direction;

minus = localRun(cfg,model,expectedAction,uMinus, ...
    leaderVelocity,historyLength);
plus = localRun(cfg,model,expectedAction,uPlus, ...
    leaderVelocity,historyLength);

senderMap = tcnsInformationLimitsSenderMap( ...
    model,sender,actualMemoryAction,historyLength);
hiddenObservationResidual = norm( ...
    senderMap.historyMap*J*direction,2);
expectedSeparation = 2*epsilon*gradientNorm;
observedSeparation = plus.expectedValue-minus.expectedValue;

W.linkClass = linkClass;
W.receiver = receiver;
W.sender = sender;
W.historyLength = historyLength;
W.duration_s = duration;
W.leaderVelocity_mps = leaderVelocity;
W.correctionTarget_mps2 = correctionTarget;
W.belief = belief;
W.expectedAction = expectedAction;
W.initialHiddenDirection = direction;
W.initialBaseShift = baseShift;
W.initialSignHalfSeparation = epsilon;
W.hiddenGradientNorm = gradientNorm;
W.senderHistoryNullResidual = hiddenObservationResidual;
W.minus = minus;
W.plus = plus;
W.senderObservationDifference = norm( ...
    plus.senderObservation-minus.senderObservation,inf);
W.sentPayloadDifference = norm( ...
    plus.sentPayload-sentHistory.pos,inf)+norm( ...
    minus.sentPayload-sentHistory.pos,inf);
W.actionResponseDifference = localResponseDifference( ...
    plus.candidateResponse,minus.candidateResponse);
W.expectedValueSeparationResidual = abs( ...
    observedSeparation-expectedSeparation);
W.oppositeExpectedValueSigns = ...
    plus.expectedValue>0 && minus.expectedValue<0;
W.oppositeActualReceiverValueSigns = ...
    plus.candidateValue(1)>0 && minus.candidateValue(1)<0;
W.oppositeEveryCandidateValueSigns = ...
    all(plus.candidateValue>0) && all(minus.candidateValue<0);
W.oppositeValueSigns = W.oppositeExpectedValueSigns && ...
    W.oppositeActualReceiverValueSigns && ...
    W.oppositeEveryCandidateValueSigns;
W.unsaturated = plus.maxUnsaturatedCommand<cfg.swarm.maxAccel && ...
    minus.maxUnsaturatedCommand<cfg.swarm.maxAccel;
W.affineTrajectoryResidual = max( ...
    plus.affineTrajectoryResidual,minus.affineTrajectoryResidual);
W.trueReceiverStateInBeliefSupport = belief.probability(1)>0;
W.allAttemptsErasedProbability = cfg.net.packetLoss;
W.dynamicallyReachable = W.oppositeValueSigns && W.unsaturated && ...
    W.senderObservationDifference<=1e-10 && ...
    W.actionResponseDifference<=1e-10 && ...
    W.affineTrajectoryResidual<=1e-10 && ...
    hiddenObservationResidual<=1e-10 && ...
    W.trueReceiverStateInBeliefSupport;

end


function R = localRun(cfg,model,expectedAction,u,leaderVelocity,L)

h = cfg.swarm.dt;
m = model.m;
delta = model.initialConsistencyMap3*u;
deltaAxis = reshape(delta,model.nAxis,3);
leader0 = localLeader(0,leaderVelocity);
P = leader0.pos'+cfg.swarm.offsets;
V = repmat(leaderVelocity,cfg.swarm.N,1);
P(model.followers,:) = P(model.followers,:)+ ...
    deltaAxis(model.index.e,:);
V(model.followers,:) = V(model.followers,:)+ ...
    deltaAxis(model.index.velocityStep,:)/h;
net = initQueuedNetworkState(P,V,leader0,cfg);
initialState = tcnsInformationLimitsState(model,P,V,leader0,net);
predicted = initialState.xi;
senderObservation = zeros(0,1);
maxCommand = 0;
time = (0:L)'*h;
formationErrorNorm = zeros(L+1,1);
senderPosition = zeros(L+1,3);
senderVelocity = zeros(L+1,3);

for k = 0:L
    tk = k*h;
    leader = localLeader(tk,leaderVelocity);
    P(1,:) = leader.pos';
    V(1,:) = leader.vel';
    state = tcnsInformationLimitsState(model,P,V,leader,net);
    formationErrorNorm(k+1) = norm(state.positionError,'fro');
    senderPosition(k+1,:) = P(1,:);
    senderVelocity(k+1,:) = V(1,:);
    if k==L
        break;
    end
    senderObservation = [senderObservation; ... %#ok<AGROW>
        leader.pos;h*leader.vel;h^2*leader.acc;h^2*leader.acc];
    maxCommand = max(maxCommand,max(vecnorm(state.unsaturatedCommand,2,2)));
    command = distributedFormationPolicy(P,V,leader,cfg,net);
    [P,V,~] = integrateFollowers(P,V,command,[],cfg,tk);
    predicted = model.holdA3*predicted+model.holdOffset3;
end
senderObservation = [senderObservation; ...
    leader.pos;h*leader.vel;h^2*leader.acc;h^2*leader.acc];
maxCommand = max(maxCommand,max(vecnorm(state.unsaturatedCommand,2,2)));

x = state.xi(expectedAction.keepIndex);
candidateValue = zeros(numel(expectedAction.probability),1);
candidateResponse = cell(numel(candidateValue),1);
for s = 1:numel(candidateValue)
    map = expectedAction.candidateMaps{s};
    candidateValue(s) = map.valueCoefficient'*x+map.valueConstant;
    candidateResponse{s} = map.actionResponse;
end
expectedValueDirect = expectedAction.probability'*candidateValue;
expectedValueAffine = expectedAction.expectedValueCoefficient'*x+ ...
    expectedAction.expectedValueConstant;

R.expectedValue = expectedValueDirect;
R.expectedValueAffineResidual = abs(expectedValueDirect-expectedValueAffine);
R.candidateValue = candidateValue;
R.candidateResponse = candidateResponse;
R.senderObservation = senderObservation;
R.sentPayload = localLeader(h,leaderVelocity).pos';
R.maxUnsaturatedCommand = maxCommand;
R.saturationMargin = cfg.swarm.maxAccel-maxCommand;
R.finalState = state.xi;
R.affineTrajectoryResidual = norm(state.xi-predicted,inf);
R.initialState = initialState.xi;
R.followerInitialPerturbationNorm = norm(u,2);
R.followerCount = m;
R.time_s = time;
R.formationErrorNorm = formationErrorNorm;
R.senderPosition = senderPosition;
R.senderVelocity = senderVelocity;

end


function leader = localLeader(t,velocity)
leader.pos = (t*velocity)';
leader.vel = velocity(:);
leader.acc = zeros(3,1);
end


function payload = localPayload(seq,time,leader)
payload.seq = seq;
payload.sendTime = time;
payload.genTime = time;
payload.pos = leader.pos';
payload.vel = leader.vel';
payload.acc = leader.acc';
end


function source = localSource(leader)
source.pos = leader.pos';
source.vel = leader.vel';
source.acc = leader.acc';
end


function value = localResponseDifference(a,b)
value = 0;
for q = 1:numel(a)
    value = max(value,norm(a{q}-b{q},inf));
end
end
