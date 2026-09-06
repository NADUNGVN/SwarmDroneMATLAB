%% EXP12_SHARED_MEDIUM_DIAGNOSTIC Infrastructure-only end-to-end validation.
%
% Development seeds only.  This script does not rank policies and does not
% support a performance-superiority claim.  Its job is to falsify protocol,
% accounting, boundedness, CRN and collision-domain assumptions before EXP13.

startup;
close all;

expRun = startExperiment('exp12_shared_medium_diagnostic', ...
    'Development-only shared-medium integration diagnostic; no method claim.');

fprintf('EXP12 status: infrastructure diagnostic, not a policy benchmark.\n');

% Fail fast on deterministic contracts before spending simulation time.
runScriptIsolated('test_shared_medium_infrastructure');
runScriptIsolated('test_causal_broadcast_policy');
runScriptIsolated('test_shared_medium_end_to_end');
microTestsPassed = true;

developmentSeeds = 12012001:12012003;
pValues = [0.10 0.20 0.40 1.00];
methodIds = {'periodic','state-event','causal-broadcast'};
methodLabels = {'Periodic-P10','State-event','Causal-Broadcast'};

scenarioNames = {'Clean','Moderate','Stressed'};
scenarioResidualLoss = [0.00 0.10 0.30];

nRun = numel(developmentSeeds)*numel(scenarioNames)* ...
    numel(pValues)*numel(methodIds);
rows = repmat(emptyRow(),nRun,1);
rowIndex = 0;
traceOut = [];

fprintf('\nDiagnostic matrix: %d runs\n',nRun);
fprintf('  development seeds : %d..%d\n', ...
    developmentSeeds(1),developmentSeeds(end));
fprintf('  p values          : %s\n',mat2str(pValues));
fprintf('  residual loss     : %s\n',mat2str(scenarioResidualLoss));

for iSeed = 1:numel(developmentSeeds)
    for iScenario = 1:numel(scenarioNames)
        for iP = 1:numel(pValues)
            for iMethod = 1:numel(methodIds)
                rowIndex = rowIndex+1;

                cfg = study2SharedMediumConfig();
                cfg.net.seed = developmentSeeds(iSeed);
                cfg.mac.pAccess = pValues(iP);
                cfg.mac.residualLoss = scenarioResidualLoss(iScenario);

                out = simSwarmSharedMedium(cfg,methodIds{iMethod});
                M = computeSharedMediumMetrics(out,cfg);

                r = emptyRow();
                r.seed = cfg.net.seed;
                r.scenario = scenarioNames{iScenario};
                r.residualLoss = cfg.mac.residualLoss;
                r.pAccess = cfg.mac.pAccess;
                r.method = methodLabels{iMethod};
                r.thetaTagged = cfg.mac.pAccess*(1-cfg.mac.pAccess)^(cfg.swarm.N-1);
                r.RMSE = M.formationRMSE;
                r.MINSEP = M.minSeparationEval;
                r.SAFEFAIL = double(M.safeFailure);
                r.MEAN_TRUE_AOI = M.meanTrueAoI;
                r.P95_TRUE_AOI = M.p95TrueAoI;
                r.P99_TRUE_AOI = M.p99TrueAoI;
                r.MEAN_EST_AOI = M.meanEstimatedAoI;
                r.MEAN_AOI_GAP = M.meanAoIGap;
                r.DATA_GENERATED = M.dataFramesGenerated;
                r.DATA_ATTEMPTED = M.dataFramesAttempted;
                r.DATA_DELIVERED = M.dataFramesDeliveredAny;
                r.ACK_ATTEMPTED = M.ackFramesAttempted;
                r.ACK_ENTRIES_DELIVERED = M.ackEntriesDelivered;
                r.DATA_RECIPIENT_ATTEMPTS = M.dataRecipientAttempts;
                r.DATA_RECIPIENT_SUCCESS = M.dataRecipientSuccess;
                r.DATA_RECIPIENT_LOSS = M.dataRecipientLoss;
                r.COLLISION_FRAMES = M.collisionFrames;
                r.COLLISION_RATE = M.collisionRate;
                r.QUEUE_DROPS = M.queueDrops;
                r.SUPERSEDED = M.supersededBeforeService;
                r.RETRIES = M.retryFrames;
                r.OBSOLETE_RETRY_DROPS = M.obsoleteRetryDrops;
                r.MAX_QUEUE = M.maxQueueDepth;
                r.MAX_HISTORY = M.maxHistoryDepth;
                r.STALE_DATA_DISCARDED = M.staleDataDiscarded;
                r.STALE_ACK_DISCARDED = M.staleAckDiscarded;
                r.EXPIRED_HISTORY_ACK = M.expiredHistoryAckCount;
                r.ACK_BEFORE_ACCEPT = M.ackBeforeAcceptCount;
                r.ACK_STANDALONE = M.ackFramesStandalone;
                r.ACK_ENTRIES_PIGGYBACKED = M.ackEntriesPiggybacked;
                r.ACK_ENTRIES_TRANSFERRED = M.ackEntriesTransferred;
                r.ACK_RECIPIENT_ATTEMPTS = M.ackRecipientAttempts;
                r.ACK_RECIPIENT_SUCCESS = M.ackRecipientSuccess;
                r.ACK_RECIPIENT_LOSS = M.ackRecipientLoss;
                r.CHANNEL_UTIL = M.channelUtilization;
                r.OFFERED_UTIL = M.offeredAirtimeUtilization;
                r.DATA_AIRTIME = M.dataAirtime;
                r.ACK_AIRTIME = M.ackAirtime;
                r.PIGGYBACK_AIRTIME = M.piggybackOverheadAirtime;
                r.ENERGY_PROXY_J = M.energyProxyJ;
                r.DATA_GOODPUT_HZ = M.dataFrameGoodputHz;
                r.RECIPIENT_GOODPUT_HZ = M.dataRecipientGoodputHz;
                r.ACK_GOODPUT_HZ = M.ackGoodputHz;
                r.MEAN_ACCESS_DELAY = M.meanAccessDelay;
                r.P95_ACCESS_DELAY = M.p95AccessDelay;
                r.MEAN_ONEWAY_DELAY = M.meanOneWayDelay;
                r.P95_ONEWAY_DELAY = M.p95OneWayDelay;
                r.MEAN_CONFIRM_DELAY = M.meanConfirmationDelay;
                r.P95_CONFIRM_DELAY = M.p95ConfirmationDelay;
                r.JAIN_FRAME_GOODPUT = M.jainFrameGoodput;
                r.NETWORK_RUNTIME_SEC = M.networkRuntimeSec;
                r.INVARIANT_VIOLATIONS = M.invariantViolations;
                r.TRACE_HASH_EXACT = out.traceHashExact;
                rows(rowIndex) = r;

                if iSeed==1 && iScenario==2 && iP==2 && iMethod==3
                    traceOut = out;
                end

                if mod(rowIndex,12)==0 || rowIndex==nRun
                    fprintf('  completed %3d / %3d runs\n',rowIndex,nRun);
                end
            end
        end
    end
end

tidy = struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));

baseCfg = study2SharedMediumConfig();
manifest = struct();
manifest.status = 'development-only';
manifest.claimScope = 'infrastructure diagnostics; no policy superiority';
manifest.developmentSeeds = developmentSeeds;
manifest.pValues = pValues;
manifest.scenarioNames = scenarioNames;
manifest.scenarioResidualLoss = scenarioResidualLoss;
manifest.methodIds = methodIds;
manifest.baseMac = sharedMediumConfig(baseCfg);
manifest.primaryPSource = 'p=1/(c+1)=1/5 for c=4';
writeJson(fullfile(expRun.dir,'diagnostic_config.json'),manifest);

% ------------------------------------------------------------
% Declared diagnostic gates
% ------------------------------------------------------------

gateName = {};
gatePassed = false(0,1);
gateDetail = {};

[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'micro_contracts',microTestsPassed, ...
    '23 kernel + 7 policy + 8 end-to-end checks executed before matrix');
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'causal_invariants', ...
    all(tidy.INVARIANT_VIOLATIONS==0), ...
    sprintf('%d total violations',sum(tidy.INVARIANT_VIOLATIONS)));

isCausal = strcmp(tidy.method,'Causal-Broadcast');
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'confirmed_age_conservative', ...
    all(tidy.MEAN_EST_AOI(isCausal)>=tidy.MEAN_TRUE_AOI(isCausal)-1e-12) && ...
    all(isnan(tidy.MEAN_EST_AOI(~isCausal))), ...
    'confirmed age dominates true AoI only where feedback belief exists');
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'finite_outputs', ...
    all(isfinite(tidy.RMSE)) && all(isfinite(tidy.MINSEP)) && ...
    all(isfinite(tidy.MEAN_TRUE_AOI)), ...
    'RMSE, separation and true-AoI finite in every development cell');
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'bounded_queue', ...
    all(tidy.MAX_QUEUE<=baseCfg.mac.queueCapacity), ...
    sprintf('max observed %d / capacity %d', ...
    max(tidy.MAX_QUEUE),baseCfg.mac.queueCapacity));
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'bounded_history', ...
    all(tidy.MAX_HISTORY<=baseCfg.mac.historySize), ...
    sprintf('max observed %d / bound %d', ...
    max(tidy.MAX_HISTORY),baseCfg.mac.historySize));
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'recipient_accounting', ...
    all(tidy.DATA_RECIPIENT_SUCCESS+tidy.DATA_RECIPIENT_LOSS == ...
    tidy.DATA_RECIPIENT_ATTEMPTS), ...
    'every attempted DATA recipient has exactly one success/loss outcome');
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'airtime_union', ...
    all(tidy.CHANNEL_UTIL<=tidy.OFFERED_UTIL+1e-12) && ...
    all(tidy.CHANNEL_UTIL<=1+1e-12), ...
    'busy-time union does not exceed offered airtime or mission horizon');

isP1Periodic = tidy.pAccess==1 & strcmp(tidy.method,'Periodic-P10');
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'p1_collision_collapse', ...
    all(tidy.COLLISION_FRAMES(isP1Periodic)>0) && ...
    all(tidy.DATA_RECIPIENT_SUCCESS(isP1Periodic)==0), ...
    'synchronized periodic senders have collisions and zero DATA reception');

theta = pValues.*(1-pValues).^(baseCfg.swarm.N-1);
[~,thetaBest] = max(theta);
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'analytical_p_star', ...
    pValues(thetaBest)==0.20 && nnz(theta==max(theta))==1, ...
    sprintf('theta=%s; unique grid maximum at p=%.2f', ...
    mat2str(theta,5),pValues(thetaBest)));

isSubunitP = tidy.pAccess<1;
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'nondeadlock_subunit_p', ...
    all(tidy.DATA_DELIVERED(isSubunitP)>0), ...
    'every p<1 development run delivers at least one DATA frame');

crnOk = true;
for seed = developmentSeeds
    crnOk = crnOk && isscalar(unique( ...
        tidy.TRACE_HASH_EXACT(tidy.seed==seed)));
end
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'paired_crn_trace',crnOk, ...
    'one absolute MAC trace hash per development seed across all cells');

isNoFeedback = ~strcmp(tidy.method,'Causal-Broadcast');
isCausalSubunit = strcmp(tidy.method,'Causal-Broadcast') & tidy.pAccess<1;
[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'feedback_semantics', ...
    all(tidy.ACK_ATTEMPTED(isNoFeedback)==0) && ...
    all(tidy.ACK_ENTRIES_DELIVERED(isCausalSubunit)>0), ...
    'only Causal-Broadcast generates ACK traffic; p<1 cells confirm entries');

[gateName,gatePassed,gateDetail] = addGate( ...
    gateName,gatePassed,gateDetail,'frame_count_order', ...
    all(tidy.DATA_DELIVERED<=tidy.DATA_GENERATED), ...
    'unique delivered logical DATA frames never exceed generated frames');

gates = table(gateName(:),double(gatePassed(:)),gateDetail(:), ...
    'VariableNames',{'gate','passed','detail'});
writetable(gates,fullfile(expRun.dir,'gates.csv'));

verdict = struct();
verdict.status = ternary(all(gatePassed),'PASS','FAIL');
verdict.gatesPassed = nnz(gatePassed);
verdict.gatesTotal = numel(gatePassed);
verdict.policyClaimPermitted = false;
verdict.note = ['EXP12 validates infrastructure only. Method performance ' ...
    'contrasts remain development observations and cannot support claims.'];
writeJson(fullfile(expRun.dir,'verdict.json'),verdict);

fprintf('\nEXP12 diagnostic gates\n');
for k = 1:height(gates)
    fprintf('  [%-4s] %-26s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        gates.gate{k},gates.detail{k});
end
fprintf('\nEXP12 VERDICT: %s (%d/%d gates)\n', ...
    verdict.status,verdict.gatesPassed,verdict.gatesTotal);
fprintf('Policy superiority claim permitted: NO\n');

makeTraceFigure(traceOut);
saveAllFigures(expRun);
save(fullfile(expRun.dir,'workspace.mat'), ...
    'tidy','gates','verdict','manifest','traceOut');
finishExperiment(expRun);

if ~all(gatePassed)
    error('exp12_shared_medium_diagnostic: %d of %d gates failed.', ...
        nnz(~gatePassed),numel(gatePassed));
end


function r = emptyRow()

r = struct( ...
    'seed',0,'scenario','','residualLoss',NaN,'pAccess',NaN,'method','', ...
    'thetaTagged',NaN,'RMSE',NaN,'MINSEP',NaN,'SAFEFAIL',NaN, ...
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
    'ACK_ENTRIES_TRANSFERRED',NaN, ...
    'ACK_RECIPIENT_ATTEMPTS',NaN,'ACK_RECIPIENT_SUCCESS',NaN, ...
    'ACK_RECIPIENT_LOSS',NaN, ...
    'CHANNEL_UTIL',NaN,'OFFERED_UTIL',NaN,'DATA_AIRTIME',NaN, ...
    'ACK_AIRTIME',NaN,'PIGGYBACK_AIRTIME',NaN, ...
    'ENERGY_PROXY_J',NaN,'DATA_GOODPUT_HZ',NaN, ...
    'RECIPIENT_GOODPUT_HZ',NaN,'ACK_GOODPUT_HZ',NaN, ...
    'MEAN_ACCESS_DELAY',NaN,'P95_ACCESS_DELAY',NaN, ...
    'MEAN_ONEWAY_DELAY',NaN,'P95_ONEWAY_DELAY',NaN, ...
    'MEAN_CONFIRM_DELAY',NaN,'P95_CONFIRM_DELAY',NaN, ...
    'JAIN_FRAME_GOODPUT',NaN,'NETWORK_RUNTIME_SEC',NaN, ...
    'INVARIANT_VIOLATIONS',NaN,'TRACE_HASH_EXACT',NaN);

end


function [names,passed,details] = addGate( ...
    names,passed,details,name,flag,detail)

names{end+1,1} = name;
passed(end+1,1) = logical(flag);
details{end+1,1} = detail;

end


function writeJson(path,value)

fid = fopen(path,'w');
if fid < 0
    error('exp12_shared_medium_diagnostic: cannot write %s.',path);
end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y = ternary(flag,a,b)

if flag, y=a; else, y=b; end

end


function makeTraceFigure(out)

if isempty(out)
    return;
end

figure('Name','EXP12 shared-medium infrastructure trace', ...
    'Color','w','Position',[100 100 1050 760]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

nexttile;
stairs(out.t,out.dataAttemptLog,'LineWidth',1.3); hold on;
stairs(out.t,out.dataDeliveredLog,'LineWidth',1.3);
stairs(out.t,out.collisionLog,'LineWidth',1.3);
grid on; ylabel('cumulative frames');
legend({'DATA attempts','unique DATA delivered','collision frames'}, ...
    'Location','northwest');
title('Development trace: Causal-Broadcast, Moderate, p=0.2');

nexttile;
stairs(out.t,max(out.queueDepth,[],2),'LineWidth',1.3);
grid on; ylabel('max queue depth');

nexttile;
plot(out.t,out.meanAoI,'LineWidth',1.3); hold on;
plot(out.t,out.meanEstimatedAoI,'LineWidth',1.3);
grid on; xlabel('time [s]'); ylabel('age [s]');
legend({'true receiver AoI','sender-confirmed age'},'Location','northwest');

end
