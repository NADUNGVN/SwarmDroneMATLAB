function exp21b_continuous_timing_validity()
%EXP21B_CONTINUOUS_TIMING_VALIDITY Validate asynchronous TDMA semantics.

startup;
close all;
run(fullfile(projectRoot(),'tests', ...
    'test_exp21b_continuous_timing_contracts.m'));
R=exp21bTimingRegistry();
[registryHash,registryLeaves]=configHash(R);
expRun=startExperiment('exp21b_continuous_timing_validity', ...
    ['Deterministic/randomized model-validity study; no policy ' ...
    'optimization or formation-performance claim.']);
writeJson(fullfile(expRun.dir,'model_validity_registry.json'),R);
opened=struct('openedAt',char(datetime('now', ...
    'Format','yyyy-MM-dd HH:mm:ss')), ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'policyOptimizationAllowed',false, ...
    'formationPerformanceClaimPermitted',false);
writeJson(fullfile(expRun.dir,'model_validity_opened.json'),opened);
snapshotSource(expRun.dir);

[seeds,Ns]=groups(R);
rows=repmat(exp21bTimingEmptyRow(),0,1);
checkpoint=fullfile(expRun.dir,'timing_checkpoint.csv');
batchSize=20;
for first=1:batchSize:numel(seeds)
    last=min(first+batchSize-1,numel(seeds));
    batchSeeds=seeds(first:last);
    batchNs=Ns(first:last);
    batch=cell(numel(batchSeeds),1);
    parfor (q=1:numel(batchSeeds),12)
        batch{q}=runGroup(batchSeeds(q),batchNs(q),R);
    end
    for q=1:numel(batch), rows=[rows;batch{q}(:)]; end %#ok<AGROW>
    writeTableAtomic(struct2table(rows),checkpoint);
    fprintf('  groups %3d--%3d / %3d; rows %4d / %4d\n', ...
        first,last,numel(seeds),numel(rows),R.expectedRuns);
end

T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'timing_tidy.csv'));
gates=integrityGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'model_validity_gates.csv'));
status=ternary(all(gates.passed==1), ...
    'TIMING_MODEL_VALID_FOR_INTEGRATION','TIMING_MODEL_INVALID_STOP');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'policyOptimizationAllowed',false, ...
    'formationPerformanceClaimPermitted',false, ...
    'closedLoopIntegrationPermitted',all(gates.passed==1));
writeJson(fullfile(expRun.dir,'model_validity_verdict.json'),verdict);
S=summaryTable(T);
writetable(S,fullfile(expRun.dir,'timing_summary.csv'));
save(fullfile(expRun.dir,'workspace.mat'),'T','S','gates','verdict','R');

fprintf('\nEXP21B model-validity gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-40s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP21B MODEL VERDICT: %s\n',status);
finishExperiment(expRun);
if ~all(gates.passed==1)
    error('exp21b_continuous_timing_validity: model validity failure.');
end

end


function rows=runGroup(seedValue,N,R)

maxEpochs=ceil(R.horizonSec/min(R.syncPeriodsSec(isfinite( ...
    R.syncPeriodsSec))));
stream=RandStream('mt19937ar','Seed',mod( ...
    seedValue+R.clockSeedOffset+1000*N,2^32));
masterOffset=(2*rand(stream,N,maxEpochs)-1)*R.maxOffsetSec;
drift=(2*rand(stream,N,1)-1)*R.maxDriftPpm;
drawHash=realizationHash([masterOffset(:);drift(:)]);
rows=repmat(exp21bTimingEmptyRow(), ...
    numel(R.syncPeriodsSec)*numel(R.guardFactors),1);
q=0;
for sync=R.syncPeriodsSec
    if isinf(sync), resetHorizon=R.horizonSec; epochOffsets=masterOffset(:,1);
    else
        resetHorizon=sync;
        nEpoch=ceil(R.horizonSec/sync);
        epochOffsets=masterOffset(:,1:nEpoch);
    end
    B=continuousTdmaGuardBound( ...
        R.maxOffsetSec,R.maxDriftPpm,resetHorizon);
    for factor=R.guardFactors
        q=q+1;
        cfg=struct('N',N,'horizonSec',R.horizonSec, ...
            'dataAirtimeSec',R.dataAirtimeSec, ...
            'guardTimeSec',factor*B.safeGuardSec, ...
            'frameSlots',N,'assignedSlot',(1:N)', ...
            'clockOffsetSec',epochOffsets, ...
            'clockDriftPpm',drift,'syncPeriodSec',sync, ...
            'topology',true(N)-eye(N)>0, ...
            'interferenceMatrix',true(N),'epochLeadTimeSec',0);
        out=simulateContinuousLocalTdma(cfg);
        row=exp21bTimingEmptyRow();
        row.seed=seedValue; row.N=N; row.syncPeriodSec=sync;
        row.guardFactor=factor; row.maxOffsetSec=R.maxOffsetSec;
        row.maxDriftPpm=R.maxDriftPpm;
        row.safeGuardSec=B.safeGuardSec;
        row.guardTimeSec=cfg.guardTimeSec;
        row.dataAirtimeSec=out.dataAirtimeSec;
        row.slotDurationSec=out.slotDurationSec;
        row.frameDurationSec=out.frameDurationSec;
        row.transmissions=numel(out.startTime);
        row.collisionFrames=out.collisionFrames;
        row.temporalOverlapPairs=out.temporalOverlapPairs;
        row.offeredAirtimeSec=out.offeredAirtimeSec;
        row.busyTimeSec=out.busyTimeSec;
        row.offeredUtilization=out.offeredUtilization;
        row.channelUtilization=out.channelUtilization;
        row.maxClockEquationResidual=out.maxClockEquationResidual;
        row.collisionWitnessValid=double(out.collisionWitnessValid);
        row.guardAtOrAboveBound=double(factor>=1);
        row.clockDrawHash=drawHash;
        row.configHash=out.configHash;
        row.realizationHash=out.realizationHash;
        rows(q)=row;
    end
end

end


function gates=integrityGates(T,R,registryHash,registryLeaves)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
key=string(T.seed)+'|'+string(T.N)+'|'+ ...
    string(T.syncPeriodSec)+'|'+string(T.guardFactor);
matrix=height(T)==R.expectedRuns && numel(unique(key))==height(T);
add('matrix_complete_unique',matrix,sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
add('exact_declared_seeds',isequal(unique(T.seed),R.seeds), ...
    'all and only 100 registered seeds');
coverage=isequal(unique(T.N)',R.N) && ...
    isequal(unique(T.guardFactor)',R.guardFactors) && ...
    isequaln(unique(T.syncPeriodSec)',R.syncPeriodsSec);
add('exact_factor_coverage',coverage,'N, sync and guard factors exact');

paired=true;
for seed=R.seeds'
    for N=R.N
        idx=T.seed==seed & T.N==N;
        paired=paired && nnz(idx)==8 && ...
            isscalar(unique(T.clockDrawHash(idx)));
    end
end
add('paired_absolute_clock_draws',paired, ...
    'all eight arms in each seed/N group share one master clock draw');

safe=T.guardAtOrAboveBound==1;
add('sufficient_guard_collision_free', ...
    all(T.collisionFrames(safe)==0),sprintf( ...
    '%d safe-bound rows, %d collision frames',nnz(safe), ...
    sum(T.collisionFrames(safe))));
add('clock_equation_closes', ...
    all(T.maxClockEquationResidual<=R.tolerance),sprintf( ...
    'maximum residual %.3g s',max(T.maxClockEquationResidual)));
add('collision_witnesses_valid',all(T.collisionWitnessValid==1), ...
    'every marked collision has positive overlap and declared interference');
account=all(abs(T.offeredAirtimeSec- ...
    T.transmissions*R.dataAirtimeSec)<=R.tolerance) && ...
    all(T.busyTimeSec<=T.offeredAirtimeSec+R.tolerance) && ...
    all(T.channelUtilization<=T.offeredUtilization+R.tolerance);
add('interval_accounting_closes',account, ...
    'offered sum and busy-time union are consistent');

Bsync=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,0.5);
Bfree=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.horizonSec);
add('synchronization_reduces_guard', ...
    Bsync.safeGuardSec<Bfree.safeGuardSec,sprintf( ...
    '0.5-s %.6g s versus 12-s %.6g s', ...
    Bsync.safeGuardSec,Bfree.safeGuardSec));
add('model_validity_scope_only', ...
    ~R.policyOptimizationAllowed && ~R.formationPerformanceClaimPermitted, ...
    'no policy or formation outcome enters a validity gate');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p); %#ok<AGROW>
        detail{end+1,1}=d; %#ok<AGROW>
    end

end


function S=summaryTable(T)

[group,S]=findgroups(T(:,{'N','syncPeriodSec','guardFactor'}));
S.n=splitapply(@numel,T.collisionFrames,group);
S.runsWithCollision=splitapply(@(x) nnz(x>0),T.collisionFrames,group);
S.totalCollisionFrames=splitapply(@sum,T.collisionFrames,group);
S.meanOfferedUtilization=splitapply(@mean,T.offeredUtilization,group);
S.meanChannelUtilization=splitapply(@mean,T.channelUtilization,group);
S.maxClockEquationResidual=splitapply(@max, ...
    T.maxClockEquationResidual,group);

end


function [seeds,Ns]=groups(R)

seeds=repelem(R.seeds,numel(R.N));
Ns=repmat(R.N',numel(R.seeds),1);
Ns=Ns(:);

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP21B_CONTINUOUS_TIME_MAC_VALIDITY_PLAN.md', ...
    'network/continuousTdmaGuardBound.m', ...
    'network/simulateContinuousLocalTdma.m', ...
    'utils/exp21bTimingRegistry.m','utils/exp21bTimingEmptyRow.m', ...
    'tests/test_exp21b_continuous_timing_contracts.m', ...
    'experiments/exp21b_continuous_timing_validity.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp21b: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
