%% TEST_TCNS_INFORMATION_LIMITS Exact affine/information theorem contracts.

startup;
fprintf('\n=== TCNS information-structure limits checks ===\n\n');

[cfg,~] = tcnsGate6Scenario(27020001,'S1');
H = 25;
D = 4;
model = tcnsInformationLimitsModel(cfg,H,D,0);
assert(model.nAxis==33 && model.nState==99 && ...
    model.nOrdinaryLinks==8 && model.nPinnedLinks==2, ...
    'InformationLimits: frozen N=5 augmented-state dimensions drifted.');

leader.pos = [0.1;-0.2;1.0];
leader.vel = [0.05;-0.02;0.01];
leader.acc = zeros(3,1);
P = leader.pos'+cfg.swarm.offsets;
V = repmat(leader.vel',cfg.swarm.N,1);
P(3,:) = P(3,:)+[0.02 -0.01 0.005];
V(4,:) = V(4,:)+[0.01 0.005 -0.004];
net = initQueuedNetworkState(P,V,leader,cfg);
net.Pij(5,1,:) = reshape(P(1,:)-[0.1 -0.03 0.02],1,1,3);
net.Vij(5,1,:) = reshape(V(1,:)-[0.01 0.02 -0.01],1,1,3);
state = tcnsInformationLimitsState(model,P,V,leader,net);
oracle = tcnsCentralizedStateOracleValue(P,V,leader,net,0,cfg,H);
baseline = localVectorizeResponse(oracle.baselineResponse);
assert(norm(baseline-(model.F*state.xi+model.r),inf)<1e-12, ...
    'InformationLimits: F_H*xi+r_H does not reproduce O1.');

i = 5; j = 1;
heldP = reshape(net.Pij(i,j,:),1,3);
heldV = reshape(net.Vij(i,j,:),1,3);
fi = find(model.followers==i,1);
correction = cfg.swarm.Kp*model.certificate.degreeScale(fi)*(P(j,:)-heldP) + ...
    cfg.swarm.Kv*model.certificate.degreeScale(fi)*(V(j,:)-heldV);
payload.pos = heldP;
payload.vel = heldV;
action = tcnsInformationLimitsActionMap( ...
    model,'ordinary',i,j,correction,payload);
x = state.xi(action.keepIndex);
assert(abs(action.valueCoefficient'*x+action.valueConstant- ...
    oracle.ordinaryValue(i,j))<1e-12, ...
    'InformationLimits: affine action value does not reproduce O1.');

sender = tcnsInformationLimitsSenderMap(model,j,action,2);
ell0 = (sender.reducedDynamics^2)'*action.crossTermCoefficient;
ident = tcnsLinearIdentifiability(sender.historyMap,ell0);
assert(~ident.identifiable && ident.rowSpaceResidual>0 && ...
    ident.nullWitnessInformationResidual<1e-10 && ...
    ident.nullWitnessValueChange>0, ...
    'InformationLimits: row/null-space witness contract failed.');
augmented = tcnsLinearIdentifiability( ...
    [sender.historyMap;ident.missingCoefficient'],ell0);
assert(augmented.identifiable, ...
    'InformationLimits: one missing scalar did not close identifiability.');

ordinary = tcnsInformationLimitsDynamicWitness( ...
    cfg,H,D,'ordinary',5,1);
pin = tcnsInformationLimitsDynamicWitness( ...
    cfg,H,D,'pinned-leader',4,1);
assert(ordinary.dynamicallyReachable && pin.dynamicallyReachable, ...
    'InformationLimits: preregistered dynamic sign witnesses failed.');

fprintf('  baseline affine residual                  %.3e\n', ...
    norm(baseline-(model.F*state.xi+model.r),inf));
fprintf('  ordinary dynamic q-/q+                    %+.3e / %+.3e\n', ...
    ordinary.minus.expectedValue,ordinary.plus.expectedValue);
fprintf('  pin dynamic q-/q+                         %+.3e / %+.3e\n', ...
    pin.minus.expectedValue,pin.plus.expectedValue);
fprintf('test_tcns_information_limits: PASS\n');


function value = localVectorizeResponse(response)
value = [];
for axis = 1:3
    value = [value;reshape(response(:,:,axis).',[],1)]; %#ok<AGROW>
end
end
