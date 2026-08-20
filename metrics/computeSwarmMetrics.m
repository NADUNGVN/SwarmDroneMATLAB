function M = computeSwarmMetrics(out, cfg)
%COMPUTESWARMMETRICS Formation, safety and coordination metrics for a run.
%
% Vectorised implementation. Numerically identical to the earlier loop-based
% version; the pairwise-separation search in particular was O(K*N^2) scalar
% norm() calls, which dominated the cost of the N = 50 scalability runs.

t = out.t;
P = out.P;
V = out.V;

K = numel(t);

N = cfg.swarm.N;
offsets = cfg.swarm.offsets;


% Ignore the initial formation-acquisition transient.
evalStart = 8.0;

idx = t >= evalStart;


%% ============================================================
% Formation error
%
% Follower i is measured against the leader's actual position plus
% its desired offset. Row 1 (the leader) stays zero.
% ============================================================

leaderPos = P(:,1,:);                       % K x 1 x 3

desiredPos = leaderPos + reshape(offsets, [1 N 3]);

formationError = sqrt(sum((P - desiredPos).^2, 3));   % K x N

formationError(:,1) = 0;


errEval = formationError(idx, 2:N);

M.formationRMSE = sqrt(mean(errEval(:).^2));

M.maxFormationError = max(errEval(:));


%% ============================================================
% Velocity disagreement
%
% RMS deviation from the instantaneous swarm-mean velocity,
% averaged over all N agents.
% ============================================================

vMean = mean(V, 2);                         % K x 1 x 3

velocityDisagreement = sqrt(mean(sum((V - vMean).^2, 3), 2));   % K x 1

M.velocityDisagreementRMSE = ...
    sqrt(mean(velocityDisagreement(idx).^2));


%% ============================================================
% Minimum pairwise separation
% ============================================================

[iPair, jPair] = find(triu(true(N), 1));

if isempty(iPair)

    minSepFull = inf;
    minSepEval = inf;

else

    d2 = zeros(K, numel(iPair));

    for c = 1:3
        dc = P(:,iPair,c) - P(:,jPair,c);
        d2 = d2 + dc.^2;
    end

    minSepFull = sqrt(min(d2(:)));

    if any(idx)
        d2Eval = d2(idx,:);
        minSepEval = sqrt(min(d2Eval(:)));
    else
        minSepEval = inf;
    end

end

M.minSeparation = minSepFull;
M.minSeparationEval = minSepEval;


%% ============================================================
% Formation settling
%
% Earliest time after which every follower stays inside 5 cm.
% ============================================================

threshold = 0.05;

maxFollowerError = max(formationError(:,2:N), [], 2);

lastViolation = find(maxFollowerError >= threshold, 1, 'last');

if isempty(lastViolation)
    settlingTime = t(1);
elseif lastViolation < K
    settlingTime = t(lastViolation + 1);
else
    settlingTime = NaN;
end

M.settlingTime = settlingTime;


M.formationError = formationError;
M.velocityDisagreement = velocityDisagreement;

end
