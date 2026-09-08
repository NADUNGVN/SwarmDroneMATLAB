function A = tcnsR25AdversarialAudit(r2Directory,options)
%TCNSR25ADVERSARIALAUDIT Try to falsify the frozen TCNS R2 evidence.
%
% This routine does not enlarge the R2 registry.  It independently rebuilds
% the exact 72 cells, exposes tolerance-by-tolerance rank bookkeeping,
% replays all persisted N=5 witnesses, audits practical normalization, and
% independently enumerates the reported information-owning coalitions.

if nargin<1 || isempty(r2Directory)
    root = fullfile('results','tcns_r2_generalization_validation');
    r2Directory = fullfile(root,strtrim(fileread(fullfile(root,'LATEST.txt'))));
end
if nargin<2, options = struct(); end
options = localOptions(options);

workspacePath = fullfile(r2Directory,'workspace.mat');
if ~isfile(workspacePath)
    error('tcnsR25AdversarialAudit:MissingWorkspace', ...
        'R2 workspace not found: %s',workspacePath);
end
S = load(workspacePath,'cfg','generalization','witness');
R2 = S.generalization;
W2 = S.witness;

registryRows = repmat(localRegistryTemplate(),0,1);
numericRows = repmat(localNumericTemplate(),0,1);
coalitionRows = repmat(localCoalitionTemplate(),0,1);

for ni = 1:numel(R2.options.NValues)
    N = R2.options.NValues(ni);
    for gi = 1:numel(R2.options.graphIds)
        graphId = string(R2.options.graphIds(gi));
        for pi = 1:numel(R2.options.pinIds)
            pinId = string(R2.options.pinIds(pi));
            cfg = tcnsR2RegistryConfiguration( ...
                R2.options.seed,N,graphId,pinId);
            graph = localGraphAudit(cfg,graphId);
            configurationId = sprintf('N%d_%s_pin_%s',N,graphId,pinId);
            for hi = 1:numel(R2.options.HValues)
                H = R2.options.HValues(hi);
                for di = 1:numel(R2.options.DValues)
                    D = R2.options.DValues(di);
                    row = localRegistryTemplate();
                    row.configurationId = string(configurationId);
                    row.N = N;
                    row.graphId = graphId;
                    row.pinId = pinId;
                    row.H = H;
                    row.D = D;
                    row.seed = R2.options.seed;
                    row.graphGeneration = graph.description;
                    row.preLeaderGraphEdgeCount = graph.undirectedEdgeCount;
                    row.preLeaderGraphDensity = graph.undirectedDensity;
                    row.controllerDirectedEdgeCount = graph.controllerEdgeCount;
                    row.controllerEdgeDensity = graph.controllerDensity;
                    row.preLeaderGraphConnected = graph.connected;
                    row.connectednessCriterion = graph.connectednessCriterion;
                    row.pinnedAgents = strjoin(string(find(cfg.swarm.pin>0)),'+');
                    row.pinnedAgentCount = nnz(cfg.swarm.pin>0);
                    row.senderInformationDefinition = ...
                        "own state + incoming controller memories + "+ ...
                        "unsaturated command; complete held-memory history";
                    row.formationObjectiveDefinition = ...
                        "identity-weighted stacked follower position-error "+ ...
                        "energy over H samples";
                    row.Kp = cfg.swarm.Kp;
                    row.Kv = cfg.swarm.Kv;
                    row.KpLeader = cfg.swarm.KpLeader;
                    row.KvLeader = cfg.swarm.KvLeader;
                    row.graphSelectedBeforeResults = true;
                    row.protocolCommit = "253b99b1071bdb65965c6aa56087ab02b6bec00e";
                    try
                        model = tcnsInformationLimitsModel(cfg,H,D,0);
                        catalog = tcnsInformationLimitsActionCatalog(model);
                        row.modelFeasible = true;
                        row.modelInfeasible = false;
                        row.actionCount = height(catalog);
                        row.scientificResultExcluded = false;
                        storedRegistry = R2.registryTable( ...
                            R2.registryTable.configurationId==string(configurationId) & ...
                            R2.registryTable.H==H & R2.registryTable.D==D,:);
                        row.storedRegistryRowCount = height(storedRegistry);
                        row.storedActionCount = sum( ...
                            R2.actionTable.configurationId==string(configurationId) & ...
                            R2.actionTable.H==H & R2.actionTable.D==D);
                        row.noSilentExclusion = height(storedRegistry)==1 && ...
                            storedRegistry.admissible && ...
                            row.storedActionCount==row.actionCount;
                        [actionRows,coalitions] = localCellAudit( ...
                            model,catalog,R2,configurationId,graphId, ...
                            pinId,H,D,options);
                        numericRows = [numericRows;actionRows]; %#ok<AGROW>
                        coalitionRows = [coalitionRows;coalitions]; %#ok<AGROW>
                        if ~row.noSilentExclusion
                            row.failureReason = "R2_ROW_OR_ACTION_COUNT_MISMATCH";
                        else
                            row.failureReason = "NONE";
                        end
                    catch exception
                        row.modelFeasible = false;
                        row.modelInfeasible = true;
                        row.scientificResultExcluded = false;
                        row.noSilentExclusion = false;
                        row.failureReason = string(exception.identifier)+ ...
                            ": "+string(exception.message);
                    end
                    registryRows(end+1,1) = row; %#ok<AGROW>
                end
            end
        end
    end
end

A.schemaVersion = 1;
A.studyClass = "TCNS_R2_5_ADVERSARIAL_AUDIT_NO_REGISTRY_EXPANSION";
A.r2Directory = string(r2Directory);
A.r2SourceCommit = "a2cec3b";
A.r2PushedHead = "c1538ae8045cfdc805e02c2a0eabc23be";
A.options = options;
A.registryTable = struct2table(registryRows);
A.numericRankTable = struct2table(numericRows);
A.coalitionTable = struct2table(coalitionRows);
A.coalitionDistribution = localCoalitionDistribution(A.coalitionTable);
A.fragileVpaTable = localFragileVpaAudit(A.numericRankTable,R2,options);
[A.witnessReplayTable,A.normalizationTable,A.witnessReplayPackage] = ...
    localWitnessReplay(S.cfg,W2,options);
A.noNewRegistryCell = true;
A.noSchedulerImplemented = true;
A.noHeldOutSeedUsed = true;

end


function options = localOptions(options)

defaults.toleranceGrid = [1e-6 1e-8 1e-10 1e-12 1e-14];
defaults.referenceTolerance = 1e-10;
defaults.vpaDigits = 80;
defaults.enableVpa = true;
defaults.informationTolerance = 1e-9;
defaults.reachabilityTolerance = 1e-9;
defaults.responseTolerance = 1e-9;
defaults.oracleTolerance = 1e-9;
defaults.signTolerance = 1e-12;
defaults.saturationMarginTolerance = 1e-6;
defaults.referenceSeed = 27022001;
defaults.referenceCount = 32;
defaults.referencePositionRadius_m = 0.05;
defaults.referenceVelocityRadius_mps = 0.05;
names = fieldnames(defaults);
for q = 1:numel(names)
    if ~isfield(options,names{q}) || isempty(options.(names{q}))
        options.(names{q}) = defaults.(names{q});
    end
end
options.toleranceGrid = double(options.toleranceGrid(:)');

end


function graph = localGraphAudit(cfg,graphId)

Acontrol = double(cfg.swarm.A~=0);
Apre = Acontrol;
Apre(1,:) = Apre(:,1)';
Apre(1,1) = 0;
info = graphConnectivity(Apre,zeros(cfg.swarm.N,1));
N = cfg.swarm.N;
graph.controllerEdgeCount = nnz(Acontrol);
graph.controllerDensity = graph.controllerEdgeCount/((N-1)^2);
graph.undirectedEdgeCount = nnz(Apre)/2;
graph.undirectedDensity = nnz(Apre)/(N*(N-1));
graph.connected = info.connected;
switch graphId
    case "ring2"
        graph.description = [ ...
            "deterministic circulant distance-1 ring; leader incoming row " ...
            "removed after construction"];
        graph.connectednessCriterion = [ ...
            "deterministic ring construction; reconstructed pre-leader graph " ...
            "checked connected"];
    case "sparse4"
        graph.description = [ ...
            "deterministic circulant distance-1/2 graph; leader incoming row " ...
            "removed after construction"];
        graph.connectednessCriterion = [ ...
            "deterministic circulant construction; reconstructed pre-leader " ...
            "graph checked connected"];
    case "geometric"
        graph.description = [ ...
            "deterministic formation-lattice radius graph; smallest radius " ...
            "in 0.15-m increments from 0.60 m giving connectivity"];
        graph.connectednessCriterion = ...
            "graphConnectivity.connected on the pre-leader-row geometric graph";
    otherwise
        error('tcnsR25AdversarialAudit:GraphId','Unknown graph %s.',graphId);
end

end


function [rows,coalitionRows] = localCellAudit(model,catalog,R2, ...
    configurationId,graphId,pinId,H,D,options)

rows = repmat(localNumericTemplate(), ...
    height(catalog)*numel(options.toleranceGrid),1);
qrow = 0;
for a = 1:height(catalog)
    action = catalog.actionMap{a};
    historyLength = model.nState-numel(action.targetIndex)-1;
    senderMap = tcnsInformationLimitsSenderMap( ...
        model,catalog.sender(a),[],historyLength);
    T = zeros(numel(action.targetIndex),model.nState);
    for q = 1:numel(action.targetIndex)
        T(q,action.targetIndex(q)) = 1;
    end
    C = [senderMap.historyMap;T];
    coefficient = -2*action.successProbability/model.m* ...
        action.fullCrossTermCoefficient;
    ell = (model.holdA3^historyLength)'*coefficient;
    ellNorm = max(norm(ell,2),eps);
    [~,S,V] = svd(C,'econ');
    s = diag(S);
    storedAction = R2.actionTable( ...
        R2.actionTable.configurationId==string(configurationId) & ...
        R2.actionTable.H==H & R2.actionTable.D==D & ...
        R2.actionTable.actionId==catalog.actionId(a),:);
    for ti = 1:numel(options.toleranceGrid)
        tol = options.toleranceGrid(ti);
        qrow = qrow+1;
        if isempty(s), sigmaMax = 0; else, sigmaMax = s(1); end
        cutoff = tol*max(1,sigmaMax);
        rawRank = sum(s>cutoff);
        Nbasis = V(:,rawRank+1:end);
        projectionResidual = norm(Nbasis'*ell,2);
        normalizedResidual = projectionResidual/ellNorm;
        identifiable = normalizedResidual<=tol;
        sAugRaw = svd([C;ell'],'econ');
        rawAugmentedRank = sum(sAugRaw> ...
            tol*max(1,localFirstOrZero(sAugRaw)));
        Q = V(:,1:rawRank);
        sAugNormalized = svd([Q';ell'/ellNorm],'econ');
        normalizedAugmentedRank = sum(sAugNormalized> ...
            tol*max(1,localFirstOrZero(sAugNormalized)));
        if rawRank>0
            smallestRetained = s(rawRank);
        else
            smallestRetained = NaN;
        end
        if rawRank<numel(s)
            largestDiscarded = s(rawRank+1);
        else
            largestDiscarded = 0;
        end
        positive = s(s>0);
        if isempty(positive)
            closestRatio = NaN;
        else
            ratios = positive/cutoff;
            [~,closest] = min(abs(log10(ratios)));
            closestRatio = ratios(closest);
        end
        storedTolerance = R2.toleranceTable( ...
            R2.toleranceTable.configurationId==string(configurationId) & ...
            R2.toleranceTable.H==H & R2.toleranceTable.D==D & ...
            R2.toleranceTable.actionId==catalog.actionId(a) & ...
            R2.toleranceTable.relativeTolerance==tol,:);
        row = localNumericTemplate();
        row.configurationId = string(configurationId);
        row.N = model.N;
        row.graphId = graphId;
        row.pinId = pinId;
        row.H = H;
        row.D = D;
        row.actionId = catalog.actionId(a);
        row.linkClass = catalog.linkClass(a);
        row.sender = catalog.sender(a);
        row.receiver = catalog.receiver(a);
        row.tolerance = tol;
        row.rawRankC = rawRank;
        row.rawNullityC = model.nState-rawRank;
        row.rawRankAugmentedC = rawAugmentedRank;
        row.rawAugmentedRankIncrease = rawAugmentedRank-rawRank;
        row.normalizedBasisAugmentedRank = normalizedAugmentedRank;
        row.normalizedBasisRankIncrease = normalizedAugmentedRank-rawRank;
        row.projectionResidual = projectionResidual;
        row.normalizedProjectionResidual = normalizedResidual;
        row.identifiable = identifiable;
        row.augmentedRowAddsDimension = ~identifiable;
        row.sigmaMaxC = sigmaMax;
        row.rankThreshold = cutoff;
        row.smallestRetainedSingularValue = smallestRetained;
        row.largestDiscardedSingularValue = largestDiscarded;
        row.retainedToThresholdRatio = smallestRetained/cutoff;
        row.discardedToThresholdRatio = largestDiscarded/cutoff;
        row.singularGapRatio = smallestRetained/ ...
            max(largestDiscarded,realmin);
        row.closestSingularToThresholdRatio = closestRatio;
        row.singularValuesAroundCutoff = localSingularWindow(s,rawRank);
        row.valueSeparationMultiple = normalizedResidual/tol;
        row.storedRowCount = height(storedTolerance);
        if height(storedTolerance)==1
            row.storedRankMatch = storedTolerance.historyRank==rawRank;
            row.storedIdentifiabilityMatch = ...
                logical(storedTolerance.identifiable)==identifiable;
            row.storedResidualDifference = abs( ...
                storedTolerance.normalizedRowSpaceResidual-normalizedResidual);
        end
        row.storedActionRankStable = height(storedAction)==1 && ...
            logical(storedAction.numericRankStable);
        rows(qrow) = row;
    end
end

coalitionRows = localCoalitionAudit(model,catalog,R2, ...
    configurationId,graphId,pinId,H,D,options.referenceTolerance);

end


function rows = localCoalitionAudit(model,catalog,R2,configurationId, ...
    graphId,pinId,H,D,tol)

senders = unique(catalog.sender,'stable');
agentMaps = cell(model.N,1);
for agent = 1:model.N
    agentMaps{agent} = tcnsInformationLimitsSenderMap( ...
        model,agent,[],0).currentMap;
end
rows = repmat(localCoalitionTemplate(),numel(senders),1);
for si = 1:numel(senders)
    sender = senders(si);
    ids = find(catalog.sender==sender);
    L = zeros(numel(ids),model.nState);
    for a = 1:numel(ids)
        action = catalog.actionMap{ids(a)};
        L(a,:) = (-2*action.successProbability/model.m* ...
            action.fullCrossTermCoefficient)';
    end
    [minimumSize,coalitions,allSmallerFail] = ...
        localEnumerateCoalitions(agentMaps,sender,L,tol);
    stored = R2.senderTable( ...
        R2.senderTable.configurationId==string(configurationId) & ...
        R2.senderTable.H==H & R2.senderTable.D==D & ...
        R2.senderTable.sender==sender,:);
    row = localCoalitionTemplate();
    row.configurationId = string(configurationId);
    row.N = model.N;
    row.graphId = graphId;
    row.pinId = pinId;
    row.H = H;
    row.D = D;
    row.sender = sender;
    row.actionCount = numel(ids);
    row.minimumCoalitionSize = minimumSize;
    row.normalizedCoalitionFraction = minimumSize/model.N;
    row.minimumCoalitionMultiplicity = numel(coalitions);
    row.minimumCoalitions = strjoin(coalitions,';');
    row.minimumCoalitionUnique = isscalar(coalitions);
    row.allReportedCoalitionsIdentify = ~isempty(coalitions);
    row.allSmallerCoalitionsFail = allSmallerFail;
    row.storedRowCount = height(stored);
    if height(stored)==1
        row.storedMinimumSizeMatch = ...
            stored.minimumCoalitionSize==minimumSize;
        row.storedMultiplicity = numel(split( ...
            stored.minimumCoalitions,';'));
        row.storedMultiplicityMatch = ...
            row.storedMultiplicity==row.minimumCoalitionMultiplicity;
    end
    rows(si) = row;
end

end


function [minimumSize,coalitions,allSmallerFail] = ...
    localEnumerateCoalitions(agentMaps,sender,L,tol)

N = numel(agentMaps);
other = setdiff(1:N,sender,'stable');
minimumSize = NaN;
coalitions = strings(0,1);
allSmallerFail = true;
for additional = 0:numel(other)
    if additional==0
        choices = zeros(1,0);
    else
        choices = nchoosek(other,additional);
    end
    foundThisSize = false;
    for q = 1:size(choices,1)
        members = [sender choices(q,:)];
        C = vertcat(agentMaps{members});
        if localAllRowsIdentifiable(C,L,tol)
            foundThisSize = true;
            minimumSize = numel(members);
            coalitions(end+1,1) = strjoin(string(members),'+'); %#ok<AGROW>
        end
    end
    if foundThisSize
        break;
    end
end

end


function yes = localAllRowsIdentifiable(C,L,tol)

[~,S,V] = svd(C,'econ');
s = diag(S);
if isempty(s), sigmaMax = 0; else, sigmaMax = s(1); end
r = sum(s>tol*max(1,sigmaMax));
N = V(:,r+1:end);
denominator = max(vecnorm(L,2,2),eps);
yes = all(vecnorm(L*N,2,2)./denominator<=tol);

end


function distribution = localCoalitionDistribution(coalitionTable)

rows = repmat(localCoalitionDistributionTemplate(),0,1);
Nvalues = unique(coalitionTable.N)';
for scopeIndex = 0:numel(Nvalues)
    if scopeIndex==0
        selected = true(height(coalitionTable),1);
        scope = "ALL";
        Nvalue = NaN;
    else
        Nvalue = Nvalues(scopeIndex);
        selected = coalitionTable.N==Nvalue;
        scope = "N"+string(Nvalue);
    end
    sizes = unique(coalitionTable.minimumCoalitionSize(selected))';
    denominator = nnz(selected);
    for sizeValue = sizes
        subset = selected & ...
            coalitionTable.minimumCoalitionSize==sizeValue;
        row = localCoalitionDistributionTemplate();
        row.scope = scope;
        row.N = Nvalue;
        row.minimumCoalitionSize = sizeValue;
        row.frequency = nnz(subset);
        row.fraction = row.frequency/denominator;
        if isfinite(Nvalue)
            row.normalizedCoalitionFraction = sizeValue/Nvalue;
        else
            row.normalizedCoalitionFraction = mean( ...
                coalitionTable.normalizedCoalitionFraction(subset));
        end
        row.uniqueMinimumFrequency = nnz(subset & ...
            coalitionTable.minimumCoalitionUnique);
        row.multipleMinimumFrequency = row.frequency- ...
            row.uniqueMinimumFrequency;
        rows(end+1,1) = row; %#ok<AGROW>
    end
end
distribution = struct2table(rows);

end


function tableOut = localFragileVpaAudit(numericTable,R2,options)

reference = numericTable(numericTable.tolerance== ...
    options.referenceTolerance,:);
key = reference.configurationId+"|"+reference.actionId+"|H"+ ...
    string(reference.H)+"|D"+string(reference.D);
selected = zeros(0,1);
[~,globalMinimum] = min(reference.normalizedProjectionResidual);
selected(end+1,1) = globalMinimum;
unstable = find(~reference.storedActionRankStable);
if ~isempty(unstable)
    [~,q] = min(reference.normalizedProjectionResidual(unstable));
    selected(end+1,1) = unstable(q);
    [~,q] = min(abs(log10( ...
        reference.closestSingularToThresholdRatio(unstable))));
    selected(end+1,1) = unstable(q);
end
selected = unique(selected,'stable');
rows = repmat(localVpaTemplate(),numel(selected),1);
for q = 1:numel(selected)
    source = reference(selected(q),:);
    cfg = tcnsR2RegistryConfiguration(R2.options.seed,source.N, ...
        source.graphId,source.pinId);
    model = tcnsInformationLimitsModel(cfg,source.H,source.D,0);
    catalog = tcnsInformationLimitsActionCatalog(model);
    a = find(catalog.actionId==source.actionId,1);
    action = catalog.actionMap{a};
    historyLength = model.nState-numel(action.targetIndex)-1;
    senderMap = tcnsInformationLimitsSenderMap( ...
        model,action.sender,[],historyLength);
    T = zeros(numel(action.targetIndex),model.nState);
    for ti = 1:numel(action.targetIndex)
        T(ti,action.targetIndex(ti)) = 1;
    end
    C = [senderMap.historyMap;T];
    coefficient = -2*action.successProbability/model.m* ...
        action.fullCrossTermCoefficient;
    ell = (model.holdA3^historyLength)'*coefficient;
    row = localVpaTemplate();
    row.selectionKey = key(selected(q));
    if selected(q)==globalMinimum
        row.selectionReason = "GLOBAL_MINIMUM_RESIDUAL";
    elseif q==2
        row.selectionReason = "UNSTABLE_RANK_MINIMUM_RESIDUAL";
    else
        row.selectionReason = "UNSTABLE_RANK_NEAREST_CUTOFF";
    end
    row.configurationId = source.configurationId;
    row.N = source.N;
    row.graphId = source.graphId;
    row.pinId = source.pinId;
    row.H = source.H;
    row.D = source.D;
    row.actionId = source.actionId;
    row.doubleNormalizedResidual = source.normalizedProjectionResidual;
    row.rawRankAtReference = source.rawRankC;
    same = numericTable.configurationId==source.configurationId & ...
        numericTable.actionId==source.actionId & ...
        numericTable.H==source.H & numericTable.D==source.D;
    row.rawRanksAcrossTolerance = strjoin( ...
        string(numericTable.rawRankC(same))',';');
    row.tolerances = strjoin(compose('%.0e', ...
        numericTable.tolerance(same))',';');
    row.sigmaMaxC = source.sigmaMaxC;
    row.rankThreshold = source.rankThreshold;
    row.smallestRetainedSingularValue = ...
        source.smallestRetainedSingularValue;
    row.largestDiscardedSingularValue = ...
        source.largestDiscardedSingularValue;
    row.retainedToThresholdRatio = source.retainedToThresholdRatio;
    row.discardedToThresholdRatio = source.discardedToThresholdRatio;
    row.singularGapRatio = source.singularGapRatio;
    row.singularValuesAroundCutoff = source.singularValuesAroundCutoff;
    if options.enableVpa
        try
            row.vpaNormalizedResidual = localVpaResidual( ...
                C,ell,options.referenceTolerance,options.vpaDigits);
            row.doubleVpaDifference = abs( ...
                row.doubleNormalizedResidual-row.vpaNormalizedResidual);
            row.vpaDigits = options.vpaDigits;
            row.failureReason = "NONE";
        catch exception
            row.failureReason = string(exception.identifier)+ ...
                ": "+string(exception.message);
        end
    else
        row.failureReason = "VPA_DISABLED";
    end
    rows(q) = row;
end
tableOut = struct2table(rows);

end


function residual = localVpaResidual(C,ell,tol,digitCount)

s = svd(C,'econ');
if isempty(s), sigmaMax = 0; else, sigmaMax = s(1); end
r = sum(s>tol*max(1,sigmaMax));
[~,R,p] = qr(C','vector');
diagonal = abs(diag(R));
qrRank = sum(diagonal>tol*max(1,sigmaMax));
if qrRank~=r
    error('tcnsR25AdversarialAudit:VpaBasis', ...
        'QR rank %d differs from SVD rank %d.',qrRank,r);
end
B = C(p(1:r),:);
oldDigits = digits;
cleanup = onCleanup(@() digits(oldDigits));
digits(digitCount);
Bv = vpa(B,digitCount);
ellv = vpa(ell,digitCount);
alpha = (Bv*Bv.')\(Bv*ellv);
hidden = ellv-Bv.'*alpha;
residual = double(sqrt(hidden.'*hidden)/sqrt(ellv.'*ellv));

end


function [witnessTable,normalizationTable,package] = ...
    localWitnessReplay(cfg,W2,options)

rows = repmat(localWitnessTemplate(),W2.actionCount,1);
normalizationRows = repmat(localNormalizationTemplate(),W2.actionCount,1);
package = repmat(struct('actionId',"",'uMinus',[], 'uPlus',[], ...
    'leaderVelocity',[],'historyLength',NaN,'minusRun',struct(), ...
    'plusRun',struct()),W2.actionCount,1);
validationOptions = struct( ...
    'informationTolerance',options.informationTolerance, ...
    'reachabilityTolerance',options.reachabilityTolerance, ...
    'responseTolerance',options.responseTolerance, ...
    'oracleTolerance',options.oracleTolerance, ...
    'signTolerance',options.signTolerance, ...
    'saturationMarginTolerance',options.saturationMarginTolerance);

for a = 1:W2.actionCount
    persisted = W2.witnessTable(a,:);
    detail = W2.details{a};
    epsilon = W2.options.initialSignHalfSeparation;
    uMinus = detail.uCenter-epsilon*detail.direction;
    uPlus = detail.uCenter+epsilon*detail.direction;
    leaderVelocity = reshape(detail.baseRun.finalLeader.vel,1,3);
    minusRun = tcnsInformationLimitsReplayWitness( ...
        cfg,W2.horizonSamples,W2.delaySamples,persisted.linkClass, ...
        persisted.receiver,persisted.sender,uMinus,leaderVelocity, ...
        persisted.historyLength);
    plusRun = tcnsInformationLimitsReplayWitness( ...
        cfg,W2.horizonSamples,W2.delaySamples,persisted.linkClass, ...
        persisted.receiver,persisted.sender,uPlus,leaderVelocity, ...
        persisted.historyLength);
    verdict = tcnsR25ValidateWitnessPair( ...
        minusRun,plusRun,validationOptions);

    row = localWitnessTemplate();
    row.actionId = persisted.actionId;
    row.linkClass = persisted.linkClass;
    row.sender = persisted.sender;
    row.receiver = persisted.receiver;
    row.actualControllerCorrection = true;
    row.actualCorrectionNorm = mean([ ...
        norm(minusRun.commandCorrection,2), ...
        norm(plusRun.commandCorrection,2)]);
    row.correctionResidual = verdict.correctionResidual;
    row.actualResponseNorm = mean([ ...
        norm(minusRun.actionResponse,2),norm(plusRun.actionResponse,2)]);
    row.qMinus = minusRun.oracleValue;
    row.qPlus = plusRun.oracleValue;
    row.informationHistoryResidual = ...
        verdict.informationHistoryResidual;
    row.responseResidual = verdict.responseResidual;
    row.oracleResponseResidual = verdict.oracleResponseResidual;
    row.dynamicResidual = verdict.dynamicResidual;
    row.minimumSaturationMargin = verdict.minimumSaturationMargin;
    row.affineValueMinus = minusRun.affineValue;
    row.affineValuePlus = plusRun.affineValue;
    row.directOracleValueMinus = minusRun.oracleValue;
    row.directOracleValuePlus = plusRun.oracleValue;
    row.affineOracleMismatch = verdict.affineOracleMismatch;
    row.witnessPerturbationNorm = norm((uPlus-uMinus)/2,2);
    row.pairSeparationNorm = norm(uPlus-uMinus,2);
    row.signMarginOverAcceptanceTolerance = min( ...
        abs([row.qMinus row.qPlus]))/options.signTolerance;
    row.signMarginOverOracleMismatch = min( ...
        abs([row.qMinus row.qPlus]))/ ...
        max(verdict.affineOracleMismatch,eps);
    row.targetValueResidual = verdict.targetValueResidual;
    row.targetIndexSame = verdict.targetIndexSame;
    row.packetSemanticsSame = verdict.packetSemanticsSame;
    row.controllerBranchSame = verdict.controllerBranchSame;
    row.fixedResponseConsistent = verdict.correctionResidual<= ...
        options.responseTolerance && verdict.responseResidual<= ...
        options.responseTolerance && verdict.oracleResponseResidual<= ...
        options.responseTolerance && verdict.targetIndexSame && ...
        verdict.targetValueResidual<=options.responseTolerance && ...
        verdict.packetSemanticsSame && verdict.controllerBranchSame;
    row.persistedReplayMismatch = max(abs([ ...
        row.qMinus-persisted.qMinus, ...
        row.qPlus-persisted.qPlus, ...
        row.informationHistoryResidual- ...
            persisted.senderObservationResidual, ...
        row.responseResidual-persisted.actionResponseResidual]));
    row.replayPass = verdict.pass;
    row.failureReason = verdict.failureReason;
    rows(a) = row;

    normalizationRows(a) = localNormalizationAudit( ...
        cfg,W2,detail,persisted,a,options,row);
    package(a).actionId = persisted.actionId;
    package(a).uMinus = uMinus;
    package(a).uPlus = uPlus;
    package(a).leaderVelocity = leaderVelocity;
    package(a).historyLength = persisted.historyLength;
    package(a).minusRun = minusRun;
    package(a).plusRun = plusRun;
end
witnessTable = struct2table(rows);
normalizationTable = struct2table(normalizationRows);

end


function row = localNormalizationAudit(cfg,W2,detail,persisted, ...
    actionIndex,options,witnessRow)

stream = RandStream('mt19937ar', ...
    'Seed',options.referenceSeed+actionIndex);
values = nan(options.referenceCount,1);
valid = false(options.referenceCount,1);
m = numel(detail.uCenter)/6;
for q = 1:options.referenceCount
    delta = zeros(size(detail.uCenter));
    for axis = 1:3
        block = (axis-1)*2*m;
        positionDirection = randn(stream,m,1);
        velocityDirection = randn(stream,m,1);
        delta(block+(1:m)) = options.referencePositionRadius_m* ...
            positionDirection/max(norm(positionDirection,2),eps);
        delta(block+m+(1:m)) = cfg.swarm.dt* ...
            options.referenceVelocityRadius_mps*velocityDirection/ ...
            max(norm(velocityDirection,2),eps);
    end
    run = tcnsInformationLimitsReplayWitness( ...
        cfg,W2.horizonSamples,W2.delaySamples,persisted.linkClass, ...
        persisted.receiver,persisted.sender,detail.uCenter+delta, ...
        reshape(detail.baseRun.finalLeader.vel,1,3), ...
        persisted.historyLength);
    if run.saturationMargin>options.saturationMarginTolerance
        valid(q) = true;
        values(q) = run.oracleValue;
    end
end
qValues = values(valid);
absValues = abs(qValues);
row = localNormalizationTemplate();
row.actionId = persisted.actionId;
row.linkClass = persisted.linkClass;
row.sender = persisted.sender;
row.receiver = persisted.receiver;
row.informationRadius = (witnessRow.qPlus-witnessRow.qMinus)/2;
row.referenceSeed = options.referenceSeed+actionIndex;
row.referenceRequestedCount = options.referenceCount;
row.referenceValidCount = nnz(valid);
row.positionRadius_m = options.referencePositionRadius_m;
row.velocityRadius_mps = options.referenceVelocityRadius_mps;
if isempty(qValues)
    row.failureReason = "NO_UNSATURATED_REFERENCE_STATES";
    return;
end
row.referenceAbsMedian = median(absValues);
row.referenceAbsIQR = localQuantile(absValues,0.75)- ...
    localQuantile(absValues,0.25);
row.referenceAbsMinimum = min(absValues);
row.referenceAbsMaximum = max(absValues);
row.referenceRms = sqrt(mean(qValues.^2));
row.referenceIqrScale = (localQuantile(qValues,0.75)- ...
    localQuantile(qValues,0.25))/1.349;
row.normalizedByMedianAbs = row.informationRadius/ ...
    max(row.referenceAbsMedian,eps);
row.normalizedByRms = row.informationRadius/ ...
    max(row.referenceRms,eps);
row.normalizedByIqrScale = row.informationRadius/ ...
    max(row.referenceIqrScale,eps);
row.persistedMedianDifference = abs( ...
    row.referenceAbsMedian-persisted.referenceMedianAbsValue);
row.persistedNormalizationDifference = abs( ...
    row.normalizedByMedianAbs-persisted.normalizedAmbiguity);
row.failureReason = "NONE";

end


function value = localQuantile(x,p)

x = sort(double(x(:)));
if isempty(x)
    value = NaN;
    return;
end
position = 1+(numel(x)-1)*p;
lowerIndex = floor(position);
upperIndex = ceil(position);
if lowerIndex==upperIndex
    value = x(lowerIndex);
else
    weight = position-lowerIndex;
    value = (1-weight)*x(lowerIndex)+weight*x(upperIndex);
end

end


function value = localFirstOrZero(x)

if isempty(x), value = 0; else, value = x(1); end

end


function text = localSingularWindow(s,r)

if isempty(s)
    text = "";
    return;
end
indices = max(1,r-2):min(numel(s),r+3);
tokens = strings(numel(indices),1);
for q = 1:numel(indices)
    tokens(q) = sprintf('s%d=%.17g',indices(q),s(indices(q)));
end
text = strjoin(tokens,';');

end


function row = localRegistryTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'seed',NaN,'graphGeneration',"", ...
    'preLeaderGraphEdgeCount',NaN,'preLeaderGraphDensity',NaN, ...
    'controllerDirectedEdgeCount',NaN,'controllerEdgeDensity',NaN, ...
    'preLeaderGraphConnected',false,'connectednessCriterion',"", ...
    'pinnedAgents',"",'pinnedAgentCount',NaN, ...
    'senderInformationDefinition',"",'formationObjectiveDefinition',"", ...
    'Kp',NaN,'Kv',NaN,'KpLeader',NaN,'KvLeader',NaN, ...
    'graphSelectedBeforeResults',false,'protocolCommit',"", ...
    'modelFeasible',false,'modelInfeasible',false,'actionCount',0, ...
    'storedRegistryRowCount',0,'storedActionCount',0, ...
    'scientificResultExcluded',false,'noSilentExclusion',false, ...
    'failureReason',"");
end


function row = localNumericTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'actionId',"",'linkClass',"",'sender',NaN, ...
    'receiver',NaN,'tolerance',NaN,'rawRankC',NaN,'rawNullityC',NaN, ...
    'rawRankAugmentedC',NaN,'rawAugmentedRankIncrease',NaN, ...
    'normalizedBasisAugmentedRank',NaN, ...
    'normalizedBasisRankIncrease',NaN,'projectionResidual',NaN, ...
    'normalizedProjectionResidual',NaN,'identifiable',false, ...
    'augmentedRowAddsDimension',false,'sigmaMaxC',NaN, ...
    'rankThreshold',NaN,'smallestRetainedSingularValue',NaN, ...
    'largestDiscardedSingularValue',NaN,'retainedToThresholdRatio',NaN, ...
    'discardedToThresholdRatio',NaN,'singularGapRatio',NaN, ...
    'closestSingularToThresholdRatio',NaN, ...
    'singularValuesAroundCutoff',"",'valueSeparationMultiple',NaN, ...
    'storedRowCount',0,'storedRankMatch',false, ...
    'storedIdentifiabilityMatch',false,'storedResidualDifference',NaN, ...
    'storedActionRankStable',false);
end


function row = localCoalitionTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'sender',NaN,'actionCount',NaN, ...
    'minimumCoalitionSize',NaN,'normalizedCoalitionFraction',NaN, ...
    'minimumCoalitionMultiplicity',NaN,'minimumCoalitions',"", ...
    'minimumCoalitionUnique',false, ...
    'allReportedCoalitionsIdentify',false,'allSmallerCoalitionsFail',false, ...
    'storedRowCount',0,'storedMinimumSizeMatch',false, ...
    'storedMultiplicity',NaN,'storedMultiplicityMatch',false);
end


function row = localCoalitionDistributionTemplate()
row = struct('scope',"",'N',NaN,'minimumCoalitionSize',NaN, ...
    'frequency',0,'fraction',NaN,'normalizedCoalitionFraction',NaN, ...
    'uniqueMinimumFrequency',0,'multipleMinimumFrequency',0);
end


function row = localVpaTemplate()
row = struct('selectionKey',"",'selectionReason',"", ...
    'configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'actionId',"",'doubleNormalizedResidual',NaN, ...
    'vpaNormalizedResidual',NaN,'doubleVpaDifference',NaN, ...
    'vpaDigits',NaN,'rawRankAtReference',NaN, ...
    'rawRanksAcrossTolerance',"",'tolerances',"",'sigmaMaxC',NaN, ...
    'rankThreshold',NaN,'smallestRetainedSingularValue',NaN, ...
    'largestDiscardedSingularValue',NaN,'retainedToThresholdRatio',NaN, ...
    'discardedToThresholdRatio',NaN,'singularGapRatio',NaN, ...
    'singularValuesAroundCutoff',"",'failureReason',"");
end


function row = localWitnessTemplate()
row = struct('actionId',"",'linkClass',"",'sender',NaN,'receiver',NaN, ...
    'actualControllerCorrection',false,'actualCorrectionNorm',NaN, ...
    'correctionResidual',NaN,'actualResponseNorm',NaN,'qMinus',NaN, ...
    'qPlus',NaN,'informationHistoryResidual',NaN,'responseResidual',NaN, ...
    'oracleResponseResidual',NaN,'dynamicResidual',NaN, ...
    'minimumSaturationMargin',NaN,'affineValueMinus',NaN, ...
    'affineValuePlus',NaN,'directOracleValueMinus',NaN, ...
    'directOracleValuePlus',NaN,'affineOracleMismatch',NaN, ...
    'witnessPerturbationNorm',NaN,'pairSeparationNorm',NaN, ...
    'signMarginOverAcceptanceTolerance',NaN, ...
    'signMarginOverOracleMismatch',NaN,'targetValueResidual',NaN, ...
    'targetIndexSame',false,'packetSemanticsSame',false, ...
    'controllerBranchSame',false,'fixedResponseConsistent',false, ...
    'persistedReplayMismatch',NaN,'replayPass',false,'failureReason',"");
end


function row = localNormalizationTemplate()
row = struct('actionId',"",'linkClass',"",'sender',NaN,'receiver',NaN, ...
    'informationRadius',NaN,'referenceSeed',NaN, ...
    'referenceRequestedCount',NaN,'referenceValidCount',0, ...
    'positionRadius_m',NaN,'velocityRadius_mps',NaN, ...
    'referenceAbsMedian',NaN,'referenceAbsIQR',NaN, ...
    'referenceAbsMinimum',NaN,'referenceAbsMaximum',NaN, ...
    'referenceRms',NaN,'referenceIqrScale',NaN, ...
    'normalizedByMedianAbs',NaN,'normalizedByRms',NaN, ...
    'normalizedByIqrScale',NaN,'persistedMedianDifference',NaN, ...
    'persistedNormalizationDifference',NaN,'failureReason',"");
end
