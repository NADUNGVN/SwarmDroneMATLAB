function R = tcnsDecisionIdentifiability(C,L,B,relativeTolerance)
%TCNSDECISIONIDENTIFIABILITY Exact-value and relative-value linear tests.
%
% R = tcnsDecisionIdentifiability(C,L) treats the rows of L as the
% coefficients of a finite family q_a(x)=L(a,:)*x+c_a and the rows of C as
% the available linear information.  The default difference matrix compares
% actions 1,...,p-1 with reference action p.
%
% R = tcnsDecisionIdentifiability(C,L,B,tol) accepts any full-row-rank B
% whose row space is one^⊥.  Constants do not enter identifiability and are
% intentionally absent from this API.  The reported ranks are numerical
% diagnostics at tol; the exact statements concern the corresponding row
% spaces.

C = double(C);
L = double(L);
if nargin<4 || isempty(relativeTolerance), relativeTolerance = 1e-10; end
relativeTolerance = double(relativeTolerance);

if ~ismatrix(C) || ~ismatrix(L) || size(C,2)~=size(L,2) || ...
        isempty(L) || any(~isfinite(C),'all') || any(~isfinite(L),'all')
    error('tcnsDecisionIdentifiability:Dimensions', ...
        'C and nonempty L must be finite matrices with equal column count.');
end
if ~isscalar(relativeTolerance) || ~isfinite(relativeTolerance) || ...
        relativeTolerance<=0
    error('tcnsDecisionIdentifiability:Tolerance', ...
        'relativeTolerance must be a finite positive scalar.');
end

p = size(L,1);
if nargin<3 || isempty(B)
    if p==1
        B = zeros(0,1);
    else
        B = [eye(p-1) -ones(p-1,1)];
    end
else
    B = double(B);
end
localValidateDifferenceBasis(B,p,relativeTolerance);

[~,~,Vc] = svd(C);
sc = svd(C);
rankC = localNumericalRank(sc,relativeTolerance);
Qc = Vc(:,1:rankC);
P_C = Qc*Qc';
P_perp = eye(size(L,2))-P_C;

LvalueHidden = L*P_perp;
Lrelative = B*L;
LrelativeHidden = Lrelative*P_perp;
[rValue,valueSingularValues] = localMatrixRank( ...
    LvalueHidden,relativeTolerance);
[rRelative,relativeSingularValues] = localMatrixRank( ...
    LrelativeHidden,relativeTolerance);

% Restrict B to im(M), where M=L*P_perp.  Its nullity is the dimension of
% im(M) intersect span(one), and is therefore either zero or one.
[Um,~,~] = svd(LvalueHidden,'econ');
Qm = Um(:,1:rValue);
one = ones(p,1);
commonHiddenOffsetResidual = norm(one-Qm*(Qm'*one),2)/norm(one,2);
rankGap = rValue-rRelative;

individualResiduals = localRowResiduals(L,LvalueHidden);
relativeBasisResiduals = localRowResiduals(Lrelative,LrelativeHidden);
[pairwiseResiduals,pairwiseHiddenNorms] = ...
    localPairwiseResiduals(L,LvalueHidden);
if isempty(pairwiseResiduals)
    maximumPairwiseResidual = 0;
else
    maximumPairwiseResidual = max(pairwiseResiduals,[],'all');
end

R.referenceTolerance = relativeTolerance;
R.actionCount = p;
R.informationRank = rankC;
R.P_C = P_C;
R.P_perp = P_perp;
R.differenceMatrix = B;
R.LValueHidden = LvalueHidden;
R.LRelative = Lrelative;
R.LRelativeHidden = LrelativeHidden;
R.rValue = rValue;
R.rRelative = rRelative;
R.rankGap = rankGap;
R.commonHiddenOffsetResidual = commonHiddenOffsetResidual;
R.hasCommonHiddenOffset = commonHiddenOffsetResidual<=relativeTolerance;
R.valueHiddenSingularValues = valueSingularValues;
R.relativeHiddenSingularValues = relativeSingularValues;
R.individualNormalizedResiduals = individualResiduals;
R.relativeBasisNormalizedResiduals = relativeBasisResiduals;
R.pairwiseNormalizedResiduals = pairwiseResiduals;
R.pairwiseHiddenNorms = pairwiseHiddenNorms;
R.maximumPairwiseNormalizedResidual = maximumPairwiseResidual;
R.individualIdentifiable = individualResiduals<=relativeTolerance;
R.fullRelativeIdentifiable = maximumPairwiseResidual<=relativeTolerance;

end


function localValidateDifferenceBasis(B,p,relativeTolerance)

if ~ismatrix(B) || size(B,1)~=max(0,p-1) || size(B,2)~=p || ...
        any(~isfinite(B),'all')
    error('tcnsDecisionIdentifiability:DifferenceBasisDimensions', ...
        'B must be a finite (p-1)-by-p matrix.');
end
if p==1, return; end
s = svd(B);
rankB = localNumericalRank(s,relativeTolerance);
basisScale = max(1,norm(B,2));
if rankB~=p-1 || norm(B*ones(p,1),2)> ...
        relativeTolerance*basisScale*sqrt(p)
    error('tcnsDecisionIdentifiability:DifferenceBasis', ...
        'B must have full row rank and row space equal to one^perp.');
end

end


function [r,s] = localMatrixRank(M,relativeTolerance)

s = svd(M,'econ');
r = localNumericalRank(s,relativeTolerance);

end


function r = localNumericalRank(s,relativeTolerance)

if isempty(s), sigmaMax = 0; else, sigmaMax = s(1); end
r = sum(s>relativeTolerance*max(1,sigmaMax));

end


function residuals = localRowResiduals(rows,hiddenRows)

if isempty(rows)
    residuals = zeros(0,1);
    return;
end
denominator = max(vecnorm(rows,2,2),eps);
residuals = vecnorm(hiddenRows,2,2)./denominator;

end


function [residuals,hiddenNorms] = localPairwiseResiduals(L,Lhidden)

p = size(L,1);
residuals = zeros(p,p);
hiddenNorms = zeros(p,p);
for a = 1:p
    for b = a+1:p
        difference = L(a,:)-L(b,:);
        hidden = Lhidden(a,:)-Lhidden(b,:);
        hiddenNorm = norm(hidden,2);
        residual = hiddenNorm/max(norm(difference,2),eps);
        residuals(a,b) = residual;
        residuals(b,a) = residual;
        hiddenNorms(a,b) = hiddenNorm;
        hiddenNorms(b,a) = hiddenNorm;
    end
end

end
