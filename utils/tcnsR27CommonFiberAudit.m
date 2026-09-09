function A = tcnsR27CommonFiberAudit(r2WorkspacePath,options)
%TCNSR27COMMONFIBERAUDIT Deterministic common-fiber audit of frozen N=5 states.

if nargin<1 || isempty(r2WorkspacePath)
    r2WorkspacePath = fullfile(projectRoot(),'results', ...
        'tcns_r2_generalization_validation','2026-09-08_161130', ...
        'workspace.mat');
end
if nargin<2, options = struct(); end
options = localOptions(options);
S = load(r2WorkspacePath,'cfg','witness');
if ~isfield(S,'cfg') || ~isfield(S,'witness')
    error('tcnsR27CommonFiberAudit:Workspace', ...
        'Frozen workspace must contain cfg and witness.');
end
cfg = S.cfg;
W = S.witness;
if cfg.swarm.N~=5 || W.horizonSamples~=25 || W.delaySamples~=4 || ...
        W.actionCount~=10
    error('tcnsR27CommonFiberAudit:FrozenScope', ...
        'R2.7 accepts only the frozen N=5, H=25, D=4, ten-action workspace.');
end

senders = [1 3 4];
candidateRows = repmat(localCandidateTemplate(),0,1);
dimensionRows = repmat(localDimensionTemplate(),0,1);
argmaxRows = repmat(localArgmaxTemplate(),0,1);
replayRows = repmat(localReplayTemplate(),0,1);
details = cell(W.actionCount,numel(senders));
attempt = 0;

for sourceIndex = 1:W.actionCount
    persisted = W.witnessTable(sourceIndex,:);
    detail = W.details{sourceIndex};
    for senderIndex = 1:numel(senders)
        sender = senders(senderIndex);
        attempt = attempt+1;
        attemptId = sprintf('center_%02d_sender_%d',sourceIndex,sender);
        candidate = localCandidateTemplate();
        candidate.attemptId = string(attemptId);
        candidate.sourceIndex = sourceIndex;
        candidate.sourceActionId = persisted.actionId;
        candidate.sender = sender;
        candidate.H = W.horizonSamples;
        candidate.D = W.delaySamples;
        candidate.N = cfg.swarm.N;
        candidate.graph = "ring2";
        candidate.pinning = "even";
        [sourceEligible,sourceReason] = localSourceEligibility( ...
            persisted,detail);
        candidate.sourceEligible = sourceEligible;
        candidate.exclusionReason = sourceReason;
        if ~sourceEligible
            candidate.outcome = "COMMON_FIBER_NOT_CERTIFIABLE";
            candidateRows(end+1,1) = candidate; %#ok<AGROW>
            arg = localArgmaxTemplate();
            arg.attemptId = candidate.attemptId;
            arg.sender = sender;
            arg.outcome = candidate.outcome;
            arg.failureReason = sourceReason;
            argmaxRows(end+1,1) = arg; %#ok<AGROW>
            continue;
        end

        leaderVelocity = reshape(detail.baseRun.finalLeader.vel,1,3);
        historyLength = persisted.historyLength;
        try
            center = tcnsR27ReplayActionFamily(cfg,W.horizonSamples, ...
                W.delaySamples,sender,detail.uCenter,leaderVelocity, ...
                historyLength);
        catch exception
            candidate.sourceEligible = false;
            candidate.exclusionReason = "CENTER_REPLAY_FAILURE:"+ ...
                string(exception.identifier);
            candidate.outcome = "COMMON_FIBER_NOT_CERTIFIABLE";
            candidateRows(end+1,1) = candidate; %#ok<AGROW>
            arg = localArgmaxTemplate();
            arg.attemptId = candidate.attemptId;
            arg.sender = sender;
            arg.outcome = candidate.outcome;
            arg.failureReason = candidate.exclusionReason;
            argmaxRows(end+1,1) = arg; %#ok<AGROW>
            continue;
        end

        candidate.actionCount = height(center.catalog);
        candidate.augmentedActionCount = candidate.actionCount+1;
        candidate.sourceStateReplayResidual = localFrozenStateResidual( ...
            center,detail);
        candidate.centerReplayPass = center.affineTrajectoryResidual<= ...
            options.reachabilityTolerance && center.saturationMargin> ...
            options.saturationMarginTolerance && ...
            max(center.oracleValueResiduals)<=options.oracleTolerance && ...
            max(center.oracleResponseResiduals)<=options.responseTolerance && ...
            center.commandMapResidual<=options.jacobianTolerance && ...
            candidate.sourceStateReplayResidual<= ...
            options.reachabilityTolerance;
        if ~candidate.centerReplayPass
            candidate.sourceEligible = false;
            candidate.exclusionReason = "CENTER_REPLAY_TOLERANCE_FAILURE";
            candidate.outcome = "COMMON_FIBER_NOT_CERTIFIABLE";
            candidateRows(end+1,1) = candidate; %#ok<AGROW>
            arg = localArgmaxTemplate();
            arg.attemptId = candidate.attemptId;
            arg.sender = sender;
            arg.outcome = candidate.outcome;
            arg.failureReason = candidate.exclusionReason;
            argmaxRows(end+1,1) = arg; %#ok<AGROW>
            continue;
        end

        geometry = localGeometry(cfg,W,center,leaderVelocity,options);
        dimension = localDimensionTemplate();
        dimension.attemptId = candidate.attemptId;
        dimension.sourceIndex = sourceIndex;
        dimension.sourceActionId = persisted.actionId;
        dimension.sender = sender;
        dimension.reachableDimension = geometry.reachableDimension;
        dimension.senderInformationNullity = ...
            geometry.senderInformationNullity;
        dimension.jointResponseDimension = geometry.jointResponseDimension;
        dimension.commonDimension = geometry.commonDimension;
        dimension.branchSemanticDimension = geometry.branchSemanticDimension;
        dimension.senderConstraintRank = geometry.senderConstraintRank;
        dimension.jointResponseConstraintRank = ...
            geometry.jointResponseConstraintRank;
        dimension.jointSemanticConstraintRank = ...
            geometry.jointSemanticConstraintRank;
        dimension.branchRadius = geometry.branchRadius;
        dimension.maximumResponseJacobianResidual = ...
            geometry.maximumResponseJacobianResidual;
        dimension.maximumCommandMapResidual = center.commandMapResidual;
        dimensionRows(end+1,1) = dimension; %#ok<AGROW>

        arg = localArgmaxTemplate();
        arg.attemptId = candidate.attemptId;
        arg.sourceIndex = sourceIndex;
        arg.sourceActionId = persisted.actionId;
        arg.sender = sender;
        arg.actionIds = localActionIds(center);
        arg.centerQ = localVectorString(center.qAugmented);
        arg.commonDimension = geometry.commonDimension;
        arg.branchRadius = geometry.branchRadius;
        arg.relativeValuesVary = geometry.relativeValuesVary;
        arg.maximumAffineOracleMismatch = max(center.oracleValueResiduals);

        replayRows = [replayRows;localReplayRows( ...
            candidate.attemptId,"CENTER",center,center,options)]; %#ok<AGROW>

        if geometry.commonDimension==0
            outcome = "COMMON_FIBER_ZERO_DIMENSION";
            arg.failureReason = "JOINT_EQUALITY_NULLSPACE_ZERO";
            candidate.outcome = outcome;
            arg.outcome = outcome;
            candidateRows(end+1,1) = candidate; %#ok<AGROW>
            argmaxRows(end+1,1) = arg; %#ok<AGROW>
            details{sourceIndex,senderIndex} = struct( ...
                'center',center,'geometry',geometry,'outcome',outcome);
            continue;
        end
        if ~isfinite(geometry.branchRadius) || geometry.branchRadius<=0
            outcome = "COMMON_FIBER_NOT_CERTIFIABLE";
            arg.failureReason = "NO_POSITIVE_FINITE_BRANCH_RADIUS";
            candidate.outcome = outcome;
            arg.outcome = outcome;
            candidateRows(end+1,1) = candidate; %#ok<AGROW>
            argmaxRows(end+1,1) = arg; %#ok<AGROW>
            details{sourceIndex,senderIndex} = struct( ...
                'center',center,'geometry',geometry,'outcome',outcome);
            continue;
        end

        decision = localDecisionSearch(cfg,W,center,geometry, ...
            leaderVelocity,historyLength,options);
        arg.commonActions = localIndexString(decision.commonActions);
        arg.commonWinnerMargins = localVectorString(decision.commonMargins);
        arg.leftQ = localVectorString(decision.leftQ);
        arg.rightQ = localVectorString(decision.rightQ);
        arg.leftArgmax = localIndexString(decision.leftArgmax);
        arg.rightArgmax = localIndexString(decision.rightArgmax);
        arg.argmaxIntersection = localIndexString( ...
            decision.argmaxIntersection);
        arg.leftWinnerMargin = decision.leftWinnerMargin;
        arg.rightWinnerMargin = decision.rightWinnerMargin;
        arg.maximumAffineOracleMismatch = max( ...
            arg.maximumAffineOracleMismatch, ...
            decision.maximumAffineOracleMismatch);
        arg.minimumSaturationMargin = decision.minimumSaturationMargin;
        arg.maximumInformationResidual = decision.maximumInformationResidual;
        arg.maximumJointResponseResidual = ...
            decision.maximumJointResponseResidual;
        arg.maximumDynamicResidual = decision.maximumDynamicResidual;
        arg.failureReason = decision.failureReason;
        arg.outcome = decision.outcome;
        candidate.outcome = decision.outcome;
        candidateRows(end+1,1) = candidate; %#ok<AGROW>
        argmaxRows(end+1,1) = arg; %#ok<AGROW>
        if ~isempty(decision.leftRun)
            replayRows = [replayRows;localReplayRows( ...
                candidate.attemptId,"LEFT",decision.leftRun, ...
                decision.rightRun,options)]; %#ok<AGROW>
            replayRows = [replayRows;localReplayRows( ...
                candidate.attemptId,"RIGHT",decision.rightRun, ...
                decision.leftRun,options)]; %#ok<AGROW>
        end
        details{sourceIndex,senderIndex} = struct('center',center, ...
            'geometry',geometry,'decision',decision, ...
            'outcome',decision.outcome);
    end
end


function residual = localFrozenStateResidual(center,detail)

minus = detail.minusRun;
plus = detail.plusRun;
residual = max([ ...
    norm(center.finalP-(minus.finalP+plus.finalP)/2,inf), ...
    norm(center.finalV-(minus.finalV+plus.finalV)/2,inf), ...
    norm(center.finalState-(minus.finalState+plus.finalState)/2,inf)]);

end

A.schemaVersion = 1;
A.studyClass = "FROZEN_N5_COMMON_MULTI_ACTION_FIBER_REPLAY";
A.sourceWorkspace = string(r2WorkspacePath);
A.options = options;
A.candidateTable = struct2table(candidateRows);
A.dimensionTable = struct2table(dimensionRows);
A.argmaxTable = struct2table(argmaxRows);
A.replayTable = struct2table(replayRows);
A.details = details;
A.noNewTrajectoryGenerated = true;
A.noRandomSearch = true;
A.noNewSeed = true;
A.manuscriptEdited = false;

end


function options = localOptions(options)

defaults.rankRelativeTolerance = 1e-10;
defaults.informationTolerance = 1e-9;
defaults.reachabilityTolerance = 1e-9;
defaults.responseTolerance = 1e-9;
defaults.oracleTolerance = 1e-9;
defaults.saturationMarginTolerance = 1e-6;
defaults.decisionTolerance = 1e-10;
defaults.jacobianTolerance = 1e-9;
defaults.unresolvedMultiplier = 100;
names = fieldnames(defaults);
for q = 1:numel(names)
    if ~isfield(options,names{q}) || isempty(options.(names{q}))
        options.(names{q}) = defaults.(names{q});
    end
end

end


function [eligible,reason] = localSourceEligibility(row,detail)

eligible = row.reachableWitnessFound && row.failureReason=="NONE" && ...
    isstruct(detail) && isfield(detail,'uCenter') && ...
    isfield(detail,'baseRun') && isfield(detail.baseRun,'finalLeader') && ...
    all(isfinite(detail.uCenter)) && isfinite(row.historyLength);
if eligible
    reason = "NONE";
else
    reason = "PERSISTED_SOURCE_INCOMPLETE_OR_FAILED";
end

end


function G = localGeometry(cfg,W,center,leaderVelocity,options)

model = center.model;
J = model.initialConsistencyMap3;
L = center.historyLength;
F0 = model.holdA3^L*J;
senderMap = tcnsInformationLimitsSenderMap( ...
    model,center.sender,[],L);
Cinfo = senderMap.historyMap*J;
responseRows = zeros(0,size(J,2));
semanticRows = zeros(0,size(J,2));
maximumJacobianResidual = 0;
for a = 1:height(center.catalog)
    action = center.actionMaps{a};
    correctionMap = localCorrectionMap(model,action.linkClass, ...
        action.receiver,action.sender);
    responseOperator = localResponseOperator(model,action, ...
        center.candidatePayloads{a});
    responseJacobian = responseOperator*correctionMap*F0;
    responseRows = [responseRows;responseJacobian]; %#ok<AGROW>
    selector = zeros(numel(action.targetIndex),model.nState);
    for q = 1:numel(action.targetIndex)
        selector(q,action.targetIndex(q)) = 1;
    end
    semanticRows = [semanticRows;selector*F0]; %#ok<AGROW>
    analytical = responseOperator*action.commandCorrection(:);
    maximumJacobianResidual = max(maximumJacobianResidual, ...
        norm(analytical-action.actionResponse,inf));
end
Kinfo = localNullBasis(Cinfo,options.rankRelativeTolerance);
Kresponse = localNullBasis([Cinfo;responseRows], ...
    options.rankRelativeTolerance);
Kcommon = localNullBasis([Cinfo;responseRows;semanticRows], ...
    options.rankRelativeTolerance);
reachableDimension = localRank(J,options.rankRelativeTolerance);

gradientU = zeros(height(center.catalog)+1,size(J,2));
for a = 1:height(center.catalog)
    action = center.actionMaps{a};
    fullCoefficient = -2*action.successProbability/model.m* ...
        action.fullCrossTermCoefficient;
    gradientU(a+1,:) = (F0'*fullCoefficient)';
end
gradientK = gradientU*Kcommon;
relativeValuesVary = false;
for a = 1:size(gradientK,1)
    for b = a+1:size(gradientK,1)
        relativeValuesVary = relativeValuesVary || ...
            norm(gradientK(a,:)-gradientK(b,:),2)> ...
            options.rankRelativeTolerance;
    end
end

branchRadius = localBranchRadius(center,J,Kcommon,options);
finiteDifferenceResidual = localResponseFiniteDifferenceResidual( ...
    cfg,W,center,leaderVelocity,Kcommon,responseRows,branchRadius,options);
if isempty(Kcommon)
    branchSemanticDimension = 0;
elseif isfinite(branchRadius) && branchRadius>0
    branchSemanticDimension = size(Kcommon,2);
else
    branchSemanticDimension = 0;
end
G.reachableDimension = reachableDimension;
G.senderInformationNullity = size(Kinfo,2);
G.jointResponseDimension = size(Kresponse,2);
G.commonDimension = size(Kcommon,2);
G.branchSemanticDimension = branchSemanticDimension;
G.senderConstraintRank = localRank(Cinfo,options.rankRelativeTolerance);
G.jointResponseConstraintRank = localRank([Cinfo;responseRows], ...
    options.rankRelativeTolerance);
G.jointSemanticConstraintRank = localRank( ...
    [Cinfo;responseRows;semanticRows],options.rankRelativeTolerance);
G.Kcommon = Kcommon;
G.gradientU = gradientU;
G.gradientK = gradientK;
G.branchRadius = branchRadius;
G.maximumResponseJacobianResidual = max( ...
    maximumJacobianResidual,finiteDifferenceResidual);
G.relativeValuesVary = relativeValuesVary;

end


function residual = localResponseFiniteDifferenceResidual( ...
    cfg,W,center,leaderVelocity,K,responseRows,rho,options)

residual = 0;
if isempty(K) || ~isfinite(rho) || rho<=0
    return;
end
step = min(1,rho/4);
blockStart = zeros(height(center.catalog),1);
blockLength = zeros(height(center.catalog),1);
cursor = 0;
for a = 1:height(center.catalog)
    blockStart(a) = cursor+1;
    blockLength(a) = numel(center.actionResponses{a});
    cursor = cursor+blockLength(a);
end
for j = 1:size(K,2)
    plus = tcnsR27ReplayActionFamily(cfg,W.horizonSamples, ...
        W.delaySamples,center.sender,center.initialCoordinate+step*K(:,j), ...
        leaderVelocity,center.historyLength,false);
    minus = tcnsR27ReplayActionFamily(cfg,W.horizonSamples, ...
        W.delaySamples,center.sender,center.initialCoordinate-step*K(:,j), ...
        leaderVelocity,center.historyLength,false);
    if min(plus.saturationMargin,minus.saturationMargin)<= ...
            options.saturationMarginTolerance
        residual = Inf;
        return;
    end
    for a = 1:height(center.catalog)
        rows = blockStart(a)+(0:blockLength(a)-1);
        observed = (plus.actionResponses{a}- ...
            minus.actionResponses{a})/(2*step);
        predicted = responseRows(rows,:)*K(:,j);
        residual = max(residual,norm(observed-predicted,inf));
    end
end

end


function rho = localBranchRadius(center,J,K,options)

if isempty(K)
    rho = 0;
    return;
end
model = center.model;
m = model.m;
rho = Inf;
for k = 0:center.historyLength
    stateMap = model.holdA3^k*J*K;
    commandMap = model.commandStepMap3*stateMap/model.h^2;
    command = reshape(center.commandHistory(k+1,:,:),m,3);
    for i = 1:m
        rows = [i,m+i,2*m+i];
        available = center.maxAccel- ...
            options.saturationMarginTolerance-norm(command(i,:),2);
        gain = norm(commandMap(rows,:),2);
        if available<=0
            rho = 0;
            return;
        elseif gain>0
            rho = min(rho,available/gain);
        end
    end
end

end


function D = localDecisionSearch(cfg,W,center,geometry,leaderVelocity,L,options)

qCenter = center.qAugmented;
gradients = geometry.gradientK;
pAug = numel(qCenter);
rho = geometry.branchRadius;
lowerMargins = inf(pAug,1);
commonActions = zeros(0,1);
for a = 1:pAug
    competitors = setdiff(1:pAug,a);
    if isempty(competitors)
        lowerMargins(a) = Inf;
    else
        values = zeros(numel(competitors),1);
        for j = 1:numel(competitors)
            b = competitors(j);
            values(j) = qCenter(a)-qCenter(b)-rho*norm( ...
                gradients(a,:)-gradients(b,:),2);
        end
        lowerMargins(a) = min(values);
    end
    if lowerMargins(a)>=-options.decisionTolerance
        commonActions(end+1,1) = a-1; %#ok<AGROW>
    end
end

runs = cell(pAug,1);
argmaxSets = cell(pAug,1);
winnerMargins = nan(pAug,1);
optimizerMargins = nan(pAug,1);
optimizerPass = false(pAug,1);
for a = 1:pAug
    [z,margin,ok] = localMaximizeWinner( ...
        qCenter,gradients,rho,a);
    optimizerMargins(a) = margin;
    if ~ok, continue; end
    run = tcnsR27ReplayActionFamily(cfg,W.horizonSamples, ...
        W.delaySamples,center.sender, ...
        center.initialCoordinate+geometry.Kcommon*z,leaderVelocity,L);
    verdict = tcnsR27ValidateCommonFiber(center,run,options);
    if ~verdict.passCommonFiber, continue; end
    runs{a} = run;
    argmaxSets{a} = verdict.rightArgmax;
    winnerMargins(a) = verdict.rightWinnerMargin;
    optimizerPass(a) = true;
end

left = [];
right = [];
pairVerdict = [];
for a = 1:pAug
    if ~optimizerPass(a), continue; end
    for b = a+1:pAug
        if ~optimizerPass(b), continue; end
        if isempty(intersect(argmaxSets{a},argmaxSets{b},'stable'))
            verdict = tcnsR27ValidateCommonFiber(runs{a},runs{b},options);
            if verdict.passCommonFiber && verdict.disjointArgmax
                left = runs{a};
                right = runs{b};
                pairVerdict = verdict;
                break;
            end
        end
    end
    if ~isempty(left), break; end
end

nearBoundary = any(abs(lowerMargins(isfinite(lowerMargins)))<= ...
    options.unresolvedMultiplier*options.decisionTolerance);
exactFlatTie = all(qCenter==0) && all(gradients==0,'all');
if ~isempty(left)
    outcome = "COMMON_FIBER_ARGMAX_AMBIGUOUS";
    failureReason = "NONE";
elseif ~isempty(commonActions) && (~nearBoundary || exactFlatTie)
    outcome = "COMMON_FIBER_WINNER_CERTIFIED";
    failureReason = "NONE";
    selected = commonActions(1)+1;
    if optimizerPass(selected)
        left = center;
        right = runs{selected};
        pairVerdict = tcnsR27ValidateCommonFiber(left,right,options);
    else
        left = center;
        right = center;
        pairVerdict = tcnsR27ValidateCommonFiber(left,right,options);
    end
elseif nearBoundary
    outcome = "COMMON_FIBER_NOT_CERTIFIABLE";
    failureReason = "NUMERICALLY_UNRESOLVED_MARGIN";
else
    outcome = "COMMON_FIBER_NOT_CERTIFIABLE";
    failureReason = "NO_REPLAYED_DISJOINT_PAIR_OR_COMMON_WINNER";
end

D.outcome = outcome;
D.failureReason = failureReason;
D.commonActions = commonActions;
D.commonMargins = lowerMargins;
D.optimizerMargins = optimizerMargins;
D.optimizerPass = optimizerPass;
D.leftRun = left;
D.rightRun = right;
if isempty(pairVerdict)
    D.leftQ = [];
    D.rightQ = [];
    D.leftArgmax = [];
    D.rightArgmax = [];
    D.argmaxIntersection = [];
    D.leftWinnerMargin = NaN;
    D.rightWinnerMargin = NaN;
    D.maximumAffineOracleMismatch = max(center.oracleValueResiduals);
    D.minimumSaturationMargin = center.saturationMargin;
    D.maximumInformationResidual = NaN;
    D.maximumJointResponseResidual = NaN;
    D.maximumDynamicResidual = center.affineTrajectoryResidual;
else
    D.leftQ = left.qAugmented;
    D.rightQ = right.qAugmented;
    D.leftArgmax = pairVerdict.leftArgmax;
    D.rightArgmax = pairVerdict.rightArgmax;
    D.argmaxIntersection = pairVerdict.argmaxIntersection;
    D.leftWinnerMargin = pairVerdict.leftWinnerMargin;
    D.rightWinnerMargin = pairVerdict.rightWinnerMargin;
    D.maximumAffineOracleMismatch = ...
        pairVerdict.maximumAffineOracleMismatch;
    D.minimumSaturationMargin = pairVerdict.minimumSaturationMargin;
    D.maximumInformationResidual = pairVerdict.senderInformationResidual;
    D.maximumJointResponseResidual = ...
        pairVerdict.maximumActionResponseResidual;
    D.maximumDynamicResidual = pairVerdict.dynamicResidual;
end

end


function [z,margin,ok] = localMaximizeWinner(q,gradients,rho,a)

k = size(gradients,2);
competitors = setdiff(1:numel(q),a);
Aineq = zeros(numel(competitors),k+1);
bineq = zeros(numel(competitors),1);
for j = 1:numel(competitors)
    b = competitors(j);
    Aineq(j,:) = [gradients(b,:)-gradients(a,:),1];
    bineq(j) = q(a)-q(b);
end
f = [zeros(k,1);-1];
soc = secondordercone([eye(k),zeros(k,1)],zeros(k,1), ...
    zeros(k+1,1),-rho);
opts = optimoptions('coneprog','Display','off');
[x,fval,exitflag] = coneprog(f,soc,Aineq,bineq,[],[],[],[],opts);
ok = exitflag>0 && all(isfinite(x));
if ok
    z = x(1:k);
    margin = -fval;
else
    z = zeros(k,1);
    margin = NaN;
end

end


function M = localResponseOperator(model,action,payload)

M = zeros(numel(action.actionResponse),3);
for axis = 1:3
    correction = zeros(1,3);
    correction(axis) = 1;
    unit = tcnsInformationLimitsActionMap(model,action.linkClass, ...
        action.receiver,action.sender,correction,payload);
    M(:,axis) = unit.actionResponse;
end

end


function K = localCorrectionMap(model,linkClass,receiver,sender)

h = model.h;
row = zeros(1,model.nAxis);
fi = find(model.followers==receiver,1);
if lower(string(linkClass))=="ordinary"
    a = find(model.edgeReceiver==receiver & model.edgeSender==sender,1);
    scale = model.certificate.degreeScale(fi);
    if sender==1
        row(model.index.leaderPosition) = ...
            row(model.index.leaderPosition)+model.config.Kp*scale;
        row(model.index.leaderVelocityStep) = ...
            row(model.index.leaderVelocityStep)+model.config.Kv*scale/h;
    else
        fj = find(model.followers==sender,1);
        row(model.index.e(fj)) = row(model.index.e(fj))+ ...
            model.config.Kp*scale;
        row(model.index.leaderPosition) = ...
            row(model.index.leaderPosition)+model.config.Kp*scale;
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


function K = localNullBasis(M,tolerance)

n = size(M,2);
if isempty(M)
    K = eye(n);
    return;
end
[~,S,V] = svd(M);
s = diag(S);
r = sum(s>tolerance*max(1,localFirst(s)));
K = V(:,r+1:n);

end


function r = localRank(M,tolerance)

s = svd(M,'econ');
r = sum(s>tolerance*max(1,localFirst(s)));

end


function value = localFirst(x)

if isempty(x), value = 0; else, value = x(1); end

end


function rows = localReplayRows(attemptId,endpoint,run,other,options)

p = height(run.catalog);
template = localReplayTemplate();
rows = repmat(template,p+1,1);
verdict = tcnsR27ValidateCommonFiber(run,other,options);
for a = 0:p
    row = template;
    row.attemptId = attemptId;
    row.endpoint = endpoint;
    row.actionIndex = a;
    if a==0
        row.actionId = "NO_TRANSMISSION";
        row.q = 0;
        row.affineQ = 0;
        row.actionResponseResidual = 0;
        row.oracleResponseResidual = 0;
        row.affineOracleMismatch = 0;
    else
        row.actionId = run.catalog.actionId(a);
        row.q = run.oracleValues(a);
        row.affineQ = run.affineValues(a);
        row.actionResponseResidual = verdict.actionResponseResiduals(a);
        row.oracleResponseResidual = run.oracleResponseResiduals(a);
        row.affineOracleMismatch = run.oracleValueResiduals(a);
    end
    row.senderInformationResidual = verdict.senderInformationResidual;
    row.dynamicResidual = run.affineTrajectoryResidual;
    row.saturationMargin = run.saturationMargin;
    row.argMax = ismember(a,localArgmax(run.qAugmented, ...
        options.decisionTolerance));
    row.commonFiberReplayPass = verdict.passCommonFiber;
    row.failureReason = verdict.failureReason;
    rows(a+1) = row;
end

end


function set = localArgmax(q,tolerance)

set = find(q>=max(q)-tolerance)-1;

end


function value = localVectorString(x)

if isempty(x), value = ""; else, value = strjoin(compose('%.17g',x(:)'),';'); end

end


function value = localIndexString(x)

if isempty(x), value = ""; else, value = strjoin(string(x(:)'),';'); end

end


function value = localActionIds(run)

value = strjoin(["NO_TRANSMISSION";run.catalog.actionId],';');

end


function row = localCandidateTemplate()

row = struct('attemptId',"",'sourceIndex',NaN,'sourceActionId',"", ...
    'N',NaN,'graph',"",'pinning',"",'H',NaN,'D',NaN,'sender',NaN, ...
    'actionCount',NaN,'augmentedActionCount',NaN,'sourceEligible',false, ...
    'centerReplayPass',false,'sourceStateReplayResidual',NaN, ...
    'exclusionReason',"",'outcome',"");

end


function row = localDimensionTemplate()

row = struct('attemptId',"",'sourceIndex',NaN,'sourceActionId',"", ...
    'sender',NaN,'reachableDimension',NaN, ...
    'senderInformationNullity',NaN,'jointResponseDimension',NaN, ...
    'commonDimension',NaN,'branchSemanticDimension',NaN, ...
    'senderConstraintRank',NaN,'jointResponseConstraintRank',NaN, ...
    'jointSemanticConstraintRank',NaN,'branchRadius',NaN, ...
    'maximumResponseJacobianResidual',NaN, ...
    'maximumCommandMapResidual',NaN);

end


function row = localArgmaxTemplate()

row = struct('attemptId',"",'sourceIndex',NaN,'sourceActionId',"", ...
    'sender',NaN,'actionIds',"",'centerQ',"",'commonDimension',NaN, ...
    'branchRadius',NaN,'relativeValuesVary',false, ...
    'commonActions',"",'commonWinnerMargins',"",'leftQ',"", ...
    'rightQ',"",'leftArgmax',"",'rightArgmax',"", ...
    'argmaxIntersection',"",'leftWinnerMargin',NaN, ...
    'rightWinnerMargin',NaN,'maximumAffineOracleMismatch',NaN, ...
    'minimumSaturationMargin',NaN,'maximumInformationResidual',NaN, ...
    'maximumJointResponseResidual',NaN,'maximumDynamicResidual',NaN, ...
    'outcome',"",'failureReason',"");

end


function row = localReplayTemplate()

row = struct('attemptId',"",'endpoint',"",'actionIndex',NaN, ...
    'actionId',"",'q',NaN,'affineQ',NaN, ...
    'senderInformationResidual',NaN,'dynamicResidual',NaN, ...
    'actionResponseResidual',NaN,'oracleResponseResidual',NaN, ...
    'affineOracleMismatch',NaN,'saturationMargin',NaN, ...
    'argMax',false,'commonFiberReplayPass',false,'failureReason',"");

end
