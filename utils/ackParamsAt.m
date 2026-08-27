function p = ackParamsAt(cfg, tk)
%ACKPARAMSAT Reverse-channel (ACK) loss / delay / jitter in force at tk.
%
%   p = ackParamsAt(cfg, tk)
%
%   p.loss       probability an ACK is dropped
%   p.delay      base one-way ACK delay [s]
%   p.jitterStd  ACK delay jitter standard deviation [s]
%   p.segment    index of the active regime segment (0 when static)
%
% Mirror of netParamsAt for the return path. With no cfg.ack.regime field
% the locked static values are returned verbatim, so pre-EXP11 behaviour is
% untouched.
%
% WHY THE ACK REGIME IS ITS OWN FIELD
%
% A degraded channel degrades in both directions, but the frozen scenario
% definitions parameterise the two paths separately (cfg.net vs cfg.ack),
% and EXP11 keeps that separation rather than deriving one from the other.
% The EXP11 driver attaches the same schedule shape to both, which is what
% makes the reverse path degrade with the forward path - but the coupling is
% stated in the driver where it can be read, not hidden in a helper.
%
% As in netParamsAt, the regime is resolved at the instant the ACK is
% generated. An ACK created just before a switch travels under the old
% conditions.

if ~isfield(cfg, 'ack')
    error('ackParamsAt: cfg.ack is required.');
end

if ~isfield(cfg.ack, 'regime') || isempty(cfg.ack.regime)

    p.loss      = cfg.ack.loss;
    p.delay     = cfg.ack.delay;
    p.jitterStd = cfg.ack.jitterStd;
    p.segment   = 0;
    return;

end

r = cfg.ack.regime;

idx = 1;
for s = 2:numel(r.tStart)
    if tk >= r.tStart(s) - 1e-12
        idx = s;
    else
        break;
    end
end

p.loss  = r.loss(idx);
p.delay = r.delay(idx);

if isfield(r, 'jitterStd') && ~isempty(r.jitterStd)
    p.jitterStd = r.jitterStd(idx);
else
    p.jitterStd = cfg.ack.jitterStd;
end

p.segment = idx;

end
