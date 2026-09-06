%% EXP13B_MULTISLOT_MAC_DIAGNOSTIC Corrective MAC-distinguishability check.

startup;
close all;

expRun = startExperiment('exp13b_multislot_mac_diagnostic', ...
    ['Post-EXP13 corrective one-slot versus multi-slot MAC diagnostic; ' ...
    'no policy claim.']);

seeds = 13013001:13013004;
pValues = [0.1 0.2 0.4];
macTypes = {'csma','aloha'};
methods = {'periodic','causal-broadcast'};
methodLabels = {'Periodic-P10','Causal-Broadcast'};
calibrationIds = {'one-slot','multi-slot'};

nRun = numel(seeds)*numel(pValues)*numel(macTypes)* ...
    numel(methods)*numel(calibrationIds);
rows = repmat(emptyRow(),nRun,1);
kRun = 0;

fprintf('EXP13B matrix: %d development diagnostic runs\n',nRun);
for iSeed = 1:numel(seeds)
    for iCal = 1:numel(calibrationIds)
        for iP = 1:numel(pValues)
            for iMac = 1:numel(macTypes)
                for iMethod = 1:numel(methods)
                    cfg = study2SharedMediumConfig();
                    cfg.net.seed = seeds(iSeed);
                    cfg.mac.residualLoss = 0.10;
                    cfg.mac.pAccess = pValues(iP);
                    cfg.mac.type = macTypes{iMac};
                    if iCal==2
                        cfg.mac.dataBytes = 96;
                        cfg.mac.ackBaseBytes = 16;
                        cfg.mac.ackEntryBytes = 8;
                        cfg.mac.phyRateBps = 250e3;
                    end

                    out = simSwarmSharedMedium(cfg,methods{iMethod});
                    M = computeSharedMediumMetrics(out,cfg);

                    kRun = kRun+1;
                    r = emptyRow();
                    r.seed = cfg.net.seed;
                    r.calibration = calibrationIds{iCal};
                    r.macType = cfg.mac.type;
                    r.pAccess = cfg.mac.pAccess;
                    r.method = methods{iMethod};
                    r.methodLabel = methodLabels{iMethod};
                    r.dataDurationSlots = ceil( ...
                        8*cfg.mac.dataBytes/cfg.mac.phyRateBps/cfg.mac.slotTime);
                    r.RMSE = M.formationRMSE;
                    r.MINSEP = M.minSeparationEval;
                    r.SAFEFAIL = double(M.safeFailure);
                    r.MEAN_TRUE_AOI = M.meanTrueAoI;
                    r.MEAN_EST_AOI = M.meanEstimatedAoI;
                    r.DATA_ATTEMPTED = M.dataFramesAttempted;
                    r.DATA_DELIVERED = M.dataFramesDeliveredAny;
                    r.ACK_ATTEMPTED = M.ackFramesAttempted;
                    r.COLLISION_FRAMES = M.collisionFrames;
                    r.DATA_RECIPIENT_SUCCESS = M.dataRecipientSuccess;
                    r.DATA_RECIPIENT_LOSS = M.dataRecipientLoss;
                    r.DATA_RECIPIENT_ATTEMPTS = M.dataRecipientAttempts;
                    r.CHANNEL_UTIL = M.channelUtilization;
                    r.OFFERED_UTIL = M.offeredAirtimeUtilization;
                    r.MAX_QUEUE = M.maxQueueDepth;
                    r.MAX_HISTORY = M.maxHistoryDepth;
                    r.historySize = cfg.mac.historySize;
                    r.INVARIANT_VIOLATIONS = M.invariantViolations;
                    r.TRACE_HASH_EXACT = out.traceHashExact;
                    rows(kRun) = r;

                    if mod(kRun,24)==0 || kRun==nRun
                        fprintf('  completed %d / %d runs\n',kRun,nRun);
                    end
                end
            end
        end
    end
end

tidy = struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));

oneSlot = strcmp(tidy.calibration,'one-slot');
multiSlot = strcmp(tidy.calibration,'multi-slot');
oneSlotEquivalent = pairedMacEquivalent(tidy(oneSlot,:));
multiSlotDistinct = pairedMacDistinct(tidy(multiSlot,:));

gateName = {'matrix_completeness';'one_slot_degeneracy_reproduced'; ...
    'multi_slot_duration';'multi_slot_mac_distinguishable'; ...
    'protocol_and_accounting';'paired_absolute_trace'};
gatePassed = [height(tidy)==96; oneSlotEquivalent; ...
    all(tidy.dataDurationSlots(multiSlot)>=4); multiSlotDistinct; ...
    all(tidy.INVARIANT_VIOLATIONS==0) && ...
    all(tidy.MAX_QUEUE<=4) && all(tidy.MAX_HISTORY<=tidy.historySize) && ...
    all(tidy.DATA_RECIPIENT_SUCCESS+tidy.DATA_RECIPIENT_LOSS== ...
    tidy.DATA_RECIPIENT_ATTEMPTS); traceGate(tidy,seeds)];
gateDetail = {sprintf('%d declared runs',height(tidy)); ...
    'one-slot CSMA and ALOHA are exactly identical on physical outcomes'; ...
    sprintf('multi-slot bare DATA duration=%d slots', ...
    unique(tidy.dataDurationSlots(multiSlot))); ...
    'multi-slot CSMA and ALOHA differ in at least one paired outcome'; ...
    sprintf('%d invariant violations; max queue=%d; max history=%d', ...
    sum(tidy.INVARIANT_VIOLATIONS),max(tidy.MAX_QUEUE),max(tidy.MAX_HISTORY)); ...
    'one absolute random trace per development seed'};

gates = table(gateName,double(gatePassed),gateDetail, ...
    'VariableNames',{'gate','passed','detail'});
writetable(gates,fullfile(expRun.dir,'gates.csv'));

summary = summarize(tidy);
writetable(summary,fullfile(expRun.dir,'summary.csv'));

verdict = struct('status',ternary(all(gatePassed),'PASS','FAIL'), ...
    'gatesPassed',nnz(gatePassed),'gatesTotal',numel(gatePassed), ...
    'totalDevelopmentRuns',height(tidy),'policyClaimPermitted',false, ...
    'note',['Post-EXP13 diagnostic confirms whether multi-slot service ' ...
    'distinguishes abstract CSMA from ALOHA; it does not rank policies.']);
writeJson(fullfile(expRun.dir,'verdict.json'),verdict);

fprintf('\nEXP13B gates\n');
for k = 1:height(gates)
    fprintf('  [%-4s] %-34s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        gates.gate{k},gates.detail{k});
end
fprintf('\nEXP13B VERDICT: %s (%d/%d)\n', ...
    verdict.status,verdict.gatesPassed,verdict.gatesTotal);

makeFigure(summary);
saveAllFigures(expRun);
save(fullfile(expRun.dir,'workspace.mat'),'tidy','summary','gates','verdict');
finishExperiment(expRun);

if ~all(gatePassed)
    error('exp13b_multislot_mac_diagnostic: %d/%d gates failed.', ...
        nnz(~gatePassed),numel(gatePassed));
end


function r = emptyRow()

r = struct('seed',0,'calibration','','macType','','pAccess',NaN, ...
    'method','','methodLabel','','dataDurationSlots',NaN, ...
    'RMSE',NaN,'MINSEP',NaN,'SAFEFAIL',NaN,'MEAN_TRUE_AOI',NaN, ...
    'MEAN_EST_AOI',NaN,'DATA_ATTEMPTED',NaN,'DATA_DELIVERED',NaN, ...
    'ACK_ATTEMPTED',NaN,'COLLISION_FRAMES',NaN, ...
    'DATA_RECIPIENT_SUCCESS',NaN,'DATA_RECIPIENT_LOSS',NaN, ...
    'DATA_RECIPIENT_ATTEMPTS',NaN,'CHANNEL_UTIL',NaN, ...
    'OFFERED_UTIL',NaN,'MAX_QUEUE',NaN,'MAX_HISTORY',NaN, ...
    'historySize',NaN,'INVARIANT_VIOLATIONS',NaN, ...
    'TRACE_HASH_EXACT',NaN);

end


function ok = pairedMacEquivalent(T)

names = {'RMSE','MINSEP','DATA_ATTEMPTED','DATA_DELIVERED', ...
    'ACK_ATTEMPTED','COLLISION_FRAMES','DATA_RECIPIENT_SUCCESS', ...
    'CHANNEL_UTIL','OFFERED_UTIL'};
ok = true;
for seed = unique(T.seed)'
    for p = unique(T.pAccess)'
        for method = unique(T.method)'
            base = T.seed==seed & T.pAccess==p & strcmp(T.method,method{1});
            a = T(base & strcmp(T.macType,'csma'),:);
            b = T(base & strcmp(T.macType,'aloha'),:);
            ok = ok && height(a)==1 && height(b)==1;
            for q = 1:numel(names)
                ok = ok && isequaln(a.(names{q}),b.(names{q}));
            end
        end
    end
end

end


function ok = pairedMacDistinct(T)

ok = false;
names = {'DATA_DELIVERED','ACK_ATTEMPTED','COLLISION_FRAMES', ...
    'DATA_RECIPIENT_SUCCESS','CHANNEL_UTIL','OFFERED_UTIL','RMSE'};
for seed = unique(T.seed)'
    for p = unique(T.pAccess)'
        for method = unique(T.method)'
            base = T.seed==seed & T.pAccess==p & strcmp(T.method,method{1});
            a = T(base & strcmp(T.macType,'csma'),:);
            b = T(base & strcmp(T.macType,'aloha'),:);
            for q = 1:numel(names)
                ok = ok || ~isequaln(a.(names{q}),b.(names{q}));
            end
        end
    end
end

end


function ok = traceGate(T,seeds)

ok = true;
for seed = seeds
    ok = ok && isscalar(unique(T.TRACE_HASH_EXACT(T.seed==seed)));
end

end


function S = summarize(T)

[G,S] = findgroups(T(:,{'calibration','macType','pAccess','methodLabel'}));
S.meanRMSE = splitapply(@mean,T.RMSE,G);
S.safeFailures = splitapply(@sum,T.SAFEFAIL,G);
S.meanTrueAoI = splitapply(@mean,T.MEAN_TRUE_AOI,G);
S.meanCollisions = splitapply(@mean,T.COLLISION_FRAMES,G);
S.meanDelivered = splitapply(@mean,T.DATA_DELIVERED,G);
S.meanOfferedUtil = splitapply(@mean,T.OFFERED_UTIL,G);
S.meanChannelUtil = splitapply(@mean,T.CHANNEL_UTIL,G);

end


function makeFigure(S)

figure('Name','EXP13B multi-slot MAC diagnostic','Color','w', ...
    'Position',[100 100 1100 460]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
calibrations = {'one-slot','multi-slot'};
for i = 1:2
    nexttile; hold on;
    C = S(strcmp(S.calibration,calibrations{i}) & ...
        strcmp(S.methodLabel,'Causal-Broadcast'),:);
    for mac = {'csma','aloha'}
        idx = strcmp(C.macType,mac{1});
        plot(C.pAccess(idx),C.meanCollisions(idx),'-o','LineWidth',1.4, ...
            'DisplayName',upper(mac{1}));
    end
    grid on; xlabel('p-access'); ylabel('mean collision frames');
    title(calibrations{i}); legend('Location','best');
end

end


function writeJson(path,value)

fid = fopen(path,'w');
if fid<0, error('Cannot write %s.',path); end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y = ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
