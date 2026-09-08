function A = tcnsInformationLimitsActualWitnessAudit(cfg,horizonSamples,delaySamples,options)
%TCNSINFORMATIONLIMITSACTUALWITNESSAUDIT Audit every actual N=5 action.
%
% The construction searches the consistent-initialization subspace for a
% dynamically reachable perturbation that is invisible to the sender's
% complete held-memory history, preserves the actual action response, and
% crosses the exact centralized communication-value sign.  Every catalog
% action produces one output row, including failures.

if nargin<4, options = struct(); end
options = localOptions(options);
cfg = localScopeConfiguration(cfg,delaySamples);
model0 = tcnsInformationLimitsModel(cfg,horizonSamples,delaySamples,0);
catalog = tcnsInformationLimitsActionCatalog(model0);
rows = repmat(localRowTemplate(),height(catalog),1);
details = cell(height(catalog),1);

for a = 1:height(catalog)
    row = localRowTemplate();
    row.actionId = catalog.actionId(a);
    row.linkClass = catalog.linkClass(a);
    row.sender = catalog.sender(a);
    row.receiver = catalog.receiver(a);
    row.structuralNonidentifiable = localStructuralNonidentifiability( ...
        model0,catalog.actionMap{a});
    try
        [row,details{a}] = localOneAction(cfg,horizonSamples, ...
            delaySamples,catalog(a,:),a,row,options);
    catch exception
        row.failureReason = "NUMERICAL_FAILURE";
        row.failureDetail = string(exception.identifier)+": "+ ...
            string(exception.message);
        details{a} = struct('exceptionIdentifier',exception.identifier, ...
            'exceptionMessage',exception.message);
    end
    rows(a) = row;
end

A.schemaVersion = 1;
A.studyClass = "NEW_TCNS_R2_ACTUAL_ACTION_WITNESS_AUDIT";
A.options = options;
A.horizonSamples = horizonSamples;
A.delaySamples = delaySamples;
A.actionCatalog = catalog(:,1:5);
A.witnessTable = struct2table(rows);
A.details = details;
A.actionCount = height(catalog);
A.structuralNonidentifiableCount = nnz( ...
    A.witnessTable.structuralNonidentifiable);
A.actualResponseTestedCount = nnz(A.witnessTable.actualResponseTested);
A.reachableWitnessCount = nnz(A.witnessTable.reachableWitnessFound);
A.noSchedulerImplemented = true;
A.noHeldOutSeedsUsed = true;

end


function options = localOptions(options)

defaults.correctionTarget_mps2 = 0.01;
defaults.initialSignHalfSeparation = 1e-4;
defaults.informationTolerance = 1e-9;
defaults.reachabilityTolerance = 1e-9;
defaults.responseTolerance = 1e-9;
defaults.oracleTolerance = 1e-9;
defaults.signTolerance = 1e-12;
defaults.saturationMarginTolerance = 1e-6;
defaults.nullRelativeTolerance = 1e-10;
defaults.referenceSeed = 27022001;
defaults.referenceCount = 32;
defaults.referencePositionRadius_m = 0.05;
defaults.referenceVelocityRadius_mps = 0.05;
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(options,names{k}) || isempty(options.(names{k}))
        options.(names{k}) = defaults.(names{k});
    end
end

end


function cfg = localScopeConfiguration(cfg,delaySamples)

cfg.sixdof.enable = false;
if isfield(cfg,'tcns') && isfield(cfg.tcns,'diDisturbance')
    cfg.tcns = rmfield(cfg.tcns,'diDisturbance');
end
cfg.net.delay = delaySamples*cfg.swarm.dt;
cfg.net.jitterStd = 0;

end


function value = localStructuralNonidentifiability(model,action)

historyLength = numel(action.keepIndex)-1;
senderMap = tcnsInformationLimitsSenderMap( ...
    model,action.sender,action,historyLength);
ell = (senderMap.reducedDynamics^historyLength)'* ...
    action.crossTermCoefficient;
value = ~tcnsLinearIdentifiability(senderMap.historyMap,ell).identifiable;

end


function [row,detail] = localOneAction(cfg,H,D,catalogRow,actionIndex,row,options)

linkClass = catalogRow.linkClass;
sender = catalogRow.sender;
receiver = catalogRow.receiver;
dummyAction = catalogRow.actionMap{1};
historyLength = numel(dummyAction.keepIndex)-1;
duration = historyLength*cfg.swarm.dt;
model = tcnsInformationLimitsModel(cfg,H,D,duration);
J = model.initialConsistencyMap3;

[uBase,leaderVelocity,baseMode,baseTransfer] = localBaseExcitation( ...
    model,linkClass,receiver,sender,historyLength,options);
baseRun = localReplay(cfg,model,linkClass,receiver,sender, ...
    uBase,leaderVelocity,historyLength,H);
baseAction = baseRun.actionMap;
row.actualResponseTested = true;
row.historyLength = historyLength;
row.duration_s = duration;
row.baseExcitationMode = baseMode;
row.baseCorrectionTransfer = baseTransfer;
row.actualCorrectionNorm = norm(baseRun.commandCorrection,2);

senderMap = tcnsInformationLimitsSenderMap(model,sender,[],historyLength);
targetSelector = zeros(numel(baseAction.targetIndex),model.nState);
for q = 1:numel(baseAction.targetIndex)
    targetSelector(q,baseAction.targetIndex(q)) = 1;
end
correctionMap = localCorrectionMap(model,linkClass,receiver,sender);
finalPerturbationMap = model.holdA3^historyLength*J;
constraintMap = [senderMap.historyMap*J; ...
    targetSelector*J;correctionMap*finalPerturbationMap];
nullBasis = localNullBasis(constraintMap,options.nullRelativeTolerance);
row.constraintRank = size(J,2)-size(nullBasis,2);
row.constraintNullity = size(nullBasis,2);
if isempty(nullBasis)
    row.failureReason = "NO_NULL_DIRECTION";
    row.failureDetail = "The complete initial-coordinate constraint has zero nullity.";
    detail = localDetail(baseRun,constraintMap,nullBasis,[],[],[]);
    return;
end

fullValueCoefficient = -2*baseAction.successProbability/model.m* ...
    baseAction.fullCrossTermCoefficient;
initialGradient = finalPerturbationMap'*fullValueCoefficient;
hiddenGradient = nullBasis' * initialGradient;
hiddenNorm = norm(hiddenGradient,2);
row.hiddenGradientNorm = hiddenNorm;
if hiddenNorm<=1e-14*max(1,norm(initialGradient,2))
    row.failureReason = "NO_NULL_DIRECTION";
    row.failureDetail = ...
        "No value-sensitive direction remains after actual-response constraints.";
    detail = localDetail(baseRun,constraintMap,nullBasis,[],[],initialGradient);
    return;
end
direction = nullBasis*(hiddenGradient/hiddenNorm);
direction = direction/norm(direction,2);
hiddenGain = initialGradient'*direction;
if hiddenGain<0
    direction = -direction;
    hiddenGain = -hiddenGain;
end
row.hiddenValueGain = hiddenGain;
qBase = baseRun.oracleValue;
centerShift = -qBase/hiddenGain;
epsilon = options.initialSignHalfSeparation;
uCenter = uBase+centerShift*direction;
uMinus = uCenter-epsilon*direction;
uPlus = uCenter+epsilon*direction;

minusRun = localReplay(cfg,model,linkClass,receiver,sender, ...
    uMinus,leaderVelocity,historyLength,H);
plusRun = localReplay(cfg,model,linkClass,receiver,sender, ...
    uPlus,leaderVelocity,historyLength,H);
row.qMinus = minusRun.oracleValue;
row.qPlus = plusRun.oracleValue;
row.valueDifference = row.qPlus-row.qMinus;
row.valueMidpoint = (row.qPlus+row.qMinus)/2;
row.informationRadius = (row.qPlus-row.qMinus)/2;
row.senderObservationResidual = norm( ...
    plusRun.senderObservation-minusRun.senderObservation,inf);
row.dynamicReachabilityResidual = max( ...
    minusRun.affineTrajectoryResidual,plusRun.affineTrajectoryResidual);
row.actionResponseResidual = max([ ...
    norm(plusRun.actionResponse-minusRun.actionResponse,inf), ...
    plusRun.oracleResponseResidual,minusRun.oracleResponseResidual]);
row.oracleValueResidual = max( ...
    minusRun.oracleValueResidual,plusRun.oracleValueResidual);
row.saturationMargin = min( ...
    minusRun.saturationMargin,plusRun.saturationMargin);
row.initialPerturbationNormMinus = norm(uMinus,2);
row.initialPerturbationNormPlus = norm(uPlus,2);

if row.dynamicReachabilityResidual>options.reachabilityTolerance
    row.failureReason = "REACHABILITY_INFEASIBLE";
    row.failureDetail = "Direct replay disagrees with held-memory affine dynamics.";
elseif row.saturationMargin<=options.saturationMarginTolerance
    row.failureReason = "SATURATION_VIOLATION";
    row.failureDetail = "One trajectory leaves the declared unsaturated scope.";
elseif row.senderObservationResidual>options.informationTolerance || ...
        row.actionResponseResidual>options.responseTolerance || ...
        row.oracleValueResidual>options.oracleTolerance
    row.failureReason = "NUMERICAL_FAILURE";
    row.failureDetail = ...
        "Independent information/action/oracle replay exceeds tolerance.";
elseif ~(row.qMinus<-options.signTolerance && row.qPlus>options.signTolerance)
    row.failureReason = "NO_SIGN_CROSSING_FOUND";
    row.failureDetail = "The fixed symmetric perturbation does not cross zero.";
else
    row.reachableWitnessFound = true;
    row.failureReason = "NONE";
    row.failureDetail = "";
    practical = localPracticalDiagnostics(cfg,model,linkClass,receiver, ...
        sender,H,historyLength,leaderVelocity,uCenter,direction, ...
        nullBasis,finalPerturbationMap,actionIndex,options);
    row.referenceValidCount = practical.validCount;
    row.referenceMedianAbsValue = practical.medianAbsValue;
    if practical.validCount==0
        row.normalizedAmbiguity = NaN;
        row.practicalDiagnosticStatus = ...
            "NO_UNSATURATED_REFERENCE_STATES";
    elseif practical.medianAbsValue<=eps
        row.normalizedAmbiguity = NaN;
        row.practicalDiagnosticStatus = "ZERO_REFERENCE_VALUE_SCALE";
    else
        row.normalizedAmbiguity = row.informationRadius/ ...
            practical.medianAbsValue;
        row.practicalDiagnosticStatus = "PASS";
    end
    row.compatibleIntervalCrossingFraction = practical.crossingFraction;
    row.localCentralizedSignDisagreementRate = practical.disagreementRate;
    row.randomizedEndpointRegret = localRandomizedRegret( ...
        row.qMinus,row.qPlus);
    row.deterministicEndpointRegret = min(row.qPlus,-row.qMinus);
end

detail = localDetail(baseRun,constraintMap,nullBasis,direction,uCenter, ...
    initialGradient);
detail.minusRun = minusRun;
detail.plusRun = plusRun;
detail.centerShift = centerShift;
detail.uBase = uBase;

end


function [uBase,leaderVelocity,mode,transfer] = localBaseExcitation( ...
    model,linkClass,receiver,sender,L,options)

m = model.m;
uBase = zeros(6*m,1);
leaderVelocity = [0 0 0];
target = options.correctionTarget_mps2;
duration = L*model.h;
fi = find(model.followers==receiver,1);
if sender==1
    if linkClass=="ordinary"
        denominator = model.config.Kp*model.certificate.degreeScale(fi)*duration;
        mode = "leader_constant_velocity";
    else
        denominator = model.config.KpLeader*duration;
        mode = "leader_constant_velocity_pin";
    end
    if abs(denominator)<=eps
        error('tcnsInformationLimitsActualWitnessAudit:BaseTransfer', ...
            'Leader base-excitation transfer is zero.');
    end
    leaderVelocity(1) = target/denominator;
    transfer = denominator;
    return;
end

sourceFollowerIndex = find(model.followers==sender,1);
if isempty(sourceFollowerIndex)
    error('tcnsInformationLimitsActualWitnessAudit:Sender', ...
        'Follower sender is outside the model follower set.');
end
correctionMap = localCorrectionMap(model,linkClass,receiver,sender);
finalMap = correctionMap*model.holdA3^L*model.initialConsistencyMap3;
positionIndex = sourceFollowerIndex;
velocityIndex = m+sourceFollowerIndex;
candidateIndex = [positionIndex velocityIndex];
candidateTransfer = finalMap(1,candidateIndex);
[~,choice] = max(abs(candidateTransfer));
transfer = candidateTransfer(choice);
if abs(transfer)<=1e-14
    error('tcnsInformationLimitsActualWitnessAudit:BaseTransfer', ...
        'Both follower source excitation transfers are numerically zero.');
end
selected = candidateIndex(choice);
uBase(selected) = target/transfer;
if choice==1
    mode = "follower_initial_position";
else
    mode = "follower_initial_scaled_velocity";
end

end


function K = localCorrectionMap(model,linkClass,receiver,sender)

h = model.h;
row = zeros(1,model.nAxis);
fi = find(model.followers==receiver,1);
if linkClass=="ordinary"
    a = find(model.edgeReceiver==receiver & model.edgeSender==sender,1);
    scale = model.certificate.degreeScale(fi);
    if sender==1
        row(model.index.leaderPosition) = row(model.index.leaderPosition)+ ...
            model.config.Kp*scale;
        row(model.index.leaderVelocityStep) = ...
            row(model.index.leaderVelocityStep)+model.config.Kv*scale/h;
    else
        fj = find(model.followers==sender,1);
        row(model.index.e(fj)) = row(model.index.e(fj))+model.config.Kp*scale;
        row(model.index.leaderPosition) = row(model.index.leaderPosition)+ ...
            model.config.Kp*scale;
        row(model.index.velocityStep(fj)) = ...
            row(model.index.velocityStep(fj))+model.config.Kv*scale/h;
        row(model.index.leaderVelocityStep) = ...
            row(model.index.leaderVelocityStep)+model.config.Kv*scale/h;
    end
    row(model.index.ordinaryPosition(a)) = ...
        row(model.index.ordinaryPosition(a))-model.config.Kp*scale;
    row(model.index.ordinaryVelocityStep(a)) = ...
        row(model.index.ordinaryVelocityStep(a))-model.config.Kv*scale/h;
else
    a = find(model.pinReceiver==receiver,1);
    row(model.index.leaderPosition) = model.config.KpLeader;
    row(model.index.pinPosition(a)) = -model.config.KpLeader;
    row(model.index.leaderVelocityStep) = model.config.KvLeader/h;
    row(model.index.pinVelocityStep(a)) = -model.config.KvLeader/h;
    row(model.index.leaderAccelerationStep) = 1/h^2;
    row(model.index.pinAccelerationStep(a)) = -1/h^2;
end
K = kron(eye(3),row);

end


function N = localNullBasis(B,relativeTolerance)

[~,S,V] = svd(B,'econ');
s = diag(S);
if isempty(s), sigma = 0; else, sigma = s(1); end
r = sum(s>relativeTolerance*max(1,sigma));
N = V(:,r+1:end);

end


function R = localReplay(cfg,model,linkClass,receiver,sender,u, ...
    leaderVelocity,L,H)

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
senderObservation = zeros((L+1)*size(senderMap.currentMap,1),1);
maxCommand = 0;

for k = 0:L
    tk = k*h;
    leader = localLeader(tk,leaderVelocity);
    P(1,:) = leader.pos';
    V(1,:) = leader.vel';
    state = tcnsInformationLimitsState(model,P,V,leader,net);
    rows = k*size(senderMap.currentMap,1)+(1:size(senderMap.currentMap,1));
    senderObservation(rows) = senderMap.currentMap*state.xi+ ...
        senderMap.currentOffset;
    maxCommand = max(maxCommand,max(vecnorm(state.unsaturatedCommand,2,2)));
    if k==L, break; end
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
oracle = tcnsCentralizedStateOracleValue(P,V,leader,net,L*h,cfg,H);
if linkClass=="ordinary"
    oracleValue = oracle.ordinaryValue(receiver,sender);
    oracleResponse = localVectorizeResponse( ...
        oracle.ordinaryActionResponse{receiver,sender});
else
    oracleValue = oracle.leaderValue(receiver);
    oracleResponse = localVectorizeResponse(oracle.leaderActionResponse{receiver});
end

R.initialCoordinate = u;
R.finalP = P;
R.finalV = V;
R.finalLeader = leader;
R.finalNet = net;
R.finalState = state.xi;
R.senderObservation = senderObservation;
R.commandCorrection = correction;
R.actionMap = action;
R.actionResponse = action.actionResponse;
R.oracleValue = oracleValue;
R.affineValue = affineValue;
R.oracleValueResidual = abs(oracleValue-affineValue);
R.oracleResponseResidual = norm(oracleResponse-action.actionResponse,inf);
R.affineTrajectoryResidual = norm(state.xi-predicted,inf);
R.maxUnsaturatedCommand = maxCommand;
R.saturationMargin = cfg.swarm.maxAccel-maxCommand;

end


function [correction,payload] = localActualPayload( ...
    model,linkClass,receiver,sender,P,V,leader,net)

fi = find(model.followers==receiver,1);
if linkClass=="ordinary"
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


function P = localPracticalDiagnostics(cfg,model,linkClass,receiver,sender,H,L, ...
    leaderVelocity,uCenter,witnessDirection,nullBasis,finalPerturbationMap, ...
    actionIndex,options)

stream = RandStream('mt19937ar','Seed',options.referenceSeed+actionIndex);
values = nan(options.referenceCount,1);
crossing = false(options.referenceCount,1);
disagreement = false(options.referenceCount,1);
valid = false(options.referenceCount,1);
for q = 1:options.referenceCount
    m = model.m;
    delta = zeros(size(uCenter));
    for axis = 1:3
        block = (axis-1)*2*m;
        positionDirection = randn(stream,m,1);
        velocityDirection = randn(stream,m,1);
        delta(block+(1:m)) = options.referencePositionRadius_m* ...
            positionDirection/max(norm(positionDirection,2),eps);
        delta(block+m+(1:m)) = model.h* ...
            options.referenceVelocityRadius_mps*velocityDirection/ ...
            max(norm(velocityDirection,2),eps);
    end
    u = uCenter+delta;
    center = localReplay(cfg,model,linkClass,receiver,sender, ...
        u,leaderVelocity,L,H);
    fullCoefficient = -2*center.actionMap.successProbability/model.m* ...
        center.actionMap.fullCrossTermCoefficient;
    gradient = finalPerturbationMap'*fullCoefficient;
    hiddenGradient = nullBasis*(nullBasis'*gradient);
    hiddenNorm = norm(hiddenGradient,2);
    if hiddenNorm<=1e-14*max(1,norm(gradient,2))
        direction = witnessDirection;
    else
        direction = hiddenGradient/hiddenNorm;
    end
    minus = localReplay(cfg,model,linkClass,receiver,sender, ...
        u-options.initialSignHalfSeparation*direction,leaderVelocity,L,H);
    plus = localReplay(cfg,model,linkClass,receiver,sender, ...
        u+options.initialSignHalfSeparation*direction,leaderVelocity,L,H);
    if min([center.saturationMargin minus.saturationMargin plus.saturationMargin]) ...
            <=options.saturationMarginTolerance
        continue;
    end
    valid(q) = true;
    values(q) = center.oracleValue;
    crossing(q) = minus.oracleValue<0 && plus.oracleValue>0;
    % For this no-update construction the initial held payload is the
    % sender's known initial packet.  Projecting the fixed-response affine
    % value coefficient onto the row space of the declared sender-history
    % constraint therefore defines an optimistic sender-local sign audit;
    % it is a diagnostic, not an implemented scheduling rule.
    affineConstant = center.oracleValue-gradient'*u;
    localEstimate = affineConstant+(gradient-hiddenGradient)'*u;
    disagreement(q) = localSign(localEstimate)~=localSign(center.oracleValue);
end
validValues = values(valid);
P.validCount = nnz(valid);
if isempty(validValues)
    P.medianAbsValue = NaN;
    P.crossingFraction = NaN;
    P.disagreementRate = NaN;
else
    P.medianAbsValue = median(abs(validValues));
    P.crossingFraction = mean(crossing(valid));
    P.disagreementRate = mean(disagreement(valid));
end

end


function s = localSign(value)
if value>0
    s = 1;
elseif value<0
    s = -1;
else
    s = 0;
end
end


function regret = localRandomizedRegret(qMinus,qPlus)

negativeMagnitude = -qMinus;
regret = qPlus*negativeMagnitude/(qPlus+negativeMagnitude);

end


function detail = localDetail(baseRun,constraintMap,nullBasis,direction, ...
    uCenter,initialGradient)

detail.baseRun = baseRun;
detail.constraintMap = constraintMap;
detail.nullBasis = nullBasis;
detail.direction = direction;
detail.uCenter = uCenter;
detail.initialValueGradient = initialGradient;

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


function row = localRowTemplate()
row = struct('actionId',"",'linkClass',"",'sender',NaN,'receiver',NaN, ...
    'structuralNonidentifiable',false,'actualResponseTested',false, ...
    'reachableWitnessFound',false,'historyLength',NaN,'duration_s',NaN, ...
    'baseExcitationMode',"",'baseCorrectionTransfer',NaN, ...
    'actualCorrectionNorm',NaN,'constraintRank',NaN,'constraintNullity',NaN, ...
    'hiddenGradientNorm',NaN,'hiddenValueGain',NaN,'qMinus',NaN,'qPlus',NaN, ...
    'senderObservationResidual',NaN,'dynamicReachabilityResidual',NaN, ...
    'actionResponseResidual',NaN,'oracleValueResidual',NaN, ...
    'valueDifference',NaN,'valueMidpoint',NaN,'informationRadius',NaN, ...
    'saturationMargin',NaN,'initialPerturbationNormMinus',NaN, ...
    'initialPerturbationNormPlus',NaN,'referenceValidCount',0, ...
    'referenceMedianAbsValue',NaN,'normalizedAmbiguity',NaN, ...
    'practicalDiagnosticStatus',"NOT_RUN", ...
    'compatibleIntervalCrossingFraction',NaN, ...
    'localCentralizedSignDisagreementRate',NaN, ...
    'randomizedEndpointRegret',NaN,'deterministicEndpointRegret',NaN, ...
    'failureReason',"",'failureDetail',"");
end
