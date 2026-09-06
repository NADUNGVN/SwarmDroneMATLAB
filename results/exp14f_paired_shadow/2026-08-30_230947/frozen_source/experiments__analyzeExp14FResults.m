function A=analyzeExp14FResults(runDir)
%ANALYZEEXP14FRESULTS Descriptive paired-shadow ACK-value analysis.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp14FResults: runDir must be char or scalar string.');
end
runDir=char(runDir);
R=exp14fRegistry();
[registryHash,registryLeaves]=configHash(R);
if registryHash~=20176987 || registryLeaves~=25
    error('analyzeExp14FResults: registry mismatch.');
end

T=readtable(fullfile(runDir,'tidy_runs.csv'), ...
    'TextType','string','Delimiter',',');
L=readtable(fullfile(runDir,'lead_events.csv'), ...
    'TextType','string','Delimiter',',');
G=readtable(fullfile(runDir,'gates.csv'), ...
    'TextType','string','Delimiter',',');
if height(T)~=R.expectedRuns || ~all(G.passed==1)
    error('analyzeExp14FResults: completed integrity-passing artifacts required.');
end

leadRows=repmat(emptyLeadSummary(),numel(R.cells),1);
contrastRows=repmat(emptyContrast(),0,1);
for c=1:numel(R.cells)
    id=R.cells(c).id;
    Q=L(L.scenario==string(id),:);
    selected=armRows(T,R,id,R.actualArm);
    shadow=armRows(T,R,id,R.shadowArm);

    row=emptyLeadSummary();
    row.scenario=id;
    row.scenarioLabel=R.cells(c).label;
    row.nSeeds=numel(R.seeds);
    row.runsWithStandaloneEvents=numel(unique(Q.seed));
    row.standaloneEvents=height(Q);
    row.matchedEvents=sum(~Q.censored);
    row.censoredEvents=sum(Q.censored);
    if ~isempty(Q)
        row.fractionMatched=mean(~Q.censored);
        row.fractionCensored=mean(Q.censored);
        row.fractionPositiveLead=mean(Q.isEarlier);
        row.fractionShadowEarlierOrEqual=mean(Q.shadowEarlierOrEqual);
        row.meanHorizonCappedLead=mean(Q.leadSeconds);
        row.medianHorizonCappedLead=percentile(Q.leadSeconds,50);
        row.p95HorizonCappedLead=percentile(Q.leadSeconds,95);
        row.maxHorizonCappedLead=max(Q.leadSeconds);
    end
    leadRows(c)=row;

    metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
        'DATA_AIRTIME','ACK_AIRTIME','COLLISION_FRAMES','DATA_ATTEMPTED'};
    for m=1:numel(metrics)
        field=metrics{m};
        ci=pairedCI(selected.(field),shadow.(field),numel(R.seeds));
        x=emptyContrast();
        x.scenario=id;
        x.metric=field;
        x.nPairs=ci.nPairs;
        x.selectedMean=mean(selected.(field));
        x.shadowMean=mean(shadow.(field));
        x.selectedMinusShadow=ci.meanD;
        x.ciLo=ci.lo;
        x.ciHi=ci.hi;
        x.crossesZero=ci.crossesZero;
        contrastRows(end+1,1)=x; %#ok<AGROW>
    end
end

A=struct();
A.leadSummary=struct2table(leadRows);
A.pairedContrasts=struct2table(contrastRows);
A.readiness=struct( ...
    'analysisStatus','DEVELOPMENT_MECHANISM_STUDY', ...
    'confirmatoryClaimPermitted',false, ...
    'thresholdTuningPermitted',false, ...
    'uniqueGenerationMatchedLeadAvailable',height(L)>0, ...
    'leadEstimand','max(min(t_shadow,H)-t_actual,0)', ...
    'censoringRetained',true, ...
    'eventLevelIIDInferencePermitted',false, ...
    'eventWindowEffectsAreAdditive',false, ...
    'predictiveCertificateReady',false, ...
    'nextRequiredStep', ...
    ['pre-register a causal-at-decision predictor and validate it on ' ...
     'a disjoint seed block'], ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));

writetable(A.leadSummary,fullfile(runDir,'lead_summary.csv'));
writetable(A.pairedContrasts,fullfile(runDir,'paired_policy_contrasts.csv'));
writeJson(fullfile(runDir,'readiness.json'),A.readiness);

end


function A=armRows(T,R,cellId,armId)

A=sortrows(T(T.scenario==string(cellId) & T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp14FResults: incomplete %s/%s arm.',cellId,armId);
end

end


function row=emptyLeadSummary()

row=struct('scenario','','scenarioLabel','','nSeeds',NaN, ...
    'runsWithStandaloneEvents',NaN,'standaloneEvents',NaN, ...
    'matchedEvents',NaN,'censoredEvents',NaN,'fractionMatched',NaN, ...
    'fractionCensored',NaN,'fractionPositiveLead',NaN, ...
    'fractionShadowEarlierOrEqual',NaN,'meanHorizonCappedLead',NaN, ...
    'medianHorizonCappedLead',NaN,'p95HorizonCappedLead',NaN, ...
    'maxHorizonCappedLead',NaN);

end


function row=emptyContrast()

row=struct('scenario','','metric','','nPairs',NaN, ...
    'selectedMean',NaN,'shadowMean',NaN,'selectedMinusShadow',NaN, ...
    'ciLo',NaN,'ciHi',NaN,'crossesZero',false);

end


function y=percentile(x,p)

x=sort(x(isfinite(x)));
if isempty(x), y=NaN; return; end
if isscalar(x), y=x; return; end
r=1+(numel(x)-1)*p/100;
lo=floor(r); hi=ceil(r); w=r-lo;
y=(1-w)*x(lo)+w*x(hi);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14FResults: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
