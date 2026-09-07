function V = tcnsCausalOneShotLinkValue( ...
    currentPos,currentVel,currentAcc,ackPayload,outstanding,currentTime, ...
    positionGain,velocityGain,accelerationGain,receiverId,cfg,horizonSamples)
%TCNSCAUSALONESHOTLINKVALUE Expected isolated value of one new DATA action.
%
% Uses tcnsCausalReceiverBelief to predict which payload the receiver would
% hold when a new transmission arrives. Existing outstanding packets are in
% that distribution, so their expected value is subtracted automatically.
% The returned score is exact only for the isolated unsaturated continuation
% stated in paper/tcns/CAUSAL_VOI_BELIEF_CHECKPOINT.md.

currentPos = localVector(currentPos,'currentPos');
currentVel = localVector(currentVel,'currentVel');
if isempty(currentAcc)
    currentAcc = zeros(1,3);
else
    currentAcc = localVector(currentAcc,'currentAcc');
end
validateattributes(positionGain,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'positionGain',7);
validateattributes(velocityGain,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'velocityGain',8);
validateattributes(accelerationGain,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'accelerationGain',9);
validateattributes(receiverId,{'numeric'}, ...
    {'real','finite','integer','scalar'},mfilename,'receiverId',10);
validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',12);

np = netParamsAt(cfg,currentTime);
h = cfg.swarm.dt;
dataDelaySteps = max(0,ceil((np.delay-1e-12)/h));
arrivalTime = currentTime+dataDelaySteps*h;
belief = tcnsCausalReceiverBelief( ...
    ackPayload,outstanding,currentTime,arrivalTime,cfg);

certificate = formationTheoryCertificate(cfg);
fi = find(certificate.followers==receiverId,1);
if isempty(fi)
    error('tcnsCausalOneShotLinkValue:Receiver', ...
        'receiverId must identify a follower in the theorem model.');
end
kernel = tcnsFiniteHorizonLinkValueKernel( ...
    cfg,horizonSamples,dataDelaySteps);

candidateAcc = belief.candidateAcc;
if accelerationGain==0
    candidateAcc = zeros(size(candidateAcc));
elseif any(~isfinite(candidateAcc),'all')
    error('tcnsCausalOneShotLinkValue:MissingAcceleration', ...
        'Finite candidate acceleration is required for a nonzero gain.');
end

correction = positionGain*(currentPos-belief.candidatePos) + ...
    velocityGain*(currentVel-belief.candidateVel) + ...
    accelerationGain*(currentAcc-candidateAcc);
correctionSquared = sum(correction.^2,2);
expectedCorrectionSquared = ...
    sum(belief.probability.*correctionSquared);
newActionSuccess = 1-np.packetLoss;
score = newActionSuccess*kernel.positionMseGain(fi) * ...
    expectedCorrectionSquared;

ackCorrectionSquared = correctionSquared(1);
if ackCorrectionSquared>0
    inFlightDiscount = expectedCorrectionSquared/ackCorrectionSquared;
else
    inFlightDiscount = NaN;
end

V.score = score;
V.expectedCorrectionSquared = expectedCorrectionSquared;
V.ackOnlyCorrectionSquared = ackCorrectionSquared;
V.inFlightDiscount = inFlightDiscount;
V.newActionSuccessProbability = newActionSuccess;
V.receiverId = receiverId;
V.receiverFollowerIndex = fi;
V.positionMseGain = kernel.positionMseGain(fi);
V.horizonSamples = horizonSamples;
V.dataDelaySamples = dataDelaySteps;
V.belief = belief;
V.usesReceiverTruth = false;
V.usesDropOutcome = false;
V.onlineInformationCausal = true;
V.totalClosedLoopValueCertified = false;
V.interpretation = [ ...
    'Expected isolated finite-horizon position-MSE separation removed by ' ...
    'one action, after crediting existing outstanding candidates.'];

end


function x = localVector(x,label)

x = double(x(:)');
if numel(x)~=3 || any(~isfinite(x))
    error('tcnsCausalOneShotLinkValue:InvalidVector', ...
        '%s must be a finite three-vector.',label);
end

end
