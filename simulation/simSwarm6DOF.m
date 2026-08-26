function out = simSwarm6DOF(cfg, method)
%SIMSWARM6DOF Run one swarm method with 6-DOF quadrotor followers.
%
%   out = simSwarm6DOF(cfg, method)
%
% method is 'P10', 'P20', 'State-event' or 'Causal-v3'.
%
% This is a DISPATCHER, not a fourth simulator. The 6-DOF path lives inside
% swarm/integrateFollowers.m, which every locked simulator now calls in
% place of the follower update it used to do inline. That is deliberate:
%
%   - the outer loop, network, AoI bookkeeping and trigger logic are the
%     SAME CODE in both modes, so nothing about communication can drift
%     between the double-integrator comparator and the 6-DOF run
%   - all four methods gain 6-DOF from one implementation rather than
%     three forks that would have to be kept in step
%   - with cfg.sixdof.enable false the call reproduces the locked
%     semi-implicit Euler exactly, which test_lock_regression checks
%     against the stored EXP05C / EXP06A / EXP07A values
%
% A separate simSwarm6DOF file duplicating simSwarmAoICausal would have
% given a weaker guarantee: two code paths that must be shown equal, rather
% than one path with a flag.

if nargin < 2
    method = 'Causal-v3';
end

if ~isfield(cfg,'sixdof') || ~isfield(cfg.sixdof,'enable')
    cfg.sixdof.enable = true;
end

if ~isfield(cfg.sixdof,'ratio')
    cfg.sixdof.ratio = 10;
end

switch method

    case 'P10'
        cfg.net.commPeriod = 0.10;
        out = simSwarmNetworkQueued(cfg);

    case 'P20'
        cfg.net.commPeriod = 0.05;
        out = simSwarmNetworkQueued(cfg);

    case 'State-event'
        out = simSwarmEventTriggered(cfg);

    case 'Causal-v3'
        out = simSwarmAoICausal(cfg);

    otherwise
        error('simSwarm6DOF: unknown method "%s".', method);

end

end
