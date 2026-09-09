function R = tcnsR27ReplayActionFamily(cfg,horizonSamples,delaySamples, ...
    sender,initialCoordinate,leaderVelocity,historyLength,evaluateOracle)
%TCNSR27REPLAYACTIONFAMILY Replay every action of one sender at one state.
%
% This is a deterministic replay of a persisted consistent-initialization
% coordinate. The physical trajectory is advanced once; every candidate
% communication action is then evaluated at the same terminal plant and
% receiver-memory state. The genuine no-transmission action is prepended.

cfg = localScopeConfiguration(cfg,delaySamples);
if nargin<8 || isempty(evaluateOracle), evaluateOracle = true; end
duration = historyLength*cfg.swarm.dt;
model = tcnsInformationLimitsModel( ...
    cfg,horizonSamples,delaySamples,duration);
u = double(initialCoordinate(:));
leaderVelocity = reshape(double(leaderVelocity),1,3);
if numel(u)~=size(model.initialConsistencyMap3,2)
    error('tcnsR27ReplayActionFamily:CoordinateDimension', ...
        'Initial coordinate has %d entries; expected %d.', ...
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
senderMap0 = tcnsInformationLimitsSenderMap(model,sender,[],0);
senderObservation = zeros( ...
    (historyLength+1)*size(senderMap0.currentMap,1),1);
commandHistory = zeros(historyLength+1,model.m,3);
stateHistory = zeros(model.nState,historyLength+1);
commandMapResidual = 0;

for k = 0:historyLength
    tk = k*h;
    leader = localLeader(tk,leaderVelocity);
    P(1,:) = leader.pos';
    V(1,:) = leader.vel';
    state = tcnsInformationLimitsState(model,P,V,leader,net);
    rows = k*size(senderMap0.currentMap,1)+ ...
        (1:size(senderMap0.currentMap,1));
    senderObservation(rows) = senderMap0.currentMap*state.xi+ ...
        senderMap0.currentOffset;
    commandHistory(k+1,:,:) = state.unsaturatedCommand;
    stateHistory(:,k+1) = state.xi;
    mappedCommand = (model.commandStepMap3*state.xi+ ...
        model.commandStepOffset3)/h^2;
    mappedCommand = reshape(mappedCommand,model.m,3);
    commandMapResidual = max(commandMapResidual,norm( ...
        mappedCommand-state.unsaturatedCommand,inf));
    if k==historyLength
        break;
    end
    command = distributedFormationPolicy(P,V,leader,cfg,net);
    [P,V,~] = integrateFollowers(P,V,command,[],cfg,tk);
    predicted = model.holdA3*predicted+model.holdOffset3;
end

catalog = tcnsInformationLimitsActionCatalog(model);
catalog = catalog(catalog.sender==sender,:);
if isempty(catalog)
    error('tcnsR27ReplayActionFamily:Sender', ...
        'Sender %d has no catalog action.',sender);
end
if evaluateOracle
    oracle = tcnsCentralizedStateOracleValue( ...
        P,V,leader,net,historyLength*h,cfg,horizonSamples);
else
    oracle = [];
end
p = height(catalog);
maps = cell(p,1);
payloads = cell(p,1);
responses = cell(p,1);
oracleResponses = cell(p,1);
corrections = zeros(p,3);
oracleValues = zeros(p,1);
affineValues = zeros(p,1);
oracleValueResiduals = zeros(p,1);
oracleResponseResiduals = zeros(p,1);
for a = 1:p
    linkClass = catalog.linkClass(a);
    receiver = catalog.receiver(a);
    [correction,payload] = localActualPayload( ...
        model,linkClass,receiver,sender,P,V,leader,net);
    action = tcnsInformationLimitsActionMap( ...
        model,linkClass,receiver,sender,correction,payload);
    affineValue = action.valueCoefficient'* ...
        state.xi(action.keepIndex)+action.valueConstant;
    if ~evaluateOracle
        oracleValue = NaN;
        oracleResponse = nan(size(action.actionResponse));
    elseif linkClass=="ordinary"
        oracleValue = oracle.ordinaryValue(receiver,sender);
        oracleResponse = localVectorizeResponse( ...
            oracle.ordinaryActionResponse{receiver,sender});
    else
        oracleValue = oracle.leaderValue(receiver);
        oracleResponse = localVectorizeResponse( ...
            oracle.leaderActionResponse{receiver});
    end
    maps{a} = action;
    payloads{a} = payload;
    responses{a} = action.actionResponse;
    oracleResponses{a} = oracleResponse;
    corrections(a,:) = correction;
    oracleValues(a) = oracleValue;
    affineValues(a) = affineValue;
    oracleValueResiduals(a) = abs(oracleValue-affineValue);
    oracleResponseResiduals(a) = norm( ...
        oracleResponse-action.actionResponse,inf);
end

R.schemaVersion = 1;
R.initialCoordinate = u;
R.sender = sender;
R.horizonSamples = horizonSamples;
R.delaySamples = delaySamples;
R.historyLength = historyLength;
R.model = model;
R.catalog = catalog(:,1:5);
R.actionMaps = maps;
R.candidatePayloads = payloads;
R.actionResponses = responses;
R.oracleActionResponses = oracleResponses;
R.commandCorrections = corrections;
R.oracleValues = oracleValues;
R.affineValues = affineValues;
R.qAugmented = [0;oracleValues];
R.affineQAugmented = [0;affineValues];
R.oracleValueResiduals = oracleValueResiduals;
R.oracleResponseResiduals = oracleResponseResiduals;
R.finalP = P;
R.finalV = V;
R.finalLeader = leader;
R.finalNet = net;
R.finalState = state.xi;
R.senderObservation = senderObservation;
R.commandHistory = commandHistory;
R.stateHistory = stateHistory;
R.commandMapResidual = commandMapResidual;
R.affineTrajectoryResidual = norm(state.xi-predicted,inf);
R.saturationMargin = cfg.swarm.maxAccel- ...
    max(vecnorm(reshape(commandHistory,[],3),2,2));
R.maxAccel = cfg.swarm.maxAccel;
R.controllerUnsaturated = R.saturationMargin>0;
R.oracleEvaluated = logical(evaluateOracle);

end


function cfg = localScopeConfiguration(cfg,delaySamples)

cfg.sixdof.enable = false;
if isfield(cfg,'tcns') && isfield(cfg.tcns,'diDisturbance')
    cfg.tcns = rmfield(cfg.tcns,'diDisturbance');
end
cfg.net.delay = delaySamples*cfg.swarm.dt;
cfg.net.jitterStd = 0;

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
