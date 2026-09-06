function Q=bindReplayDataOutcomes(Q,neighborGraph,interferenceMatrix)
%BINDREPLAYDATAOUTCOMES Bind scheduled DATA to controller recipients.
%
% The timing kernel determines which nodes share a logical DATA group.  This
% function independently reconstructs the receiver mask, half-duplex
% exclusions and receiver-level collision outcome used by the shared-medium
% simulator.  IID loss may be overlaid afterwards with
% applySharedDataLossToReplaySchedule.

required={'dataStartTime','dataNode','dataFrame','dataSuccessMask', ...
    'dataErasureMask','dataCollisionMask','dataCompletesByHorizon', ...
    'logicalOpportunityHashExact','hashExact'};
if ~isstruct(Q) || ~isscalar(Q) || ~all(isfield(Q,required))
    error('bindReplayDataOutcomes: invalid replay schedule.');
end
N=size(Q.dataSuccessMask,2); E=numel(Q.dataStartTime);
staticInterference=isequal(size(interferenceMatrix),[N N]);
dynamicInterference=ndims(interferenceMatrix)==3 && ...
    size(interferenceMatrix,2)==N && size(interferenceMatrix,3)==N && ...
    size(interferenceMatrix,1)>=max([0;Q.dataFrame(:)]);
if ~isequal(size(neighborGraph),[N N]) || ...
        ~(staticInterference || dynamicInterference) || ...
        ~isequal(size(Q.dataSuccessMask),[E N]) || ...
        ~isequal(size(Q.dataErasureMask),[E N]) || ...
        ~isequal(size(Q.dataCollisionMask),[E N])
    error('bindReplayDataOutcomes: dimension mismatch.');
end
neighbor=logical(neighborGraph);
neighbor(1:N+1:end)=false;
interference=logical(interferenceMatrix);
if staticInterference
    interference(1:N+1:end)=false;
else
    for frame=1:size(interference,1)
        layer=reshape(interference(frame,:,:),N,N);
        layer(1:N+1:end)=false;
        interference(frame,:,:)=layer;
    end
end
if ~isfield(Q,'dataGroup') || numel(Q.dataGroup)~=E
    error('bindReplayDataOutcomes: logical DATA groups are required.');
end

success=false(E,N); erasure=false(E,N); collision=false(E,N);
groups=unique(Q.dataGroup,'stable');
for group=reshape(groups,1,[])
    rows=find(Q.dataGroup==group);
    tx=reshape(Q.dataNode(rows),1,[]);
    if numel(unique(tx))~=numel(tx)
        error('bindReplayDataOutcomes: duplicate sender in one group.');
    end
    txMask=false(N,1); txMask(tx)=true;
    for q=1:numel(rows)
        index=rows(q); sender=Q.dataNode(index);
        receivers=neighbor(:,sender) & ~txMask;
        peers=tx(tx~=sender);
        hit=false(N,1);
        if ~isempty(peers)
            if staticInterference
                layer=interference;
            else
                layer=reshape(interference(Q.dataFrame(index),:,:),N,N);
            end
            hit(receivers)=any(layer(receivers,peers),2);
        end
        collision(index,:)=reshape(receivers & hit,1,[]);
        success(index,:)=reshape(receivers & ~hit,1,[]);
    end
end
partition=double(success)+double(erasure)+double(collision);
if any(partition(:)>1)
    error('bindReplayDataOutcomes: outcome partition fails.');
end

Q.dataSuccessMask=success;
Q.dataErasureMask=erasure;
Q.dataCollisionMask=collision;
Q.expectedDataCollisionFrames=nnz(any(collision,2));
Q.expectedDataRecipientSuccess=nnz(success);
Q.expectedDataRecipientErasure=0;
Q.expectedDataRecipientCollision=nnz(collision);
complete=logical(Q.dataCompletesByHorizon(:));
Q.expectedCompletedDataCollisionFrames= ...
    nnz(any(collision(complete,:),2));
Q.expectedCompletedDataRecipientSuccess=nnz(success(complete,:));
Q.expectedCompletedDataRecipientErasure=0;
Q.expectedCompletedDataRecipientCollision=nnz(collision(complete,:));
Q.dataOutcomeBinding=struct('version','REPLAY-DATA-OUTCOME-BINDING-v1', ...
    'neighborGraphHashExact',realizationHash(double(neighbor(:))), ...
    'interferenceGraphHashExact', ...
        realizationHash(double(interference(:))), ...
    'recipientAttempts',nnz(success | collision), ...
    'recipientSuccess',nnz(success), ...
    'recipientCollision',nnz(collision));
Q.logicalOpportunityHashExact=realizationHash([ ...
    Q.logicalOpportunityHashExact;double(success(:));double(collision(:))]);
Q.hashExact=realizationHash([Q.hashExact;double(success(:)); ...
    double(collision(:));Q.dataOutcomeBinding.neighborGraphHashExact; ...
    Q.dataOutcomeBinding.interferenceGraphHashExact]);

end
