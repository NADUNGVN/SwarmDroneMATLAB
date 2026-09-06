function exp14c_mac_aware_development(existingRunDir)
%EXP14C_MAC_AWARE_DEVELOPMENT Fixed post-holdout mechanism attribution.
%
%   exp14c_mac_aware_development(existingRunDir) finalizes a completed
%   development matrix from its tidy.csv without rerunning simulations.

startup;
close all;
if nargin>=1 && ~isempty(existingRunDir)
    finalizeExistingRun(existingRunDir);
    return;
end
runScriptIsolated('test_mac_aware_policy');

R=exp14cRegistry();
expRun=startExperiment('exp14c_mac_aware_development', ...
    ['Eight-seed post-holdout development matrix; adaptive feedback, ' ...
    'load guard and access-scaling ablations; no confirmatory claim.']);
snapshotSource(expRun.dir);
writeJson(fullfile(expRun.dir,'development_registry.json'),R);

[groupSeed,groupCell]=developmentGroups(R);
nGroup=numel(groupSeed);
batchSize=8;
rows=repmat(exp14EmptyRow(),0,1);
checkpoint=fullfile(expRun.dir,'tidy_checkpoint.csv');

fprintf('EXP14C development matrix: %d runs, %d seed/cell groups.\n', ...
    R.expectedRuns,nGroup);
for first=1:batchSize:nGroup
    last=min(first+batchSize-1,nGroup);
    idx=first:last;
    batch=cell(numel(idx),1);
    parfor (q=1:numel(idx),8)
        batch{q}=runGroup(groupSeed(idx(q)),groupCell(idx(q)),R);
    end
    for q=1:numel(batch)
        rows=[rows; batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %2d--%2d / %2d; rows %3d / %3d\n', ...
        first,last,nGroup,numel(rows),R.expectedRuns);
end

tidy=struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
finalizeRun(expRun,tidy,R);

end


function finalizeExistingRun(runDir)

runDir=char(runDir);
tidyPath=fullfile(runDir,'tidy.csv');
if exist(tidyPath,'file')~=2
    error('exp14c: missing completed tidy.csv in %s.',runDir);
end
R=exp14cRegistry();
tidy=readtable(tidyPath,'TextType','string');
if height(tidy)~=R.expectedRuns
    error('exp14c: expected %d rows but found %d.',R.expectedRuns,height(tidy));
end
expRun=resumeRunRecord(runDir);
fprintf('\nFinalizing existing EXP14C run from %s; no simulations rerun.\n', ...
    tidyPath);
finalizeRun(expRun,tidy,R);

end


function finalizeRun(expRun,tidy,R)

summary=summarizeRows(tidy);
writetable(summary,fullfile(expRun.dir,'summary.csv'));
contrasts=developmentContrasts(tidy,R);
writetable(contrasts,fullfile(expRun.dir,'paired_contrasts.csv'));
gates=integrityGates(tidy,R);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
[selection,selectionVerdict]=selectionAudit(summary,gates,R);
writetable(selection,fullfile(expRun.dir,'selection_criteria.csv'));
writeJson(fullfile(expRun.dir,'selection_verdict.json'),selectionVerdict);

makeFigure(summary);
saveAllFigures(expRun);

fprintf('\nEXP14C integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-32s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'),gates.gate{k}, ...
        gates.detail{k});
end
fprintf('\nEXP14C DEVELOPMENT DECISION: %s\n',selectionVerdict.status);
for k=1:height(selection)
    fprintf('  [%-4s] %-28s %s\n', ...
        ternary(selection.passed(k)==1,'PASS','FAIL'), ...
        selection.criterion{k},selection.detail{k});
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','summary','contrasts', ...
    'gates','selection','selectionVerdict','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp14c_mac_aware_development: integrity gates failed.');
end

end


function expRun=resumeRunRecord(runDir)

[expRoot,runId]=fileparts(runDir);
v=ver('MATLAB');
root=projectRoot();
finalizationStartedAt=char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
try
    originalStartedAt=char(datetime(runId,'InputFormat','yyyy-MM-dd_HHmmss', ...
        'Format','yyyy-MM-dd HH:mm:ss'));
catch
    originalStartedAt=finalizationStartedAt;
end
expRun=struct();
expRun.name='exp14c_mac_aware_development';
expRun.runId=runId;
expRun.expRoot=expRoot;
expRun.dir=runDir;
expRun.figDir=fullfile(runDir,'figures');
if exist(expRun.figDir,'dir')~=7, mkdir(expRun.figDir); end
expRun.notes=['Post-run finalization after a figure type mismatch; ' ...
    'simulation rows were not rerun.'];
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',originalStartedAt, ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer,'projectRoot',root, ...
    'gitCommit',localGitCommit(root),'notes',expRun.notes, ...
    'sourceFile',which(expRun.name),'finalizedExistingRun',true, ...
    'simulationsRerun',false,'finalizationStartedAt',finalizationStartedAt, ...
    'elapsedScope','finalization_only');
expRun.logFile=fullfile(runDir,'console.log');
diary(expRun.logFile); diary on;
expRun.t0=tic;

end


function commit=localGitCommit(root)

commit='';
try
    [status,out]=system(sprintf('git -C "%s" rev-parse --short HEAD',root));
    if status==0, commit=strtrim(out); end
catch
    commit='';
end

end


function rows=runGroup(seedValue,cellIndex,R)

cellDef=R.cells(cellIndex);
base=applyExp14CCell(cellDef.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp14EmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label]=applyExp14CArm(base,arm.id);
    meta=struct('stage','development','scenario',cellDef.id, ...
        'scenarioLabel',cellDef.label,'family','MAC-aware ablation', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',NaN);
    rows(k)=runExp14Cell(cfg,method,label,meta,trace);
end

end


function [seeds,cells]=developmentGroups(R)

n=numel(R.seeds)*numel(R.cells);
seeds=zeros(n,1); cells=zeros(n,1); q=0;
for i=1:numel(R.seeds)
    for j=1:numel(R.cells)
        q=q+1; seeds(q)=R.seeds(i); cells(q)=j;
    end
end

end


function S=summarizeRows(T)

[G,S]=findgroups(T(:,{'scenario','scenarioLabel','arm','methodLabel'}));
S.n=splitapply(@numel,T.RMSE,G);
S.meanRMSE=splitapply(@nanmeanLocal,T.RMSE,G);
S.safeFailures=splitapply(@sum,T.SAFEFAIL,G);
S.divergences=splitapply(@sum,T.DIVERGED,G);
S.meanTrueAoI=splitapply(@nanmeanLocal,T.MEAN_TRUE_AOI,G);
S.meanOfferedUtil=splitapply(@nanmeanLocal,T.OFFERED_UTIL,G);
S.meanChannelUtil=splitapply(@nanmeanLocal,T.CHANNEL_UTIL,G);
S.meanCollisions=splitapply(@nanmeanLocal,T.COLLISION_FRAMES,G);
S.meanDataAttempts=splitapply(@nanmeanLocal,T.DATA_ATTEMPTED,G);
S.meanAckAttempts=splitapply(@nanmeanLocal,T.ACK_ATTEMPTED,G);
S.meanLocalBusy=splitapply(@nanmeanLocal,T.MEAN_LOCAL_BUSY,G);
S.meanGuardBlocked=splitapply(@nanmeanLocal,T.LOAD_GUARD_BLOCKED,G);
S.meanAdaptiveAckPermitted=splitapply( ...
    @nanmeanLocal,T.ADAPTIVE_ACK_PERMITTED,G);
S.meanAdaptiveAckDeferred=splitapply( ...
    @nanmeanLocal,T.ADAPTIVE_ACK_DEFERRED,G);
S.actualPAccess=splitapply(@nanmeanLocal,T.pAccess,G);

end


function C=developmentContrasts(T,R)

metrics={'RMSE','OFFERED_UTIL','MEAN_TRUE_AOI', ...
    'COLLISION_FRAMES','ACK_ATTEMPTED'};
comparators={'frozen-hybrid','frozen-piggyback'};
C=table();
for cellDef=R.cells
    for comparator=comparators
        A=sortrows(T(T.scenario==string(cellDef.id) & ...
            T.arm=="full-v2",:),'seed');
        B=sortrows(T(T.scenario==string(cellDef.id) & ...
            T.arm==string(comparator{1}),:),'seed');
        if ~isequal(A.seed,R.seeds) || ~isequal(B.seed,R.seeds) || ...
                ~isequal(A.TRACE_HASH_EXACT,B.TRACE_HASH_EXACT) || ...
                ~isequal(A.CHANNEL_STATE_HASH,B.CHANNEL_STATE_HASH)
            error('exp14c: incomplete or non-CRN development contrast.');
        end
        for q=1:numel(metrics)
            metric=metrics{q};
            ci=pairedCI(A.(metric),B.(metric),numel(R.seeds));
            row=table(string(cellDef.id),string(comparator{1}), ...
                string(metric),mean(A.(metric),'omitnan'), ...
                mean(B.(metric),'omitnan'),ci.meanD,ci.lo,ci.hi, ...
                ci.nPairs,ci.nDropped,'VariableNames',{'cell','comparator', ...
                'metric','meanFullV2','meanComparator','difference', ...
                'pairedTLo','pairedTHi','nPairs','nDropped'});
            C=[C; row]; %#ok<AGROW>
        end
    end
end

end


function gates=integrityGates(T,R)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d development runs',height(T)));
keys=string(T.seed)+"|"+T.scenario+"|"+T.arm;
[names,passed,detail]=addGate(names,passed,detail,'unique_cells', ...
    numel(unique(keys))==height(T),'one row per declared seed/cell/arm');
finite=all(isfinite(T.RMSE) & isfinite(T.MINSEP) & ...
    isfinite(T.MEAN_TRUE_AOI) & isfinite(T.OFFERED_UTIL));
[names,passed,detail]=addGate(names,passed,detail,'finite_outputs',finite, ...
    'control, AoI and medium outputs are finite');
feedback=T.feedbackMode~="none";
causal=all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI(feedback)>=T.MEAN_TRUE_AOI(feedback)-1e-12);
[names,passed,detail]=addGate(names,passed,detail,'causal_conservatism', ...
    causal,sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));
bounded=all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
[names,passed,detail]=addGate(names,passed,detail,'bounded_memory',bounded, ...
    sprintf('max queue=%d max history=%d',max(T.MAX_QUEUE),max(T.MAX_HISTORY)));
accounting=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT==T.ACK_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=1+1e-12);
[names,passed,detail]=addGate(names,passed,detail,'physical_accounting', ...
    accounting,'DATA/ACK terminal accounting and busy union close');
crn=true;
for seed=R.seeds'
    for c=R.cells
        idx=T.seed==seed & T.scenario==string(c.id);
        crn=crn && isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
            isscalar(unique(T.CHANNEL_STATE_HASH(idx)));
    end
end
[names,passed,detail]=addGate(names,passed,detail,'paired_absolute_trace', ...
    crn,'one trace and channel-state realization per seed/cell');
adaptive=ismember(T.arm,["adaptive-only" "guarded-adaptive" "full-v2"]);
semantics=all(T.feedbackMode(adaptive)=="adaptive") && ...
    all(T.ADAPTIVE_ACK_PERMITTED(~adaptive)==0) && ...
    all(T.ADAPTIVE_ACK_DEFERRED(~adaptive)==0) && ...
    sum(T.ADAPTIVE_ACK_PERMITTED(adaptive))>0;
[names,passed,detail]=addGate(names,passed,detail,'adaptive_ack_semantics', ...
    semantics,'adaptive decisions occur only in declared adaptive arms');
guarded=ismember(T.arm,["guarded-adaptive" "full-v2"]);
guardSemantics=all(T.LOAD_GUARD_BLOCKED(~guarded)==0) && ...
    sum(T.LOAD_GUARD_BLOCKED(guarded))>0;
[names,passed,detail]=addGate(names,passed,detail,'load_guard_semantics', ...
    guardSemantics,'guard blocks only declared guarded arms and is exercised');
scaled=ismember(T.arm,["access-only" "full-v2"]);
expected=min(T.configuredPAccess,1./T.N);
accessOk=all(abs(T.pAccess(scaled)-expected(scaled))<1e-12) && ...
    all(abs(T.pAccess(~scaled)-T.configuredPAccess(~scaled))<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'access_scaling_semantics', ...
    accessOk,'only access/full arms apply min(p,1/N)');
busyOk=all(T.MEAN_LOCAL_BUSY>=0 & T.MEAN_LOCAL_BUSY<=1 & ...
    T.MAX_LOCAL_BUSY>=T.MEAN_LOCAL_BUSY & T.MAX_LOCAL_BUSY<=1+1e-12);
[names,passed,detail]=addGate(names,passed,detail,'local_busy_contract', ...
    busyOk,'causal local busy estimates remain in [0,1]');
divergenceOk=all(ismember(T.DIVERGED,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED);
[names,passed,detail]=addGate(names,passed,detail,'divergence_accounting', ...
    divergenceOk,sprintf('%d divergences retained',sum(T.DIVERGED)));
gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function [S,V]=selectionAudit(summary,gates,R)

criteria=cell(0,1); passed=false(0,1); detail=cell(0,1);
[criteria,passed,detail]=addGate(criteria,passed,detail, ...
    'integrity',all(gates.passed==1),'all integrity gates pass');

safeAll=true;
for c=R.cells
    if strcmp(c.id,'n20-ring2'), continue; end
    H=oneSummary(summary,c.id,'frozen-hybrid');
    F=oneSummary(summary,c.id,'full-v2');
    safeAll=safeAll && F.safeFailures<=H.safeFailures;
end
[criteria,passed,detail]=addGate(criteria,passed,detail, ...
    'no_n5_n10_safety_regression', ...
    safeAll,'full-v2 has no additional N5/N10 failures');

H20=oneSummary(summary,'n20-ring2','frozen-hybrid');
F20=oneSummary(summary,'n20-ring2','full-v2');
n20=F20.meanOfferedUtil<1.2 && F20.safeFailures<H20.safeFailures;
[criteria,passed,detail]=addGate(criteria,passed,detail, ...
    'n20_collapse_removed',n20,sprintf( ...
    'full-v2 util=%.3f failures=%d versus hybrid=%d', ...
    F20.meanOfferedUtil,F20.safeFailures,H20.safeFailures));

HA=oneSummary(summary,'n5-aloha','frozen-hybrid');
FA=oneSummary(summary,'n5-aloha','full-v2');
aloha=~(FA.meanRMSE>HA.meanRMSE && ...
    FA.meanOfferedUtil>HA.meanOfferedUtil);
[criteria,passed,detail]=addGate(criteria,passed,detail, ...
    'aloha_no_two_axis_loss',aloha,sprintf( ...
    'full-v2 RMSE/util %.4f/%.3f; hybrid %.4f/%.3f', ...
    FA.meanRMSE,FA.meanOfferedUtil,HA.meanRMSE,HA.meanOfferedUtil));

S=table(criteria,double(passed),detail, ...
    'VariableNames',{'criterion','passed','detail'});
V=struct('status',ternary(all(passed),'PROCEED_TO_NEW_PREREGISTRATION', ...
    'CLOSE_THIS_DESIGN'),'candidate',R.selectedCandidate, ...
    'criteriaPassed',nnz(passed),'criteriaTotal',numel(passed), ...
    'confirmatoryClaimPermitted',false);

end


function R=oneSummary(S,cellId,arm)

R=S(S.scenario==string(cellId) & S.arm==string(arm),:);
if height(R)~=1
    error('exp14c: expected one summary row for %s/%s.',cellId,arm);
end

end


function makeFigure(S)

cellLabels=unique(string(S.scenarioLabel),'stable');
arms=unique(string(S.arm),'stable');
colors=lines(numel(arms));
figure('Name','EXP14C MAC-aware development','Color','w', ...
    'Position',[70 70 1450 760]);
tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
for k=1:numel(cellLabels)
    ax=nexttile; hold(ax,'on');
    for j=1:numel(arms)
        Q=S(string(S.scenarioLabel)==cellLabels(k) & ...
            string(S.arm)==arms(j),:);
        scatter(ax,Q.meanOfferedUtil,Q.meanRMSE,70,colors(j,:),'filled', ...
            'DisplayName',char(string(Q.methodLabel(1))));
        if Q.safeFailures>0
            plot(ax,Q.meanOfferedUtil,Q.meanRMSE,'kx','MarkerSize',11, ...
                'LineWidth',1.8,'HandleVisibility','off');
        end
    end
    grid(ax,'on'); box(ax,'on');
    xlabel(ax,'Offered airtime utilization'); ylabel(ax,'RMSE [m]');
    title(ax,char(cellLabels(k)));
    if k==1, legend(ax,'Location','best','FontSize',7); end
end
sgtitle('EXP14C development ablation (cross = any safety failure)');

end


function [names,passed,detail]=addGate(names,passed,detail,name,flag,text)

names{end+1,1}=name;
passed(end+1,1)=logical(flag);
detail{end+1,1}=text;

end


function y=nanmeanLocal(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP14C_MAC_AWARE_DEVELOPMENT_PLAN.md', ...
    'utils/exp14cRegistry.m','utils/applyExp14CCell.m', ...
    'utils/applyExp14CArm.m','utils/exp14EmptyRow.m', ...
    'utils/runExp14Cell.m','utils/writeTableAtomic.m', ...
    'network/macAwarePolicyConfig.m', ...
    'network/macAwareLoadGuard.m','network/adaptiveStandaloneAckDecision.m', ...
    'network/sharedMediumFeedbackMode.m','network/initSharedMediumState.m', ...
    'network/enqueueAckSummary.m','network/enqueueBroadcastState.m', ...
    'network/advanceSharedMedium.m','simulation/simSwarmSharedMedium.m', ...
    'metrics/computeSharedMediumMetrics.m', ...
    'tests/test_mac_aware_policy.m','tests/run_all_tests.m', ...
    'experiments/exp14c_mac_aware_development.m'};
freeze=fullfile(target,'source_snapshot'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14c: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
