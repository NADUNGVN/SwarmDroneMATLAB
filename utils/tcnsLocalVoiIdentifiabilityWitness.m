function W = tcnsLocalVoiIdentifiabilityWitness( ...
    cfg,horizonSamples,delaySamples,receiverId,commandCorrection)
%TCNSLOCALVOIIDENTIFIABILITYWITNESS Exact quadratic-value sign witness.
%
%   W = tcnsLocalVoiIdentifiabilityWitness(cfg,H,D,i,c)
%
% Uses the exact Gate-3 unsaturated degradation recurrence to construct the
% stacked follower-position response g caused by one persistent command
% correction c at follower receiver i after D samples. For a no-action
% baseline response z, the quadratic benefit of the action is
%
%   ||z||^2 - ||z+g||^2 = -2*z'*g - ||g||^2.
%
% The two hidden baselines z=-g and z=+g retain the same locally known
% action response but give benefits +||g||^2 and -3||g||^2. This is an
% algebraic/model-input witness. It does not assert that both baselines are
% reachable from every physical swarm state; see the associated proof gap.

validateattributes(receiverId,{'numeric'}, ...
    {'real','finite','integer','scalar'},mfilename,'receiverId',4);
commandCorrection = double(commandCorrection(:)');
if numel(commandCorrection)~=3 || any(~isfinite(commandCorrection))
    error('tcnsLocalVoiIdentifiabilityWitness:Correction', ...
        'commandCorrection must be a finite three-vector.');
end
if norm(commandCorrection)==0
    error('tcnsLocalVoiIdentifiabilityWitness:ZeroResponse', ...
        'A nonzero commandCorrection is required for a sign witness.');
end

kernel = tcnsFiniteHorizonLinkValueKernel( ...
    cfg,horizonSamples,delaySamples);
followerIndex = find(kernel.followers==receiverId,1);
if isempty(followerIndex)
    error('tcnsLocalVoiIdentifiabilityWitness:Receiver', ...
        'receiverId must identify a follower in the theorem model.');
end

m = numel(kernel.followers);
scalarResponse = reshape( ...
    kernel.positionResponse(:,:,followerIndex),horizonSamples,m);
actionResponse = scalarResponse .* ...
    reshape(commandCorrection,1,1,3);
responseEnergy = sum(actionResponse.^2,'all');
if responseEnergy==0
    error('tcnsLocalVoiIdentifiabilityWitness:ZeroResponse', ...
        'The selected delay leaves no nonzero response inside the horizon.');
end

helpfulBaseline = -actionResponse;
harmfulBaseline = actionResponse;
helpfulBenefit = localBenefit(helpfulBaseline,actionResponse);
harmfulBenefit = localBenefit(harmfulBaseline,actionResponse);

W.scope = [ ...
    'exact Gate-3 fixed symmetric grounded, exact-state, unsaturated ' ...
    'double-integrator output model'];
W.receiverId = receiverId;
W.receiverFollowerIndex = followerIndex;
W.horizonSamples = horizonSamples;
W.delaySamples = delaySamples;
W.commandCorrection = commandCorrection;
W.actionResponse = actionResponse;
W.responseEnergy = responseEnergy;
W.helpfulBaseline = helpfulBaseline;
W.harmfulBaseline = harmfulBaseline;
W.helpfulCrossTerm = sum(helpfulBaseline.*actionResponse,'all');
W.harmfulCrossTerm = sum(harmfulBaseline.*actionResponse,'all');
W.helpfulBenefit = helpfulBenefit;
W.harmfulBenefit = harmfulBenefit;
W.benefitSignChanges = helpfulBenefit>0 && harmfulBenefit<0;
W.signThreshold = -0.5*responseEnergy;
W.actualTrajectoryReachabilityProved = false;
W.interpretation = [ ...
    'The local action-response energy alone cannot determine total ' ...
    'quadratic marginal-benefit sign when the hidden baseline-response ' ...
    'projection can cross -||g||^2/2.'];

end


function value = localBenefit(baseline,actionResponse)

value = sum(baseline.^2,'all') - ...
    sum((baseline+actionResponse).^2,'all');

end
