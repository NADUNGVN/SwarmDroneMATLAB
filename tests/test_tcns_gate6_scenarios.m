%% TEST_TCNS_GATE6_SCENARIOS Nonstationary scenario and burst-channel contracts.

startup;

fprintf('\n=== TCNS Gate-6 scenario infrastructure checks ===\n\n');

% Explicit IID must preserve the historical trace exactly.
[cfg1,scenario1] = tcnsGate6Scenario(27020001,'S1');
traceDefault = generateNetworkTrace(cfg1);
cfgIid = cfg1;
cfgIid.net.lossModel.type = 'iid';
traceIid = generateNetworkTrace(cfgIid);
assert(traceDefault.hashExact==traceIid.hashExact && ...
    isequal(traceDefault.lossU,traceIid.lossU) && ...
    ~isfield(traceDefault,'dropMask') && ~isfield(traceIid,'dropMask'), ...
    'Gate6: explicit IID changed the frozen trace.');
assert(strcmp(scenario1.name,'Stationary-Moderate'), ...
    'Gate6: S1 is not the stationary control scenario.');

% Formation switching is continuous and uses the declared knots.
[cfg2,scenario2] = tcnsGate6Scenario(27020001,'S2');
base = cfg2.swarm.offsets;
rotated = base;
rotated(:,1:2) = base(:,1:2)*[0 1;-1 0];
assert(isequal(tcnsFormationOffsetsAt(cfg2,10),base) && ...
    max(abs(tcnsFormationOffsetsAt(cfg2,14)-rotated),[],'all')<1e-14 && ...
    max(abs(tcnsFormationOffsetsAt(cfg2,12)-0.5*(base+rotated)),[],'all')<1e-14, ...
    'Gate6: S2 formation interpolation is incorrect.');
assert(isequal(scenario2.eventWindows_s,[10 14;20 24]), ...
    'Gate6: S2 event windows drifted.');

% Gilbert-Elliott realization is shared/reproducible and visibly bursty.
[cfg3,scenario3] = tcnsGate6Scenario(27020001,'S3');
traceGeA = generateNetworkTrace(cfg3);
traceGeB = generateNetworkTrace(cfg3);
[cfg3Other,~] = tcnsGate6Scenario(27020002,'S3');
traceGeOther = generateNetworkTrace(cfg3Other);
assert(isequal(traceGeA.dropMask,traceGeB.dropMask) && ...
    traceGeA.hashExact==traceGeB.hashExact && ...
    traceGeA.hashExact~=traceGeOther.hashExact, ...
    'Gate6: Gilbert-Elliott trace is not seed-deterministic/distinct.');
badNow = traceGeA.badState(1:end-1,:,:);
badNext = traceGeA.badState(2:end,:,:);
badPersistence = mean(badNext(badNow));
dropFraction = mean(traceGeA.dropMask,'all');
assert(badPersistence>0.85 && dropFraction>0.20 && dropFraction<0.60, ...
    'Gate6: configured burst trace is not observably persistent/plausible.');
assert(strcmp(scenario3.name,'Gilbert-Elliott-burst-loss'), ...
    'Gate6: S3 label drifted.');

% Dynamic congestion resolves by transmission time on both directions.
[cfg4,~] = tcnsGate6Scenario(27020001,'S4');
np = netParamsAt(cfg4,12);
ap = ackParamsAt(cfg4,12);
assert(abs(np.packetLoss-0.40)<1e-14 && abs(np.delay-0.18)<1e-14 && ...
    abs(np.jitterStd-0.04)<1e-14 && ap.loss==0 && ...
    abs(ap.delay-0.18)<1e-14, ...
    'Gate6: S4 channel/ACK regime lookup is incorrect.');

% Topology outage is temporary, method-blind, and does not edit nominal A.
[cfg5,scenario5] = tcnsGate6Scenario(27020001,'S5');
assert(nnz(cfg5.fault.down)>0 && cfg5.fault.tStart==12 && ...
    cfg5.fault.tEnd==18 && isequal(cfg5.swarm.A,cfg1.swarm.A) && ...
    isequal(scenario5.eventWindows_s,[12 18]), ...
    'Gate6: S5 temporary topology perturbation is malformed.');

% DI disturbance pulses are physical-time deterministic and affect only the
% selected follower in the exact semi-implicit update.
[cfg6,scenario6] = tcnsGate6Scenario(27020001,'S6');
d0 = tcnsFollowerDisturbanceAt(cfg6,11);
d1 = tcnsFollowerDisturbanceAt(cfg6,13);
d2 = tcnsFollowerDisturbanceAt(cfg6,21);
assert(all(d0==0,'all') && abs(d1(3,1)-0.8)<1e-14 && ...
    nnz(abs(d1)>1e-14)==1 && abs(d2(4,2)-0.8)<1e-14 && ...
    nnz(abs(d2)>1e-14)==1 && ...
    isequal(scenario6.eventWindows_s,[12 16;20 24]), ...
    'Gate6: S6 deterministic excitation is incorrect.');
P = zeros(cfg6.swarm.N,3);
V = P;
acc = P;
[Pnext,Vnext] = integrateFollowers(P,V,acc,[],cfg6,13);
h = cfg6.swarm.dt;
assert(abs(Vnext(3,1)-h*0.8)<1e-14 && ...
    abs(Pnext(3,1)-h^2*0.8)<1e-14, ...
    'Gate6: DI excitation is not applied by the exact integrator.');

% End-to-end burst mask consumption uses the same trace in both policy
% families and keeps the causal protocol valid.
cfg3.swarm.T = 4;
cfg3.net.commPeriod = 0.10;
periodic = simSwarmNetworkQueued(cfg3);
cfg3.causal.policyMode = 'control-aware';
cfg3.controlAware.epsilonPosition = 0.4;
cfg3.controlAware.retryInterval = 0.10;
control = simSwarmAoICausal(cfg3);
assert(periodic.traceHashExact==control.traceHashExact && ...
    periodic.dropCount>0 && control.dropCount>0 && ...
    control.invariantViolations==0, ...
    'Gate6: S3 end-to-end trace sharing or causal delivery failed.');

fprintf('  S1 stationary control / S2 formation schedule       PASS\n');
fprintf('  S3 GE persistence %.3f, realized mask loss %.3f     PASS\n', ...
    badPersistence,dropFraction);
fprintf('  S4 channel schedule / S5 topology outage            PASS\n');
fprintf('  S6 DI dynamic excitation                            PASS\n');
fprintf('test_tcns_gate6_scenarios: PASS\n');

