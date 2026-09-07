function out = simSwarmCentralizedStateOracle(cfg)
%SIMSWARMCENTRALIZEDSTATEORACLE Privileged online O1 diagnostic scheduler.
%
% O1 reads current plant and receiver-held state, but never future channel
% outcomes, disturbances, formation changes or trajectories. Each active
% directed payload link is tested by q_ij > lambda. A deterministic waiting
% interval equal to sampled forward delay prevents a second attempt before
% the outcome of the first can be present in current receiver truth.

required = {'lambda','horizonSamples'};
if ~isfield(cfg,'centralizedStateOracle')
    error('simSwarmCentralizedStateOracle:Config', ...
        'cfg.centralizedStateOracle is required.');
end
for q = 1:numel(required)
    if ~isfield(cfg.centralizedStateOracle,required{q})
        error('simSwarmCentralizedStateOracle:Config', ...
            'cfg.centralizedStateOracle.%s is required.',required{q});
    end
end
validateattributes(cfg.centralizedStateOracle.lambda,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'lambda');
validateattributes(cfg.centralizedStateOracle.horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples');
if isfield(cfg,'sixdof') && isfield(cfg.sixdof,'enable') && ...
        cfg.sixdof.enable
    error('simSwarmCentralizedStateOracle:PlantScope', ...
        'O1 Stage A uses the exact double-integrator theorem model.');
end
if isfield(cfg,'estimator') && ~isempty(cfg.estimator)
    error('simSwarmCentralizedStateOracle:EstimatorScope', ...
        'O1 Stage A requires actual current plant state without an estimator.');
end

rng(cfg.net.seed,'twister');
dt = cfg.swarm.dt;
t = (0:dt:cfg.swarm.T)';
K = numel(t);
N = cfg.swarm.N;
P = cfg.swarm.initialPositions;
V = cfg.swarm.initialVelocities;

if ~isfield(cfg.net,'useTrace'), cfg.net.useTrace = false; end
if cfg.net.useTrace
    netTrace = generateNetworkTrace(cfg);
else
    netTrace = [];
end

leader = leaderReference(0);
net = initQueuedNetworkState(P,V,leader,cfg);
np0 = netParamsAt(cfg,0);
delaySamples = max(0,ceil((np0.delay-1e-12)/dt));
observationInterval = max(dt,delaySamples*dt);
oracleModel = struct( ...
    'certificate',tcnsFormationRobustnessCertificate(cfg), ...
    'formationCertificate',formationTheoryCertificate(cfg), ...
    'kernel',tcnsFiniteHorizonLinkValueKernel( ...
        cfg,cfg.centralizedStateOracle.horizonSamples,delaySamples));
lastOrdinaryAttempt = -inf(N,N);
lastLeaderAttempt = -inf(N,1);

Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);
DesiredOffsetsLog = zeros(K,N,3);
DisturbanceAccelerationLog = zeros(K,N,3);
MeanAoILog = zeros(K,1);
TxCountLog = zeros(K,1);
AckCountLog = zeros(K,1);
BroadcastCountLog = zeros(K,1);
OracleSendCountLog = zeros(K,1);
OracleStepMaxValueLog = nan(K,1);
OraclePredictedSaturationFractionLog = zeros(K,1);
ordinaryScheduleCount = zeros(N,N);
leaderScheduleCount = zeros(N,1);

net.broadcastCount = 0;
valueCheckCount = 0;
positiveValueCount = 0;
thresholdSuppressedCount = 0;
observationBlockedCount = 0;
sendCount = 0;
maxValue = -inf;
sumValue = 0;
maxPredictedSaturationFraction = 0;

maxActions = K*(nnz(cfg.swarm.A(2:end,:))+nnz(cfg.swarm.pin(2:end)));
actions = repmat(localActionRow(),maxActions,1);
actionCount = 0;

for k = 1:K
    tk = t(k);
    leader = leaderReference(tk);
    offsetsNow = tcnsFormationOffsetsAt(cfg,tk);
    controlCfg = cfg;
    controlCfg.swarm.offsets = offsetsNow;
    P(1,:) = leader.pos';
    V(1,:) = leader.vel';
    kTrace = traceIndex(cfg,tk,k);

    % Delivery occurs before the oracle reads current receiver truth. The
    % before/after copies are used only to finalize passive action logs.
    netBeforeDelivery = net;
    net = deliverNetworkPackets(net,tk,cfg);
    actions = localResolveActions( ...
        actions,actionCount,netBeforeDelivery,net,P,V,tk);

    value = tcnsCentralizedStateOracleValue( ...
        P,V,leader,net,tk,cfg, ...
        cfg.centralizedStateOracle.horizonSamples,oracleModel);
    maxPredictedSaturationFraction = max( ...
        maxPredictedSaturationFraction,value.predictedSaturationFraction);
    OraclePredictedSaturationFractionLog(k) = ...
        value.predictedSaturationFraction;

    stepMax = -inf;
    ordinarySenderFired = false(N,1);
    leaderPayloadFired = false;
    broadcastBefore = net.broadcastCount;

    for i = 2:N
        for j = 1:N
            if cfg.swarm.A(i,j)==0
                continue;
            end
            qij = value.ordinaryValue(i,j);
            stepMax = max(stepMax,qij);
            maxValue = max(maxValue,qij);
            sumValue = sumValue+qij;
            valueCheckCount = valueCheckCount+1;
            if qij>0, positiveValueCount = positiveValueCount+1; end
            if qij<=cfg.centralizedStateOracle.lambda
                thresholdSuppressedCount = thresholdSuppressedCount+1;
                continue;
            end
            if tk-lastOrdinaryAttempt(i,j)<observationInterval-1e-12
                observationBlockedCount = observationBlockedCount+1;
                continue;
            end

            actionCount = actionCount+1;
            actions(actionCount) = localStartAction( ...
                tk,i,j,'ordinary',value,P(j,:),V(j,:),[]);
            txBefore = net.txCount;
            dropBefore = net.dropCount;
            net = localTransmitLink( ...
                net,P,V,leader,tk,cfg,netTrace,kTrace,i,j,'ordinary');
            actions(actionCount) = localFinishAttempt( ...
                actions(actionCount),net,txBefore,dropBefore,tk,np0.delay);
            lastOrdinaryAttempt(i,j) = tk;
            ordinaryScheduleCount(i,j) = ordinaryScheduleCount(i,j)+1;
            ordinarySenderFired(j) = true;
            sendCount = sendCount+1;
        end

        if cfg.swarm.pin(i)<=0
            continue;
        end
        qiL = value.leaderValue(i);
        stepMax = max(stepMax,qiL);
        maxValue = max(maxValue,qiL);
        sumValue = sumValue+qiL;
        valueCheckCount = valueCheckCount+1;
        if qiL>0, positiveValueCount = positiveValueCount+1; end
        if qiL<=cfg.centralizedStateOracle.lambda
            thresholdSuppressedCount = thresholdSuppressedCount+1;
            continue;
        end
        if tk-lastLeaderAttempt(i)<observationInterval-1e-12
            observationBlockedCount = observationBlockedCount+1;
            continue;
        end

        actionCount = actionCount+1;
        actions(actionCount) = localStartAction( ...
            tk,i,1,'pinned-leader',value,leader.pos',leader.vel',leader.acc');
        txBefore = net.txCount;
        dropBefore = net.dropCount;
        net = localTransmitLink( ...
            net,P,V,leader,tk,cfg,netTrace,kTrace,i,1,'pinned-leader');
        actions(actionCount) = localFinishAttempt( ...
            actions(actionCount),net,txBefore,dropBefore,tk,np0.delay);
        lastLeaderAttempt(i) = tk;
        leaderScheduleCount(i) = leaderScheduleCount(i)+1;
        leaderPayloadFired = true;
        sendCount = sendCount+1;
    end

    % Sparse per-link enqueue calls count one broadcast each. Replace that
    % passive count by the actual unique sender/payload-class count.
    net.broadcastCount = broadcastBefore + ...
        nnz(ordinarySenderFired)+double(leaderPayloadFired);

    % Required only for a zero-delay configuration; inert in Stage A.
    netBeforeDelivery = net;
    net = deliverNetworkPackets(net,tk,cfg);
    actions = localResolveActions( ...
        actions,actionCount,netBeforeDelivery,net,P,V,tk);

    accCmd = distributedFormationPolicy(P,V,leader,controlCfg,net);
    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;
    DesiredOffsetsLog(k,:,:) = reshape(offsetsNow,1,N,3);
    DisturbanceAccelerationLog(k,:,:) = reshape( ...
        tcnsFollowerDisturbanceAt(cfg,tk),1,N,3);
    MeanAoILog(k) = localMeanAoI(net,tk,dt,cfg);
    TxCountLog(k) = net.txCount;
    BroadcastCountLog(k) = net.broadcastCount;
    OracleSendCountLog(k) = sendCount;
    if isfinite(stepMax), OracleStepMaxValueLog(k) = stepMax; end

    if k==K, break; end
    [P,V] = integrateFollowers(P,V,accCmd,[],cfg,tk);
end

actions = actions(1:actionCount);
if isempty(actions)
    actionTable = struct2table(repmat(localActionRow(),0,1));
else
    actionTable = struct2table(actions);
end

out.t = t;
out.P = Plog;
out.V = Vlog;
out.A = Alog;
out.desiredOffsets = DesiredOffsetsLog;
out.appliedFollowerDisturbance = DisturbanceAccelerationLog;
out.meanAoI = MeanAoILog;
out.txCount = net.txCount;
out.txCountLog = TxCountLog;
out.ackCountLog = AckCountLog;
out.broadcastCount = net.broadcastCount;
out.broadcastCountLog = BroadcastCountLog;
out.rxCount = net.rxCount;
out.dropCount = net.dropCount;
out.staleDiscardCount = net.staleDiscardCount;
out.PDR = 1-net.dropCount/max(net.txCount,1);
out.arrivalRatio = net.rxCount/max(net.txCount,1);
out.effectiveUpdateRatio = ...
    (net.rxCount-net.staleDiscardCount)/max(net.txCount,1);
if isempty(netTrace)
    out.traceHash = NaN;
    out.traceHashExact = NaN;
else
    out.traceHash = netTrace.hash;
    out.traceHashExact = netTrace.hashExact;
end
out.ackTraceHash = NaN;
out.ackTraceHashExact = NaN;
out.phaseHash = NaN;
out.six = [];
out.est = [];

out.centralizedStateOracleActive = true;
out.centralizedStateOracleLabel = 'centralized_state_oracle';
out.centralizedStateOracleConfig = cfg.centralizedStateOracle;
out.oracleActions = actionTable;
out.oracleSendCountLog = OracleSendCountLog;
out.oracleStepMaxValueLog = OracleStepMaxValueLog;
out.oraclePredictedSaturationFractionLog = ...
    OraclePredictedSaturationFractionLog;
out.oracleValueCheckCount = valueCheckCount;
out.oraclePositiveValueCount = positiveValueCount;
out.oracleThresholdSuppressedCount = thresholdSuppressedCount;
out.oracleObservationBlockedCount = observationBlockedCount;
out.oracleSendCount = sendCount;
out.oracleMeanValue = sumValue/max(valueCheckCount,1);
out.oracleMaxValue = maxValue;
out.oracleUsefulDeliveryCount = nnz(actionTable.accepted);
out.oracleFailedTransmissionCount = nnz(actionTable.dropped);
out.oracleNoInformationAttemptCount = ...
    height(actionTable)-nnz(actionTable.accepted);
out.oracleOrdinaryScheduleCount = ordinaryScheduleCount;
out.oracleLeaderScheduleCount = leaderScheduleCount;
out.oracleMaxPredictedSaturationFraction = ...
    maxPredictedSaturationFraction;
out.onlineNonanticipative = true;
out.usesFutureChannelOutcome = false;
out.usesFutureDisturbance = false;
out.usesFutureFormationChange = false;
out.usesFutureTrajectory = false;

end


function net = localTransmitLink( ...
    net,P,V,leader,tk,cfg,netTrace,kTrace,i,j,linkClass)

N = cfg.swarm.N;
singleCfg = cfg;
singleCfg.swarm.A = zeros(N);
singleCfg.swarm.pin = zeros(N,1);
fireMask = false(N+1,1);
if strcmp(linkClass,'ordinary')
    singleCfg.swarm.A(i,j) = 1;
    fireMask(j) = true;
else
    singleCfg.swarm.pin(i) = 1;
    fireMask(N+1) = true;
end
net = enqueueNetworkPackets( ...
    net,P,V,leader,tk,singleCfg,netTrace,kTrace,fireMask);

end


function row = localActionRow()

row = struct('time_s',NaN,'receiver',NaN,'sender',NaN, ...
    'linkClass',"",'predictedValue',NaN, ...
    'predictedIsolatedEnergy',NaN,'predictedCrossContribution',NaN, ...
    'positionResidualBefore_m',NaN, ...
    'velocityResidualBefore_mps',NaN,'payloadPosX',NaN, ...
    'payloadPosY',NaN,'payloadPosZ',NaN,'payloadVelX',NaN, ...
    'payloadVelY',NaN,'payloadVelZ',NaN,'attempted',false, ...
    'dropped',false,'arrivalTime_s',NaN,'resolved',false, ...
    'accepted',false,'positionResidualAfter_m',NaN, ...
    'velocityResidualAfter_mps',NaN, ...
    'realizedShortHorizonBranchBenefit',NaN);

end


function row = localStartAction( ...
    tk,i,j,linkClass,value,payloadPos,payloadVel,payloadAcc)

row = localActionRow();
row.time_s = tk;
row.receiver = i;
row.sender = j;
row.linkClass = string(linkClass);
row.payloadPosX = payloadPos(1);
row.payloadPosY = payloadPos(2);
row.payloadPosZ = payloadPos(3);
row.payloadVelX = payloadVel(1);
row.payloadVelY = payloadVel(2);
row.payloadVelZ = payloadVel(3);
if strcmp(linkClass,'ordinary')
    row.predictedValue = value.ordinaryValue(i,j);
    row.predictedIsolatedEnergy = ...
        value.ordinaryIsolatedResponseEnergy(i,j);
    row.predictedCrossContribution = ...
        value.ordinaryCrossContribution(i,j);
    row.positionResidualBefore_m = value.ordinaryPositionResidual(i,j);
    row.velocityResidualBefore_mps = value.ordinaryVelocityResidual(i,j);
else
    row.predictedValue = value.leaderValue(i);
    row.predictedIsolatedEnergy = ...
        value.leaderIsolatedResponseEnergy(i);
    row.predictedCrossContribution = value.leaderCrossContribution(i);
    row.positionResidualBefore_m = value.leaderPositionResidual(i);
    row.velocityResidualBefore_mps = value.leaderVelocityResidual(i);
end
% Acceleration is part of the pinned payload but is not needed to audit the
% requested position/velocity residual contraction.
if ~isempty(payloadAcc) && any(~isfinite(payloadAcc))
    error('simSwarmCentralizedStateOracle:Payload', ...
        'Pinned payload acceleration must be finite.');
end

end


function row = localFinishAttempt(row,net,txBefore,dropBefore,tk,delay)

row.attempted = net.txCount-txBefore==1;
row.dropped = net.dropCount-dropBefore==1;
if ~row.attempted || ~ismember(net.dropCount-dropBefore,[0 1])
    error('simSwarmCentralizedStateOracle:AttemptAccounting', ...
        'Each O1 action must create exactly one DATA attempt.');
end
row.arrivalTime_s = tk+max(delay,0);
if row.dropped
    row.resolved = true;
end

end


function actions = localResolveActions( ...
    actions,actionCount,netBefore,netAfter,P,V,tk)

for q = 1:actionCount
    if actions(q).resolved || actions(q).dropped || ...
            tk<actions(q).arrivalTime_s-1e-12
        continue;
    end
    i = actions(q).receiver;
    j = actions(q).sender;
    payloadP = [actions(q).payloadPosX actions(q).payloadPosY ...
        actions(q).payloadPosZ];
    payloadV = [actions(q).payloadVelX actions(q).payloadVelY ...
        actions(q).payloadVelZ];
    if actions(q).linkClass=="ordinary"
        beforeP = reshape(netBefore.Pij(i,j,:),1,3);
        beforeV = reshape(netBefore.Vij(i,j,:),1,3);
        afterP = reshape(netAfter.Pij(i,j,:),1,3);
        afterV = reshape(netAfter.Vij(i,j,:),1,3);
        acceptedGenTime = netAfter.genTime(i,j);
    else
        beforeP = netBefore.leaderPos(i,:);
        beforeV = netBefore.leaderVel(i,:);
        afterP = netAfter.leaderPos(i,:);
        afterV = netAfter.leaderVel(i,:);
        acceptedGenTime = netAfter.leaderGenTime(i);
    end
    actions(q).positionResidualBefore_m = norm(payloadP-beforeP);
    actions(q).velocityResidualBefore_mps = norm(payloadV-beforeV);
    actions(q).positionResidualAfter_m = norm(payloadP-afterP);
    actions(q).velocityResidualAfter_mps = norm(payloadV-afterV);
    actions(q).accepted = abs(acceptedGenTime-actions(q).time_s)<=1e-12;
    actions(q).resolved = true;
end

% P and V are intentionally accepted by this passive resolver so future
% extensions cannot silently replace payload-relative residuals by current
% sender residuals. They are not read in the present contract.
if isempty(P) || isempty(V)
    error('simSwarmCentralizedStateOracle:ResolverState', ...
        'Current plant state must be available when resolving actions.');
end

end


function value = localMeanAoI(net,tk,dt,cfg)

ages = [];
N = cfg.swarm.N;
for i = 2:N
    for j = 1:N
        if cfg.swarm.A(i,j)>0
            ages(end+1) = tk-net.genTime(i,j)+0.5*dt; %#ok<AGROW>
        end
    end
    if cfg.swarm.pin(i)>0
        ages(end+1) = tk-net.leaderGenTime(i)+0.5*dt; %#ok<AGROW>
    end
end
value = mean(ages);

end
