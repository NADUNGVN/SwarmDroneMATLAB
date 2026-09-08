function A = tcnsR1TheoryDepthAudit(model)
%TCNSR1THEORYDEPTHAUDIT Multi-action, rank-robustness and regret diagnostics.
%
% This is a theorem-validation utility.  It constructs no scheduler and
% consumes no held-out scenario trajectory.

relativeTolerance = [1e-6 1e-8 1e-10 1e-12 1e-14];
[actionCatalog,actionMaps] = localActionCatalog(model);
[senderTable,senderActionTable] = localSenderAudit( ...
    model,actionCatalog,actionMaps);
[rankTable,toleranceTable,spectrumTable] = localRankAudit( ...
    model,actionCatalog,actionMaps,relativeTolerance);

A.relativeTolerance = relativeTolerance;
A.actionCatalog = actionCatalog;
A.actionMaps = actionMaps;
A.senderTable = senderTable;
A.senderActionTable = senderActionTable;
A.rankTable = rankTable;
A.toleranceTable = toleranceTable;
A.spectrumTable = spectrumTable;

end


function [catalog,maps] = localActionCatalog(model)

count = model.nOrdinaryLinks+model.nPinnedLinks;
rows = repmat(struct('actionId',"",'linkClass',"", ...
    'receiver',NaN,'sender',NaN),count,1);
maps = cell(count,1);
q = 0;
for a = 1:model.nOrdinaryLinks
    q = q+1;
    i = model.edgeReceiver(a); j = model.edgeSender(a);
    payload.pos = [0 0 0]; payload.vel = [0 0 0];
    maps{q} = tcnsInformationLimitsActionMap( ...
        model,'ordinary',i,j,[1 0 0],payload);
    rows(q) = localActionRow("ordinary",i,j);
end
for a = 1:model.nPinnedLinks
    q = q+1;
    i = model.pinReceiver(a); j = 1;
    payload.pos = [0 0 0]; payload.vel = [0 0 0];
    payload.acc = [0 0 0];
    maps{q} = tcnsInformationLimitsActionMap( ...
        model,'pinned-leader',i,j,[1 0 0],payload);
    rows(q) = localActionRow("pinned-leader",i,j);
end
catalog = struct2table(rows);

end


function row = localActionRow(linkClass,receiver,sender)
row.actionId = sprintf('%s:%d->%d',linkClass,sender,receiver);
row.linkClass = linkClass;
row.receiver = receiver;
row.sender = sender;
end


function [senderTable,actionTable] = localSenderAudit(model,catalog,maps)

senders = unique(catalog.sender,'stable');
senderRows = repmat(struct('sender',NaN,'actionCount',NaN, ...
    'actionIds',"",'informationRank',NaN,'missingRank',NaN, ...
    'compressionRatio',NaN,'missingSingularValues',"", ...
    'minimumCoalitionSize',NaN,'minimumAdditionalAgents',NaN, ...
    'minimumCoalitions',"",'allAgentsIdentifyAllValues',false), ...
    numel(senders),1);
actionRows = repmat(struct('sender',NaN,'actionId',"", ...
    'missingRowNorm',NaN),height(catalog),1);
aq = 0;
for sj = 1:numel(senders)
    sender = senders(sj);
    ids = find(catalog.sender==sender);
    Csender = tcnsInformationLimitsSenderMap(model,sender,[],0).currentMap;
    L = zeros(numel(ids),model.nState);
    for a = 1:numel(ids)
        map = maps{ids(a)};
        L(a,:) = (-2*map.successProbability/model.m* ...
            map.fullCrossTermCoefficient)';
    end
    Cinfo = tcnsLinearIdentifiability(Csender,zeros(model.nState,1));
    projector = pinv(Csender,Cinfo.rankTolerance)*Csender;
    Lperp = L*(eye(model.nState)-projector);
    s = svd(Lperp,'econ');
    if isempty(s), sigmaMax = 0; else, sigmaMax = s(1); end
    tol = 1e-10*max(1,sigmaMax);
    missingRank = sum(s>tol);
    location = localMultiActionCoalition(model,sender,L);
    senderRows(sj).sender = sender;
    senderRows(sj).actionCount = numel(ids);
    senderRows(sj).actionIds = strjoin(catalog.actionId(ids),';');
    senderRows(sj).informationRank = rank(Csender, ...
        1e-10*max(1,norm(Csender,2)));
    senderRows(sj).missingRank = missingRank;
    senderRows(sj).compressionRatio = missingRank/numel(ids);
    senderRows(sj).missingSingularValues = localVectorString(s(s>tol));
    senderRows(sj).minimumCoalitionSize = location.minimumCoalitionSize;
    senderRows(sj).minimumAdditionalAgents = ...
        location.minimumCoalitionSize-1;
    senderRows(sj).minimumCoalitions = location.minimumCoalitions;
    senderRows(sj).allAgentsIdentifyAllValues = location.allAgentsCan;
    for a = 1:numel(ids)
        aq = aq+1;
        actionRows(aq).sender = sender;
        actionRows(aq).actionId = catalog.actionId(ids(a));
        actionRows(aq).missingRowNorm = norm(Lperp(a,:),2);
    end
end
senderTable = struct2table(senderRows);
actionTable = struct2table(actionRows(1:aq));

end


function location = localMultiActionCoalition(model,sender,L)

maps = cell(model.N,1);
for agent = 1:model.N
    maps{agent} = tcnsInformationLimitsSenderMap( ...
        model,agent,[],0).currentMap;
end
other = setdiff(1:model.N,sender,'stable');
minimumSize = NaN;
coalitions = strings(0,1);
for additional = 0:numel(other)
    if additional==0
        choices = zeros(1,0);
    else
        choices = nchoosek(other,additional);
    end
    if additional==0, choices = reshape(choices,1,0); end
    for q = 1:size(choices,1)
        ids = [sender choices(q,:)];
        C = zeros(0,model.nState);
        for agent = ids
            C = [C;maps{agent}]; %#ok<AGROW>
        end
        if localAllRowsIdentifiable(C,L)
            minimumSize = numel(ids);
            coalitions(end+1,1) = strjoin(string(ids),'+'); %#ok<AGROW>
        end
    end
    if ~isnan(minimumSize), break; end
end
Call = zeros(0,model.nState);
for agent = 1:model.N
    Call = [Call;maps{agent}]; %#ok<AGROW>
end
location.minimumCoalitionSize = minimumSize;
location.minimumCoalitions = strjoin(coalitions,';');
location.allAgentsCan = localAllRowsIdentifiable(Call,L);

end


function yes = localAllRowsIdentifiable(C,L)
yes = true;
for row = 1:size(L,1)
    if ~tcnsLinearIdentifiability(C,L(row,:)').identifiable
        yes = false;
        return;
    end
end
end


function [rankTable,toleranceTable,spectrumTable] = localRankAudit( ...
    model,catalog,maps,relativeTolerance)

rankRows = repmat(struct('actionId',"",'linkClass',"", ...
    'receiver',NaN,'sender',NaN,'reducedDimension',NaN, ...
    'historyLength',NaN,'referenceRank',NaN, ...
    'smallestRetainedSingularValue',NaN, ...
    'largestDiscardedSingularValue',NaN,'singularGapRatio',NaN, ...
    'augmentedRank',NaN,'augmentedAddedSingularValue',NaN, ...
    'doubleNormalizedResidual',NaN, ...
    'vpaDigits',80,'vpaNormalizedResidual',NaN, ...
    'relativeVpaDoubleDifference',NaN,'stableAcrossToleranceGrid',false), ...
    height(catalog),1);
tolRows = repmat(struct('actionId',"",'relativeTolerance',NaN, ...
    'numericRank',NaN,'normalizedResidual',NaN, ...
    'identifiable',false),height(catalog)*numel(relativeTolerance),1);
spectrumRows = repmat(struct('actionId',"",'matrix',"", ...
    'index',NaN,'singularValue',NaN), ...
    height(catalog)*2*model.nState,1);
tq = 0; sq = 0;
for a = 1:height(catalog)
    action = maps{a};
    Lhistory = numel(action.keepIndex)-1;
    senderMap = tcnsInformationLimitsSenderMap( ...
        model,catalog.sender(a),action,Lhistory);
    ell = (senderMap.reducedDynamics^Lhistory)'* ...
        action.crossTermCoefficient;
    C = senderMap.historyMap;
    base = tcnsLinearIdentifiability(C,ell);
    s = svd(C,'econ');
    sAug = svd([C;ell'],'econ');
    retained = s(1:base.rank);
    if base.rank<numel(s)
        largestDiscarded = s(base.rank+1);
    else
        largestDiscarded = 0;
    end
    if largestDiscarded==0
        gap = Inf;
    else
        gap = retained(end)/largestDiscarded;
    end
    augmentedRank = sum(sAug>base.rankTolerance);
    if augmentedRank>base.rank
        addedSingular = sAug(augmentedRank);
    else
        addedSingular = 0;
    end
    vpaResidual = localVpaProjectionResidual(C,ell,base.rank,80);
    stable = true;
    for t = 1:numel(relativeTolerance)
        tq = tq+1;
        factor = relativeTolerance(t);
        absoluteTolerance = factor*max(1,s(1));
        numericRank = sum(s>absoluteTolerance);
        projector = pinv(C,absoluteTolerance)*C;
        residual = norm((eye(numel(ell))-projector)*ell,2)/ ...
            max(norm(ell,2),eps);
        identifiable = residual<=absoluteTolerance;
        tolRows(tq).actionId = catalog.actionId(a);
        tolRows(tq).relativeTolerance = factor;
        tolRows(tq).numericRank = numericRank;
        tolRows(tq).normalizedResidual = residual;
        tolRows(tq).identifiable = identifiable;
        stable = stable && ~identifiable;
    end
    for k = 1:numel(s)
        sq = sq+1;
        spectrumRows(sq).actionId = catalog.actionId(a);
        spectrumRows(sq).matrix = "information";
        spectrumRows(sq).index = k;
        spectrumRows(sq).singularValue = s(k);
    end
    for k = 1:numel(sAug)
        sq = sq+1;
        spectrumRows(sq).actionId = catalog.actionId(a);
        spectrumRows(sq).matrix = "information-plus-value";
        spectrumRows(sq).index = k;
        spectrumRows(sq).singularValue = sAug(k);
    end
    rankRows(a).actionId = catalog.actionId(a);
    rankRows(a).linkClass = catalog.linkClass(a);
    rankRows(a).receiver = catalog.receiver(a);
    rankRows(a).sender = catalog.sender(a);
    rankRows(a).reducedDimension = numel(ell);
    rankRows(a).historyLength = Lhistory;
    rankRows(a).referenceRank = base.rank;
    rankRows(a).smallestRetainedSingularValue = retained(end);
    rankRows(a).largestDiscardedSingularValue = largestDiscarded;
    rankRows(a).singularGapRatio = gap;
    rankRows(a).augmentedRank = augmentedRank;
    rankRows(a).augmentedAddedSingularValue = addedSingular;
    rankRows(a).doubleNormalizedResidual = ...
        base.normalizedRowSpaceResidual;
    rankRows(a).vpaNormalizedResidual = vpaResidual;
    rankRows(a).relativeVpaDoubleDifference = abs( ...
        vpaResidual-base.normalizedRowSpaceResidual)/ ...
        max(vpaResidual,eps);
    rankRows(a).stableAcrossToleranceGrid = stable;
end
rankTable = struct2table(rankRows);
toleranceTable = struct2table(tolRows(1:tq));
spectrumTable = struct2table(spectrumRows(1:sq));

end


function normalizedResidual = localVpaProjectionResidual(C,ell,r,digitCount)

s = svd(C,'econ');
absoluteTolerance = 1e-10*max(1,s(1));
[~,R,p] = qr(C','vector');
diagonal = abs(diag(R));
qrRank = sum(diagonal>absoluteTolerance);
if qrRank~=r
    error('tcnsR1TheoryDepthAudit:RowBasis', ...
        'Pivoted-QR rank %d differs from SVD rank %d.',qrRank,r);
end
B = C(p(1:r),:);
oldDigits = digits;
cleanup = onCleanup(@() digits(oldDigits)); %#ok<NASGU>
digits(digitCount);
Bv = vpa(B,digitCount);
ellv = vpa(ell,digitCount);
alpha = (Bv*Bv.')\(Bv*ellv);
residual = ellv-Bv.'*alpha;
normalizedResidual = double(sqrt(residual.'*residual)/ ...
    sqrt(ellv.'*ellv));

end


function value = localVectorString(x)
if isempty(x)
    value = "";
else
    value = strjoin(compose('%.17g',x(:)'),';');
end
end

