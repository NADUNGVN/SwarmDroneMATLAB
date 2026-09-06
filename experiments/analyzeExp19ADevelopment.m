function A=analyzeExp19ADevelopment(runDir)
%ANALYZEEXP19ADEVELOPMENT Evaluate the frozen headroom promotion gates.

R=exp19aRegistry();
T=readtable(fullfile(runDir,'tidy.csv'),'TextType','string');
G=readtable(fullfile(runDir,'gates.csv'),'TextType','string');
if height(T)~=R.expectedRuns
    error('analyzeExp19ADevelopment: result matrix is incomplete.');
end
S=summarize(T);
D=evaluateExp19Promotion(S,R,all(G.passed==1));
writetable(S,fullfile(runDir,'development_summary.csv'));
writetable(D.oracle,fullfile(runDir,'oracle_gate_diagnostics.csv'));
writetable(D.periodic,fullfile(runDir,'periodic_frontier_audit.csv'));
writetable(D.gates,fullfile(runDir,'development_decision_gates.csv'));
status=ternary(D.promote,'SERVICE_SCHEDULING_HEADROOM_DEMONSTRATED', ...
    'NO_SERVICE_SCHEDULING_HEADROOM');
verdict=struct('status',status,'developmentOnly',true, ...
    'confirmatoryClaimPermitted',false,'hypothesisTestsRun',false, ...
    'gatesPassed',sum(D.gates.passed),'gatesTotal',height(D.gates), ...
    'exp19bPermitted',logical(D.promote), ...
    'manuscriptClaimPermitted',false, ...
    'hardwarePolicyValidationPermitted',false, ...
    'negativeResultsRetained',true);
writeJson(fullfile(runDir,'development_verdict.json'),verdict);
A=struct('summary',S,'oracleDiagnostics',D.oracle, ...
    'periodicAudit',D.periodic,'gates',D.gates,'verdict',verdict);

end


function S=summarize(T)

U=T;
continuous={'RMSE','OFFERED_UTIL','MEAN_TRUE_AOI', ...
    'MEAN_NODE_GOODPUT_HZ','MIN_NODE_GOODPUT_HZ', ...
    'MAX_STARVATION_SEC','VIRTUAL_DEFICIT_MAX'};
for k=1:numel(continuous)
    U.(continuous{k})(logical(U.DIVERGED))=NaN;
end
[group,S]=findgroups(U(:,{'scenario','scenarioLabel', ...
    'originalMacType','arm','methodLabel','armKind','schedulerMode'}));
S.n=splitapply(@numel,U.RMSE,group);
S.nEligible=splitapply(@(x) nnz(isfinite(x)),U.RMSE,group);
S.meanRMSE=splitapply(@finiteMean,U.RMSE,group);
S.safeFailures=splitapply(@sum,U.SAFEFAIL,group);
S.divergences=splitapply(@sum,U.DIVERGED,group);
S.meanOfferedUtil=splitapply(@finiteMean,U.OFFERED_UTIL,group);
S.meanTrueAoI=splitapply(@finiteMean,U.MEAN_TRUE_AOI,group);
S.meanNodeGoodputHz=splitapply(@finiteMean,U.MEAN_NODE_GOODPUT_HZ,group);
S.minNodeGoodputHz=splitapply(@finiteMean,U.MIN_NODE_GOODPUT_HZ,group);
S.meanMaxStarvationSec=splitapply(@finiteMean,U.MAX_STARVATION_SEC,group);
S.meanMaxVirtualDeficit=splitapply(@finiteMean,U.VIRTUAL_DEFICIT_MAX,group);
S.meanCollisions=splitapply(@finiteMean,U.COLLISION_FRAMES,group);
S.meanEndogenousCollisions=splitapply( ...
    @finiteMean,U.ENDOGENOUS_COLLISION_FRAMES,group);
S.priorityDiffersFifo=splitapply(@sum,U.PRIORITY_DIFFERS_FIFO,group);
S.fifoComparableDecisions=splitapply( ...
    @sum,U.FIFO_COMPARABLE_DECISIONS,group);
S.priorityDiffersFifoFraction=S.priorityDiffersFifo./ ...
    max(S.fifoComparableDecisions,1);

end


function y=finiteMean(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=mean(x); end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp19ADevelopment: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
