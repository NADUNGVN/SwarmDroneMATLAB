function R = tcnsInformationLimitsReplayWitness(cfg,horizonSamples, ...
    delaySamples,linkClass,receiver,sender,initialCoordinate, ...
    leaderVelocity,historyLength)
%TCNSINFORMATIONLIMITSREPLAYWITNESS Independently replay a persisted witness.
%
% The input initialCoordinate is the consistent-initialization coordinate
% saved by the R2 witness artifact.  This routine reconstructs plant and
% receiver memories, advances the implemented controller/integrator, builds
% the actual candidate action from the terminal controller residual, and
% evaluates it with the independent centralized current-state oracle.

cfg.sixdof.enable = false;
if isfield(cfg,'tcns') && isfield(cfg.tcns,'diDisturbance')
    cfg.tcns = rmfield(cfg.tcns,'diDisturbance');
end
cfg.net.delay = delaySamples*cfg.swarm.dt;
cfg.net.jitterStd = 0;

duration = historyLength*cfg.swarm.dt;
model = tcnsInformationLimitsModel( ...
    cfg,horizonSamples,delaySamples,duration);
u = double(initialCoordinate(:));
leaderVelocity = reshape(double(leaderVelocity),1,3);
if numel(u)~=size(model.initialConsistencyMap3,2)
    error('tcnsInformationLimitsReplayWitness:CoordinateDimension', ...
        'initialCoordinate has %d entries; expected %d.', ...
        numel(u),size(model.initialConsistencyMap3,2));
end

h = cfg.swarm.dt;
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
state = tcnsInformationLimitsState(model,P,V,leader0,net);
predicted = state.xi;
senderMap = tcnsInformationLimitsSenderMap(model,sender,[],0);
senderObservation = zeros( ...
    (historyLength+1)*size(senderMap.currentMap,1),1);
maxUnsaturatedCommand = 0;

for k = 0:historyLength
    tk = k*h;
    leader = localLeader(tk,leaderVelocity);
    P(1,:) = leader.pos';
    V(1,:) = leader.vel';
    state = tcnsInformationLimitsState(model,P,V,leader,net);
    rows = k*size(senderMap.currentMap,1)+ ...
        (1:size(senderMap.currentMap,1));
    senderObservation(rows) = senderMap.currentMap*state.xi+ ...
        senderMap.currentOffset;
    maxUnsaturatedCommand = max(maxUnsaturatedCommand, ...
        max(vecnorm(state.unsaturatedCommand,2,2)));
    if k==historyLength
        break;
    end
    command = distributedFormationPolicy(P,V,leader,cfg,net);
    [P,V,~] = integrateFollowers(P,V,command,[],cfg,tk);
    predicted = model.holdA3*predicted+model.holdOffset3;
end

[correction,payload] = localActualPayload( ...
    model,linkClass,receiver,sender,P,V,leader,net);
action = tcnsInformationLimitsActionMap( ...
    model,linkClass,receiver,sender,correction,payload);
affineValue = action.valueCoefficient'*state.xi(action.keepIndex)+ ...
    action.valueConstant;
oracle = tcnsCentralizedStateOracleValue( ...
    P,V,leader,net,historyLength*h,cfg,horizonSamples);
if lower(string(linkClass))=="ordinary"
    oracleValue = oracle.ordinaryValue(receiver,sender);
    oracleResponse = localVectorizeResponse( ...
        oracle.ordinaryActionResponse{receiver,sender});
else
    oracleValue = oracle.leaderValue(receiver);
    oracleResponse = localVectorizeResponse( ...
        oracle.leaderActionResponse{receiver});
end

R.initialCoordinate = u;
R.finalP = P;
R.finalV = V;
R.finalLeader = leader;
R.finalNet = net;
R.finalState = state.xi;
R.senderObservation = senderObservation;
R.commandCorrection = correction;
R.candidatePayload = payload;
R.actionMap = action;
R.actionResponse = action.actionResponse;
R.oracleActionResponse = oracleResponse;
R.oracleValue = oracleValue;
R.affineValue = affineValue;
R.oracleValueResidual = abs(oracleValue-affineValue);
R.oracleResponseResidual = norm( ...
    oracleResponse-action.actionResponse,inf);
R.affineTrajectoryResidual = norm(state.xi-predicted,inf);
R.maxUnsaturatedCommand = maxUnsaturatedCommand;
R.saturationMargin = cfg.swarm.maxAccel-maxUnsaturatedCommand;
R.controllerUnsaturated = R.saturationMargin>0;
R.linkClass = lower(string(linkClass));
R.receiver = receiver;
R.sender = sender;
R.horizonSamples = horizonSamples;
R.delaySamples = delaySamples;
R.historyLength = historyLength;

end


function [correction,payload] = localActualPayload( ...
    model,linkClass,receiver,sender,P,V,leader,net)

fi = find(model.followers==receiver,1);
if lower(string(linkClass))=="ordinary"
    heldP = reshape(net.Pij(receiver,sender,:),1,3);
    heldV = reshape(net.Vij(receiver,sender,:),1,3);
    scale = model.certificate.degreeScale(fi);
    correction = model.config.Kp*scale*(P(sender,:)-heldP)+ ...
        model.config.Kv*scale*(V(sender,:)-heldV);
    payload.pos = heldP;
    payload.vel = heldV;
else
    heldP = net.leaderPos(receiver,:);
    heldV = net.leaderVel(receiver,:);
    heldA = net.leaderAcc(receiver,:);
    correction = model.config.KpLeader*(leader.pos'-heldP)+ ...
        model.config.KvLeader*(leader.vel'-heldV)+(leader.acc'-heldA);
    payload.pos = heldP;
    payload.vel = heldV;
    payload.acc = heldA;
end

end


function leader = localLeader(t,velocity)

leader.pos = (t*velocity)';
leader.vel = velocity(:);
leader.acc = zeros(3,1);

end


function value = localVectorizeResponse(response)

value = [];
for axis = 1:3
    value = [value;reshape(response(:,:,axis).',[],1)]; %#ok<AGROW>
end

end
