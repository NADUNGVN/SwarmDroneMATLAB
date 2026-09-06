function A=analyzeExp14GSupportLimited(runDir)
%ANALYZEEXP14GSUPPORTLIMITED Audit cells meeting the frozen support minimum.
%
% This does not convert the EXP14G FAIL-support verdict into a pass. It reports
% only cells that independently meet the preregistered minimum and retains the
% under-supported N20 cell as a raw boundary without an interval or claim.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp14GSupportLimited: runDir must be char or scalar string.');
end
runDir=char(runDir); R=exp14gRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=52831592 || registryLeaves~=31
    error('analyzeExp14GSupportLimited: registry mismatch.');
end
G=readtable(fullfile(runDir,'gates.csv'),'TextType','string');
P=readtable(fullfile(runDir,'branch_pairs.csv'),'TextType','string');
support=G.gate=="selection_support";
if nnz(support)~=1 || G.passed(support)~=0 || any(G.passed(~support)~=1)
    error(['analyzeExp14GSupportLimited: expected exactly the frozen ' ...
        'selection-support failure.']);
end

metrics={'meanLeadSeconds','ackAirtimeCost','dataAirtimeSaved', ...
    'netAirtimeBenefit','dataAttemptsSaved','collisionsSaved', ...
    'trueAoIIntegralBenefit','estimatedAoIIntegralBenefit', ...
    'controlLossIntegralBenefit','minimumSeparationBenefit'};
summary=repmat(emptySummary(),0,1);
effects=repmat(emptyEffect(),0,1);
sparse=repmat(emptySparse(),0,1);
for c=1:numel(R.cells)
    Q=P(P.scenario==string(R.cells(c).id),:);
    if height(Q)>=R.minimumEventsPerCell
        row=emptySummary();
        row.scenario=R.cells(c).id; row.scenarioLabel=R.cells(c).label;
        row.nDecisions=height(Q); row.nParentSeeds=numel(unique(Q.seed));
        row.totalEntries=sum(Q.nEntries);
        row.positiveLeadEntryFraction=sum(Q.positiveLeadEntries)/sum(Q.nEntries);
        row.actualConfirmationFraction=sum(Q.actualConfirmedEntries)/sum(Q.nEntries);
        row.shadowConfirmationFraction=sum(Q.shadowConfirmedEntries)/sum(Q.nEntries);
        row.meanLocalBusy=mean(Q.localBusy); row.meanPendingAge=mean(Q.pendingAge);
        row.meanEntries=mean(Q.nEntries); row.forcedFraction=mean(Q.forced);
        [row.paretoBeneficialDecisions,row.paretoHarmfulDecisions, ...
            row.mixedOrNullDecisions]=classify(Q);
        summary(end+1,1)=row; %#ok<AGROW>
        for m=1:numel(metrics)
            ci=oneSampleCI(Q.(metrics{m}));
            x=emptyEffect(); x.scenario=R.cells(c).id;
            x.metric=metrics{m}; x.nDecisions=height(Q);
            x.meanEffect=ci.mean; x.ciLo=ci.lo; x.ciHi=ci.hi;
            x.crossesZero=ci.lo<=0 && ci.hi>=0;
            effects(end+1,1)=x; %#ok<AGROW>
        end
    else
        x=emptySparse(); x.scenario=R.cells(c).id;
        x.nDecisions=height(Q); x.minimumRequired=R.minimumEventsPerCell;
        x.totalEntries=sum(Q.nEntries);
        x.positiveLeadEntryFraction=sum(Q.positiveLeadEntries)/max(sum(Q.nEntries),1);
        x.meanLeadSeconds=mean(Q.meanLeadSeconds);
        x.meanNetAirtimeBenefit=mean(Q.netAirtimeBenefit);
        x.meanTrueAoIIntegralBenefit=mean(Q.trueAoIIntegralBenefit);
        x.meanControlLossIntegralBenefit=mean(Q.controlLossIntegralBenefit);
        x.inferencePermitted=false;
        sparse(end+1,1)=x; %#ok<AGROW>
    end
end

A=struct(); A.summary=struct2table(summary);
A.effects=struct2table(effects); A.sparseBoundary=struct2table(sparse);
A.manifest=struct( ...
    'analysisStatus','SUPPORT_LIMITED_DEVELOPMENT_AUDIT', ...
    'originalIntegrityVerdict','FAIL_SELECTION_SUPPORT', ...
    'verdictChanged',false,'confirmatoryClaimPermitted',false, ...
    'thresholdTuningPermitted',false,'predictorFittingPermitted',false, ...
    'supportedCells',{cellstr(string(A.summary.scenario))}, ...
    'unsupportedCells',{cellstr(string(A.sparseBoundary.scenario))}, ...
    'n20InferencePermitted',false, ...
    'performanceUsedToChangeSupportRule',false, ...
    'nextRequiredStep', ...
    ['new fixed N20-only pilot seed block; retain the same selection ' ...
     'minimum, covariates, intervention and local horizon'], ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writetable(A.summary,fullfile(runDir,'supported_causal_summary.csv'));
writetable(A.effects,fullfile(runDir,'supported_causal_effects_long.csv'));
writetable(A.sparseBoundary,fullfile(runDir,'sparse_boundary.csv'));
writeJson(fullfile(runDir,'support_limited_manifest.json'),A.manifest);

end


function [good,bad,mixed]=classify(Q)

tol=1e-12; resource=Q.netAirtimeBenefit;
fresh=Q.trueAoIIntegralBenefit; control=Q.controlLossIntegralBenefit;
good=sum(resource>tol & fresh>=-tol & control>=-tol);
bad=sum(resource<-tol & fresh<=tol & control<=tol);
mixed=height(Q)-good-bad;

end


function S=oneSampleCI(x)

x=x(isfinite(x)); n=numel(x); S.mean=mean(x);
half=tinv(0.975,n-1)*std(x)/sqrt(n); S.lo=S.mean-half; S.hi=S.mean+half;

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


function row=emptySparse()

row=struct('scenario','','nDecisions',NaN,'minimumRequired',NaN, ...
    'totalEntries',NaN,'positiveLeadEntryFraction',NaN, ...
    'meanLeadSeconds',NaN,'meanNetAirtimeBenefit',NaN, ...
    'meanTrueAoIIntegralBenefit',NaN, ...
    'meanControlLossIntegralBenefit',NaN,'inferencePermitted',false);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14GSupportLimited: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
