function merged = mergeSharedMediumAckEntries(existing, incoming, sourceReceiver, N)
%MERGESHAREDMEDIUMACKENTRIES Cumulatively merge ACK entries by target sender.

merged = existing;

for k = 1:numel(incoming)
    e = incoming(k);

    if ~isfield(e,'targetSender') || ~isfield(e,'seq') || ~isfield(e,'genTime')
        error('mergeSharedMediumAckEntries: incomplete ACK entry.');
    end
    if e.targetSender < 1 || e.targetSender > N || e.targetSender ~= floor(e.targetSender)
        error('mergeSharedMediumAckEntries: targetSender is out of range.');
    end
    if e.seq < 0 || e.seq ~= floor(e.seq) || ~isfinite(e.genTime)
        error('mergeSharedMediumAckEntries: invalid sequence or generation time.');
    end

    e.sourceReceiver = sourceReceiver;

    idx = find([merged.targetSender] == e.targetSender, 1);
    if isempty(idx)
        merged(end+1) = e; %#ok<AGROW>
    elseif e.seq > merged(idx).seq
        merged(idx) = e;
    elseif e.seq == merged(idx).seq && abs(e.genTime-merged(idx).genTime) > 1e-12
        error('mergeSharedMediumAckEntries: one sequence has two generation times.');
    end
end

if ~isempty(merged)
    [~,order] = sort([merged.targetSender]);
    merged = merged(order);
end

end

