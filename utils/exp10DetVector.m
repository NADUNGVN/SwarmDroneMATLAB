function v = exp10DetVector(out, cfg)
%EXP10DETVECTOR The scalars the serial-versus-parallel check compares.
%
%   v = exp10DetVector(out, cfg)
%
% A proper function file rather than a local function of the validation
% script, because it is called from inside a parfor body and a script's
% local functions are not a dependable thing to hand to a pool worker.
%
% Every entry is either exact by construction (a count, a hash) or a
% deterministic function of the trajectory (RMSE, minimum separation), so
% the comparison against these values is bit-identity and not a
% tolerance. See the header of run_simulation_v1_validation for why no
% tolerance is applied.
%
% Order:
%   1 formation RMSE
%   2 minimum separation over the evaluation window
%   3 DATA transmissions
%   4 ACK transmissions (0 for a method with no reverse channel)
%   5 broadcast-accounted DATA transmissions
%   6 received packets
%   7 dropped packets
%   8 forward-trace EXACT hash
%   9 reverse-trace EXACT hash (NaN where there is none)
%  10 causal protocol invariant violations
%
% The EXACT hashes, not the locked generator ones. The locked hashes sum
% millions of floats whose partial sums exceed 2^53, and MATLAB's
% multithreaded pairwise sum() groups them differently depending on
% thread count - a pool worker runs single-threaded, the client does not.
% The identical forward trace therefore hashed to 7.37428389003314e+15 in
% the client and 7.37428389003311e+15 on a worker while the trajectories
% were bit-identical. Comparing those here would report a
% reproducibility failure that does not exist. The exact hashes are
% integer-summed below 2^53, so summation order cannot move them.

M = computeSwarmMetrics(out, cfg);

if isfield(out,'ackTxCount')
    ackCount = out.ackTxCount;
else
    ackCount = 0;
end

if isfield(out,'invariantViolations')
    inv = out.invariantViolations;
else
    inv = 0;
end

v = [ ...
    M.formationRMSE, ...
    M.minSeparationEval, ...
    out.txCount, ...
    ackCount, ...
    out.broadcastCount, ...
    out.rxCount, ...
    out.dropCount, ...
    out.traceHashExact, ...
    out.ackTraceHashExact, ...
    inv];

end
