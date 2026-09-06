function A=analyzeExp21AResults(runDir)
%ANALYZEEXP21ARESULTS Apply the frozen EXP21A stop/go rule.

R=exp21aRegistry();
T=readtable(fullfile(runDir,'trajectory_tidy.csv'),'TextType','string');
G=readtable(fullfile(runDir,'integrity_gates.csv'),'TextType','string');
if height(T)~=R.expectedRuns
    error('analyzeExp21AResults: result matrix is incomplete.');
end
if ~all(G.passed==1)
    error('analyzeExp21AResults: integrity gates must pass first.');
end

S=summaryTable(T);
P=pairedAudit(T,R);
[decisionGates,nominalPass]=decisionAudit(T,S,R);
if ~nominalPass
    status='IDEAL_SCHEDULING_ARTIFACT';
elseif all(decisionGates.passed==1)
    status='DISTRIBUTED_SCHEDULING_PATH_SUPPORTED';
else
    status='SCHEDULING_GAIN_FRAGILE';
end

writetable(S,fullfile(runDir,'summary.csv'));
writetable(P,fullfile(runDir,'paired_current_audit.csv'));
writetable(decisionGates,fullfile(runDir,'decision_gates.csv'));
verdict=struct('status',status,'developmentFalsificationOnly',true, ...
    'confirmatoryClaimPermitted',false, ...
    'candidateOptimizationWasAllowed',false, ...
    'schedulingConfirmatoryStudyPermitted',strcmp(status, ...
        'DISTRIBUTED_SCHEDULING_PATH_SUPPORTED'), ...
    'manuscriptClaimPermitted',false,'hardwareClaimPermitted',false, ...
    'negativeResultsRetained',true);
writeJson(fullfile(runDir,'development_verdict.json'),verdict);
A=struct('summary',S,'pairedAudit',P, ...
    'decisionGates',decisionGates,'verdict',verdict);

end


function S=summaryTable(T)

U=T;
U.RMSE(logical(U.DIVERGED))=NaN;
[group,S]=findgroups(U(:,{'scenario','scenarioLabel','cellRole', ...
    'arm','methodLabel','armKind','schedulerMode'}));
S.n=splitapply(@numel,U.RMSE,group);
S.nEligible=splitapply(@(x) nnz(isfinite(x)),U.RMSE,group);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,group);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,group);
S.divergences=splitapply(@sum,U.DIVERGED,group);
S.meanChargedUtil=splitapply(@finiteMean,U.CHARGED_OFFERED_UTIL,group);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,group);
S.meanControlOverhead=splitapply( ...
    @finiteMean,U.CONTROL_OVERHEAD_FRACTION,group);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,group);
S.meanCollisions=splitapply( ...
    @finiteMean,U.ENDOGENOUS_COLLISION_FRAMES,group);
S.convergenceFraction=splitapply(@finiteMean,U.CONVERGED_BY_2SEC,group);
S.recoveryFraction=splitapply(@finiteMean,U.RECOVERED_BY_2SEC,group);
S.meanConflictFraction=splitapply( ...
    @finiteMean,U.SCHEDULE_CONFLICT_FRACTION,group);

end


function P=pairedAudit(T,R)

P=table('Size',[numel(R.cells) 13], ...
    'VariableTypes',{'string','string','double','double','double','double', ...
        'double','double','double','double','double','double','double'}, ...
    'VariableNames',{'scenario','role','nPairs','currentMeanRMSE', ...
        'distributedMeanRMSE','meanPairedRmseDelta','rmseCiLo','rmseCiHi', ...
        'currentMeanChargedUtil','distributedMeanChargedUtil', ...
        'meanPairedUtilDelta','utilCiLo','utilCiHi'});
for k=1:numel(R.cells)
    c=R.cells(k);
    current=select(T,c.id,R.currentArm);
    candidate=select(T,c.id,R.primaryArm);
    B1=pairedBootstrapCI(candidate.RMSE,current.RMSE, ...
        R.bootstrapReplicates,R.bootstrapSeed+2*k-1,numel(R.seeds));
    B2=pairedBootstrapCI(candidate.CHARGED_OFFERED_UTIL, ...
        current.CHARGED_OFFERED_UTIL,R.bootstrapReplicates, ...
        R.bootstrapSeed+2*k,numel(R.seeds));
    P.scenario(k)=string(c.id); P.role(k)=string(c.role);
    P.nPairs(k)=B1.nPairs;
    P.currentMeanRMSE(k)=mean(current.RMSE);
    P.distributedMeanRMSE(k)=mean(candidate.RMSE);
    P.meanPairedRmseDelta(k)=B1.meanD;
    P.rmseCiLo(k)=B1.lo; P.rmseCiHi(k)=B1.hi;
    P.currentMeanChargedUtil(k)=mean(current.CHARGED_OFFERED_UTIL);
    P.distributedMeanChargedUtil(k)=mean( ...
        candidate.CHARGED_OFFERED_UTIL);
    P.meanPairedUtilDelta(k)=B2.meanD;
    P.utilCiLo(k)=B2.lo; P.utilCiHi(k)=B2.hi;
end

end


function [D,nominalPass]=decisionAudit(T,S,R)

nominalDominance=false(numel(R.nominalCells),1);
idealGap=false(numel(R.nominalCells),1);
for k=1:numel(R.nominalCells)
    scenario=R.nominalCells{k};
    candidate=one(S,scenario,R.primaryArm);
    current=one(S,scenario,R.currentArm);
    ideal=one(S,scenario,R.idealArm);
    nominalDominance(k)=dominates(candidate,current,R.dominanceMargin);
    idealGap(k)=candidate.meanRMSE<= ...
        ideal.meanRMSE*(1+R.maxRelativeIdealRmseGap) && ...
        candidate.meanChargedUtil<= ...
        ideal.meanChargedUtil+R.maxAbsoluteIdealUtilGap;
end
nominalPass=all(nominalDominance);

faultRetained=false(numel(R.singleFaultCells),1);
for k=1:numel(R.singleFaultCells)
    scenario=R.singleFaultCells{k};
    candidate=one(S,scenario,R.primaryArm);
    current=one(S,scenario,R.currentArm);
    faultRetained(k)=candidate.safeFailures<=current.safeFailures && ...
        candidate.meanRMSE<=current.meanRMSE;
end

primary=string(T.arm)==string(R.primaryArm);
meanOverhead=mean(T.CONTROL_OVERHEAD_FRACTION(primary));
nominalRows=primary & ismember(string(T.scenario),string(R.nominalCells));
convergenceFraction=mean(T.CONVERGED_BY_2SEC(nominalRows));
churnCells={R.cells([R.cells.churnEnabled]).id};
churnRows=primary & ismember(string(T.scenario),string(churnCells));
recoveryFraction=mean(T.RECOVERED_BY_2SEC(churnRows));
compoundCandidate=one(S,R.compoundCell,R.primaryArm);
compoundCurrent=one(S,R.compoundCell,R.currentArm);
compoundGuard=compoundCandidate.safeFailures<=compoundCurrent.safeFailures;

gate=["all_integrity_gates";"dominates_current_both_nominal"; ...
    "retains_4_of_5_single_fault_cells"; ...
    "mean_control_overhead_at_most_0p15"; ...
    "nominal_convergence_at_least_0p90"; ...
    "churn_recovery_at_least_0p90"; ...
    "within_registered_ideal_gap_both_nominal"; ...
    "compound_safety_no_worse_than_current"];
passed=[true;nominalPass; ...
    sum(faultRetained)>=R.minFaultCellsRetained; ...
    meanOverhead<=R.maxControlOverheadFraction; ...
    convergenceFraction>=R.minConvergenceFraction; ...
    recoveryFraction>=R.minConvergenceFraction;all(idealGap);compoundGuard];
detail=string({'all integrity gates passed'; ...
    sprintf('%d/%d nominal cells dominated',sum(nominalDominance), ...
        numel(nominalDominance)); ...
    sprintf('%d/5 single-fault cells retain safety and mean RMSE', ...
        sum(faultRetained)); ...
    sprintf('mean control overhead %.6f',meanOverhead); ...
    sprintf('nominal convergence fraction %.6f',convergenceFraction); ...
    sprintf('churn recovery fraction %.6f',recoveryFraction); ...
    sprintf('%d/%d nominal cells within ideal gap',sum(idealGap), ...
        numel(idealGap)); ...
    sprintf('compound failures candidate/current %d/%d', ...
        compoundCandidate.safeFailures,compoundCurrent.safeFailures)});
D=table(gate,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function r=one(S,scenario,arm)

idx=string(S.scenario)==string(scenario) & string(S.arm)==string(arm);
if nnz(idx)~=1
    error('analyzeExp21AResults: expected one row for %s/%s.',scenario,arm);
end
r=S(idx,:);

end


function T=select(T,scenario,arm)

T=T(string(T.scenario)==string(scenario) & string(T.arm)==string(arm),:);
T=sortrows(T,'seed');

end


function yes=dominates(a,b,margin)

noWorseRmse=a.meanRMSE<=b.meanRMSE*(1+margin);
noWorseCost=a.meanChargedUtil<=b.meanChargedUtil*(1+margin);
strict=a.meanRMSE<b.meanRMSE*(1-margin) || ...
    a.meanChargedUtil<b.meanChargedUtil*(1-margin);
yes=noWorseRmse && noWorseCost && strict && ...
    a.safeFailures<=b.safeFailures;

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp21AResults: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
