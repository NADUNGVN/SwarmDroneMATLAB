%% TEST_TCNS_LOCAL_VOI_IDENTIFIABILITY Exact cross-term witness contracts.

startup;

fprintf('\n=== TCNS local-VoI identifiability checks ===\n\n');

cfg = defaultConfig();
H = 25;
D = 4;
receiverId = 3;
correction = [0.7 -0.2 0.5];
W = tcnsLocalVoiIdentifiabilityWitness( ...
    cfg,H,D,receiverId,correction);

K = tcnsFiniteHorizonLinkValueKernel(cfg,H,D);
fi = find(K.followers==receiverId,1);
expectedEnergy = K.positionEnergyGain(fi)*sum(correction.^2);
scale = max(1,expectedEnergy);

assert(abs(W.responseEnergy-expectedEnergy)<1e-13*scale, ...
    'LocalVoI: witness response does not match the exact Gate-3 kernel.');
assert(abs(W.helpfulBenefit-expectedEnergy)<1e-13*scale, ...
    'LocalVoI: z=-g did not produce benefit +||g||^2.');
assert(abs(W.harmfulBenefit+3*expectedEnergy)<1e-13*scale, ...
    'LocalVoI: z=+g did not produce benefit -3||g||^2.');
assert(abs(W.helpfulCrossTerm+expectedEnergy)<1e-13*scale && ...
    abs(W.harmfulCrossTerm-expectedEnergy)<1e-13*scale, ...
    'LocalVoI: witness cross terms are inconsistent.');
assert(W.benefitSignChanges && ~W.actualTrajectoryReachabilityProved, ...
    'LocalVoI: sign ambiguity or proof-gap metadata was lost.');

rejectedZero = false;
try
    tcnsLocalVoiIdentifiabilityWitness(cfg,H,D,receiverId,[0 0 0]);
catch err
    rejectedZero = strcmp(err.identifier, ...
        'tcnsLocalVoiIdentifiabilityWitness:ZeroResponse');
end
assert(rejectedZero, ...
    'LocalVoI: a zero action response was accepted as a sign witness.');

rejectedOutsideHorizon = false;
try
    tcnsLocalVoiIdentifiabilityWitness( ...
        cfg,H,H,receiverId,correction);
catch err
    rejectedOutsideHorizon = strcmp(err.identifier, ...
        'tcnsLocalVoiIdentifiabilityWitness:ZeroResponse');
end
assert(rejectedOutsideHorizon, ...
    'LocalVoI: an action outside the horizon produced a sign witness.');

fprintf('  exact action-response energy                %.9g\n', ...
    W.responseEnergy);
fprintf('  benefit for hidden baseline z=-g            %+.9g\n', ...
    W.helpfulBenefit);
fprintf('  benefit for hidden baseline z=+g            %+.9g\n', ...
    W.harmfulBenefit);
fprintf('  actual-trajectory reachability              PROOF GAP\n');
fprintf('test_tcns_local_voi_identifiability: PASS\n');
