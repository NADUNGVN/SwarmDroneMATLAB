% TEST_TCNS_GATE1_MODEL_MAPPING Verify equations against real MATLAB steps.

startup;

cfg = defaultConfig();
cfg.sixdof.enable = false;
cfg.swarm.normalizeConsensusDegree = false;

cert = formationTheoryCertificate(cfg);
h = cfg.swarm.dt;

assert(isequal(cert.plantStateMatrix,[1 h;0 1]), ...
    'Gate1: the exported plant matrix does not match semi-implicit Euler.');
assert(isequal(cert.plantInputMatrix,[h^2;h]), ...
    'Gate1: the exported input matrix must contain h^2, not h^2/2.');
assert(~cert.maxSpeedIsEnforced, ...
    'Gate1: dead maxSpeed configuration must not become a theorem bound.');
assert(isequal(cert.leaderPinVector,double(cfg.swarm.pin(2:end))), ...
    'Gate1: exported pin vector differs from controller semantics.');

% Takeoff has changing vertical acceleration; circle has changing horizontal
% acceleration. Both must satisfy the corrected sampled identity.
times = [1.0 4.2];
legacyGapSeen = false;
for tk = times
    a = auditFormationSampledStep(cfg,tk);
    assert(a.unsaturated, ...
        'Gate1: exact-step fixture accidentally entered saturation.');
    assert(a.maxControllerResidual < 1e-12, ...
        'Gate1: matrix controller does not match distributedFormationPolicy.');
    assert(a.maxStateResidual < 1e-12, ...
        'Gate1: exact sampled state equation does not match integrateFollowers.');
    legacyGapSeen = legacyGapSeen || a.maxLegacyLeaderApproxResidual > 1e-12;
end
assert(legacyGapSeen, ...
    ['Gate1: fixture did not expose the analytical-leader velocity residual; ' ...
     'the test would not distinguish the corrected model from Euler shorthand.']);

% A directed follower edge may remain numerically Schur, but cannot inherit
% the symmetric grounded-Laplacian theorem.
directedCfg = cfg;
directedCfg.swarm.A(3,2) = 0;
directed = formationTheoryCertificate(directedCfg);
assert(~directed.primaryTheoremApplicable, ...
    'Gate1: directed graph incorrectly inherited the symmetric theorem.');

fprintf(['test_tcns_gate1_model_mapping: PASS ' ...
    '(plant, controller, analytical leader residual, theorem scope)\n']);
