function out = finiteHorizonSafetyCertificate(cfg,motion,service,analysis)
%FINITEHORIZONSAFETYCERTIFICATE Conditional Study-2 separation certificate.
%
% This function combines four declared ingredients:
%   confirmed-age block tail -> semantic envelope -> LTI ISS -> separation.
% It never infers service or motion bounds from holdout. A positive result is
% conditional on protocol integrity, block minorization, bounded motion,
% common-information initialization and inactive acceleration saturation.
%
% motion fields:
%   maxVelocity                 scalar or N-vector [m/s]
%   maxAcceleration             scalar or N-vector [m/s^2]
%   maxLeaderAcceleration       scalar [m/s^2]
%   maxLeaderAccelEstimateError scalar [m/s^2], including ACK staleness and
%                                mismatch to interval-average leader accel
%
% service field:
%   qConfirmed                  end-to-end fresh confirmation lower bound
%
% analysis fields:
%   blockLength                 B [s]
%   failureRunLength            m, positive integer
%   horizon                     T [s]
%   evaluationStart             t_eval [s]
%   initialStateNorm            norm([e(0);h*r(0)]) [m]
%   safeDistance                required pairwise separation [m]
%   targetFailureProbability    alpha in (0,1)

requiredMotion = {'maxVelocity','maxAcceleration', ...
    'maxLeaderAcceleration','maxLeaderAccelEstimateError'};
requiredService = {'qConfirmed'};
requiredAnalysis = {'blockLength','failureRunLength','horizon', ...
    'evaluationStart','initialStateNorm','safeDistance', ...
    'targetFailureProbability'};
requireFields(motion,requiredMotion,'motion');
requireFields(service,requiredService,'service');
requireFields(analysis,requiredAnalysis,'analysis');

N = cfg.swarm.N;
vBar = expandNodeBound(motion.maxVelocity,N,'maxVelocity');
aBar = expandNodeBound(motion.maxAcceleration,N,'maxAcceleration');
validateNonnegativeScalar(motion.maxLeaderAcceleration, ...
    'maxLeaderAcceleration');
validateNonnegativeScalar(motion.maxLeaderAccelEstimateError, ...
    'maxLeaderAccelEstimateError');
validateProbability(service.qConfirmed,'qConfirmed',true);
validatePositiveScalar(analysis.blockLength,'blockLength');
validatePositiveScalar(analysis.horizon,'horizon');
validateNonnegativeScalar(analysis.evaluationStart,'evaluationStart');
validateNonnegativeScalar(analysis.initialStateNorm,'initialStateNorm');
validateNonnegativeScalar(analysis.safeDistance,'safeDistance');
validateProbability(analysis.targetFailureProbability, ...
    'targetFailureProbability',false);
if analysis.targetFailureProbability >= 1
    error(['finiteHorizonSafetyCertificate: targetFailureProbability ' ...
        'must be strictly less than one.']);
end
if analysis.evaluationStart > analysis.horizon
    error(['finiteHorizonSafetyCertificate: evaluationStart must not ' ...
        'exceed horizon.']);
end
m = analysis.failureRunLength;
if ~isscalar(m) || ~isfinite(m) || m < 1 || m ~= floor(m)
    error(['finiteHorizonSafetyCertificate: failureRunLength must be a ' ...
        'positive integer.']);
end

formation = formationTheoryCertificate(cfg);
if isempty(formation.lyapunovP)
    error(['finiteHorizonSafetyCertificate: the nominal formation matrix ' ...
        'has no Hurwitz Lyapunov certificate.']);
end
if isempty(formation.discreteLyapunovP)
    error(['finiteHorizonSafetyCertificate: the sampled semi-implicit ' ...
        'formation matrix has no Schur Lyapunov certificate.']);
end

B = analysis.blockLength;
ageCap = (m+1)*B;
positionEnvelope = vBar*ageCap + 0.5*aBar*ageCap^2;
velocityEnvelope = aBar*ageCap;

A = double(cfg.swarm.A ~= 0);
pin = double(cfg.swarm.pin(:) > 0);
followers = 2:N;
dFollower = zeros(N-1,1);
for row = 1:N-1
    i = followers(row);
    scale = formation.degreeScale(row);
    neighborPosition = sum(A(i,:).*positionEnvelope');
    neighborVelocity = sum(A(i,:).*velocityEnvelope');

    dFollower(row) = ...
        cfg.swarm.Kp*scale*neighborPosition ...
        + cfg.swarm.Kv*scale*neighborVelocity ...
        + pin(i)*cfg.swarm.KpLeader*positionEnvelope(1) ...
        + pin(i)*cfg.swarm.KvLeader*velocityEnvelope(1) ...
        + pin(i)*motion.maxLeaderAccelEstimateError ...
        + (1-pin(i))*motion.maxLeaderAcceleration;
end
disturbanceBound = norm(dFollower,2);

% The physical leader is reset from an analytic reference, while followers
% use semi-implicit Euler. For each follower,
% chi_k = h*v_L(t_{k+1})-[p_L(t_{k+1})-p_L(t_k)]. Bounded acceleration gives
% ||chi_k|| <= 0.5*aLbar*h^2.
h = formation.sampleTime;
leaderStepResidualPerFollower = ...
    0.5*motion.maxLeaderAcceleration*h^2;
leaderStepResidualBound = sqrt(N-1)*leaderStepResidualPerFollower;
accelerationStepIncrementBound = h^2*disturbanceBound;
sampledInputBound = hypot( ...
    leaderStepResidualBound,accelerationStepIncrementBound);

evaluationSteps = floor(analysis.evaluationStart/h + 1e-12);
transientBound = formation.discreteTransientGain ...
    * formation.discreteContractionFactor^evaluationSteps ...
    * analysis.initialStateNorm;
ultimateBound = formation.discreteInputGain*sampledInputBound;
formationRadiusBound = transientBound + ultimateBound;

desiredMin = formation.desiredMinSeparation;
safeRadius = (desiredMin-analysis.safeDistance)/sqrt(2);
geometryFeasible = safeRadius > 0;
deterministicCondition = formation.primaryTheoremApplicable ...
    && geometryFeasible && formationRadiusBound < safeRadius;

relevantLinkCount = nnz(A(2:end,:)) + nnz(pin(2:end));
blockCount = ceil(analysis.horizon/B);
failureWindowCount = max(0,blockCount-m+1);
unionFactor = relevantLinkCount*failureWindowCount;
ageViolationUpperBound = min(1, ...
    unionFactor*(1-service.qConfirmed)^m);

if unionFactor == 0
    requiredQ = 0;
else
    requiredQ = 1-(analysis.targetFailureProbability/unionFactor)^(1/m);
    requiredQ = min(1,max(0,requiredQ));
end

if deterministicCondition
    safetyFailureUpperBound = ageViolationUpperBound;
else
    safetyFailureUpperBound = 1;
end

out = struct();
out.conditional = true;
out.ageCap = ageCap;
out.positionEnvelope = positionEnvelope;
out.velocityEnvelope = velocityEnvelope;
out.followerDisturbanceBounds = dFollower;
out.disturbanceBound = disturbanceBound;
out.leaderStepResidualPerFollower = leaderStepResidualPerFollower;
out.leaderStepResidualBound = leaderStepResidualBound;
out.accelerationStepIncrementBound = accelerationStepIncrementBound;
out.sampledInputBound = sampledInputBound;
out.evaluationSteps = evaluationSteps;
out.transientBound = transientBound;
out.ultimateBound = ultimateBound;
out.formationRadiusBound = formationRadiusBound;
out.desiredMinSeparation = desiredMin;
out.safeRadius = safeRadius;
out.geometryFeasible = geometryFeasible;
out.deterministicCondition = deterministicCondition;
out.relevantLinkCount = relevantLinkCount;
out.blockCount = blockCount;
out.failureWindowCount = failureWindowCount;
out.qConfirmed = service.qConfirmed;
out.requiredQForTarget = requiredQ;
out.ageViolationUpperBound = ageViolationUpperBound;
out.safetyFailureUpperBound = safetyFailureUpperBound;
out.meetsTarget = deterministicCondition ...
    && safetyFailureUpperBound <= analysis.targetFailureProbability;
out.assumptions = { ...
    'honest monotone DATA/ACK protocol', ...
    'declared qConfirmed lower-bounds every recovery block conditionally', ...
    'declared motion bounds hold over the full horizon', ...
    'initial communication state is common knowledge', ...
    'acceleration saturation is inactive', ...
    'primary follower graph satisfies the symmetric grounding theorem'};

end


function requireFields(s,names,parent)

for k = 1:numel(names)
    if ~isfield(s,names{k})
        error('finiteHorizonSafetyCertificate: missing %s.%s.', ...
            parent,names{k});
    end
end

end


function x = expandNodeBound(value,N,name)

if isscalar(value)
    x = repmat(value,N,1);
elseif numel(value) == N
    x = value(:);
else
    error(['finiteHorizonSafetyCertificate: motion.%s must be scalar ' ...
        'or have N entries.'],name);
end
if any(~isfinite(x) | x < 0)
    error(['finiteHorizonSafetyCertificate: motion.%s must be finite ' ...
        'and nonnegative.'],name);
end

end


function validateNonnegativeScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x < 0
    error(['finiteHorizonSafetyCertificate: %s must be a finite ' ...
        'nonnegative scalar.'],name);
end

end


function validatePositiveScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x <= 0
    error(['finiteHorizonSafetyCertificate: %s must be a finite positive ' ...
        'scalar.'],name);
end

end


function validateProbability(x,name,allowZero)

lowerOk = x > 0;
if allowZero
    lowerOk = x >= 0;
end
if ~isscalar(x) || ~isfinite(x) || ~lowerOk || x > 1
    error('finiteHorizonSafetyCertificate: %s is outside its probability range.', ...
        name);
end

end
