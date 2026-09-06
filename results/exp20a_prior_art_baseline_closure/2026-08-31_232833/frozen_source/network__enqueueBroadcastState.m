function [net, admitted, seq] = enqueueBroadcastState( ...
    net, sender, pos, vel, tk, cfg, acc)
%ENQUEUEBROADCASTSTATE Enqueue one sender state frame for all out-neighbours.

if nargin < 7 || isempty(acc)
    acc = nan(1,3);
end
if nargin < 6 || isempty(cfg)
    mac = net.mac;
    cfg = struct('shared',struct('feedbackMode','hybrid'));
else
    mac = sharedMediumConfig(cfg);
end

if sender < 1 || sender > net.N || sender ~= floor(sender)
    error('enqueueBroadcastState: sender is out of range.');
end
if numel(pos) ~= 3 || numel(vel) ~= 3 || numel(acc) ~= 3
    error(['enqueueBroadcastState: pos, vel and optional acc must each ' ...
        'have three elements.']);
end

net.stats.dataFramesGenerated = net.stats.dataFramesGenerated + 1;

seq = net.lastBroadcastSeq(sender) + 1;
mode = sharedMediumFeedbackMode(cfg);
if any(strcmp(mode,{'piggyback','hybrid','adaptive'}))
    entries = net.pendingAck{sender};
else
    entries = net.pendingAck{sender}([]);
end

f = net.frameTemplate;
f.id          = net.nextFrameId;
f.type        = 'data';
f.dataMode    = 'broadcast';
f.sender      = sender;
f.seq         = seq;
f.genTime     = tk;
f.pos         = reshape(pos,1,3);
f.vel         = reshape(vel,1,3);
f.acc         = reshape(acc,1,3);
f.dataReceiverMask = reshape(net.topology(:,sender),1,[]);
f.ackEntries       = entries;
f.ackReceiverMask  = false(1,net.N);
if ~isempty(entries)
    f.ackReceiverMask(unique([entries.targetSender])) = true;
end
f.receiverMask = f.dataReceiverMask | f.ackReceiverMask;
f.bytes       = mac.dataBytes + mac.ackEntryBytes*numel(entries);
f.enqueueTime = tk;

[net, admitted] = sharedMediumAdmitFrame(net, sender, f);

if ~admitted
    seq = 0;
    return;
end

net = recordServiceAdmission(net,sender,tk);

net.nextFrameId = net.nextFrameId + 1;
net.lastBroadcastSeq(sender)     = seq;
net.lastBroadcastGenTime(sender) = tk;

W = mac.historySize;
h = mod(net.historyHead(sender),W) + 1;
net.historyHead(sender)       = h;
net.historySeq(sender,h)      = seq;
net.historyGenTime(sender,h)  = tk;
net.historyCount(sender)      = min(net.historyCount(sender)+1,W);
net.stats.maxHistoryDepth = max( ...
    net.stats.maxHistoryDepth, net.historyCount(sender));

if ~isempty(entries)
    net.pendingAck{sender} = entries([]);
    net.pendingAckDue(sender) = inf;
    net.pendingAckSince(sender) = inf;
end

end
