function [T, segIdx, segStart] = commPeriodAt(cfg, tk)
%COMMPERIODAT Periodic transmission period in force at time tk.
%
%   [T, segIdx, segStart] = commPeriodAt(cfg, tk)
%
%   T         period [s]
%   segIdx    index of the active schedule segment, or 0 when the period
%             is fixed for the whole run
%   segStart  start time [s] of that segment, or 0 when fixed
%
% DEFAULT-OFF, AND THAT DEFAULT COVERS EVERY FIXED PERIODIC METHOD
%
% With no cfg.net.periodSchedule field this returns cfg.net.commPeriod and
% segIdx = 0. That is the path taken by every locked experiment AND by all
% five fixed periodic methods in EXP11 (P5, P10, P12.5, P20, P25) - those
% methods run under a time-varying CHANNEL but their own rate never moves,
% which is the whole point of the comparison. Only Oracle-periodic attaches
% a period schedule.
%
% WHY A NON-ZERO segIdx MEANS "RE-ANCHOR" RATHER THAN "KEEP ACCUMULATING"
%
% The caller uses segIdx to detect a boundary crossing and restart the
% transmission grid at the segment start. Accumulating instead - adding the
% new period to a nextTx inherited from the previous segment - would leave
% the first transmission of a segment at an arbitrary offset that depends on
% the old rate, so the realised rate near a boundary would be neither the
% old one nor the new one. Re-anchoring makes each segment an exact
% periodic schedule at its own rate, with the sender's phase fraction
% preserved, so "the oracle transmits at 20 Hz while Stressed" is literally
% true and can be asserted.
%
% Segment starts are outer-tick-aligned and the periods are multiples of the
% outer step, so a re-anchored grid lands on ticks and loses nothing to
% quantisation.

if ~isfield(cfg, 'net')
    error('commPeriodAt: cfg.net is required.');
end

if ~isfield(cfg.net, 'periodSchedule') || isempty(cfg.net.periodSchedule)

    T        = cfg.net.commPeriod;
    segIdx   = 0;
    segStart = 0;
    return;

end

ps = cfg.net.periodSchedule;

idx = 1;
for s = 2:numel(ps.tStart)
    if tk >= ps.tStart(s) - 1e-12
        idx = s;
    else
        break;
    end
end

T        = ps.period(idx);
segIdx   = idx;
segStart = ps.tStart(idx);

end
