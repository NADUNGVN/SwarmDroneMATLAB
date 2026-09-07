function S = tcnsInformationLimitsState(model,P,V,leader,net)
%TCNSINFORMATIONLIMITSSTATE Pack plant/receiver state into the IL coordinates.

N = model.N;
if ~isequal(size(P),[N 3]) || ~isequal(size(V),[N 3]) || ...
        any(~isfinite(P),'all') || any(~isfinite(V),'all')
    error('tcnsInformationLimitsState:PlantState', ...
        'P and V must be finite N-by-3 matrices.');
end
requiredLeader = {'pos','vel','acc'};
for q = 1:numel(requiredLeader)
    if ~isfield(leader,requiredLeader{q})
        error('tcnsInformationLimitsState:Leader', ...
            'leader.%s is required.',requiredLeader{q});
    end
end
requiredNet = {'Pij','Vij','leaderPos','leaderVel','leaderAcc'};
for q = 1:numel(requiredNet)
    if ~isfield(net,requiredNet{q})
        error('tcnsInformationLimitsState:Network', ...
            'net.%s is required.',requiredNet{q});
    end
end

h = model.h;
idx = model.index;
xiAxis = zeros(model.nAxis,3);
leaderPosition = double(leader.pos(:)');
leaderVelocity = double(leader.vel(:)');
leaderAcceleration = double(leader.acc(:)');
followers = model.followers;
xiAxis(idx.e,:) = P(followers,:)-leaderPosition-model.offsets(followers,:);
xiAxis(idx.velocityStep,:) = h*(V(followers,:)-leaderVelocity);
xiAxis(idx.leaderPosition,:) = leaderPosition;
xiAxis(idx.leaderVelocityStep,:) = h*leaderVelocity;
xiAxis(idx.leaderAccelerationStep,:) = h^2*leaderAcceleration;
for a = 1:model.nOrdinaryLinks
    i = model.edgeReceiver(a);
    j = model.edgeSender(a);
    xiAxis(idx.ordinaryPosition(a),:) = reshape(net.Pij(i,j,:),1,3);
    xiAxis(idx.ordinaryVelocityStep(a),:) = ...
        h*reshape(net.Vij(i,j,:),1,3);
end
for a = 1:model.nPinnedLinks
    i = model.pinReceiver(a);
    xiAxis(idx.pinPosition(a),:) = net.leaderPos(i,:);
    xiAxis(idx.pinVelocityStep(a),:) = h*net.leaderVel(i,:);
    xiAxis(idx.pinAccelerationStep(a),:) = h^2*net.leaderAcc(i,:);
end

S.xiAxis = xiAxis;
S.xi = [xiAxis(:,1);xiAxis(:,2);xiAxis(:,3)];
S.positionError = xiAxis(idx.e,:);
S.velocityError = xiAxis(idx.velocityStep,:)/h;
S.communicationResidual = ...
    (model.communicationStepMap*xiAxis + ...
     model.communicationStepOffset)/h^2;
S.relativeFrozenInput = ...
    (model.relativeInputStepMap*xiAxis + ...
     model.relativeInputStepOffset)/h^2;
S.unsaturatedCommand = ...
    (model.commandStepMap*xiAxis+model.commandStepOffset)/h^2;

end

