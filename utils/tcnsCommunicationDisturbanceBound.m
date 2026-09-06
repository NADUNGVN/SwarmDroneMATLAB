function D = tcnsCommunicationDisturbanceBound(out,cfg)
%TCNSCOMMUNICATIONDISTURBANCEBOUND Map stale-state bounds to control input.
%
%   D = tcnsCommunicationDisturbanceBound(out,cfg)
%
% For each follower and sample, this utility computes both the exact
% pre-saturation stale-minus-perfect-information acceleration d_c and a
% causal receiver-side norm bound beta satisfying ||d_c,i||_2 <= beta_i.
% It combines the Gate-2 follower ZOH envelope, the dedicated analytical
% leader envelope, and the implemented controller gains/topology.
%
% Scope: exact-state double-integrator path with Gate-2 receiver logging.
% This utility diagnoses trajectories; it is not itself a transmit policy.

requiredOut = {'t','P','V','A','LeaderPos','LeaderVel', ...
    'receiverNeighborPosition','receiverNeighborVelocity', ...
    'receiverNeighborGenTime','receiverLeaderPosition', ...
    'receiverLeaderVelocity','receiverLeaderAcceleration', ...
    'receiverLeaderGenTime'};
for q = 1:numel(requiredOut)
    if ~isfield(out,requiredOut{q})
        error('tcnsCommunicationDisturbanceBound:MissingLog', ...
            'out.%s is required.',requiredOut{q});
    end
end

if isfield(cfg,'sixdof') && isfield(cfg.sixdof,'enable') ...
        && cfg.sixdof.enable
    error('tcnsCommunicationDisturbanceBound:SixDofOutOfScope', ...
        'The Gate-3 analytical disturbance identity excludes 6-DOF dynamics.');
end
if isfield(cfg,'estimator') && ~isempty(cfg.estimator)
    error('tcnsCommunicationDisturbanceBound:EstimatorOutOfScope', ...
        'The first Gate-3 identity requires exact local and payload state.');
end

cert = formationTheoryCertificate(cfg);
N = cfg.swarm.N;
m = N-1;
K = numel(out.t);

if size(out.P,1)~=K || size(out.P,2)~=N
    error('tcnsCommunicationDisturbanceBound:Shape', ...
        'Trajectory shape is inconsistent with cfg.swarm.N and out.t.');
end

actual = zeros(K,m,3);
neighborPosition = zeros(K,m);
neighborVelocity = zeros(K,m);
pinPosition = zeros(K,m);
pinVelocity = zeros(K,m);
pinAcceleration = zeros(K,m);

hasCausalSet = isfield(out,'senderSetPositionBound') && ...
    isfield(out,'senderSetVelocityBound') && ...
    isfield(out,'senderLeaderSetPositionBound') && ...
    isfield(out,'senderLeaderSetVelocityBound') && ...
    isfield(out,'senderLeaderSetAccelerationBound');
if hasCausalSet
    causalSetNeighborPosition = zeros(K,m);
    causalSetNeighborVelocity = zeros(K,m);
    causalSetPinPosition = zeros(K,m);
    causalSetPinVelocity = zeros(K,m);
    causalSetPinAcceleration = zeros(K,m);
end

leaderAcceleration = reshape(out.A(:,1,:),K,3);

for fi = 1:m
    i = fi+1;
    scale = cert.degreeScale(fi);
    di = zeros(K,3);

    for j = 1:N
        if cfg.swarm.A(i,j)==0
            continue;
        end

        heldP = reshape(out.receiverNeighborPosition(:,i,j,:),K,3);
        heldV = reshape(out.receiverNeighborVelocity(:,i,j,:),K,3);
        genTime = reshape(out.receiverNeighborGenTime(:,i,j),K,1);

        if j==1
            bound = tcnsLeaderStalenessBound(genTime,out.t);
            trueP = out.LeaderPos;
            trueV = out.LeaderVel;
        else
            physicalAge = out.t-genTime;
            payloadSpeed = vecnorm(heldV,2,2);
            bound = tcnsZohStalenessBound(physicalAge,payloadSpeed, ...
                cfg.swarm.maxAccel,cfg.swarm.dt);
            trueP = reshape(out.P(:,j,:),K,3);
            trueV = reshape(out.V(:,j,:),K,3);
        end

        tildeP = trueP-heldP;
        tildeV = trueV-heldV;
        di = di-cfg.swarm.Kp*scale*tildeP ...
            -cfg.swarm.Kv*scale*tildeV;
        neighborPosition(:,fi) = neighborPosition(:,fi) + ...
            cfg.swarm.Kp*scale*bound.position;
        neighborVelocity(:,fi) = neighborVelocity(:,fi) + ...
            cfg.swarm.Kv*scale*bound.velocity;
        if hasCausalSet
            causalSetNeighborPosition(:,fi) = ...
                causalSetNeighborPosition(:,fi) + cfg.swarm.Kp*scale* ...
                reshape(out.senderSetPositionBound(:,i,j),K,1);
            causalSetNeighborVelocity(:,fi) = ...
                causalSetNeighborVelocity(:,fi) + cfg.swarm.Kv*scale* ...
                reshape(out.senderSetVelocityBound(:,i,j),K,1);
        end
    end

    if cfg.swarm.pin(i)
        heldP = reshape(out.receiverLeaderPosition(:,i,:),K,3);
        heldV = reshape(out.receiverLeaderVelocity(:,i,:),K,3);
        heldA = reshape(out.receiverLeaderAcceleration(:,i,:),K,3);
        genTime = reshape(out.receiverLeaderGenTime(:,i),K,1);
        bound = tcnsLeaderStalenessBound(genTime,out.t);

        tildeP = out.LeaderPos-heldP;
        tildeV = out.LeaderVel-heldV;
        di = di-cfg.swarm.KpLeader*tildeP ...
            -cfg.swarm.KvLeader*tildeV ...
            +(heldA-leaderAcceleration);
        pinPosition(:,fi) = cfg.swarm.KpLeader*bound.position;
        pinVelocity(:,fi) = cfg.swarm.KvLeader*bound.velocity;
        pinAcceleration(:,fi) = bound.acceleration;
        if hasCausalSet
            causalSetPinPosition(:,fi) = cfg.swarm.KpLeader * ...
                reshape(out.senderLeaderSetPositionBound(:,i),K,1);
            causalSetPinVelocity(:,fi) = cfg.swarm.KvLeader * ...
                reshape(out.senderLeaderSetVelocityBound(:,i),K,1);
            causalSetPinAcceleration(:,fi) = ...
                reshape(out.senderLeaderSetAccelerationBound(:,i),K,1);
        end
    end

    actual(:,fi,:) = reshape(di,K,1,3);
end

beta = neighborPosition+neighborVelocity+pinPosition+pinVelocity+ ...
    pinAcceleration;
actualNorm = vecnorm(actual,2,3);

D.actual = actual;
D.actualNorm = actualNorm;
D.bound = beta;
D.neighborPositionBound = neighborPosition;
D.neighborVelocityBound = neighborVelocity;
D.pinPositionBound = pinPosition;
D.pinVelocityBound = pinVelocity;
D.pinAccelerationBound = pinAcceleration;
D.coverage = actualNorm<=beta+1e-10;
D.maxViolation = max(actualNorm-beta,[],1);
D.followers = 2:N;
D.scope = 'exact-state double-integrator, pre-saturation command difference';

if hasCausalSet
    causalSetBeta = causalSetNeighborPosition + ...
        causalSetNeighborVelocity+causalSetPinPosition + ...
        causalSetPinVelocity+causalSetPinAcceleration;
    D.causalSetBound = causalSetBeta;
    D.causalSetCoverage = actualNorm<=causalSetBeta+1e-10;
    D.causalSetMaxViolation = max(actualNorm-causalSetBeta,[],1);
    D.causalSetNeighborPositionBound = causalSetNeighborPosition;
    D.causalSetNeighborVelocityBound = causalSetNeighborVelocity;
    D.causalSetPinPositionBound = causalSetPinPosition;
    D.causalSetPinVelocityBound = causalSetPinVelocity;
    D.causalSetPinAccelerationBound = causalSetPinAcceleration;
end

end
