function R = tcnsR2GeneralizationAudit(options)
%TCNSR2GENERALIZATIONAUDIT Cross-instance information-structure audit.
%
% This routine implements the preregistered TCNS R2 structural study.  Its
% unit correction is a structural value functional, not a claim that the
% correction occurs on a simulated trajectory.  No stochastic trajectory,
% held-out seed, or scheduling policy is used.

if nargin<1, options = struct(); end
options = localOptions(options);

registryRows = repmat(localRegistryTemplate(),0,1);
actionRows = repmat(localActionTemplate(),0,1);
toleranceRows = repmat(localToleranceTemplate(),0,1);
senderRows = repmat(localSenderTemplate(),0,1);
vpaRows = repmat(localVpaTemplate(),0,1);

for nIndex = 1:numel(options.NValues)
    N = options.NValues(nIndex);
    for graphIndex = 1:numel(options.graphIds)
        graphId = string(options.graphIds(graphIndex));
        for pinIndex = 1:numel(options.pinIds)
            pinId = string(options.pinIds(pinIndex));
            cfg = localConfiguration(options.seed,N,graphId,pinId);
            configurationId = sprintf('N%d_%s_pin_%s',N,graphId,pinId);
            try
                baseModel = tcnsInformationLimitsModel(cfg, ...
                    options.HValues(1),options.DValues(1),0);
                baseCatalog = tcnsInformationLimitsActionCatalog(baseModel);
                geometry = localInformationGeometry( ...
                    baseModel,baseCatalog,options.toleranceGrid, ...
                    options.referenceTolerance);
                admissible = true;
                scopeFailure = "NONE";
            catch exception
                admissible = false;
                scopeFailure = string(exception.identifier)+": "+ ...
                    string(exception.message);
                baseCatalog = table();
                geometry = {};
            end

            for hIndex = 1:numel(options.HValues)
                H = options.HValues(hIndex);
                for dIndex = 1:numel(options.DValues)
                    D = options.DValues(dIndex);
                    registryRow = localRegistryTemplate();
                    registryRow.configurationId = string(configurationId);
                    registryRow.N = N;
                    registryRow.graphId = graphId;
                    registryRow.pinId = pinId;
                    registryRow.H = H;
                    registryRow.D = D;
                    registryRow.seed = options.seed;
                    registryRow.admissible = admissible;
                    registryRow.failureReason = scopeFailure;
                    if ~admissible
                        registryRows(end+1,1) = registryRow; %#ok<AGROW>
                        continue;
                    end

                    try
                        model = tcnsInformationLimitsModel(cfg,H,D,0);
                        catalog = tcnsInformationLimitsActionCatalog(model);
                        localAssertCatalogIdentity(baseCatalog,catalog);
                        [cellActions,cellTolerance] = localActionAudit( ...
                            model,catalog,geometry,configurationId,graphId, ...
                            pinId,H,D,options);
                        cellSenders = localSenderAudit(model,catalog, ...
                            configurationId,graphId,pinId,H,D,options);
                        [cellActions,cellVpa] = localHighPrecisionAudit( ...
                            cellActions,model,catalog,geometry, ...
                            configurationId,graphId,pinId,H,D,options);
                        cellActions = localAttachSenderResults( ...
                            cellActions,cellSenders);
                        registryRow.actionCount = height(catalog);
                        registryRow.senderCount = height(cellSenders);
                        registryRow.allActionsToleranceStable = all( ...
                            [cellActions.toleranceStable]);
                        registryRow.allCompressedDirectAgree = all( ...
                            [cellActions.compressedDirectAgree]);
                        registryRow.allAgentsIdentifyAllValues = all( ...
                            [cellSenders.allAgentsIdentifyAllValues]);
                        if ~registryRow.allAgentsIdentifyAllValues
                            registryRow.failureReason = ...
                                "FULL_COALITION_DOES_NOT_IDENTIFY";
                        end
                        actionRows = [actionRows;cellActions]; %#ok<AGROW>
                        toleranceRows = [toleranceRows;cellTolerance]; %#ok<AGROW>
                        senderRows = [senderRows;cellSenders]; %#ok<AGROW>
                        vpaRows = [vpaRows;cellVpa]; %#ok<AGROW>
                    catch exception
                        registryRow.admissible = false;
                        registryRow.failureReason = string(exception.identifier)+ ...
                            ": "+string(exception.message);
                    end
                    registryRows(end+1,1) = registryRow; %#ok<AGROW>
                end
            end
        end
    end
end

R.schemaVersion = 1;
R.studyClass = "NEW_TCNS_R2_THEORY_GENERALIZATION";
R.options = options;
R.registryTable = struct2table(registryRows);
R.actionTable = struct2table(actionRows);
R.toleranceTable = struct2table(toleranceRows);
R.senderTable = struct2table(senderRows);
R.vpaTable = struct2table(vpaRows);
R.noSchedulerImplemented = true;
R.noHeldOutSeedsUsed = true;
R.structuralUnitCorrectionOnly = true;

end


function options = localOptions(options)

defaults.NValues = [5 7 9];
defaults.graphIds = ["ring2" "sparse4" "geometric"];
defaults.pinIds = ["even" "odd"];
defaults.HValues = [15 25];
defaults.DValues = [2 4];
defaults.seed = 27022001;
defaults.toleranceGrid = [1e-6 1e-8 1e-10 1e-12 1e-14];
defaults.referenceTolerance = 1e-10;
defaults.vpaDigits = 80;
defaults.enableVpa = true;
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(options,names{k}) || isempty(options.(names{k}))
        options.(names{k}) = defaults.(names{k});
    end
end
options.NValues = double(options.NValues(:)');
options.graphIds = string(options.graphIds(:)');
options.pinIds = string(options.pinIds(:)');
options.HValues = double(options.HValues(:)');
options.DValues = double(options.DValues(:)');
options.toleranceGrid = double(options.toleranceGrid(:)');
if ~any(options.toleranceGrid==options.referenceTolerance)
    error('tcnsR2GeneralizationAudit:ReferenceTolerance', ...
        'referenceTolerance must occur in toleranceGrid.');
end

end


function cfg = localConfiguration(seed,N,graphId,pinId)

[cfg,~] = tcnsGate6Scenario(seed,'S1');
cfg = applyTopologyConfig(cfg,N,char(graphId));
cfg.swarm.normalizeConsensusDegree = false;
cfg.swarm.Kp = 1.8;
cfg.swarm.Kv = 2.2;
cfg.swarm.KpLeader = 1.5;
cfg.swarm.KvLeader = 1.8;
pin = zeros(N,1);
switch pinId
    case "even"
        pin(2:2:N) = 1;
    case "odd"
        pin(3:2:N) = 1;
    otherwise
        error('tcnsR2GeneralizationAudit:PinRegistry', ...
            'Unknown pin registry entry %s.',pinId);
end
cfg.swarm.pin = pin;

end


function geometry = localInformationGeometry(model,catalog,toleranceGrid,referenceTolerance)

geometry = cell(height(catalog),1);
cache = containers.Map('KeyType','char','ValueType','any');
for a = 1:height(catalog)
    action = catalog.actionMap{a};
    historyLength = model.nState-numel(action.targetIndex)-1;
    key = sprintf('%d_%d',catalog.sender(a),historyLength);
    if isKey(cache,key)
        base = cache(key);
    else
        senderMap = tcnsInformationLimitsSenderMap( ...
            model,catalog.sender(a),[],historyLength);
        C = senderMap.historyMap;
        [~,S,V] = svd(C,'econ');
        singularValues = diag(S);
        base.C = C;
        base.V = V;
        base.singularValues = singularValues;
        cache(key) = base;
    end
    T = zeros(numel(action.targetIndex),model.nState);
    for q = 1:numel(action.targetIndex)
        T(q,action.targetIndex(q)) = 1;
    end
    G.historyLength = historyLength;
    G.targetSelector = T;
    G.conditionedMap = [base.C;T];
    G.nullBases = cell(numel(toleranceGrid),1);
    G.numericRanks = zeros(numel(toleranceGrid),1);
    for t = 1:numel(toleranceGrid)
        relativeTolerance = toleranceGrid(t);
        if isempty(base.singularValues), sigma = 0; else, sigma = base.singularValues(1); end
        baseRank = sum(base.singularValues>relativeTolerance*max(1,sigma));
        Nbase = base.V(:,baseRank+1:end);
        if isempty(Nbase)
            Nconditioned = zeros(model.nState,0);
        else
            M = T*Nbase;
            [~,Sm,Vm] = svd(M);
            sm = diag(Sm);
            if isempty(sm), sigmaM = 0; else, sigmaM = sm(1); end
            targetRank = sum(sm>relativeTolerance*max(1,sigmaM));
            Nconditioned = Nbase*Vm(:,targetRank+1:end);
        end
        G.nullBases{t} = Nconditioned;
        G.numericRanks(t) = model.nState-size(Nconditioned,2);
    end
    referenceIndex = find(toleranceGrid==referenceTolerance,1);
    G.nullBasis = G.nullBases{referenceIndex};
    [~,Sd,Vd] = svd(G.conditionedMap,'econ');
    sd = diag(Sd);
    if isempty(sd), sigmaD = 0; else, sigmaD = sd(1); end
    G.directRank = sum(sd>referenceTolerance*max(1,sigmaD));
    G.directNullBasis = Vd(:,G.directRank+1:end);
    G.conditionedSingularValues = sd;
    geometry{a} = G;
end

end


function [rows,toleranceRows] = localActionAudit(model,catalog,geometry, ...
    configurationId,graphId,pinId,H,D,options)

rows = repmat(localActionTemplate(),height(catalog),1);
toleranceRows = repmat(localToleranceTemplate(), ...
    height(catalog)*numel(options.toleranceGrid),1);
tq = 0;
for a = 1:height(catalog)
    action = catalog.actionMap{a};
    G = geometry{a};
    coefficient = -2*action.successProbability/model.m* ...
        action.fullCrossTermCoefficient;
    ell = (model.holdA3^G.historyLength)'*coefficient;
    coefficientNorm = max(norm(ell,2),eps);
    residuals = zeros(numel(options.toleranceGrid),1);
    identifiable = false(numel(options.toleranceGrid),1);
    for t = 1:numel(options.toleranceGrid)
        relativeTolerance = options.toleranceGrid(t);
        nullBasis = G.nullBases{t};
        residuals(t) = norm(nullBasis'*ell,2)/coefficientNorm;
        identifiable(t) = residuals(t)<=relativeTolerance;
        tq = tq+1;
        toleranceRows(tq) = localToleranceTemplate();
        toleranceRows(tq).configurationId = string(configurationId);
        toleranceRows(tq).N = model.N;
        toleranceRows(tq).graphId = graphId;
        toleranceRows(tq).pinId = pinId;
        toleranceRows(tq).H = H;
        toleranceRows(tq).D = D;
        toleranceRows(tq).actionId = catalog.actionId(a);
        toleranceRows(tq).relativeTolerance = relativeTolerance;
        toleranceRows(tq).historyRank = G.numericRanks(t);
        toleranceRows(tq).historyNullity = model.nState-G.numericRanks(t);
        toleranceRows(tq).normalizedRowSpaceResidual = residuals(t);
        toleranceRows(tq).identifiable = identifiable(t);
    end
    referenceIndex = find(options.toleranceGrid==options.referenceTolerance,1);
    directResidual = norm(G.directNullBasis'*ell,2)/coefficientNorm;
    rowBasis = VectorsForRowSpace(G);
    augmentedSmall = [rowBasis';ell'/coefficientNorm];
    sAug = svd(augmentedSmall,'econ');
    augmentedRank = sum(sAug>options.referenceTolerance*max(1,sAug(1)));
    refRank = G.numericRanks(referenceIndex);
    row = localActionTemplate();
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
    row.structuralCorrection = "[1 0 0]";
    row.historyLength = G.historyLength;
    row.historyRank = refRank;
    row.historyNullity = model.nState-refRank;
    row.normalizedRowSpaceResidual = residuals(referenceIndex);
    row.directNormalizedResidual = directResidual;
    row.identifiable = identifiable(referenceIndex);
    row.toleranceStable = all(identifiable==identifiable(referenceIndex));
    row.numericRankStable = all(G.numericRanks==refRank);
    row.compressedDirectAgree = abs(directResidual-residuals(referenceIndex)) ...
        <=1e-9*max(1,directResidual);
    row.augmentedRank = augmentedRank;
    row.augmentedRankIncrease = augmentedRank-refRank;
    row.conditionedSingularValues = localVectorString( ...
        G.conditionedSingularValues);
    row.vpaAttempted = false;
    row.vpaNormalizedResidual = NaN;
    row.vpaFailure = "NOT_SELECTED";
    rows(a) = row;
end

end


function Q = VectorsForRowSpace(G)

[~,~,V] = svd(G.conditionedMap,'econ');
Q = V(:,1:G.directRank);

end


function rows = localSenderAudit(model,catalog,configurationId,graphId, ...
    pinId,H,D,options)

senders = unique(catalog.sender,'stable');
rows = repmat(localSenderTemplate(),numel(senders),1);
agentMaps = cell(model.N,1);
for agent = 1:model.N
    agentMaps{agent} = tcnsInformationLimitsSenderMap( ...
        model,agent,[],0).currentMap;
end
for q = 1:numel(senders)
    sender = senders(q);
    ids = find(catalog.sender==sender);
    L = zeros(numel(ids),model.nState);
    for a = 1:numel(ids)
        action = catalog.actionMap{ids(a)};
        L(a,:) = (-2*action.successProbability/model.m* ...
            action.fullCrossTermCoefficient)';
    end
    C = agentMaps{sender};
    [~,Sc,Vc] = svd(C,'econ');
    sc = diag(Sc);
    if isempty(sc), sigmaC = 0; else, sigmaC = sc(1); end
    rankC = sum(sc>options.referenceTolerance*max(1,sigmaC));
    Qc = Vc(:,1:rankC);
    Lperp = L*(eye(model.nState)-Qc*Qc');
    missingSingularValues = svd(Lperp,'econ');
    if isempty(missingSingularValues)
        sigmaMissing = 0;
    else
        sigmaMissing = missingSingularValues(1);
    end
    missingRank = sum(missingSingularValues> ...
        options.referenceTolerance*max(1,sigmaMissing));
    coalition = localCoalition(agentMaps,sender,L,options.referenceTolerance);
    row = localSenderTemplate();
    row.configurationId = string(configurationId);
    row.N = model.N;
    row.graphId = graphId;
    row.pinId = pinId;
    row.H = H;
    row.D = D;
    row.sender = sender;
    row.actionCount = numel(ids);
    row.actionIds = strjoin(catalog.actionId(ids),';');
    row.senderInformationRank = rankC;
    row.missingRank = missingRank;
    row.compressionRatio = missingRank/numel(ids);
    row.missingSingularValues = localVectorString(missingSingularValues);
    row.minimumCoalitionSize = coalition.minimumSize;
    row.minimumCoalitions = coalition.minimumCoalitions;
    row.allAgentsIdentifyAllValues = coalition.allAgentsIdentify;
    rows(q) = row;
end

end


function result = localCoalition(agentMaps,sender,L,relativeTolerance)

N = numel(agentMaps);
other = setdiff(1:N,sender,'stable');
minimumSize = NaN;
coalitions = strings(0,1);
for additional = 0:numel(other)
    if additional==0
        choices = zeros(1,0);
    else
        choices = nchoosek(other,additional);
    end
    for q = 1:size(choices,1)
        members = [sender choices(q,:)];
        C = vertcat(agentMaps{members});
        if localAllRowsIdentifiable(C,L,relativeTolerance)
            minimumSize = numel(members);
            coalitions(end+1,1) = strjoin(string(members),'+'); %#ok<AGROW>
        end
    end
    if isfinite(minimumSize), break; end
end
Call = vertcat(agentMaps{:});
result.minimumSize = minimumSize;
result.minimumCoalitions = strjoin(coalitions,';');
result.allAgentsIdentify = localAllRowsIdentifiable(Call,L,relativeTolerance);

end


function yes = localAllRowsIdentifiable(C,L,relativeTolerance)

[~,S,V] = svd(C,'econ');
s = diag(S);
if isempty(s), sigma = 0; else, sigma = s(1); end
r = sum(s>relativeTolerance*max(1,sigma));
N = V(:,r+1:end);
denominator = max(vecnorm(L,2,2),eps);
residual = vecnorm(L*N,2,2)./denominator;
yes = all(residual<=relativeTolerance);

end


function [rows,vpaRows] = localHighPrecisionAudit(rows,model,catalog,geometry, ...
    configurationId,graphId,pinId,H,D,options)

vpaRows = repmat(localVpaTemplate(),0,1);
if ~options.enableVpa, return; end
residuals = [rows.normalizedRowSpaceResidual];
selected = unique([find(residuals==min(residuals),1) find(residuals<1e-6)]);
for a = selected
    row = localVpaTemplate();
    row.configurationId = string(configurationId);
    row.N = model.N;
    row.graphId = graphId;
    row.pinId = pinId;
    row.H = H;
    row.D = D;
    row.actionId = catalog.actionId(a);
    row.digits = options.vpaDigits;
    rows(a).vpaAttempted = true;
    action = catalog.actionMap{a};
    G = geometry{a};
    coefficient = -2*action.successProbability/model.m* ...
        action.fullCrossTermCoefficient;
    ell = (model.holdA3^G.historyLength)'*coefficient;
    try
        value = localVpaResidual(G.conditionedMap,ell, ...
            options.referenceTolerance,options.vpaDigits);
        row.normalizedResidual = value;
        row.failureReason = "NONE";
        rows(a).vpaNormalizedResidual = value;
        rows(a).vpaFailure = "NONE";
    catch exception
        row.normalizedResidual = NaN;
        row.failureReason = string(exception.identifier)+": "+ ...
            string(exception.message);
        rows(a).vpaNormalizedResidual = NaN;
        rows(a).vpaFailure = row.failureReason;
    end
    vpaRows(end+1,1) = row; %#ok<AGROW>
end

end


function residual = localVpaResidual(C,ell,relativeTolerance,digitCount)

s = svd(C,'econ');
if isempty(s), sigma = 0; else, sigma = s(1); end
r = sum(s>relativeTolerance*max(1,sigma));
[~,R,p] = qr(C','vector');
diagonal = abs(diag(R));
qrRank = sum(diagonal>relativeTolerance*max(1,sigma));
if qrRank~=r
    error('tcnsR2GeneralizationAudit:VpaBasis', ...
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


function rows = localAttachSenderResults(rows,senderRows)

for a = 1:numel(rows)
    q = find([senderRows.sender]==rows(a).sender,1);
    rows(a).senderActionCount = senderRows(q).actionCount;
    rows(a).senderMissingRank = senderRows(q).missingRank;
    rows(a).senderCompressionRatio = senderRows(q).compressionRatio;
    rows(a).minimumCoalitionSize = senderRows(q).minimumCoalitionSize;
    rows(a).allAgentsIdentifyAllValues = ...
        senderRows(q).allAgentsIdentifyAllValues;
end

end


function localAssertCatalogIdentity(left,right)

if height(left)~=height(right) || any(left.actionId~=right.actionId) || ...
        any(left.sender~=right.sender) || any(left.receiver~=right.receiver)
    error('tcnsR2GeneralizationAudit:ActionCatalogChanged', ...
        'The action catalog changed across H/D within one configuration.');
end

end


function value = localVectorString(x)

if isempty(x)
    value = "";
else
    value = strjoin(compose('%.17g',x(:)'),';');
end

end


function row = localRegistryTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'seed',NaN,'admissible',false,'actionCount',0, ...
    'senderCount',0,'allActionsToleranceStable',false, ...
    'allCompressedDirectAgree',false,'allAgentsIdentifyAllValues',false, ...
    'failureReason',"");
end


function row = localActionTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'actionId',"",'linkClass',"",'sender',NaN, ...
    'receiver',NaN,'structuralCorrection',"",'historyLength',NaN, ...
    'historyRank',NaN,'historyNullity',NaN, ...
    'normalizedRowSpaceResidual',NaN,'directNormalizedResidual',NaN, ...
    'identifiable',false,'toleranceStable',false,'numericRankStable',false, ...
    'compressedDirectAgree',false,'augmentedRank',NaN, ...
    'augmentedRankIncrease',NaN,'conditionedSingularValues',"", ...
    'senderActionCount',NaN,'senderMissingRank',NaN, ...
    'senderCompressionRatio',NaN,'minimumCoalitionSize',NaN, ...
    'allAgentsIdentifyAllValues',false,'vpaAttempted',false, ...
    'vpaNormalizedResidual',NaN,'vpaFailure',"");
end


function row = localToleranceTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'actionId',"",'relativeTolerance',NaN, ...
    'historyRank',NaN,'historyNullity',NaN, ...
    'normalizedRowSpaceResidual',NaN,'identifiable',false);
end


function row = localSenderTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'sender',NaN,'actionCount',NaN,'actionIds',"", ...
    'senderInformationRank',NaN,'missingRank',NaN,'compressionRatio',NaN, ...
    'missingSingularValues',"",'minimumCoalitionSize',NaN, ...
    'minimumCoalitions',"",'allAgentsIdentifyAllValues',false);
end


function row = localVpaTemplate()
row = struct('configurationId',"",'N',NaN,'graphId',"",'pinId',"", ...
    'H',NaN,'D',NaN,'actionId',"",'digits',NaN, ...
    'normalizedResidual',NaN,'failureReason',"");
end
