function F = tcnsFiniteHorizonFormationBound(cfg,disturbanceBound)
%TCNSFINITEHORIZONFORMATIONBOUND Time-varying structured convolution bound.
%
%   F = tcnsFiniteHorizonFormationBound(cfg,beta)
%
% BETA is K-by-(N-1), where beta(k,i) bounds the Euclidean norm of the
% communication-induced acceleration disturbance for follower i at sample
% k. The initial stale/perfect-information degradation is assumed zero.
% For n>=2 this function evaluates exactly
%
%   z(n) = sum_{r=1}^{n-1} abs(Ah^(n-1-r)*Bc)*beta(r),
%
% which bounds the Euclidean norm of each 3-D block of
% delta_y=[delta_e;h*delta_v]. It preserves cancellations inside every
% signed matrix power, unlike the much looser recursion abs(Ah)*z.

validateattributes(disturbanceBound,{'numeric'}, ...
    {'real','finite','nonnegative','2d'},mfilename,'disturbanceBound',2);

cert = formationTheoryCertificate(cfg);
if ~cert.primaryTheoremApplicable || ~cert.isSchur
    error('tcnsFiniteHorizonFormationBound:Scope', ...
        ['The first finite-horizon bound requires the fixed symmetric ' ...
         'grounded graph and a Schur exact sampled matrix.']);
end

A = cert.sampledAcl;
h = cert.sampleTime;
m = size(A,1)/2;
[K,mInput] = size(disturbanceBound);
if mInput~=m
    error('tcnsFiniteHorizonFormationBound:Shape', ...
        'disturbanceBound must have N-1 columns.');
end

Bc = h^2*[eye(m);eye(m)];
n = 2*m;

impulse = zeros(n,m,max(K-1,1));
if K>1
    X = Bc;
    for lag = 0:K-2
        impulse(:,:,lag+1) = abs(X);
        X = A*X;
    end
end

blockBound = zeros(K,n);
for current = 2:K
    z = zeros(n,1);
    for source = 1:current-1
        lag = current-1-source;
        z = z+impulse(:,:,lag+1)*disturbanceBound(source,:)';
    end
    blockBound(current,:) = z';
end

F.blockNormBound = blockBound;
F.position = blockBound(:,1:m);
F.scaledVelocity = blockBound(:,m+1:end);
F.velocity = F.scaledVelocity/h;
F.Ah = A;
F.Bc = Bc;
F.zeroInitialDegradation = true;
F.scope = 'time-varying structured finite-horizon communication bound';

end
