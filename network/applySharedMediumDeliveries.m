function net = applySharedMediumDeliveries(net, events, tk, cfg)
%APPLYSHAREDMEDIUMDELIVERIES Apply DATA reception and causal ACK feedback.

tol = 1e-12;

feedbackEnabled = ~strcmp(sharedMediumFeedbackMode(cfg),'none');

for k = 1:numel(events)
    e = events(k);
    if ~e.success
        continue;
    end

    if e.dataIntended
        i = e.receiver;
        j = e.sender;

        if e.genTime > tk + tol
            net.stats.futureGenTimeCount = net.stats.futureGenTimeCount + 1;
        elseif e.seq > net.acceptedSeq(i,j)
            net.acceptedSeq(i,j)     = e.seq;
            net.acceptedGenTime(i,j) = e.genTime;

            % Publish exactly the payload that crossed the medium.  The local
            % formation controller never reads channel loss/collision truth;
            % it only sees this cache after a successful, newest-generation
            % reception.
            if isfield(net,'Pij')
                net.Pij(i,j,:) = reshape(e.pos,1,1,3);
                net.Vij(i,j,:) = reshape(e.vel,1,1,3);
            end
            if j == 1 && isfield(cfg.swarm,'pin') && cfg.swarm.pin(i)
                net.leaderPos(i,:) = reshape(e.pos,1,3);
                net.leaderVel(i,:) = reshape(e.vel,1,3);
                if all(isfinite(e.acc))
                    net.leaderAcc(i,:) = reshape(e.acc,1,3);
                end
            end

            if feedbackEnabled
                ack = struct( ...
                    'sourceReceiver', i, ...
                    'targetSender',   j, ...
                    'seq',            e.seq, ...
                    'genTime',        e.genTime);
                net = enqueueAckSummary(net,i,ack,tk,cfg);
            end
        else
            net.stats.staleDataDiscarded = net.stats.staleDataDiscarded + 1;
        end
    end

    if e.ackIntended && ~isempty(e.ackEntries)
        target = e.receiver;
        entries = e.ackEntries([e.ackEntries.targetSender] == target);

        for q = 1:numel(entries)
            a = entries(q);
            source = a.sourceReceiver;

            if a.seq > net.lastBroadcastSeq(target)
                net.stats.unknownSeqAckCount = net.stats.unknownSeqAckCount + 1;
                continue;
            end
            if a.genTime > tk + tol
                net.stats.futureGenTimeCount = net.stats.futureGenTimeCount + 1;
                continue;
            end
            if a.seq > net.acceptedSeq(source,target) || ...
                    a.genTime > net.acceptedGenTime(source,target) + tol
                net.stats.ackBeforeAcceptCount = ...
                    net.stats.ackBeforeAcceptCount + 1;
                continue;
            end
            if a.seq <= net.ackedSeq(source,target)
                net.stats.staleAckDiscarded = net.stats.staleAckDiscarded + 1;
                continue;
            end
            if a.genTime + tol < net.ackedGenTime(source,target)
                net.stats.senderRollbackCount = net.stats.senderRollbackCount + 1;
                continue;
            end

            idx = find(net.historySeq(target,:) == a.seq,1);
            if isempty(idx)
                net.stats.expiredHistoryAckCount = ...
                    net.stats.expiredHistoryAckCount + 1;
                continue;
            elseif abs(net.historyGenTime(target,idx)-a.genTime) > tol
                net.stats.seqGenTimeMismatchCount = ...
                    net.stats.seqGenTimeMismatchCount + 1;
                continue;
            end

            net.ackedSeq(source,target)     = a.seq;
            net.ackedGenTime(source,target) = a.genTime;
            net.stats.ackEntriesDelivered = net.stats.ackEntriesDelivered + 1;
            net.logs.confirmationDelay(end+1,1) = max(tk-a.genTime,0);
            if net.ackValueLogging.enabled
                event=struct( ...
                    'time',tk, ...
                    'sourceReceiver',source, ...
                    'targetSender',target, ...
                    'seq',a.seq, ...
                    'genTime',a.genTime, ...
                    'transport',e.frameType, ...
                    'frameId',e.frameId, ...
                    'frameSender',e.sender, ...
                    'txStart',e.txStart, ...
                    'txEnd',e.txEnd, ...
                    'bytes',e.bytes);
                net.logs.confirmationEvents(end+1,1)=event;
            end
        end
    end
end

active = net.topology;
if any(net.ackedGenTime(active) > net.acceptedGenTime(active) + tol)
    net.stats.causalConservatismViolationCount = ...
        net.stats.causalConservatismViolationCount + 1;
end

end
