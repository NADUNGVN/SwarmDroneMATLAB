function regime = networkRegimeSchedule(name)
%NETWORKREGIMESCHEDULE Piecewise-constant network quality over a mission.
%
%   regime = networkRegimeSchedule('exp11')
%
% Every experiment before EXP11 held network quality FIXED for a whole run,
% so a periodic baseline could be tuned to the one condition it would ever
% meet. That is precisely the reviewer objection EXP11 exists to answer:
% "why not just tune a periodic rate?". A fixed rate can only be tuned to a
% network you already know, and this schedule denies that knowledge.
%
% WHAT A REGIME MAY AND MAY NOT CHANGE
%
% A regime changes the CHANNEL and nothing else. It sets the packet-loss
% probability and the base delay applied to transmissions occurring inside
% its interval. It does NOT touch any trigger threshold, adaptive-scale
% parameter, cooldown, max-silence bound, controller gain, or the period of
% any non-oracle periodic method. tests/test_exp11_regime_semantics.m
% asserts that directly, because a regime that leaked into the policy
% would make the whole experiment circular: the method would be told what
% it is supposed to infer.
%
% THE SCHEDULE IS PIECEWISE CONSTANT AND SWITCHES ON OUTER TICKS
%
% Segment boundaries are integer multiples of the 0.02 s outer step, so a
% switch lands exactly on a tick and no transmission straddles two
% regimes. The interval convention is half-open, [tStart, tNext), with the
% final segment closed at the mission end.
%
% EXP11 TIMELINE
%
%   0 - 23 s   Clean      (0-8 s is warm-up, excluded from every metric)
%   23 - 38 s  Moderate
%   38 - 53 s  Stressed
%   53 - 68 s  Moderate
%   68 - 83 s  Clean
%
% Four switch instants: 23, 38, 53, 68 s. The schedule descends into
% degradation and comes back out again on purpose. A one-way sweep would
% only show that the policy notices a network getting worse; the return leg
% is what tests whether it also gives the traffic back, which is the
% property a fixed rate cannot have in either direction.
%
% The three quality levels are the locked EXP05-EXP10 definitions,
% unchanged:
%
%   Clean     loss 0.00   delay 0.00 s
%   Moderate  loss 0.20   delay 0.08 s
%   Stressed  loss 0.40   delay 0.12 s

if nargin < 1 || isempty(name)
    name = 'exp11';
end

switch lower(name)

    case 'exp11'

        regime.name = 'exp11';

        % Segment start times [s]. The channel is constant on
        % [tStart(k), tStart(k+1)).
        regime.tStart = [0, 23, 38, 53, 68];

        regime.loss  = [0.00, 0.20, 0.40, 0.20, 0.00];
        regime.delay = [0.00, 0.08, 0.12, 0.08, 0.00];

        % Jitter is zero in every nominal frozen scenario and stays zero
        % here, so the only things a switch changes are loss and delay.
        regime.jitterStd = [0, 0, 0, 0, 0];

        regime.label = {'Clean','Moderate','Stressed','Moderate','Clean'};

        regime.tEnd = 83;

        % The four preregistered switch instants. Oracle-periodic is the
        % only method permitted to change behaviour at these times, and
        % only at these times.
        regime.switchTimes = regime.tStart(2:end);

        % Metric segments. Distinct from the channel segments because the
        % first 8 s are warm-up: the channel is Clean from t = 0, but no
        % metric is taken until t = 8.
        %
        % The two Clean segments and the two Moderate segments are kept
        % SEPARATE deliberately. Averaging Clean_1 with Clean_2 would hide
        % exactly the question the return leg asks - whether the policy
        % comes back down - so the experiment never merges them.
        regime.segName  = {'Clean_1','Moderate_1','Stressed','Moderate_2','Clean_2'};
        regime.segStart = [8, 23, 38, 53, 68];
        regime.segEnd   = [23, 38, 53, 68, 83];

        regime.evalStart = 8;

    otherwise

        error('networkRegimeSchedule: unknown schedule "%s".', name);

end


%% ============================================================
% Consistency checks
%
% Cheap, and they run every time the schedule is built. A schedule whose
% boundaries do not land on outer ticks would let a switch fall inside a
% step, which is the kind of defect that produces a plausible-looking
% result.
% ============================================================

dt = 0.02;

allTimes = [regime.tStart, regime.tEnd, regime.segStart, regime.segEnd];

for t = allTimes
    if abs(t/dt - round(t/dt)) > 1e-9
        error('networkRegimeSchedule: time %g is not a multiple of dt = %g.', t, dt);
    end
end

if ~isequal(sort(regime.tStart), regime.tStart)
    error('networkRegimeSchedule: segment starts must be increasing.');
end

if numel(regime.loss) ~= numel(regime.tStart) || ...
        numel(regime.delay) ~= numel(regime.tStart)
    error('networkRegimeSchedule: schedule arrays disagree in length.');
end

end
