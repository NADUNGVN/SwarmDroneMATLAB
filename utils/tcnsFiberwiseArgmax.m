function R = tcnsFiberwiseArgmax(C,L,c,x0,rho,tolerance)
%TCNSFIBERWISEARGMAX Common maximizers on a bounded Euclidean information fiber.
%
% The fiber is {x0+v : C*v=0, ||v||_2<=rho}.  Rows of L and entries of c
% define q_a(x)=L(a,:)*x+c(a).  commonActions contains exactly the actions
% that are optimal at every point of the fiber, up to the supplied numerical
% comparison tolerance.  uniformlyStrictActions are uniquely optimal at
% every point; this is stronger than the intersection of argmax sets being a
% singleton.

C = double(C);
L = double(L);
c = double(c(:));
x0 = double(x0(:));
rho = double(rho);
if nargin<6 || isempty(tolerance), tolerance = 1e-12; end
tolerance = double(tolerance);

if ~ismatrix(C) || ~ismatrix(L) || isempty(L) || ...
        size(C,2)~=size(L,2) || size(L,2)~=numel(x0) || ...
        size(L,1)~=numel(c) || any(~isfinite(C),'all') || ...
        any(~isfinite(L),'all') || any(~isfinite(c)) || any(~isfinite(x0))
    error('tcnsFiberwiseArgmax:Dimensions', ...
        'C, L, c, and x0 must be finite and dimensionally compatible.');
end
if ~isscalar(rho) || ~isfinite(rho) || rho<0
    error('tcnsFiberwiseArgmax:Radius', ...
        'rho must be a finite nonnegative scalar.');
end
if ~isscalar(tolerance) || ~isfinite(tolerance) || tolerance<0
    error('tcnsFiberwiseArgmax:Tolerance', ...
        'tolerance must be a finite nonnegative scalar.');
end

[~,~,V] = svd(C);
s = svd(C);
if isempty(s), sigmaMax = 0; else, sigmaMax = s(1); end
rankTolerance = max(1e-10,tolerance)*max(1,sigmaMax);
rankC = sum(s>rankTolerance);
Q = V(:,1:rankC);
Pperp = eye(size(L,2))-Q*Q';

q0 = L*x0+c;
p = size(L,1);
centers = zeros(p,p);
hiddenNorms = zeros(p,p);
lower = zeros(p,p);
upper = zeros(p,p);
for a = 1:p
    for b = 1:p
        ellDifference = L(a,:)-L(b,:);
        centers(a,b) = q0(a)-q0(b);
        hiddenNorms(a,b) = norm(ellDifference*Pperp,2);
        lower(a,b) = centers(a,b)-rho*hiddenNorms(a,b);
        upper(a,b) = centers(a,b)+rho*hiddenNorms(a,b);
    end
end

offDiagonal = ~eye(p);
isCommon = false(p,1);
isUniformlyStrict = false(p,1);
margin = zeros(p,1);
for a = 1:p
    competitors = offDiagonal(a,:);
    if any(competitors)
        margin(a) = min(lower(a,competitors));
        isCommon(a) = all(lower(a,competitors)>=-tolerance);
        isUniformlyStrict(a) = all(lower(a,competitors)>tolerance);
    else
        margin(a) = Inf;
        isCommon(a) = true;
        isUniformlyStrict(a) = true;
    end
end

R.centerValues = q0;
R.pairwiseCenters = centers;
R.pairwiseHiddenNorms = hiddenNorms;
R.pairwiseLower = lower;
R.pairwiseUpper = upper;
R.actionMargins = margin;
R.commonActions = find(isCommon);
R.uniformlyStrictActions = find(isUniformlyStrict);
R.hasCommonMaximizer = any(isCommon);
R.hasUniformlyStrictMaximizer = any(isUniformlyStrict);
R.argmaxIntersectionIsSingleton = nnz(isCommon)==1;

end
