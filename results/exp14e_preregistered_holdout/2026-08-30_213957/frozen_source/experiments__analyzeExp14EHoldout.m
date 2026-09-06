function A=analyzeExp14EHoldout(runDir)
%ANALYZEEXP14EHOLDOUT Frozen confirmatory and secondary holdout analysis.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp14EHoldout: runDir must be char or scalar string.');
end
runDir=char(runDir);
R=exp14eRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=87778193 || registryLeaves~=58
    error('analyzeExp14EHoldout: frozen registry hash mismatch.');
end
tidyPath=fullfile(runDir,'tidy.csv');
gatePath=fullfile(runDir,'gates.csv');
if exist(tidyPath,'file')~=2 || exist(gatePath,'file')~=2
    error('analyzeExp14EHoldout: tidy.csv and gates.csv are required.');
end
T=readtable(tidyPath,'TextType','string','Delimiter',',');
G=readtable(gatePath,'TextType','string','Delimiter',',');
if height(T)~=R.expectedRuns || ~all(G.passed==1)
    error('analyzeExp14EHoldout: matrix or integrity gates are incomplete.');
end

A=struct();
A.summary=summarizeRows(T);
A.primaryTests=primaryTests(T,R);
A.cellClaims=cellClaims(T,A.primaryTests,R);
A.secondaryContrasts=secondaryContrasts(T,R);
[A.safetySummary,A.pairedSafety]=safetyAnalysis(T,R);
A.claimVerdict=claimVerdict(A.primaryTests,A.cellClaims,R);

writetable(A.summary,fullfile(runDir,'analysis_summary.csv'));
writetable(A.primaryTests,fullfile(runDir,'primary_holm_tests.csv'));
writetable(A.cellClaims,fullfile(runDir,'primary_cell_claims.csv'));
writetable(A.secondaryContrasts, ...
    fullfile(runDir,'secondary_paired_contrasts.csv'));
writetable(A.safetySummary,fullfile(runDir,'safety_wilson.csv'));
writetable(A.pairedSafety,fullfile(runDir,'paired_safety_counts.csv'));
writeJson(fullfile(runDir,'claim_verdict.json'),A.claimVerdict);
manifest=struct('registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'rows',height(T),'primaryTests',height(A.primaryTests), ...
    'holmFamilySize',height(A.primaryTests), ...
    'secondaryContrasts',height(A.secondaryContrasts), ...
    'bootstrapReplicates',R.bootstrapReplicates, ...
    'bootstrapSeed',R.bootstrapSeed,'familywiseAlpha',R.familywiseAlpha, ...
    'universalMacClaimPermitted',false, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writeJson(fullfile(runDir,'analysis_manifest.json'),manifest);
makeFigure(A.summary,R);

end


function S=summarizeRows(T)

U=T;
continuous={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED','MEAN_LOCAL_BUSY'};
diverged=logical(U.DIVERGED);
for k=1:numel(continuous)
    U.(continuous{k})(diverged)=NaN;
end
[G,S]=findgroups(U(:,{'scenario','scenarioLabel','arm','methodLabel'}));
S.n=splitapply(@numel,U.RMSE,G);
S.nContinuousEligible=splitapply(@(x) nnz(isfinite(x)),U.RMSE,G);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,G);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,G);
S.divergences=splitapply(@sum,U.DIVERGED,G);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,G);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,G);
S.meanChannelUtil=splitapply(@finiteMean,U.CHANNEL_UTIL,G);
S.meanCollisions=splitapply(@finiteMean,U.COLLISION_FRAMES,G);
S.meanDataAttempts=splitapply(@finiteMean,U.DATA_ATTEMPTED,G);
S.meanAckAttempts=splitapply(@finiteMean,U.ACK_ATTEMPTED,G);
S.meanLocalBusy=splitapply(@finiteMean,U.MEAN_LOCAL_BUSY,G);
S.actualPAccess=splitapply(@finiteMean,U.pAccess,G);

end


function P=primaryTests(T,R)

P=table();
for c=R.primaryCells
    A=armRows(T,R,c{1},R.candidate);
    B=armRows(T,R,c{1},R.primaryComparator);
    validatePair(A,B,c{1},'primary');
    for m=1:numel(R.primaryMetrics)
        metric=R.primaryMetrics{m};
        [a,b]=continuousPair(A,B,metric);
        t=pairedCI(a,b,numel(R.seeds));
        boot=pairedBootstrapCI(a,b,R.bootstrapReplicates, ...
            R.bootstrapSeed,numel(R.seeds));
        pRaw=oneSidedPairedP(a,b);
        row=table(string(c{1}),string(metric),mean(a,'omitnan'), ...
            mean(b,'omitnan'),t.meanD,t.lo,t.hi,boot.lo,boot.hi,pRaw, ...
            NaN,t.nRequested,t.nPairs,t.nDropped,double(t.complete),false, ...
            'VariableNames',{'cell','metric','meanCandidate','meanAccess', ...
            'difference','pairedTLo','pairedTHi','bootstrapLo','bootstrapHi', ...
            'oneSidedPRaw','holmAdjustedP','nRequested','nPairs','nDropped', ...
            'complete','rejectAfterHolm'});
        P=[P; row]; %#ok<AGROW>
    end
end
P.holmAdjustedP=holmAdjustP(P.oneSidedPRaw);
P.rejectAfterHolm=P.complete==1 & P.difference<0 & ...
    P.holmAdjustedP<R.familywiseAlpha;

end


function C=cellClaims(T,P,R)

C=table();
for c=R.primaryCells
    Q=P(P.cell==string(c{1}),:);
    A=armRows(T,R,c{1},R.candidate);
    B=armRows(T,R,c{1},R.primaryComparator);
    failA=sum(A.SAFEFAIL); failB=sum(B.SAFEFAIL);
    continuousPass=height(Q)==numel(R.primaryMetrics) && ...
        all(Q.rejectAfterHolm);
    safetyGuard=failA<=failB;
    row=table(string(c{1}),double(continuousPass),failA,failB, ...
        double(safetyGuard),double(continuousPass && safetyGuard), ...
        'VariableNames',{'cell','continuousPass','candidateFailures', ...
        'accessFailures','observedSafetyGuard','cellClaimSupported'});
    C=[C; row]; %#ok<AGROW>
end

end


function C=secondaryContrasts(T,R)

metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED'};
comparators=setdiff({R.arms.id},{R.candidate},'stable');
C=table();
for c=R.cells
    A=armRows(T,R,c.id,R.candidate);
    for comparator=comparators
        B=armRows(T,R,c.id,comparator{1});
        validatePair(A,B,c.id,comparator{1});
        for m=1:numel(metrics)
            metric=metrics{m};
            [a,b]=continuousPair(A,B,metric);
            t=pairedCI(a,b,numel(R.seeds));
            boot=pairedBootstrapCI(a,b,R.bootstrapReplicates, ...
                R.bootstrapSeed,numel(R.seeds));
            meanA=mean(a,'omitnan'); meanB=mean(b,'omitnan');
            relativePct=NaN;
            if meanB~=0, relativePct=100*(meanA-meanB)/abs(meanB); end
            row=table(string(c.id),string(comparator{1}),string(metric), ...
                meanA,meanB,relativePct,t.meanD,t.lo,t.hi,boot.lo,boot.hi, ...
                t.nRequested,t.nPairs,t.nDropped,double(t.complete), ...
                'VariableNames',{'cell','comparator','metric','meanCandidate', ...
                'meanComparator','relativePct','difference','pairedTLo', ...
                'pairedTHi','bootstrapLo','bootstrapHi','nRequested','nPairs', ...
                'nDropped','complete'});
            C=[C; row]; %#ok<AGROW>
        end
    end
end

end


function [S,P]=safetyAnalysis(T,R)

S=table(); P=table();
for c=R.cells
    for arm=R.arms
        Q=armRows(T,R,c.id,arm.id);
        w=wilsonCI(sum(Q.SAFEFAIL),numel(R.seeds),R.familywiseAlpha);
        row=table(string(c.id),string(arm.id),w.nFailure,w.nTotal, ...
            w.rate,w.lo,w.hi,sum(Q.DIVERGED),'VariableNames', ...
            {'cell','arm','failures','n','rate','wilsonLo','wilsonHi', ...
            'divergences'});
        S=[S; row]; %#ok<AGROW>
    end
    A=armRows(T,R,c.id,R.candidate);
    for arm=R.arms
        if strcmp(arm.id,R.candidate), continue; end
        B=armRows(T,R,c.id,arm.id);
        a=logical(A.SAFEFAIL); b=logical(B.SAFEFAIL);
        row=table(string(c.id),string(arm.id),sum(a),sum(b), ...
            sum(~a & b),sum(a & ~b),sum(a==b),numel(a), ...
            'VariableNames',{'cell','comparator','candidateFailures', ...
            'comparatorFailures','seedsImproved','seedsWorsened', ...
            'seedsEqual','nPairs'});
        P=[P; row]; %#ok<AGROW>
    end
end

end


function V=claimVerdict(P,C,R)

nRejected=nnz(P.rejectAfterHolm);
nCells=nnz(C.cellClaimSupported);
if nCells==numel(R.primaryCells)
    status='SUPPORTED_ALL_PREREGISTERED_CSMA_CELLS';
elseif nCells>0
    status='PARTIALLY_SUPPORTED';
else
    status='NOT_SUPPORTED';
end
V=struct('status',status,'candidate',R.candidate, ...
    'primaryComparator',R.primaryComparator,'holmTestsRejected',nRejected, ...
    'holmTestsTotal',height(P),'primaryCellsSupported',nCells, ...
    'primaryCellsTotal',numel(R.primaryCells), ...
    'observedSafetyGuardOnly',true,'populationSafetyClaimPermitted',false, ...
    'universalMacClaimPermitted',false,'alohaIsMandatoryBoundary',true);

end


function A=armRows(T,R,cellId,armId)

A=sortrows(T(T.scenario==string(cellId) & T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp14EHoldout: incomplete %s/%s arm.',cellId,armId);
end

end


function validatePair(A,B,cellId,contrast)

if ~isequal(A.seed,B.seed) || ...
        ~isequal(A.TRACE_HASH_EXACT,B.TRACE_HASH_EXACT) || ...
        ~isequal(A.CHANNEL_STATE_HASH,B.CHANNEL_STATE_HASH)
    error('analyzeExp14EHoldout: non-CRN pair %s/%s.',cellId,contrast);
end

end


function [a,b]=continuousPair(A,B,metric)

a=A.(metric); b=B.(metric);
invalid=logical(A.DIVERGED) | logical(B.DIVERGED);
a(invalid)=NaN; b(invalid)=NaN;

end


function p=oneSidedPairedP(a,b)

d=a(:)-b(:); d=d(isfinite(d));
if numel(d)<2, p=NaN; return; end
mu=mean(d); sigma=std(d);
if sigma==0
    if mu<0, p=0; elseif mu==0, p=0.5; else, p=1; end
else
    p=tcdf(mu/(sigma/sqrt(numel(d))),numel(d)-1);
end

end


function makeFigure(S,R)

colors=lines(numel(R.arms));
figure('Name','EXP14E holdout fixed arms','Color','w', ...
    'Position',[80 80 1350 850]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for c=1:numel(R.cells)
    ax=nexttile; hold(ax,'on');
    Q=S(S.scenario==string(R.cells(c).id),:);
    for k=1:numel(R.arms)
        q=Q(Q.arm==string(R.arms(k).id),:);
        marker='o'; sizeValue=65;
        if strcmp(R.arms(k).id,R.candidate), marker='p'; sizeValue=110; end
        scatter(ax,q.meanOfferedUtil,q.meanRMSE,sizeValue,colors(k,:), ...
            marker,'filled','DisplayName',R.arms(k).label);
        if q.safeFailures>0
            plot(ax,q.meanOfferedUtil,q.meanRMSE,'kx','MarkerSize',11, ...
                'LineWidth',1.6,'HandleVisibility','off');
        end
    end
    grid(ax,'on'); box(ax,'on');
    xlabel(ax,'Offered airtime utilization'); ylabel(ax,'RMSE [m]');
    title(ax,R.cells(c).label);
    if c==1, legend(ax,'Location','best','FontSize',7); end
end
sgtitle('EXP14E holdout (cross = any observed safety failure)');

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14EHoldout: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
