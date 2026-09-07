function R = tcnsLinearIdentifiability(informationMap,valueCoefficient)
%TCNSLINEARIDENTIFIABILITY Row-space test for one affine scalar statistic.

C = double(informationMap);
ell = double(valueCoefficient(:));
if size(C,2)~=numel(ell) || any(~isfinite(C),'all') || ...
        any(~isfinite(ell))
    error('tcnsLinearIdentifiability:Dimensions', ...
        'C must be finite and have one column per coefficient entry.');
end
s = svd(C,'econ');
if isempty(s), sigmaMax = 0; else, sigmaMax = s(1); end
tolerance = 1e-10*max(1,sigmaMax);
numericRank = sum(s>tolerance);
rowProjector = pinv(C,tolerance)*C;
perpendicular = (eye(numel(ell))-rowProjector)*ell;
residual = norm(perpendicular,2);
normalizer = max(norm(ell,2),eps);
if residual>tolerance*normalizer
    witness = perpendicular/residual;
else
    witness = zeros(size(ell));
end

R.rankTolerance = tolerance;
R.rank = numericRank;
R.nullity = size(C,2)-numericRank;
R.coefficientNorm = norm(ell,2);
R.rowSpaceResidual = residual;
R.normalizedRowSpaceResidual = residual/normalizer;
R.identifiable = residual<=tolerance*normalizer;
R.missingCoefficient = perpendicular;
R.nullWitness = witness;
R.nullWitnessInformationResidual = norm(C*witness,2);
R.nullWitnessValueChange = ell'*witness;

end
