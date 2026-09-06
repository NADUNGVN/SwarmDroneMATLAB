function audit = analyzeExp13Results(exp13Dir,exp13bDir)
%ANALYZEEXP13RESULTS Reproducible post-run development analysis.

if nargin < 2
    error('analyzeExp13Results: EXP13 and EXP13B directories are required.');
end

F = readtable(fullfile(exp13Dir,'frontier_summary.csv'), ...
    'TextType','string');
M = readtable(fullfile(exp13Dir,'mechanism_summary.csv'), ...
    'TextType','string');
S = readtable(fullfile(exp13Dir,'sensitivity.csv'), ...
    'TextType','string');
D = readtable(fullfile(exp13Dir,'lhs_design.csv'), ...
    'TextType','string');
B = readtable(fullfile(exp13bDir,'summary.csv'), ...
    'TextType','string');


%% Exact two-axis Pareto membership among zero-failure mean points

F.pareto = zeros(height(F),1);
F.dominatedByFamily = strings(height(F),1);
F.dominatedByPoint = nan(height(F),1);
for k = 1:height(F)
    if F.safeFailures(k)>0
        continue;
    end
    candidates = F.scenario==F.scenario(k) & F.safeFailures==0;
    dominates = candidates & ...
        F.meanRMSE<=F.meanRMSE(k) & ...
        F.meanOfferedUtil<=F.meanOfferedUtil(k) & ...
        (F.meanRMSE<F.meanRMSE(k) | ...
        F.meanOfferedUtil<F.meanOfferedUtil(k));
    if ~any(dominates)
        F.pareto(k)=1;
    else
        q = find(dominates,1,'first');
        F.dominatedByFamily(k)=F.family(q);
        F.dominatedByPoint(k)=F.pointIndex(q);
    end
end
writetable(F,fullfile(exp13Dir,'pareto_audit.csv'));


%% LHS-only rank screening

[G,designIndex] = findgroups(S.pointIndex);
meanRMSE = splitapply(@mean,S.RMSE,G);
meanUtil = splitapply(@mean,S.OFFERED_UTIL,G);
meanAoI = splitapply(@mean,S.MEAN_TRUE_AOI,G);
keep = designIndex>0;
designIndex = designIndex(keep);
meanRMSE = meanRMSE(keep);
meanUtil = meanUtil(keep);
meanAoI = meanAoI(keep);
D = D(ismember(D.designIndex,designIndex),:);

names = {'posThreshold','velThreshold','aoiThreshold','maxSilence', ...
    'minInterTx','aoiMinInterTx','scaleBase','scaleMin','adaptRange'};
X = zeros(height(D),numel(names));
for k = 1:numel(names)
    X(:,k)=D.(names{k});
end
rhoRMSE = corr(X,meanRMSE,'Type','Spearman');
rhoUtil = corr(X,meanUtil,'Type','Spearman');
rhoAoI = corr(X,meanAoI,'Type','Spearman');
sensitivityRank = table(string(names(:)),rhoRMSE(:),rhoUtil(:),rhoAoI(:), ...
    'VariableNames',{'parameter','rhoRMSE','rhoOfferedUtil','rhoTrueAoI'});
sensitivityRank.absRhoRMSE = abs(sensitivityRank.rhoRMSE);
sensitivityRank = sortrows(sensitivityRank,'absRhoRMSE','descend');
writetable(sensitivityRank,fullfile(exp13Dir,'sensitivity_spearman.csv'));


%% Mechanism contrasts

scenarios = unique(M.scenario,'stable');
mechanismContrast = table('Size',[numel(scenarios) 8], ...
    'VariableTypes',{'string','double','double','double','double', ...
    'double','double','double'}, ...
    'VariableNames',{'scenario','unicastToHybridUtilRatio', ...
    'unicastMinusHybridRMSE','piggybackUtilReductionPct', ...
    'piggybackMinusHybridRMSE','piggybackMinusHybridEstimatedAoI', ...
    'standaloneUtilIncreasePct','standaloneMinusHybridEstimatedAoI'});
for k = 1:numel(scenarios)
    sc = scenarios(k);
    U = oneRow(M,sc,"Causal unicast + standalone ACK");
    P = oneRow(M,sc,"Broadcast + piggyback ACK");
    A = oneRow(M,sc,"Broadcast + standalone ACK");
    H = oneRow(M,sc,"Full Causal-Broadcast");
    mechanismContrast.scenario(k)=sc;
    mechanismContrast.unicastToHybridUtilRatio(k)= ...
        U.meanOfferedUtil/H.meanOfferedUtil;
    mechanismContrast.unicastMinusHybridRMSE(k)=U.meanRMSE-H.meanRMSE;
    mechanismContrast.piggybackUtilReductionPct(k)= ...
        100*(H.meanOfferedUtil-P.meanOfferedUtil)/H.meanOfferedUtil;
    mechanismContrast.piggybackMinusHybridRMSE(k)=P.meanRMSE-H.meanRMSE;
    mechanismContrast.piggybackMinusHybridEstimatedAoI(k)= ...
        P.meanEstimatedAoI-H.meanEstimatedAoI;
    mechanismContrast.standaloneUtilIncreasePct(k)= ...
        100*(A.meanOfferedUtil-H.meanOfferedUtil)/H.meanOfferedUtil;
    mechanismContrast.standaloneMinusHybridEstimatedAoI(k)= ...
        A.meanEstimatedAoI-H.meanEstimatedAoI;
end
writetable(mechanismContrast,fullfile(exp13Dir,'mechanism_contrasts.csv'));


%% Multi-slot CSMA-versus-ALOHA contrasts

BM = B(B.calibration=="multi-slot",:);
[G,keys] = findgroups(BM(:,{'methodLabel','pAccess'}));
macContrast = keys;
n = height(keys);
macContrast.alohaMinusCsmaRMSE = nan(n,1);
macContrast.alohaMinusCsmaCollisions = nan(n,1);
macContrast.alohaToCsmaOfferedUtilRatio = nan(n,1);
macContrast.alohaMinusCsmaSafeFailures = nan(n,1);
for k = 1:n
    R = BM(G==k,:);
    C = R(R.macType=="csma",:);
    A = R(R.macType=="aloha",:);
    macContrast.alohaMinusCsmaRMSE(k)=A.meanRMSE-C.meanRMSE;
    macContrast.alohaMinusCsmaCollisions(k)= ...
        A.meanCollisions-C.meanCollisions;
    macContrast.alohaToCsmaOfferedUtilRatio(k)= ...
        A.meanOfferedUtil/C.meanOfferedUtil;
    macContrast.alohaMinusCsmaSafeFailures(k)= ...
        A.safeFailures-C.safeFailures;
end
writetable(macContrast,fullfile(exp13bDir,'mac_contrasts.csv'));


%% Compact audit record

audit = struct();
audit.exp13Dir = exp13Dir;
audit.exp13bDir = exp13bDir;
audit.proposedParetoClean = nnz(F.pareto==1 & ...
    F.scenario=="Clean" & F.family=="Causal-Broadcast");
audit.proposedParetoModerate = nnz(F.pareto==1 & ...
    F.scenario=="Moderate" & F.family=="Causal-Broadcast");
audit.proposedParetoStressed = nnz(F.pareto==1 & ...
    F.scenario=="Stressed" & F.family=="Causal-Broadcast");
audit.mostInfluentialParameter = sensitivityRank.parameter(1);
audit.oneSlotMacDegenerate = oneSlotEquivalent(B);
audit.multiSlotMacDistinct = any(abs(macContrast.alohaMinusCsmaCollisions)>0);
audit.policyClaimPermitted = false;
writeJson(fullfile(exp13Dir,'postrun_audit.json'),audit);

end


function R = oneRow(T,scenario,family)

R = T(T.scenario==scenario & T.family==family,:);
if height(R)~=1
    error('analyzeExp13Results: expected one %s/%s row.',scenario,family);
end

end


function ok = oneSlotEquivalent(B)

T = B(B.calibration=="one-slot",:);
ok = true;
for method = unique(T.methodLabel)'
    for p = unique(T.pAccess)'
        R = T(T.methodLabel==method & T.pAccess==p,:);
        C = R(R.macType=="csma",:);
        A = R(R.macType=="aloha",:);
        ok = ok && C.meanRMSE==A.meanRMSE && ...
            C.meanCollisions==A.meanCollisions && ...
            C.meanOfferedUtil==A.meanOfferedUtil;
    end
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('Cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
