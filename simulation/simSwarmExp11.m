function out = simSwarmExp11(cfg, method)
%SIMSWARMEXP11 Run one EXP11 method under a time-varying network.
%
%   out = simSwarmExp11(cfg, method)
%
% method is one of the ids in exp11Methods():
%
%   'P5' 'P10' 'P12.5' 'P20' 'P25'   fixed-period baselines
%   'StateEvent'                     locked state-error event trigger
%   'Causal'                         Causal-AoI-v3, the proposed method
%   'OraclePeriodic'                 non-causal / regime-aware reference
%
% WHY THIS IS A SEPARATE DISPATCHER AND NOT AN EXTRA CASE IN simSwarm6DOF
%
% simSwarm6DOF produced locked results and is left untouched. StateEvent and
% Causal are delegated straight to it, so those two methods run through the
% identical call the frozen experiments made - not a re-implementation that
% would have to be argued equal. Only the new periodic rates and the oracle
% are handled here.
%
% WHAT DISTINGUISHES THE PERIODIC METHODS FROM THE ORACLE
%
% Every fixed-period method sets cfg.net.commPeriod and NOTHING else. It is
% not given cfg.net.periodSchedule, so commPeriodAt returns segment 0 for the
% whole run, the transmission grid never re-anchors, and the rate is
% provably constant across all four channel switches. That is the property
% the reviewer objection turns on: a periodic baseline cannot be tuned to a
% network it is not told about.
%
% Oracle-periodic is the single exception. It receives the preregistered
% period schedule and therefore the switch times. It is non-causal and is
% never a gate for the proposed method.
%
% NO METHOD RECEIVES A REGIME LABEL
%
% cfg.net.regime and cfg.ack.regime describe the CHANNEL and are consumed
% only by netParamsAt and ackParamsAt inside the delivery path. No trigger,
% threshold, cooldown or controller gain reads them.
% tests/test_exp11_regime_semantics.m asserts that, because a policy told
% which regime it is in would be solving a different problem than the one
% EXP11 poses.

if nargin < 2 || isempty(method)
    method = 'Causal';
end

% Same 6-DOF defaults simSwarm6DOF applies, so the periodic and oracle
% branches below cannot silently run a double integrator when the caller
% left cfg.sixdof unset.
if ~isfield(cfg,'sixdof') || ~isfield(cfg.sixdof,'enable')
    cfg.sixdof.enable = true;
end

if ~isfield(cfg.sixdof,'ratio')
    cfg.sixdof.ratio = 10;
end

M = exp11Methods();

idx = find(strcmp({M.id}, method), 1);

if isempty(idx)
    error('simSwarmExp11: unknown method "%s".', method);
end

entry = M(idx);


switch entry.family

    case 'periodic'

        % Fixed rate for the whole mission. No period schedule is
        % attached, so the rate cannot change at a switch.
        cfg.net.commPeriod = entry.period;

        if isfield(cfg.net, 'periodSchedule')
            cfg.net = rmfield(cfg.net, 'periodSchedule');
        end

        out = simSwarmNetworkQueued(cfg);

    case 'oracle'

        sched = oraclePeriodicSchedule(cfg.net.regime);

        cfg.net.periodSchedule = sched;

        % commPeriod is still set, to the period of the first segment, so
        % that any consumer reading it directly sees a sensible value
        % rather than an inherited one. commPeriodAt overrides it whenever
        % the schedule is present.
        cfg.net.commPeriod = sched.period(1);

        out = simSwarmNetworkQueued(cfg);

        out.oracleSchedule = sched;

    case 'event'

        out = simSwarm6DOF(cfg, 'State-event');

    case 'causal'

        out = simSwarm6DOF(cfg, 'Causal-v3');

    otherwise

        error('simSwarmExp11: unhandled family "%s".', entry.family);

end

out.exp11Method = entry.id;
out.exp11Family = entry.family;

end
