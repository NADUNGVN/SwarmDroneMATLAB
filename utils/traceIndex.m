function kt = traceIndex(cfg, tk, k)
%TRACEINDEX Map an outer step to its CRN trace slot.
%
%   kt = traceIndex(cfg, tk, k)
%
% Default: the trace is indexed by outer step, exactly as every locked
% experiment has used it, and kt = k.
%
% When cfg.net.traceBaseDt is set, the trace lives on a master
% PHYSICAL-TIME grid and the slot is
%
%   kt = round(tk / traceBaseDt) + 1
%
% This exists for the EXP09C timestep diagnostic. A trace indexed by outer
% step cannot be reused across different dt: at dt = 0.04 a run would take
% half as many steps and so read half the trace, meeting a different
% channel realization than the dt = 0.02 run it is being compared against.
% Physical-time indexing makes every dt meet the same channel at the same
% instant, which is the only way the comparison isolates the timestep.
%
% The flag is additive and default-off, and test_lock_regression proves the
% historical behaviour is unchanged when it is absent.

if isfield(cfg,'net') && isfield(cfg.net,'traceBaseDt') ...
        && ~isempty(cfg.net.traceBaseDt) && cfg.net.traceBaseDt > 0

    kt = round(tk / cfg.net.traceBaseDt) + 1;

else

    kt = k;

end

end
