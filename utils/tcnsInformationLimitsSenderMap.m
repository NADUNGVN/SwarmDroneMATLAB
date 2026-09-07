function O = tcnsInformationLimitsSenderMap( ...
    model,agentId,action,historyLength)
%TCNSINFORMATIONLIMITSSENDERMAP Strongest implemented local information map.
%
% The observation contains the agent's own physical state, all receiver
% memories feeding its controller, and its current unsaturated command.
% For the leader it also contains the full reference state.  Known model
% data and sent-packet records are fixed affine data, not hidden-state rows.

validateattributes(agentId,{'numeric'}, ...
    {'real','finite','integer','scalar','>=',1,'<=',model.N}, ...
    mfilename,'agentId',2);
if nargin<3 || isempty(action)
    keepIndex = (1:model.nState)';
    targetIndex = zeros(0,1);
    targetValue = zeros(0,1);
else
    required = {'keepIndex','targetIndex','targetValue'};
    for q = 1:numel(required)
        if ~isfield(action,required{q})
            error('tcnsInformationLimitsSenderMap:Action', ...
                'action.%s is required.',required{q});
        end
    end
    keepIndex = action.keepIndex(:);
    targetIndex = action.targetIndex(:);
    targetValue = action.targetValue(:);
end
if nargin<4 || isempty(historyLength), historyLength = 0; end
validateattributes(historyLength,{'numeric'}, ...
    {'real','finite','integer','nonnegative','scalar'}, ...
    mfilename,'historyLength',4);

idx = model.index;
C = zeros(0,model.nAxis);
d = zeros(0,3);
labels = strings(0,1);

if agentId==1
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.leaderPosition),zeros(1,3), ...
        "own_position");
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.leaderVelocityStep),zeros(1,3), ...
        "h_own_velocity");
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.leaderAccelerationStep),zeros(1,3), ...
        "h2_own_acceleration");
else
    fi = find(model.followers==agentId,1);
    positionRow = zeros(1,model.nAxis);
    positionRow(idx.e(fi)) = 1;
    positionRow(idx.leaderPosition) = 1;
    [C,d,labels] = localAppend(C,d,labels,positionRow, ...
        model.offsets(agentId,:),"own_position");
    velocityRow = zeros(1,model.nAxis);
    velocityRow(idx.velocityStep(fi)) = 1;
    velocityRow(idx.leaderVelocityStep) = 1;
    [C,d,labels] = localAppend(C,d,labels,velocityRow, ...
        zeros(1,3),"h_own_velocity");
end

incoming = find(model.edgeReceiver==agentId);
for a = reshape(incoming,1,[])
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.ordinaryPosition(a)),zeros(1,3), ...
        sprintf('held_position_from_%d',model.edgeSender(a)));
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.ordinaryVelocityStep(a)),zeros(1,3), ...
        sprintf('h_held_velocity_from_%d',model.edgeSender(a)));
end
pinIndex = find(model.pinReceiver==agentId,1);
if ~isempty(pinIndex)
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.pinPosition(pinIndex)),zeros(1,3), ...
        "held_leader_position");
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.pinVelocityStep(pinIndex)),zeros(1,3), ...
        "h_held_leader_velocity");
    [C,d,labels] = localAppend(C,d,labels, ...
        localUnit(model.nAxis,idx.pinAccelerationStep(pinIndex)), ...
        zeros(1,3),"h2_held_leader_acceleration");
end

if agentId==1
    commandRow = localUnit(model.nAxis,idx.leaderAccelerationStep);
    commandOffset = zeros(1,3);
else
    fi = find(model.followers==agentId,1);
    commandRow = model.commandStepMap(fi,:);
    commandOffset = model.commandStepOffset(fi,:);
end
[C,d,labels] = localAppend(C,d,labels,commandRow,commandOffset, ...
    "h2_unsaturated_command");

C3 = kron(eye(3),C);
d3 = [d(:,1);d(:,2);d(:,3)];
Cred = C3(:,keepIndex);
dred = d3;
if ~isempty(targetIndex)
    dred = dred+C3(:,targetIndex)*targetValue;
end

Ared = model.holdA3(keepIndex,keepIndex);
ared = model.holdOffset3(keepIndex);
if ~isempty(targetIndex)
    ared = ared+model.holdA3(keepIndex,targetIndex)*targetValue;
end
historyMap = zeros((historyLength+1)*size(Cred,1),numel(keepIndex));
historyOffset = zeros((historyLength+1)*size(Cred,1),1);
stateMap = eye(numel(keepIndex));
stateOffset = zeros(numel(keepIndex),1);
for lag = 0:historyLength
    rows = lag*size(Cred,1)+(1:size(Cred,1));
    historyMap(rows,:) = Cred*stateMap;
    historyOffset(rows) = Cred*stateOffset+dred;
    stateMap = Ared*stateMap;
    stateOffset = Ared*stateOffset+ared;
end

O.agentId = agentId;
O.axisObservationMap = C;
O.axisObservationOffset = d;
O.axisLabels = labels;
O.currentMap = Cred;
O.currentOffset = dred;
O.historyLength = historyLength;
O.historyMap = historyMap;
O.historyOffset = historyOffset;
O.reducedDynamics = Ared;
O.reducedDynamicsOffset = ared;
O.keepIndex = keepIndex;
O.includesOwnPhysicalState = true;
O.includesIncomingControllerMemories = true;
O.includesUnsaturatedCommand = true;
O.includesSentPacketHistoryAsFixedData = true;
O.usesRemoteReceiverTruth = false;

end


function row = localUnit(n,index)
row = zeros(1,n);
row(index) = 1;
end


function [C,d,labels] = localAppend(C,d,labels,row,offset,label)
C(end+1,:) = row;
d(end+1,:) = offset;
labels(end+1,1) = string(label);
end
