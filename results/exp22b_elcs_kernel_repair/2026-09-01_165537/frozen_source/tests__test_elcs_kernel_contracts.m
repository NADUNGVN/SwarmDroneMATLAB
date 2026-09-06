%% TEST_ELCS_KERNEL_CONTRACTS Edge-lease safety and causal evidence.

startup;
fprintf('\n============================================================\n');
fprintf('test_elcs_kernel_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

%% Zero-loss priority induction and accounting.
C=elcsKernelConfig(5,180);
T=generateElcsTrace(16038991,C);
zero=simulateElcsScheduling(C,T);
checks(end+1,:)={zero.finalAllCertified && ...
    isfinite(zero.firstAllCertifiedFrame) && ...
    zero.finalScheduledCollisionFree && ...
    zero.falseValidEdgeFrames==0 && zero.ownerLockViolations==0, ...
    'zero-loss priority coloring reaches a certified safe schedule'};
checks(end+1,:)={zero.accountingCloses && ...
    zero.offeredUtilization>=zero.channelUtilization && ...
    zero.statusAttempts>0 && zero.grantAttempts>0 && ...
    zero.scheduledAttempts>0 && zero.fallbackAttempts>0, ...
    'control, fallback and scheduled attempt accounting closes'};

%% Losing one owner-to-client GRANT is conservative, not false-valid.
C2=elcsKernelConfig(3,120);
C2.managementErasureProbability=0.5;
T2=generateElcsTrace(16038992,C2);
T2.statusDeliveryU(:)=1;
T2.grantDeliveryU(:)=1;
T2.grantDeliveryU(:,2,1)=0; % every 1 -> 2 GRANT is erased
T2.statusSlotU(:)=0;
T2.grantSlotU(:)=0;
loss=simulateElcsScheduling(C2,T2);
checks(end+1,:)={loss.debug.active(end,1) && ...
    ~loss.debug.active(end,2) && loss.falseValidEdgeFrames==0 && ...
    loss.scheduledCollisionFrames==0 && ...
    any(reshape(loss.debug.fallbackTx(:,:,2),[],1)), ...
    'lost final GRANT leaves the client in the disjoint fallback region'};
checks(end+1,:)={loss.ownerLockExpiry(1,2)>0 && ...
    loss.grantExpiry(2,1)==0 && loss.ownerLockViolations==0, ...
    'owner lock is created by a GRANT attempt even when decoding fails'};

%% DATA erasure cannot mutate schedule evidence.
C3=C;
C3.dataErasureProbability=1;
T3=T;
T3.scheduledDeliveryU(:)=0;
T3.fallbackDeliveryU(:)=0;
erased=simulateElcsScheduling(C3,T3);
checks(end+1,:)={isequal(erased.debug.ready,zero.debug.ready) && ...
    isequal(erased.debug.active,zero.debug.active) && ...
    isequal(erased.debug.slot,zero.debug.slot) && ...
    erased.scheduledRecipientSuccess==0 && ...
    erased.scheduledRecipientErasure>0, ...
    'DATA erasure changes delivery only and never schedule evidence'};

%% Restricted reach cannot create certified incompatibility.
C4=elcsKernelConfig(4,140);
C4.conflictGraph=true(4)-eye(4)>0;
C4.neighborGraph=C4.conflictGraph;
C4.interferenceMatrix=C4.conflictGraph;
C4.managementReach=false(4);
C4.managementReach(2,1)=true; C4.managementReach(1,2)=true;
C4.managementReach(3,2)=true; C4.managementReach(2,3)=true;
C4.managementReach(4,3)=true; C4.managementReach(3,4)=true;
T4=generateElcsTrace(16038993,C4);
restricted=simulateElcsScheduling(C4,T4);
checks(end+1,:)={restricted.falseValidEdgeFrames==0 && ...
    restricted.scheduledCollisionFrames==0 && ...
    ~restricted.finalAllCertified && ...
    any(~restricted.debug.active(end,:)), ...
    'missing conflict-edge visibility yields fallback rather than false validity'};
checks(end+1,:)={restricted.frameLength==C4.N && ...
    all(restricted.debug.slot(:)>=0) && ...
    restricted.accountingCloses, ...
    'fixed frame remains common under restricted management reach'};

%% A conflict-envelope underapproximation is rejected before execution.
Cbad=C4;
Cbad.conflictGraph(1,4)=false;
Cbad.conflictGraph(4,1)=false;
rejected=false;
try
    simulateElcsScheduling(Cbad,T4);
catch err
    rejected=contains(err.message,'conflict envelope omits');
end
checks(end+1,:)={rejected, ...
    'physical conflict outside the declared envelope is rejected explicitly'};

%% Local client evidence loss reconstructs through the normal lease path.
C5=elcsKernelConfig(5,220);
C5.stateLossEnabled=true;
C5.stateLossFrame=100;
C5.stateLossNode=2;
T5=generateElcsTrace(16038994,C5);
churn=simulateElcsScheduling(C5,T5);
checks(end+1,:)={isfinite(churn.recoveryFrame) && ...
    churn.recoveryFrame>0 && churn.finalAllCertified && ...
    churn.falseValidEdgeFrames==0 && churn.ownerLockViolations==0, ...
    'state-loss client reconstructs without violating outstanding owner locks'};

%% Owner tuple reconfiguration is fenced beyond every issued lease.
C6=elcsKernelConfig(4,260);
C6.reconfigurationEnabled=true;
C6.reconfigurationFrame=120;
C6.reconfigurationNode=2;
C6.reconfigurationSlot=4;
T6=generateElcsTrace(16038995,C6);
changed=simulateElcsScheduling(C6,T6);
checks(end+1,:)={isfinite(changed.reconfigurationAppliedFrame) && ...
    changed.reconfigurationAppliedFrame> ...
        changed.reconfigurationReleaseFence && ...
    changed.slot(2)==4 && changed.ownerLockViolations==0 && ...
    changed.falseValidEdgeFrames==0 && ...
    changed.scheduledCollisionFrames==0 && ...
    changed.finalAllCertified && changed.automaticRecolorCount>=1, ...
    'owner tuple changes only after client-stop and owner-lock fencing'};

%% Every v1 zero-loss terminal-refresh witness closes structurally in v2.
failureSeeds=[16040037 16040042 16040061 16040075 16040080 16040096];
R=exp22ElcsKernelRegistry();
base=applyExp21dClosedLoopCell(R.cells(2).exp21dCell,failureSeeds(1));
allClosed=true;
for seed=failureSeeds
    base=applyExp21dClosedLoopCell(R.cells(2).exp21dCell,seed);
    probe=elcsKernelConfig(base.swarm.N,R.maxFrames);
    Treg=generateElcsTrace(seed,probe);
    condition=R.conditions(strcmp({R.conditions.id},R.zeroCondition));
    [Creg,Treg]=applyExp22ElcsCondition(base,condition,Treg,R);
    regression=simulateElcsScheduling(Creg,Treg);
    allClosed=allClosed && regression.finalAllCertified && ...
        regression.falseValidEdgeFrames==0 && ...
        regression.scheduledCollisionFrames==0;
end
checks(end+1,:)={allClosed, ...
    'deterministic control closes all six v1 refresh-outage witnesses'};

%% Stale, future and mismatched grants are rejected.
state=localClientState(3,1,3,3);
base=struct('owner',1,'client',3,'epoch',1,'frameLength',3, ...
    'ownerSlot',1,'clientSlot',3,'activationFrame',5, ...
    'expiryFrame',30,'version',1);
[ok,state]=elcsAcceptGrant(state,base,5,C2);
stale=base; stale.epoch=0;
future=base; future.epoch=2;
mismatch=base; mismatch.clientSlot=1;
[a,~,ra]=elcsAcceptGrant(state,stale,6,C2);
[b,~,rb]=elcsAcceptGrant(state,future,6,C2);
[c,~,rc]=elcsAcceptGrant(state,mismatch,6,C2);
checks(end+1,:)={ok && ~a && ~b && ~c && ...
    strcmp(ra,'stale-epoch') && strcmp(rb,'future-epoch') && ...
    strcmp(rc,'tuple-mismatch'), ...
    'stale, future and tuple-mismatched GRANTs never create validity'};

%% Absolute trace replay.
repeat=simulateElcsScheduling(C,T);
checks(end+1,:)={zero.realizationHash==repeat.realizationHash && ...
    zero.traceHash==repeat.traceHash && zero.futureRandomReads==0 && ...
    zero.receiverTruthDecisionReads==0, ...
    'identical absolute trace replays bit-identically and causally'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_elcs_kernel_contracts: %d of %d failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_elcs_kernel_contracts: PASS (%d checks)\n',numel(flags));


function state=localClientState(node,epoch,L,slot)

state=struct('node',node,'epoch',epoch,'frameLength',L,'slot',slot, ...
    'grantExpiry',zeros(1,L),'grantOwnerSlot',zeros(1,L), ...
    'grantClientSlot',zeros(1,L),'lastGrantVersion',zeros(1,L));

end
