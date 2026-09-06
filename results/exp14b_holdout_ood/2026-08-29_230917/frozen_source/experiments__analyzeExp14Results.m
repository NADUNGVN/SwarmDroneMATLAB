function audit = analyzeExp14Results(primaryDir,oodDir)
%ANALYZEEXP14RESULTS Frozen post-run summaries, Pareto audit and paired CIs.

if nargin<2
    error('analyzeExp14Results: primaryDir and oodDir are required.');
end
R=exp14Registry();
P=readtable(fullfile(primaryDir,'tidy.csv'),'TextType','string');
O=readtable(fullfile(oodDir,'tidy.csv'),'TextType','string');
F=P(P.stage=="frontier",:);
M=P(P.stage=="mechanism",:);

FS=summarize(F,{'scenarioLabel','family','arm','pointIndex','parameterValue'});
MS=summarize(M,{'scenarioLabel','family','arm'});
OS=summarize(O,{'family','methodLabel','arm'});
writetable(FS,fullfile(primaryDir,'analysis_frontier_summary.csv'));
writetable(MS,fullfile(primaryDir,'analysis_mechanism_summary.csv'));
writetable(OS,fullfile(oodDir,'analysis_ood_summary.csv'));

pareto=paretoAudit(FS);
writetable(pareto,fullfile(primaryDir,'pareto_margin_audit.csv'));

[contrasts,safety]=primaryContrasts(P,R);
writetable(contrasts,fullfile(primaryDir,'primary_paired_contrasts.csv'));
writetable(safety,fullfile(primaryDir,'primary_safety_intervals.csv'));

audit=struct();
audit.registryHash=configHash(R);
audit.primaryRows=height(P);
audit.oodRows=height(O);
audit.primaryContrasts=size(contrasts,1);
audit.bootstrapReplicates=R.bootstrapReplicates;
audit.bootstrapSeed=R.bootstrapSeed;
audit.performanceGate='NONE';
audit.negativeResultsRetained=true;
for sc=["Clean" "Moderate" "Stressed"]
    field=lower(char(sc));
    idx=pareto.scenarioLabel==sc & pareto.family=="Causal-Broadcast";
    audit.proposedPareto.(field).exact=nnz(idx & pareto.margin==0 & ...
        pareto.dominated==0);
    audit.proposedPareto.(field).margin1pct=nnz(idx & ...
        abs(pareto.margin-0.01)<1e-12 & pareto.dominated==0);
end
writeJson(fullfile(primaryDir,'postrun_analysis_audit.json'),audit);

end


function S=summarize(T,groups)

[G,S]=findgroups(T(:,groups));
S.n=splitapply(@numel,T.RMSE,G);
S.meanRMSE=splitapply(@nanmeanLocal,T.RMSE,G);
S.stdRMSE=splitapply(@std,T.RMSE,G);
S.safeFailures=splitapply(@sum,T.SAFEFAIL,G);
S.divergences=splitapply(@sum,T.DIVERGED,G);
S.meanTrueAoI=splitapply(@nanmeanLocal,T.MEAN_TRUE_AOI,G);
S.meanEstimatedAoI=splitapply(@nanmeanLocal,T.MEAN_EST_AOI,G);
S.meanOfferedUtil=splitapply(@nanmeanLocal,T.OFFERED_UTIL,G);
S.meanChannelUtil=splitapply(@nanmeanLocal,T.CHANNEL_UTIL,G);
S.meanEnergyProxyJ=splitapply(@nanmeanLocal,T.ENERGY_PROXY_J,G);
S.meanCollisions=splitapply(@nanmeanLocal,T.COLLISION_FRAMES,G);

end


function A=paretoAudit(S)

margins=[0 0.005 0.01 0.02];
A=table();
for scenario=unique(S.scenarioLabel,'stable')'
    C=S(S.scenarioLabel==scenario,:);
    eligible=C.safeFailures==0 & C.divergences==0 & ...
        isfinite(C.meanRMSE) & isfinite(C.meanOfferedUtil);
    for margin=margins
        for k=1:height(C)
            dominated=false;
            who=strings(0,1);
            if eligible(k)
                candidates=find(eligible);
                candidates(candidates==k)=[];
                for q=candidates'
                    better=C.meanRMSE(q)<=(1-margin)*C.meanRMSE(k) && ...
                        C.meanOfferedUtil(q)<= ...
                        (1-margin)*C.meanOfferedUtil(k);
                    if margin==0
                        better=better && (C.meanRMSE(q)<C.meanRMSE(k) || ...
                            C.meanOfferedUtil(q)<C.meanOfferedUtil(k));
                    end
                    if better
                        dominated=true;
                        who(end+1,1)=C.family(q)+"/"+C.arm(q); %#ok<AGROW>
                    end
                end
            end
            row=C(k,{'scenarioLabel','family','arm','pointIndex', ...
                'parameterValue','meanRMSE','meanOfferedUtil', ...
                'safeFailures','divergences'});
            row.margin=margin;
            row.eligible=double(eligible(k));
            row.dominated=double(dominated);
            row.dominatedBy=strjoin(who,'; ');
            A=[A; row]; %#ok<AGROW>
        end
    end
end

end


function [C,Safety]=primaryContrasts(P,R)

defs={ ...
    'clean-proposed-default-vs-p10', ...
    selectFrontier(P,'Clean','Causal-Broadcast',3), ...
    selectFrontier(P,'Clean','Periodic',2); ...
    'stressed-proposed-default-vs-p10', ...
    selectFrontier(P,'Stressed','Causal-Broadcast',3), ...
    selectFrontier(P,'Stressed','Periodic',2); ...
    'stressed-proposed-default-vs-belief', ...
    selectFrontier(P,'Stressed','Causal-Broadcast',3), ...
    selectFrontier(P,'Stressed','Delayed-ACK belief',3); ...
    'moderate-hybrid-vs-unicast', ...
    selectMechanism(P,'Moderate','broadcast-hybrid'), ...
    selectMechanism(P,'Moderate','causal-unicast'); ...
    'moderate-piggyback-vs-hybrid', ...
    selectMechanism(P,'Moderate','broadcast-piggyback'), ...
    selectMechanism(P,'Moderate','broadcast-hybrid')};
metrics={'RMSE','OFFERED_UTIL','MEAN_TRUE_AOI'};
C=table(); Safety=table();
for k=1:size(defs,1)
    name=string(defs{k,1});
    [A,B]=pairBySeed(defs{k,2},defs{k,3},R.seeds);
    for q=1:numel(metrics)
        metric=metrics{q};
        t=pairedCI(A.(metric),B.(metric),numel(R.seeds));
        b=pairedBootstrapCI(A.(metric),B.(metric), ...
            R.bootstrapReplicates,R.bootstrapSeed,numel(R.seeds));
        row=table(name,string(metric),mean(A.(metric),'omitnan'), ...
            mean(B.(metric),'omitnan'),t.meanD,t.stdD,t.lo,t.hi, ...
            b.lo,b.hi,t.nRequested,t.nPairs,t.nDropped,double(t.complete), ...
            'VariableNames',{'contrast','metric','meanA','meanB', ...
            'meanDifferenceAminusB','stdDifference','pairedTLo','pairedTHi', ...
            'bootstrapLo','bootstrapHi','nRequested','nPairs','nDropped', ...
            'complete'});
        C=[C; row]; %#ok<AGROW>
    end
    wa=wilsonCI(sum(A.SAFEFAIL),height(A));
    wb=wilsonCI(sum(B.SAFEFAIL),height(B));
    row=table(name,sum(A.SAFEFAIL),height(A),wa.rate,wa.lo,wa.hi, ...
        sum(B.SAFEFAIL),height(B),wb.rate,wb.lo,wb.hi, ...
        'VariableNames',{'contrast','failuresA','totalA','rateA','loA','hiA', ...
        'failuresB','totalB','rateB','loB','hiB'});
    Safety=[Safety; row]; %#ok<AGROW>
end

end


function T=selectFrontier(P,scenario,family,point)

T=P(P.stage=="frontier" & P.scenarioLabel==scenario & ...
    P.family==family & P.pointIndex==point,:);

end


function T=selectMechanism(P,scenario,arm)

T=P(P.stage=="mechanism" & P.scenarioLabel==scenario & P.arm==arm,:);

end


function [A,B]=pairBySeed(A,B,seeds)

A=sortrows(A,'seed'); B=sortrows(B,'seed');
if height(A)~=numel(seeds) || height(B)~=numel(seeds) || ...
        ~isequal(A.seed,B.seed) || ~isequal(A.seed,seeds) || ...
        ~isequal(A.TRACE_HASH_EXACT,B.TRACE_HASH_EXACT)
    error('analyzeExp14Results: incomplete or non-CRN primary contrast.');
end

end


function y=nanmeanLocal(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14Results: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
