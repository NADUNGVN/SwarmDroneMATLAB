function counts = sharedMediumTerminalCounts(net)
%SHAREDMEDIUMTERMINALCOUNTS Right-censored physical work at mission end.
%
% Attempts are counted when a frame starts.  A multi-slot frame that remains
% active at the finite simulation horizon has neither a success nor a loss
% outcome yet.  This function exposes that third, right-censored state without
% mutating the medium or assigning a synthetic outcome.

counts.frames = numel(net.active);
counts.dataRecipientAttempts = 0;
counts.ackRecipientAttempts = 0;
for k = 1:numel(net.active)
    frame = net.active(k).frame;
    counts.dataRecipientAttempts = counts.dataRecipientAttempts + ...
        nnz(frame.dataReceiverMask);
    counts.ackRecipientAttempts = counts.ackRecipientAttempts + ...
        nnz(frame.ackReceiverMask);
end

end
