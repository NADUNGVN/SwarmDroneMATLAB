%% TEST_TCNS_GATE2_STALENESS_BOUND Gate-2 formula and passive-log contracts.

startup;

fprintf('\n=== TCNS Gate-2 staleness-bound checks ===\n\n');

h = 0.02;
B = tcnsZohStalenessBound(3*h,2.0,2.0,h);
assert(B.sampleCount==3,'Gate2: incorrect sample-age conversion.');
assert(abs(B.velocity-0.12)<1e-14, ...
    'Gate2: incorrect velocity envelope formula.');
assert(abs(B.position-0.1248)<1e-14, ...
    'Gate2: incorrect semi-implicit position envelope formula.');

Bpayload = tcnsZohStalenessBound(3*h,2.0,2.0,h,0.01,0.03);
assert(abs(Bpayload.velocity-0.15)<1e-14, ...
    'Gate2: payload velocity uncertainty was not propagated.');
assert(abs(Bpayload.position-(0.01+3*h*2.03+0.0048))<1e-14, ...
    'Gate2: payload position uncertainty was not propagated.');

offGridRefused = false;
try
    tcnsZohStalenessBound(0.031,1,2,h);
catch err
    offGridRefused = strcmp(err.identifier, ...
        'tcnsZohStalenessBound:OffGridAge');
end
assert(offGridRefused,'Gate2: an off-grid age was silently rounded.');

leaderCases = [1.0 2.0; 2.98 3.0; 3.0 4.0];
for c = 1:size(leaderCases,1)
    generationTime = leaderCases(c,1);
    currentTime = leaderCases(c,2);
    generated = leaderReference(generationTime);
    current = leaderReference(currentTime);
    leaderBound = tcnsLeaderStalenessBound(generationTime,currentTime);
    assert(norm(current.pos-generated.pos)<=leaderBound.position+1e-12, ...
        'Gate2: analytical leader position violated its envelope.');
    assert(norm(current.vel-generated.vel)<=leaderBound.velocity+1e-12, ...
        'Gate2: analytical leader velocity violated its envelope.');
    assert(norm(current.acc-generated.acc)<=leaderBound.acceleration+1e-12, ...
        'Gate2: analytical leader acceleration violated its envelope.');
end
crossingBound = tcnsLeaderStalenessBound(2.98,3.0);
assert(crossingBound.crossesSwitch && crossingBound.velocity>=0.2, ...
    'Gate2: leader switch jump was omitted from the bound.');

cfg = defaultConfig();
cfg.swarm.T = 0.60;
cfg.sixdof.enable = false;
cfg.ack.assertInvariants = true;

outDefault = simSwarmAoICausal(cfg);

cfgFalse = cfg;
cfgFalse.tcns.logReceiverState = false;
outFalse = simSwarmAoICausal(cfgFalse);

assert(isequaln(outDefault,outFalse), ...
    'Gate2: an explicitly disabled diagnostic changed simulator output.');
assert(~isfield(outFalse,'receiverNeighborPosition'), ...
    'Gate2: default-off receiver diagnostics leaked into normal output.');

cfgTrue = cfg;
cfgTrue.tcns.logReceiverState = true;
out = simSwarmAoICausal(cfgTrue);

coreFields = {'P','V','A','neighborAoI','estimatedAoI','txCountLog', ...
    'ackCountLog','broadcastCountLog','txCount','ackTxCount', ...
    'dropCount','staleDiscardCount'};
for f = 1:numel(coreFields)
    name = coreFields{f};
    assert(isequaln(out.(name),outFalse.(name)), ...
        'Gate2: passive instrumentation changed core field %s.',name);
end

K = numel(out.t);
N = cfg.swarm.N;
assert(isequal(size(out.receiverNeighborPosition),[K N N 3]), ...
    'Gate2: receiver position log has the wrong shape.');
assert(isequal(size(out.receiverNeighborVelocity),[K N N 3]), ...
    'Gate2: receiver velocity log has the wrong shape.');
assert(isequal(size(out.receiverNeighborGenTime),[K N N]), ...
    'Gate2: receiver generation-time log has the wrong shape.');

tol = 2e-12;
maxPayloadResidual = 0;
maxAgeResidual = 0;
maxBoundViolation = -inf;
maxLeaderBoundViolation = -inf;

for k = 1:K
    for i = 2:N
        for j = 2:N
            if cfg.swarm.A(i,j)==0
                continue;
            end

            genTime = out.receiverNeighborGenTime(k,i,j);
            g = round(genTime/h)+1;
            heldP = reshape(out.receiverNeighborPosition(k,i,j,:),1,3);
            heldV = reshape(out.receiverNeighborVelocity(k,i,j,:),1,3);
            generatedP = reshape(out.P(g,j,:),1,3);
            generatedV = reshape(out.V(g,j,:),1,3);
            maxPayloadResidual = max(maxPayloadResidual, ...
                max(abs([heldP-generatedP heldV-generatedV])));

            physicalAge = out.t(k)-genTime;
            loggedAge = out.neighborAoI(k,i,j);
            maxAgeResidual = max(maxAgeResidual, ...
                abs(loggedAge-(physicalAge+h/2)));

            bound = tcnsZohStalenessBound(physicalAge,norm(heldV), ...
                cfg.swarm.maxAccel,h);
            actualP = norm(reshape(out.P(k,j,:),1,3)-heldP);
            actualV = norm(reshape(out.V(k,j,:),1,3)-heldV);
            maxBoundViolation = max(maxBoundViolation, ...
                max([actualP-bound.position actualV-bound.velocity]));
        end
    end
end

for k = 1:K
    for i = 2:N
        if cfg.swarm.A(i,1)~=0
            genTime = out.receiverNeighborGenTime(k,i,1);
            heldP = reshape(out.receiverNeighborPosition(k,i,1,:),1,3);
            heldV = reshape(out.receiverNeighborVelocity(k,i,1,:),1,3);
            leaderBound = tcnsLeaderStalenessBound(genTime,out.t(k));
            actualP = norm(out.LeaderPos(k,:)-heldP);
            actualV = norm(out.LeaderVel(k,:)-heldV);
            maxLeaderBoundViolation = max(maxLeaderBoundViolation, ...
                max([actualP-leaderBound.position, ...
                actualV-leaderBound.velocity]));
        end

        if cfg.swarm.pin(i)
            genTime = out.receiverLeaderGenTime(k,i);
            heldP = reshape(out.receiverLeaderPosition(k,i,:),1,3);
            heldV = reshape(out.receiverLeaderVelocity(k,i,:),1,3);
            heldA = reshape(out.receiverLeaderAcceleration(k,i,:),1,3);
            leaderBound = tcnsLeaderStalenessBound(genTime,out.t(k));
            actualP = norm(out.LeaderPos(k,:)-heldP);
            actualV = norm(out.LeaderVel(k,:)-heldV);
            actualA = norm(reshape(out.A(k,1,:),1,3)-heldA);
            maxLeaderBoundViolation = max(maxLeaderBoundViolation, ...
                max([actualP-leaderBound.position, ...
                actualV-leaderBound.velocity, ...
                actualA-leaderBound.acceleration]));
        end
    end
end

assert(maxPayloadResidual<tol, ...
    'Gate2: held payload does not equal the state at its generation tick.');
assert(maxAgeResidual<tol, ...
    'Gate2: logged AoI is inconsistent with physical sample age + h/2.');
assert(maxBoundViolation<tol, ...
    'Gate2: an exact-state double-integrator trajectory violated the bound.');
assert(maxLeaderBoundViolation<tol, ...
    'Gate2: an analytical leader stream violated its dedicated bound.');

fprintf('  formula and off-grid refusal             PASS\n');
fprintf('  logging default-off / trajectory-inert    PASS\n');
fprintf('  payload-generation residual               %.3e\n',maxPayloadResidual);
fprintf('  AoI convention residual                   %.3e\n',maxAgeResidual);
fprintf('  maximum bound violation                   %.3e\n',maxBoundViolation);
fprintf('  maximum leader-bound violation            %.3e\n', ...
    maxLeaderBoundViolation);
