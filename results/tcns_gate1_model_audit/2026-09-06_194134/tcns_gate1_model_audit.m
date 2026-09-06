%% TCNS GATE 1 - Exact implementation-to-model audit

startup;
close all;

R = startExperiment('tcns_gate1_model_audit', ...
    'Exact double-integrator/controller/leader sampled-model audit.');

cfg = defaultConfig();
cfg.sixdof.enable = false;
cfg.swarm.normalizeConsensusDegree = false;
cert = formationTheoryCertificate(cfg);

times = [1.0 4.2];
T = table('Size',[numel(times) 7], ...
    'VariableTypes',repmat({'double'},1,7), ...
    'VariableNames',{'time_s','sampleTime_s','maxControllerResidual', ...
    'maxStateResidual','maxLegacyLeaderApproxResidual', ...
    'maxFollowerAcceleration_mps2','saturationMargin_mps2'});

for k = 1:numel(times)
    a = auditFormationSampledStep(cfg,times(k));
    T.time_s(k) = a.time;
    T.sampleTime_s(k) = a.sampleTime;
    T.maxControllerResidual(k) = a.maxControllerResidual;
    T.maxStateResidual(k) = a.maxStateResidual;
    T.maxLegacyLeaderApproxResidual(k) = ...
        a.maxLegacyLeaderApproxResidual;
    T.maxFollowerAcceleration_mps2(k) = a.maxFollowerAcceleration;
    T.saturationMargin_mps2(k) = a.saturationMargin;

    assert(a.unsaturated,'Gate1: audit fixture entered saturation.');
    assert(a.maxControllerResidual < 1e-12, ...
        'Gate1: controller equation mismatch at t=%g.',times(k));
    assert(a.maxStateResidual < 1e-12, ...
        'Gate1: sampled state equation mismatch at t=%g.',times(k));
end

assert(any(T.maxLegacyLeaderApproxResidual > 1e-12), ...
    'Gate1: analytical-leader correction was not exercised.');

writetable(T,fullfile(R.dir,'one_step_audit.csv'));
writematrix(cert.Hp,fullfile(R.dir,'Hp.csv'));
writematrix(cert.Hv,fullfile(R.dir,'Hv.csv'));
writematrix(cert.sampledAcl,fullfile(R.dir,'Ah.csv'));
writematrix(cert.sampledInputMatrix,fullfile(R.dir,'Dh.csv'));

model = struct();
model.schemaVersion = 1;
model.gate = 1;
model.status = 'PASS';
model.scope = 'unsaturated exact-state double-integrator subsystem';
model.seed = cfg.seed;
model.networkSeed = cfg.net.seed;
model.sampleTime_s = cfg.swarm.dt;
model.swarmSize = cfg.swarm.N;
model.controller = struct( ...
    'Kp',cfg.swarm.Kp,'Kv',cfg.swarm.Kv, ...
    'KpLeader',cfg.swarm.KpLeader,'KvLeader',cfg.swarm.KvLeader, ...
    'maxCommandedAcceleration_mps2',cfg.swarm.maxAccel, ...
    'degreeNormalization',false);
model.adjacency = cfg.swarm.A;
model.pin = cfg.swarm.pin;
model.offsets = cfg.swarm.offsets;
model.plantStateMatrix = cert.plantStateMatrix;
model.plantInputMatrix = cert.plantInputMatrix;
model.Hp = cert.Hp;
model.Hv = cert.Hv;
model.Ah = cert.sampledAcl;
model.Dh = cert.sampledInputMatrix;
model.sampledSpectralRadius = cert.sampledSpectralRadius;
model.sampledSchur = cert.isSchur;
model.primarySymmetricTheoremApplicable = cert.primaryTheoremApplicable;
model.maxSpeedConfigured_mps = cfg.swarm.maxSpeed;
model.maxSpeedEnforced = cert.maxSpeedIsEnforced;
model.oneStepAudit = table2struct(T);
model.proofGaps = { ...
    '6-DOF cascade is outside the sampled LTI identity', ...
    'acceleration saturation is outside the linear closed-loop matrix', ...
    'directed and switching graphs lack the symmetric proof', ...
    'existing generic sampled ISS constants are numerically too loose'};

fid = fopen(fullfile(R.dir,'model.json'),'w');
assert(fid > 0,'Gate1: cannot create model.json.');
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(model,'PrettyPrint',true));
clear cleaner;

fprintf('Gate 1 exact sampled model: PASS\n');
fprintf('  rho(Ah)                    : %.12f\n',cert.sampledSpectralRadius);
fprintf('  max controller residual    : %.3e\n',max(T.maxControllerResidual));
fprintf('  max exact state residual   : %.3e\n',max(T.maxStateResidual));
fprintf('  legacy leader residual seen: %.3e\n', ...
    max(T.maxLegacyLeaderApproxResidual));
fprintf('  maxSpeed enforced          : no\n');

save(fullfile(R.dir,'workspace.mat'),'cfg','cert','T','model');
finishExperiment(R);
