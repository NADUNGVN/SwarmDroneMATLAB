function [X,strata] = deterministicLatinHypercube(nPoint,nDimension,seed)
%DETERMINISTICLATINHYPERCUBE Midpoint Latin hypercube without toolboxes.

if ~isscalar(nPoint) || nPoint < 2 || nPoint ~= floor(nPoint)
    error('deterministicLatinHypercube: nPoint must be an integer >= 2.');
end
if ~isscalar(nDimension) || nDimension < 1 || ...
        nDimension ~= floor(nDimension)
    error(['deterministicLatinHypercube: nDimension must be a positive ' ...
        'integer.']);
end
if ~isscalar(seed) || ~isfinite(seed) || seed < 0 || seed ~= floor(seed)
    error('deterministicLatinHypercube: seed must be a nonnegative integer.');
end

stream = RandStream('mt19937ar','Seed',mod(seed,2^32));
strata = zeros(nPoint,nDimension);
for d = 1:nDimension
    strata(:,d) = randperm(stream,nPoint)';
end
X = (strata-0.5)/nPoint;

end
