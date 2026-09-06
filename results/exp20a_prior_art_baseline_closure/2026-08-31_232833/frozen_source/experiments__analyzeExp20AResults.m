function A=analyzeExp20AResults(runDir)
%ANALYZEEXP20ARESULTS Apply the frozen EXP20A stop/go rule.

R=exp20aRegistry();
F=readtable(fullfile(runDir,'formation_tidy.csv'),'TextType','string');
N=readtable(fullfile(runDir,'native_tidy.csv'),'TextType','string');
G=readtable(fullfile(runDir,'integrity_gates.csv'),'TextType','string');
if height(F)~=R.expectedFormationRuns || height(N)~=R.expectedNativeRuns
    error('analyzeExp20AResults: result matrix is incomplete.');
end
if ~all(G.passed==1)
    error('analyzeExp20AResults: integrity gates must pass first.');
end

FS=formationSummary(F);
NS=nativeSummary(N);
NP=nativePrivateAudit(N,R);
[FA,priorExplains,existingMatches,formationPrivateLoss]= ...
    formationAudit(FS,R);

nativeSupported=sum(NP.supported);
nativeGap=nativeSupported>=4;
noGap=nativeSupported<=2;

gate=[ ...
    "all_integrity_gates"; ...
    "native_private_feedback_gap_4_of_6"; ...
    "not_explained_by_periodic_or_dtsa"; ...
    "not_matched_by_private_delta_or_age_gain"; ...
    "formation_public_private_loss_after_charging"];
passed=[true; nativeGap; ~priorExplains; ~existingMatches; formationPrivateLoss];
detail=string({ ...
    sprintf('%d/%d integrity gates pass',sum(G.passed),height(G)); ...
    sprintf('%d/6 rho=0.50 cells meet the 10%% positive-CI rule',nativeSupported); ...
    sprintf('priorArtExplains=%d',priorExplains); ...
    sprintf('existingPrivateBaselineMatches=%d',existingMatches); ...
    sprintf('charged N5 Stressed public-private loss=%d',formationPrivateLoss)});
decisionGates=table(gate,double(passed),detail);

if priorExplains || existingMatches
    status='PRIOR_ART_EXPLAINS_FRONTIER';
elseif noGap
    status='NO_PRIVATE_FEEDBACK_GAP';
elseif all(passed)
    status='INFORMATION_STRUCTURE_GAP_SUPPORTED';
else
    status='INCONCLUSIVE_NO_CANDIDATE';
end

writetable(FS,fullfile(runDir,'formation_summary.csv'));
writetable(NS,fullfile(runDir,'native_summary.csv'));
writetable(NP,fullfile(runDir,'native_public_private_audit.csv'));
writetable(FA,fullfile(runDir,'formation_primary_audit.csv'));
writetable(decisionGates,fullfile(runDir,'decision_gates.csv'));

verdict=struct('status',status,'developmentFalsificationOnly',true, ...
    'confirmatoryClaimPermitted',false, ...
    'candidateOptimizationWasAllowed',false, ...
    'newCandidatePermitted',strcmp(status, ...
        'INFORMATION_STRUCTURE_GAP_SUPPORTED'), ...
    'exp20bPermitted',strcmp(status, ...
        'INFORMATION_STRUCTURE_GAP_SUPPORTED'), ...
    'nativeGapSupportedCells',nativeSupported, ...
    'nativeGapRequiredCells',4, ...
    'priorArtExplainsFrontier',logical(priorExplains), ...
    'existingPrivateBaselineMatches',logical(existingMatches), ...
    'formationPrivateLossAfterCharging',logical(formationPrivateLoss), ...
    'manuscriptClaimPermitted',false, ...
    'hardwarePolicyValidationPermitted',false, ...
    'negativeResultsRetained',true);
writeJson(fullfile(runDir,'development_verdict.json'),verdict);
A=struct('formationSummary',FS,'nativeSummary',NS, ...
    'nativeAudit',NP,'formationAudit',FA, ...
    'decisionGates',decisionGates,'verdict',verdict);

end


function S=formationSummary(T)

U=T;
U.RMSE(logical(U.DIVERGED))=NaN;
[group,S]=findgroups(U(:,{'scenario','scenarioLabel','originalMacType', ...
    'arm','methodLabel','armKind','schedulerMode'}));
S.n=splitapply(@numel,U.RMSE,group);
S.nEligible=splitapply(@(x) nnz(isfinite(x)),U.RMSE,group);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,group);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,group);
S.divergences=splitapply(@sum,U.DIVERGED,group);
S.meanChargedUtil=splitapply(@finiteMean,U.CHARGED_OFFERED_UTIL,group);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,group);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,group);
S.meanCollisions=splitapply(@finiteMean,U.ENDOGENOUS_COLLISION_FRAMES,group);
S.meanPublicFeedbackAirtime=splitapply( ...
    @finiteMean,U.PUBLIC_FEEDBACK_AIRTIME,group);
S.meanDtsaDisagreement=splitapply( ...
    @finiteMean,U.DTSA_DISAGREEMENT_FRACTION,group);

end


function S=nativeSummary(T)

[group,S]=findgroups(T(:,{'cell','arm','N','rho','epsilon'}));
S.n=splitapply(@numel,T.MEAN_AOII,group);
S.meanAoII=splitapply(@finiteMean,T.MEAN_AOII,group);
S.meanMaxAoII=splitapply(@finiteMean,T.MEAN_MAX_AOII,group);
S.meanAttemptRate=splitapply(@finiteMean,T.ATTEMPT_RATE,group);
S.meanSuccessRate=splitapply(@finiteMean,T.SUCCESS_RATE,group);
S.meanCollisionRate=splitapply(@finiteMean,T.COLLISION_SLOT_RATE,group);
S.meanFeedbackRate=splitapply(@finiteMean,T.FEEDBACK_EVENT_RATE,group);
S.meanPhaseDivergence=splitapply( ...
    @finiteMean,T.PHASE_DIVERGENCE_FRACTION,group);

end


function P=nativePrivateAudit(T,R)

cells=R.nativeCells([R.nativeCells.rho]==0.50);
P=table('Size',[numel(cells) 12], ...
    'VariableTypes',{'string','double','double','double','double','double', ...
        'double','double','double','double','double','double'}, ...
    'VariableNames',{'cell','N','rho','epsilon','nPairs','publicMeanAoII', ...
        'privateMeanAoII','meanRelativePenalty','ciLo','ciHi', ...
        'crossesZero','supported'});
for k=1:numel(cells)
    c=cells(k);
    pub=T(string(T.cell)==string(c.id) & ...
        string(T.arm)=='delta-public',:);
    priv=T(string(T.cell)==string(c.id) & ...
        string(T.arm)=='delta-private-delayed',:);
    pub=sortrows(pub,'seed');
    priv=sortrows(priv,'seed');
    if ~isequal(pub.seed,priv.seed)
        error('analyzeExp20AResults: native public/private pairing failed.');
    end
    relative=(priv.MEAN_AOII-pub.MEAN_AOII)./max(pub.MEAN_AOII,eps);
    B=pairedBootstrapCI(relative,zeros(size(relative)), ...
        R.nativeBootstrapResamples,R.nativeBootstrapSeed+k,numel(R.nativeSeeds));
    supported=B.meanD>=R.privatePenaltyThreshold && B.lo>0;
    P.cell(k)=string(c.id);
    P.N(k)=c.N;
    P.rho(k)=c.rho;
    P.epsilon(k)=c.epsilon;
    P.nPairs(k)=B.nPairs;
    P.publicMeanAoII(k)=mean(pub.MEAN_AOII);
    P.privateMeanAoII(k)=mean(priv.MEAN_AOII);
    P.meanRelativePenalty(k)=B.meanD;
    P.ciLo(k)=B.lo;
    P.ciHi(k)=B.hi;
    P.crossesZero(k)=double(B.crossesZero);
    P.supported(k)=double(supported);
end

end


function [A,priorExplains,existingMatches,formationPrivateLoss]= ...
    formationAudit(S,R)

current='frame-piggyback';
boundary=R.primaryBoundaryCell;
failure=R.primaryFailureCell;
competitors={'periodic-tdma-p6p25','periodic-tdma-p8p333', ...
    'periodic-tdma-p10','periodic-tdma-p12p5', ...
    'dtsa-common-view','dtsa-private-view', ...
    'chen-age-gain-private','delta-private-projection'};
A=table('Size',[numel(competitors) 11], ...
    'VariableTypes',{'string','double','double','double','double','double', ...
        'double','double','double','double','double'}, ...
    'VariableNames',{'arm','boundaryRMSE','currentBoundaryRMSE', ...
        'boundaryChargedUtil','currentBoundaryChargedUtil', ...
        'boundaryFailures','currentBoundaryFailures','failureCellFailures', ...
        'currentFailureCellFailures','dominatesBoundary','matchesBoth'});
for k=1:numel(competitors)
    arm=competitors{k};
    b=one(S,boundary,arm);
    cb=one(S,boundary,current);
    f=one(S,failure,arm);
    cf=one(S,failure,current);
    dominates=dominatesRow(b,cb,R.dominanceMargin) && ...
        f.safeFailures<=cf.safeFailures;
    matchesBoundary=matchesRow(b,cb,R.dominanceMargin);
    matchesFailure=matchesRow(f,cf,R.dominanceMargin);
    A.arm(k)=string(arm);
    A.boundaryRMSE(k)=b.meanRMSE;
    A.currentBoundaryRMSE(k)=cb.meanRMSE;
    A.boundaryChargedUtil(k)=b.meanChargedUtil;
    A.currentBoundaryChargedUtil(k)=cb.meanChargedUtil;
    A.boundaryFailures(k)=b.safeFailures;
    A.currentBoundaryFailures(k)=cb.safeFailures;
    A.failureCellFailures(k)=f.safeFailures;
    A.currentFailureCellFailures(k)=cf.safeFailures;
    A.dominatesBoundary(k)=double(dominates);
    A.matchesBoth(k)=double(matchesBoundary && matchesFailure);
end

priorMask=startsWith(A.arm,'periodic-') | startsWith(A.arm,'dtsa-');
priorExplains=any(A.dominatesBoundary(priorMask)==1);
privateMask=ismember(A.arm, ...
    ["chen-age-gain-private","delta-private-projection"]);
existingMatches=any(A.matchesBoth(privateMask)==1);

pub=one(S,boundary,'delta-public-projection');
priv=one(S,boundary,'delta-private-projection');
formationPrivateLoss=priv.meanRMSE>pub.meanRMSE*(1+R.dominanceMargin) || ...
    priv.meanChargedUtil>pub.meanChargedUtil*(1+R.dominanceMargin) || ...
    priv.safeFailures>pub.safeFailures;

end


function r=one(S,scenario,arm)

idx=string(S.scenario)==string(scenario) & string(S.arm)==string(arm);
if nnz(idx)~=1
    error('analyzeExp20AResults: expected one summary row for %s/%s.', ...
        scenario,arm);
end
r=S(idx,:);

end


function yes=dominatesRow(a,b,margin)

rmseNoWorse=a.meanRMSE<=b.meanRMSE*(1+margin);
costNoWorse=a.meanChargedUtil<=b.meanChargedUtil*(1+margin);
strict=a.meanRMSE<b.meanRMSE*(1-margin) || ...
    a.meanChargedUtil<b.meanChargedUtil*(1-margin);
yes=rmseNoWorse && costNoWorse && strict && ...
    a.safeFailures<=b.safeFailures;

end


function yes=matchesRow(a,b,margin)

yes=a.meanRMSE<=b.meanRMSE*(1+margin) && ...
    a.meanChargedUtil<=b.meanChargedUtil*(1+margin) && ...
    a.safeFailures<=b.safeFailures;

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp20AResults: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
