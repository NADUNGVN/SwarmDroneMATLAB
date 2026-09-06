% TEST_FORMATION_THEORY_CERTIFICATE Check code-to-theory matrix construction.

startup;

cfg = defaultConfig();
cert = formationTheoryCertificate(cfg);

assert(cert.primaryTheoremApplicable, ...
    'Default ring/pinning cell should satisfy the symmetric grounded theorem.');
assert(cert.isHurwitz, ...
    'Default unsaturated one-axis formation matrix should be Hurwitz.');
assert(cert.lambdaMinHp > 0 && cert.lambdaMinHv > 0, ...
    'Default grounded stiffness and damping matrices must be positive definite.');
assert(cert.spectralAbscissa < 0, ...
    'Default closed-loop spectral abscissa must be negative.');
assert(cert.lyapunovLambdaMin > 0, ...
    'Hurwitz default cell must produce a positive-definite Lyapunov matrix.');
assert(cert.lyapunovResidual < 1e-10, ...
    'Continuous Lyapunov equation residual is too large.');
assert(cert.lyapunovStateDecayRate > 0 && cert.lyapunovInputGain > 0, ...
    'Explicit ISS certificate constants must be positive.');
assert(cert.isSchur && cert.sampledSpectralRadius < 1, ...
    'Default semi-implicit sampled formation matrix must be Schur.');
assert(cert.discreteLyapunovLambdaMin > 0, ...
    'Schur default cell must produce a positive discrete Lyapunov matrix.');
assert(cert.discreteLyapunovResidual < 1e-10, ...
    'Discrete Lyapunov equation residual is too large.');
assert(cert.discreteContractionFactor > 0 ...
    && cert.discreteContractionFactor < 1 ...
    && cert.discreteInputGain > 0, ...
    'Sampled ISS contraction and input gains are invalid.');

% Exact one-step identity for the locked semi-implicit Euler update.  The
% sampled theory state is y=[e;h*r], and its two inputs are [chi;h^2*omega].
m = cfg.swarm.N-1;
h = cfg.swarm.dt;
e = (1:m)'/10;
r = -(1:m)'/20;
omega = (1:m)'/7;
chi = -(1:m)'/1000;
rNext = r-h*cert.Hp*e-h*cert.Hv*r+h*omega;
eNext = e+h*rNext+chi;
yNextDirect = [eNext;h*rNext];
yNextMatrix = cert.sampledAcl*[e;h*r] ...
    + cert.sampledInputMatrix*[chi;h^2*omega];
assert(norm(yNextDirect-yNextMatrix) < 1e-12, ...
    'Sampled matrix does not match the semi-implicit Euler update exactly.');

expectedLeaderMap = double(cfg.swarm.pin(2:end)) - 1;
assert(isequal(cert.leaderAccelerationMismatchMap,expectedLeaderMap), ...
    'Leader-acceleration mismatch map does not match controller pin semantics.');

% Removing every direct/extra leader grounding must restore translational
% invariance, so the theorem no longer applies and Acl has a zero mode.
cfgUngrounded = cfg;
cfgUngrounded.swarm.A(2:end,1) = 0;
cfgUngrounded.swarm.A(1,2:end) = 0;
cfgUngrounded.swarm.pin(:) = 0;
ungrounded = formationTheoryCertificate(cfgUngrounded);

assert(~ungrounded.primaryTheoremApplicable, ...
    'Ungrounded formation must not pass the positive-definite theorem gate.');
assert(ungrounded.lambdaMinHp < 1e-9, ...
    'Ungrounded stiffness should retain a translation zero mode.');
assert(abs(ungrounded.spectralAbscissa) < 1e-8, ...
    'Ungrounded closed loop should have a translation mode at zero.');
assert(isempty(ungrounded.lyapunovP), ...
    'No positive-definite Lyapunov certificate should be issued for zero mode.');
assert(~ungrounded.isSchur && isempty(ungrounded.discreteLyapunovP), ...
    'Ungrounded sampled model must retain its unit translation mode.');

% A directed follower edge invalidates this symmetric proof even if a raw
% eigenvalue calculation happens to remain stable.
cfgDirected = cfg;
cfgDirected.swarm.A(3,2) = 0;
directed = formationTheoryCertificate(cfgDirected);
assert(~directed.primaryTheoremApplicable, ...
    'Directed/nonsymmetric cell must not inherit the undirected theorem.');

fprintf(['test_formation_theory_certificate: PASS ' ...
    '(default, ungrounded, directed)\n']);
