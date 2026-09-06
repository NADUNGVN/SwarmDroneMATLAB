function [net, events] = advanceSharedMedium(net, t0, t1, cfg, trace)
%ADVANCESHAREDMEDIUM Advance the abstract broadcast medium over [t0,t1].
%
% CSMA admits attempts only when the carrier is idle.  Simultaneous starts can
% still collide.  Slotted ALOHA may start frames while other transmissions are
% active.  TDMA assigns one node to each slot.  Collision is receiver-specific:
% two simultaneous broadcasts collide only at intended receivers they share.

if nargin < 5 || isempty(trace)
    trace = generateSharedMediumTrace(cfg);
end

mac = sharedMediumConfig(cfg);
aware = macAwarePolicyConfig(cfg);
tol = 1e-12;

if t1 < t0 - tol
    error('advanceSharedMedium: t1 must not precede t0.');
end
if abs(trace.slotTime-mac.slotTime) > tol
    error('advanceSharedMedium: trace slot time differs from cfg.mac.slotTime.');
end
expectedSignature = sharedMediumChannelSignature(mac,net.N);
if isfield(trace,'modelSignature')
    if trace.modelSignature ~= expectedSignature
        error(['advanceSharedMedium: trace channel-model signature differs ' ...
            'from cfg.mac.']);
    end
elseif mac.separateAckTrace || strcmp(mac.lossModel,'gilbert-elliott')
    error(['advanceSharedMedium: extended channel model requires a trace ' ...
        'with modelSignature.']);
end

events = repmat(net.eventTemplate,0,1);

slot = floor((t0+tol)/mac.slotTime) + 1;
slotStart = (slot-1)*mac.slotTime;

while slotStart < t1 - tol
    nEvent = numel(events);
    [net, events] = completeDue(net, events, slotStart, trace);
    if mac.applyDeliveriesInline && numel(events) > nEvent
        net = applySharedMediumDeliveries( ...
            net, events(nEvent+1:end), slotStart, cfg);
    end
    net = materializeDueAcks(net, slotStart, cfg);
    net = updateServiceStarvation(net,slotStart);

    backgroundActive = false;
    if isfield(trace,'measuredBackgroundActive')
        backgroundActive = logical(trace.measuredBackgroundActive(slot));
    elseif isfield(trace,'backgroundU')
        backgroundActive = trace.backgroundU(slot) < mac.backgroundLoad;
    elseif mac.backgroundLoad > 0
        error(['advanceSharedMedium: trace lacks backgroundU required by ' ...
            'a nonzero backgroundLoad.']);
    end

    [net,candidates] = selectCandidates( ...
        net,slot,slotStart,mac,trace,backgroundActive);
    [net, started] = startCandidates(net, candidates, slotStart, mac);
    net = markCollisions(net, started);
    if backgroundActive
        net = markBackgroundCollisions(net);
        net.stats.backgroundBusyTime = net.stats.backgroundBusyTime ...
            + min(mac.slotTime,t1-slotStart);
    end
    net = updateLocalBusyEstimate(net,backgroundActive,mac,aware);

    if backgroundActive || ~isempty(net.active)
        net.stats.busyTime = net.stats.busyTime ...
            + min(mac.slotTime, t1-slotStart);
    end

    slot = slot + 1;
    slotStart = (slot-1)*mac.slotTime;
end

nEvent = numel(events);
[net, events] = completeDue(net, events, t1, trace);
if mac.applyDeliveriesInline && numel(events) > nEvent
    net = applySharedMediumDeliveries(net, events(nEvent+1:end), t1, cfg);
end

end


function [net,candidates] = selectCandidates( ...
    net,slot,tk,mac,trace,backgroundActive)

N = net.N;
candidates = false(N,1);
hasFrame = false(N,1);
for n = 1:N
    hasFrame(n) = ~isempty(net.queues{n});
end

if ~any(hasFrame)
    return;
end

if slot > trace.K
    error('advanceSharedMedium: trace is shorter than the requested horizon.');
end


if net.serviceScheduler.config.enabled
    [net,candidates]=selectScheduledService( ...
        net,slot,tk,hasFrame,backgroundActive);
    return;
end

switch lower(mac.type)
    case 'tdma'
        if ~isempty(net.active) || backgroundActive
            return;
        end
        n = mod(slot-1,N) + 1;
        candidates(n) = hasFrame(n);

    case 'csma'
        if backgroundActive
            return;
        end
        sensedBusy = false(N,1);
        if ~isempty(net.active)
            activeSenders = arrayfun(@(a) a.frame.sender,net.active);
            sensedBusy = any(mac.carrierSenseMatrix(:,activeSenders),2);
        end
        candidates = hasFrame & ~sensedBusy & ...
            (reshape(trace.accessU(slot,:),[],1) <= mac.pAccess);

    case 'aloha'
        candidates = hasFrame & (reshape(trace.accessU(slot,:),[],1) <= mac.pAccess);
end

end


function net = markBackgroundCollisions(net)

for k = 1:numel(net.active)
    if ~any(net.active(k).frame.receiverMask)
        continue;
    end
    net.active(k).collisionMask(net.active(k).frame.receiverMask) = true;
    net.active(k).backgroundCollision = true;
end

end


function [net, started] = startCandidates(net, candidates, tk, mac)

nodes = find(candidates(:))';
started = zeros(1,numel(nodes));

for k = 1:numel(nodes)
    n = nodes(k);
    q = net.queues{n};
    f = q(1);
    q(1) = [];
    net.queues{n} = q;

    f.attempts = f.attempts + 1;
    durationSlots = max(1,ceil((8*f.bytes/mac.phyRateBps)/mac.slotTime));
    duration = durationSlots*mac.slotTime;

    a = net.activeTemplate;
    a.frame = f;
    a.startTime = tk;
    a.endTime = tk + duration;
    a.collisionMask = false(1,net.N);
    net.active(numel(net.active)+1) = a;
    started(k) = numel(net.active);

    net.stats.framesAttempted = net.stats.framesAttempted + 1;
    net.stats.perNodeFramesAttempted(n) = ...
        net.stats.perNodeFramesAttempted(n) + 1;
    net.logs.accessDelay(end+1,1) = max(tk-f.enqueueTime,0);

    if strcmp(f.type,'data')
        net.stats.dataFramesAttempted = net.stats.dataFramesAttempted + 1;
        net.stats.perNodeDataFramesAttempted(n) = ...
            net.stats.perNodeDataFramesAttempted(n) + 1;
        net.stats.dataAirtime = net.stats.dataAirtime + duration;
        net.stats.ackEntriesPiggybacked = ...
            net.stats.ackEntriesPiggybacked + numel(f.ackEntries);
        piggyBytes = mac.ackEntryBytes*numel(f.ackEntries);
        net.stats.piggybackOverheadAirtime = ...
            net.stats.piggybackOverheadAirtime + 8*piggyBytes/mac.phyRateBps;
    else
        net.stats.ackFramesAttempted = net.stats.ackFramesAttempted + 1;
        net.stats.ackAirtime = net.stats.ackAirtime + duration;
    end
    net.stats.recipientAttempts = net.stats.recipientAttempts + nnz(f.receiverMask);
    net.stats.dataRecipientAttempts = net.stats.dataRecipientAttempts ...
        + nnz(f.dataReceiverMask);
    net.stats.ackRecipientAttempts = net.stats.ackRecipientAttempts ...
        + nnz(f.ackReceiverMask);
end

end


function net = markCollisions(net, started)

if isempty(started)
    return;
end

% New ALOHA frames may overlap transmissions started in earlier slots.  CSMA
% never starts in that situation, but using one pairwise rule keeps semantics
% common across MAC types.
for a = 1:numel(net.active)
    for b = a+1:numel(net.active)
        overlapTime = net.active(a).startTime < net.active(b).endTime ...
            && net.active(b).startTime < net.active(a).endTime;
        if ~overlapTime
            continue;
        end
        fa = net.active(a).frame;
        fb = net.active(b).frame;

        % A receiver intended by frame A is corrupted whenever transmitter B
        % lies in its interference domain, even if B did not intend that same
        % receiver.  This is the fully-conflicting primary model; sparse
        % matrices later express hidden-terminal/OOD cells.
        collideA = fa.receiverMask & ...
            reshape(net.mac.interferenceMatrix(:,fb.sender),1,[]);
        collideB = fb.receiverMask & ...
            reshape(net.mac.interferenceMatrix(:,fa.sender),1,[]);

        net.active(a).collisionMask(collideA) = true;
        net.active(b).collisionMask(collideB) = true;
    end
end

end


function [net, events] = completeDue(net, events, tk, trace)

tol = 1e-12;
due = find(arrayfun(@(a) a.endTime <= tk+tol, net.active));
if isempty(due)
    return;
end

for idx = due(:)'
    a = net.active(idx);
    f = a.frame;
    receivers = find(f.receiverMask);
    anyDataSuccess = false;

    if any(a.collisionMask(f.receiverMask))
        net.stats.collisionFrames = net.stats.collisionFrames + 1;
        net.stats.perNodeCollisionFrames(f.sender) = ...
            net.stats.perNodeCollisionFrames(f.sender) + 1;
    end
    if a.backgroundCollision
        net.stats.backgroundCollisionFrames = ...
            net.stats.backgroundCollisionFrames + 1;
    end

    startSlot = floor((a.startTime+tol)/net.mac.slotTime) + 1;

    for receiver = receivers(:)'
        collision = a.collisionMask(receiver);
        [pLoss,lossDraw,isBadState,channelKind] = channelSample( ...
            net.mac,trace,f,startSlot,receiver,net.N);
        if strcmp(channelKind,'data')
            net.stats.dataChannelRecipientAttempts = ...
                net.stats.dataChannelRecipientAttempts+1;
            if isBadState
                net.stats.dataChannelBadStateAttempts = ...
                    net.stats.dataChannelBadStateAttempts+1;
            end
        else
            net.stats.ackChannelRecipientAttempts = ...
                net.stats.ackChannelRecipientAttempts+1;
            if isBadState
                net.stats.ackChannelBadStateAttempts = ...
                    net.stats.ackChannelBadStateAttempts+1;
            end
        end
        loss = collision;
        if ~collision
            loss = lossDraw < pLoss;
        end

        e = net.eventTemplate;
        e.frameId      = f.id;
        e.frameType    = f.type;
        e.sender       = f.sender;
        e.receiver     = receiver;
        e.seq          = f.seq;
        e.genTime      = f.genTime;
        e.pos          = f.pos;
        e.vel          = f.vel;
        e.acc          = f.acc;
        e.dataIntended = f.dataReceiverMask(receiver);
        e.ackIntended  = f.ackReceiverMask(receiver);
        e.ackEntries   = f.ackEntries;
        e.success      = ~loss;
        e.collision    = collision;
        e.txStart      = a.startTime;
        e.txEnd        = a.endTime;
        e.bytes        = f.bytes;
        events(numel(events)+1)= e;

        if loss
            net.stats.recipientLoss = net.stats.recipientLoss + 1;
            if e.dataIntended
                net.stats.dataRecipientLoss = ...
                    net.stats.dataRecipientLoss + 1;
            end
            if e.ackIntended
                net.stats.ackRecipientLoss = ...
                    net.stats.ackRecipientLoss + 1;
            end
        else
            net.stats.recipientSuccess = net.stats.recipientSuccess + 1;
            if e.dataIntended
                net.stats.dataRecipientSuccess = ...
                    net.stats.dataRecipientSuccess + 1;
                net.stats.perNodeDataRecipientSuccess(f.sender) = ...
                    net.stats.perNodeDataRecipientSuccess(f.sender) + 1;
                net.logs.dataOneWayDelay(end+1,1) = ...
                    max(a.endTime-f.genTime,0);
            end
            if e.ackIntended
                net.stats.ackRecipientSuccess = ...
                    net.stats.ackRecipientSuccess + 1;
            end
            anyDataSuccess = anyDataSuccess || e.dataIntended;
        end
    end

    if strcmp(f.type,'data') && anyDataSuccess && ...
            ~any(net.logs.deliveredDataFrameIds == f.id)
        net.stats.dataFramesDeliveredAny = net.stats.dataFramesDeliveredAny + 1;
        net.stats.perNodeDataFramesDeliveredAny(f.sender) = ...
            net.stats.perNodeDataFramesDeliveredAny(f.sender) + 1;
        net.logs.deliveredDataFrameIds(end+1,1) = f.id;
        net = recordServiceCompletion(net,f.sender,a.endTime);
    end

    % Optional collision retry.  It retains the original frame id and
    % enqueue time.  Latest-generated-wins admission prevents an obsolete
    % retry from replacing a newer sender state.
    if strcmp(f.type,'data') && ...
            any(a.collisionMask(f.receiverMask)) && ...
            f.attempts <= net.mac.maxRetries
        [net, retried] = sharedMediumAdmitFrame(net,f.sender,f);
        if retried
            net.stats.retryFrames = net.stats.retryFrames + 1;
        end
    end
end

net.active(due) = [];

end


function net = materializeDueAcks(net, tk, cfg)

mac = sharedMediumConfig(cfg);
mode = sharedMediumFeedbackMode(cfg);
policy = macAwarePolicyConfig(cfg);
if ~any(strcmp(mode,{'standalone','hybrid','adaptive'}))
    return;
end

for node = 1:net.N
    if isempty(net.pendingAck{node}) || net.pendingAckDue(node) > tk + 1e-12
        continue;
    end

    decision=struct('forced',false,'pendingAge',NaN,'localBusy',NaN);
    if strcmp(mode,'adaptive')
        [allow,nextDue,decision] = adaptiveStandaloneAckDecision( ...
            net,node,tk,cfg);
        isContext=isfield(decision,'contextDecision') && ...
            decision.contextDecision && ...
            isfield(decision,'evaluated') && decision.evaluated;
        if isContext
            net.stats.contextAckEvaluated = ...
                net.stats.contextAckEvaluated + 1;
            if ~decision.feasible
                net.stats.contextAckBlockedFeasibility = ...
                    net.stats.contextAckBlockedFeasibility + 1;
            elseif ~decision.valuePositive
                net.stats.contextAckBlockedValue = ...
                    net.stats.contextAckBlockedValue + 1;
            elseif allow
                net.stats.contextAckPermitted = ...
                    net.stats.contextAckPermitted + 1;
            end
        end
        if ~allow
            net.pendingAckDue(node)=nextDue;
            net.stats.adaptiveAckDeferred = ...
                net.stats.adaptiveAckDeferred + 1;
            continue;
        end
        replay=net.ackBranchReplay;
        if replay.enabled
            net.ackBranchState.candidateOrdinal = ...
                net.ackBranchState.candidateOrdinal + 1;
            ordinal=net.ackBranchState.candidateOrdinal;
            preNetworkHash=ackBranchNetworkHash(net);
            preContextHash=net.ackBranchState.contextHash;
            isTarget=any(strcmp(replay.mode, ...
                {'admit-target','suppress-target'})) && ...
                ordinal==replay.targetOrdinal;
        else
            ordinal=0; preNetworkHash=0; preContextHash=0; isTarget=false;
        end
        net.stats.adaptiveAckPermitted = ...
            net.stats.adaptiveAckPermitted + 1;
        if decision.forced
            net.stats.adaptiveAckForced = ...
                net.stats.adaptiveAckForced + 1;
        end
    end

    entries = net.pendingAck{node};
    decisionEntries=entries;
    suppressed=entries([]);
    intervention='none';
    if strcmp(mode,'adaptive') && net.ackBranchReplay.enabled
        if isTarget
            net.ackBranchState.targetReached=true;
            net.ackBranchState.targetTime=tk;
            net.ackBranchState.targetEntries=entries;
            if strcmp(net.ackBranchReplay.mode,'suppress-target')
                net.ackBranchState.interventionActive=true;
                intervention='suppress-target';
            else
                intervention='admit-target';
            end
        end
        net=updateAckBranchResolution(net,tk);
        if net.ackBranchState.interventionActive
            [entries,suppressed]=splitProtectedEntries( ...
                entries,net.ackBranchState.targetEntries,net);
            net.ackBranchState.suppressedEntryCount = ...
                net.ackBranchState.suppressedEntryCount + numel(suppressed);
            if ~isempty(suppressed) && strcmp(intervention,'none')
                intervention='suppress-active';
            end
        end
    end

    q = net.queues{node};
    ackIdx = find(strcmp({q.type},'ack'),1,'last');

    if isempty(entries)
        admitted=false;
    elseif ~isempty(ackIdx)
        f = q(ackIdx);
        f.ackEntries = mergeSharedMediumAckEntries( ...
            f.ackEntries, entries, node, net.N);
        f.ackReceiverMask = maskFromEntries(f.ackEntries,net.N);
        f.receiverMask = f.ackReceiverMask;
        f.bytes = mac.ackBaseBytes + mac.ackEntryBytes*numel(f.ackEntries);
        q(ackIdx) = f;
        net.queues{node} = q;
        admitted = true;
    else
        f = net.frameTemplate;
        f.id          = net.nextFrameId;
        f.type        = 'ack';
        f.sender      = node;
        f.ackEntries  = entries;
        f.ackReceiverMask = maskFromEntries(entries,net.N);
        f.receiverMask    = f.ackReceiverMask;
        f.bytes       = mac.ackBaseBytes + mac.ackEntryBytes*numel(entries);
        f.enqueueTime = tk;
        [net, admitted] = sharedMediumAdmitFrame(net,node,f);
        if admitted
            net.nextFrameId = net.nextFrameId + 1;
            net.stats.ackFramesStandalone = net.stats.ackFramesStandalone + 1;
        end
    end

    if admitted
        net.pendingAck{node} = suppressed;
        if isempty(suppressed)
            net.pendingAckDue(node) = inf;
            net.pendingAckSince(node) = inf;
        else
            net.pendingAckDue(node) = tk + ...
                policy.ackRecheckInterval;
        end
    else
        if ~isempty(suppressed)
            net.pendingAck{node}=mergeSharedMediumAckEntries( ...
                entries,suppressed,node,net.N);
            net.pendingAckDue(node)=tk+policy.ackRecheckInterval;
        else
            net.pendingAckDue(node) = tk + mac.slotTime;
        end
    end

    if strcmp(mode,'adaptive') && net.ackBranchReplay.enabled
        logEvent=struct( ...
            'candidateOrdinal',ordinal, ...
            'time',tk, ...
            'node',node, ...
            'nEntries',numel(decisionEntries), ...
            'targetSenders',[decisionEntries.targetSender], ...
            'seqs',[decisionEntries.seq], ...
            'genTimes',[decisionEntries.genTime], ...
            'pendingAge',decision.pendingAge, ...
            'localBusy',decision.localBusy, ...
            'forced',logical(decision.forced), ...
            'queueDepth',numel(q), ...
            'preNetworkHash',preNetworkHash, ...
            'preContextHash',preContextHash, ...
            'policyAllowed',true, ...
            'physicalAdmitted',logical(admitted), ...
            'isTarget',logical(isTarget), ...
            'intervention',intervention, ...
            'suppressedEntries',numel(suppressed));
        net.logs.ackAdmissionEvents(end+1,1)=logEvent;
    end
end

end


function net=updateAckBranchResolution(net,tk)

if ~net.ackBranchState.interventionActive
    return;
end
target=net.ackBranchState.targetEntries;
crossed=true;
for k=1:numel(target)
    crossed=crossed && net.ackedGenTime( ...
        target(k).sourceReceiver,target(k).targetSender) >= ...
        target(k).genTime-1e-12;
end
if crossed
    net.ackBranchState.interventionActive=false;
    net.ackBranchState.resolvedByPiggyback=true;
    net.ackBranchState.resolvedTime=tk;
elseif tk>=net.ackBranchState.targetTime+ ...
        net.ackBranchReplay.localHorizon-1e-12
    net.ackBranchState.interventionActive=false;
    net.ackBranchState.expired=true;
    net.ackBranchState.resolvedTime=tk;
end

end


function [allowed,protected]=splitProtectedEntries(entries,target,net)

keep=true(size(entries));
for k=1:numel(entries)
    for q=1:numel(target)
        sameLink=entries(k).sourceReceiver==target(q).sourceReceiver && ...
            entries(k).targetSender==target(q).targetSender;
        unresolved=net.ackedGenTime(target(q).sourceReceiver, ...
            target(q).targetSender)<target(q).genTime-1e-12;
        if sameLink && unresolved
            keep(k)=false;
            break;
        end
    end
end
allowed=entries(keep);
protected=entries(~keep);

end


function h=ackBranchNetworkHash(net)

snapshot=net;
remove={'logs','ackBranchReplay','ackBranchState'};
for k=1:numel(remove)
    if isfield(snapshot,remove{k}), snapshot=rmfield(snapshot,remove{k}); end
end
h=configHash(snapshot);

end


function net = updateLocalBusyEstimate(net,backgroundActive,mac,aware)

observed=repmat(logical(backgroundActive),net.N,1);
if ~isempty(net.active)
    activeSenders=arrayfun(@(a) a.frame.sender,net.active);
    observed=observed | any(mac.carrierSenseMatrix(:,activeSenders),2);
end
beta=1-exp(-mac.slotTime/aware.busyWindow);
net.localBusyEWMA=(1-beta)*net.localBusyEWMA+beta*double(observed);

end


function mask = maskFromEntries(entries,N)

mask = false(1,N);
if ~isempty(entries)
    mask(unique([entries.targetSender])) = true;
end

end


function [p,draw,isBad,kind] = channelSample( ...
    mac,trace,frame,slot,receiver,N)

sender = frame.sender;
if strcmp(frame.type,'ack')
    kind = 'ack';
    draw = trace.ackLossU(slot,receiver,sender);
    if isfield(trace,'measuredAckLossProbability')
        p = trace.measuredAckLossProbability(slot,receiver,sender);
        isBad = trace.ackBadState(slot,receiver,sender);
        return;
    end
    iidLoss = valueAt(mac.ackResidualLoss,receiver,sender,N);
    if strcmp(mac.lossModel,'gilbert-elliott')
        isBad = trace.ackBadState(slot,receiver,sender);
        if isBad
            p = valueAt(mac.burst.ackBadLoss,receiver,sender,N);
        else
            p = valueAt(mac.burst.ackGoodLoss,receiver,sender,N);
        end
    else
        isBad = false;
        p = iidLoss;
    end
else
    % ACK entries piggybacked in DATA experience the DATA frame's physical
    % channel, not the standalone reverse-ACK loss process.
    kind = 'data';
    draw = trace.lossU(slot,receiver,sender);
    if isfield(trace,'measuredDataLossProbability')
        p = trace.measuredDataLossProbability(slot,receiver,sender);
        isBad = trace.dataBadState(slot,receiver,sender);
        return;
    end
    iidLoss = valueAt(mac.dataResidualLoss,receiver,sender,N);
    if strcmp(mac.lossModel,'gilbert-elliott')
        isBad = trace.dataBadState(slot,receiver,sender);
        if isBad
            p = valueAt(mac.burst.dataBadLoss,receiver,sender,N);
        else
            p = valueAt(mac.burst.dataGoodLoss,receiver,sender,N);
        end
    else
        isBad = false;
        p = iidLoss;
    end
end

end


function value = valueAt(x,receiver,sender,N)

if isscalar(x)
    value = x;
elseif isequal(size(x),[N N])
    value = x(receiver,sender);
else
    error('advanceSharedMedium: channel probability map has invalid shape.');
end

end
