%% TEST_TCNS_GATE3_ROBUSTNESS_BOUND Structured ISS and real-step contracts.

startup;

fprintf('\n=== TCNS Gate-3 robustness-bound checks ===\n\n');

cfg = defaultConfig();
cfg.sixdof.enable = false;
certificate = tcnsFormationRobustnessCertificate(cfg);

assert(certificate.blockContraction<1 && ...
    certificate.blockContraction<=certificate.blockTarget, ...
    'Gate3: no valid contracting matrix-power block was certified.');
assert(all(certificate.unitInputPositionUltimateBound>0) && ...
    all(certificate.unitInputPositionUltimateBound<10), ...
    'Gate3: structured position gain is invalid or numerically useless.');
assert(certificate.legacyLyapunovInputGain>1e3, ...
    'Gate3: the test no longer distinguishes the legacy loose certificate.');

candidate = struct('genTime',0.1,'seq',1,'pos',[1 0 0], ...
    'vel',[0.5 0 0],'acc',[0.2 0 0],'dropped',false);
setA = causalReceiverStateSetBound([2 0 0],[1 0 0],[0 0 0],[0 0 0], ...
    candidate,[0.4 0 0],[0 0 0]);
candidate.dropped = true;
setB = causalReceiverStateSetBound([2 0 0],[1 0 0],[0 0 0],[0 0 0], ...
    candidate,[0.4 0 0],[0 0 0]);
assert(setA.position==2 && setA.velocity==1 && ...
    abs(setA.acceleration-0.4)<1e-14 && setA.candidateCount==2, ...
    'Gate3: causal receiver information-set maximum is incorrect.');
assert(isequaln(setA,setB) && ~setA.usesDropOutcome, ...
    'Gate3: causal set bound used the oracle forward-drop flag.');

m = cfg.swarm.N-1;
beta = reshape(1:20,5,m)/20;
finite = tcnsFiniteHorizonFormationBound(cfg,beta);
A = certificate.Ah;
B = certificate.Bc;
expected2 = abs(B)*beta(1,:)';
expected3 = abs(A*B)*beta(1,:)' + abs(B)*beta(2,:)';
assert(norm(finite.blockNormBound(2,:)'-expected2)<1e-14 && ...
    norm(finite.blockNormBound(3,:)'-expected3)<1e-14, ...
    'Gate3: finite-horizon convolution indexing is incorrect.');

sc = exp10Scenarios();
points = exp10Points();
pt = points(strcmp({points.id},'NOMINAL'));
cfg = applyExp10Point(pt,sc.STRESSED,27020001);
cfg.sixdof.enable = false;
cfg.swarm.T = 10;
cfg.tcns.logReceiverState = true;
cfgNoSet = cfg;
outNoSet = simSwarmAoICausal(cfgNoSet);
cfg.tcns.logCausalSetBound = true;
out = simSwarmAoICausal(cfg);

coreFields = {'P','V','A','neighborAoI','estimatedAoI','txCountLog', ...
    'ackCountLog','broadcastCountLog','txCount','ackTxCount','dropCount'};
for f = 1:numel(coreFields)
    name = coreFields{f};
    assert(isequaln(out.(name),outNoSet.(name)), ...
        'Gate3: passive causal-set logging changed core field %s.',name);
end

D = tcnsCommunicationDisturbanceBound(out,cfg);
assert(all(D.coverage(:)), ...
    'Gate3: communication disturbance exceeded the Gate-2-derived budget.');
assert(all(D.causalSetCoverage(:)), ...
    'Gate3: actual receiver state escaped the causal sender information set.');

Kfull = numel(out.t);
N = cfg.swarm.N;
maxSetViolation = -inf;
for i = 2:N
    for j = 1:N
        if cfg.swarm.A(i,j)==0
            continue;
        end
        heldP = reshape(out.receiverNeighborPosition(:,i,j,:),Kfull,3);
        heldV = reshape(out.receiverNeighborVelocity(:,i,j,:),Kfull,3);
        if j==1
            trueP = out.LeaderPos;
            trueV = out.LeaderVel;
        else
            trueP = reshape(out.P(:,j,:),Kfull,3);
            trueV = reshape(out.V(:,j,:),Kfull,3);
        end
        actualP = vecnorm(trueP-heldP,2,2);
        actualV = vecnorm(trueV-heldV,2,2);
        boundP = reshape(out.senderSetPositionBound(:,i,j),Kfull,1);
        boundV = reshape(out.senderSetVelocityBound(:,i,j),Kfull,1);
        maxSetViolation = max(maxSetViolation,max([ ...
            actualP-boundP; actualV-boundV]));
    end

    if cfg.swarm.pin(i)
        heldP = reshape(out.receiverLeaderPosition(:,i,:),Kfull,3);
        heldV = reshape(out.receiverLeaderVelocity(:,i,:),Kfull,3);
        heldA = reshape(out.receiverLeaderAcceleration(:,i,:),Kfull,3);
        trueA = reshape(out.A(:,1,:),Kfull,3);
        actualP = vecnorm(out.LeaderPos-heldP,2,2);
        actualV = vecnorm(out.LeaderVel-heldV,2,2);
        actualA = vecnorm(trueA-heldA,2,2);
        boundP = reshape(out.senderLeaderSetPositionBound(:,i),Kfull,1);
        boundV = reshape(out.senderLeaderSetVelocityBound(:,i),Kfull,1);
        boundA = reshape(out.senderLeaderSetAccelerationBound(:,i),Kfull,1);
        maxSetViolation = max(maxSetViolation,max([ ...
            actualP-boundP; actualV-boundV; actualA-boundA]));
    end
end
assert(maxSetViolation<2e-12, ...
    'Gate3: a receiver payload was outside the causal sender set.');

startIndex = find(out.t>=8,1,'first');
ideal = tcnsPerfectInformationContinuation(out,cfg,startIndex);
assert(ideal.initialStateCopiedExactly, ...
    'Gate3: perfect-information continuation did not share its initial state.');

actualAcceleration = vecnorm(reshape( ...
    out.A(startIndex:end,2:end,:),[],3),2,2);
assert(max(actualAcceleration)<cfg.swarm.maxAccel-1e-6 && ...
    ideal.maxFollowerAcceleration<cfg.swarm.maxAccel-1e-6, ...
    'Gate3: real-step identity fixture entered acceleration saturation.');

K = numel(ideal.t);
h = cfg.swarm.dt;
A = formationTheoryCertificate(cfg).sampledAcl;
B = h^2*[eye(m);eye(m)];
maxRecurrenceResidual = 0;

for k = 1:K-1
    globalIndex = startIndex+k-1;
    actualP = reshape(out.P(globalIndex,2:end,:),m,3);
    actualV = reshape(out.V(globalIndex,2:end,:),m,3);
    idealP = reshape(ideal.P(k,2:end,:),m,3);
    idealV = reshape(ideal.V(k,2:end,:),m,3);
    actualPNext = reshape(out.P(globalIndex+1,2:end,:),m,3);
    actualVNext = reshape(out.V(globalIndex+1,2:end,:),m,3);
    idealPNext = reshape(ideal.P(k+1,2:end,:),m,3);
    idealVNext = reshape(ideal.V(k+1,2:end,:),m,3);
    dc = reshape(D.actual(globalIndex,:,:),m,3);

    for axis = 1:3
        y = [actualP(:,axis)-idealP(:,axis); ...
            h*(actualV(:,axis)-idealV(:,axis))];
        yNext = [actualPNext(:,axis)-idealPNext(:,axis); ...
            h*(actualVNext(:,axis)-idealVNext(:,axis))];
        predicted = A*y+B*dc(:,axis);
        maxRecurrenceResidual = max(maxRecurrenceResidual, ...
            norm(yNext-predicted,inf));
    end
end

assert(maxRecurrenceResidual<2e-12, ...
    'Gate3: stale-versus-perfect degradation recurrence is not exact.');

F = tcnsFiniteHorizonFormationBound(cfg,D.bound(startIndex:end,:));
actualPositionDegradation = zeros(K,m);
actualScaledVelocityDegradation = zeros(K,m);
for k = 1:K
    dP = reshape(out.P(startIndex+k-1,2:end,:),m,3) - ...
        reshape(ideal.P(k,2:end,:),m,3);
    dV = reshape(out.V(startIndex+k-1,2:end,:),m,3) - ...
        reshape(ideal.V(k,2:end,:),m,3);
    actualPositionDegradation(k,:) = vecnorm(dP,2,2)';
    actualScaledVelocityDegradation(k,:) = h*vecnorm(dV,2,2)';
end

maxFiniteViolation = max([ ...
    actualPositionDegradation-F.position; ...
    actualScaledVelocityDegradation-F.scaledVelocity],[], 'all');
assert(maxFiniteViolation<2e-12, ...
    'Gate3: real trajectory violated the structured finite-horizon bound.');

fprintf('  block length / contraction                 %d / %.3e\n', ...
    certificate.blockLength,certificate.blockContraction);
fprintf('  max unit-input position UUB [m/(m/s^2)]   %.4f\n', ...
    max(certificate.unitInputPositionUltimateBound));
fprintf('  real recurrence residual                   %.3e\n', ...
    maxRecurrenceResidual);
fprintf('  real finite-bound violation                %.3e\n', ...
    maxFiniteViolation);
fprintf('  causal set-containment violation           %.3e\n', ...
    maxSetViolation);
