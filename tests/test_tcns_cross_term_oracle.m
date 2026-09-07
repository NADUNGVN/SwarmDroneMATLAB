%% TEST_TCNS_CROSS_TERM_ORACLE Centralized value-decomposition contracts.

startup;

fprintf('\n=== TCNS centralized quadratic cross-term checks ===\n\n');

[cfg,~] = tcnsGate6Scenario(27020001,'S1');
cfg.swarm.T = 4;
cfg.net.commPeriod = 10*cfg.swarm.dt;
cfg.tcns.logReceiverState = true;
out = simSwarmNetworkQueued(cfg);
H = 25;
Q = tcnsOracleQuadraticCrossTerm(out,cfg,H);

assert(Q.oracle && ~Q.onlinePolicyAdmissible && ...
    ~Q.trueClosedLoopBranch, ...
    'CrossTerm: oracle/scope metadata is incorrect.');
assert(Q.lastDecisionIndex==numel(out.t)-H && ...
    Q.candidateCount>0, ...
    'CrossTerm: candidate horizon/count contract failed.');
assert(Q.maxDecompositionResidual<1e-13, ...
    'CrossTerm: direct and decomposed benefits disagree.');

valid = isfinite(Q.ordinaryIsolatedResponseEnergy);
isolated = Q.ordinaryIsolatedResponseEnergy(valid);
crossContribution = Q.ordinaryCrossContribution(valid);
benefit = Q.ordinaryExpectedBenefit(valid);
assert(all(isolated>=0) && all(isfinite(crossContribution)) && ...
    all(isfinite(benefit)), ...
    'CrossTerm: nonfinite or negative response energy was produced.');
assert(max(abs(benefit-(crossContribution-isolated)))<1e-14, ...
    'CrossTerm: exported decomposition is inconsistent.');
assert(any(isolated>0), ...
    'CrossTerm: moving fixture did not excite any candidate action.');

cfgLogged = cfg;
cfgPlain = rmfield(cfg,'tcns');
outPlain = simSwarmNetworkQueued(cfgPlain);
coreFields = {'P','V','A','meanAoI','txCountLog','broadcastCountLog', ...
    'txCount','dropCount','rxCount','traceHashExact','phaseHash'};
for f = 1:numel(coreFields)
    name = coreFields{f};
    assert(isequaln(outPlain.(name),out.(name)), ...
        'CrossTerm: passive receiver logging changed out.%s.',name);
end

fprintf('  candidates evaluated                       %d\n',Q.candidateCount);
fprintf('  max quadratic decomposition residual       %.3e\n', ...
    Q.maxDecompositionResidual);
fprintf('  passive receiver logging                   PASS\n');
fprintf('test_tcns_cross_term_oracle: PASS\n');
