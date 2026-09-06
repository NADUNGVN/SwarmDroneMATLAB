function A=analyzeExp16Results(runDir)
%ANALYZEEXP16RESULTS Frozen route-by-MAC interaction analysis.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp16Results: runDir must be char or scalar string.');
end
runDir=char(runDir);
R=exp16Registry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=89775929 || registryLeaves~=56
    error('analyzeExp16Results: frozen registry hash mismatch.');
end
tidyPath=fullfile(runDir,'tidy.csv');
gatePath=fullfile(runDir,'gates.csv');
if exist(tidyPath,'file')~=2 || exist(gatePath,'file')~=2
    error('analyzeExp16Results: tidy.csv and gates.csv are required.');
end
T=readtable(tidyPath,'TextType','string','Delimiter',',');
G=readtable(gatePath,'TextType','string','Delimiter',',');
if height(T)~=R.expectedRuns || ~all(G.passed==1)
    error('analyzeExp16Results: matrix or integrity gates are incomplete.');
end

A=struct();
A.summary=summarizeRows(T);
[A.seedEffects,A.primaryTests]=primaryAnalysis(T,R);
A.metricClaims=metricClaims(A.primaryTests,R);
A.safetySummary=safetySummary(T,R);
A.safetyGuards=safetyGuards(T,R);
A.hybridContrasts=hybridContrasts(T,R);
A.claimVerdict=claimVerdict(A.primaryTests,A.metricClaims,A.safetyGuards,R);

writetable(A.summary,fullfile(runDir,'analysis_summary.csv'));
writetable(A.seedEffects,fullfile(runDir,'seed_level_factorial_effects.csv'));
writetable(A.primaryTests,fullfile(runDir,'primary_holm_tests.csv'));
writetable(A.metricClaims,fullfile(runDir,'metric_reversal_claims.csv'));
writetable(A.safetySummary,fullfile(runDir,'safety_wilson.csv'));
writetable(A.safetyGuards,fullfile(runDir,'registered_safety_guards.csv'));
writetable(A.hybridContrasts,fullfile(runDir,'hybrid_baseline_contrasts.csv'));
writeJson(fullfile(runDir,'claim_verdict.json'),A.claimVerdict);
manifest=struct('registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'rows',height(T),'primaryTests',height(A.primaryTests), ...
    'holmFamilySize',height(A.primaryTests), ...
    'bootstrapReplicates',R.bootstrapReplicates, ...
    'bootstrapSeed',R.bootstrapSeed,'familywiseAlpha',R.familywiseAlpha, ...
    'interactionComputedWithinSeed',true, ...
    'generalMacSelectorClaimPermitted',false, ...
    'namedMacClaimPermitted',false,'hardwareClaimPermitted',false, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writeJson(fullfile(runDir,'analysis_manifest.json'),manifest);
makeFigure(A.summary,R);

end


function S=summarizeRows(T)

U=T;
continuous={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED','ACK_STANDALONE'};
diverged=logical(U.DIVERGED);
for k=1:numel(continuous)
    U.(continuous{k})(diverged)=NaN;
end
[G,S]=findgroups(U(:,{'arm','methodLabel','macType','route', ...
    'primaryFactorialFlag'}));
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
S.meanStandaloneAcks=splitapply(@finiteMean,U.ACK_STANDALONE,G);

end


function [E,P]=primaryAnalysis(T,R)

CA=armRows(T,R,'csma-adaptive');
CP=armRows(T,R,'csma-piggyback');
AA=armRows(T,R,'aloha-adaptive');
AP=armRows(T,R,'aloha-piggyback');
validateCrossMacGroup(CA,CP,AA,AP);

E=table(R.seeds,'VariableNames',{'seed'});
P=table();
for m=1:numel(R.primaryMetrics)
    metric=R.primaryMetrics{m};
    ca=eligibleMetric(CA,metric); cp=eligibleMetric(CP,metric);
    aa=eligibleMetric(AA,metric); ap=eligibleMetric(AP,metric);
    dCsma=ca-cp;
    dAloha=aa-ap;
    interaction=dAloha-dCsma;
    stem=lower(metric);
    E.([stem 'AdaptiveMinusPiggyCsma'])=dCsma;
    E.([stem 'AdaptiveMinusPiggyAloha'])=dAloha;
    E.([stem 'Interaction'])=interaction;

    % All registered alternatives are oriented below zero.
    P=[P; testRow(metric,'csma-simple', ...
        'piggyback(CSMA)-adaptive(CSMA)',cp-ca,R); ...
        testRow(metric,'aloha-simple', ...
        'adaptive(ALOHA)-piggyback(ALOHA)',dAloha,R); ...
        testRow(metric,'interaction', ...
        '(adaptive-piggyback)_ALOHA-(adaptive-piggyback)_CSMA', ...
        interaction,R)]; %#ok<AGROW>
end
P.holmAdjustedP=holmAdjustP(P.oneSidedPRaw);
P.rejectAfterHolm=P.complete==1 & P.estimate<0 & ...
    P.holmAdjustedP<R.familywiseAlpha;

end


function row=testRow(metric,testType,formula,d,R)

zero=zeros(size(d));
t=pairedCI(d,zero,numel(R.seeds));
boot=pairedBootstrapCI(d,zero,R.bootstrapReplicates, ...
    R.bootstrapSeed,numel(R.seeds));
sigma=std(d(isfinite(d)));
dz=NaN;
if isfinite(sigma) && sigma>0, dz=mean(d,'omitnan')/sigma; end
pRaw=oneSidedZeroP(d);
row=table(string(metric),string(testType),string(formula), ...
    t.meanD,t.lo,t.hi,boot.lo,boot.hi,dz,pRaw,NaN, ...
    t.nRequested,t.nPairs,t.nDropped,double(t.complete),false, ...
    'VariableNames',{'metric','testType','formula','estimate', ...
    'pairedTLo','pairedTHi','bootstrapLo','bootstrapHi','standardizedDz', ...
    'oneSidedPRaw','holmAdjustedP','nRequested','nPairs','nDropped', ...
    'complete','rejectAfterHolm'});

end


function C=metricClaims(P,R)

C=table();
for m=1:numel(R.primaryMetrics)
    metric=R.primaryMetrics{m};
    Q=P(P.metric==string(metric),:);
    simpleCsma=Q(Q.testType=="csma-simple",:);
    simpleAloha=Q(Q.testType=="aloha-simple",:);
    interaction=Q(Q.testType=="interaction",:);
    supported=height(Q)==numel(R.primaryTestTypes) && ...
        all(Q.rejectAfterHolm);
    row=table(string(metric),simpleCsma.estimate,simpleAloha.estimate, ...
        interaction.estimate,double(supported),'VariableNames', ...
        {'metric','orientedCsmaEffect','adaptiveMinusPiggyAloha', ...
        'interaction','reversalSupported'});
    C=[C; row]; %#ok<AGROW>
end

end


function S=safetySummary(T,R)

S=table();
for arm=R.arms
    Q=armRows(T,R,arm.id);
    w=wilsonCI(sum(Q.SAFEFAIL),numel(R.seeds),R.familywiseAlpha);
    row=table(string(arm.id),string(arm.macType),string(arm.route), ...
        w.nFailure,w.nTotal,w.rate,w.lo,w.hi,sum(Q.DIVERGED), ...
        'VariableNames',{'arm','macType','route','failures','n','rate', ...
        'wilsonLo','wilsonHi','divergences'});
    S=[S; row]; %#ok<AGROW>
end

end


function G=safetyGuards(T,R)

definitions=struct( ...
    'macType',{'csma','aloha'}, ...
    'winner',{'csma-piggyback','aloha-adaptive'}, ...
    'loser',{'csma-adaptive','aloha-piggyback'});
G=table();
for d=definitions
    W=armRows(T,R,d.winner); L=armRows(T,R,d.loser);
    win=logical(W.SAFEFAIL); lose=logical(L.SAFEFAIL);
    row=table(string(d.macType),string(d.winner),string(d.loser), ...
        sum(win),sum(lose),sum(~win & lose),sum(win & ~lose), ...
        sum(win==lose),numel(win),double(sum(win)<=sum(lose)), ...
        'VariableNames',{'macType','registeredWinner','registeredLoser', ...
        'winnerFailures','loserFailures','seedsImproved','seedsWorsened', ...
        'seedsEqual','nPairs','observedGuardPassed'});
    G=[G; row]; %#ok<AGROW>
end

end


function C=hybridContrasts(T,R)

metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED','ACK_STANDALONE'};
C=table();
for mac={'csma','aloha'}
    H=armRows(T,R,[mac{1} '-fixed-hybrid']);
    for route={'adaptive','piggyback'}
        A=armRows(T,R,[mac{1} '-' route{1}]);
        for m=1:numel(metrics)
            metric=metrics{m};
            a=eligibleMetric(A,metric); h=eligibleMetric(H,metric);
            ci=pairedCI(a,h,numel(R.seeds));
            meanA=mean(a,'omitnan'); meanH=mean(h,'omitnan');
            relativePct=NaN;
            if meanH~=0, relativePct=100*(meanA-meanH)/abs(meanH); end
            row=table(string(mac{1}),string(route{1}),string(metric), ...
                meanA,meanH,relativePct,ci.meanD,ci.lo,ci.hi, ...
                ci.nPairs,ci.nDropped,double(ci.complete), ...
                'VariableNames',{'macType','route','metric','meanRoute', ...
                'meanHybrid','relativePct','difference','pairedTLo', ...
                'pairedTHi','nPairs','nDropped','complete'});
            C=[C; row]; %#ok<AGROW>
        end
    end
end

end


function V=claimVerdict(P,C,G,R)

nRejected=nnz(P.rejectAfterHolm);
nMetrics=nnz(C.reversalSupported);
safetyPass=all(G.observedGuardPassed==1);
if nRejected==R.primaryFamilySize && ...
        nMetrics==numel(R.primaryMetrics) && safetyPass
    status='SUPPORTED_REGISTERED_FACTORIAL_INTERACTION';
elseif nRejected>0
    status='PARTIALLY_SUPPORTED';
else
    status='NOT_SUPPORTED';
end
V=struct('status',status, ...
    'holmTestsRejected',nRejected,'holmTestsTotal',height(P), ...
    'metricsSupported',nMetrics,'metricsTotal',numel(R.primaryMetrics), ...
    'observedSafetyGuardsPassed',nnz(G.observedGuardPassed), ...
    'observedSafetyGuardsTotal',height(G), ...
    'observedSafetyGuardOnly',true, ...
    'populationSafetyClaimPermitted',false, ...
    'generalMacSelectorClaimPermitted',false, ...
    'namedMacClaimPermitted',false,'hardwareClaimPermitted',false);

end


function A=armRows(T,R,armId)

A=sortrows(T(T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp16Results: incomplete %s arm.',armId);
end

end


function validateCrossMacGroup(CA,CP,AA,AP)

if ~isequal(CA.seed,CP.seed,AA.seed,AP.seed) || ...
        ~isequal(CA.TRACE_HASH_EXACT,CP.TRACE_HASH_EXACT, ...
        AA.TRACE_HASH_EXACT,AP.TRACE_HASH_EXACT) || ...
        ~isequal(CA.CHANNEL_STATE_HASH,CP.CHANNEL_STATE_HASH, ...
        AA.CHANNEL_STATE_HASH,AP.CHANNEL_STATE_HASH)
    error('analyzeExp16Results: primary factorial is not cross-MAC CRN paired.');
end

end


function x=eligibleMetric(T,metric)

x=T.(metric);
x(logical(T.DIVERGED))=NaN;

end


function p=oneSidedZeroP(d)

d=d(:); d=d(isfinite(d));
if numel(d)<2, p=NaN; return; end
mu=mean(d); sigma=std(d);
if sigma==0
    if mu<0, p=0; elseif mu==0, p=0.5; else, p=1; end
else
    p=tcdf(mu/(sigma/sqrt(numel(d))),numel(d)-1);
end

end


function makeFigure(S,R)

routes={'adaptive','piggyback','fixed-hybrid'};
colors=lines(numel(routes));
figure('Name','EXP16 route-by-MAC interaction','Color','w', ...
    'Position',[100 100 1150 480]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
metrics={'meanRMSE','meanOfferedUtil'};
ylabels={'Formation RMSE [m]','Offered airtime utilization'};
for m=1:2
    ax=nexttile; hold(ax,'on');
    for r=1:numel(routes)
        Q=S(S.route==string(routes{r}),:);
        Q=sortrows(Q,'macType','descend');
        plot(ax,1:2,Q.(metrics{m}),'-o','Color',colors(r,:), ...
            'LineWidth',1.5,'MarkerFaceColor',colors(r,:), ...
            'DisplayName',routes{r});
    end
    xlim(ax,[0.75 2.25]); xticks(ax,1:2); xticklabels(ax,{'CSMA','ALOHA'});
    ylabel(ax,ylabels{m}); grid(ax,'on'); box(ax,'on');
    if m==1, legend(ax,'Location','best'); end
end
sgtitle(sprintf('EXP16 matched route-by-MAC design, %d paired seeds', ...
    numel(R.seeds)));

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp16Results: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
