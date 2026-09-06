function exp14d_factorial_closure(existingRunDir)
%EXP14D_FACTORIAL_CLOSURE Complete A-by-G-by-S mechanism attribution.
%
%   exp14d_factorial_closure(existingRunDir) finalizes a completed tidy.csv
%   without rerunning simulations.

startup;
close all;
if nargin>=1 && ~isempty(existingRunDir)
    finalizeExistingRun(existingRunDir);
    return;
end
runScriptIsolated('test_exp14d_factorial_contracts');

R=exp14dRegistry();
expRun=startExperiment('exp14d_factorial_closure', ...
    ['Twelve-seed complete adaptive-ACK by load-guard by access-scaling ' ...
    'development factorial; no confirmatory claim.']);
snapshotSource(expRun.dir);
writeJson(fullfile(expRun.dir,'development_registry.json'),R);

[groupSeed,groupCell]=developmentGroups(R);
nGroup=numel(groupSeed);
batchSize=8;
rows=repmat(exp14dEmptyRow(),0,1);
checkpoint=fullfile(expRun.dir,'tidy_checkpoint.csv');
fprintf('EXP14D factorial matrix: %d runs, %d seed/cell groups.\n', ...
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


function rows=runGroup(seedValue,cellIndex,R)

cellDef=R.cells(cellIndex);
base=applyExp14DCell(cellDef.id,seedValue);
trace=generateSharedMediumTrace(base);
rows=repmat(exp14dEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label]=applyExp14DArm(base,arm);
    meta=struct('stage','development','scenario',cellDef.id, ...
        'scenarioLabel',cellDef.label,'family','EXP14D factorial', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',NaN);
    row=runExp14Cell(cfg,method,label,meta,trace);
    row.factorAdaptiveAck=double(arm.adaptiveAck);
    row.factorLoadGuard=double(arm.loadGuard);
    row.factorAccessScaling=double(arm.accessScaling);
    row.basePAccess=base.mac.pAccess;
    rows(k)=row;
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


function finalizeExistingRun(runDir)

runDir=char(runDir);
tidyPath=fullfile(runDir,'tidy.csv');
if exist(tidyPath,'file')~=2
    error('exp14d: missing completed tidy.csv in %s.',runDir);
end
R=exp14dRegistry();
tidy=readtable(tidyPath,'TextType','string','Delimiter',',');
if height(tidy)~=R.expectedRuns
    error('exp14d: expected %d rows but found %d.',R.expectedRuns,height(tidy));
end
expRun=resumeRunRecord(runDir);
fprintf('\nFinalizing existing EXP14D run; no simulations rerun.\n');
finalizeRun(expRun,tidy,R);

end


function finalizeRun(expRun,tidy,R)

summary=summarizeRows(tidy);
effects=factorialEffects(tidy,R);
safetyShifts=factorialSafetyShifts(tidy,R);
gates=integrityGates(tidy,R);
[selection,verdict]=candidateSelection(summary,R);
writetable(summary,fullfile(expRun.dir,'summary.csv'));
writetable(effects,fullfile(expRun.dir,'factorial_effects.csv'));
writetable(safetyShifts,fullfile(expRun.dir,'factorial_safety_shifts.csv'));
writetable(gates,fullfile(expRun.dir,'gates.csv'));
writetable(selection,fullfile(expRun.dir,'candidate_audit.csv'));
writeJson(fullfile(expRun.dir,'selection_verdict.json'),verdict);

makeFigure(summary);
saveAllFigures(expRun);

fprintf('\nEXP14D integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-34s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
fprintf('\nEXP14D DEVELOPMENT DECISION: %s\n',verdict.status);
fprintf('  candidate: %s | eligible arms: %d\n', ...
    verdict.candidate,verdict.eligibleArms);

save(fullfile(expRun.dir,'workspace.mat'),'tidy','summary','effects', ...
    'safetyShifts','gates','selection','verdict','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp14d_factorial_closure: integrity gates failed.');
end

end


function S=summarizeRows(T)

[G,S]=findgroups(T(:,{'scenario','scenarioLabel','arm','methodLabel', ...
    'factorAdaptiveAck','factorLoadGuard','factorAccessScaling'}));
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
S.meanGuardBlocked=splitapply(@nanmeanLocal,T.LOAD_GUARD_BLOCKED,G);
S.meanAdaptiveAck=splitapply(@nanmeanLocal,T.ADAPTIVE_ACK_PERMITTED,G);
S.actualPAccess=splitapply(@nanmeanLocal,T.pAccess,G);

end


function E=factorialEffects(T,R)

metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED'};
effects=struct('id',{'A','G','S','AxG','AxS','GxS','AxGxS'}, ...
    'columns',{1,2,3,[1 2],[1 3],[2 3],[1 2 3]});
E=table();
for c=R.cells
    for e=effects
        perMetric=nan(numel(R.seeds),numel(metrics));
        for i=1:numel(R.seeds)
            Q=T(T.seed==R.seeds(i) & T.scenario==string(c.id),:);
            factors=[Q.factorAdaptiveAck Q.factorLoadGuard ...
                Q.factorAccessScaling];
            signs=prod(2*factors(:,e.columns)-1,2);
            if height(Q)~=8 || nnz(signs==1)~=4 || nnz(signs==-1)~=4
                error('exp14d: incomplete factorial for %s seed %d.', ...
                    c.id,R.seeds(i));
            end
            for m=1:numel(metrics)
                y=Q.(metrics{m});
                perMetric(i,m)=mean(y(signs==1))-mean(y(signs==-1));
            end
        end
        for m=1:numel(metrics)
            d=perMetric(:,m);
            ci=pairedCI(d,zeros(size(d)),numel(R.seeds));
            row=table(string(c.id),string(e.id),string(metrics{m}), ...
                ci.meanD,ci.lo,ci.hi,ci.nPairs,ci.nDropped,ci.crossesZero, ...
                'VariableNames',{'cell','effect','metric','meanEffect', ...
                'pairedTLo','pairedTHi','nPairs','nDropped','crossesZero'});
            E=[E; row]; %#ok<AGROW>
        end
    end
end

end


function S=factorialSafetyShifts(T,R)

factors={'A','G','S'};
columns={'factorAdaptiveAck','factorLoadGuard','factorAccessScaling'};
S=table();
for c=R.cells
    Q=T(T.scenario==string(c.id),:);
    for f=1:numel(factors)
        other=setdiff(1:3,f);
        high=[]; low=[];
        for x=0:1
            for y=0:1
                selector=[Q.factorAdaptiveAck Q.factorLoadGuard ...
                    Q.factorAccessScaling];
                common=selector(:,other(1))==x & selector(:,other(2))==y;
                H=sortrows(Q(common & Q.(columns{f})==1,:),'seed');
                L=sortrows(Q(common & Q.(columns{f})==0,:),'seed');
                if ~isequal(H.seed,R.seeds) || ~isequal(L.seed,R.seeds)
                    error('exp14d: incomplete safety pair for %s/%s.', ...
                        c.id,factors{f});
                end
                high=[high; logical(H.SAFEFAIL)]; %#ok<AGROW>
                low=[low; logical(L.SAFEFAIL)]; %#ok<AGROW>
            end
        end
        row=table(string(c.id),string(factors{f}),sum(high),sum(low), ...
            sum(~high & low),sum(high & ~low),sum(high==low),numel(high), ...
            'VariableNames',{'cell','factor','failuresHigh','failuresLow', ...
            'pairsImproved','pairsWorsened','pairsEqual','nMatchedPairs'});
        S=[S; row]; %#ok<AGROW>
    end
end

end


function gates=integrityGates(T,R)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
[names,passed,detail]=addGate(names,passed,detail,'contract_hash', ...
    R.contractHash==R.expectedContractHash,sprintf('hash %.0f',R.contractHash));
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d development runs',height(T)));
keys=string(T.seed)+"|"+T.scenario+"|"+T.arm;
[names,passed,detail]=addGate(names,passed,detail,'unique_cells', ...
    numel(unique(keys))==height(T),'one row per seed/cell/factor arm');
finite=all(isfinite(T.RMSE) & isfinite(T.MINSEP) & ...
    isfinite(T.MEAN_TRUE_AOI) & isfinite(T.OFFERED_UTIL));
[names,passed,detail]=addGate(names,passed,detail,'finite_outputs',finite, ...
    'control, AoI and medium outputs are finite');

cube=true;
expected=sortrows(dec2bin(0:7)-'0');
for seed=R.seeds'
    for c=R.cells
        Q=T(T.seed==seed & T.scenario==string(c.id),:);
        actual=sortrows([Q.factorAdaptiveAck Q.factorLoadGuard ...
            Q.factorAccessScaling]);
        cube=cube && isequal(actual,expected);
    end
end
[names,passed,detail]=addGate(names,passed,detail,'complete_factorial_cube', ...
    cube,'all eight binary combinations occur once per seed/cell');

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
    accounting,'terminal DATA/ACK accounting and busy union close');

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

A=logical(T.factorAdaptiveAck); G=logical(T.factorLoadGuard);
adaptiveOk=all(T.feedbackMode(A)=="adaptive") && ...
    all(T.feedbackMode(~A)=="hybrid") && ...
    all(T.ADAPTIVE_ACK_PERMITTED(~A)==0) && ...
    all(T.ADAPTIVE_ACK_DEFERRED(~A)==0) && ...
    sum(T.ADAPTIVE_ACK_PERMITTED(A))>0;
[names,passed,detail]=addGate(names,passed,detail,'adaptive_factor_semantics', ...
    adaptiveOk,'adaptive feedback and decisions occur iff A=1');
method=string(T.method);
guardOk=all(T.LOAD_GUARD_BLOCKED(~G)==0) && ...
    sum(T.LOAD_GUARD_BLOCKED(G))>0 && ...
    all(method(~A & G)=="load-guarded-broadcast") && ...
    all(method(A)=="mac-aware-broadcast") && ...
    all(method(~A & ~G)=="causal-broadcast");
[names,passed,detail]=addGate(names,passed,detail,'guard_factor_semantics', ...
    guardOk,'guard blocks iff G=1 and method contracts match factors');

S=logical(T.factorAccessScaling);
expectedP=T.basePAccess;
expectedP(S)=min(T.basePAccess(S),1./T.N(S));
accessOk=all(abs(T.pAccess-expectedP)<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'access_factor_semantics', ...
    accessOk,'actual access equals declared S factor');

n5Exact=n5NegativeControl(T,R);
[names,passed,detail]=addGate(names,passed,detail,'n5_scaling_negative_control', ...
    n5Exact,'S=0/S=1 physical rows are bit-identical when p=1/N');
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


function exact=n5NegativeControl(T,R)

names=T.Properties.VariableNames;
first=find(strcmp(names,'RMSE'),1);
last=find(strcmp(names,'ESTIMATOR_HASH_EXACT'),1);
physical=names(first:last);
% Wall-clock runtime is deliberately excluded: it is neither a physical,
% control, traffic nor protocol output and cannot be bit-identical across two
% sequential MATLAB calls. The scientific outputs on both sides remain exact.
physical=setdiff(physical,{'NETWORK_RUNTIME_SEC'},'stable');
exact=true;
for c={'n5-csma','n5-aloha'}
    for seed=R.seeds'
        for A=0:1
            for G=0:1
                common=T.scenario==string(c{1}) & T.seed==seed & ...
                    T.factorAdaptiveAck==A & T.factorLoadGuard==G;
                L=T(common & T.factorAccessScaling==0,physical);
                H=T(common & T.factorAccessScaling==1,physical);
                exact=exact && height(L)==1 && height(H)==1 && ...
                    isequaln(table2array(L),table2array(H));
            end
        end
    end
end

end


function [A,V]=candidateSelection(S,R)

nArm=numel(R.arms);
eligible=false(nArm,1);
totalFailures=zeros(nArm,1);
n20Util=nan(nArm,1);
worstRMSERegret=inf(nArm,1);
worstUtilRegret=inf(nArm,1);
for k=1:nArm
    Q=S(string(S.arm)==string(R.arms(k).id),:);
    totalFailures(k)=sum(Q.safeFailures);
    N20=Q(string(Q.scenario)=="n20-ring2",:);
    n20Util(k)=N20.meanOfferedUtil;
    eligible(k)=height(Q)==numel(R.cells) && totalFailures(k)==0 && ...
        height(N20)==1 && n20Util(k)<R.n20OfferedUtilCeiling;
end

rmseTie=false(nArm,1); selected=false(nArm,1);
if any(eligible)
    for c=R.cells
        Q=S(string(S.scenario)==string(c.id),:);
        qEligible=ismember(string(Q.arm),string({R.arms(eligible).id}));
        best=min(Q.meanRMSE(qEligible));
        bestUtil=min(Q.meanOfferedUtil(qEligible));
        for k=find(eligible)'
            row=Q(string(Q.arm)==string(R.arms(k).id),:);
            worstRMSERegret(k)=max(worstRMSERegretValue( ...
                worstRMSERegret(k)),row.meanRMSE/best-1);
            worstUtilRegret(k)=max(worstRMSERegretValue( ...
                worstUtilRegret(k)),row.meanOfferedUtil/bestUtil-1);
        end
    end
    minRMSE=min(worstRMSERegret(eligible));
    rmseTie=eligible & worstRMSERegret<=minRMSE+R.regretTieMargin;
    minUtil=min(worstUtilRegret(rmseTie));
    finalists=find(rmseTie & ...
        worstUtilRegret<=minUtil+R.regretTieMargin);
    selected(finalists(1))=true;
    candidate=R.arms(finalists(1)).id;
    status='FREEZE_FOR_NEW_PREREGISTRATION';
else
    candidate='none';
    status='CLOSE_FACTORIAL_DESIGN';
end

A=table(string({R.arms.id})',double(eligible),totalFailures,n20Util, ...
    worstRMSERegret,double(rmseTie),worstUtilRegret,double(selected), ...
    'VariableNames',{'arm','eligible','totalSafetyFailures','n20OfferedUtil', ...
    'worstRMSERegret','withinRMSETie','worstUtilRegret','selected'});
V=struct('status',status,'candidate',candidate, ...
    'eligibleArms',nnz(eligible),'contractHash',R.contractHash, ...
    'confirmatoryClaimPermitted',false);

end


function value=worstRMSERegretValue(value)

if isinf(value), value=-inf; end

end


function makeFigure(S)

cellLabels=unique(string(S.scenarioLabel),'stable');
colors=[0.10 0.45 0.80; 0.85 0.33 0.10];
markers={'o','s'};
figure('Name','EXP14D complete factorial','Color','w', ...
    'Position',[80 80 1250 850]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for c=1:numel(cellLabels)
    ax=nexttile; hold(ax,'on');
    Q=S(string(S.scenarioLabel)==cellLabels(c),:);
    isN5=startsWith(cellLabels(c),"N5");
    for k=1:height(Q)
        if isN5 && Q.factorAccessScaling(k)==1
            continue;
        end
        A=Q.factorAdaptiveAck(k)+1;
        G=Q.factorLoadGuard(k)+1;
        scatter(ax,Q.meanOfferedUtil(k),Q.meanRMSE(k),75,colors(A,:), ...
            markers{G},'filled','HandleVisibility','off');
        if isN5
            pointLabel=sprintf(' A%d G%d S{0,1}',A-1,G-1);
        else
            pointLabel=" "+string(Q.arm(k));
        end
        text(ax,Q.meanOfferedUtil(k),Q.meanRMSE(k),pointLabel,'FontSize',7);
        if Q.safeFailures(k)>0
            plot(ax,Q.meanOfferedUtil(k),Q.meanRMSE(k),'kx', ...
                'MarkerSize',11,'LineWidth',1.6,'HandleVisibility','off');
        end
    end
    grid(ax,'on'); box(ax,'on');
    xlabel(ax,'Offered airtime utilization'); ylabel(ax,'RMSE [m]');
    title(ax,char(cellLabels(c)));
end
sgtitle('EXP14D factorial: color A, marker G, label includes S; cross = failure');

end


function expRun=resumeRunRecord(runDir)

[expRoot,runId]=fileparts(runDir);
v=ver('MATLAB'); root=projectRoot();
nowText=char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
try
    original=char(datetime(runId,'InputFormat','yyyy-MM-dd_HHmmss', ...
        'Format','yyyy-MM-dd HH:mm:ss'));
catch
    original=nowText;
end
expRun=struct('name','exp14d_factorial_closure','runId',runId, ...
    'expRoot',expRoot,'dir',runDir,'figDir',fullfile(runDir,'figures'));
if exist(expRun.figDir,'dir')~=7, mkdir(expRun.figDir); end
expRun.notes='Post-run finalization; simulation rows were not rerun.';
metaPath=fullfile(runDir,'meta.json');
if exist(metaPath,'file')==2
    expRun.meta=jsondecode(fileread(metaPath));
    if ~isfield(expRun.meta,'simulationElapsedSec') && ...
            isfield(expRun.meta,'elapsedSec')
        expRun.meta.simulationElapsedSec=expRun.meta.elapsedSec;
    end
    if ~isfield(expRun.meta,'simulationElapsedText') && ...
            isfield(expRun.meta,'elapsedText')
        expRun.meta.simulationElapsedText=expRun.meta.elapsedText;
    end
else
    expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
        'startedAt',original,'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
        'matlabRelease',v.Release,'computer',computer,'projectRoot',root, ...
        'gitCommit',localGitCommit(root),'sourceFile',which(expRun.name));
end
expRun.meta.notes=expRun.notes;
expRun.meta.finalizedExistingRun=true;
expRun.meta.simulationsRerun=false;
expRun.meta.finalizationStartedAt=nowText;
expRun.meta.elapsedScope='finalization_only';
expRun.logFile=fullfile(runDir,'console.log');
diary(expRun.logFile); diary on; expRun.t0=tic;

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


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP14D_FACTORIAL_CLOSURE_PLAN.md', ...
    'utils/exp14dRegistry.m','utils/applyExp14DCell.m', ...
    'utils/applyExp14DArm.m','utils/exp14dEmptyRow.m', ...
    'utils/exp14EmptyRow.m','utils/runExp14Cell.m', ...
    'utils/writeTableAtomic.m','network/macAwarePolicyConfig.m', ...
    'network/macAwareLoadGuard.m','network/adaptiveStandaloneAckDecision.m', ...
    'network/sharedMediumFeedbackMode.m','network/initSharedMediumState.m', ...
    'network/enqueueAckSummary.m','network/enqueueBroadcastState.m', ...
    'network/advanceSharedMedium.m','simulation/simSwarmSharedMedium.m', ...
    'metrics/computeSharedMediumMetrics.m', ...
    'tests/test_exp14d_factorial_contracts.m','tests/test_mac_aware_policy.m', ...
    'experiments/exp14d_factorial_closure.m'};
freeze=fullfile(target,'source_snapshot'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

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


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp14d: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
