function audit = auditFormationSampledStep(cfg, tk)
%AUDITFORMATIONSAMPLEDSTEP Compare one real MATLAB step to the proof model.
%
%   audit = auditFormationSampledStep(cfg, tk)
%
% The fixture uses the actual distributedFormationPolicy and
% integrateFollowers functions. It is deliberately restricted to the exact-
% state, constant-offset, unsaturated double-integrator path used by the first
% TCNS theorem track. The leader is evaluated analytically at tk and tk+h, so
% the audit also exposes the velocity-step residual missed by an Euler-only
% leader approximation.

if nargin < 2 || isempty(tk)
    tk = 1.0;
end
if ~isscalar(tk) || ~isfinite(tk) || tk < 0
    error('auditFormationSampledStep: tk must be a finite nonnegative scalar.');
end
if isfield(cfg,'sixdof') && isfield(cfg.sixdof,'enable') ...
        && cfg.sixdof.enable
    error(['auditFormationSampledStep: the exact sampled LTI audit does not ' ...
        'apply to the 6-DOF path.']);
end

cert = formationTheoryCertificate(cfg);
h = cfg.swarm.dt;
N = cfg.swarm.N;
m = N-1;

leaderNow = leaderReference(tk);
leaderNext = leaderReference(tk+h);

% Small deterministic perturbations keep the real controller away from its
% acceleration saturation while exciting every coordinate and follower mode.
q = (1:m)';
e = 1e-3 * [q, (-1).^q, q/(m+1)];
r = 5e-4 * [(-1).^q, q/(m+1), -q];

P = repmat(leaderNow.pos',N,1) + cfg.swarm.offsets;
V = repmat(leaderNow.vel',N,1);
P(2:end,:) = P(2:end,:) + e;
V(2:end,:) = V(2:end,:) + r;
P(1,:) = leaderNow.pos';
V(1,:) = leaderNow.vel';

accCmd = distributedFormationPolicy(P,V,leaderNow,cfg);

controllerExpected = zeros(m,3);
for c = 1:3
    controllerExpected(:,c) = -cert.Hp*e(:,c) - cert.Hv*r(:,c) ...
        + cert.leaderPinVector*leaderNow.acc(c);
end
controllerResidual = accCmd(2:end,:)-controllerExpected;

followerAccelNorm = sqrt(sum(accCmd(2:end,:).^2,2));
if isfinite(cert.maxCommandedAcceleration)
    unsaturated = all(followerAccelNorm ...
        < cert.maxCommandedAcceleration-1e-10);
    saturationMargin = cert.maxCommandedAcceleration-max(followerAccelNorm);
else
    unsaturated = true;
    saturationMargin = inf;
end

[Pnext,Vnext,~] = integrateFollowers(P,V,accCmd,[],cfg,tk);
Pnext(1,:) = leaderNext.pos';
Vnext(1,:) = leaderNext.vel';

eNext = Pnext(2:end,:) - repmat(leaderNext.pos',m,1) ...
    - cfg.swarm.offsets(2:end,:);
rNext = Vnext(2:end,:) - repmat(leaderNext.vel',m,1);

yActual = zeros(2*m,3);
yPredicted = zeros(2*m,3);
yLegacyLeaderApprox = zeros(2*m,3);
inputExact = zeros(2*m,3);
inputLegacy = zeros(2*m,3);

onesFollower = ones(m,1);
for c = 1:3
    y = [e(:,c);h*r(:,c)];
    chi = onesFollower * (h*leaderNext.vel(c) ...
        -(leaderNext.pos(c)-leaderNow.pos(c)));

    % Exact scaled velocity input h*zeta. No communication disturbance is
    % present in this fixture. The term includes the analytical leader's true
    % velocity increment, not the approximation h*a_L(tk).
    upsilon = h^2*cert.leaderPinVector*leaderNow.acc(c) ...
        - h*onesFollower*(leaderNext.vel(c)-leaderNow.vel(c));

    % Historical continuous-time shorthand (Pi-I)*a_L, included only to prove
    % that it is not an exact sampled identity for a time-varying acceleration.
    legacyUpsilon = h^2*(cert.leaderPinVector-onesFollower) ...
        * leaderNow.acc(c);

    inputExact(:,c) = [chi;upsilon];
    inputLegacy(:,c) = [chi;legacyUpsilon];
    yActual(:,c) = [eNext(:,c);h*rNext(:,c)];
    yPredicted(:,c) = cert.sampledAcl*y ...
        + cert.sampledInputMatrix*inputExact(:,c);
    yLegacyLeaderApprox(:,c) = cert.sampledAcl*y ...
        + cert.sampledInputMatrix*inputLegacy(:,c);
end

audit = struct();
audit.time = tk;
audit.sampleTime = h;
audit.unsaturated = unsaturated;
audit.saturationMargin = saturationMargin;
audit.maxFollowerAcceleration = max(followerAccelNorm);
audit.maxControllerResidual = max(abs(controllerResidual(:)));
audit.maxStateResidual = max(abs(yActual(:)-yPredicted(:)));
audit.maxLegacyLeaderApproxResidual = ...
    max(abs(yActual(:)-yLegacyLeaderApprox(:)));
audit.leaderPositionStepResidual = inputExact(1:m,:);
audit.scaledLeaderVelocityInput = inputExact(m+1:end,:);
audit.actualState = yActual;
audit.predictedState = yPredicted;
audit.legacyPredictedState = yLegacyLeaderApprox;
audit.initialFormationError = e;
audit.initialVelocityError = r;
audit.actualAcceleration = accCmd(2:end,:);
audit.expectedAcceleration = controllerExpected;
audit.certificate = cert;

end
