function analyzeExp23kCoherencePacketCost(runDir)
%ANALYZEEXP23KCOHERENCEPACKETCOST Charge explicit horizon metadata bytes.

if nargin<1 || isempty(runDir)
    error('analyzeExp23kCoherencePacketCost: run directory is required.');
end
startup;
K=exp23kHorizonScaledRegistry();
I=exp23iCumulativeClosedLoopRegistry();
T=readtable(fullfile(runDir,'trajectory_tidy.csv'),'TextType','string');
sourceDir=fullfile(projectRoot(),'results', ...
    'exp23i_cumulative_closed_loop_target',K.sourceRun);
P=readtable(fullfile(sourceDir,'trajectory_tidy.csv'),'TextType','string');
P=P(string(P.arm)==string(I.periodicArm),:);
P=sortrows(P,'seed'); T=sortrows(T,'seed');
if height(T)~=K.expectedRuns || height(P)~=K.expectedRuns || ...
        ~isequal(T.seed,P.seed)
    error('EXP23K/EXP23I source rows do not pair.');
end

format=struct('claimBytes',28,'responseHeaderBytes',16, ...
    'responseEntryBytes',10,'maxPacketBytes',96,'revokeBytes',24);
rows=repmat(emptyRow(),numel(K.seeds),1);
for k=1:numel(K.seeds)
    [Q,C]=rebuild(K.seeds(k),K);
    claim=Q.controlKind=="claim";
    response=Q.controlKind=="response";
    oldBytes=Q.controlAttemptBytes;
    entries=zeros(size(oldBytes));
    entries(response)=(oldBytes(response)-C.certificateHeaderBytes)/ ...
        C.certificateEntryBytes;
    if any(entries~=round(entries)) || any(entries<0)
        error('Old RESPONSE packet cannot be decomposed into entries.');
    end
    newBytes=zeros(size(oldBytes));
    newBytes(claim)=format.claimBytes;
    newBytes(response)=format.responseHeaderBytes+ ...
        format.responseEntryBytes*entries(response);
    mtuViolations=nnz(newBytes>format.maxPacketBytes);
    deltaBytes=sum(newBytes)-sum(oldBytes);
    chargedUtil=T.TOTAL_OFFERED_UTIL(k)+ ...
        deltaBytes*8/C.phyRateBps/12;
    rows(k)=struct('seed',K.seeds(k),'claimAttempts',nnz(claim), ...
        'responseAttempts',nnz(response),'certificateEntries',sum(entries), ...
        'oldControlBytes',sum(oldBytes),'newControlBytes',sum(newBytes), ...
        'metadataDeltaBytes',deltaBytes,'maxNewPacketBytes',max(newBytes), ...
        'mtuViolations',mtuViolations, ...
        'originalCandidateUtil',T.TOTAL_OFFERED_UTIL(k), ...
        'chargedCandidateUtil',chargedUtil, ...
        'periodicUtil',P.TOTAL_OFFERED_UTIL(k), ...
        'relativeChargedCostVsPeriodic',chargedUtil/P.TOTAL_OFFERED_UTIL(k)-1);
end
D=struct2table(rows);
writetable(D,fullfile(runDir,'posthoc_coherence_packet_cost.csv'));
delta=pairedBootstrapCI(D.chargedCandidateUtil,D.periodicUtil,10000, ...
    K.bootstrapSeedBase+40,numel(K.seeds));
relative=mean(D.chargedCandidateUtil)/mean(D.periodicUtil)-1;
pass=all(D.mtuViolations==0) && ...
    relative<=-K.requiredPeriodicCostAdvantage;
status=ternary(pass,'COHERENCE_PACKET_FORMAT_RETAINS_COST_MARGIN', ...
    'COHERENCE_PACKET_FORMAT_ERASES_COST_MARGIN');
S=table(numel(K.seeds),mean(D.claimAttempts),mean(D.responseAttempts), ...
    mean(D.certificateEntries),mean(D.oldControlBytes), ...
    mean(D.newControlBytes),mean(D.metadataDeltaBytes), ...
    max(D.maxNewPacketBytes),sum(D.mtuViolations), ...
    mean(D.originalCandidateUtil),mean(D.chargedCandidateUtil), ...
    mean(D.periodicUtil),relative,delta.meanD,delta.lo,delta.hi, ...
    double(pass),string(status),'VariableNames',{'nPairs', ...
    'meanClaimAttempts','meanResponseAttempts','meanCertificateEntries', ...
    'meanOldControlBytes','meanNewControlBytes','meanMetadataDeltaBytes', ...
    'maxNewPacketBytes','mtuViolations','meanOriginalCandidateUtil', ...
    'meanChargedCandidateUtil','meanPeriodicUtil', ...
    'relativeChargedCostVsPeriodic','chargedCostDelta', ...
    'chargedCostCiLo','chargedCostCiHi','formatPassed','status'});
writetable(S,fullfile(runDir,'posthoc_coherence_packet_summary.csv'));
verdict=struct('status',status,'sourceRun',K.sourceRun,'rows',height(D), ...
    'format',format,'mtuViolations',sum(D.mtuViolations), ...
    'relativeChargedCostVsPeriodic',relative, ...
    'distributedKernelFormatPermitted',pass, ...
    'newMethodPromotionAllowed',false,'submissionClaimPermitted',false);
writeJson(fullfile(runDir,'posthoc_coherence_packet_verdict.json'),verdict);

fprintf('\nEXP23N coherence packet-cost audit\n');
fprintf('  old/new control bytes      %.2f / %.2f\n', ...
    S.meanOldControlBytes,S.meanNewControlBytes);
fprintf('  max packet / MTU failures %.0f / %.0f\n', ...
    S.maxNewPacketBytes,S.mtuViolations);
fprintf('  charged candidate cost     %.8f\n',S.meanChargedCandidateUtil);
fprintf('  periodic cost              %.8f\n',S.meanPeriodicUtil);
fprintf('  relative candidate cost    %.3f%%\n', ...
    100*S.relativeChargedCostVsPeriodic);
fprintf('EXP23N DECISION: %s\n',status);

end


function [Q,C]=rebuild(seedValue,R)
c=R.cells(1); condition=R.conditions(1);
base=applyExp21dClosedLoopCell(c.id,seedValue);
base.mac.backgroundLoad=condition.targetLoad;
base.mac=sharedMediumConfig(base);
trace=generateSharedMediumTrace(base);
C=elcsWitnessKernelConfig(base.swarm.N,R.elcsMaxFrames);
C.guardSec=R.missionSafeGuardSec;
C.dataBytes=base.mac.dataBytes;
C.phyRateBps=base.mac.phyRateBps;
C.neighborGraph=logical(base.swarm.A);
C.managementReach=C.neighborGraph;
C.interferenceMatrix=logical(base.mac.interferenceMatrix);
C.conflictGraph=buildSenderConflictGraph( ...
    C.neighborGraph,C.interferenceMatrix);
C.cumulativeReceiptRetry=true;
C.renewalPeriodFrames=R.renewalPeriodFrames;
C.leaseFrames=R.leaseFrames;
elcsTrace=generateElcsWitnessTrace(seedValue,C);
offset=(2*reshape(trace.exp21cClockOffsetU(1,:),[],1)-1)*R.maxOffsetSec;
drift=(2*reshape(trace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
spec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'leadTimeSec',R.clockLeadTimeSec);
elcsTrace=applySharedBackgroundToElcsWitnessTrace( ...
    elcsTrace,C,trace,spec,condition.targetLoad);
Q=buildElcsWitnessContinuousSchedule(C,elcsTrace,base.swarm.T);
end


function row=emptyRow()
names={'seed','claimAttempts','responseAttempts','certificateEntries', ...
    'oldControlBytes','newControlBytes','metadataDeltaBytes', ...
    'maxNewPacketBytes','mtuViolations','originalCandidateUtil', ...
    'chargedCandidateUtil','periodicUtil','relativeChargedCostVsPeriodic'};
row=cell2struct(num2cell(nan(size(names))),names,2);
end


function writeJson(path,value)
fid=fopen(path,'w');
if fid<0, error('Cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));
end


function value=ternary(condition,a,b)
if condition, value=a; else, value=b; end
end
