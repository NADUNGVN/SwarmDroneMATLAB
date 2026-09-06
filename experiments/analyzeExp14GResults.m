function A=analyzeExp14GResults(runDir)
%ANALYZEEXP14GRESULTS Descriptive causal branch-at-decision analysis.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp14GResults: runDir must be char or scalar string.');
end
runDir=char(runDir);
R=exp14gRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=52831592 || registryLeaves~=31
    error('analyzeExp14GResults: registry mismatch.');
end
P=readtable(fullfile(runDir,'branch_pairs.csv'), ...
    'TextType','string','Delimiter',',');
G=readtable(fullfile(runDir,'gates.csv'), ...
    'TextType','string','Delimiter',',');
if ~all(G.passed==1)
    error('analyzeExp14GResults: integrity gates must pass first.');
end

summary=repmat(emptySummary(),numel(R.cells),1);
long=repmat(emptyEffect(),0,1);
metrics={'meanLeadSeconds','ackAirtimeCost','dataAirtimeSaved', ...
    'netAirtimeBenefit','dataAttemptsSaved','collisionsSaved', ...
    'trueAoIIntegralBenefit','estimatedAoIIntegralBenefit', ...
    'controlLossIntegralBenefit','minimumSeparationBenefit'};
for c=1:numel(R.cells)
    Q=P(P.scenario==string(R.cells(c).id),:);
    if height(Q)<R.minimumEventsPerCell
        error('analyzeExp14GResults: insufficient support in %s.',R.cells(c).id);
    end
    row=emptySummary();
    row.scenario=R.cells(c).id; row.scenarioLabel=R.cells(c).label;
    row.nDecisions=height(Q); row.nParentSeeds=numel(unique(Q.seed));
    row.totalEntries=sum(Q.nEntries);
    row.positiveLeadEntryFraction=sum(Q.positiveLeadEntries)/sum(Q.nEntries);
    row.actualConfirmationFraction=sum(Q.actualConfirmedEntries)/sum(Q.nEntries);
    row.shadowConfirmationFraction=sum(Q.shadowConfirmedEntries)/sum(Q.nEntries);
    row.meanLocalBusy=mean(Q.localBusy); row.meanPendingAge=mean(Q.pendingAge);
    row.meanEntries=mean(Q.nEntries); row.forcedFraction=mean(Q.forced);
    resource=Q.netAirtimeBenefit;
    freshness=Q.trueAoIIntegralBenefit;
    control=Q.controlLossIntegralBenefit;
    tol=1e-12;
    beneficial=resource>tol & freshness>=-tol & control>=-tol;
    harmful=resource<-tol & freshness<=tol & control<=tol;
    row.paretoBeneficialDecisions=sum(beneficial);
    row.paretoHarmfulDecisions=sum(harmful);
    row.mixedOrNullDecisions=height(Q)-sum(beneficial)-sum(harmful);
    summary(c)=row;

    for m=1:numel(metrics)
        ci=oneSampleCI(Q.(metrics{m}));
        x=emptyEffect(); x.scenario=R.cells(c).id;
        x.metric=metrics{m}; x.nDecisions=height(Q);
        x.meanEffect=ci.mean; x.ciLo=ci.lo; x.ciHi=ci.hi;
        x.crossesZero=ci.lo<=0 && ci.hi>=0;
        long(end+1,1)=x; %#ok<AGROW>
    end
end

A=struct();
A.summary=struct2table(summary);
A.effects=struct2table(long);
A.readiness=struct( ...
    'analysisStatus','DEVELOPMENT_CAUSAL_BRANCH_STUDY', ...
    'confirmatoryClaimPermitted',false, ...
    'thresholdTuningPermitted',false, ...
    'perDecisionCausalLeadIdentified',true, ...
    'sharedPreDecisionStateVerified',true, ...
    'outcomeBlindSampling',true, ...
    'oneDecisionPerParentSeedCell',true, ...
    'eventLevelIIDInferencePermittedWithinCell',false, ...
    'decisionLevelDescriptiveIntervalsPermitted',true, ...
    'predictorFittingPermitted',false, ...
    'predictiveCertificateReady',false, ...
    'reasonNotReady', ...
    ['EXP14G estimates effects but did not preregister a predictor or ' ...
     'lead-benefit envelope; fitting one here would reuse development outcomes'], ...
    'nextRequiredStep', ...
    ['freeze an interpretable causal-at-decision rule, then validate it ' ...
     'on a disjoint seed block without refitting'], ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writetable(A.summary,fullfile(runDir,'causal_summary.csv'));
writetable(A.effects,fullfile(runDir,'causal_effects_long.csv'));
writeJson(fullfile(runDir,'readiness.json'),A.readiness);

end


function S=oneSampleCI(x)

x=x(isfinite(x)); n=numel(x);
if n<2, S=struct('mean',mean(x),'lo',NaN,'hi',NaN); return; end
S.mean=mean(x); half=tinv(0.975,n-1)*std(x)/sqrt(n);
S.lo=S.mean-half; S.hi=S.mean+half;

end


function row=emptySummary()

row=struct('scenario','','scenarioLabel','','nDecisions',NaN, ...
    'nParentSeeds',NaN,'totalEntries',NaN, ...
    'positiveLeadEntryFraction',NaN,'actualConfirmationFraction',NaN, ...
    'shadowConfirmationFraction',NaN,'meanLocalBusy',NaN, ...
    'meanPendingAge',NaN,'meanEntries',NaN,'forcedFraction',NaN, ...
    'paretoBeneficialDecisions',NaN,'paretoHarmfulDecisions',NaN, ...
    'mixedOrNullDecisions',NaN);

end


function row=emptyEffect()

row=struct('scenario','','metric','','nDecisions',NaN, ...
    'meanEffect',NaN,'ciLo',NaN,'ciHi',NaN,'crossesZero',false);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14GResults: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
