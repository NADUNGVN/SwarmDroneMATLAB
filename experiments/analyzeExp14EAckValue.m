function A=analyzeExp14EAckValue(runDir)
%ANALYZEEXP14EACKVALUE Post-hoc standalone-ACK versus piggyback accounting.
%
% This analysis does not alter or extend the frozen EXP14E confirmatory
% family. It evaluates an exact airtime identity and paired descriptive
% intervals for the already-registered selected and piggyback arms.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp14EAckValue: runDir must be char or scalar string.');
end
runDir=char(runDir);
R=exp14eRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=87778193 || registryLeaves~=58
    error('analyzeExp14EAckValue: frozen registry mismatch.');
end
tidyPath=fullfile(runDir,'tidy.csv');
gatePath=fullfile(runDir,'gates.csv');
if exist(tidyPath,'file')~=2 || exist(gatePath,'file')~=2
    error('analyzeExp14EAckValue: completed EXP14E artifacts are required.');
end
T=readtable(tidyPath,'TextType','string','Delimiter',',');
G=readtable(gatePath,'TextType','string','Delimiter',',');
if height(T)~=R.expectedRuns || ~all(G.passed==1)
    error('analyzeExp14EAckValue: EXP14E integrity contract is not satisfied.');
end

rows=repmat(emptyRow(),numel(R.cells),1);
cellVerdicts=repmat(struct('cell','','classification',''),numel(R.cells),1);
for k=1:numel(R.cells)
    cellId=R.cells(k).id;
    selected=armRows(T,R,cellId,R.candidate);
    piggyback=armRows(T,R,cellId,'piggyback-scaled');
    validatePair(selected,piggyback,cellId);
    horizon=applyExp14ECell(cellId,0).swarm.T;

    ackCost=selected.ACK_AIRTIME-piggyback.ACK_AIRTIME;
    dataSaving=piggyback.DATA_AIRTIME-selected.DATA_AIRTIME;
    netAirtime=(piggyback.DATA_AIRTIME+piggyback.ACK_AIRTIME) ...
        -(selected.DATA_AIRTIME+selected.ACK_AIRTIME);
    offeredBenefit=piggyback.OFFERED_UTIL-selected.OFFERED_UTIL;
    rmseBenefit=piggyback.RMSE-selected.RMSE;
    aoiBenefit=piggyback.MEAN_TRUE_AOI-selected.MEAN_TRUE_AOI;
    collisionSaving=piggyback.COLLISION_FRAMES-selected.COLLISION_FRAMES;
    dataAttemptSaving=piggyback.DATA_ATTEMPTED-selected.DATA_ATTEMPTED;
    identityResidual=netAirtime-(dataSaving-ackCost);
    utilizationResidual=offeredBenefit-netAirtime/horizon;
    if max(abs(identityResidual))>1e-12 || ...
            max(abs(utilizationResidual))>1e-12
        error('analyzeExp14EAckValue: airtime identity failed in %s.',cellId);
    end

    ciAck=oneSampleCI(ackCost,numel(R.seeds));
    ciData=oneSampleCI(dataSaving,numel(R.seeds));
    ciNet=oneSampleCI(netAirtime,numel(R.seeds));
    ciUtil=oneSampleCI(offeredBenefit,numel(R.seeds));
    ciRmse=oneSampleCI(rmseBenefit,numel(R.seeds));
    ciAoi=oneSampleCI(aoiBenefit,numel(R.seeds));
    ciCollision=oneSampleCI(collisionSaving,numel(R.seeds));

    accounting=struct( ...
        'standaloneAckAirtimeSeconds',ciAck.mean, ...
        'dataAirtimeSavedSeconds',ciData.mean, ...
        'controlLossSaved',ciRmse.mean, ...
        'collisionEventsSaved',ciCollision.mean, ...
        'weights',struct('airtimeCostPerSecond',1, ...
        'controlCostPerUnit',0,'collisionCostPerEvent',0));
    cert=standaloneAckValueCertificate(accounting);
    classification=intervalClassification(ciNet,ciRmse);

    row=emptyRow();
    row.cell=cellId;
    row.role=R.cells(k).role;
    row.nPairs=ciNet.nPairs;
    row.meanAckAirtimeCost=ciAck.mean;
    row.ackAirtimeCostLo=ciAck.lo;
    row.ackAirtimeCostHi=ciAck.hi;
    row.meanDataAirtimeSaved=ciData.mean;
    row.dataAirtimeSavedLo=ciData.lo;
    row.dataAirtimeSavedHi=ciData.hi;
    row.dataSavingCoverage=ciData.mean/max(ciAck.mean,eps);
    row.meanNetAirtimeBenefit=ciNet.mean;
    row.netAirtimeBenefitLo=ciNet.lo;
    row.netAirtimeBenefitHi=ciNet.hi;
    row.meanOfferedUtilBenefit=ciUtil.mean;
    row.offeredUtilBenefitLo=ciUtil.lo;
    row.offeredUtilBenefitHi=ciUtil.hi;
    row.meanRmseBenefit=ciRmse.mean;
    row.rmseBenefitLo=ciRmse.lo;
    row.rmseBenefitHi=ciRmse.hi;
    row.meanAoIBenefit=ciAoi.mean;
    row.aoiBenefitLo=ciAoi.lo;
    row.aoiBenefitHi=ciAoi.hi;
    row.meanCollisionEventsSaved=ciCollision.mean;
    row.collisionEventsSavedLo=ciCollision.lo;
    row.collisionEventsSavedHi=ciCollision.hi;
    row.meanDataAttemptsSaved=mean(dataAttemptSaving);
    row.meanStandaloneAckAttempts=mean(selected.ACK_ATTEMPTED ...
        -piggyback.ACK_ATTEMPTED);
    row.maxAccountingResidual=max(abs(identityResidual));
    row.maxUtilizationResidual=max(abs(utilizationResidual));
    row.meanCertificateMargin=cert.offeredAirtimeMarginSeconds;
    row.classification=classification;
    rows(k)=row;
    cellVerdicts(k)=struct('cell',cellId,'classification',classification);
end

A=struct();
A.accounting=struct2table(rows);
A.manifest=struct('analysisStatus','POST_HOC_MECHANISM_ACCOUNTING', ...
    'confirmatoryClaimPermitted',false,'thresholdTuningPermitted',false, ...
    'comparison','selected-adaptive-scaled minus piggyback-scaled', ...
    'positiveBenefitConvention', ...
    'piggyback outcome minus ACK-assisted outcome', ...
    'airtimeIdentity', ...
    'net benefit = DATA airtime saved - standalone ACK airtime', ...
    'piggybackOverheadDoubleCounted',false, ...
    'uniqueLeadTimeAvailable',false, ...
    'predictiveCertificateStatus','NOT_EVALUATED', ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'cells',cellVerdicts, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writetable(A.accounting,fullfile(runDir, ...
    'posthoc_ack_value_accounting.csv'));
writeJson(fullfile(runDir,'posthoc_ack_value_manifest.json'),A.manifest);

end


function row=emptyRow()

row=struct('cell','','role','','nPairs',NaN, ...
    'meanAckAirtimeCost',NaN,'ackAirtimeCostLo',NaN, ...
    'ackAirtimeCostHi',NaN,'meanDataAirtimeSaved',NaN, ...
    'dataAirtimeSavedLo',NaN,'dataAirtimeSavedHi',NaN, ...
    'dataSavingCoverage',NaN,'meanNetAirtimeBenefit',NaN, ...
    'netAirtimeBenefitLo',NaN,'netAirtimeBenefitHi',NaN, ...
    'meanOfferedUtilBenefit',NaN,'offeredUtilBenefitLo',NaN, ...
    'offeredUtilBenefitHi',NaN,'meanRmseBenefit',NaN, ...
    'rmseBenefitLo',NaN,'rmseBenefitHi',NaN,'meanAoIBenefit',NaN, ...
    'aoiBenefitLo',NaN,'aoiBenefitHi',NaN, ...
    'meanCollisionEventsSaved',NaN,'collisionEventsSavedLo',NaN, ...
    'collisionEventsSavedHi',NaN,'meanDataAttemptsSaved',NaN, ...
    'meanStandaloneAckAttempts',NaN,'maxAccountingResidual',NaN, ...
    'maxUtilizationResidual',NaN,'meanCertificateMargin',NaN, ...
    'classification','');

end


function A=armRows(T,R,cellId,armId)

A=sortrows(T(T.scenario==string(cellId) & T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp14EAckValue: incomplete %s/%s arm.',cellId,armId);
end

end


function validatePair(A,B,cellId)

if ~isequal(A.seed,B.seed) || ...
        ~isequal(A.TRACE_HASH_EXACT,B.TRACE_HASH_EXACT) || ...
        ~isequal(A.CHANNEL_STATE_HASH,B.CHANNEL_STATE_HASH)
    error('analyzeExp14EAckValue: non-CRN pair in %s.',cellId);
end

end


function S=oneSampleCI(x,nRequested)

x=x(:);
if any(~isfinite(x)) || numel(x)~=nRequested
    error('analyzeExp14EAckValue: continuous pair is incomplete.');
end
S.nPairs=numel(x);
S.mean=mean(x);
S.se=std(x)/sqrt(S.nPairs);
half=tinv(0.975,S.nPairs-1)*S.se;
S.lo=S.mean-half;
S.hi=S.mean+half;

end


function status=intervalClassification(airtime,rmse)

if airtime.lo>0 && rmse.lo>0
    status='ACK_ASSISTED_DOMINATES_CONTINUOUS';
elseif airtime.hi<0 && rmse.hi<0
    status='PIGGYBACK_DOMINATES_CONTINUOUS';
elseif (airtime.lo>0 && rmse.hi<0) || ...
        (airtime.hi<0 && rmse.lo>0)
    status='CONFIRMED_TRADEOFF';
else
    status='INCONCLUSIVE_CONTINUOUS';
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14EAckValue: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
