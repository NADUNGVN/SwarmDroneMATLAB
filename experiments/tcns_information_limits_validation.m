%% TCNS INFORMATION LIMITS - affine, rank and reachable-sign validation

startup;
close all;
R = startExperiment('tcns_information_limits_validation', ...
    ['IL1--IL9 theorem validation only: exact augmented affine model, ' ...
     'sender row-space tests, minimal scalar, and reachable sign witnesses.']);

seed = 27020001;
[cfg,~] = tcnsGate6Scenario(seed,'S1');
H = 25;
D = 4;
model = tcnsInformationLimitsModel(cfg,H,D,0);

%% Exact affine identities against frozen O1
leader.pos = [0.1;-0.2;1.0];
leader.vel = [0.05;-0.02;0.01];
leader.acc = zeros(3,1);
P = leader.pos'+cfg.swarm.offsets;
V = repmat(leader.vel',cfg.swarm.N,1);
P(2:end,:) = P(2:end,:)+[ ...
    0.010 -0.004 0.003; -0.008 0.006 -0.002; ...
    0.005 0.007 0.001; -0.006 -0.005 0.004];
V(2:end,:) = V(2:end,:)+[ ...
    0.004 -0.002 0.001; -0.003 0.002 -0.001; ...
    0.002 0.003 0.001; -0.002 -0.002 0.002];
net = initQueuedNetworkState(P,V,leader,cfg);
for a = 1:model.nOrdinaryLinks
    i = model.edgeReceiver(a); j = model.edgeSender(a);
    shiftP = 0.002*a*[1 -0.3 0.2];
    shiftV = 0.0005*a*[0.5 1 -0.4];
    net.Pij(i,j,:) = reshape(P(j,:)-shiftP,1,1,3);
    net.Vij(i,j,:) = reshape(V(j,:)-shiftV,1,1,3);
end
for a = 1:model.nPinnedLinks
    i = model.pinReceiver(a);
    net.leaderPos(i,:) = leader.pos'-0.003*a*[1 0.4 -0.2];
    net.leaderVel(i,:) = leader.vel'-0.0007*a*[-0.5 1 0.3];
end
state = tcnsInformationLimitsState(model,P,V,leader,net);
oracle = tcnsCentralizedStateOracleValue(P,V,leader,net,0,cfg,H);
baseline = localVectorizeResponse(oracle.baselineResponse);
baselineResidual = norm(baseline-(model.F*state.xi+model.r),inf);

affineRows = repmat(localAffineRow(), ...
    model.nOrdinaryLinks+model.nPinnedLinks,1);
rowIndex = 0;
for a = 1:model.nOrdinaryLinks
    rowIndex = rowIndex+1;
    i = model.edgeReceiver(a); j = model.edgeSender(a);
    fi = find(model.followers==i,1);
    heldP = reshape(net.Pij(i,j,:),1,3);
    heldV = reshape(net.Vij(i,j,:),1,3);
    correction = cfg.swarm.Kp*model.certificate.degreeScale(fi)* ...
        (P(j,:)-heldP)+cfg.swarm.Kv*model.certificate.degreeScale(fi)* ...
        (V(j,:)-heldV);
    payload.pos = heldP; payload.vel = heldV;
    map = tcnsInformationLimitsActionMap( ...
        model,'ordinary',i,j,correction,payload);
    affineRows(rowIndex) = localCheckAffine( ...
        "ordinary",i,j,map,state.xi,oracle.ordinaryValue(i,j), ...
        oracle.ordinaryActionResponse{i,j},baselineResidual);
end
for a = 1:model.nPinnedLinks
    rowIndex = rowIndex+1;
    i = model.pinReceiver(a); j = 1;
    heldP = net.leaderPos(i,:); heldV = net.leaderVel(i,:);
    heldA = net.leaderAcc(i,:);
    correction = cfg.swarm.KpLeader*(leader.pos'-heldP)+ ...
        cfg.swarm.KvLeader*(leader.vel'-heldV)+(leader.acc'-heldA);
    payload.pos = heldP; payload.vel = heldV; payload.acc = heldA;
    map = tcnsInformationLimitsActionMap( ...
        model,'pinned-leader',i,j,correction,payload);
    affineRows(rowIndex) = localCheckAffine( ...
        "pinned-leader",i,j,map,state.xi,oracle.leaderValue(i), ...
        oracle.leaderActionResponse{i},baselineResidual);
end
affineTable = struct2table(affineRows);

%% Actual graph row-space application and minimal-information audit
linkCount = model.nOrdinaryLinks+model.nPinnedLinks;
rankRows = repmat(localRankRow(),linkCount,1);
rowIndex = 0;
for linkType = 1:2
    if linkType==1
        count = model.nOrdinaryLinks;
    else
        count = model.nPinnedLinks;
    end
    for a = 1:count
        rowIndex = rowIndex+1;
        if linkType==1
            linkClass = "ordinary";
            i = model.edgeReceiver(a); j = model.edgeSender(a);
            payload.pos = [0 0 0]; payload.vel = [0 0 0];
        else
            linkClass = "pinned-leader";
            i = model.pinReceiver(a); j = 1;
            payload.pos = [0 0 0]; payload.vel = [0 0 0];
            payload.acc = [0 0 0];
        end
        action = tcnsInformationLimitsActionMap( ...
            model,linkClass,i,j,[1 0 0],payload);
        L = numel(action.keepIndex)-1;
        senderMap = tcnsInformationLimitsSenderMap(model,j,action,L);
        ellCurrent = action.crossTermCoefficient;
        ellStart = (senderMap.reducedDynamics^L)'*ellCurrent;
        current = tcnsLinearIdentifiability( ...
            senderMap.currentMap,ellCurrent);
        history = tcnsLinearIdentifiability( ...
            senderMap.historyMap,ellStart);
        theta = history.missingCoefficient;

        individual = false(model.N,1);
        maps = cell(model.N,1);
        for agent = 1:model.N
            maps{agent} = tcnsInformationLimitsSenderMap( ...
                model,agent,action,L);
            individual(agent) = tcnsLinearIdentifiability( ...
                maps{agent}.historyMap,theta).identifiable;
        end
        receiverCan = individual(i);
        pairMap = [maps{j}.historyMap;maps{i}.historyMap];
        pairCan = tcnsLinearIdentifiability(pairMap,theta).identifiable;
        allMap = zeros(0,numel(action.keepIndex));
        for agent = 1:model.N
            allMap = [allMap;maps{agent}.historyMap]; %#ok<AGROW>
        end
        allCan = tcnsLinearIdentifiability(allMap,theta).identifiable;
        augmented = tcnsLinearIdentifiability( ...
            [senderMap.historyMap;theta'],ellStart);
        rankRows(rowIndex) = localMakeRankRow( ...
            linkClass,i,j,L,current,history,augmented, ...
            receiverCan,pairCan,allCan,find(individual)');
    end
end
rankTable = struct2table(rankRows);

%% Dynamically admissible opposite-sign histories
ordinaryWitness = tcnsInformationLimitsDynamicWitness( ...
    cfg,H,D,'ordinary',5,1);
pinWitness = tcnsInformationLimitsDynamicWitness( ...
    cfg,H,D,'pinned-leader',4,1);
dynamicTable = struct2table([ ...
    localDynamicRow(ordinaryWitness);localDynamicRow(pinWitness)]);

%% Gate decision
maxAffineResidual = max([affineTable.baselineResidual; ...
    affineTable.actionResponseResidual;affineTable.valueResidual]);
allLinksNonidentifiable = all(~rankTable.historyIdentifiable);
allScalarClosuresPass = all(rankTable.oneScalarCloses);
dynamicPass = all(dynamicTable.dynamicallyReachable);
if maxAffineResidual<1e-10 && allLinksNonidentifiable && ...
        allScalarClosuresPass && dynamicPass
    classification = "LIMITS_THEORY_STRONG";
elseif maxAffineResidual<1e-10 && allLinksNonidentifiable
    classification = "LIMITS_THEORY_PARTIAL";
else
    classification = "LIMITS_THEORY_WEAK";
end

summary.schemaVersion = 1;
summary.seed = seed;
summary.horizonSamples = H;
summary.delaySamples = D;
summary.augmentedStatePerAxis = model.nAxis;
summary.augmentedState3D = model.nState;
summary.ordinaryLinkCount = model.nOrdinaryLinks;
summary.pinnedPayloadCount = model.nPinnedLinks;
summary.maxAffineIdentityResidual = maxAffineResidual;
summary.allLinksHistoryNonidentifiable = allLinksNonidentifiable;
summary.allOneScalarClosuresPass = allScalarClosuresPass;
summary.dynamicOrdinaryPass = ordinaryWitness.dynamicallyReachable;
summary.dynamicPinPass = pinWitness.dynamicallyReachable;
summary.classification = char(classification);
summary.noSchedulerImplemented = true;
summary.noHeldOutSeedsUsed = true;

writematrix(model.F,fullfile(R.dir,'finite_horizon_F.csv'));
writematrix(model.r,fullfile(R.dir,'finite_horizon_r.csv'));
writetable(affineTable,fullfile(R.dir,'affine_validation.csv'));
writetable(rankTable,fullfile(R.dir,'link_identifiability.csv'));
writetable(dynamicTable,fullfile(R.dir,'dynamic_witness.csv'));
fid = fopen(fullfile(R.dir,'summary.json'),'w');
assert(fid>0,'InformationLimits: cannot create summary.json.');
fprintf(fid,'%s\n',jsonencode(summary,'PrettyPrint',true));
fclose(fid);
save(fullfile(R.dir,'workspace.mat'),'cfg','model','affineTable', ...
    'rankTable','dynamicTable','ordinaryWitness','pinWitness','summary');

figure('Color','w','Position',[100 100 1050 430]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;
bar(categorical(compose('%s %d<- %d',rankTable.linkClass, ...
    rankTable.receiver,rankTable.sender)), ...
    rankTable.historyNormalizedResidual);
ylabel('normalized row-space residual'); grid on;
title('Exact value is outside sender-information row space');
nexttile;
bar(categorical(compose('%s %d<- %d',dynamicTable.linkClass, ...
    dynamicTable.receiver,dynamicTable.sender)), ...
    [dynamicTable.qMinus dynamicTable.qPlus]);
yline(0,'k-'); ylabel('expected Gate-3 value'); grid on;
title('Reachable sender-indistinguishable value signs');
saveAllFigures(R);

fprintf('IL affine maximum residual        : %.3e\n',maxAffineResidual);
fprintf('history-nonidentifiable links     : %d / %d\n', ...
    nnz(~rankTable.historyIdentifiable),height(rankTable));
fprintf('one-scalar exact closures         : %d / %d\n', ...
    nnz(rankTable.oneScalarCloses),height(rankTable));
fprintf('ordinary/pin dynamic witnesses   : %d / %d\n', ...
    ordinaryWitness.dynamicallyReachable,pinWitness.dynamicallyReachable);
fprintf('classification                    : %s\n',classification);
finishExperiment(R);


function row = localAffineRow()
row = struct('linkClass',"",'receiver',NaN,'sender',NaN, ...
    'baselineResidual',NaN,'actionResponseResidual',NaN, ...
    'crossTermResidual',NaN,'valueResidual',NaN);
end


function row = localCheckAffine( ...
    linkClass,receiver,sender,map,xi,oracleValue,oracleResponse,baseResidual)
x = xi(map.keepIndex);
baseline = map.fullCrossTermCoefficient'*xi+map.fullCrossTermConstant;
directCross = sum(localVectorizeResponse(oracleResponse).* ...
    map.actionResponse);
row = localAffineRow();
row.linkClass = linkClass;
row.receiver = receiver;
row.sender = sender;
row.baselineResidual = baseResidual;
row.actionResponseResidual = norm( ...
    map.actionResponse-localVectorizeResponse(oracleResponse),inf);
row.crossTermResidual = abs(baseline-directCross);
row.valueResidual = abs(map.valueCoefficient'*x+ ...
    map.valueConstant-oracleValue);
end


function row = localRankRow()
row = struct('linkClass',"",'receiver',NaN,'sender',NaN, ...
    'reducedDimension',NaN,'historyLength',NaN, ...
    'currentRank',NaN,'currentNullity',NaN, ...
    'currentNormalizedResidual',NaN,'currentIdentifiable',false, ...
    'historyRank',NaN,'historyNullity',NaN, ...
    'historyNormalizedResidual',NaN,'historyIdentifiable',false, ...
    'missingScalarNorm',NaN,'receiverCanComputeMissing',false, ...
    'senderReceiverCanComputeMissing',false, ...
    'allAgentsCanComputeMissing',false,'individualComputers',"", ...
    'oneScalarCloses',false);
end


function row = localMakeRankRow( ...
    linkClass,i,j,L,current,history,augmented,receiverCan,pairCan,allCan,ids)
row = localRankRow();
row.linkClass = linkClass;
row.receiver = i;
row.sender = j;
row.reducedDimension = current.rank+current.nullity;
row.historyLength = L;
row.currentRank = current.rank;
row.currentNullity = current.nullity;
row.currentNormalizedResidual = current.normalizedRowSpaceResidual;
row.currentIdentifiable = current.identifiable;
row.historyRank = history.rank;
row.historyNullity = history.nullity;
row.historyNormalizedResidual = history.normalizedRowSpaceResidual;
row.historyIdentifiable = history.identifiable;
row.missingScalarNorm = norm(history.missingCoefficient,2);
row.receiverCanComputeMissing = receiverCan;
row.senderReceiverCanComputeMissing = pairCan;
row.allAgentsCanComputeMissing = allCan;
row.individualComputers = strjoin(string(ids),',');
row.oneScalarCloses = augmented.identifiable;
end


function row = localDynamicRow(W)
row = struct('linkClass',W.linkClass,'receiver',W.receiver, ...
    'sender',W.sender,'historyLength',W.historyLength, ...
    'duration_s',W.duration_s,'beliefSupport',W.belief.supportSize, ...
    'erasureHistoryProbability',W.allAttemptsErasedProbability, ...
    'qMinus',W.minus.expectedValue,'qPlus',W.plus.expectedValue, ...
    'senderObservationDifference',W.senderObservationDifference, ...
    'actionResponseDifference',W.actionResponseDifference, ...
    'affineTrajectoryResidual',W.affineTrajectoryResidual, ...
    'maximumCommand_mps2',max(W.minus.maxUnsaturatedCommand, ...
        W.plus.maxUnsaturatedCommand), ...
    'minimumSaturationMargin_mps2',min(W.minus.saturationMargin, ...
        W.plus.saturationMargin), ...
    'dynamicallyReachable',W.dynamicallyReachable);
end


function value = localVectorizeResponse(response)
value = [];
for axis = 1:3
    value = [value;reshape(response(:,:,axis).',[],1)]; %#ok<AGROW>
end
end
