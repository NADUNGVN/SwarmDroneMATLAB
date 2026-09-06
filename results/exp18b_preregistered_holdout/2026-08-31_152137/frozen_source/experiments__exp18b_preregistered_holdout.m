function exp18b_preregistered_holdout(resumeDir)
%EXP18B_PREREGISTERED_HOLDOUT Frozen 100-seed capacity-screen holdout.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp18bRegistry();
[registryHash,registryLeaves]=configHash(R);
expectedRegistryHash=149048254;
expectedRegistryLeaves=153;
if registryHash~=expectedRegistryHash || registryLeaves~=expectedRegistryLeaves
    error(['exp18b: frozen registry hash mismatch (got %.0f/%d; ' ...
        'expected %.0f/%d).'],registryHash,registryLeaves, ...
        expectedRegistryHash,expectedRegistryLeaves);
end
[groupSeed,groupCell,groupMac]=holdoutGroups(R);
nGroup=numel(groupSeed); batchSize=16;

if isempty(resumeDir)
    runScriptIsolated('test_exp18b_contracts');
    runScriptIsolated('test_exp18b_analysis_contracts');
    expRun=startExperiment('exp18b_preregistered_holdout', ...
        ['Frozen 100-seed capacity-screen and abstention holdout; ' ...
        'nine-test Holm family; no hardware claim.']);
    [sourceHash,sourceLeaves]=snapshotFreeze(expRun.dir);
    writeJson(fullfile(expRun.dir,'frozen_registry.json'),R);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'sourceHash',sourceHash,'sourceLeaves',sourceLeaves, ...
        'firstSeed',R.seeds(1),'lastSeed',R.seeds(end), ...
        'policyMayChange',false,'matrixMayChange',false, ...
        'analysisMayChange',false, ...
        'primaryFamilySize',R.primaryFamilySize, ...
        'performanceInspectedBeforeOpen',false, ...
        'developmentEvidenceEndsAt','EXP18A4', ...
        'hardwareClaimPermitted',false);
    writeJson(fullfile(expRun.dir,'holdout_opened.json'),opened);
    rows=repmat(exp18bEmptyRow(),0,1);
    completed=false(nGroup,1);
    fprintf('EXP18B HOLDOUT IS NOW OPEN. Registry hash: %.0f\n', ...
        registryHash);
    fprintf('Frozen matrix: %d runs (%d seeds, %d paired groups).\n', ...
        R.expectedRuns,numel(R.seeds),nGroup);
else
    expRun=resumeExperiment(resumeDir,registryHash,registryLeaves);
    [rows,completed]=loadCheckpoint( ...
        fullfile(expRun.dir,'tidy_checkpoint.csv'), ...
        groupSeed,groupCell,groupMac,R);
    fprintf(['EXP18B RESUME: %d complete groups, %d rows recovered; ' ...
        'no performance column inspected.\n'],nnz(completed),numel(rows));
end

checkpoint=fullfile(expRun.dir,'tidy_checkpoint.csv');
pending=find(~completed);
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    indices=pending(first:last);
    batch=cell(numel(indices),1);
    parfor (q=1:numel(indices),16)
        g=indices(q);
        batch{q}=runGroup(groupSeed(g),groupCell(g),groupMac(g),R);
    end
    for q=1:numel(batch)
        rows=[rows; batch{q}(:)]; %#ok<AGROW>
    end
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        indices(1),indices(end),nGroup,numel(rows),R.expectedRuns);
end

tidy=struct2table(rows);
writetable(tidy,fullfile(expRun.dir,'tidy.csv'));
gates=integrityGates(tidy,R,registryHash,registryLeaves,expRun.dir, ...
    expectedRegistryHash,expectedRegistryLeaves);
writetable(gates,fullfile(expRun.dir,'gates.csv'));
integrityVerdict=struct('status',ternary(all(gates.passed==1), ...
    'PASS','FAIL'),'gatesPassed',nnz(gates.passed), ...
    'gatesTotal',height(gates),'totalRuns',height(tidy), ...
    'performanceIsIntegrityGate',false,'negativeResultsRetained',true, ...
    'policyChangePermitted',false,'hardwareClaimPermitted',false);
writeJson(fullfile(expRun.dir,'integrity_verdict.json'),integrityVerdict);

fprintf('\nEXP18B integrity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-38s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(string(gates.gate(k))),char(string(gates.detail(k))));
end
if all(gates.passed==1)
    analysis=analyzeExp18BResults(expRun.dir);
    fprintf('\nEXP18B CLAIM VERDICT: %s\n',analysis.claimVerdict.status);
    fprintf('  Holm tests: %d/%d | alias: %d | safety guard: %d\n', ...
        analysis.claimVerdict.holmTestsRejected, ...
        analysis.claimVerdict.holmTestsTotal, ...
        analysis.claimVerdict.exactAliasGatePassed, ...
        analysis.claimVerdict.boundarySafetyGuardPassed);
else
    analysis=struct();
    fprintf('\nEXP18B performance analysis NOT OPENED: integrity failure.\n');
end

save(fullfile(expRun.dir,'workspace.mat'),'tidy','gates', ...
    'integrityVerdict','analysis','R','-v7.3');
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp18b_preregistered_holdout: integrity gates failed.');
end

end


function rows=runGroup(seedValue,cellIndex,macIndex,R)

c=R.cells(cellIndex);
base=applyExp18BCell(c.id,seedValue);
base.mac.type=R.macTypes{macIndex};
base.mac.pAccess=min(0.20,1/base.swarm.N);
base.mac=sharedMediumConfig(base);
trace=generateSharedMediumTrace(base);
rows=repmat(exp18bEmptyRow(),numel(R.arms),1);
for k=1:numel(R.arms)
    arm=R.arms(k);
    [cfg,method,label,details,certificate]=applyExp18BArm(base,arm);
    meta=struct('stage','holdout','scenario',c.id, ...
        'scenarioLabel',c.label, ...
        'family','EXP18B capacity-screen holdout', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',c.background, ...
        'role',c.role,'channel',c.channel,'modifier',c.modifier, ...
        'basePAccess',base.mac.pAccess);
    rows(k)=runExp18BCell(cfg,method,label,meta,trace,details,certificate);
end

end


function [seeds,cells,macs]=holdoutGroups(R)

n=numel(R.seeds)*numel(R.cells)*numel(R.macTypes);
seeds=zeros(n,1); cells=zeros(n,1); macs=zeros(n,1); q=0;
for i=1:numel(R.seeds)
    for j=1:numel(R.cells)
        for m=1:numel(R.macTypes)
            q=q+1; seeds(q)=R.seeds(i); cells(q)=j; macs(q)=m;
        end
    end
end

end


function gates=integrityGates(T,R,registryHash,registryLeaves,runDir, ...
    expectedHash,expectedLeaves)

names=cell(0,1); passed=false(0,1); detail=cell(0,1);
[names,passed,detail]=addGate(names,passed,detail,'registry_contract', ...
    registryHash==expectedHash && registryLeaves==expectedLeaves, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
artifacts=exist(fullfile(runDir,'holdout_opened.json'),'file')==2 && ...
    exist(fullfile(runDir,'frozen_registry.json'),'file')==2 && ...
    exist(fullfile(runDir,'source_manifest.json'),'file')==2 && ...
    exist(fullfile(runDir,'frozen_source'),'dir')==7;
[names,passed,detail]=addGate(names,passed,detail,'pre_run_freeze_artifacts', ...
    artifacts,'opening record, registry and source snapshot exist');
sourceOk=false; sourceDetail='source manifest missing or unreadable';
if artifacts
    sourceManifest=jsondecode(fileread(fullfile(runDir,'source_manifest.json')));
    [actualSourceHash,actualSourceLeaves]=hashFreezeDir( ...
        fullfile(runDir,'frozen_source'));
    sourceOk=sourceManifest.sourceHash==actualSourceHash && ...
        sourceManifest.sourceLeaves==actualSourceLeaves;
    sourceDetail=sprintf('aggregate source hash %.0f over %d leaves', ...
        actualSourceHash,actualSourceLeaves);
end
[names,passed,detail]=addGate(names,passed,detail,'frozen_source_hash', ...
    sourceOk,sourceDetail);
[names,passed,detail]=addGate(names,passed,detail,'matrix_completeness', ...
    height(T)==R.expectedRuns,sprintf('%d frozen rows',height(T)));
keys=string(T.seed)+"|"+string(T.scenario)+"|"+string(T.macType)+ ...
    "|"+string(T.arm);
[names,passed,detail]=addGate(names,passed,detail,'unique_rows', ...
    numel(unique(keys))==height(T), ...
    'one row per seed/context/MAC/arm');

seedOk=isequal(unique(T.seed),R.seeds) && ...
    numel(unique(T.seed))==numel(R.seeds);
[names,passed,detail]=addGate(names,passed,detail,'exact_holdout_seeds', ...
    seedOk,'all and only 100 registered seeds are present');

complete=true; declared=sort(string({R.arms.id}))';
for seed=R.seeds'
    for c=R.cells
        for m=1:numel(R.macTypes)
            idx=T.seed==seed & string(T.scenario)==string(c.id) & ...
                string(T.macType)==string(R.macTypes{m});
            complete=complete && nnz(idx)==numel(R.arms) && ...
                isequal(sort(string(T.arm(idx))),declared);
        end
    end
end
[names,passed,detail]=addGate(names,passed,detail,'complete_paired_groups', ...
    complete,'all four arms occur once in every paired group');

eligible=T.DIVERGED==0;
finite=all(isfinite(T.RMSE(eligible)) & ...
    isfinite(T.OFFERED_UTIL(eligible)) & ...
    isfinite(T.DATA_GOODPUT_HZ(eligible)) & ...
    isfinite(T.serviceRatio(eligible)));
[names,passed,detail]=addGate(names,passed,detail,'finite_eligible_outputs', ...
    finite,'all nondivergent registered outcomes are finite');
feedback=string(T.feedbackMode)~="none";
causal=all(T.INVARIANT_VIOLATIONS==0) && ...
    all(T.MEAN_EST_AOI(feedback)>=T.MEAN_TRUE_AOI(feedback)-1e-12);
[names,passed,detail]=addGate(names,passed,detail,'causal_conservatism', ...
    causal,sprintf('%d protocol violations',sum(T.INVARIANT_VIOLATIONS)));
bounded=all(T.MAX_QUEUE<=4) && all(T.MAX_HISTORY<=T.historySize);
[names,passed,detail]=addGate(names,passed,detail,'bounded_memory',bounded, ...
    sprintf('max queue=%d max history=%d',max(T.MAX_QUEUE), ...
    max(T.MAX_HISTORY)));
accounting=all(T.DATA_RECIPIENT_SUCCESS+T.DATA_RECIPIENT_LOSS+ ...
    T.TERMINAL_DATA_INFLIGHT==T.DATA_RECIPIENT_ATTEMPTS) && ...
    all(T.ACK_RECIPIENT_SUCCESS+T.ACK_RECIPIENT_LOSS+ ...
    T.TERMINAL_ACK_INFLIGHT==T.ACK_RECIPIENT_ATTEMPTS) && ...
    all(T.CHANNEL_UTIL<=1+1e-12);
[names,passed,detail]=addGate(names,passed,detail,'physical_accounting', ...
    accounting,'recipient and channel busy-union accounting close');

crn=true;
for seed=R.seeds'
    for c=R.cells
        for m=1:numel(R.macTypes)
            idx=T.seed==seed & string(T.scenario)==string(c.id) & ...
                string(T.macType)==string(R.macTypes{m});
            crn=crn && isscalar(unique(T.TRACE_HASH_EXACT(idx))) && ...
                isscalar(unique(T.CHANNEL_STATE_HASH(idx))) && ...
                isscalar(unique(T.ESTIMATOR_HASH_EXACT(idx)));
        end
    end
end
[names,passed,detail]=addGate(names,passed,detail,'paired_absolute_trace', ...
    crn,'trace, channel state and estimator match within paired groups');

legacy=string(T.arm)=="legacy-selector";
frame=~legacy;
expectedFrame=1./T.N;
aloha=string(T.macType)=="aloha";
expectedFrame(aloha)=1./(T.N(aloha).*(2*T.dataFrameSlots(aloha)-1));
accessOk=all(abs(T.pAccess(frame)-expectedFrame(frame))<1e-12) && ...
    all(abs(T.pAccess(legacy)-1./T.N(legacy))<1e-12);
[names,passed,detail]=addGate(names,passed,detail,'access_geometry', ...
    accessOk,'frame-aware and legacy access probabilities are exact');

candidate=string(T.arm)==string(R.candidate);
routeOk=all(string(T.method(candidate))=="context-aware-broadcast") && ...
    all(string(T.route(candidate))=="capacity-gated-selector") && ...
    all(string(T.routeRule(candidate))=="capacity-gated-mac") && ...
    all(T.candidateFlag(candidate)==1) && ...
    all(T.candidateFlag(~candidate)==0);
[names,passed,detail]=addGate(names,passed,detail,'candidate_semantics', ...
    routeOk,'capacity screen and fixed route map are enabled');
comparatorOk=checkComparator(T,'frame-piggyback','piggyback', ...
    'fixed-comparator') && ...
    checkComparator(T,'frame-adaptive','adaptive','fixed-comparator') && ...
    checkComparator(T,'legacy-selector','', 'legacy-mac-only');
[names,passed,detail]=addGate(names,passed,detail,'comparator_semantics', ...
    comparatorOk,'all three fixed comparator contracts match');

static=true;
for c=R.cells
    for m=1:numel(R.macTypes)
        Q=T(string(T.scenario)==string(c.id) & ...
            string(T.macType)==string(R.macTypes{m}),:);
        static=static && isscalar(unique(Q.serviceCertificateFeasible)) && ...
            max(Q.serviceRatio)-min(Q.serviceRatio)<1e-12 && ...
            max(Q.successfulUpdateRateHz)-min(Q.successfulUpdateRateHz)<1e-12;
    end
end
[names,passed,detail]=addGate(names,passed,detail,'static_service_screen', ...
    static,'screen is arm- and seed-independent within each context/MAC');
decisionOk=all(T.CONTEXT_ACK_EVALUATED(candidate)== ...
    T.CONTEXT_ACK_PERMITTED(candidate)+ ...
    T.CONTEXT_ACK_BLOCKED_FEASIBILITY(candidate)+ ...
    T.CONTEXT_ACK_BLOCKED_VALUE(candidate));
[names,passed,detail]=addGate(names,passed,detail,'decision_accounting', ...
    decisionOk,'every candidate feedback decision has one outcome');
infeasible=candidate & T.serviceCertificateFeasible==0;
abstain=all(T.ACK_STANDALONE(infeasible)==0) && ...
    all(T.CONTEXT_ACK_PERMITTED(infeasible)==0);
[names,passed,detail]=addGate(names,passed,detail,'infeasible_abstention', ...
    abstain,sprintf('%d screen-negative rows emit no standalone ACK', ...
    nnz(infeasible)));
[aliasOk,maxAliasDifference]=exactAliasGate(T,R);
[names,passed,detail]=addGate(names,passed,detail,'exact_route_alias', ...
    aliasOk,sprintf('max difference %.3g over %d fields', ...
    maxAliasDifference,numel(R.aliasFields)));
reverse=candidate & contains(string(T.scenario),'reverse');
[names,passed,detail]=addGate(names,passed,detail,'calibration_boundary', ...
    all(string(T.calibrationSource(reverse))=="nominal-moderate-mismatch"), ...
    'reverse boundary retains declared nominal calibration mismatch');
divergenceOk=all(ismember(T.DIVERGED,[0 1])) && ...
    all(T.SAFEFAIL>=T.DIVERGED);
[names,passed,detail]=addGate(names,passed,detail,'divergence_accounting', ...
    divergenceOk,sprintf('%d divergences retained',sum(T.DIVERGED)));
gates=table(names,double(passed),detail, ...
    'VariableNames',{'gate','passed','detail'});

end


function ok=checkComparator(T,id,route,rule)

idx=string(T.arm)==string(id);
ok=nnz(idx)>0 && all(string(T.routeRule(idx))==string(rule));
if ~isempty(route)
    ok=ok && all(string(T.route(idx))==string(route));
else
    csma=idx & string(T.macType)=="csma";
    aloha=idx & string(T.macType)=="aloha";
    ok=ok && all(string(T.route(csma))=="piggyback") && ...
        all(string(T.route(aloha))=="adaptive");
end

end


function [ok,maxDifference]=exactAliasGate(T,R)

ok=true; maxDifference=0;
candidate=T(string(T.arm)==string(R.candidate),:);
for k=1:height(candidate)
    A=candidate(k,:);
    B=T(T.seed==A.seed & string(T.scenario)==string(A.scenario) & ...
        string(T.macType)==string(A.macType) & ...
        string(T.arm)==string(A.routedReference),:);
    if height(B)~=1
        ok=false; continue;
    end
    for f=1:numel(R.aliasFields)
        name=R.aliasFields{f};
        ok=ok && isequaln(A.(name),B.(name));
        a=A.(name); b=B.(name);
        if isfinite(a) && isfinite(b)
            maxDifference=max(maxDifference,abs(a-b));
        end
    end
end

end


function [rows,completed]=loadCheckpoint(path,groupSeed,groupCell,groupMac,R)

if exist(path,'file')~=2
    error('exp18b: resume checkpoint is missing.');
end
T=readtable(path,'TextType','string','Delimiter',',');
expected=fieldnames(exp18bEmptyRow());
if ~isequal(T.Properties.VariableNames(:),expected)
    error('exp18b: checkpoint schema mismatch.');
end
if height(T)>R.expectedRuns || mod(height(T),numel(R.arms))~=0
    error('exp18b: checkpoint is not group-complete.');
end
completed=false(numel(groupSeed),1);
for g=1:numel(groupSeed)
    id=R.cells(groupCell(g)).id; mac=R.macTypes{groupMac(g)};
    idx=T.seed==groupSeed(g) & string(T.scenario)==string(id) & ...
        string(T.macType)==string(mac);
    if any(idx)
        if nnz(idx)~=numel(R.arms) || ...
                numel(unique(string(T.arm(idx))))~=numel(R.arms)
            error('exp18b: incomplete checkpoint group.');
        end
        completed(g)=true;
    end
end
if nnz(completed)*numel(R.arms)~=height(T)
    error('exp18b: checkpoint contains undeclared groups.');
end
rows=table2struct(T);
template=exp18bEmptyRow(); fields=fieldnames(template);
charFields=fields(structfun(@ischar,template));
for i=1:numel(rows)
    for f=1:numel(charFields)
        rows(i).(charFields{f})=char(string(rows(i).(charFields{f})));
    end
end

end


function expRun=resumeExperiment(runDir,registryHash,registryLeaves)

runDir=char(runDir);
openedPath=fullfile(runDir,'holdout_opened.json');
if exist(openedPath,'file')~=2
    error('exp18b: holdout_opened.json is missing.');
end
opened=jsondecode(fileread(openedPath));
sourceManifestPath=fullfile(runDir,'source_manifest.json');
if exist(sourceManifestPath,'file')~=2
    error('exp18b: source_manifest.json is missing.');
end
sourceManifest=jsondecode(fileread(sourceManifestPath));
[sourceHash,sourceLeaves]=hashFreezeDir(fullfile(runDir,'frozen_source'));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves || opened.policyMayChange || ...
        opened.matrixMayChange || opened.analysisMayChange || ...
        opened.sourceHash~=sourceHash || opened.sourceLeaves~=sourceLeaves || ...
        sourceManifest.sourceHash~=sourceHash || ...
        sourceManifest.sourceLeaves~=sourceLeaves
    error('exp18b: opened holdout contract mismatch.');
end
[expRoot,runId]=fileparts(runDir); v=ver('MATLAB');
expRun.name='exp18b_preregistered_holdout'; expRun.runId=runId;
expRun.expRoot=expRoot; expRun.dir=runDir;
expRun.figDir=fullfile(runDir,'figures');
expRun.logFile=fullfile(runDir,'console.log');
expRun.notes='Recovery only; frozen rows and analysis unchanged.';
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',opened.openedAt, ...
    'resumedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'matlabVersion',sprintf('%s %s',v.Name,v.Version), ...
    'matlabRelease',v.Release,'computer',computer, ...
    'projectRoot',projectRoot(),'gitCommit','', ...
    'notes',expRun.notes,'sourceFile',which(expRun.name));
expRun.t0=tic; diary(expRun.logFile); diary on;
fprintf('\nEXP18B RECOVERY ONLY: %s\n',runId);

end


function [sourceHash,sourceLeaves]=snapshotFreeze(target)

root=projectRoot();
files={'docs/EXP18B_PREREGISTERED_HOLDOUT_PLAN.md', ...
    'docs/EXP18A4_CAPACITY_GATED_SELECTOR_RESULTS.md', ...
    'utils/exp18bRegistry.m','utils/applyExp18BCell.m', ...
    'utils/applyExp18BArm.m','utils/exp18bEmptyRow.m', ...
    'utils/runExp18BCell.m','utils/applyExp18Cell.m', ...
    'utils/applyExp18Arm.m','utils/applyExp18A4Arm.m', ...
    'utils/exp18a4EmptyRow.m','utils/runExp18Cell.m', ...
    'utils/pairedCI.m','utils/pairedBootstrapCI.m','utils/wilsonCI.m', ...
    'utils/holmAdjustP.m','utils/writeTableAtomic.m', ...
    'network/contextAwarePolicyConfig.m', ...
    'network/contextAwareAccessProbability.m', ...
    'network/contextAwareServiceCertificate.m', ...
    'network/capacityGatedStandaloneAckDecision.m', ...
    'network/adaptiveStandaloneAckDecision.m', ...
    'network/advanceSharedMedium.m','simulation/simSwarmSharedMedium.m', ...
    'metrics/computeSharedMediumMetrics.m', ...
    'tests/test_exp18b_contracts.m', ...
    'tests/test_exp18b_analysis_contracts.m', ...
    'experiments/analyzeExp18BResults.m', ...
    'experiments/exp18b_preregistered_holdout.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end
[sourceHash,sourceLeaves,names]=hashFreezeDir(freeze);
manifest=struct('algorithm','configHash over sorted path/content records', ...
    'sourceHash',sourceHash,'sourceLeaves',sourceLeaves, ...
    'fileCount',numel(names),'files',{names});
writeJson(fullfile(target,'source_manifest.json'),manifest);

end


function [sourceHash,sourceLeaves,names]=hashFreezeDir(freeze)

listing=dir(freeze); listing=listing(~[listing.isdir]);
names=sort({listing.name});
records=repmat(struct('name','','content',''),numel(names),1);
for k=1:numel(names)
    records(k).name=names{k};
    records(k).content=fileread(fullfile(freeze,names{k}));
end
[sourceHash,sourceLeaves]=configHash(records);

end


function [names,passed,detail]=addGate(names,passed,detail,name,flag,textValue)

names{end+1,1}=name; passed(end+1,1)=logical(flag);
detail{end+1,1}=textValue;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp18b: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
