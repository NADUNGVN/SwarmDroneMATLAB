function M = exp11Methods()
%EXP11METHODS The seven EXP11 methods plus the oracle reference.
%
% Fields per entry:
%   id       short label used in results tables
%   family   'periodic' | 'event' | 'causal' | 'oracle'
%   period   scalar period [s] for a fixed periodic method, NaN otherwise
%   rateHz   nominal per-channel rate [Hz], for reporting only
%   note     one line on what the method is for
%
% THE FIXED PERIODIC LADDER
%
% P5 through P25 bracket the rates that EXP07-EXP10 showed to be
% interesting, and every one of them is held FIXED for the entire 83 s
% mission. That is the point: the reviewer objection "why not just tune a
% periodic rate?" is only answerable if the periodic baselines are denied
% the regime knowledge they would need. None of these methods is told which
% regime is active, and none may change rate at a switch.
%
% Transmissions can only occur on the 0.02 s outer step, so a period that
% is not a multiple of the step is realised as an alternating interval with
% the correct long-run rate. P5 (0.20 s), P10 (0.10 s), P12.5 (0.08 s) and
% P25 (0.04 s) are exact multiples. P20 is 0.05 s and is NOT: it fires on
% ticks 0.06, 0.10, 0.16, 0.20, ..., alternating two- and three-tick gaps
% at exactly 20 Hz on average. That is how every locked experiment ran P20
% and EXP11 leaves it alone - rounding the period to the step would turn
% P20 into a 25 Hz or 16.7 Hz method and break comparability with the
% frozen results that H2b is stated against.
%
% ORACLE-PERIODIC IS A REFERENCE, NOT A COMPETITOR
%
% Oracle-periodic is given the regime label and switches rate at the four
% preregistered boundaries. It is NON-CAUSAL: it uses information no
% deployable controller has. It exists to bound how much of the achievable
% gain comes from rate adaptation alone, and it must be labelled
% "non-causal / regime-aware reference" wherever it appears. It is never a
% gate for the proposed method: a result where the oracle wins is reported
% as it stands.

k = 0;

k = k + 1;
M(k).id     = 'P5';
M(k).family = 'periodic';
M(k).period = 0.20;
M(k).rateHz = 5.0;
M(k).note   = 'Fixed 5 Hz for the whole mission.';

k = k + 1;
M(k).id     = 'P10';
M(k).family = 'periodic';
M(k).period = 0.10;
M(k).rateHz = 10.0;
M(k).note   = 'Fixed 10 Hz. H2a reference for tracking accuracy.';

k = k + 1;
M(k).id     = 'P12.5';
M(k).family = 'periodic';
M(k).period = 0.08;
M(k).rateHz = 12.5;
M(k).note   = 'Fixed 12.5 Hz, fills the P10-P20 gap on the frontier.';

k = k + 1;
M(k).id     = 'P20';
M(k).family = 'periodic';
M(k).period = 0.05;
M(k).rateHz = 20.0;
M(k).note   = 'Fixed 20 Hz. H2b reference for communication cost.';

k = k + 1;
M(k).id     = 'P25';
M(k).family = 'periodic';
M(k).period = 0.04;
M(k).rateHz = 25.0;
M(k).note   = 'Fixed 25 Hz, the high-rate end of the ladder.';

k = k + 1;
M(k).id     = 'StateEvent';
M(k).family = 'event';
M(k).period = NaN;
M(k).rateHz = NaN;
M(k).note   = 'Locked state-error event trigger. No freshness term.';

k = k + 1;
M(k).id     = 'Causal';
M(k).family = 'causal';
M(k).period = NaN;
M(k).rateHz = NaN;
M(k).note   = 'Causal-AoI-v3, frozen. The proposed method.';

k = k + 1;
M(k).id     = 'OraclePeriodic';
M(k).family = 'oracle';
M(k).period = NaN;
M(k).rateHz = NaN;
M(k).note   = 'Non-causal / regime-aware reference. Not a gate.';

end
