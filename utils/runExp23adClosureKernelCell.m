function row=runExp23adClosureKernelCell(seedValue,N,condition,R)
%RUNEXP23ADCLOSUREKERNELCELL One receiver-lift closure kernel cell.

[M,physicalChanges,nonincident]=fixture(seedValue,N,R);
C=kernelConfig(R);
T=generateReceiverLiftedClosureTrace(seedValue,M,C);
condition=char(condition);
if ~strcmp(condition,'iid20')
    fields={'prepareDeliveryU','quietDeliveryU','claimDeliveryU', ...
        'lockProofDeliveryU','responseDeliveryU','commitDeliveryU', ...
        'revokeDeliveryU'};
    for k=1:numel(fields), T.(fields{k})(:)=1; end
end
remote=M.affectedNodes(M.affectedNodes~=M.initiator);
target=remote(1);
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
    case 'revoke-blackout'
        T.revokeDeliveryU(:)=0;
    case 'incomplete-union'
        missing=find(triu(~M.unionGraph,1),1);
        if isempty(missing), error('exp23ad: fixture has no omitted edge.'); end
        [a,b]=ind2sub([N N],missing);
        T.actualGraphAfter(:,a,b)=true; T.actualGraphAfter(:,b,a)=true;
    otherwise
        error('runExp23adClosureKernelCell: unknown condition.');
end
T.hashExact=receiverLiftedClosureTraceHash(T);
O=simulateReceiverLiftedClosureMigration(M,C,T);
row=exp23adClosureKernelEmptyRow();
row.seed=seedValue; row.N=N; row.condition=condition;
row.traceHash=T.hashExact; row.selectorHash=M.hashExact;
row.stateHash=O.stateHashExact; row.physicalChangeCount=physicalChanges;
row.senderChangeCount=M.changedEdgeCount;
row.nonincidentSenderChangeCount=nonincident;
row.initiatorIsChangedEndpoint=M.changedEdgeEndpointMask(M.initiator);
row.affectedCount=M.affectedCount;
row.affectedHash=realizationHash(M.affectedNodes);
row.changedSlotCount=M.changedSlotCount;
row.outsideUnchanged=M.outsideSubgraphUnchanged;
row.candidateProper=M.candidateUnionColoringProper;
row.prepareBytes=M.prepareBytes; row.maxResponseBytes=M.maxResponseBytes;
row.barrierClosed=O.barrierClosed; row.barrierFrame=O.barrierFrame;
row.motionAuthorized=O.motionAuthorized;
row.activationFrame=O.graphActivationFrame; row.commitReady=O.commitReady;
row.allReactivated=O.allAffectedReactivated;
row.reactivatedCount=O.reactivatedCount;
row.finalSuppressedCount=O.finalSuppressedCount;
row.prepareBudgetExhausted=O.prepareBudgetExhausted;
row.commitBudgetExhausted=O.commitBudgetExhausted;
row.edgeReceipts=O.edgeReceipts;
row.requiredEdgeReceipts=O.requiredEdgeReceipts;
row.actualSubsetUnion=O.actualSubsetUnion;
row.collisionFrames=O.scheduledCollisionFrames;
row.collisionEdges=O.scheduledCollisionEdges;
row.controlAttempts=O.controlAttempts; row.controlBytes=O.controlBytes;
row.controlAirtime=O.controlAirtimeSec;
row.attemptBound=O.controlAttemptBound; row.byteBound=O.controlByteBound;
row.attemptBoundRatio=O.controlAttemptBoundRatio;
row.byteBoundRatio=O.controlByteBoundRatio;
row.recipientAttempts=O.recipientAttempts;
row.recipientSuccess=O.recipientSuccess;
row.recipientErasure=O.recipientErasure;
row.prepareAttempts=O.attempts.prepare; row.quietAttempts=O.attempts.quiet;
row.claimAttempts=O.attempts.claim; row.proofAttempts=O.attempts.lockProof;
row.responseAttempts=O.attempts.response;
row.commitAttempts=O.attempts.commit; row.revokeAttempts=O.attempts.revoke;
row.futureRandomReads=O.futureRandomReads;
row.receiverTruthReads=O.receiverTruthDecisionReads;

end


function [M,k,nonincident]=fixture(seedValue,N,R)

initiator=N; intendedSender=1;
neighbor=false(N); neighbor(initiator,intendedSender)=true;
k=1+mod(seedValue,min(R.maxPhysicalChanges,N-2));
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
if ~M.admissible, error('exp23ad: generated fixture inadmissible.'); end
nonincident=nnz(M.changedEdgeA~=initiator&M.changedEdgeB~=initiator);

end


function C=kernelConfig(R)

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
    'revokeErasureProbability',R.controlErasureProbability);

end
