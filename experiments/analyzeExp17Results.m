function A=analyzeExp17Results(runDir)
%ANALYZEEXP17RESULTS Frozen operating-envelope analysis.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp17Results: runDir must be char or scalar string.');
end
runDir=char(runDir);
R=exp17Registry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=123727884 || registryLeaves~=122
    error('analyzeExp17Results: frozen registry hash mismatch.');
end
T=readtable(fullfile(runDir,'tidy.csv'),'TextType','string','Delimiter',',');
G=readtable(fullfile(runDir,'gates.csv'),'TextType','string','Delimiter',',');
if height(T)~=R.expectedRuns || ~all(G.passed==1)
    error('analyzeExp17Results: matrix or integrity gates are incomplete.');
end

A=struct();
A.summary=summarizeRows(T);
[A.seedEffects,A.primaryTests]=primaryAnalysis(T,R);
A.safetySummary=safetySummary(T,R);
A.safetyGuards=safetyGuards(T,R);
A.metricClaims=metricClaims(A.primaryTests,R);
A.cellClaims=cellClaims(A.metricClaims,A.safetyGuards,R);
A.boundaryEffects=boundaryEffects(T,R);
A.continuationVerdict=continuationVerdict(A.cellClaims,A.safetyGuards,R);
A.claimVerdict=claimVerdict(A.primaryTests,A.cellClaims, ...
    A.continuationVerdict,R);

writetable(A.summary,fullfile(runDir,'analysis_summary.csv'));
writetable(A.seedEffects,fullfile(runDir,'seed_level_effects.csv'));
writetable(A.primaryTests,fullfile(runDir,'primary_48_holm_tests.csv'));
writetable(A.metricClaims,fullfile(runDir,'core_metric_claims.csv'));
writetable(A.cellClaims,fullfile(runDir,'core_cell_claims.csv'));
writetable(A.safetySummary,fullfile(runDir,'safety_wilson.csv'));
writetable(A.safetyGuards,fullfile(runDir,'observed_safety_guards.csv'));
writetable(A.boundaryEffects,fullfile(runDir,'boundary_effects.csv'));
writeJson(fullfile(runDir,'continuation_verdict.json'),A.continuationVerdict);
writeJson(fullfile(runDir,'claim_verdict.json'),A.claimVerdict);
manifest=struct('registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'rows',height(T),'primaryTests',height(A.primaryTests), ...
    'holmFamilySize',height(A.primaryTests), ...
    'bootstrapReplicates',R.bootstrapReplicates, ...
    'bootstrapSeed',R.bootstrapSeed,'familywiseAlpha',R.familywiseAlpha, ...
    'boundaryConfirmatory',false,'interactionComputedWithinSeed',true, ...
    'namedMacClaimPermitted',false,'hardwareClaimPermitted',false, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writeJson(fullfile(runDir,'analysis_manifest.json'),manifest);
makeFigure(A.primaryTests,R);

end


function S=summarizeRows(T)

U=T; continuous={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED','ACK_STANDALONE'};
diverged=logical(U.DIVERGED);
for k=1:numel(continuous), U.(continuous{k})(diverged)=NaN; end
[G,S]=findgroups(U(:,{'scenario','scenarioLabel','arm','methodLabel', ...
    'macType','route','coreFlag','channelRegime','contextModifier'}));
S.n=splitapply(@numel,U.RMSE,G);
S.nEligible=splitapply(@(x) nnz(isfinite(x)),U.RMSE,G);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,G);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,G);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,G);
S.meanChannelUtil=splitapply(@finiteMean,U.CHANNEL_UTIL,G);
S.meanCollisions=splitapply(@finiteMean,U.COLLISION_FRAMES,G);
S.meanDataAttempts=splitapply(@finiteMean,U.DATA_ATTEMPTED,G);
S.meanAckAttempts=splitapply(@finiteMean,U.ACK_ATTEMPTED,G);
S.meanStandaloneAcks=splitapply(@finiteMean,U.ACK_STANDALONE,G);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,G);
S.divergences=splitapply(@sum,U.DIVERGED,G);

end


function [E,P]=primaryAnalysis(T,R)

E=table(); P=table();
for c=R.cells(strcmp({R.cells.role},'core'))
    [effects,tests]=contextEffects(T,R,c,true);
    E=[E; effects]; %#ok<AGROW>
    P=[P; tests]; %#ok<AGROW>
end
P.holmAdjustedP=holmAdjustP(P.oneSidedPRaw);
P.rejectAfterHolm=P.complete==1 & P.estimate<0 & ...
    P.holmAdjustedP<R.familywiseAlpha;

end


function [E,P]=contextEffects(T,R,c,includeTests)

CA=armRows(T,R,c.id,'csma-adaptive');
CP=armRows(T,R,c.id,'csma-piggyback');
AA=armRows(T,R,c.id,'aloha-adaptive');
AP=armRows(T,R,c.id,'aloha-piggyback');
validateGroup(CA,CP,AA,AP,c.id);
E=table(R.seeds,repmat(string(c.id),numel(R.seeds),1), ...
    'VariableNames',{'seed','cell'});
P=table();
for m=1:numel(R.primaryMetrics)
    metric=R.primaryMetrics{m};
    ca=eligibleMetric(CA,metric); cp=eligibleMetric(CP,metric);
    aa=eligibleMetric(AA,metric); ap=eligibleMetric(AP,metric);
    dCsma=ca-cp; dAloha=aa-ap; interaction=dAloha-dCsma;
    stem=lower(metric);
    E.([stem 'AdaptiveMinusPiggyCsma'])=dCsma;
    E.([stem 'AdaptiveMinusPiggyAloha'])=dAloha;
    E.([stem 'Interaction'])=interaction;
    if includeTests
        P=[P; testRow(c.id,metric,'csma-simple', ...
            'piggyback(CSMA)-adaptive(CSMA)',cp-ca,R,true); ...
            testRow(c.id,metric,'aloha-simple', ...
            'adaptive(ALOHA)-piggyback(ALOHA)',dAloha,R,true); ...
            testRow(c.id,metric,'interaction', ...
            '(adaptive-piggyback)_ALOHA-(adaptive-piggyback)_CSMA', ...
            interaction,R,true)]; %#ok<AGROW>
    end
end

end


function row=testRow(cellId,metric,testType,formula,d,R,withP)

zero=zeros(size(d)); t=pairedCI(d,zero,numel(R.seeds));
boot=pairedBootstrapCI(d,zero,R.bootstrapReplicates, ...
    R.bootstrapSeed,numel(R.seeds));
sigma=std(d(isfinite(d))); dz=NaN;
if isfinite(sigma) && sigma>0, dz=mean(d,'omitnan')/sigma; end
pRaw=NaN;
if withP, pRaw=oneSidedZeroP(d); end
row=table(string(cellId),string(metric),string(testType),string(formula), ...
    t.meanD,t.lo,t.hi,boot.lo,boot.hi,dz,pRaw,NaN, ...
    t.nRequested,t.nPairs,t.nDropped,double(t.complete),false, ...
    'VariableNames',{'cell','metric','testType','formula','estimate', ...
    'pairedTLo','pairedTHi','bootstrapLo','bootstrapHi','standardizedDz', ...
    'oneSidedPRaw','holmAdjustedP','nRequested','nPairs','nDropped', ...
    'complete','rejectAfterHolm'});

end


function C=metricClaims(P,R)

C=table();
for cellId=R.coreCells
    for metric=R.primaryMetrics
        Q=P(P.cell==string(cellId{1}) & P.metric==string(metric{1}),:);
        supported=height(Q)==numel(R.primaryTestTypes) && ...
            all(Q.rejectAfterHolm);
        csma=Q(Q.testType=="csma-simple",:);
        aloha=Q(Q.testType=="aloha-simple",:);
        interaction=Q(Q.testType=="interaction",:);
        row=table(string(cellId{1}),string(metric{1}),csma.estimate, ...
            aloha.estimate,interaction.estimate,double(supported), ...
            'VariableNames',{'cell','metric','orientedCsmaEffect', ...
            'adaptiveMinusPiggyAloha','interaction','metricSupported'});
        C=[C; row]; %#ok<AGROW>
    end
end

end


function C=cellClaims(M,G,R)

C=table();
for cellId=R.coreCells
    c=R.cells(strcmp({R.cells.id},cellId{1}));
    Q=M(M.cell==string(cellId{1}),:);
    S=G(G.cell==string(cellId{1}),:);
    metricsPass=height(Q)==numel(R.primaryMetrics) && all(Q.metricSupported);
    safetyPass=height(S)==2 && all(S.observedGuardPassed);
    row=table(string(cellId{1}),c.N,string(c.channel),c.background, ...
        double(metricsPass),double(safetyPass), ...
        double(metricsPass && safetyPass),'VariableNames', ...
        {'cell','N','channel','background','bothMetricsSupported', ...
        'bothSafetyGuardsPassed','cellSupported'});
    C=[C; row]; %#ok<AGROW>
end

end


function S=safetySummary(T,R)

S=table();
for c=R.cells
    for arm=R.arms
        Q=armRows(T,R,c.id,arm.id);
        w=wilsonCI(sum(Q.SAFEFAIL),numel(R.seeds),R.familywiseAlpha);
        row=table(string(c.id),string(c.role),string(arm.id), ...
            string(arm.macType),string(arm.route),w.nFailure,w.nTotal, ...
            w.rate,w.lo,w.hi,sum(Q.DIVERGED),'VariableNames', ...
            {'cell','role','arm','macType','route','failures','n','rate', ...
            'wilsonLo','wilsonHi','divergences'});
        S=[S; row]; %#ok<AGROW>
    end
end

end


function G=safetyGuards(T,R)

definitions=struct('macType',{'csma','aloha'}, ...
    'winner',{'csma-piggyback','aloha-adaptive'}, ...
    'loser',{'csma-adaptive','aloha-piggyback'});
G=table();
for c=R.cells
    for d=definitions
        W=armRows(T,R,c.id,d.winner); L=armRows(T,R,c.id,d.loser);
        win=logical(W.SAFEFAIL); lose=logical(L.SAFEFAIL);
        row=table(string(c.id),string(c.role),string(d.macType), ...
            string(d.winner),string(d.loser),sum(win),sum(lose), ...
            sum(~win & lose),sum(win & ~lose),sum(win==lose),numel(win), ...
            double(sum(win)<=sum(lose)),'VariableNames', ...
            {'cell','role','macType','registeredWinner','registeredLoser', ...
            'winnerFailures','loserFailures','seedsImproved','seedsWorsened', ...
            'seedsEqual','nPairs','observedGuardPassed'});
        G=[G; row]; %#ok<AGROW>
    end
end

end


function B=boundaryEffects(T,R)

B=table();
for c=R.cells(strcmp({R.cells.role},'boundary'))
    CA=armRows(T,R,c.id,'csma-adaptive');
    CP=armRows(T,R,c.id,'csma-piggyback');
    AA=armRows(T,R,c.id,'aloha-adaptive');
    AP=armRows(T,R,c.id,'aloha-piggyback');
    validateGroup(CA,CP,AA,AP,c.id);
    for metric=R.primaryMetrics
        ca=eligibleMetric(CA,metric{1}); cp=eligibleMetric(CP,metric{1});
        aa=eligibleMetric(AA,metric{1}); ap=eligibleMetric(AP,metric{1});
        dCsma=cp-ca; dAloha=aa-ap;
        interaction=(aa-ap)-(ca-cp);
        B=[B; testRow(c.id,metric{1},'csma-simple', ...
            'piggyback(CSMA)-adaptive(CSMA)',dCsma,R,false); ...
            testRow(c.id,metric{1},'aloha-simple', ...
            'adaptive(ALOHA)-piggyback(ALOHA)',dAloha,R,false); ...
            testRow(c.id,metric{1},'interaction', ...
            '(adaptive-piggyback)_ALOHA-(adaptive-piggyback)_CSMA', ...
            interaction,R,false)]; %#ok<AGROW>
    end
end

end


function V=continuationVerdict(C,G,R)

supported=logical(C.cellSupported);
basePass=any(C.cell==string(R.continuation.baseCell) & supported);
nCore=nnz(supported);
n5=nnz(supported & C.N==5); n10=nnz(supported & C.N==10);
channels=unique(C.channel(supported));
backgrounds=unique(C.background(supported));
channelPass=all(ismember(["moderate" "stressed"],channels));
backgroundPass=all(ismember([0 0.30],backgrounds));
coreGuards=G(G.role=="core",:);
safetyPass=all(coreGuards.observedGuardPassed==1);
pass=basePass && nCore>=R.continuation.minCoreSupported && ...
    n5>=R.continuation.minN5Supported && ...
    n10>=R.continuation.minN10Supported && channelPass && ...
    backgroundPass && safetyPass;
V=struct('status',ternary(pass,'PROCEED_TO_SENSITIVITY_AND_MEASURED_CSMA', ...
    'DO_NOT_PROCEED_WITH_GENERAL_SELECTOR'), ...
    'passed',pass,'baseCellSupported',basePass, ...
    'coreCellsSupported',nCore,'coreCellsTotal',height(C), ...
    'n5Supported',n5,'n10Supported',n10, ...
    'bothChannelLevelsRepresented',channelPass, ...
    'bothBackgroundLevelsRepresented',backgroundPass, ...
    'allCoreSafetyGuardsPassed',safetyPass);

end


function V=claimVerdict(P,C,H,R)

nRejected=nnz(P.rejectAfterHolm); nCells=nnz(C.cellSupported);
if nCells==numel(R.coreCells)
    status='SUPPORTED_FULL_REGISTERED_CORE_ENVELOPE';
elseif H.passed
    status='SUPPORTED_BOUNDED_CORE_ENVELOPE';
elseif nCells>0
    status='PARTIALLY_SUPPORTED_NO_CONTINUATION_GATE';
else
    status='NOT_SUPPORTED';
end
V=struct('status',status,'holmTestsRejected',nRejected, ...
    'holmTestsTotal',height(P),'coreCellsSupported',nCells, ...
    'coreCellsTotal',numel(R.coreCells),'continuationGatePassed',H.passed, ...
    'boundaryConfirmatory',false,'populationSafetyClaimPermitted',false, ...
    'namedMacClaimPermitted',false,'hardwareClaimPermitted',false);

end


function A=armRows(T,R,cellId,armId)

A=sortrows(T(T.scenario==string(cellId) & T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp17Results: incomplete %s/%s arm.',cellId,armId);
end

end


function validateGroup(CA,CP,AA,AP,cellId)

if ~isequal(CA.seed,CP.seed,AA.seed,AP.seed) || ...
        ~isequal(CA.TRACE_HASH_EXACT,CP.TRACE_HASH_EXACT, ...
        AA.TRACE_HASH_EXACT,AP.TRACE_HASH_EXACT) || ...
        ~isequal(CA.CHANNEL_STATE_HASH,CP.CHANNEL_STATE_HASH, ...
        AA.CHANNEL_STATE_HASH,AP.CHANNEL_STATE_HASH)
    error('analyzeExp17Results: %s is not cross-MAC CRN paired.',cellId);
end

end


function x=eligibleMetric(T,metric)

x=T.(metric); x(logical(T.DIVERGED))=NaN;

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


function makeFigure(P,R)

figure('Name','EXP17 operating-envelope interactions','Color','w', ...
    'Position',[80 80 1450 700]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
for m=1:numel(R.primaryMetrics)
    ax=nexttile; Q=P(P.metric==string(R.primaryMetrics{m}) & ...
        P.testType=="interaction",:);
    [~,order]=ismember(string(R.coreCells),Q.cell);
    Q=Q(order,:); x=1:height(Q);
    errorbar(ax,x,Q.estimate,Q.estimate-Q.pairedTLo, ...
        Q.pairedTHi-Q.estimate,'o','LineWidth',1.2,'MarkerFaceColor',[0.2 0.5 0.8]);
    yline(ax,0,'k--'); grid(ax,'on'); box(ax,'on');
    xticks(ax,x); xticklabels(ax,replace(Q.cell,'-',' '));
    xtickangle(ax,25); ylabel(ax,R.primaryMetrics{m});
    title(ax,'Within-seed route-by-MAC interaction (95% paired CI)');
end

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp17Results: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
