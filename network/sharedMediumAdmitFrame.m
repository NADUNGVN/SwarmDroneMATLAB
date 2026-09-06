function [net, admitted] = sharedMediumAdmitFrame(net, node, frame)
%SHAREDMEDIUMADMITFRAME Apply the bounded node-queue admission policy.
%
% State DATA is latest-generated-wins before service.  A due standalone ACK
% has priority over queued DATA, because otherwise congestion can permanently
% prevent the causal sender belief from advancing.

q = net.queues{node};

if strcmp(frame.type,'data')
    oldData = find(strcmp({q.type},'data'));
    isUnicast = isfield(frame,'dataMode') && ...
        strcmp(frame.dataMode,'unicast');
    if isUnicast && ~isempty(oldData)
        overlaps = arrayfun(@(f) ...
            any(f.dataReceiverMask & frame.dataReceiverMask),q(oldData));
        oldData = oldData(overlaps);
    end
    if ~isempty(oldData)
        % A collision retry must never displace a newer state update that was
        % generated while the older frame was in service.  Its cumulative ACK
        % obligations still move to that newer frame; dropping the payload
        % must not silently turn already-earned receiver feedback into loss.
        if frame.attempts > 0 && max([q(oldData).seq]) >= frame.seq
            [~,newestLocal] = max([q(oldData).seq]);
            newest = oldData(newestLocal);
            [q(newest),nMoved] = transferAckEntries( ...
                q(newest),frame.ackEntries,node,net);
            net.stats.ackEntriesTransferred = ...
                net.stats.ackEntriesTransferred + nMoved;
            net.queues{node} = q;
            net.stats.obsoleteRetryDrops = ...
                net.stats.obsoleteRetryDrops + 1;
            admitted = false;
            return;
        end
        for k = oldData(:)'
            [frame,nMoved] = transferAckEntries( ...
                frame,q(k).ackEntries,node,net);
            net.stats.ackEntriesTransferred = ...
                net.stats.ackEntriesTransferred + nMoved;
        end
        net.stats.supersededBeforeService = ...
            net.stats.supersededBeforeService + numel(oldData);
        q(oldData) = [];
    end
end

if numel(q) >= net.mac.queueCapacity
    if strcmp(frame.type,'ack')
        oldData = find(strcmp({q.type},'data'),1,'first');
        if ~isempty(oldData)
            [frame,nMoved] = transferAckEntries( ...
                frame,q(oldData).ackEntries,node,net);
            net.stats.ackEntriesTransferred = ...
                net.stats.ackEntriesTransferred + nMoved;
            q(oldData) = [];
            net.stats.queueDrops = net.stats.queueDrops + 1;
        else
            net.stats.queueDrops = net.stats.queueDrops + 1;
            net.queues{node} = q;
            admitted = false;
            return;
        end
    else
        net.stats.queueDrops = net.stats.queueDrops + 1;
        net.queues{node} = q;
        admitted = false;
        return;
    end
end


function [frame,nMoved] = transferAckEntries(frame,entries,node,net)

nMoved = numel(entries);
if nMoved == 0
    return;
end

frame.ackEntries = mergeSharedMediumAckEntries( ...
    frame.ackEntries,entries,node,net.N);
frame.ackReceiverMask = false(1,net.N);
frame.ackReceiverMask(unique([frame.ackEntries.targetSender])) = true;
frame.receiverMask = frame.dataReceiverMask | frame.ackReceiverMask;

if strcmp(frame.type,'data')
    frame.bytes = net.mac.dataBytes + ...
        net.mac.ackEntryBytes*numel(frame.ackEntries);
else
    frame.bytes = net.mac.ackBaseBytes + ...
        net.mac.ackEntryBytes*numel(frame.ackEntries);
end

end

q(numel(q)+1) = frame;
net.queues{node} = q;
net.stats.maxQueueDepth = max(net.stats.maxQueueDepth, numel(q));
admitted = true;

end
