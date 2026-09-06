function exp23l_coherence_geometry_kernel()
%EXP23L_COHERENCE_GEOMETRY_KERNEL Fresh motion-tube falsification study.

startup;
close all;
runScriptIsolated('test_coherence_certified_lease_contracts');
R=exp23lCoherenceGeometryRegistry();
[registryHash,registryLeaves]=configHash(R);
expRun=startExperiment('exp23l_coherence_geometry_kernel', ...
    ['Fresh randomized falsification of reachable conflict supergraphs, ' ...
    'coherence horizon selection and fail-silent self-revocation.']);
writeJson(fullfile(expRun.dir,'coherence_registry.json'),R);
writeJson(fullfile(expRun.dir,'coherence_opened.json'),struct( ...
    'openedAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'registryHash',registryHash,'registryLeaves',registryLeaves, ...
    'submissionClaimPermitted',false));
snapshotSource(expRun.dir);

rows=repmat(exp23lCoherenceGeometryEmptyRow(),R.expectedRuns,1);
q=0;
for seed=R.seeds'
    for N=R.nodeCounts
        base=baseRealization(seed,N,R);
        for conditionIndex=1:numel(R.conditions)
            q=q+1;
            rows(q)=runCell(base,R.conditions(conditionIndex), ...
                conditionIndex,R);
        end
    end
    if mod(find(R.seeds==seed),10)==0
        fprintf('  seeds %3d / %3d; rows %3d / %3d\n', ...
            find(R.seeds==seed),numel(R.seeds),q,R.expectedRuns);
    end
end

T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'coherence_tidy.csv'));
S=summaryTable(T);
writetable(S,fullfile(expRun.dir,'summary.csv'));
gates=validationGates(T,R,registryHash,registryLeaves);
writetable(gates,fullfile(expRun.dir,'validation_gates.csv'));
pass=all(gates.passed==1);
status=ternary(pass,'COHERENCE_GEOMETRY_KERNEL_VALID', ...
    'COHERENCE_GEOMETRY_KERNEL_INVALID');
verdict=struct('status',status,'gatesPassed',sum(gates.passed), ...
    'gatesTotal',height(gates),'rows',height(T), ...
    'distributedKernelIntegrationPermitted',pass, ...
    'newMethodPromotionAllowed',false,'submissionClaimPermitted',false);
writeJson(fullfile(expRun.dir,'coherence_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','gates','verdict','R');

fprintf('\nEXP23L coherence geometry-kernel gates\n');
for k=1:height(gates)
    fprintf('  [%-4s] %-43s %s\n', ...
        ternary(gates.passed(k)==1,'PASS','FAIL'), ...
        char(gates.gate(k)),char(gates.detail(k)));
end
fprintf('\nEXP23L DECISION: %s\n',status);
finishExperiment(expRun);
if ~pass, error('exp23l: coherence geometry kernel invalid.'); end

end


function base=baseRealization(seedValue,N,R)

stream=RandStream('mrg32k3a','Seed',mod(seedValue+701*N,2^32));
stream.Substream=1; p=R.areaSide*rand(stream,N,R.dimension);
stream.Substream=2;
v=(2*rand(stream,N,R.dimension)-1)*R.nominalSpeedBound;
stream.Substream=3; pDirection=randn(stream,N,R.dimension);
stream.Substream=4; vDirection=randn(stream,N,R.dimension);
stream.Substream=5; aDirection=randn(stream,N,R.dimension);
stream.Substream=6; pFraction=rand(stream,N,1).^(1/R.dimension);
stream.Substream=7; vFraction=rand(stream,N,1).^(1/R.dimension);
stream.Substream=8; aFraction=rand(stream,N,1).^(1/R.dimension);
pDirection=normalizeRows(pDirection);
vDirection=normalizeRows(vDirection);
aDirection=normalizeRows(aDirection);
distance=squareformLocal(p);
management=distance<=R.managementRadius;
management(1:N+1:end)=false;
base=struct('seed',seedValue,'N',N,'p',p,'v',v, ...
    'pDirection',pDirection,'vDirection',vDirection, ...
    'aDirection',aDirection,'pFraction',pFraction, ...
    'vFraction',vFraction,'aFraction',aFraction, ...
    'managementReach',management,'hashExact',realizationHash([ ...
    seedValue;N;p(:);v(:);pDirection(:);vDirection(:);aDirection(:); ...
    pFraction;vFraction;aFraction;double(management(:))]));

end


function row=runCell(base,condition,conditionIndex,R)

N=base.N;
ep=condition.positionError*ones(N,1);
ev=condition.velocityError*ones(N,1);
aa=R.accelerationBound*ones(N,1);
state=struct('p',base.p,'v',base.v,'positionError',ep, ...
    'velocityError',ev,'accelerationBound',aa);
C=struct('interferenceRadius',R.interferenceRadius, ...
    'managementReach',base.managementReach,'maxDataSlots',N, ...
    'claimBytes',R.claimBytes, ...
    'certificateHeaderBytes',R.certificateHeaderBytes, ...
    'certificateEntryBytes',R.certificateEntryBytes, ...
    'maxControlPacketBytes',R.maxControlPacketBytes, ...
    'mandatoryConflictGraph',false(N));
selector=selectCoherenceLeaseHorizon(state,R.horizonsSec,C);

pError=base.pDirection.*(base.pFraction.*ep);
vError=base.vDirection.*(base.vFraction.*ev);
actualAcceleration=base.aDirection.*( ...
    base.aFraction.*R.accelerationBound);
subsetViolations=0; colorViolations=0; monotonicViolations=0;
previous=false(N);
for h=R.horizonsSec
    G=buildReachableConflictSupergraph( ...
        state,h,R.interferenceRadius,false(N));
    monotonicViolations=monotonicViolations+nnz(previous & ...
        ~G.potentialGraph);
    previous=G.potentialGraph;
    color=elcsWitnessPriorityColor(G.potentialGraph);
    for tau=linspace(0,h,R.timeSamplesPerHorizon)
        actual=base.p+pError+(base.v+vError)*tau+ ...
            0.5*actualAcceleration*tau^2;
        distance=squareformLocal(actual);
        conflict=distance<=R.interferenceRadius;
        conflict(1:N+1:end)=false;
        subsetViolations=subsetViolations+nnz(triu( ...
            conflict & ~G.potentialGraph,1));
        sameColor=color==color';
        colorViolations=colorViolations+nnz(triu(conflict & sameColor,1));
    end
end

normalRevocations=0; violationMisses=0;
for node=1:N
    A=struct('p',base.p(node,:),'v',base.v(node,:), ...
        'positionError',ep(node),'velocityError',ev(node), ...
        'accelerationBound',aa(node),'issuedAt',0, ...
        'expiryTime',R.horizonsSec(end),'tupleVersion',1);
    current=struct('p',base.p(node,:)+pError(node,:), ...
        'v',base.v(node,:)+vError(node,:), ...
        'a',actualAcceleration(node,:),'time',0);
    D=coherenceSelfRevocationDecision(A,current,R.monitorStepSec);
    normalRevocations=normalRevocations+double(D.selfRevokeRequired);
    current.a=base.aDirection(node,:)*R.accelerationBound* ...
        R.violationAccelerationFactor;
    D=coherenceSelfRevocationDecision(A,current,R.monitorStepSec);
    violationMisses=violationMisses+double(~D.selfRevokeRequired);
end

selectedEdges=0; selectedColors=0; selectedCovered=0; selectedFit=0;
if selector.selectedIndex>0
    selectedEdges=selector.selectedGraph.edgeCount;
    selectedColors=max(selector.selectedColor);
    selectedCovered=double(selector.selectedWitnessMap.allCovered);
    index=selector.selectedIndex;
    selectedFit=double(selector.payloadFitsSingleResponse(index));
end
row=exp23lCoherenceGeometryEmptyRow();
row.seed=base.seed; row.N=N; row.condition=condition.id;
row.conditionIndex=conditionIndex;
row.positionError=condition.positionError;
row.velocityError=condition.velocityError;
row.BASE_REALIZATION_HASH=base.hashExact;
row.STATE_HASH_EXACT=realizationHash([base.hashExact;ep;ev;aa]);
row.MANAGEMENT_GRAPH_HASH=realizationHash(double(base.managementReach(:)));
row.SELECTOR_HASH_EXACT=selector.hashExact;
row.selectedHorizonSec=selector.selectedHorizonSec;
row.selectedIndex=selector.selectedIndex;
row.selectedEdgeCount=selectedEdges;
row.selectedColorCount=selectedColors;
row.selectedWitnessCovered=selectedCovered;
row.selectedPayloadFits=selectedFit;
row.targetHorizonSelected=double( ...
    selector.selectedHorizonSec==R.horizonsSec(end));
row.noLeaseIssued=double(selector.selectedIndex==0);
row.infeasibleHorizonCount=nnz(~selector.feasible);
row.actualSubsetViolations=subsetViolations;
row.sameColorConflictViolations=colorViolations;
row.horizonMonotonicViolations=monotonicViolations;
row.normalSelfRevocations=normalRevocations;
row.injectedViolationMisses=violationMisses;
row.futureRandomReads=selector.futureRandomReads;
row.receiverTruthDecisionReads=selector.receiverTruthDecisionReads;

end


function gates=validationGates(T,R,registryHash,registryLeaves)

name=cell(0,1); pass=false(0,1); detail=cell(0,1);
add('registry_frozen',isfinite(registryHash) && registryLeaves>0, ...
    sprintf('hash %.0f over %d leaves',registryHash,registryLeaves));
key=string(T.seed)+'|'+string(T.N)+'|'+string(T.condition);
add('matrix_complete_unique',height(T)==R.expectedRuns && ...
    numel(unique(key))==height(T),sprintf('%d/%d unique rows', ...
    numel(unique(key)),R.expectedRuns));
coverage=isequal(unique(T.seed),R.seeds) && ...
    isequal(unique(T.N)',R.nodeCounts) && isequal( ...
    sort(unique(string(T.condition))), ...
    sort(reshape(string({R.conditions.id}),[],1)));
add('exact_matrix_coverage',coverage, ...
    '100 seeds, N5/N10 and two uncertainty levels exact');
paired=true;
for seed=R.seeds'
    for N=R.nodeCounts
        index=T.seed==seed & T.N==N;
        paired=paired && nnz(index)==2 && ...
            isscalar(unique(T.BASE_REALIZATION_HASH(index))) && ...
            isscalar(unique(T.MANAGEMENT_GRAPH_HASH(index)));
    end
end
add('paired_base_realizations',paired, ...
    'uncertainty arms share motion, errors and management graph');
fixture=baseRealization(R.seeds(1),R.nodeCounts(1),R);
a=runCell(fixture,R.conditions(1),1,R);
b=runCell(fixture,R.conditions(1),1,R);
add('deterministic_reproduction',isequaln(a,b), ...
    'repeated seed/cell is bit-identical');
add('actual_graph_subset',all(T.actualSubsetViolations==0), ...
    'every sampled actual conflict belongs to its supergraph');
add('proper_color_safety',all(T.sameColorConflictViolations==0), ...
    'no sampled actual conflict shares a selected graph color');
add('horizon_graph_monotonicity',all(T.horizonMonotonicViolations==0), ...
    'potential edges never disappear as horizon grows');
contraction=true;
for seed=R.seeds'
    for N=R.nodeCounts
        low=T.selectedHorizonSec(T.seed==seed & T.N==N & ...
            string(T.condition)=="low-uncertainty");
        high=T.selectedHorizonSec(T.seed==seed & T.N==N & ...
            string(T.condition)=="high-uncertainty");
        contraction=contraction && isscalar(low) && isscalar(high) && ...
            high<=low+1e-12;
    end
end
add('uncertainty_horizon_contraction',contraction, ...
    'higher causal uncertainty never lengthens selected horizon');
issued=T.selectedIndex>0;
add('issued_horizon_feasible',all(T.selectedWitnessCovered(issued)==1) && ...
    all(T.selectedPayloadFits(issued)==1) && all( ...
    T.selectedColorCount(issued)<=T.N(issued)), ...
    'every issued lease has cover, payload and slot feasibility');
add('uncovered_fail_silent',all(T.noLeaseIssued==double( ...
    T.selectedIndex==0)), ...
    'no feasible horizon yields no positive lease');
add('self_revocation_contract',all(T.normalSelfRevocations==0) && ...
    all(T.injectedViolationMisses==0), ...
    'bounded motion remains active; injected bound violation self-revokes');
add('causal_information_contract',all(T.futureRandomReads==0) && ...
    all(T.receiverTruthDecisionReads==0), ...
    'zero future-random and receiver-truth decision reads');
stimulus=any(T.targetHorizonSelected==1) && ...
    any(T.selectedHorizonSec>0 & T.targetHorizonSelected==0) && ...
    any(T.noLeaseIssued==1);
add('selector_boundary_stimulus',stimulus,sprintf( ...
    'target/contracted/no-lease rows %d/%d/%d', ...
    nnz(T.targetHorizonSelected),nnz(T.selectedHorizonSec>0 & ...
    T.targetHorizonSelected==0),nnz(T.noLeaseIssued)));
add('kernel_scope_only',~R.policyOptimizationAllowed && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted, ...
    'no closed-loop, promotion or submission decision');
gates=table(string(name),double(pass),string(detail), ...
    'VariableNames',{'gate','passed','detail'});
if height(gates)~=R.requiredValidationContracts
    error('exp23l: registry contract count differs from implemented gates.');
end

    function add(n,p,d)
        name{end+1,1}=n; pass(end+1,1)=logical(p);
        detail{end+1,1}=d;
    end

end


function S=summaryTable(T)
[group,S]=findgroups(T(:,{'N','condition','positionError','velocityError'}));
S.nRuns=splitapply(@numel,T.selectedHorizonSec,group);
S.meanSelectedHorizonSec=splitapply(@mean,T.selectedHorizonSec,group);
S.targetHorizonRate=splitapply(@mean,T.targetHorizonSelected,group);
S.noLeaseRate=splitapply(@mean,T.noLeaseIssued,group);
S.meanSelectedEdges=splitapply(@mean,T.selectedEdgeCount,group);
S.meanInfeasibleHorizons=splitapply(@mean,T.infeasibleHorizonCount,group);
end


function D=squareformLocal(p)
N=size(p,1); D=zeros(N);
for i=1:N
    for j=i+1:N
        D(i,j)=norm(p(i,:)-p(j,:)); D(j,i)=D(i,j);
    end
end
end


function x=normalizeRows(x)
n=sqrt(sum(x.^2,2)); n(n==0)=1; x=x./n;
end


function snapshotSource(target)
root=projectRoot();
files={'docs/EXP23L_COHERENCE_CERTIFIED_LEASE_DESIGN.md', ...
    'docs/EXP23L_COHERENCE_GEOMETRY_KERNEL_PLAN.md', ...
    'network/buildReachableConflictSupergraph.m', ...
    'network/selectCoherenceLeaseHorizon.m', ...
    'network/coherenceSelfRevocationDecision.m', ...
    'utils/exp23lCoherenceGeometryRegistry.m', ...
    'utils/exp23lCoherenceGeometryEmptyRow.m', ...
    'tests/test_coherence_certified_lease_contracts.m', ...
    'experiments/exp23l_coherence_geometry_kernel.m'};
freeze=fullfile(target,'frozen_source'); mkdir(freeze);
for k=1:numel(files)
    name=replace(files{k},{'/' '\'},'__');
    copyfile(fullfile(root,files{k}),fullfile(freeze,name));
end
end


function writeJson(path,value)
fid=fopen(path,'w');
if fid<0, error('exp23l: cannot write %s.',path); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));
end


function value=ternary(condition,a,b)
if condition, value=a; else, value=b; end
end
