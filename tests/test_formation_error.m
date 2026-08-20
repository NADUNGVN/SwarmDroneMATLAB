% TEST_FORMATION_ERROR Check computeSwarmMetrics against known geometry.
%
% The previous version of this test indexed cfg.swarm.offsets by column,
% which matched a config layout that no longer exists, so it errored on
% every run. It also compared the offsets matrix against itself, so even
% with correct indexing it could not have failed.
%
% This version drives computeSwarmMetrics with synthetic trajectories whose
% correct answers are known analytically.

startup;

cfg = defaultConfig();

N = cfg.swarm.N;
offsets = cfg.swarm.offsets;      % N x 3, row per agent

dt = cfg.swarm.dt;
t  = (0:dt:cfg.swarm.T)';
K  = numel(t);

tol = 1e-12;


%% ------------------------------------------------------------
% Case 1: perfect formation held for the whole run.
%
% Every follower sits exactly at leaderPos + offset, so the
% formation error must be identically zero.
% ------------------------------------------------------------

leaderPath = [0.5*t, 0.25*t, 1.2*ones(K,1)];

P = zeros(K,N,3);

for i = 1:N
    P(:,i,:) = leaderPath + offsets(i,:);
end

out.t = t;
out.P = P;
out.V = zeros(K,N,3);

M = computeSwarmMetrics(out, cfg);

assert(M.formationRMSE < tol, ...
    'Perfect formation should give zero RMSE, got %g', M.formationRMSE);

assert(M.maxFormationError < tol, ...
    'Perfect formation should give zero max error, got %g', M.maxFormationError);

assert(abs(M.settlingTime - t(1)) < tol, ...
    'Perfect formation should settle immediately, got %g', M.settlingTime);


%% ------------------------------------------------------------
% Case 2: one follower displaced by a known constant.
%
% Agent 2 is offset by d along x for the whole run. The RMSE is
% taken over the (N-1) followers and all evaluated samples, so
% only agent 2 contributes:
%
%   RMSE = d / sqrt(N-1)
% ------------------------------------------------------------

d = 0.30;

P2 = P;
P2(:,2,1) = P2(:,2,1) + d;

out.P = P2;

M2 = computeSwarmMetrics(out, cfg);

expectedRMSE = d / sqrt(N-1);

assert(abs(M2.formationRMSE - expectedRMSE) < 1e-10, ...
    'Expected RMSE %g, got %g', expectedRMSE, M2.formationRMSE);

assert(abs(M2.maxFormationError - d) < 1e-10, ...
    'Expected max error %g, got %g', d, M2.maxFormationError);


%% ------------------------------------------------------------
% Case 3: minimum separation.
%
% In the perfect formation the closest pair is determined by the
% offset lattice alone, so it can be computed independently.
% ------------------------------------------------------------

expectedMinSep = inf;

for i = 1:N
    for j = i+1:N
        expectedMinSep = min(expectedMinSep, norm(offsets(i,:) - offsets(j,:)));
    end
end

out.P = P;

M3 = computeSwarmMetrics(out, cfg);

assert(abs(M3.minSeparation - expectedMinSep) < 1e-10, ...
    'Expected min separation %g, got %g', expectedMinSep, M3.minSeparation);

assert(abs(M3.minSeparationEval - expectedMinSep) < 1e-10, ...
    'Expected eval min separation %g, got %g', ...
    expectedMinSep, M3.minSeparationEval);


%% ------------------------------------------------------------
% Case 4: velocity disagreement.
%
% All agents share one velocity, so disagreement must be zero.
% ------------------------------------------------------------

out.V = repmat(reshape([0.5 0.25 0], 1, 1, 3), K, N, 1);

M4 = computeSwarmMetrics(out, cfg);

assert(M4.velocityDisagreementRMSE < tol, ...
    'Identical velocities should give zero disagreement, got %g', ...
    M4.velocityDisagreementRMSE);


fprintf('test_formation_error: PASS (4 cases)\n');
