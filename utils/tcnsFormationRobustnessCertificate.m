function R = tcnsFormationRobustnessCertificate(cfg,blockTarget,maxBlockLength)
%TCNSFORMATIONROBUSTNESSCERTIFICATE Structured sampled ISS/UUB certificate.
%
%   R = tcnsFormationRobustnessCertificate(cfg)
%
% For the communication-induced degradation state
%
%   delta_y(k+1) = Ah*delta_y(k) + Bc*d_c(k),
%
% where delta_y=[delta_e;h*delta_v] and
% Bc=h^2*[I;I], the certificate computes the structured block gain
%
%   G_q = sum_{r=0}^{q-1} abs(Ah^r*Bc).
%
% Each scalar entry multiplies a Euclidean 3-D follower disturbance norm;
% no spurious sqrt(3) conversion is needed. A rigorous geometric tail uses
% alpha=||Ah^q||_2<1. This is much sharper than the legacy Q=I/Young bound
% while retaining an explicit infinite-horizon upper bound.

if nargin < 2 || isempty(blockTarget)
    blockTarget = 1e-4;
end
if nargin < 3 || isempty(maxBlockLength)
    maxBlockLength = 5000;
end

validateattributes(blockTarget,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'blockTarget',2);
validateattributes(maxBlockLength,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'maxBlockLength',3);

cert = formationTheoryCertificate(cfg);
if ~cert.primaryTheoremApplicable || ~cert.isSchur
    error('tcnsFormationRobustnessCertificate:Scope', ...
        ['The first robustness certificate requires the fixed symmetric ' ...
         'grounded graph and a Schur exact sampled matrix.']);
end

A = cert.sampledAcl;
h = cert.sampleTime;
m = size(A,1)/2;
n = 2*m;
Bc = h^2*[eye(m);eye(m)];

partialGain = zeros(n,m);
rowPrefixNorm = zeros(n,1);
Apower = eye(n);
q = 0;

while q < maxBlockLength
    partialGain = partialGain+abs(Apower*Bc);
    rowPrefixNorm = rowPrefixNorm+vecnorm(Apower,2,2);
    q = q+1;
    Apower = Apower*A;
    if norm(Apower,2)<=blockTarget
        break;
    end
end

alpha = norm(Apower,2);
if alpha>=1
    error('tcnsFormationRobustnessCertificate:NoContractingBlock', ...
        ['No block power with induced norm below one was found within ' ...
         '%d samples.'],maxBlockLength);
end

tailCoefficient = rowPrefixNorm*norm(Bc,2)*alpha/(1-alpha);
unitFollowerBound = ones(m,1);
unitInputUltimateBound = partialGain*unitFollowerBound + ...
    tailCoefficient*norm(unitFollowerBound,2);

R.scope = 'fixed symmetric grounded, exact-state, unsaturated DI subsystem';
R.Ah = A;
R.Bc = Bc;
R.followers = cert.followers;
R.sampleTime = h;
R.blockLength = q;
R.blockTarget = blockTarget;
R.blockContraction = alpha;
R.partialBlockGain = partialGain;
R.tailCoefficient = tailCoefficient;
R.positionPartialGain = partialGain(1:m,:);
R.scaledVelocityPartialGain = partialGain(m+1:end,:);
R.positionTailCoefficient = tailCoefficient(1:m);
R.scaledVelocityTailCoefficient = tailCoefficient(m+1:end);
R.unitInputPositionUltimateBound = unitInputUltimateBound(1:m);
R.unitInputVelocityUltimateBound = ...
    unitInputUltimateBound(m+1:end)/h;
R.legacyLyapunovInputGain = cert.discreteInputGain;
R.legacyLyapunovTransientGain = cert.discreteTransientGain;
R.proofIdentity = [ ...
    'G_q*b + tailCoefficient*norm(b,2) bounds limsup block norms ' ...
    'when ||d_c,i(k)||_2 <= b_i uniformly.'];

end
