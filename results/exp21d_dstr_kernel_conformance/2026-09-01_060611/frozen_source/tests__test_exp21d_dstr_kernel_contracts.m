%% TEST_EXP21D_DSTR_KERNEL_CONTRACTS Source-mapped protocol witnesses.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp21d_dstr_kernel_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

%% Native N=5 must self-allocate and remove no valid occupied slot.
C=baseConfig(5,100);
T=deterministicTrace(C,17);
a=simulateDstrScheduling(C,T);
checks(end+1,:)={a.finalAllResolved && a.finalCollisionFree && ...
    a.finalFrameAgreement && isfinite(a.firstResolutionFrame), ...
    'native N5 reaches a valid resolved assignment'};
checks(end+1,:)={a.accountingCloses && a.futureRandomReads==0 && ...
    a.receiverTruthDecisionReads==0, ...
    'recipient accounting and causal-information counters close'};

%% N=10 with five initial transmission slots must activate TG/TGn growth.
C10=baseConfig(10,160);
T10=deterministicTrace(C10,29);
b=simulateDstrScheduling(C10,T10);
checks(end+1,:)={b.growRequests>0 && b.growNacks>0 && ...
    b.growthEvents>0 && b.finalDataSlots>=10, ...
    'colliding allocation activates TG/TGn and grows the superframe'};
checks(end+1,:)={b.finalAllResolved && b.finalCollisionFree && ...
    b.maxFrameDisagreement==0, ...
    'formation-wide management reach preserves native frame consensus'};
Rw=exp21dDstrRegistry();
[Cw,~]=applyExp21dDstrCondition(10,'native',Rw);
Tw=generateExp21dDstrTrace(16033001,10,Rw);
w=simulateDstrScheduling(Cw,Tw);
checks(end+1,:)={b.shrinkRequests>0 && b.shrinkObjects>0 && ...
    w.shrinkNacks>0 && b.shrinkEvents>0, ...
    'TS/TSo/TSn and successful shrink paths all activate'};

%% Two colliding claimants plus idle listeners produce record/NACK witnesses.
Cc=baseConfig(6,24);
Tc=deterministicTrace(Cc,3);
% Node 1 already owns slot 1.  Nodes 2--3 repeatedly choose slot 2 while
% nodes 4--6 occupy distinct slots and can therefore observe/report the
% collision.  Making every node choose one slot would create a legitimate
% half-duplex all-transmitter deadlock with no reception-record witness.
Tc.choiceU=repmat([0 0.2 0.2 0.4 0.6 0.8],Cc.maxFrames,1);
c=simulateDstrScheduling(Cc,Tc);
checks(end+1,:)={c.dataCollisionFrames>0 && c.dataRecipientCollision>0 && ...
    c.growRequests>0 && c.growNacks>0, ...
    'same-slot choices create DATA collision and energy-NACK witnesses'};

%% An all-transmitter collision must not be repaired by hidden truth.
Cd=baseConfig(6,12);
Td=deterministicTrace(Cd,5);
Td.choiceU(:)=0;
d=simulateDstrScheduling(Cd,Td);
checks(end+1,:)={~d.finalAllResolved && d.conflictFrameFraction>0 && ...
    d.growRequests>0 && d.dataRecipientCollision==0 && ...
    d.receiverTruthDecisionReads==0, ...
    'missing implicit reports cause causal retry without oracle repair'};

%% Exogenous erasure is distinct from endogenous collision and closes.
Ce=baseConfig(5,12);
Ce.dataErasureProbability=1;
Te=deterministicTrace(Ce,7);
e=simulateDstrScheduling(Ce,Te);
checks(end+1,:)={e.dataRecipientErasure>0 && ...
    e.dataRecipientSuccess==0 && e.accountingCloses, ...
    'post-collision erasure is separately charged and accounted'};

%% Churn uses normal Start/Assignment recovery rather than an oracle reset.
Cr=baseConfig(5,140);
Cr.churnEnabled=true;
Cr.churnFrame=50;
Tr=deterministicTrace(Cr,43);
r=simulateDstrScheduling(Cr,Tr);
checks(end+1,:)={r.churnApplied && isfinite(r.recoveryFrame) && ...
    r.finalAllResolved && r.finalCollisionFree, ...
    'state loss rejoins through the normal protocol path'};

%% Deterministic replay is bit-identical.
a2=simulateDstrScheduling(baseConfig(5,100),T);
checks(end+1,:)={a.realizationHash==a2.realizationHash && ...
    a.traceHash==a2.traceHash && a.configHash==a2.configHash, ...
    'identical absolute traces replay bit-identically'};

%% Frozen registry and factor projections are exact.
R=exp21dDstrRegistry();
checks(end+1,:)={R.expectedRuns==800 && numel(R.seeds)==100 && ...
    isequal(R.N,[5 10]) && numel(R.conditions)==4 && ...
    R.initialDataSlots==10 && R.failedShrinkTimeout==10, ...
    'registry contains exactly 800 declared seed/N/condition rows'};
[Cb,~]=applyExp21dDstrCondition(5,'beacon-loss',R);
checks(end+1,:)={Cb.dataErasureProbability==0.05 && ...
    Cb.managementErasureProbability==0 && ~Cb.churnEnabled, ...
    'beacon-loss boundary changes DATA erasure only'};
[Cm,~]=applyExp21dDstrCondition(10,'restricted-management',R);
[Cn,~]=applyExp21dDstrCondition(10,'native',R);
[Crg,~]=applyExp21dDstrCondition(5,'churn-rejoin',R);
checks(end+1,:)={isequal(Cm.neighborGraph,Cn.neighborGraph) && ...
    isequal(Cm.neighborGraph,Cm.managementReach) && ...
    all(sum(Cn.managementReach,2)==9) && ...
    Crg.churnEnabled && Crg.churnFrame==60, ...
    'restricted reach and churn mappings match the frozen factors'};
T1=generateExp21dDstrTrace(R.seeds(1),5,R);
T2=generateExp21dDstrTrace(R.seeds(1),5,R);
checks(end+1,:)={isequal(T1,T2) && ...
    isequal(size(T1.managementDeliveryU),[R.maxFrames 5 5 5]), ...
    'absolute trace generation is deterministic and dimensionally exact'};
Rshort=R; Rshort.maxFrames=17;
Rlong=R; Rlong.maxFrames=23;
Ts=generateExp21dDstrTrace(R.seeds(1),5,Rshort);
Tl=generateExp21dDstrTrace(R.seeds(1),5,Rlong);
checks(end+1,:)={isequal(Ts.choiceU,Tl.choiceU(1:17,:)) && ...
    isequal(Ts.retentionU,Tl.retentionU(1:17,:)) && ...
    isequal(Ts.dataDeliveryU,Tl.dataDeliveryU(1:17,:,:)) && ...
    isequal(Ts.managementDeliveryU,Tl.managementDeliveryU(1:17,:,:,:)), ...
    'absolute draw prefixes are invariant to horizon extension'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error(['test_exp21d_dstr_kernel_contracts: %d of %d ' ...
        'checks failed.'],nnz(~flags),numel(flags));
end
fprintf('\ntest_exp21d_dstr_kernel_contracts: PASS (%d checks)\n', ...
    numel(flags));


function C=baseConfig(N,maxFrames)

C=struct();
C.N=N;
C.maxFrames=maxFrames;
C.initialDataSlots=5;
C.maxDataSlots=64;
C.collisionThreshold=3;
C.growthMargin=3;
C.shrinkThreshold=5;
C.failedShrinkTimeout=10;
C.shrinkBackoffExponentCap=6;
C.retentionProbability=0.75;
C.frameBytes=512;
C.phyRateBps=1e6;
C.guardSec=0.540022e-3;
C.neighborGraph=true(N)-eye(N)>0;
C.managementReach=true(N)-eye(N)>0;
C.interferenceMatrix=true(N);
C.dataErasureProbability=0;
C.managementErasureProbability=0;
C.enableShrink=true;
C.churnEnabled=false;
C.churnFrame=min(60,maxFrames);
C.churnNode=min(2,N);

end


function T=deterministicTrace(C,offset)

[f,n]=ndgrid(1:C.maxFrames,1:C.N);
T.choiceU=mod(0.41421356237*f+0.61803398875*n+offset/97,1);
T.retentionU=mod(0.27182818285*f+0.14142135623*n+offset/89,1);
T.dataDeliveryU=0.9*ones(C.maxFrames,C.N,C.N);
T.managementDeliveryU=0.9*ones(C.maxFrames,5,C.N,C.N);

end
