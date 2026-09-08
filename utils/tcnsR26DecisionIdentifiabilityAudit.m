function A = tcnsR26DecisionIdentifiabilityAudit(r2Directory)
%TCNSR26DECISIONIDENTIFIABILITYAUDIT Post-process the frozen R2 registry.
%
% This utility reconstructs only the deterministic affine matrices specified
% by the persisted R2 registry and verifies every reconstructed action catalog
% and rValue result against the frozen CSVs.  It runs no trajectory, scheduler,
% Monte Carlo trial, seed sweep, or graph search.

if nargin<1 || isempty(r2Directory)
    r2Directory = fullfile(projectRoot(),'results', ...
        'tcns_r2_generalization_validation', ...
        '2026-09-08_161130');
end
r2Directory = char(r2Directory);
registryPath = fullfile(r2Directory,'configuration_registry.csv');
actionPath = fullfile(r2Directory,'generalization_actions.csv');
senderPath = fullfile(r2Directory,'generalization_sender_multi_action.csv');
witnessPath = fullfile(r2Directory,'actual_witness_audit.csv');
for path = {registryPath,actionPath,senderPath,witnessPath}
    if ~isfile(path{1})
        error('tcnsR26DecisionIdentifiabilityAudit:MissingInput', ...
            'Frozen R2 input is missing: %s',path{1});
    end
end

registry = localRead(registryPath);
storedActions = localRead(actionPath);
storedSenders = localRead(senderPath);
witness = localRead(witnessPath);
referenceTolerance = 1e-10;
rows = repmat(localSenderTemplate(),0,1);

for k = 1:height(registry)
    frozen = registry(k,:);
    if ~frozen.admissible
        error('tcnsR26DecisionIdentifiabilityAudit:InadmissibleFrozenCell', ...
            'R2 cell %s is not admissible.',frozen.configurationId);
    end
    cfg = tcnsR2RegistryConfiguration(frozen.seed,frozen.N, ...
        frozen.graphId,frozen.pinId);
    model = tcnsInformationLimitsModel(cfg,frozen.H,frozen.D,0);
    catalog = tcnsInformationLimitsActionCatalog(model);
    expectedActions = storedActions( ...
        storedActions.configurationId==frozen.configurationId & ...
        storedActions.H==frozen.H & storedActions.D==frozen.D,:);
    if height(expectedActions)~=height(catalog) || ...
            any(expectedActions.actionId~=catalog.actionId)
        error('tcnsR26DecisionIdentifiabilityAudit:CatalogMismatch', ...
            'Reconstructed action catalog differs in cell %s, H=%d, D=%d.', ...
            frozen.configurationId,frozen.H,frozen.D);
    end

    senders = unique(catalog.sender,'stable');
    for s = reshape(senders,1,[])
        ids = find(catalog.sender==s);
        C = tcnsInformationLimitsSenderMap(model,s,[],0).currentMap;
        L = zeros(numel(ids),model.nState);
        for q = 1:numel(ids)
            action = catalog.actionMap{ids(q)};
            L(q,:) = (-2*action.successProbability/model.m* ...
                action.fullCrossTermCoefficient)';
        end
        decision = tcnsDecisionIdentifiability( ...
            C,L,[],referenceTolerance);
        stored = storedSenders( ...
            storedSenders.configurationId==frozen.configurationId & ...
            storedSenders.H==frozen.H & storedSenders.D==frozen.D & ...
            storedSenders.sender==s,:);
        if height(stored)~=1 || stored.actionCount~=numel(ids) || ...
                stored.missingRank~=decision.rValue
            error('tcnsR26DecisionIdentifiabilityAudit:StoredValueMismatch', ...
                'Frozen p/rValue mismatch in cell %s, H=%d, D=%d, sender=%d.', ...
                frozen.configurationId,frozen.H,frozen.D,s);
        end

        row = localSenderTemplate();
        row.sourceR2Run = string(r2Directory);
        row.configurationId = frozen.configurationId;
        row.N = frozen.N;
        row.graph = frozen.graphId;
        row.pinning = frozen.pinId;
        row.H = frozen.H;
        row.D = frozen.D;
        row.sender = s;
        row.p = numel(ids);
        row.rValue = decision.rValue;
        row.rRelative = decision.rRelative;
        row.strictReduction = decision.rRelative<decision.rValue;
        row.relativeRankRatio = decision.rRelative/decision.rValue;
        row.pairwiseHiddenDirections = decision.rRelative;
        row.fullRelativeIdentifiable = decision.fullRelativeIdentifiable;
        row.individualNonidentifiableCount = nnz( ...
            ~decision.individualIdentifiable);
        row.allIndividualValuesIdentifiable = all( ...
            decision.individualIdentifiable);
        row.orderingIdentifiableDespiteHiddenValues = numel(ids)>=2 && ...
            row.individualNonidentifiableCount>0 && ...
            decision.fullRelativeIdentifiable;
        row.nontrivialActionSet = numel(ids)>=2;
        row.relativeProjectionResidualMax = ...
            decision.maximumPairwiseNormalizedResidual;
        row.relativeProjectionResidualFro = norm( ...
            decision.LRelativeHidden,'fro')/max( ...
            norm(decision.LRelative,'fro'),eps);
        row.relativeBasisResiduals = localVectorString( ...
            decision.relativeBasisNormalizedResiduals);
        row.pairwiseProjectionResiduals = localPairwiseString( ...
            catalog.actionId(ids),decision.pairwiseNormalizedResiduals);
        row.valueHiddenSingularValues = localVectorString( ...
            decision.valueHiddenSingularValues);
        row.relativeHiddenSingularValues = localVectorString( ...
            decision.relativeHiddenSingularValues);
        row.storedRValueMatch = true;
        rows(end+1,1) = row; %#ok<AGROW>
    end
end

senderTable = struct2table(rows);
n5FrozenTable = senderTable( ...
    senderTable.configurationId=="N5_ring2_pin_even" & ...
    senderTable.H==25 & senderTable.D==4,:);
binaryWitnessTable = localBinaryWitnessTable(witness);

A.schemaVersion = 1;
A.studyClass = "FROZEN_R2_DECISION_IDENTIFIABILITY_POSTPROCESS";
A.sourceR2Directory = string(r2Directory);
A.referenceTolerance = referenceTolerance;
A.senderTable = senderTable;
A.n5FrozenTable = n5FrozenTable;
A.binaryWitnessTable = binaryWitnessTable;
A.noTrajectoriesGenerated = true;
A.noRegistryExpansion = true;
A.noSchedulerImplemented = true;
A.sharedMultiactionFiberEvaluated = false;
A.sharedMultiactionFiberReason = ...
    "Persisted witnesses use action-specific conditioned fibers; they cannot be combined into one sender-wise argmax fiber.";

end


function T = localBinaryWitnessTable(witness)

n = height(witness);
actionId = witness.actionId;
sender = witness.sender;
receiver = witness.receiver;
qMinus = witness.qMinus;
qPlus = witness.qPlus;
transmitCommonOptimal = qMinus>=0;
noTransmitCommonOptimal = qPlus<=0;
commonOptimalActionExistsOnWitnessPair = ...
    transmitCommonOptimal | noTransmitCommonOptimal;
strictlyAmbiguousOnWitnessPair = qMinus<0 & qPlus>0;
boundaryTieOnly = ~strictlyAmbiguousOnWitnessPair & ...
    (qMinus==0 | qPlus==0) & qMinus<=0 & qPlus>=0;
sourceWitnessRows = repmat("frozen R2 actual_witness_audit.csv",n,1);
T = table(actionId,sender,receiver,qMinus,qPlus, ...
    transmitCommonOptimal,noTransmitCommonOptimal, ...
    commonOptimalActionExistsOnWitnessPair,strictlyAmbiguousOnWitnessPair, ...
    boundaryTieOnly,sourceWitnessRows);

end


function T = localRead(path)

T = readtable(path,'Delimiter',',','ReadVariableNames',true, ...
    'TextType','string');

end


function value = localVectorString(x)

if isempty(x)
    value = "";
else
    value = strjoin(compose('%.17g',x(:)'),';');
end

end


function value = localPairwiseString(actionIds,residuals)

parts = strings(0,1);
for a = 1:numel(actionIds)
    for b = a+1:numel(actionIds)
        parts(end+1,1) = actionIds(a)+"-"+actionIds(b)+"="+ ...
            compose('%.17g',residuals(a,b)); %#ok<AGROW>
    end
end
value = strjoin(parts,';');

end


function row = localSenderTemplate()

row = struct('sourceR2Run',"",'configurationId',"",'N',NaN, ...
    'graph',"",'pinning',"",'H',NaN,'D',NaN,'sender',NaN,'p',NaN, ...
    'rValue',NaN,'rRelative',NaN,'strictReduction',false, ...
    'relativeRankRatio',NaN,'pairwiseHiddenDirections',NaN, ...
    'fullRelativeIdentifiable',false, ...
    'individualNonidentifiableCount',NaN, ...
    'allIndividualValuesIdentifiable',false, ...
    'orderingIdentifiableDespiteHiddenValues',false, ...
    'nontrivialActionSet',false,'relativeProjectionResidualMax',NaN, ...
    'relativeProjectionResidualFro',NaN,'relativeBasisResiduals',"", ...
    'pairwiseProjectionResiduals',"",'valueHiddenSingularValues',"", ...
    'relativeHiddenSingularValues',"",'storedRValueMatch',false);

end
