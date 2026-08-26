function [PHat, VHat, est] = applyEstimator(P, V, est, cfg, tk)
%APPLYESTIMATOR Synthetic swarm-state estimate for one outer step.
%
%   [PHat, VHat, est] = applyEstimator(P, V, est, cfg, tk)
%
% Each follower i observes its own state ONCE, at physical time tk:
%
%   pHat_i(tk) = pTrue_i(tk - latency) + nP_i(tk)
%   vHat_i(tk) = vTrue_i(tk - latency) + nV_i(tk)
%
% That single estimate feeds three things and only three:
%   - the self-state the local swarm formation policy uses
%   - the event / Causal trigger
%   - the state payload that follower transmits
%
% The receiver applies NO second noise draw. It gets exactly the payload
% that was sent. Adding noise again at the receiver would give a value that
% crossed the network twice the variance of one used locally, and the noise
% would be silently charged to the act of transmitting.
%
% The TRUE P and V are returned untouched by the caller and remain what the
% dynamics integrate and what minSep and formation RMSE are measured on.
% Measuring safety on the noisy state would let a policy score as safe
% precisely because it could not see the collision.
%
% LATENCY is applied at exactly t - latency by linear interpolation between
% the two nearest outer-history samples. It is NOT rounded to a multiple of
% dt: rounding would make the effective latency change with dt and confound
% the timestep study. Before t - latency reaches zero the initial state is
% used.
%
% The leader is left noise-free and undelayed. It is a kinematic reference
% in EXP09C; this is a scope choice, not an oversight.
%
% With no cfg.estimator present the function is inert and returns the true
% state unchanged.

PHat = P;
VHat = V;

if ~isfield(cfg,'estimator') || isempty(cfg.estimator)
    return;
end

N = size(P,1);

latency = cfg.estimator.latency;


%% ============================================================
% History, for the delayed query
% ============================================================

if isempty(est) || ~isfield(est,'t')

    est.t = tk;
    est.P = reshape(P, [1 N 3]);
    est.V = reshape(V, [1 N 3]);

    est.nSum   = 0;
    est.nSumSq = zeros(1,2);
    est.errSq  = 0;
    est.errN   = 0;

else

    est.t(end+1)     = tk;
    est.P(end+1,:,:) = P;
    est.V(end+1,:,:) = V;

end


%% ============================================================
% Delayed true state at exactly tk - latency
% ============================================================

if latency <= 0

    Pd = P;
    Vd = V;

else

    tq = tk - latency;

    if tq <= est.t(1)

        % Startup: before the history reaches back that far, the initial
        % state is the only honest answer.
        Pd = squeeze(est.P(1,:,:));
        Vd = squeeze(est.V(1,:,:));

    else

        idx = find(est.t <= tq, 1, 'last');

        if idx >= numel(est.t)

            Pd = squeeze(est.P(end,:,:));
            Vd = squeeze(est.V(end,:,:));

        else

            t0 = est.t(idx);
            t1 = est.t(idx+1);

            w = (tq - t0) / (t1 - t0);

            Pd = (1-w) * squeeze(est.P(idx,:,:)) + w * squeeze(est.P(idx+1,:,:));
            Vd = (1-w) * squeeze(est.V(idx,:,:)) + w * squeeze(est.V(idx+1,:,:));

        end

    end

end

Pd = reshape(Pd, N, 3);
Vd = reshape(Vd, N, 3);


%% ============================================================
% One noise draw, looked up by physical time
% ============================================================

trace = cfg.estimator.noise;

kM = floor(tk / trace.baseDt) + 1;

kM = min(max(kM, 1), trace.nSample);

nP = squeeze(trace.n(kM, :, 1:3));
nV = squeeze(trace.n(kM, :, 4:6));

nP = reshape(nP, N, 3);
nV = reshape(nV, N, 3);

PHat = Pd + nP;
VHat = Vd + nV;

% The leader keeps its true, undelayed state.
PHat(1,:) = P(1,:);
VHat(1,:) = V(1,:);


%% ============================================================
% Realized noise and total estimator error, for reporting
%
% The total error includes the latency contribution, which the noise
% sigma alone does not capture: at 50 ms a moving follower is displaced
% by more than the position sigma.
% ============================================================

est.nSumSq(1) = est.nSumSq(1) + sum(sum(nP(2:N,:).^2));
est.nSumSq(2) = est.nSumSq(2) + sum(sum(nV(2:N,:).^2));
est.nSum      = est.nSum + (N-1);

est.errSq = est.errSq + sum(sum((PHat(2:N,:) - P(2:N,:)).^2));
est.errN  = est.errN + (N-1);

end
