function exp21d_dstr_kernel_conformance(resumeDir)
%EXP21D_DSTR_KERNEL_CONFORMANCE Frozen D-STR mechanism reproduction.

if nargin<1, resumeDir=''; end
startup;
close all;
R=exp21dDstrRegistry();
[registryHash,registryLeaves]=configHash(R);

if isempty(resumeDir)
    runScriptIsolated('test_exp21d_dstr_kernel_contracts');
    preflight=deterministicPreflight(R);
    expRun=startExperiment('exp21d_dstr_kernel_conformance', ...
        ['Rule-mapped prior-art kernel conformance and boundary study; ' ...
        'no closed-loop, policy-promotion, or submission claim.']);
    writeJson(fullfile(expRun.dir,'kernel_registry.json'),R);
    sourceManifest=snapshotSource(expRun.dir);
    writeJson(fullfile(expRun.dir,'source_manifest.json'),sourceManifest);
    opened=struct('openedAt',char(datetime('now', ...
        'Format','yyyy-MM-dd HH:mm:ss')), ...
        'registryHash',registryHash,'registryLeaves',registryLeaves, ...
        'sourceHash',sourceManifest.combinedHash, ...
        'contractChecksPassed',R.requiredContractChecks, ...
        'preflight',preflight,'policyOptimizationAllowed',false, ...
        'closedLoopClaimPermitted',false, ...
        'submissionClaimPermitted',false);
    writeJson(fullfile(expRun.dir,'kernel_opened.json'),opened);
else
    [expRun,opened,sourceManifest,preflight]=resumeRun( ...
        resumeDir,registryHash,registryLeaves,R);
end

[rows,completed]=loadCheckpoint(expRun.dir,R);
[seeds,Ns]=groups(R);
pending=find(~completed);
checkpoint=fullfile(expRun.dir,'kernel_checkpoint.csv');
batchSize=10;
for first=1:batchSize:numel(pending)
    last=min(first+batchSize-1,numel(pending));
    idx=pending(first:last);
    selectedSeeds=seeds(idx);
    selectedNs=Ns(idx);
    batch=cell(numel(idx),1);
    parfor (q=1:numel(idx),12)
        batch{q}=runGroup(selectedSeeds(q),selectedNs(q),R);
    end
    for q=1:numel(batch), rows=[rows;batch{q}(:)]; end %#ok<AGROW>
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        idx(1),idx(end),numel(seeds),numel(rows),R.expectedRuns);
end

T=struct2table(rows);
T=sortrows(T,{'seed','N','condition'});
writetable(T,fullfile(expRun.dir,'tidy.csv'));
writetable(T,fullfile(expRun.dir,'dstr_kernel_tidy.csv'));
S=summaryTable(T);
writetable(S,fullfile(expRun.dir,'kernel_summary.csv'));
gates=integrityGates(T,R,registryHash,registryLeaves, ...
    sourceManifest,opened,preflight);
writetable(gates,fullfile(expRun.dir,'kernel_conformance_gates.csv'));
pass=all(gates.passed==1);
status=ternary(pass,'DSTR_KERNEL_CONFORMANCE_VALID', ...
    'DSTR_KERNEL_INVALID_NO_CLOSED_LOOP');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'closedLoopPriorArtComparisonPermitted',pass, ...
    'newPolicyPromotionPermitted',false, ...
    'submissionClaimPermitted',false, ...
    'boundaryFailuresAreSourceClaims',false);
writeJson(fullfile(expRun.dir,'kernel_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'), ...
    'T','S','gates','verdict','R','preflight','sourceManifest');

fprintf('\nEXP21D-K conformance gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-42s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP21D-K VERDICT: %s\n',status);
finishExperiment(expRun);
if ~pass
    error('exp21d: D-STR kernel conformance failed.');
end

end


function rows=runGroup(seedValue,N,R)

trace=generateExp21dDstrTrace(seedValue,N,R);
rows=repmat(exp21dDstrEmptyRow(),numel(R.conditions),1);
for k=1:numel(R.conditions)
    rows(k)=runExp21dDstrKernelCell( ...
        seedValue,N,R.conditions(k),R,trace);
end

end


function P=deterministicPreflight(R)

[C,~]=applyExp21dDstrCondition(10,'native',R);
C.maxFrames=160;
C.initialDataSlots=5;
T=deterministicTrace(C,29);
a=simulateDstrScheduling(C,T);
b=simulateDstrScheduling(C,T);
[Cw,~]=applyExp21dDstrCondition(10,'native',R);
Tw=generateExp21dDstrTrace(16033001,10,R);
w=simulateDstrScheduling(Cw,Tw);
P=struct();
P.sourceTransitionsValid=a.finalAllResolved && ...
    a.finalCollisionFree && a.finalFrameAgreement && ...
    a.growRequests>0 && a.growNacks>0 && a.growthEvents>0;
P.namedManagementPathsValid=a.growRequests>0 && a.growNacks>0 && ...
    a.shrinkRequests>0 && a.shrinkObjects>0 && w.shrinkNacks>0 && ...
    a.shrinkEvents>0;
P.replayValid=a.traceHash==b.traceHash && ...
    a.configHash==b.configHash && a.realizationHash==b.realizationHash;
P.accountingValid=a.accountingCloses && a.deliveryWitnessValid;
P.causalCountersValid=a.futureRandomReads==0 && ...
    a.receiverTruthDecisionReads==0;
P.managementCounts=struct('TG',a.growRequests,'TGn',a.growNacks, ...
    'TS',a.shrinkRequests,'TSo',a.shrinkObjects, ...
    'TSn',w.shrinkNacks,'shrinkEvents',a.shrinkEvents);

end


function T=deterministicTrace(C,offset)

[f,n]=ndgrid(1:C.maxFrames,1:C.N);
T.choiceU=mod(0.41421356237*f+0.61803398875*n+offset/97,1);
T.retentionU=mod(0.27182818285*f+0.14142135623*n+offset/89,1);
T.dataDeliveryU=0.9*ones(C.maxFrames,C.N,C.N);
T.managementDeliveryU=0.9*ones(C.maxFrames,5,C.N,C.N);

end


function gates=integrityGates(T,R,registryHash,registryLeaves, ...
    sourceManifest,opened,P)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0 && ...
    opened.registryHash==registryHash,sprintf( ...
    'hash %.0f over %d leaves',registryHash,registryLeaves));
add('source_snapshot_frozen',sourceManifest.fileCount>=10 && ...
    sourceManifest.combinedHash==opened.sourceHash,sprintf( ...
    '%d files, hash %.0f',sourceManifest.fileCount, ...
    sourceManifest.combinedHash));
key=string(T.seed)+'|'+string(T.N)+'|'+string(T.condition);
add('matrix_complete_unique',height(T)==R.expectedRuns && ...
    numel(unique(key))==height(T),sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
add('exact_declared_seeds',isequal(unique(T.seed),R.seeds), ...
    'all and only 100 registered seeds');
observedConditions=sort(unique(string(T.condition)))';
expectedConditions=sort(string({R.conditions.id}));
coverage=isequal(unique(T.N)',R.N) && ...
    isequal(observedConditions,expectedConditions);
add('exact_factor_coverage',coverage, ...
    'N={5,10} and four registered conditions exact');

paired=true;
for seed=R.seeds'
    for N=R.N
        idx=T.seed==seed & T.N==N;
        paired=paired && nnz(idx)==numel(R.conditions) && ...
            isscalar(unique(T.traceHash(idx)));
    end
end
add('paired_absolute_draws',paired, ...
    'four conditions share one absolute trace per seed/N');
add('source_mapped_transition_contracts', ...
    opened.contractChecksPassed==R.requiredContractChecks && ...
    P.sourceTransitionsValid,sprintf('%d contract checks passed', ...
    opened.contractChecksPassed));
add('deterministic_replay',P.replayValid, ...
    'trace, configuration and realization hashes repeat exactly');
add('named_management_paths',P.namedManagementPathsValid,sprintf( ...
    'TG %d, TGn %d, TS %d, TSo %d, TSn %d, shrink %d', ...
    P.managementCounts.TG,P.managementCounts.TGn, ...
    P.managementCounts.TS,P.managementCounts.TSo, ...
    P.managementCounts.TSn,P.managementCounts.shrinkEvents));

native=string(T.condition)=='native';
nativeValid=all(isfinite(T.firstResolutionFrame(native))) && ...
    all(T.firstResolutionFrame(native)<=R.nativeResolutionDeadline) && ...
    all(T.finalAllResolved(native)==1) && ...
    all(T.finalCollisionFree(native)==1);
add('native_resolves_physically',nativeValid,sprintf( ...
    '%d/%d final physically valid by deadline %d', ...
    nnz(T.finalAllResolved(native) & T.finalCollisionFree(native)), ...
    nnz(native),R.nativeResolutionDeadline));
add('native_converges_without_unused_slots', ...
    all(T.finalConverged(native)==1) && ...
    all(isfinite(T.firstConvergenceFrame(native))),sprintf( ...
    '%d/%d converged by frame %d',nnz(T.finalConverged(native)), ...
    nnz(native),R.maxFrames));
add('native_frame_agreement',all(T.finalFrameAgreement(native)==1), ...
    sprintf('maximum native disagreement %.0f slots', ...
    max(T.maxFrameDisagreement(native))));
add('delivery_witnesses_valid',all(T.deliveryWitnessValid==1) && ...
    P.accountingValid,'every success/collision has its physical witness');
add('terminal_accounting_closes',all(T.accountingCloses==1), ...
    'DATA and management recipient outcomes close in every row');
add('causal_information_only',all(T.futureRandomReads==0) && ...
    all(T.receiverTruthDecisionReads==0) && P.causalCountersValid, ...
    'zero future-random and receiver-truth decision reads');
add('all_boundary_outcomes_retained',height(T(~native,:))==600 && ...
    all(isfinite(T.realizationHash)),sprintf( ...
    '%d boundary rows retained; %d nonresolved final rows', ...
    height(T(~native,:)),nnz(T.finalAllResolved(~native)==0)));
add('conformance_scope_only',~R.policyOptimizationAllowed && ...
    ~R.closedLoopClaimPermitted && ~R.submissionClaimPermitted, ...
    'no performance promotion or paper decision in kernel study');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function S=summaryTable(T)

[group,S]=findgroups(T(:,{'N','condition','conditionLabel','scope'}));
S.n=splitapply(@numel,T.finalAllResolved,group);
S.finalResolvedRate=splitapply(@mean,T.finalAllResolved,group);
S.finalPhysicallyValidRate=splitapply( ...
    @(x,y) mean(x & y),T.finalAllResolved,T.finalCollisionFree,group);
S.finalAgreementRate=splitapply(@mean,T.finalFrameAgreement,group);
S.finalConvergedRate=splitapply(@mean,T.finalConverged,group);
S.medianResolutionFrame=splitapply(@finiteMedian, ...
    T.firstResolutionFrame,group);
S.medianRecoveryFrame=splitapply(@finiteMedian,T.recoveryFrame,group);
S.meanFinalDataSlots=splitapply(@mean,T.finalDataSlots,group);
S.meanConflictFrameFraction=splitapply(@mean, ...
    T.conflictFrameFraction,group);
S.meanFalseResolvedNodeFrames=splitapply(@mean, ...
    T.falseResolvedNodeFrames,group);
S.meanOfferedUtilization=splitapply(@mean,T.offeredUtilization,group);
S.meanChannelUtilization=splitapply(@mean,T.channelUtilization,group);

end


function y=finiteMedian(x)

x=x(isfinite(x));
if isempty(x), y=NaN; else, y=median(x); end

end


function [seeds,Ns]=groups(R)

seeds=repelem(R.seeds,numel(R.N));
Ns=repmat(R.N',numel(R.seeds),1);
Ns=Ns(:);

end


function [rows,completed]=loadCheckpoint(runDir,R)

[seeds,Ns]=groups(R);
completed=false(size(seeds));
path=fullfile(runDir,'kernel_checkpoint.csv');
if ~isfile(path), rows=repmat(exp21dDstrEmptyRow(),0,1); return; end
T=readtable(path,'TextType','string');
rows=table2struct(T);
textFields={'condition','conditionLabel','scope','topology'};
for q=1:numel(rows)
    for k=1:numel(textFields)
        rows(q).(textFields{k})=char(rows(q).(textFields{k}));
    end
end
for q=1:numel(seeds)
    idx=T.seed==seeds(q) & T.N==Ns(q);
    if nnz(idx)==numel(R.conditions), completed(q)=true;
    elseif any(idx), error('exp21d: partial checkpoint group.'); end
end

end


function manifest=snapshotSource(target)

root=projectRoot();
files={'docs/EXP21D_DSTR_KERNEL_CONFORMANCE_PLAN.md', ...
    'docs/EXP21D_DSTR_KERNEL_AMENDMENT_01.md', ...
    'docs/EXP21D_DSTR_KERNEL_AMENDMENT_02.md', ...
    'docs/EXP21D_DSTR_KERNEL_AMENDMENT_03.md', ...
    'docs/EXP21D_DSTR_RULE_MAP.md', ...
    'network/simulateDstrScheduling.m', ...
    'utils/exp21dDstrRegistry.m','utils/exp21dDstrEmptyRow.m', ...
    'utils/generateExp21dDstrTrace.m', ...
    'utils/applyExp21dDstrCondition.m', ...
    'utils/runExp21dDstrKernelCell.m', ...
    'tests/test_exp21d_dstr_kernel_contracts.m', ...
    'experiments/exp21d_dstr_kernel_conformance.m'};
freeze=fullfile(target,'frozen_source');
mkdir(freeze);
hashes=zeros(numel(files),1);
for k=1:numel(files)
    source=fullfile(root,files{k});
    name=replace(files{k},{'/' '\'},'__');
    copyfile(source,fullfile(freeze,name));
    hashes(k)=realizationHash(double(fileread(source)));
end
manifest=struct('files',{files},'fileHashes',hashes, ...
    'fileCount',numel(files), ...
    'combinedHash',realizationHash(hashes));

end


function [expRun,opened,sourceManifest,P]=resumeRun( ...
    runDir,registryHash,registryLeaves,R)

opened=jsondecode(fileread(fullfile(runDir,'kernel_opened.json')));
sourceManifest=jsondecode(fileread( ...
    fullfile(runDir,'source_manifest.json')));
if opened.registryHash~=registryHash || ...
        opened.registryLeaves~=registryLeaves || ...
        opened.sourceHash~=sourceManifest.combinedHash || ...
        opened.contractChecksPassed~=R.requiredContractChecks
    error('exp21d: resume registry/source mismatch.');
end
P=opened.preflight;
[root,runId]=fileparts(runDir);
expRun=struct('name','exp21d_dstr_kernel_conformance', ...
    'runId',runId,'expRoot',root,'dir',runDir, ...
    'figDir',fullfile(runDir,'figures'),'t0',tic);
v=ver;
v=v(strcmp({v.Name},'MATLAB'));
expRun.meta=struct('experiment',expRun.name,'runId',runId, ...
    'startedAt',opened.openedAt,'matlabVersion', ...
    sprintf('%s %s',v.Name,v.Version),'matlabRelease',v.Release, ...
    'computer',computer,'projectRoot',projectRoot(),'gitCommit','', ...
    'notes','resumed D-STR kernel run','sourceFile','');
expRun.logFile=fullfile(runDir,'console.log');
diary(expRun.logFile); diary on;

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp21d: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
