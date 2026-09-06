function analysis=analyzeExp18ADevelopment(runDir)
%ANALYZEEXP18ADEVELOPMENT Descriptive EXP18A promotion audit.

R=exp18Registry();
T=readtable(fullfile(runDir,'tidy.csv'),'TextType','string');
summaryRows=repmat(emptySummary(),0,1);
comparisonRows=repmat(emptyComparison(),0,1);

for c=R.cells
    for m=1:numel(R.macTypes)
        mac=string(R.macTypes{m});
        for a=R.arms
            Q=T(T.scenario==string(c.id) & T.macType==mac & ...
                T.arm==string(a.id),:);
            if height(Q)~=numel(R.seeds)
                error('analyzeExp18ADevelopment: incomplete summary cell.');
            end
            row=emptySummary();
            row.context=char(c.id); row.role=char(c.role); row.N=c.N;
            row.macType=char(mac); row.arm=char(a.id);
            row.meanRMSE=mean(Q.RMSE); row.meanOffered=mean(Q.OFFERED_UTIL);
            row.meanTrueAoI=mean(Q.MEAN_TRUE_AOI);
            row.meanCollisionRate=mean(Q.COLLISION_RATE);
            row.failureCount=sum(Q.SAFEFAIL); row.meanPAccess=mean(Q.pAccess);
            row.meanStandaloneAck=mean(Q.ACK_STANDALONE);
            row.contextEvaluated=sum(Q.CONTEXT_ACK_EVALUATED);
            row.contextPermitted=sum(Q.CONTEXT_ACK_PERMITTED);
            row.contextBlockedFeasibility= ...
                sum(Q.CONTEXT_ACK_BLOCKED_FEASIBILITY);
            row.contextBlockedValue=sum(Q.CONTEXT_ACK_BLOCKED_VALUE);
            summaryRows(end+1,1)=row; %#ok<AGROW>
        end

        C=summaryRows(strcmp({summaryRows.context},c.id) & ...
            strcmp({summaryRows.macType},char(mac)) & ...
            strcmp({summaryRows.arm},'context-aware'));
        L=summaryRows(strcmp({summaryRows.context},c.id) & ...
            strcmp({summaryRows.macType},char(mac)) & ...
            strcmp({summaryRows.arm},'legacy-selector'));
        P=summaryRows(strcmp({summaryRows.context},c.id) & ...
            strcmp({summaryRows.macType},char(mac)) & ...
            strcmp({summaryRows.arm},'frame-piggyback'));
        A=summaryRows(strcmp({summaryRows.context},c.id) & ...
            strcmp({summaryRows.macType},char(mac)) & ...
            strcmp({summaryRows.arm},'frame-adaptive'));
        row=emptyComparison();
        row.context=char(c.id); row.role=char(c.role); row.N=c.N;
        row.macType=char(mac);
        row.deltaRmseVsLegacy=C.meanRMSE-L.meanRMSE;
        row.deltaOfferedVsLegacy=C.meanOffered-L.meanOffered;
        row.offeredReductionVsLegacy=relativeReduction( ...
            L.meanOffered,C.meanOffered);
        row.collisionReductionVsLegacy=relativeReduction( ...
            L.meanCollisionRate,C.meanCollisionRate);
        row.deltaRmseVsPiggy=C.meanRMSE-P.meanRMSE;
        row.deltaOfferedVsPiggy=C.meanOffered-P.meanOffered;
        row.deltaRmseVsAdaptive=C.meanRMSE-A.meanRMSE;
        row.deltaOfferedVsAdaptive=C.meanOffered-A.meanOffered;
        row.candidateFailures=C.failureCount;
        row.piggyFailures=P.failureCount;
        row.adaptiveFailures=A.failureCount;
        row.failureNonincrease=C.failureCount<=P.failureCount && ...
            C.failureCount<=A.failureCount;
        row.jointlyWorseBoth=C.meanRMSE>max(P.meanRMSE,A.meanRMSE) && ...
            C.meanOffered>max(P.meanOffered,A.meanOffered);
        comparisonRows(end+1,1)=row; %#ok<AGROW>
    end
end

S=struct2table(summaryRows);
C=struct2table(comparisonRows);
writetable(S,fullfile(runDir,'development_summary.csv'));
writetable(C,fullfile(runDir,'development_comparisons.csv'));

failureNonincrease=all(C.failureNonincrease==1);
cRole=string(C.role); cMac=string(C.macType);
n10Aloha=C(cRole=="core" & C.N==10 & cMac=="aloha",:);
n10AccessRepair=height(n10Aloha)==4 && ...
    all(n10Aloha.offeredReductionVsLegacy>= ...
        R.materialReductionFraction-1e-12) && ...
    all(n10Aloha.collisionReductionVsLegacy>= ...
        R.materialReductionFraction-1e-12);
core=C(cRole=="core",:);
jointlyWorseCount=sum(core.jointlyWorseBoth);
notJointlyWorse=jointlyWorseCount<=R.maxJointlyWorseCoreCells;
candidate=T(string(T.arm)=="context-aware",:);
decisionAccounting=all(candidate.CONTEXT_ACK_EVALUATED== ...
    candidate.CONTEXT_ACK_PERMITTED+ ...
    candidate.CONTEXT_ACK_BLOCKED_FEASIBILITY+ ...
    candidate.CONTEXT_ACK_BLOCKED_VALUE);
valueBlocksActive=sum(candidate.CONTEXT_ACK_BLOCKED_VALUE)>0;
reverse=candidate(contains(string(candidate.scenario),"reverse"),:);
reverseMismatchReported=~isempty(reverse) && ...
    all(string(reverse.calibrationSource)=="nominal-moderate-mismatch");

gateNames={'failure_nonincrease','n10_aloha_access_repair', ...
    'not_jointly_worse','decision_accounting','value_blocks_active', ...
    'reverse_mismatch_reported'}';
gatePassed=double([failureNonincrease;n10AccessRepair;notJointlyWorse; ...
    decisionAccounting;valueBlocksActive;reverseMismatchReported]);
gateDetail={ ...
    'candidate failure count does not exceed either frame-aware fixed route'; ...
    sprintf('all four N10 ALOHA core cells reduce offered/collision by >= %.0f%%', ...
        100*R.materialReductionFraction); ...
    sprintf('%d jointly-worse core context--MAC cells (maximum %d)', ...
        jointlyWorseCount,R.maxJointlyWorseCoreCells); ...
    'evaluated decisions close into permit/feasibility/value outcomes'; ...
    sprintf('%d value-blocked development evaluations', ...
        sum(candidate.CONTEXT_ACK_BLOCKED_VALUE)); ...
    'reverse-asymmetric boundary uses nominal calibration intentionally'};
gates=table(gateNames,gatePassed,gateDetail, ...
    'VariableNames',{'gate','passed','detail'});
writetable(gates,fullfile(runDir,'development_decision_gates.csv'));

promote=all(gatePassed==1);
verdict=struct('status',ternary(promote, ...
    'CANDIDATE_READY_TO_PREREGISTER','REJECT_OR_REVISE_CANDIDATE'), ...
    'developmentOnly',true,'confirmatoryClaimPermitted',false, ...
    'gatesPassed',sum(gatePassed),'gatesTotal',numel(gatePassed), ...
    'jointlyWorseCoreMacCells',jointlyWorseCount, ...
    'futureHoldoutOpened',false,'hardwareClaimPermitted',false);
writeJson(fullfile(runDir,'development_verdict.json'),verdict);

makeFigure(S,R,runDir);
analysis=struct('summary',S,'comparisons',C,'gates',gates, ...
    'verdict',verdict);

end


function r=emptySummary()

r=struct('context','','role','','N',NaN,'macType','','arm','', ...
    'meanRMSE',NaN,'meanOffered',NaN,'meanTrueAoI',NaN, ...
    'meanCollisionRate',NaN,'failureCount',NaN,'meanPAccess',NaN, ...
    'meanStandaloneAck',NaN,'contextEvaluated',NaN, ...
    'contextPermitted',NaN,'contextBlockedFeasibility',NaN, ...
    'contextBlockedValue',NaN);

end


function r=emptyComparison()

r=struct('context','','role','','N',NaN,'macType','', ...
    'deltaRmseVsLegacy',NaN,'deltaOfferedVsLegacy',NaN, ...
    'offeredReductionVsLegacy',NaN,'collisionReductionVsLegacy',NaN, ...
    'deltaRmseVsPiggy',NaN,'deltaOfferedVsPiggy',NaN, ...
    'deltaRmseVsAdaptive',NaN,'deltaOfferedVsAdaptive',NaN, ...
    'candidateFailures',NaN,'piggyFailures',NaN, ...
    'adaptiveFailures',NaN,'failureNonincrease',false, ...
    'jointlyWorseBoth',false);

end


function x=relativeReduction(reference,candidate)

x=(reference-candidate)/max(abs(reference),eps);

end


function makeFigure(S,R,runDir)

core=S(string(S.role)=="core",:);
candidate=core(string(core.arm)=="context-aware",:);
legacy=core(string(core.arm)=="legacy-selector",:);
labels=string(candidate.context)+" "+upper(candidate.macType);
[labels,order]=sort(labels);
candidate=candidate(order,:);
legacyOrder=zeros(height(candidate),1);
for k=1:height(candidate)
    legacyOrder(k)=find(string(legacy.context)== ...
        string(candidate.context(k)) & string(legacy.macType)== ...
        string(candidate.macType(k)),1);
end
legacy=legacy(legacyOrder,:);

f=figure('Color','w','Name','EXP18A development');
tiledlayout(2,1,'TileSpacing','compact');
nexttile;
bar([legacy.meanOffered candidate.meanOffered]);
ylabel('Offered utilization'); grid on;
legend('Legacy selector','Context-aware','Location','best');
set(gca,'XTick',1:numel(labels),'XTickLabel',labels, ...
    'XTickLabelRotation',35);
nexttile;
bar([legacy.meanRMSE candidate.meanRMSE]);
ylabel('Formation RMSE [m]'); grid on;
set(gca,'XTick',1:numel(labels),'XTickLabel',labels, ...
    'XTickLabelRotation',35);
exportgraphics(f,fullfile(runDir,'figures', ...
    'exp18a_legacy_vs_context.png'),'Resolution',180);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp18ADevelopment: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
