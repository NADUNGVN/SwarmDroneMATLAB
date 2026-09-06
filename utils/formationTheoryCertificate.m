function cert = formationTheoryCertificate(cfg)
%FORMATIONTHEORYCERTIFICATE Map a swarm config to the Study-2 LTI proof model.
%
% This is a consistency certificate, not a numerical substitute for proof.
% It constructs the exact one-axis grounded matrices used by the unsaturated
% double-integrator formation controller.  Agent 1 is the physical leader;
% cfg.swarm.A edges to agent 1 and cfg.swarm.pin are distinct grounding terms,
% matching distributedFormationPolicy.m.

required = {'N','A','pin','offsets','Kp','Kv','KpLeader','KvLeader','dt'};
for k = 1:numel(required)
    if ~isfield(cfg.swarm,required{k})
        error('formationTheoryCertificate: missing cfg.swarm.%s.',required{k});
    end
end

N = cfg.swarm.N;
if N < 2 || N ~= floor(N)
    error('formationTheoryCertificate: N must be an integer at least two.');
end
if ~isequal(size(cfg.swarm.A),[N N])
    error('formationTheoryCertificate: A must be N-by-N.');
end
if numel(cfg.swarm.pin) ~= N
    error('formationTheoryCertificate: pin must have N entries.');
end
if size(cfg.swarm.offsets,1) ~= N
    error('formationTheoryCertificate: offsets must have N rows.');
end

A = double(cfg.swarm.A);
if any(~isfinite(A(:)) | A(:) < 0)
    error('formationTheoryCertificate: A must be finite and nonnegative.');
end
if any(A(:) ~= 0 & A(:) ~= 1)
    error(['formationTheoryCertificate: A must be binary to match the ' ...
        'current controller semantics.']);
end
if any(abs(diag(A)) > 0)
    error('formationTheoryCertificate: self-loops are not supported.');
end
pinRaw = double(cfg.swarm.pin(:));
if any(pinRaw ~= 0 & pinRaw ~= 1)
    error(['formationTheoryCertificate: pin must be binary to match the ' ...
        'current controller semantics.']);
end

followers = 2:N;
m = N-1;
Aff = A(followers,followers);
Aleader = A(followers,1);
pinAll = pinRaw;
pinFollower = pinAll(followers);

Df = diag(sum(Aff,2));
Lf = Df - Aff;
G = diag(Aleader);
Pi = diag(pinFollower);

degreeScale = ones(m,1);
normalizeDegree = isfield(cfg.swarm,'normalizeConsensusDegree') ...
    && logical(cfg.swarm.normalizeConsensusDegree);
if normalizeDegree
    degree = sum(A(followers,:),2);
    positive = degree > 0;
    degreeScale(positive) = 2 ./ degree(positive);
end
S = diag(degreeScale);

Hp = cfg.swarm.Kp * S * (Lf + G) + cfg.swarm.KpLeader * Pi;
Hv = cfg.swarm.Kv * S * (Lf + G) + cfg.swarm.KvLeader * Pi;
Acl = [zeros(m), eye(m); -Hp, -Hv];

h = cfg.swarm.dt;
if ~isscalar(h) || ~isfinite(h) || h <= 0
    error('formationTheoryCertificate: dt must be a positive finite scalar.');
end
% Use y_k=[e_k; h*r_k], so every state component has position units.  chi is
% the analytic-leader position-step residual and uOmega=h^2*omega is the
% acceleration-induced position increment. Input order: [chi; uOmega].
Ah = [eye(m)-h^2*Hp, eye(m)-h*Hv; ...
      -h^2*Hp,          eye(m)-h*Hv];
Dh = [eye(m), eye(m); zeros(m), eye(m)];

% Exact one-axis plant matrices for x_i=[p_i;v_i]. The h^2 coefficient is
% implementation-faithful: integrateFollowers updates velocity first and then
% advances position with the new velocity.
plantA = [1 h; 0 1];
plantB = [h^2; h];

symTol = 1e-11;
eigTol = 1e-10;
isSymmetricHp = norm(Hp-Hp','fro') <= symTol*max(1,norm(Hp,'fro'));
isSymmetricHv = norm(Hv-Hv','fro') <= symTol*max(1,norm(Hv,'fro'));

lambdaMinHp = min(eig((Hp+Hp')/2));
lambdaMinHv = min(eig((Hv+Hv')/2));
closedLoopEigenvalues = eig(Acl);
spectralAbscissa = max(real(closedLoopEigenvalues));
isHurwitz = spectralAbscissa < -eigTol;

lyapunovP = [];
lyapunovResidual = nan;
lyapunovLambdaMin = nan;
lyapunovLambdaMax = nan;
lyapunovTransientGain = nan;
lyapunovStateDecayRate = nan;
lyapunovInputGain = nan;
if isHurwitz
    lyapunovP = solveContinuousLyapunov(Acl);
    B = [zeros(m); eye(m)];
    pEig = eig((lyapunovP+lyapunovP')/2);
    lyapunovLambdaMin = min(pEig);
    lyapunovLambdaMax = max(pEig);
    lyapunovResidual = norm( ...
        Acl'*lyapunovP + lyapunovP*Acl + eye(2*m),'fro');
    lyapunovTransientGain = sqrt( ...
        lyapunovLambdaMax/lyapunovLambdaMin);
    lyapunovStateDecayRate = 1/(4*lyapunovLambdaMax);
    lyapunovInputGain = 2*norm(lyapunovP*B,2) ...
        * lyapunovTransientGain;
end

sampledEigenvalues = eig(Ah);
sampledSpectralRadius = max(abs(sampledEigenvalues));
isSchur = sampledSpectralRadius < 1-eigTol;
discreteLyapunovP = [];
discreteLyapunovResidual = nan;
discreteLyapunovLambdaMin = nan;
discreteLyapunovLambdaMax = nan;
discreteTransientGain = nan;
discreteContractionFactor = nan;
discreteStateDecayRate = nan;
discreteInputGain = nan;
if isSchur
    discreteLyapunovP = solveDiscreteLyapunov(Ah);
    pdEig = eig((discreteLyapunovP+discreteLyapunovP')/2);
    discreteLyapunovLambdaMin = min(pdEig);
    discreteLyapunovLambdaMax = max(pdEig);
    discreteLyapunovResidual = norm( ...
        Ah'*discreteLyapunovP*Ah-discreteLyapunovP+eye(2*m),'fro');
    discreteTransientGain = sqrt( ...
        discreteLyapunovLambdaMax/discreteLyapunovLambdaMin);
    alpha = 1/(2*discreteLyapunovLambdaMax);
    discreteContractionFactor = sqrt(1-alpha);
    discreteStateDecayRate = -log(discreteContractionFactor)/h;
    crossGain = norm(Ah'*discreteLyapunovP*Dh,2);
    directGain = norm(Dh'*discreteLyapunovP*Dh,2);
    beta = 2*crossGain^2 + directGain;
    discreteInputGain = sqrt( ...
        beta/(alpha*discreteLyapunovLambdaMin));
end

offsets = cfg.swarm.offsets;
desiredMinSeparation = inf;
for i = 1:N
    for j = i+1:N
        desiredMinSeparation = min( ...
            desiredMinSeparation,norm(offsets(i,:)-offsets(j,:)));
    end
end

cert = struct();
cert.followers = followers;
cert.followerAdjacency = Aff;
cert.followerLaplacian = Lf;
cert.ordinaryLeaderGrounding = G;
cert.pinGrounding = Pi;
cert.degreeScale = degreeScale;
cert.Hp = Hp;
cert.Hv = Hv;
cert.Acl = Acl;
cert.sampleTime = h;
cert.plantStateMatrix = plantA;
cert.plantInputMatrix = plantB;
cert.sampledAcl = Ah;
cert.sampledInputMatrix = Dh;
cert.controllerStateMatrix = [-Hp, -Hv];
cert.leaderPinVector = pinFollower;
cert.positionUpdateConvention = 'semi-implicit Euler: v first, then p';
cert.maxSpeedIsEnforced = false;
if isfield(cfg.swarm,'maxAccel')
    cert.maxCommandedAcceleration = cfg.swarm.maxAccel;
else
    cert.maxCommandedAcceleration = nan;
end
cert.isSymmetricHp = isSymmetricHp;
cert.isSymmetricHv = isSymmetricHv;
cert.lambdaMinHp = lambdaMinHp;
cert.lambdaMinHv = lambdaMinHv;
cert.closedLoopEigenvalues = closedLoopEigenvalues;
cert.spectralAbscissa = spectralAbscissa;
cert.spectralDecayMargin = max(0,-spectralAbscissa);
cert.isHurwitz = isHurwitz;
cert.primaryTheoremApplicable = isSymmetricHp && isSymmetricHv ...
    && lambdaMinHp > eigTol && lambdaMinHv > eigTol;
cert.leaderAccelerationMismatchMap = pinFollower - ones(m,1);
cert.desiredMinSeparation = desiredMinSeparation;
cert.lyapunovP = lyapunovP;
cert.lyapunovResidual = lyapunovResidual;
cert.lyapunovLambdaMin = lyapunovLambdaMin;
cert.lyapunovLambdaMax = lyapunovLambdaMax;
cert.lyapunovTransientGain = lyapunovTransientGain;
cert.lyapunovStateDecayRate = lyapunovStateDecayRate;
cert.lyapunovInputGain = lyapunovInputGain;
cert.sampledEigenvalues = sampledEigenvalues;
cert.sampledSpectralRadius = sampledSpectralRadius;
cert.isSchur = isSchur;
cert.discreteLyapunovP = discreteLyapunovP;
cert.discreteLyapunovResidual = discreteLyapunovResidual;
cert.discreteLyapunovLambdaMin = discreteLyapunovLambdaMin;
cert.discreteLyapunovLambdaMax = discreteLyapunovLambdaMax;
cert.discreteTransientGain = discreteTransientGain;
cert.discreteContractionFactor = discreteContractionFactor;
cert.discreteStateDecayRate = discreteStateDecayRate;
cert.discreteInputGain = discreteInputGain;

end


function P = solveDiscreteLyapunov(A)
% Solve A'*P*A - P = -I.

n = size(A,1);
if exist('dlyap','file') == 2
    P = dlyap(A',eye(n));
else
    K = kron(A',A') - eye(n^2);
    rhs = -reshape(eye(n),[],1);
    P = reshape(K\rhs,n,n);
end
P = (P+P')/2;

end


function P = solveContinuousLyapunov(A)
% Solve A'*P + P*A = -I. Prefer the toolbox solver for scalable configs.

n = size(A,1);
if exist('lyap','file') == 2
    P = lyap(A',eye(n));
else
    K = kron(eye(n),A') + kron(A',eye(n));
    rhs = -reshape(eye(n),[],1);
    P = reshape(K\rhs,n,n);
end
P = (P+P')/2;

end
