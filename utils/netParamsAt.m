function p = netParamsAt(cfg, tk)
%NETPARAMSAT Forward-channel loss / delay / jitter in force at time tk.
%
%   p = netParamsAt(cfg, tk)
%
%   p.packetLoss   probability a forward DATA packet is dropped
%   p.delay        base one-way delay [s]
%   p.jitterStd    delay jitter standard deviation [s]
%   p.segment      index of the active regime segment (0 when static)
%
% DEFAULT-OFF BY CONSTRUCTION
%
% With no cfg.net.regime field this returns cfg.net.packetLoss,
% cfg.net.delay and cfg.net.jitterStd verbatim. That is the only path any
% experiment before EXP11 can take, so every locked result must reproduce
% bit-identically; tests/test_lock_regression.m is the check that it does.
% The time-varying branch is reachable only when a caller explicitly
% attaches a schedule.
%
% WHY THE LOOKUP IS BY TRANSMISSION TIME
%
% The regime in force is the one containing the instant the packet is put on
% the channel. A packet transmitted at 22.98 s carries the Clean delay even
% though it arrives after the 23 s switch. The alternative - re-evaluating a
% packet's delay as it flies - would mean a regime change retroactively
% altering packets already sent, which no radio does.
%
% Interval convention is half-open, [tStart(k), tStart(k+1)), matching
% networkRegimeSchedule. Boundaries are outer-tick-aligned, so the
% comparison never has to resolve a tie inside a step; the small tolerance
% below only absorbs floating-point accumulation in tk itself.

if ~isfield(cfg, 'net')
    error('netParamsAt: cfg.net is required.');
end

if ~isfield(cfg.net, 'regime') || isempty(cfg.net.regime)

    % Static channel: the locked path.
    p.packetLoss = cfg.net.packetLoss;
    p.delay      = cfg.net.delay;
    p.jitterStd  = cfg.net.jitterStd;
    p.segment    = 0;
    return;

end

r = cfg.net.regime;

% Walk forward to the last segment whose start is not after tk. At most a
% handful of segments, so a loop is cheaper than find() and allocates
% nothing - this is called once per outer tick per link.
idx = 1;
for s = 2:numel(r.tStart)
    if tk >= r.tStart(s) - 1e-12
        idx = s;
    else
        break;
    end
end

p.packetLoss = r.loss(idx);
p.delay      = r.delay(idx);

if isfield(r, 'jitterStd') && ~isempty(r.jitterStd)
    p.jitterStd = r.jitterStd(idx);
else
    p.jitterStd = cfg.net.jitterStd;
end

p.segment = idx;

end
