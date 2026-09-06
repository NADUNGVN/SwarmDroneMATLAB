function Q=applySharedDataLossToReplaySchedule(Q,trace,pLoss)
%APPLYSHAREDDATALOSSTOREPLAYSCHEDULE Overlay an absolute link-time trace.
%
% Only entries previously classified as successful are eligible for IID
% erasure. Existing collision outcomes remain collisions. This lets replay
% schedules and ordinary MAC arms consume the same absolute shared-medium
% random field without reading future outcomes during a protocol decision.

requiredQ={'dataStartTime','dataNode','dataSuccessMask', ...
    'dataErasureMask','dataCollisionMask','logicalOpportunityHashExact', ...
    'hashExact'};
requiredT={'dataLossU','slotTime','hashExact'};
if ~isstruct(Q) || ~isscalar(Q) || ~all(isfield(Q,requiredQ))
    error('applySharedDataLossToReplaySchedule: invalid replay schedule.');
end
if ~isstruct(trace) || ~isscalar(trace) || ~all(isfield(trace,requiredT))
    error('applySharedDataLossToReplaySchedule: invalid shared trace.');
end
if ~isscalar(pLoss) || ~isfinite(pLoss) || pLoss<0 || pLoss>1
    error('applySharedDataLossToReplaySchedule: invalid loss probability.');
end
E=numel(Q.dataStartTime);
N=size(Q.dataSuccessMask,2);
if ~isequal(size(Q.dataSuccessMask),[E N]) || ...
        ~isequal(size(Q.dataErasureMask),[E N]) || ...
        ~isequal(size(Q.dataCollisionMask),[E N]) || ...
        size(trace.dataLossU,2)~=N || size(trace.dataLossU,3)~=N
    error('applySharedDataLossToReplaySchedule: dimension mismatch.');
end

newErasure=false(E,N);
for index=1:E
    sender=Q.dataNode(index);
    slot=floor((Q.dataStartTime(index)+1e-12)/trace.slotTime)+1;
    if slot<1 || slot>size(trace.dataLossU,1)
        error('applySharedDataLossToReplaySchedule: event leaves trace.');
    end
    eligible=Q.dataSuccessMask(index,:);
    draws=reshape(trace.dataLossU(slot,:,sender),1,[]);
    newErasure(index,:)=eligible & draws<pLoss;
end
Q.dataSuccessMask=Q.dataSuccessMask & ~newErasure;
Q.dataErasureMask=Q.dataErasureMask | newErasure;
partition=double(Q.dataSuccessMask)+double(Q.dataErasureMask)+ ...
    double(Q.dataCollisionMask);
if any(partition(:)>1)
    error('applySharedDataLossToReplaySchedule: outcome partition fails.');
end
Q.expectedDataCollisionFrames=nnz(any(Q.dataCollisionMask,2));
Q.expectedDataRecipientSuccess=nnz(Q.dataSuccessMask);
Q.expectedDataRecipientErasure=nnz(Q.dataErasureMask);
Q.expectedDataRecipientCollision=nnz(Q.dataCollisionMask);
Q.expectedCompletedDataCollisionFrames=Q.expectedDataCollisionFrames;
Q.expectedCompletedDataRecipientSuccess=Q.expectedDataRecipientSuccess;
Q.expectedCompletedDataRecipientErasure=Q.expectedDataRecipientErasure;
Q.expectedCompletedDataRecipientCollision=Q.expectedDataRecipientCollision;
Q.dataLossOverlayApplied=1;
Q.dataLossOverlayProbability=pLoss;
Q.dataLossOverlayTraceHashExact=trace.hashExact;
Q.dataLossOverlayErasureCount=nnz(newErasure);
Q.logicalOpportunityHashExact=realizationHash([ ...
    Q.logicalOpportunityHashExact;trace.hashExact;pLoss; ...
    double(Q.dataSuccessMask(:));double(Q.dataErasureMask(:)); ...
    double(Q.dataCollisionMask(:))]);
Q.hashExact=realizationHash([Q.hashExact;trace.hashExact;pLoss; ...
    double(newErasure(:));double(Q.dataSuccessMask(:)); ...
    double(Q.dataErasureMask(:));double(Q.dataCollisionMask(:))]);

end
