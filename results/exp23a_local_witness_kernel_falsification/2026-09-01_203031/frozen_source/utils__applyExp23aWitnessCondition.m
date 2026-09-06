function [C,T,meta]=applyExp23aWitnessCondition(base,condition,baseTrace,R)
%APPLYEXP23AWITNESSCONDITION Map one frozen witness-kernel condition.

N=base.swarm.N;
C=elcsWitnessKernelConfig(N,R.maxFrames);
C.neighborGraph=logical(base.swarm.A);
C.managementReach=C.neighborGraph;
C.interferenceMatrix=logical(base.mac.interferenceMatrix);
C.conflictGraph=buildSenderConflictGraph( ...
    C.neighborGraph,C.interferenceMatrix);
C.claimBytes=R.claimBytes;
C.certificateHeaderBytes=R.certificateHeaderBytes;
C.certificateEntryBytes=R.certificateEntryBytes;
C.maxControlPacketBytes=R.maxControlPacketBytes;
T=baseTrace;
owner=NaN; client=NaN; witness=NaN;
switch char(condition.id)
    case R.zeroCondition
    case R.claimLossCondition
        C.claimErasureProbability=R.claimErasureProbability;
    case R.certificateLossCondition
        C.certificateErasureProbability=R.certificateErasureProbability;
    case R.dataLossCondition
        C.dataErasureProbability=R.dataErasureProbability;
    case R.blackoutCondition
        W=buildConflictWitnessMap(C.conflictGraph,C.managementReach);
        [aa,bb]=find(triu(C.conflictGraph,1));
        target=find(arrayfun(@(q) W.witness(aa(q),bb(q))~=bb(q), ...
            1:numel(aa)),1);
        if isempty(target)
            error('applyExp23aWitnessCondition: no transmitted CERT edge.');
        end
        owner=aa(target); client=bb(target); witness=W.witness(owner,client);
        C.certificateErasureProbability=R.blackoutDrawThreshold;
        T.certificateDeliveryU(:)=1;
        T.certificateDeliveryU(:,client,witness)=0;
        T.hashExact=elcsWitnessTraceHash(T);
    otherwise
        error('applyExp23aWitnessCondition: unknown condition %s.', ...
            char(condition.id));
end
meta=struct('blackoutOwner',owner,'blackoutClient',client, ...
    'blackoutWitness',witness,'conditionTraceHash',T.hashExact);

end
