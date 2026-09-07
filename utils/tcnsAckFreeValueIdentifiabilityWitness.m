function W = tcnsAckFreeValueIdentifiabilityWitness( ...
    cfg,horizonSamples,delaySamples,receiverId,probability,corrections)
%TCNSACKFREEVALUEIDENTIFIABILITYWITNESS Belief-value cross-term witness.
%
% Given one exact packet-memory PMF and its candidate command corrections,
% construct each exact Gate-3 action response G_s. The two hidden baseline
% families Z_s=-G_s and Z_s=+G_s preserve the same PMF and action responses,
% but reverse the sign of the expected quadratic action value.
%
% This is an algebraic output-space witness. It does not claim that both
% complete hidden baseline families are reachable from every physical swarm
% history; that unresolved reachability statement is recorded in metadata.

validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',2);
validateattributes(delaySamples,{'numeric'}, ...
    {'real','finite','integer','nonnegative','scalar'}, ...
    mfilename,'delaySamples',3);
validateattributes(receiverId,{'numeric'}, ...
    {'real','finite','integer','scalar'},mfilename,'receiverId',4);
probability = double(probability(:));
corrections = double(corrections);
if size(corrections,1)~=numel(probability) || size(corrections,2)~=3 || ...
        any(~isfinite(corrections),'all') || any(~isfinite(probability)) || ...
        any(probability<0) || abs(sum(probability)-1)>1e-12
    error('tcnsAckFreeValueIdentifiabilityWitness:Input', ...
        'Probabilities and N-by-3 candidate corrections are required.');
end

kernel = tcnsFiniteHorizonLinkValueKernel( ...
    cfg,horizonSamples,delaySamples);
followerIndex = find(kernel.followers==receiverId,1);
if isempty(followerIndex)
    error('tcnsAckFreeValueIdentifiabilityWitness:Receiver', ...
        'receiverId must identify a Gate-3 follower.');
end
m = numel(kernel.followers);
np = netParamsAt(cfg,0);
successProbability = 1-np.packetLoss;
scalarResponse = reshape( ...
    kernel.positionResponse(:,:,followerIndex),horizonSamples,m);
n = numel(probability);
actionResponses = zeros(horizonSamples,m,3,n);
energy = zeros(n,1);
helpfulCandidateValue = zeros(n,1);
harmfulCandidateValue = zeros(n,1);
maxDirectResidual = 0;
for s = 1:n
    G = scalarResponse.*reshape(corrections(s,:),1,1,3);
    actionResponses(:,:,:,s) = G;
    energy(s) = sum(G.^2,'all');
    helpfulBaseline = -G;
    harmfulBaseline = G;
    helpfulCandidateValue(s) = successProbability/m*localBenefit( ...
        helpfulBaseline,G);
    harmfulCandidateValue(s) = successProbability/m*localBenefit( ...
        harmfulBaseline,G);
    maxDirectResidual = max(maxDirectResidual,max( ...
        abs(helpfulCandidateValue(s)-successProbability/m*energy(s)), ...
        abs(harmfulCandidateValue(s)+3*successProbability/m*energy(s))));
end

knownIsolatedTerm = successProbability/m*sum(probability.*energy);
helpfulExpectedValue = sum(probability.*helpfulCandidateValue);
harmfulExpectedValue = sum(probability.*harmfulCandidateValue);
if knownIsolatedTerm<=0
    error('tcnsAckFreeValueIdentifiabilityWitness:ZeroResponse', ...
        'At least one positive-probability response must be nonzero.');
end

W.probability = probability;
W.corrections = corrections;
W.actionResponses = actionResponses;
W.candidateResponseEnergy = energy;
W.knownExpectedIsolatedTerm = knownIsolatedTerm;
W.helpfulCandidateValue = helpfulCandidateValue;
W.harmfulCandidateValue = harmfulCandidateValue;
W.helpfulExpectedValue = helpfulExpectedValue;
W.harmfulExpectedValue = harmfulExpectedValue;
W.expectedValueSignChanges = ...
    helpfulExpectedValue>0 && harmfulExpectedValue<0;
W.helpfulToIsolatedRatio = helpfulExpectedValue/knownIsolatedTerm;
W.harmfulToIsolatedRatio = harmfulExpectedValue/knownIsolatedTerm;
W.maxDirectIdentityResidual = maxDirectResidual;
W.sameBeliefAndActionResponseFamily = true;
W.requiresHiddenBaselineProjection = true;
W.actualTrajectoryReachabilityProved = false;
W.usesReceiverTruth = false;
W.usesFutureChannelOutcome = false;
W.interpretation = [ ...
    'The ACK-free packet-memory PMF and candidate action responses identify ' ...
    'the isolated term, but not the expected baseline/action cross term; ' ...
    'therefore they do not identify the exact Gate-3 expected-value sign.'];

end


function value = localBenefit(baseline,actionResponse)

value = sum(baseline.^2,'all') - ...
    sum((baseline+actionResponse).^2,'all');

end

