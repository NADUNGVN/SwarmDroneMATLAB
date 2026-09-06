function S = wilsonCI(nFailure,nTotal,alpha)
%WILSONCI Wilson score interval for a binomial proportion.

if nargin<3 || isempty(alpha), alpha=0.05; end
if ~isscalar(nTotal) || nTotal<1 || nTotal~=floor(nTotal) || ...
        ~isscalar(nFailure) || nFailure<0 || ...
        nFailure>nTotal || nFailure~=floor(nFailure)
    error('wilsonCI: require integer 0 <= nFailure <= nTotal.');
end
if ~isscalar(alpha) || alpha<=0 || alpha>=1
    error('wilsonCI: alpha must lie in (0,1).');
end

z=norminv(1-alpha/2);
p=nFailure/nTotal;
denominator=1+z^2/nTotal;
centre=(p+z^2/(2*nTotal))/denominator;
half=z/denominator*sqrt(p*(1-p)/nTotal+z^2/(4*nTotal^2));
S.nFailure=nFailure;
S.nTotal=nTotal;
S.rate=p;
S.lo=max(0,centre-half);
S.hi=min(1,centre+half);
if nFailure==0, S.lo=0; end
if nFailure==nTotal, S.hi=1; end
S.alpha=alpha;

end
