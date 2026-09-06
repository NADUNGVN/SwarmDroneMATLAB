function row=runExp23aeClosureCommonPhyCell( ...
    seedValue,N,condition,clockArm,R)
%RUNEXP23AECLOSURECOMMONPHYCELL One closure common-PHY validation cell.

[M,C,T,I0,I1,physicalChanges,nonincident]=fixture(seedValue,N,R);
condition=char(condition);
if ~strcmp(condition,'iid20')
    fields={'prepareDeliveryU','quietDeliveryU','claimDeliveryU', ...
        'lockProofDeliveryU','responseDeliveryU','commitDeliveryU', ...
        'revokeDeliveryU'};
    for k=1:numel(fields), T.(fields{k})(:)=1; end
end
remote=M.affectedNodes(M.affectedNodes~=M.initiator);
target=remote(1); Iafter=I1;
switch condition
    case {'nominal-zero','iid20'}
    case 'prepare-blackout'
        T.prepareDeliveryU(:,target,M.initiator)=0;
    case 'quiescent-blackout'
        T.quietDeliveryU(:,M.initiator,target)=0;
    case 'response-blackout'
        T.responseDigest(:)=0;
    case 'commit-blackout'
        for node=reshape(remote,1,[])
            T.commitDeliveryU(:,node,M.initiator)=0;
        end
    case 'incomplete-union'
        omitted=setdiff((2:N-1)',find(I1(M.initiator,:))');
        if isempty(omitted)
            error('runExp23aeClosureCommonPhyCell: no omitted interferer.');
        end
        added=omitted(1);
        Iafter(M.initiator,added)=true;
        Iafter(added,M.initiator)=true;
        Fbad=buildSenderConflictGraph(M.dataNeighborGraph,Iafter);
        if ~any(triu(Fbad&~M.unionGraph,1),'all')
            error('runExp23aeClosureCommonPhyCell: oracle not stimulated.');
        end
        T.actualGraphAfter(:,:,:)=repmat(reshape(Fbad,1,N,N), ...
            C.maxFrames,1,1);
    otherwise
        error('runExp23aeClosureCommonPhyCell: unknown condition.');
end
T.hashExact=receiverLiftedClosureTraceHash(T);

controlSlot=8*R.maxControlPacketBytes/R.phyRateBps+R.safeGuardSec;
dataSlot=8*R.dataBytes/R.phyRateBps+R.safeGuardSec;
frameDuration=(2*N+1)*controlSlot+N*dataSlot;
P=struct('guardSec',R.safeGuardSec,'dataBytes',R.dataBytes, ...
    'horizonSec',R.maxFrames*frameDuration+.1);
Q=buildReceiverLiftedClosureContinuousSchedule(M,C,T,P);
K=Q.kernel;

physical=repmat(reshape(I0,1,N,N),C.maxFrames,1,1);
if isfinite(K.graphActivationFrame)
    physical(K.graphActivationFrame:end,:,:)= ...
        repmat(reshape(Iafter,1,N,N), ...
        C.maxFrames-K.graphActivationFrame+1,1,1);
end
Q=bindReplayDataOutcomes(Q,M.dataNeighborGraph,physical);

armIndex=find(string({R.clockArms.id})==string(clockArm),1);
if isempty(armIndex)
    error('runExp23aeClosureCommonPhyCell: unknown clock arm.');
end
arm=R.clockArms(armIndex);
if arm.impaired
    stream=RandStream('mrg32k3a', ...
        'Seed',mod(seedValue+73103+1000*N,2^32));
    stream.Substream=17;
    offset=(2*rand(stream,N,1)-1)*R.maxOffsetSec;
    drift=(2*rand(stream,N,1)-1)*R.maxDriftPpm;
else
    offset=zeros(N,1); drift=zeros(N,1);
end
spec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'maxOffsetSec',R.maxOffsetSec,'maxDriftPpm',R.maxDriftPpm, ...
    'leadTimeSec',R.clockLeadTimeSec,'safeGuardSec',R.safeGuardSec);
A=applyDstrAffineClockSchedule(Q,spec);

row=exp23aeClosureCommonPhyEmptyRow();
row.seed=seedValue; row.N=N; row.condition=condition;
row.clockArm=char(clockArm); row.clockImpaired=double(arm.impaired);
row.selectorHash=M.hashExact; row.traceHash=T.hashExact;
row.kernelStateHash=K.stateHashExact; row.nativeScheduleHash=Q.hashExact;
row.scheduleHash=A.hashExact; row.logicalHash=A.logicalOpportunityHashExact;
row.selectorAdmissible=M.admissible;
row.physicalChangeCount=physicalChanges;
row.senderChangeCount=M.changedEdgeCount;
row.nonincidentSenderChangeCount=nonincident;
row.affectedCount=M.affectedCount; row.changedSlotCount=M.changedSlotCount;
row.candidateProper=M.candidateUnionColoringProper;
row.actualSubsetUnion=K.actualSubsetUnion;
row.barrierClosed=K.barrierClosed; row.motionAuthorized=K.motionAuthorized;
row.commitReady=K.commitReady; row.allReactivated=K.allAffectedReactivated;
row.reactivatedCount=K.reactivatedCount;
row.finalSuppressedCount=K.finalSuppressedCount;
row.prepareBudgetExhausted=K.prepareBudgetExhausted;
row.commitBudgetExhausted=K.commitBudgetExhausted;
row.dataStateSlotExact=dataStateSlotExact(A,K,N,C.maxFrames);
row.kernelControlAttempts=K.controlAttempts;
row.physicalControlAttempts=numel(A.controlStartTime);
row.kernelControlBytes=K.controlBytes;
row.physicalControlBytes=sum(A.controlAttemptBytes);
row.kernelControlAirtime=K.controlAirtimeSec;
row.physicalControlAirtime=sum(A.controlAttemptAirtimeSec);
row.kernelRecipientAttempts=K.recipientAttempts;
row.physicalRecipientAttempts=A.expectedManagementRecipientAttempts;
row.kernelRecipientSuccess=K.recipientSuccess;
row.physicalRecipientSuccess=A.expectedManagementRecipientSuccess;
row.kernelRecipientErasure=K.recipientErasure;
row.physicalRecipientErasure=A.expectedManagementRecipientErasure;
row.prepareMapped=nnz(A.controlKind=="prepare");
row.quietMapped=nnz(A.controlKind=="quiescent");
row.claimMapped=nnz(A.controlKind=="claim");
row.proofMapped=nnz(A.controlKind=="lock-proof");
row.responseMapped=nnz(A.controlKind=="response");
row.commitMapped=nnz(A.controlKind=="commit");
row.revokeMapped=nnz(A.controlKind=="revoke");
row.kernelPrepareAttempts=K.attempts.prepare;
row.kernelQuietAttempts=K.attempts.quiet;
row.kernelClaimAttempts=K.attempts.claim;
row.kernelProofAttempts=K.attempts.lockProof;
row.kernelResponseAttempts=K.attempts.response;
row.kernelCommitAttempts=K.attempts.commit;
row.kernelRevokeAttempts=K.attempts.revoke;
row.piggybackRevoke=K.revokePiggybacked;
row.maxControlPacketBytes=max([0;A.controlAttemptBytes]);
row.nativeDataAttempts=numel(Q.dataStartTime);
row.physicalDataAttempts=numel(A.dataStartTime);
row.dataRecipientAttempts=nnz(A.dataSuccessMask|A.dataCollisionMask);
row.dataRecipientSuccess=nnz(A.dataSuccessMask);
row.dataRecipientCollision=nnz(A.dataCollisionMask);
row.dataRecipientPartitionExact=double(~any(A.dataSuccessMask & ...
    A.dataCollisionMask,'all') && row.dataRecipientSuccess+ ...
    row.dataRecipientCollision==row.dataRecipientAttempts);
row.kernelCollisionFrames=K.scheduledCollisionFrames;
row.physicalCollisionAttempts=nnz(any(A.dataCollisionMask,2));
row.physicalCollisionFrames=numel(unique( ...
    A.dataFrame(any(A.dataCollisionMask,2))));
row.clockTimingConflictFree=A.clockTimingConflictFree;
row.clockEquationResidual=A.clockEquationMaxResidualSec;
row.clockMinIntergroupGap=A.clockMinimumIntergroupGapSec;
row.clockMaxIntragroupSkew=A.clockMaximumIntragroupSkewSec;
row.nativeControlAttempts=numel(Q.controlStartTime);
row.physicalFrameDuration=Q.frameDurationSec; row.horizonSec=P.horizonSec;
row.attemptBoundRatio=K.controlAttemptBoundRatio;
row.byteBoundRatio=K.controlByteBoundRatio;
row.futureRandomReads=A.futureRandomReads;
row.receiverTruthReads=A.receiverTruthDecisionReads;

end


function [M,C,T,I0,I1,k,nonincident]=fixture(seedValue,N,R)

initiator=N; intendedSender=1;
neighbor=false(N); neighbor(initiator,intendedSender)=true;
k=1+mod(seedValue,min(R.maxPhysicalChanges,N-3));
interferers=(2:1+k)';
I0=false(N); I1=I0;
I1(initiator,interferers)=true; I1(interferers,initiator)=true;
F0=buildSenderConflictGraph(neighbor,I0);
F1=buildSenderConflictGraph(neighbor,I1);
oldSlot=elcsWitnessPriorityColor(F0);
reach=true(N); reach(1:N+1:end)=false;
packet=struct('maxDataSlots',R.maxDataSlotsFactor*N, ...
    'maxAffectedNodes',R.maxAffectedNodesFactor*N, ...
    'prepareHeaderBytes',R.prepareHeaderBytes, ...
    'affectedEntryBytes',R.affectedEntryBytes, ...
    'claimBytes',R.claimBytes,'quietBytes',R.quietBytes, ...
    'lockProofBytes',R.lockProofBytes, ...
    'certificateHeaderBytes',R.certificateHeaderBytes, ...
    'certificateEntryBytes',R.certificateEntryBytes, ...
    'commitBytes',R.commitBytes, ...
    'maxControlPacketBytes',R.maxControlPacketBytes, ...
    'revokeBytes',R.revokeBytes);
M=buildReceiverLiftedDependencyMigration(F0,F1,oldSlot,initiator, ...
    reach,packet);
M.dataNeighborGraph=logical(neighbor);
if ~M.admissible
    error('runExp23aeClosureCommonPhyCell: inadmissible fixture.');
end
nonincident=nnz(M.changedEdgeA~=initiator & ...
    M.changedEdgeB~=initiator);
C=struct('maxFrames',R.maxFrames,'prepareFrame',R.prepareFrame, ...
    'transactionVersion',R.transactionVersion, ...
    'prepareDenseRetryFrames',R.prepareDenseRetryFrames, ...
    'prepareMaxBackoffFrames',R.prepareMaxBackoffFrames, ...
    'prepareRetryAttemptLimit',R.prepareRetryAttemptLimit, ...
    'claimEligibilityDelayFrames',R.claimEligibilityDelayFrames, ...
    'lockProofRepeatFrames',R.lockProofRepeatFrames, ...
    'claimBackoffEnabled',R.claimBackoffEnabled, ...
    'claimDenseRetryFrames',R.claimDenseRetryFrames, ...
    'claimMaxBackoffFrames',R.claimMaxBackoffFrames, ...
    'claimRetryAttemptLimit',R.claimRetryAttemptLimit, ...
    'commitRetryAttemptLimit',R.commitRetryAttemptLimit, ...
    'phyRateBps',R.phyRateBps, ...
    'prepareErasureProbability',R.controlErasureProbability, ...
    'quietErasureProbability',R.controlErasureProbability, ...
    'claimErasureProbability',R.controlErasureProbability, ...
    'lockProofErasureProbability',R.controlErasureProbability, ...
    'responseErasureProbability',R.controlErasureProbability, ...
    'commitErasureProbability',R.controlErasureProbability, ...
    'revokeErasureProbability',R.controlErasureProbability, ...
    'piggybackRevoke',true);
T=generateReceiverLiftedClosureTrace(seedValue,M,C);

end


function exact=dataStateSlotExact(A,K,N,F)

exact=true;
for frame=1:F
    for node=1:N
        index=A.dataFrame==frame&A.dataNode==node;
        expected=logical(K.debug.active(frame,node));
        if nnz(index)~=double(expected)
            exact=false; return;
        end
        if expected && A.dataSlot(index)~=K.debug.slot(frame,node)
            exact=false; return;
        end
    end
end
exact=double(exact);

end
