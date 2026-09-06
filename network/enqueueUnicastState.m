function [net, admittedCount, seq] = enqueueUnicastState( ...
    net, sender, pos, vel, tk, cfg, acc)
%ENQUEUEUNICASTSTATE Enqueue one physical DATA frame per out-neighbour.
%
% This Study-2 ablation preserves one logical generation/sequence while
% materializing separate receiver masks.  It isolates the physical DATA cost
% of unicast from the causal trigger; it is not a bit-level reproduction of
% the frozen Study-1 link simulator.

if nargin < 7 || isempty(acc)
    acc = nan(1,3);
end
mac = sharedMediumConfig(cfg);

if sender < 1 || sender > net.N || sender ~= floor(sender)
    error('enqueueUnicastState: sender is out of range.');
end
if numel(pos) ~= 3 || numel(vel) ~= 3 || numel(acc) ~= 3
    error(['enqueueUnicastState: pos, vel and optional acc must each ' ...
        'have three elements.']);
end

receivers = find(net.topology(:,sender));
seq = net.lastBroadcastSeq(sender)+1;
admittedCount = 0;

for receiver = receivers(:)'
    net.stats.dataFramesGenerated = net.stats.dataFramesGenerated+1;

    f = net.frameTemplate;
    f.id = net.nextFrameId;
    f.type = 'data';
    f.dataMode = 'unicast';
    f.sender = sender;
    f.seq = seq;
    f.genTime = tk;
    f.pos = reshape(pos,1,3);
    f.vel = reshape(vel,1,3);
    f.acc = reshape(acc,1,3);
    f.dataReceiverMask(receiver) = true;
    f.receiverMask = f.dataReceiverMask;
    f.bytes = mac.dataBytes;
    f.enqueueTime = tk;

    [net,admitted] = sharedMediumAdmitFrame(net,sender,f);
    if admitted
        admittedCount = admittedCount+1;
        net.nextFrameId = net.nextFrameId+1;
    end
end

if admittedCount == 0
    seq = 0;
    return;
end

net.lastBroadcastSeq(sender) = seq;
net.lastBroadcastGenTime(sender) = tk;

W = mac.historySize;
h = mod(net.historyHead(sender),W)+1;
net.historyHead(sender) = h;
net.historySeq(sender,h) = seq;
net.historyGenTime(sender,h) = tk;
net.historyCount(sender) = min(net.historyCount(sender)+1,W);
net.stats.maxHistoryDepth = max( ...
    net.stats.maxHistoryDepth,net.historyCount(sender));

end
