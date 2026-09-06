function exp23x_local_union_migration_kernel()
%EXP23X_LOCAL_UNION_MIGRATION_KERNEL Randomized migration falsification.

startup; close all;
runRequiredTests();
R=exp23xLocalUnionMigrationRegistry();
[registryHash,registryLeaves]=configHash(R);
expRun=startExperiment('exp23x_local_union_migration_kernel', ...
    'Randomized local union-graph migration kernel falsification.');
writeJson(fullfile(expRun.dir,'migration_registry.json'),R);
snapshotSource(expRun.dir);

rows=repmat(exp23xLocalUnionMigrationEmptyRow(),R.expectedRuns,1); q=0;
for seed=reshape(R.seeds,1,[])
    for N=R.swarmSizes
        for k=1:numel(R.cases)
            q=q+1; rows(q)=runCell(seed,N,R.cases(k),R);
        end
    end
end
T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'migration_tidy.csv'));
S=summaryTable(T); writetable(S,fullfile(expRun.dir,'summary.csv'));
gates=validationGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'validation_gates.csv'));
valid=all(gates.passed==1);
status=ternary(valid,'LOCAL_UNION_MIGRATION_KERNEL_VALID', ...
    'LOCAL_UNION_MIGRATION_KERNEL_INVALID');
next=ternary(valid,'common_phy_local_migration_integration', ...
    'repair_migration_kernel_without_relaxing_gates');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'freshSeedEvidence',false,'closedLoopClaimPermitted',false, ...
    'submissionClaimPermitted',false,'next',next);
writeJson(fullfile(expRun.dir,'migration_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','gates','verdict','R');

fprintf('\nEXP23X local-union migration gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-42s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('EXP23X DECISION: %s\n',status);
finishExperiment(expRun);
if ~valid, error('exp23x: randomized migration kernel invalid.'); end

end


function row=runCell(seed,N,testCase,R)

[G0,G1,slot,node,reach,packet]=fixture(N,R);
localReach=reach; localPacket=packet;
if strcmp(testCase.kind,'missing-witness'), localReach=false(N); end
if strcmp(testCase.kind,'over-mtu')
    localPacket.maxControlPacketBytes=25;
end
M=buildLocalUnionGraphMigration(G0,G1,slot,node,localReach,localPacket);
C=struct('maxFrames',R.maxFrames,'transitionFrame',R.transitionFrame, ...
    'eligibleFrame',R.eligibleFrame, ...
    'newGraphActivationFrame',R.newGraphActivationFrame, ...
    'lockProofRepeatFrames',R.lockProofRepeatFrames, ...
    'phyRateBps',R.phyRateBps, ...
    'claimErasureProbability',testCase.erasureProbability, ...
    'lockProofErasureProbability',testCase.erasureProbability, ...
    'responseErasureProbability',testCase.erasureProbability, ...
    'revokeErasureProbability',testCase.erasureProbability);
T=generateLocalUnionMigrationTrace(seed,M,C); rawHash=T.hashExact;
switch testCase.kind
    case 'valid'
        if testCase.erasureProbability==0
            T.claimDeliveryU(:)=1; T.lockProofDeliveryU(:)=1;
            T.responseDeliveryU(:)=1; T.revokeDeliveryU(:)=1;
        end
    case 'response-blackout'
        T.responseDeliveryU(R.eligibleFrame:end,node,:)=0;
    case 'revoke-blackout'
        T.revokeDeliveryU(R.transitionFrame,:,node)=0;
    case 'stale-response'
        T.responseVersion(R.eligibleFrame:end,:)=1;
    case 'incomplete-union'
        T.actualGraph(R.newGraphActivationFrame:end,1,3)=true;
        T.actualGraph(R.newGraphActivationFrame:end,3,1)=true;
    case 'concurrent'
        T.selfRevoke(R.transitionFrame,2)=true;
    case {'missing-witness','over-mtu'}
        % The inadmissible selector must fail silent without trace help.
    otherwise
        error('exp23x: unknown case %s.',testCase.kind);
end
T.hashExact=localUnionMigrationTraceHash(T);
O=simulateLocalUnionGraphMigration(M,C,T);
row=exp23xLocalUnionMigrationEmptyRow();
row.seed=seed; row.N=N; row.caseId=testCase.id;
row.caseKind=testCase.kind; row.erasureProbability=testCase.erasureProbability;
row.selectorAdmissible=M.admissible; row.selectorReason=M.reason;
row.selectorHash=M.hashExact; row.rawTraceHash=rawHash;
row.finalTraceHash=T.hashExact; row.stateHash=O.stateHashExact;
row.slotChanged=M.slotChanged; row.oldSlot=M.oldSlot(node);
row.newSlot=M.newSlot; row.addedEdges=M.addedEdgeCount;
row.removedEdges=M.removedEdgeCount;
row.unionEdges=nnz(triu(M.unionGraph,1));
row.unionWitnessCovered=M.unionWitnessMap.allCovered;
row.maxIncidentEntriesAtWitness=M.maxIncidentEntriesAtWitness;
row.maxMigrationResponseBytes=M.maxMigrationResponseBytes;
row.eventFrame=O.eventFrame; row.eligibleFrame=O.eligibleFrame;
row.activationFrame=O.newGraphActivationFrame; row.reacquired=O.reacquired;
row.firstReacquiredFrame=O.firstReacquiredFrame;
row.finalSuppressed=O.finalSuppressed; row.finalSlot=O.finalSlot;
row.transactionOpen=O.transactionOpen;
row.acceptedEntries=O.acceptedResponseEntries;
row.requiredEntries=O.requiredResponseEntries;
row.responseEntriesAttempted=O.responseEntriesAttempted;
row.unsupportedConcurrent=O.unsupportedConcurrentMigration;
row.actualSubsetUnion=O.actualSubsetUnion;
row.scheduledCollisionFrames=O.scheduledCollisionFrames;
row.scheduledCollisionEdges=O.scheduledCollisionEdges;
row.unsafeReuseFrames=O.unsafeReuseFrames;
row.claimAttempts=O.claimAttempts; row.lockProofAttempts=O.lockProofAttempts;
row.responseAttempts=O.responseAttempts; row.revokeAttempts=O.revokeAttempts;
row.claimBytes=O.claimBytes; row.lockProofBytes=O.lockProofBytes;
row.responseBytes=O.responseBytes; row.revokeBytes=O.revokeBytes;
row.controlAttempts=O.controlAttempts; row.controlBytes=O.controlBytes;
row.controlAirtimeSec=O.controlAirtimeSec;
row.recipientAttempts=O.recipientAttempts;
row.recipientSuccess=O.recipientSuccess;
row.recipientErasure=O.recipientErasure;
row.recipientCollision=O.recipientCollision;
row.attemptBound=O.controlAttemptBound; row.byteBound=O.controlByteBound;
row.attemptBoundRatio=O.controlAttemptBoundRatio;
row.byteBoundRatio=O.controlByteBoundRatio;
row.futureRandomReads=O.futureRandomReads;
row.receiverTruthReads=O.receiverTruthReads;

end


function gates=validationGates(T,R,registryHash,registryLeaves)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
key=string(T.seed)+'|'+string(T.N)+'|'+string(T.caseId);
add('matrix_complete_unique',height(T)==R.expectedRuns && ...
    numel(unique(key))==height(T),sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
coverage=isequal(unique(T.seed),R.seeds) && ...
    isequal(unique(T.N)',R.swarmSizes) && ...
    isequal(sort(unique(string(T.caseId))), ...
    sort(reshape(string({R.cases.id}),[],1)));
add('exact_matrix_coverage',coverage, ...
    '100 seeds, N={5,10,20}, and ten cases exact');
paired=true;
for seed=R.seeds'
    for N=R.swarmSizes
        index=T.seed==seed & T.N==N;
        paired=paired && isscalar(unique(T.rawTraceHash(index)));
    end
end
add('paired_random_draws',paired, ...
    'all ten cases share one raw draw tensor per seed and size');
admissible=ismember(string(T.caseKind), ...
    ["valid" "response-blackout" "revoke-blackout" ...
    "stale-response" "incomplete-union" "concurrent"]);
add('selector_stimulus',all(T.selectorAdmissible(admissible)==1) && ...
    all(T.selectorAdmissible(~admissible)==0) && all( ...
    T.slotChanged==1) && all(T.addedEdges==1) && all(T.removedEdges==1), ...
    'every topology forces one add, one removal and a changed slot');
zero=string(T.caseId)=="zero-loss-valid";
add('zero_loss_activation',all(T.reacquired(zero)==1) && all( ...
    T.firstReacquiredFrame(zero)==R.eligibleFrame) && all( ...
    T.finalSlot(zero)==T.newSlot(zero)), ...
    '300/300 zero-loss rows activate the new slot at eligibility');
iid20=string(T.caseId)=="iid20-valid";
add('iid20_cumulative_recovery',all(T.reacquired(iid20)==1) && all( ...
    T.firstReacquiredFrame(iid20)>=R.eligibleFrame),sprintf( ...
    '%d/%d IID-20 rows recover',sum(T.reacquired(iid20)),nnz(iid20)));
iid40=string(T.caseId)=="iid40-valid";
add('iid40_cumulative_recovery',all(T.reacquired(iid40)==1) && all( ...
    T.firstReacquiredFrame(iid40)>=R.eligibleFrame),sprintf( ...
    '%d/%d IID-40 rows recover',sum(T.reacquired(iid40)),nnz(iid40)));
add('loss_delay_stimulus',any( ...
    T.firstReacquiredFrame(iid40)>R.eligibleFrame) && mean( ...
    T.controlAttempts(iid40))>mean(T.controlAttempts(zero)), ...
    'loss produces delayed closure and additional charged attempts');
blocked=string(T.caseKind)=="response-blackout";
add('response_blackout_fail_silent',all(T.reacquired(blocked)==0) && ...
    all(T.finalSuppressed(blocked)==1) && all( ...
    T.acceptedEntries(blocked)<T.requiredEntries(blocked)), ...
    'permanent missing RESPONSE never activates');
stale=string(T.caseKind)=="stale-response";
add('stale_response_fail_silent',all(T.reacquired(stale)==0) && ...
    all(T.acceptedEntries(stale)==0) && all(T.finalSuppressed(stale)==1), ...
    'wrong version cannot create a positive receipt');
revoke=string(T.caseKind)=="revoke-blackout";
revokeEquivalent=true;
for seed=R.seeds'
    for N=R.swarmSizes
        a=T.seed==seed & T.N==N & iid20;
        b=T.seed==seed & T.N==N & revoke;
        revokeEquivalent=revokeEquivalent && T.stateHash(a)==T.stateHash(b) && ...
            T.firstReacquiredFrame(a)==T.firstReacquiredFrame(b) && ...
            T.finalSlot(a)==T.finalSlot(b);
    end
end
add('revoke_blackout_equivalence',revokeEquivalent, ...
    'lost REVOKE cannot alter local state or reacquisition');
concurrent=string(T.caseKind)=="concurrent";
add('concurrent_boundary',all(T.unsupportedConcurrent(concurrent)==1) && ...
    all(T.reacquired(concurrent)==0) && all(T.finalSuppressed(concurrent)==1), ...
    'two-sender migration is explicitly unsupported and silent');
outside=string(T.caseKind)=="incomplete-union";
add('independent_union_oracle',all(T.actualSubsetUnion(outside)==0) && ...
    all(T.scheduledCollisionFrames(outside)>0), ...
    'omitted actual edge is rejected and its collision remains visible');
missing=string(T.caseKind)=="missing-witness";
mtu=string(T.caseKind)=="over-mtu";
add('inadmissible_selector_fail_silent',all(T.reacquired(missing|mtu)==0) && ...
    all(T.finalSuppressed(missing|mtu)==1) && all( ...
    string(T.selectorReason(missing))=="union_witness_uncovered") && all( ...
    string(T.selectorReason(mtu))=="migration_response_exceeds_mtu"), ...
    'missing witness and over-MTU selector outputs remain silent');
safe=~outside;
add('supported_safety',all(T.scheduledCollisionFrames(safe)==0) && ...
    all(T.unsafeReuseFrames(safe)==0), ...
    'zero scheduled collision or unsafe reuse in every supported row');
add('control_component_accounting',all(T.controlAttempts== ...
    T.claimAttempts+T.lockProofAttempts+T.responseAttempts+ ...
    T.revokeAttempts) && all(T.controlBytes==T.claimBytes+ ...
    T.lockProofBytes+T.responseBytes+T.revokeBytes), ...
    'attempt and byte components close exactly');
add('recipient_airtime_accounting',all(T.recipientSuccess+ ...
    T.recipientErasure+T.recipientCollision==T.recipientAttempts) && ...
    all(abs(T.controlAirtimeSec-T.controlBytes*8/R.phyRateBps)<=1e-15), ...
    'recipient outcomes and control airtime close');
add('absolute_bounds',all(T.attemptBoundRatio<=1+1e-12) && ...
    all(T.byteBoundRatio<=1+1e-12), ...
    'finite-horizon attempt and byte bounds hold');
add('causal_integrity',all(T.futureRandomReads==0) && ...
    all(T.receiverTruthReads==0) && all(isfinite(T.finalTraceHash)) && ...
    all(isfinite(T.stateHash)),'zero forbidden reads and exact hashes finite');
add('kernel_scope_only',~R.freshSeedEvidence && ...
    ~R.policyOptimizationAllowed && ~R.closedLoopClaimPermitted && ...
    ~R.submissionClaimPermitted, ...
    'randomized falsification cannot promote performance claims');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});
if height(gates)~=R.requiredValidationContracts
    error('exp23x: gate count differs from registry.');
end

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p); detail{end+1,1}=d;
    end
end


function [G0,G1,slot,node,reach,packet]=fixture(N,R)

node=N; G0=false(N);
for k=1:N-1, G0(k,k+1)=true; G0(k+1,k)=true; end
G1=G0; G1(N-1,N)=false; G1(N,N-1)=false;
G1(N-2,N)=true; G1(N,N-2)=true;
slot=elcsWitnessPriorityColor(G0);
reach=true(N); reach(1:N+1:end)=false;
packet=struct('maxDataSlots',N,'claimBytes',R.claimBytes, ...
    'certificateHeaderBytes',R.certificateHeaderBytes, ...
    'certificateEntryBytes',R.certificateEntryBytes, ...
    'maxControlPacketBytes',R.maxControlPacketBytes, ...
    'revokeBytes',R.revokeBytes);

end


function S=summaryTable(T)

[group,S]=findgroups(T(:,{'N','caseId','caseKind'}));
S.nRuns=splitapply(@numel,T.reacquired,group);
S.reacquisitionRate=splitapply(@mean,T.reacquired,group);
S.meanFirstReacquiredFrame=splitapply(@(x) mean(x,'omitnan'), ...
    T.firstReacquiredFrame,group);
S.meanControlAttempts=splitapply(@mean,T.controlAttempts,group);
S.meanControlBytes=splitapply(@mean,T.controlBytes,group);
S.collisionFrames=splitapply(@sum,T.scheduledCollisionFrames,group);

end


function runRequiredTests()

names={'test_exp23x_local_union_migration_contracts', ...
    'test_local_union_graph_migration_contracts', ...
    'test_local_union_graph_migration_kernel_contracts'};
for k=1:numel(names), runScriptIsolated(names{k}); end

end


function snapshotSource(target)

root=projectRoot();
files={'docs/EXP23X_LOCAL_UNION_GRAPH_MIGRATION_DESIGN.md', ...
    'docs/EXP23X_LOCAL_UNION_GRAPH_MIGRATION_KERNEL_PLAN.md', ...
    'network/buildLocalUnionGraphMigration.m', ...
    'network/generateLocalUnionMigrationTrace.m', ...
    'network/localUnionMigrationTraceHash.m', ...
    'network/simulateLocalUnionGraphMigration.m', ...
    'utils/exp23xLocalUnionMigrationRegistry.m', ...
    'utils/exp23xLocalUnionMigrationEmptyRow.m', ...
    'tests/test_exp23x_local_union_migration_contracts.m', ...
    'tests/test_local_union_graph_migration_contracts.m', ...
    'tests/test_local_union_graph_migration_kernel_contracts.m', ...
    'experiments/exp23x_local_union_migration_kernel.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp23x: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)

if condition, value=a; else, value=b; end

end
