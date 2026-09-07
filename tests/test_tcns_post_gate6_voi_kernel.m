%% TEST_TCNS_POST_GATE6_VOI_KERNEL Exact kernel and passive-log contracts.

startup;

fprintf('\n=== TCNS post-Gate-6 one-shot value-kernel checks ===\n\n');

cfg = defaultConfig();
H = 25;
D = 4;
K = tcnsFiniteHorizonLinkValueKernel(cfg,H,D);
certificate = tcnsFormationRobustnessCertificate(cfg);
A = certificate.Ah;
B = certificate.Bc;
m = numel(certificate.followers);
C = [eye(m),zeros(m)];

corrections = [0.7 -0.2 0.5; -0.1 0.9 0.3; ...
    0.4 0.6 -0.8; 1.1 -0.5 0.2];
maxIdentityResidual = 0;
for fi = 1:m
    state = zeros(2*m,3);
    directEnergy = 0;
    for r = 1:H
        active = (r-1)>=D;
        state = A*state+B(:,fi)*(corrections(fi,:)*double(active));
        directEnergy = directEnergy+sum((C*state).^2,'all');
    end
    formulaEnergy = K.positionEnergyGain(fi) * ...
        sum(corrections(fi,:).^2);
    maxIdentityResidual = max(maxIdentityResidual, ...
        abs(directEnergy-formulaEnergy));
end
assert(maxIdentityResidual<1e-13, ...
    'PostGate6: finite-horizon link-value identity failed.');

Klate = tcnsFiniteHorizonLinkValueKernel(cfg,H,H);
assert(all(Klate.positionEnergyGain==0), ...
    'PostGate6: a delivery outside the horizon received nonzero value.');

[cfgRun,~] = tcnsGate6Scenario(27020001,'S1');
cfgRun.swarm.T = 4;
cfgRun.net.commPeriod = 10*cfgRun.swarm.dt;
cfgPlain = cfgRun;
cfgLogged = cfgRun;
cfgLogged.tcns.logReceiverState = true;
outPlain = simSwarmNetworkQueued(cfgPlain);
outLogged = simSwarmNetworkQueued(cfgLogged);

coreFields = {'P','V','A','meanAoI','txCountLog','broadcastCountLog', ...
    'txCount','dropCount','rxCount','traceHashExact','phaseHash'};
for f = 1:numel(coreFields)
    name = coreFields{f};
    assert(isequaln(outPlain.(name),outLogged.(name)), ...
        'PostGate6: passive periodic receiver logging changed out.%s.',name);
end

value = tcnsOracleLinkUpdateValue(outLogged,cfgLogged,H);
assert(value.oracle && ~value.onlinePolicyAdmissible, ...
    'PostGate6: the receiver-truth probe lost its oracle warning.');
assert(all(isfinite(value.total)) && all(value.total>=0), ...
    'PostGate6: oracle link-update value is invalid.');
assert(value.total(1)<1e-14, ...
    'PostGate6: common initial receiver state should have zero value.');
assert(any(value.total(2:end)>0), ...
    'PostGate6: the value probe is inactive on a moving trajectory.');

fprintf('  max exact-kernel identity residual       %.3e\n', ...
    maxIdentityResidual);
fprintf('  static-channel success probability       %.3f\n', ...
    value.successProbability);
fprintf('  max observed oracle one-shot value        %.3e\n', ...
    max(value.total));
fprintf('test_tcns_post_gate6_voi_kernel: PASS\n');

