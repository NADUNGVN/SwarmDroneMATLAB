function A=analyzeExp18BResults(runDir)
%ANALYZEEXP18BRESULTS Frozen nine-test EXP18B confirmatory analysis.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp18BResults: runDir must be char or scalar string.');
end
runDir=char(runDir);
R=exp18bRegistry();
tidyPath=fullfile(runDir,'tidy.csv');
gatePath=fullfile(runDir,'gates.csv');
if exist(tidyPath,'file')~=2 || exist(gatePath,'file')~=2
    error('analyzeExp18BResults: tidy.csv and gates.csv are required.');
end
T=readtable(tidyPath,'TextType','string','Delimiter',',');
G=readtable(gatePath,'TextType','string','Delimiter',',');
if height(T)~=R.expectedRuns || ~all(G.passed==1)
    error('analyzeExp18BResults: matrix or integrity gates are incomplete.');
end

A=struct();
A.summary=summarizeRows(T);
A.primaryTests=primaryTests(T,R);
A.aliasAudit=aliasAudit(T,R);
A.calibration=calibrationTable(T,R);
A.secondaryContrasts=secondaryContrasts(T,R);
[A.safetySummary,A.pairedSafety]=safetyAnalysis(T,R);
A.boundaryGuard=boundaryGuard(T,R);
A.claimVerdict=claimVerdict(T,A.primaryTests,A.aliasAudit, ...
    A.boundaryGuard,R);

writetable(A.summary,fullfile(runDir,'analysis_summary.csv'));
writetable(A.primaryTests,fullfile(runDir,'primary_holm_tests.csv'));
writetable(A.aliasAudit,fullfile(runDir,'candidate_alias_audit.csv'));
writetable(A.calibration,fullfile(runDir,'service_calibration.csv'));
writetable(A.secondaryContrasts, ...
    fullfile(runDir,'secondary_paired_contrasts.csv'));
writetable(A.safetySummary,fullfile(runDir,'safety_wilson.csv'));
writetable(A.pairedSafety,fullfile(runDir,'paired_safety_counts.csv'));
writetable(A.boundaryGuard,fullfile(runDir,'boundary_safety_guard.csv'));
writeJson(fullfile(runDir,'claim_verdict.json'),A.claimVerdict);
manifest=struct('version',R.version,'rows',height(T), ...
    'primaryTests',height(A.primaryTests), ...
    'holmFamilySize',R.primaryFamilySize, ...
    'bootstrapReplicates',R.bootstrapReplicates, ...
    'bootstrapSeed',R.bootstrapSeed, ...
    'familywiseAlpha',R.familywiseAlpha, ...
    'screenIsNecessityClaim',false, ...
    'populationSafetyClaimPermitted',false, ...
    'universalOptimalityClaimPermitted',false, ...
    'hardwareClaimPermitted',false, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writeJson(fullfile(runDir,'analysis_manifest.json'),manifest);

end


function S=summarizeRows(T)

U=T;
continuous={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_GOODPUT_HZ','ACK_STANDALONE'};
diverged=logical(U.DIVERGED);
for k=1:numel(continuous)
    U.(continuous{k})(diverged)=NaN;
end
[G,S]=findgroups(U(:,{'scenario','scenarioLabel','macType','arm', ...
    'methodLabel','route'}));
S.n=splitapply(@numel,U.RMSE,G);
S.nContinuousEligible=splitapply(@(x) nnz(isfinite(x)),U.RMSE,G);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,G);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,G);
S.divergences=splitapply(@sum,U.DIVERGED,G);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,G);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,G);
S.meanChannelUtil=splitapply(@finiteMean,U.CHANNEL_UTIL,G);
S.meanCollisionFrames=splitapply(@finiteMean,U.COLLISION_FRAMES,G);
S.meanDataGoodputHz=splitapply(@finiteMean,U.DATA_GOODPUT_HZ,G);
S.meanStandaloneAck=splitapply(@finiteMean,U.ACK_STANDALONE,G);
S.actualPAccess=splitapply(@finiteMean,U.pAccess,G);

end


function P=primaryTests(T,R)

P=table();
for k=1:numel(R.feasibleTests)
    f=R.feasibleTests(k);
    Q=armRows(T,R,f.cell,f.macType,R.candidate);
    observed=Q.DATA_GOODPUT_HZ./Q.N;
    target=Q.requiredUpdateRateHz;
    observed(logical(Q.DIVERGED))=NaN;
    target(logical(Q.DIVERGED))=NaN;
    row=testRow(f.id,'positive-screen',f.cell,f.macType,'rate-target', ...
        'DATA_GOODPUT_HZ_PER_NODE','greater',observed,target,R);
    P=[P; row]; %#ok<AGROW>
end

Q=armRows(T,R,R.abstentionCell,R.abstentionMac,R.candidate);
C=armRows(T,R,R.abstentionCell,R.abstentionMac, ...
    R.abstentionComparator);
validatePair(Q,C,R.abstentionCell,R.abstentionMac, ...
    R.abstentionComparator);
for spec={{'H6','RMSE'},{'H7','OFFERED_UTIL'}}
    id=spec{1}{1}; metric=spec{1}{2};
    [a,b]=continuousPair(Q,C,metric);
    row=testRow(id,'abstention-effect',R.abstentionCell, ...
        R.abstentionMac,R.abstentionComparator,metric,'less',a,b,R);
    P=[P; row]; %#ok<AGROW>
end

for spec={{'H8','COLLISION_FRAMES'},{'H9','OFFERED_UTIL'}}
    id=spec{1}{1}; metric=spec{1}{2};
    [a,b]=aggregateN10Aloha(T,R,metric);
    row=testRow(id,'n10-access-repair','mean-four-n10-core', ...
        'aloha',R.accessComparator,metric,'less',a,b,R);
    P=[P; row]; %#ok<AGROW>
end

if height(P)~=R.primaryFamilySize
    error('analyzeExp18BResults: primary family size changed.');
end
P.holmAdjustedP=holmAdjustP(P.oneSidedPRaw);
P.rejectAfterHolm=P.complete==1 & ...
    ((P.direction=="less" & P.difference<0) | ...
    (P.direction=="greater" & P.difference>0)) & ...
    P.holmAdjustedP<R.familywiseAlpha;

end


function row=testRow(id,component,cellId,macType,comparator,metric, ...
    direction,a,b,R)

t=pairedCI(a,b,numel(R.seeds));
boot=pairedBootstrapCI(a,b,R.bootstrapReplicates,R.bootstrapSeed, ...
    numel(R.seeds));
switch direction
    case 'less'
        pRaw=oneSidedP(a-b,'less');
    case 'greater'
        pRaw=oneSidedP(a-b,'greater');
    otherwise
        error('analyzeExp18BResults: unknown test direction.');
end
row=table(string(id),string(component),string(cellId),string(macType), ...
    string(comparator),string(metric),string(direction), ...
    mean(a,'omitnan'),mean(b,'omitnan'),t.meanD,t.lo,t.hi, ...
    boot.lo,boot.hi,pRaw,NaN,t.nRequested,t.nPairs,t.nDropped, ...
    double(t.complete),false,'VariableNames', ...
    {'id','component','cell','macType','comparator','metric','direction', ...
    'meanCandidateOrObserved','meanComparatorOrTarget','difference', ...
    'pairedTLo','pairedTHi','bootstrapLo','bootstrapHi', ...
    'oneSidedPRaw','holmAdjustedP','nRequested','nPairs','nDropped', ...
    'complete','rejectAfterHolm'});

end


function [a,b]=aggregateN10Aloha(T,R,metric)

n=numel(R.seeds); a=NaN(n,1); b=NaN(n,1);
for s=1:n
    candidate=zeros(numel(R.n10CollisionCells),1);
    legacy=zeros(numel(R.n10CollisionCells),1);
    valid=true;
    for c=1:numel(R.n10CollisionCells)
        cellId=R.n10CollisionCells{c};
        A=T(T.seed==R.seeds(s) & T.scenario==string(cellId) & ...
            T.macType=="aloha" & T.arm==string(R.candidate),:);
        B=T(T.seed==R.seeds(s) & T.scenario==string(cellId) & ...
            T.macType=="aloha" & T.arm==string(R.accessComparator),:);
        valid=valid && height(A)==1 && height(B)==1 && ...
            A.DIVERGED==0 && B.DIVERGED==0 && ...
            A.TRACE_HASH_EXACT==B.TRACE_HASH_EXACT && ...
            A.CHANNEL_STATE_HASH==B.CHANNEL_STATE_HASH;
        if valid
            candidate(c)=A.(metric);
            legacy(c)=B.(metric);
        end
    end
    if valid
        a(s)=mean(candidate); b(s)=mean(legacy);
    end
end

end


function A=aliasAudit(T,R)

A=table();
for c=R.cells
    for m=1:numel(R.macTypes)
        mac=R.macTypes{m};
        X=armRows(T,R,c.id,mac,R.candidate);
        reference=char(X.routedReference(1));
        Y=armRows(T,R,c.id,mac,reference);
        validatePair(X,Y,c.id,mac,reference);
        exact=true; maxDifference=0;
        for f=1:numel(R.aliasFields)
            name=R.aliasFields{f};
            exact=exact && isequaln(X.(name),Y.(name));
            d=abs(X.(name)-Y.(name)); d=d(isfinite(d));
            if ~isempty(d), maxDifference=max(maxDifference,max(d)); end
        end
        row=table(string(c.id),string(mac),string(reference), ...
            double(exact),maxDifference,numel(R.aliasFields), ...
            'VariableNames',{'cell','macType','routedReference', ...
            'allFieldsExact','maxAbsDifference','fieldsChecked'});
        A=[A; row]; %#ok<AGROW>
    end
end

end


function C=calibrationTable(T,R)

C=table();
for c=R.cells
    for m=1:numel(R.macTypes)
        mac=R.macTypes{m};
        Q=armRows(T,R,c.id,mac,R.candidate);
        observed=Q.DATA_GOODPUT_HZ./Q.N;
        observed(logical(Q.DIVERGED))=NaN;
        predicted=Q.successfulUpdateRateHz(1);
        target=Q.requiredUpdateRateHz(1);
        ratio=Q.serviceRatio(1);
        [~,~,ci]=meanCI(observed);
        row=table(string(c.id),string(mac),Q.serviceCertificateFeasible(1), ...
            predicted,target,ratio,mean(observed,'omitnan'), ...
            mean(observed,'omitnan')-predicted,ci(1),ci(2), ...
            double(mean(observed,'omitnan')>target),sum(Q.SAFEFAIL), ...
            mean(Q.ACK_STANDALONE),nnz(isfinite(observed)), ...
            'VariableNames',{'cell','macType','screenFeasible', ...
            'predictedPerNodeHz','requiredPerNodeHz','serviceRatio', ...
            'observedPerNodeHz','calibrationErrorHz','observedTLo', ...
            'observedTHi','cellMeanExceedsTarget','safeFailures', ...
            'meanStandaloneAck','nEligible'});
        C=[C; row]; %#ok<AGROW>
    end
end

end


function C=secondaryContrasts(T,R)

metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','COLLISION_FRAMES', ...
    'ACK_STANDALONE'};
comparators={'frame-piggyback','frame-adaptive','legacy-selector'};
C=table();
for c=R.cells
    for m=1:numel(R.macTypes)
        mac=R.macTypes{m};
        A=armRows(T,R,c.id,mac,R.candidate);
        for k=1:numel(comparators)
            comparator=comparators{k};
            B=armRows(T,R,c.id,mac,comparator);
            validatePair(A,B,c.id,mac,comparator);
            for q=1:numel(metrics)
                metric=metrics{q};
                [a,b]=continuousPair(A,B,metric);
                t=pairedCI(a,b,numel(R.seeds));
                boot=pairedBootstrapCI(a,b,R.bootstrapReplicates, ...
                    R.bootstrapSeed,numel(R.seeds));
                meanA=mean(a,'omitnan'); meanB=mean(b,'omitnan');
                relativePct=NaN;
                if meanB~=0, relativePct=100*(meanA-meanB)/abs(meanB); end
                row=table(string(c.id),string(mac),string(comparator), ...
                    string(metric),meanA,meanB,relativePct,t.meanD,t.lo,t.hi, ...
                    boot.lo,boot.hi,t.nRequested,t.nPairs,t.nDropped, ...
                    double(t.complete),'VariableNames',{'cell','macType', ...
                    'comparator','metric','meanCandidate','meanComparator', ...
                    'relativePct','difference','pairedTLo','pairedTHi', ...
                    'bootstrapLo','bootstrapHi','nRequested','nPairs', ...
                    'nDropped','complete'});
                C=[C; row]; %#ok<AGROW>
            end
        end
    end
end

end


function [S,P]=safetyAnalysis(T,R)

S=table(); P=table();
for c=R.cells
    for m=1:numel(R.macTypes)
        mac=R.macTypes{m};
        A=armRows(T,R,c.id,mac,R.candidate);
        for k=1:numel(R.arms)
            arm=R.arms(k);
            Q=armRows(T,R,c.id,mac,arm.id);
            w=wilsonCI(sum(Q.SAFEFAIL),numel(R.seeds),R.familywiseAlpha);
            row=table(string(c.id),string(mac),string(arm.id), ...
                w.nFailure,w.nTotal,w.rate,w.lo,w.hi,sum(Q.DIVERGED), ...
                'VariableNames',{'cell','macType','arm','failures','n', ...
                'rate','wilsonLo','wilsonHi','divergences'});
            S=[S; row]; %#ok<AGROW>
            if strcmp(arm.id,R.candidate), continue; end
            a=logical(A.SAFEFAIL); b=logical(Q.SAFEFAIL);
            pair=table(string(c.id),string(mac),string(arm.id),sum(a), ...
                sum(b),sum(~a & b),sum(a & ~b),sum(a==b),numel(a), ...
                'VariableNames',{'cell','macType','comparator', ...
                'candidateFailures','comparatorFailures','seedsImproved', ...
                'seedsWorsened','seedsEqual','nPairs'});
            P=[P; pair]; %#ok<AGROW>
        end
    end
end

end


function G=boundaryGuard(T,R)

A=armRows(T,R,R.abstentionCell,R.abstentionMac,R.candidate);
B=armRows(T,R,R.abstentionCell,R.abstentionMac, ...
    R.abstentionComparator);
C=armRows(T,R,R.abstentionCell,R.abstentionMac,R.accessComparator);
fa=sum(A.SAFEFAIL); fb=sum(B.SAFEFAIL); fc=sum(C.SAFEFAIL);
G=table(string(R.abstentionCell),string(R.abstentionMac),fa,fb,fc, ...
    double(fa<=fb && fa<=fc),'VariableNames',{'cell','macType', ...
    'candidateFailures','frameAdaptiveFailures','legacyFailures', ...
    'observedSafetyGuard'});

end


function V=claimVerdict(T,P,A,G,R)

allTests=height(P)==R.primaryFamilySize && all(P.rejectAfterHolm);
aliasPass=height(A)==numel(R.cells)*numel(R.macTypes) && ...
    all(A.allFieldsExact==1);
candidate=T(T.arm==string(R.candidate),:);
infeasible=candidate.serviceCertificateFeasible==0;
abstentionPass=all(candidate.ACK_STANDALONE(infeasible)==0) && ...
    all(candidate.CONTEXT_ACK_PERMITTED(infeasible)==0);
safetyPass=all(G.observedSafetyGuard==1);
if allTests && aliasPass && abstentionPass && safetyPass
    status='SUPPORTED_WITHIN_REGISTERED_SCOPE';
else
    status='PARTIAL_OR_NOT_SUPPORTED';
end
V=struct('status',status,'candidate',R.candidate, ...
    'holmTestsRejected',nnz(P.rejectAfterHolm), ...
    'holmTestsTotal',height(P), ...
    'positiveScreenTestsRejected', ...
    nnz(P.component=="positive-screen" & P.rejectAfterHolm), ...
    'positiveScreenTestsTotal',numel(R.feasibleTests), ...
    'abstentionTestsRejected', ...
    nnz(P.component=="abstention-effect" & P.rejectAfterHolm), ...
    'abstentionTestsTotal',2,'accessRepairTestsRejected', ...
    nnz(P.component=="n10-access-repair" & P.rejectAfterHolm), ...
    'accessRepairTestsTotal',2,'exactAliasGatePassed',aliasPass, ...
    'infeasibleAbstentionGatePassed',abstentionPass, ...
    'boundarySafetyGuardPassed',safetyPass, ...
    'screenNecessityClaimPermitted',false, ...
    'populationSafetyClaimPermitted',false, ...
    'universalOptimalityClaimPermitted',false, ...
    'hardwareClaimPermitted',false, ...
    'measuredTraceBenchPermitted',strcmp(status, ...
    'SUPPORTED_WITHIN_REGISTERED_SCOPE'));

end


function A=armRows(T,R,cellId,macType,armId)

A=sortrows(T(T.scenario==string(cellId) & ...
    T.macType==string(macType) & T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp18BResults: incomplete %s/%s/%s arm.', ...
        cellId,macType,armId);
end

end


function validatePair(A,B,cellId,macType,contrast)

if ~isequal(A.seed,B.seed) || ...
        ~isequal(A.TRACE_HASH_EXACT,B.TRACE_HASH_EXACT) || ...
        ~isequal(A.CHANNEL_STATE_HASH,B.CHANNEL_STATE_HASH) || ...
        ~isequal(A.ESTIMATOR_HASH_EXACT,B.ESTIMATOR_HASH_EXACT)
    error('analyzeExp18BResults: non-CRN pair %s/%s/%s.', ...
        cellId,macType,contrast);
end

end


function [a,b]=continuousPair(A,B,metric)

a=A.(metric); b=B.(metric);
invalid=logical(A.DIVERGED) | logical(B.DIVERGED);
a(invalid)=NaN; b(invalid)=NaN;

end


function p=oneSidedP(d,direction)

d=d(:); d=d(isfinite(d));
if numel(d)<2, p=NaN; return; end
mu=mean(d); sigma=std(d);
if sigma==0
    switch direction
        case 'less'
            if mu<0, p=0; elseif mu==0, p=0.5; else, p=1; end
        case 'greater'
            if mu>0, p=0; elseif mu==0, p=0.5; else, p=1; end
    end
    return;
end
t=mu/(sigma/sqrt(numel(d)));
if strcmp(direction,'less')
    p=tcdf(t,numel(d)-1);
else
    p=1-tcdf(t,numel(d)-1);
end

end


function [mu,se,ci]=meanCI(x)

x=x(isfinite(x)); mu=mean(x); se=std(x)/sqrt(numel(x));
if numel(x)<2
    ci=[NaN NaN];
else
    half=tinv(0.975,numel(x)-1)*se;
    ci=[mu-half mu+half];
end

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp18BResults: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
