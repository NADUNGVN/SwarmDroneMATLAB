function net = enqueueAckSummary(net, receiver, ackEntries, tk, cfg)
%ENQUEUEACKSUMMARY Merge causal cumulative feedback for later transmission.
%
% Pending entries are piggybacked immediately when an unsent DATA frame exists.
% Otherwise advanceSharedMedium materializes one standalone summary at the ACK
% deadline.  Silence is never interpreted as successful delivery.

if nargin < 5 || isempty(cfg)
    mac = net.mac;
    cfg = struct('shared',struct('feedbackMode','hybrid'));
else
    mac = sharedMediumConfig(cfg);
end

if receiver < 1 || receiver > net.N || receiver ~= floor(receiver)
    error('enqueueAckSummary: receiver is out of range.');
end
if isempty(ackEntries)
    return;
end

mode = sharedMediumFeedbackMode(cfg);
if strcmp(mode,'none')
    return;
end

wasEmpty = isempty(net.pendingAck{receiver});
pending = mergeSharedMediumAckEntries( ...
    net.pendingAck{receiver}, ackEntries, receiver, net.N);
if wasEmpty || ~isfinite(net.pendingAckSince(receiver))
    net.pendingAckSince(receiver) = tk;
end

q = net.queues{receiver};
dataIdx = [];
if any(strcmp(mode,{'piggyback','hybrid','adaptive'}))
    dataIdx = find(strcmp({q.type},'data'),1,'last');
end

if ~isempty(dataIdx)
    f = q(dataIdx);
    f.ackEntries = mergeSharedMediumAckEntries( ...
        f.ackEntries, pending, receiver, net.N);
    f.ackReceiverMask = ackMask(f.ackEntries, net.N);
    f.receiverMask = f.dataReceiverMask | f.ackReceiverMask;
    f.bytes = mac.dataBytes + mac.ackEntryBytes*numel(f.ackEntries);
    q(dataIdx) = f;
    net.queues{receiver} = q;
    net.pendingAck{receiver} = pending([]);
    net.pendingAckDue(receiver) = inf;
    net.pendingAckSince(receiver) = inf;
else
    net.pendingAck{receiver} = pending;
    if any(strcmp(mode,{'standalone','hybrid'}))
        net.pendingAckDue(receiver) = min( ...
            net.pendingAckDue(receiver), tk + mac.ackDeadline);
    elseif strcmp(mode,'adaptive')
        policy = macAwarePolicyConfig(cfg);
        if strcmpi(mac.type,'aloha')
            delay = policy.alohaMinAckDelay;
        else
            delay = policy.csmaMinAckDelay;
        end
        net.pendingAckDue(receiver) = min( ...
            net.pendingAckDue(receiver), ...
            net.pendingAckSince(receiver) + delay);
    else
        net.pendingAckDue(receiver) = inf;
    end
end

end


function mask = ackMask(entries, N)

mask = false(1,N);
if ~isempty(entries)
    mask(unique([entries.targetSender])) = true;
end

end
