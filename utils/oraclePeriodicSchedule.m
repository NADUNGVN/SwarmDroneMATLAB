function sched = oraclePeriodicSchedule(regime)
%ORACLEPERIODICSCHEDULE Preregistered regime-to-rate map for the oracle.
%
%   sched = oraclePeriodicSchedule(networkRegimeSchedule('exp11'))
%
%   sched.tStart   segment start times [s], identical to the regime's
%   sched.period   period [s] in force on each segment
%   sched.rateHz   the same rates in Hz, for reporting
%   sched.label    regime label per segment
%
% THE MAP IS FIXED IN ADVANCE
%
%   Clean     -> P5    (0.20 s)
%   Moderate  -> P10   (0.10 s)
%   Stressed  -> P20   (0.05 s)
%
% Written down before any EXP11 run and not revisited afterwards. Choosing
% the oracle's rates after seeing the results would turn the reference into
% a fitted upper envelope, and the gap to it would then measure the fitting
% rather than the value of regime knowledge.
%
% WHAT THIS REFERENCE IS AND IS NOT
%
% It is non-causal: the switch times and the active regime are handed to it.
% No deployable policy has that. It is therefore an information-efficiency
% reference for rate adaptation, NOT an accuracy bound and NOT a
% performance upper bound - a fixed rate chosen per regime is not optimal
% within its own family, let alone over all policies, and Causal-v3 may
% legitimately beat it on either axis.
%
% It switches ONLY at the four regime boundaries. tests assert that, because
% an oracle allowed to switch freely would no longer be a periodic method.

if nargin < 1 || isempty(regime)
    regime = networkRegimeSchedule('exp11');
end

nSeg = numel(regime.tStart);

sched.tStart = regime.tStart;
sched.period = zeros(1, nSeg);
sched.label  = regime.label;

for s = 1:nSeg

    switch regime.label{s}

        case 'Clean'
            sched.period(s) = 0.20;   % P5

        case 'Moderate'
            sched.period(s) = 0.10;   % P10

        case 'Stressed'
            sched.period(s) = 0.05;   % P20

        otherwise
            error('oraclePeriodicSchedule: unmapped regime label "%s".', ...
                regime.label{s});

    end

end

sched.rateHz = 1 ./ sched.period;

% The oracle may change rate only where the channel changes. If two
% adjacent segments carry the same rate the oracle simply does not switch
% there, which is fine; what must never happen is a rate change at a time
% that is not a regime boundary.
sched.switchTimes = regime.switchTimes;

% NOT every period is a multiple of the outer step, and that is inherited
% rather than a defect. P20 is 0.05 s against a 0.02 s step, so its
% transmission instants land on ticks 0.06, 0.10, 0.16, 0.20, ... - the
% inter-transmission interval alternates between two and three ticks while
% the long-run rate is exactly 20 Hz. Every locked experiment that ran P20
% ran it this way, and EXP11 does not change it: quantising the period to
% the step would silently make P20 a 25 Hz or 16.7 Hz method and break
% comparability with the frozen results. What IS required is that the
% period is positive and finite on every segment.
for s = 1:nSeg
    if ~isfinite(sched.period(s)) || sched.period(s) <= 0
        error(['oraclePeriodicSchedule: period on segment %d is %g; it must ' ...
            'be positive and finite.'], s, sched.period(s));
    end
    if sched.period(s) < 0.02
        error(['oraclePeriodicSchedule: period %g on segment %d is shorter ' ...
            'than the outer step 0.02 s, so the rate is unreachable.'], ...
            sched.period(s), s);
    end
end

end
