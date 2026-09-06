%% EXP13_DEVELOPMENT Equal-budget baselines, ablations and sensitivity.
%
% Development seeds only.  The protocol and matrix are preregistered in
% docs/EXP13_DEVELOPMENT_PLAN.md.  This script may select an EXP14 candidate,
% but it never permits a method-superiority claim.

startup;
close all;

expRun = startExperiment('exp13_development', ...
    ['Development-only shared-medium frontiers, mechanism ablations, ' ...
    'sensitivity and contention boundaries; no superiority claim.']);

fprintf('EXP13 status: DEVELOPMENT ONLY; holdout remains unopened.\n');

runScriptIsolated('test_shared_medium_infrastructure');
runScriptIsolated('test_causal_broadcast_policy');
runScriptIsolated('test_shared_medium_end_to_end');
runScriptIsolated('test_exp13_policy_contracts');
contractTestsPassed = true;

developmentSeeds = 13013001:13013004;
sensitivitySeeds = developmentSeeds(1:3);
scenarioNames = {'Clean','Moderate','Stressed'};
scenarioLoss = [0.00 0.10 0.30];

fprintf('\nDeclared development seeds: %s\n',mat2str(developmentSeeds));
fprintf('No EXP14 seed is accessed by this script.\n');


%% 1. Equal-budget frontiers

families = frontierFamilies();
nFrontier = numel(developmentSeeds)*numel(scenarioNames)* ...
    numel(families)*5;
frontierRows = repmat(emptyRow(),nFrontier,1);
kRun = 0;

fprintf('\n[1/4] Equal-budget frontiers: %d runs\n',nFrontier);
for iSeed = 1:numel(developmentSeeds)
    for iScenario = 1:numel(scenarioNames)
        for iFamily = 1:numel(families)
            f = families(iFamily);
            for iPoint = 1:numel(f.values)
                cfg = study2SharedMediumConfig();
                cfg.net.seed = developmentSeeds(iSeed);
                cfg.mac.residualLoss = scenarioLoss(iScenario);
                cfg = applyFrontierPoint(cfg,f.id,f.values(iPoint));

                kRun = kRun+1;
                frontierRows(kRun) = runCell(cfg,f.method, ...
                    'frontier',f.label,sprintf('%s-%d',f.id,iPoint), ...
                    scenarioNames{iScenario},iPoint,f.values(iPoint));
                printProgress(kRun,nFrontier,20);
            end
        end
    end
end
frontier = struct2table(frontierRows);
writetable(frontier,fullfile(expRun.dir,'frontier.csv'));
frontierSummary = summarizeRows(frontier,{'scenario','family','pointIndex'});
writetable(frontierSummary,fullfile(expRun.dir,'frontier_summary.csv'));


%% 2. Mechanism ablation

mechanisms = mechanismArms();
nMechanism = numel(developmentSeeds)*numel(scenarioNames)*numel(mechanisms);
mechanismRows = repmat(emptyRow(),nMechanism,1);
kRun = 0;

fprintf('\n[2/4] Mechanism ablation: %d runs\n',nMechanism);
for iSeed = 1:numel(developmentSeeds)
    for iScenario = 1:numel(scenarioNames)
        for iArm = 1:numel(mechanisms)
            a = mechanisms(iArm);
            cfg = study2SharedMediumConfig();
            cfg.net.seed = developmentSeeds(iSeed);
            cfg.mac.residualLoss = scenarioLoss(iScenario);
            cfg.shared.feedbackMode = a.feedbackMode;

            kRun = kRun+1;
            mechanismRows(kRun) = runCell(cfg,a.method, ...
                'mechanism',a.label,a.id,scenarioNames{iScenario},iArm,NaN);
            printProgress(kRun,nMechanism,15);
        end
    end
end
mechanism = struct2table(mechanismRows);
writetable(mechanism,fullfile(expRun.dir,'mechanism.csv'));
mechanismSummary = summarizeRows(mechanism,{'scenario','family'});
writetable(mechanismSummary,fullfile(expRun.dir,'mechanism_summary.csv'));


%% 3. Deterministic Latin-hypercube sensitivity

[lhsDesign,lhsStrata] = makeSensitivityDesign();
writetable(lhsDesign,fullfile(expRun.dir,'lhs_design.csv'));
nSensitivity = numel(sensitivitySeeds)*height(lhsDesign);
sensitivityRows = repmat(emptyRow(),nSensitivity,1);
kRun = 0;

fprintf('\n[3/4] Trigger sensitivity: %d runs\n',nSensitivity);
for iSeed = 1:numel(sensitivitySeeds)
    for iDesign = 1:height(lhsDesign)
        cfg = study2SharedMediumConfig();
        cfg.net.seed = sensitivitySeeds(iSeed);
        cfg.mac.residualLoss = 0.10;
        cfg = applySensitivityPoint(cfg,lhsDesign(iDesign,:));

        kRun = kRun+1;
        sensitivityRows(kRun) = runCell(cfg,'causal-broadcast', ...
            'sensitivity','Causal-Broadcast', ...
            sprintf('design-%02d',lhsDesign.designIndex(iDesign)), ...
            'Moderate',lhsDesign.designIndex(iDesign),NaN);
        printProgress(kRun,nSensitivity,13);
    end
end
sensitivity = struct2table(sensitivityRows);
writetable(sensitivity,fullfile(expRun.dir,'sensitivity.csv'));
[selection,selectedDesign] = selectSensitivity(sensitivity,lhsDesign);
writetable(selection,fullfile(expRun.dir,'selection.csv'));
writeJson(fullfile(expRun.dir,'selected_development_config.json'), ...
    table2struct(selectedDesign));


%% 4. Contention, background load and finite history

contentionArms = makeContentionArms();
contentionMethods = struct( ...
    'method',{'periodic','causal-broadcast'}, ...
    'label',{'Periodic-P10','Causal-Broadcast'});
nContention = numel(developmentSeeds)*numel(contentionArms)* ...
    numel(contentionMethods);
contentionRows = repmat(emptyRow(),nContention,1);
kRun = 0;

fprintf('\n[4/4] Contention and memory boundaries: %d runs\n',nContention);
for iSeed = 1:numel(developmentSeeds)
    for iArm = 1:numel(contentionArms)
        a = contentionArms(iArm);
        for iMethod = 1:numel(contentionMethods)
            cfg = study2SharedMediumConfig();
            cfg.net.seed = developmentSeeds(iSeed);
            cfg.mac.type = a.macType;
            cfg.mac.pAccess = a.pAccess;
            cfg.mac.backgroundLoad = a.backgroundLoad;
            cfg.mac.residualLoss = a.residualLoss;
            cfg.mac.historySize = a.historySize;
            cfg.mac.ackDeadline = a.ackDeadline;

            kRun = kRun+1;
            contentionRows(kRun) = runCell(cfg, ...
                contentionMethods(iMethod).method,'contention', ...
                contentionMethods(iMethod).label,a.id,a.scenario, ...
                iArm,a.pAccess);
            printProgress(kRun,nContention,18);
        end
    end
end
contention = struct2table(contentionRows);
writetable(contention,fullfile(expRun.dir,'contention.csv'));
contentionSummary = summarizeRows(contention,{'arm','family'});
writetable(contentionSummary,fullfile(expRun.dir,'contention_summary.csv'));


%% Declared machine gates

allRows = [frontier; mechanism; sensitivity; contention];
gateName = cell(0,1);
gatePassed = false(0,1);
gateDetail = cell(0,1);

[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'contract_tests',contractTestsPassed, ...
    '23 kernel + 7 trigger + 8 end-to-end + 21 EXP13 checks');

matrixComplete = height(frontier)==360 && height(mechanism)==60 && ...
    height(sensitivity)==39 && height(contention)==72;
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'matrix_completeness',matrixComplete, ...
    sprintf('frontier=%d mechanism=%d sensitivity=%d contention=%d', ...
    height(frontier),height(mechanism),height(sensitivity),height(contention)));

finiteOutputs = all(isfinite(allRows.RMSE)) && ...
    all(isfinite(allRows.MINSEP)) && all(isfinite(allRows.MEAN_TRUE_AOI));
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'finite_outputs',finiteOutputs, ...
    'formation, separation and true-age outputs are finite');

usesFeedback = ~strcmp(allRows.feedbackMode,'none');
causalOk = all(allRows.INVARIANT_VIOLATIONS==0) && ...
    all(allRows.MEAN_EST_AOI(usesFeedback) >= ...
    allRows.MEAN_TRUE_AOI(usesFeedback)-1e-12) && ...
    all(isnan(allRows.MEAN_EST_AOI(~usesFeedback)));
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'causal_conservatism',causalOk, ...
    sprintf('%d total protocol violations',sum(allRows.INVARIANT_VIOLATIONS)));

boundedMemory = all(allRows.MAX_QUEUE<=4) && ...
    all(allRows.MAX_HISTORY<=allRows.historySize);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'bounded_memory',boundedMemory, ...
    sprintf('max queue=%d; max history=%d', ...
    max(allRows.MAX_QUEUE),max(allRows.MAX_HISTORY)));

accountingOk = all(allRows.DATA_RECIPIENT_SUCCESS+ ...
    allRows.DATA_RECIPIENT_LOSS==allRows.DATA_RECIPIENT_ATTEMPTS) && ...
    all(allRows.CHANNEL_UTIL<=allRows.OFFERED_UTIL+ ...
    allRows.BACKGROUND_UTIL+1e-12) && all(allRows.CHANNEL_UTIL<=1+1e-12);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'physical_accounting',accountingOk, ...
    'recipient outcomes close and busy-time union includes external occupancy');

crnOk = true;
for seed = developmentSeeds
    crnOk = crnOk && isscalar(unique( ...
        allRows.TRACE_HASH_EXACT(allRows.seed==seed)));
end
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'paired_absolute_trace',crnOk, ...
    'one trace hash per development seed across every matrix');

noFeedbackOk = all(allRows.ACK_ATTEMPTED(~usesFeedback)==0);
frontierCausal = ~ismember(frontier.method,{'periodic','state-event'});
causalConfirmationOk = all(frontier.ACK_ENTRIES_DELIVERED(frontierCausal)>0);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'feedback_information_constraint', ...
    noFeedbackOk && causalConfirmationOk, ...
    'non-feedback arms emit no ACK; causal frontier cells confirm feedback');

standalone = strcmp(mechanism.arm,'broadcast-standalone');
piggyback = strcmp(mechanism.arm,'broadcast-piggyback');
hybrid = strcmp(mechanism.arm,'broadcast-hybrid');
feedbackAblationOk = ...
    all(mechanism.ACK_ENTRIES_PIGGYBACKED(standalone)==0) && ...
    all(mechanism.ACK_STANDALONE(standalone)>0) && ...
    all(mechanism.ACK_STANDALONE(piggyback)==0) && ...
    all(mechanism.ACK_ENTRIES_PIGGYBACKED(piggyback)>0) && ...
    all(mechanism.ACK_STANDALONE(hybrid)>0) && ...
    all(mechanism.ACK_ENTRIES_PIGGYBACKED(hybrid)>0);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'feedback_ablation_semantics', ...
    feedbackAblationOk,'standalone, piggyback and hybrid traffic are separated');

unicastDominatesFrames = pairedUnicastFrameGate(mechanism);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'unicast_physical_frame_order', ...
    unicastDominatesFrames, ...
    'unicast generates no fewer physical DATA frames than paired hybrid broadcast');

lhsOk = lhsStrataAreComplete(lhsStrata);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'lhs_strata',lhsOk, ...
    '12 points occupy each of nine strata exactly once');

primaryContention = strcmp(contention.arm,'csma-p020');
loadedContention = ismember(contention.arm,{'csma-bg010','csma-bg030'});
backgroundOk = all(contention.BACKGROUND_BUSY_TIME(primaryContention)==0) && ...
    all(contention.BACKGROUND_BUSY_TIME(loadedContention)>0);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'background_load_exercised',backgroundOk, ...
    'zero-load arm is inert and both external-load arms occupy airtime');

historyStress = strcmp(contention.arm,'history-stress') & ...
    strcmp(contention.method,'causal-broadcast');
historyBoundary = any(contention.EXPIRED_HISTORY_ACK(historyStress)>0 | ...
    contention.STALE_ACK_DISCARDED(historyStress)>0);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'finite_history_boundary',historyBoundary, ...
    sprintf('expired=%d stale=%d', ...
    sum(contention.EXPIRED_HISTORY_ACK(historyStress)), ...
    sum(contention.STALE_ACK_DISCARDED(historyStress))));

selectionOk = selectedByDeclaredRule(selection,selectedDesign.designIndex);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'declared_selection_rule',selectionOk, ...
    sprintf('selected development design %d',selectedDesign.designIndex));

gates = table(gateName,double(gatePassed),gateDetail, ...
    'VariableNames',{'gate','passed','detail'});
writetable(gates,fullfile(expRun.dir,'gates.csv'));

verdict = struct();
verdict.status = ternary(all(gatePassed),'PASS','FAIL');
verdict.gatesPassed = nnz(gatePassed);
verdict.gatesTotal = numel(gatePassed);
verdict.totalDevelopmentRuns = height(allRows);
verdict.selectedDesignIndex = selectedDesign.designIndex;
verdict.policyClaimPermitted = false;
verdict.holdoutOpened = false;
verdict.note = ['EXP13 may freeze an EXP14 candidate only. Frontier and ' ...
    'ablation contrasts are development observations.'];
writeJson(fullfile(expRun.dir,'verdict.json'),verdict);

manifest = struct();
manifest.status = 'development-only';
manifest.preregistration = 'docs/EXP13_DEVELOPMENT_PLAN.md';
manifest.developmentSeeds = developmentSeeds;
manifest.sensitivitySeeds = sensitivitySeeds;
manifest.scenarioNames = scenarioNames;
manifest.scenarioLoss = scenarioLoss;
manifest.primaryPAccess = 0.2;
manifest.frontierPointsPerFamily = 5;
manifest.totalRuns = height(allRows);
manifest.holdoutSeedRange = 'not assigned and not accessed';
writeJson(fullfile(expRun.dir,'development_manifest.json'),manifest);

fprintf('\nEXP13 machine gates\n');
for k = 1:height(gates)
    fprintf('  [%-4s] %-32s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        gates.gate{k},gates.detail{k});
end
fprintf('\nEXP13 VERDICT: %s (%d/%d gates)\n', ...
    verdict.status,verdict.gatesPassed,verdict.gatesTotal);
fprintf('Selected development design: %d\n',verdict.selectedDesignIndex);
fprintf('Policy superiority claim permitted: NO\n');
fprintf('Holdout opened: NO\n');

makeFrontierFigure(frontierSummary);
makeMechanismFigure(mechanismSummary);
makeSensitivityFigure(selection);
makeContentionFigure(contentionSummary);
saveAllFigures(expRun);

save(fullfile(expRun.dir,'workspace.mat'), ...
    'frontier','frontierSummary','mechanism','mechanismSummary', ...
    'sensitivity','lhsDesign','lhsStrata','selection','selectedDesign', ...
    'contention','contentionSummary','gates','verdict','manifest');
finishExperiment(expRun);

if ~all(gatePassed)
    error('exp13_development: %d of %d gates failed.', ...
        nnz(~gatePassed),numel(gatePassed));
end


function families = frontierFamilies()

families = struct( ...
    'id',{'periodic','state','aoi','aoci','belief','proposed'}, ...
    'label',{'Periodic','State-event','Causal AoI-only', ...
    'AoCI-inspired','Delayed-ACK belief','Causal-Broadcast'}, ...
    'method',{'periodic','state-event','causal-aoi-only', ...
    'causal-aoci','delayed-ack-belief','causal-broadcast'}, ...
    'values',{[5 10 12.5 20 25],[0.5 0.75 1 1.5 2], ...
    [0.06 0.09 0.12 0.18 0.24],[0.5 0.75 1 1.5 2], ...
    [0.06 0.09 0.12 0.18 0.24],[0.5 0.75 1 1.5 2]});

end


function cfg = applyFrontierPoint(cfg,id,value)

switch id
    case 'periodic'
        cfg.net.commPeriod = 1/value;
    case 'state'
        cfg.event.posThreshold = 0.05*value;
        cfg.event.velThreshold = 0.10*value;
    case 'aoi'
        cfg.aoiEvent.aoiThreshold = value;
    case 'aoci'
        cfg.shared.aociRiskThreshold = value;
    case 'belief'
        cfg.shared.beliefAgeThreshold = value;
    case 'proposed'
        cfg.aoiEvent.posThreshold = 0.05*value;
        cfg.aoiEvent.velThreshold = 0.10*value;
    otherwise
        error('exp13_development: unknown frontier id %s.',id);
end

end


function arms = mechanismArms()

arms = struct( ...
    'id',{'causal-unicast','broadcast-data-only','broadcast-standalone', ...
    'broadcast-piggyback','broadcast-hybrid'}, ...
    'label',{'Causal unicast + standalone ACK','Broadcast DATA only', ...
    'Broadcast + standalone ACK','Broadcast + piggyback ACK', ...
    'Full Causal-Broadcast'}, ...
    'method',{'causal-unicast','state-event','causal-broadcast', ...
    'causal-broadcast','causal-broadcast'}, ...
    'feedbackMode',{'standalone','none','standalone','piggyback','hybrid'});

end


function [design,strata] = makeSensitivityDesign()

names = {'posThreshold','velThreshold','aoiThreshold','maxSilence', ...
    'minInterTx','aoiMinInterTx','scaleBase','scaleMin','adaptRange'};
lowerBound = [0.03 0.06 0.08 0.25 0.02 0.04 0.35 0.10 0.50];
upperBound = [0.08 0.16 0.24 0.80 0.08 0.20 0.75 0.30 2.00];
[u,strata] = deterministicLatinHypercube(12,numel(names),13013000);
x = lowerBound + u.*(upperBound-lowerBound);
x(:,4:6) = round(x(:,4:6)/0.02)*0.02;

base = study2SharedMediumConfig();
defaultPoint = [base.aoiEvent.posThreshold,base.aoiEvent.velThreshold, ...
    base.aoiEvent.aoiThreshold,base.aoiEvent.maxSilence, ...
    base.aoiEvent.minInterTx,base.aoiEvent.aoiMinInterTx, ...
    base.aoiEvent.aoiStateScaleBase,base.aoiEvent.aoiStateScaleMin, ...
    base.aoiEvent.aoiAdaptRange];
x = [defaultPoint; x];
designIndex = (0:12)';
isDefault = [1; zeros(12,1)];
design = array2table([designIndex,isDefault,x], ...
    'VariableNames',[{'designIndex','isDefault'},names]);

end


function cfg = applySensitivityPoint(cfg,row)

cfg.aoiEvent.posThreshold = row.posThreshold;
cfg.aoiEvent.velThreshold = row.velThreshold;
cfg.aoiEvent.aoiThreshold = row.aoiThreshold;
cfg.aoiEvent.maxSilence = row.maxSilence;
cfg.aoiEvent.minInterTx = row.minInterTx;
cfg.aoiEvent.aoiMinInterTx = row.aoiMinInterTx;
cfg.aoiEvent.aoiStateScaleBase = row.scaleBase;
cfg.aoiEvent.aoiStateScaleMin = row.scaleMin;
cfg.aoiEvent.aoiAdaptRange = row.adaptRange;

end


function arms = makeContentionArms()

base = study2SharedMediumConfig();
id = {'csma-p010','csma-p020','csma-p040','csma-p100', ...
    'aloha-p020','tdma-reference','csma-bg010','csma-bg030', ...
    'history-stress'};
macType = {'csma','csma','csma','csma','aloha','tdma', ...
    'csma','csma','csma'};
p = [0.1 0.2 0.4 1.0 0.2 0.2 0.2 0.2 0.2];
bg = [0 0 0 0 0 0 0.1 0.3 0];
loss = [0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.3];
history = [repmat(base.mac.historySize,1,8) 2];
deadline = [repmat(base.mac.ackDeadline,1,8) 0.5];
scenario = [repmat({'Moderate'},1,8) {'History-Stress'}];

arms = struct('id',id,'macType',macType, ...
    'pAccess',num2cell(p),'backgroundLoad',num2cell(bg), ...
    'residualLoss',num2cell(loss),'historySize',num2cell(history), ...
    'ackDeadline',num2cell(deadline),'scenario',scenario);

end


function row = runCell(cfg,method,stage,family,arm,scenario,pointIndex,value)

out = simSwarmSharedMedium(cfg,method);
M = computeSharedMediumMetrics(out,cfg);

row = emptyRow();
row.stage = stage;
row.seed = cfg.net.seed;
row.scenario = scenario;
row.residualLoss = cfg.mac.residualLoss;
row.family = family;
row.arm = arm;
row.pointIndex = pointIndex;
row.parameterValue = value;
row.method = method;
row.feedbackMode = out.feedbackMode;
row.macType = cfg.mac.type;
row.pAccess = cfg.mac.pAccess;
row.backgroundLoad = cfg.mac.backgroundLoad;
row.historySize = cfg.mac.historySize;
row.ackDeadline = cfg.mac.ackDeadline;
row.posThreshold = cfg.aoiEvent.posThreshold;
row.velThreshold = cfg.aoiEvent.velThreshold;
row.aoiThreshold = cfg.aoiEvent.aoiThreshold;
row.maxSilence = cfg.aoiEvent.maxSilence;
row.minInterTx = cfg.aoiEvent.minInterTx;
row.aoiMinInterTx = cfg.aoiEvent.aoiMinInterTx;
row.scaleBase = cfg.aoiEvent.aoiStateScaleBase;
row.scaleMin = cfg.aoiEvent.aoiStateScaleMin;
row.adaptRange = cfg.aoiEvent.aoiAdaptRange;
row.RMSE = M.formationRMSE;
row.MINSEP = M.minSeparationEval;
row.SAFEFAIL = double(M.safeFailure);
row.MEAN_TRUE_AOI = M.meanTrueAoI;
row.P95_TRUE_AOI = M.p95TrueAoI;
row.P99_TRUE_AOI = M.p99TrueAoI;
row.MEAN_EST_AOI = M.meanEstimatedAoI;
row.MEAN_AOI_GAP = M.meanAoIGap;
row.DATA_GENERATED = M.dataFramesGenerated;
row.DATA_ATTEMPTED = M.dataFramesAttempted;
row.DATA_DELIVERED = M.dataFramesDeliveredAny;
row.ACK_ATTEMPTED = M.ackFramesAttempted;
row.ACK_ENTRIES_DELIVERED = M.ackEntriesDelivered;
row.DATA_RECIPIENT_ATTEMPTS = M.dataRecipientAttempts;
row.DATA_RECIPIENT_SUCCESS = M.dataRecipientSuccess;
row.DATA_RECIPIENT_LOSS = M.dataRecipientLoss;
row.COLLISION_FRAMES = M.collisionFrames;
row.COLLISION_RATE = M.collisionRate;
row.QUEUE_DROPS = M.queueDrops;
row.SUPERSEDED = M.supersededBeforeService;
row.RETRIES = M.retryFrames;
row.OBSOLETE_RETRY_DROPS = M.obsoleteRetryDrops;
row.MAX_QUEUE = M.maxQueueDepth;
row.MAX_HISTORY = M.maxHistoryDepth;
row.STALE_DATA_DISCARDED = M.staleDataDiscarded;
row.STALE_ACK_DISCARDED = M.staleAckDiscarded;
row.EXPIRED_HISTORY_ACK = M.expiredHistoryAckCount;
row.ACK_BEFORE_ACCEPT = M.ackBeforeAcceptCount;
row.ACK_STANDALONE = M.ackFramesStandalone;
row.ACK_ENTRIES_PIGGYBACKED = M.ackEntriesPiggybacked;
row.ACK_ENTRIES_TRANSFERRED = M.ackEntriesTransferred;
row.CHANNEL_UTIL = M.channelUtilization;
row.OFFERED_UTIL = M.offeredAirtimeUtilization;
row.DATA_AIRTIME = M.dataAirtime;
row.ACK_AIRTIME = M.ackAirtime;
row.PIGGYBACK_AIRTIME = M.piggybackOverheadAirtime;
row.BACKGROUND_BUSY_TIME = M.backgroundBusyTime;
row.BACKGROUND_UTIL = M.backgroundBusyTime/max(cfg.swarm.T,eps);
row.BACKGROUND_COLLISION_FRAMES = M.backgroundCollisionFrames;
row.ENERGY_PROXY_J = M.energyProxyJ;
row.DATA_GOODPUT_HZ = M.dataFrameGoodputHz;
row.RECIPIENT_GOODPUT_HZ = M.dataRecipientGoodputHz;
row.ACK_GOODPUT_HZ = M.ackGoodputHz;
row.MEAN_ACCESS_DELAY = M.meanAccessDelay;
row.P95_ACCESS_DELAY = M.p95AccessDelay;
row.MEAN_CONFIRM_DELAY = M.meanConfirmationDelay;
row.P95_CONFIRM_DELAY = M.p95ConfirmationDelay;
row.JAIN_FRAME_GOODPUT = M.jainFrameGoodput;
row.NETWORK_RUNTIME_SEC = M.networkRuntimeSec;
row.INVARIANT_VIOLATIONS = M.invariantViolations;
row.TRACE_HASH_EXACT = out.traceHashExact;
row.BELIEF_UPDATES = out.belief.updateCount;

end


function row = emptyRow()

row = struct( ...
    'stage','','seed',0,'scenario','','residualLoss',NaN, ...
    'family','','arm','','pointIndex',NaN,'parameterValue',NaN, ...
    'method','','feedbackMode','','macType','','pAccess',NaN, ...
    'backgroundLoad',NaN,'historySize',NaN,'ackDeadline',NaN, ...
    'posThreshold',NaN,'velThreshold',NaN,'aoiThreshold',NaN, ...
    'maxSilence',NaN,'minInterTx',NaN,'aoiMinInterTx',NaN, ...
    'scaleBase',NaN,'scaleMin',NaN,'adaptRange',NaN, ...
    'RMSE',NaN,'MINSEP',NaN,'SAFEFAIL',NaN, ...
    'MEAN_TRUE_AOI',NaN,'P95_TRUE_AOI',NaN,'P99_TRUE_AOI',NaN, ...
    'MEAN_EST_AOI',NaN,'MEAN_AOI_GAP',NaN, ...
    'DATA_GENERATED',NaN,'DATA_ATTEMPTED',NaN,'DATA_DELIVERED',NaN, ...
    'ACK_ATTEMPTED',NaN,'ACK_ENTRIES_DELIVERED',NaN, ...
    'DATA_RECIPIENT_ATTEMPTS',NaN,'DATA_RECIPIENT_SUCCESS',NaN, ...
    'DATA_RECIPIENT_LOSS',NaN,'COLLISION_FRAMES',NaN, ...
    'COLLISION_RATE',NaN,'QUEUE_DROPS',NaN,'SUPERSEDED',NaN, ...
    'RETRIES',NaN,'OBSOLETE_RETRY_DROPS',NaN, ...
    'MAX_QUEUE',NaN,'MAX_HISTORY',NaN, ...
    'STALE_DATA_DISCARDED',NaN,'STALE_ACK_DISCARDED',NaN, ...
    'EXPIRED_HISTORY_ACK',NaN,'ACK_BEFORE_ACCEPT',NaN, ...
    'ACK_STANDALONE',NaN,'ACK_ENTRIES_PIGGYBACKED',NaN, ...
    'ACK_ENTRIES_TRANSFERRED',NaN,'CHANNEL_UTIL',NaN, ...
    'OFFERED_UTIL',NaN,'DATA_AIRTIME',NaN,'ACK_AIRTIME',NaN, ...
    'PIGGYBACK_AIRTIME',NaN,'BACKGROUND_BUSY_TIME',NaN, ...
    'BACKGROUND_UTIL',NaN,'BACKGROUND_COLLISION_FRAMES',NaN, ...
    'ENERGY_PROXY_J',NaN,'DATA_GOODPUT_HZ',NaN, ...
    'RECIPIENT_GOODPUT_HZ',NaN,'ACK_GOODPUT_HZ',NaN, ...
    'MEAN_ACCESS_DELAY',NaN,'P95_ACCESS_DELAY',NaN, ...
    'MEAN_CONFIRM_DELAY',NaN,'P95_CONFIRM_DELAY',NaN, ...
    'JAIN_FRAME_GOODPUT',NaN,'NETWORK_RUNTIME_SEC',NaN, ...
    'INVARIANT_VIOLATIONS',NaN,'TRACE_HASH_EXACT',NaN, ...
    'BELIEF_UPDATES',NaN);

end


function summary = summarizeRows(T,groupNames)

[G,summary] = findgroups(T(:,groupNames));
summary.meanRMSE = splitapply(@mean,T.RMSE,G);
summary.maxRMSE = splitapply(@max,T.RMSE,G);
summary.safeFailures = splitapply(@sum,T.SAFEFAIL,G);
summary.meanTrueAoI = splitapply(@mean,T.MEAN_TRUE_AOI,G);
summary.meanEstimatedAoI = splitapply(@mean,T.MEAN_EST_AOI,G);
summary.meanOfferedUtil = splitapply(@mean,T.OFFERED_UTIL,G);
summary.meanChannelUtil = splitapply(@mean,T.CHANNEL_UTIL,G);
summary.meanDataFrames = splitapply(@mean,T.DATA_ATTEMPTED,G);
summary.meanAckFrames = splitapply(@mean,T.ACK_ATTEMPTED,G);
summary.meanEnergyProxyJ = splitapply(@mean,T.ENERGY_PROXY_J,G);

end


function [selection,selectedDesign] = selectSensitivity(T,design)

ids = unique(T.pointIndex,'sorted');
n = numel(ids);
safeFailures = zeros(n,1);
worstRMSE = zeros(n,1);
worstOfferedUtil = zeros(n,1);
for k = 1:n
    idx = T.pointIndex==ids(k);
    safeFailures(k) = sum(T.SAFEFAIL(idx));
    worstRMSE(k) = max(T.RMSE(idx));
    worstOfferedUtil(k) = max(T.OFFERED_UTIL(idx));
end

minFailures = min(safeFailures);
feasible = safeFailures==minFailures;
bestRMSE = min(worstRMSE(feasible));
withinFivePercent = feasible & worstRMSE<=1.05*bestRMSE+1e-12;
bestUtil = min(worstOfferedUtil(withinFivePercent));
eligible = withinFivePercent & ...
    worstOfferedUtil<=bestUtil+1e-12;
selectedIndex = min(ids(eligible));
selected = ids==selectedIndex;

selection = table(ids,safeFailures,worstRMSE,worstOfferedUtil, ...
    double(feasible),double(withinFivePercent),double(selected), ...
    'VariableNames',{'designIndex','safeFailures','worstRMSE', ...
    'worstOfferedUtil','minimumFailureSet','withinFivePercent', ...
    'selected'});
selectedDesign = design(design.designIndex==selectedIndex,:);

end


function ok = selectedByDeclaredRule(selection,selectedIndex)

minFailures = min(selection.safeFailures);
feasible = selection.safeFailures==minFailures;
bestRMSE = min(selection.worstRMSE(feasible));
within = feasible & selection.worstRMSE<=1.05*bestRMSE+1e-12;
bestUtil = min(selection.worstOfferedUtil(within));
eligible = within & selection.worstOfferedUtil<=bestUtil+1e-12;
expected = min(selection.designIndex(eligible));
ok = isscalar(selectedIndex) && selectedIndex==expected && ...
    nnz(selection.selected)==1;

end


function ok = pairedUnicastFrameGate(T)

ok = true;
for seed = unique(T.seed)'
    scenarios = unique(T.scenario(T.seed==seed));
    for k = 1:numel(scenarios)
        base = T.seed==seed & strcmp(T.scenario,scenarios{k});
        u = T.DATA_GENERATED(base & strcmp(T.arm,'causal-unicast'));
        b = T.DATA_GENERATED(base & strcmp(T.arm,'broadcast-hybrid'));
        ok = ok && isscalar(u) && isscalar(b) && u>=b;
    end
end

end


function ok = lhsStrataAreComplete(strata)

n = size(strata,1);
ok = all(sort(strata,1)==repmat((1:n)',1,size(strata,2)),'all');

end


function [names,passed,details] = addGate( ...
    names,passed,details,name,flag,detail)

names{end+1,1} = name;
passed(end+1,1) = logical(flag);
details{end+1,1} = detail;

end


function printProgress(k,n,stride)

if mod(k,stride)==0 || k==n
    fprintf('  completed %3d / %3d runs\n',k,n);
end

end


function writeJson(path,value)

fid = fopen(path,'w');
if fid < 0
    error('exp13_development: cannot write %s.',path);
end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y = ternary(flag,a,b)

if flag, y=a; else, y=b; end

end


function makeFrontierFigure(S)

figure('Name','EXP13 equal-budget frontiers','Color','w', ...
    'Position',[80 80 1250 390]);
scenarios = unique(S.scenario,'stable');
families = unique(S.family,'stable');
colors = lines(numel(families));
tiledlayout(1,numel(scenarios),'TileSpacing','compact','Padding','compact');
for i = 1:numel(scenarios)
    nexttile; hold on;
    for j = 1:numel(families)
        idx = strcmp(S.scenario,scenarios{i}) & strcmp(S.family,families{j});
        plot(S.meanOfferedUtil(idx),S.meanRMSE(idx),'-o', ...
            'LineWidth',1.2,'Color',colors(j,:), ...
            'DisplayName',families{j});
    end
    grid on; xlabel('offered airtime utilization'); ylabel('formation RMSE [m]');
    title(scenarios{i});
    if i==1, legend('Location','best'); end
end

end


function makeMechanismFigure(S)

figure('Name','EXP13 mechanism ablation','Color','w', ...
    'Position',[100 100 1150 470]);
moderate = strcmp(S.scenario,'Moderate');
labels = S.family(moderate);
X = categorical(labels,unique(labels,'stable'));
yyaxis left;
bar(X,S.meanRMSE(moderate)); ylabel('formation RMSE [m]');
yyaxis right;
plot(X,S.meanOfferedUtil(moderate),'ko-','LineWidth',1.3); 
ylabel('offered airtime utilization'); grid on;
title('Mechanism ablation — Moderate development cell');

end


function makeSensitivityFigure(S)

figure('Name','EXP13 sensitivity selection','Color','w', ...
    'Position',[120 120 820 520]);
scatter(S.worstRMSE,S.worstOfferedUtil,55,S.safeFailures,'filled');
hold on;
sel = S.selected==1;
plot(S.worstRMSE(sel),S.worstOfferedUtil(sel),'kp', ...
    'MarkerSize',15,'LineWidth',1.8);
grid on; xlabel('worst-seed RMSE [m]');
ylabel('worst-seed offered airtime utilization');
cb = colorbar; cb.Label.String='separation-failure count';
title('LHS development selection (star = frozen candidate)');

end


function makeContentionFigure(S)

figure('Name','EXP13 contention boundaries','Color','w', ...
    'Position',[140 140 1180 500]);
families = unique(S.family,'stable');
arms = unique(S.arm,'stable');
Y = nan(numel(arms),numel(families));
for i = 1:numel(arms)
    for j = 1:numel(families)
        idx = strcmp(S.arm,arms{i}) & strcmp(S.family,families{j});
        Y(i,j) = S.meanRMSE(idx);
    end
end
bar(categorical(arms,arms),Y);
grid on; ylabel('formation RMSE [m]');
legend(families,'Location','northwest');
title('Contention, external load and finite-history boundaries');

end
