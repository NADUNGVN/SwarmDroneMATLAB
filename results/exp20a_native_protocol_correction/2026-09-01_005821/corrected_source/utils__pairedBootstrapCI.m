function S = pairedBootstrapCI(a,b,nReplicate,seedValue,nRequested)
%PAIREDBOOTSTRAPCI Deterministic paired percentile bootstrap interval.

if nargin < 3 || isempty(nReplicate), nReplicate=10000; end
if nargin < 4 || isempty(seedValue), seedValue=14141414; end
if nargin < 5 || isempty(nRequested), nRequested=numel(a); end
if numel(a)~=numel(b)
    error('pairedBootstrapCI: paired vectors must have equal length.');
end
if ~isscalar(nReplicate) || nReplicate<1 || ...
        nReplicate~=floor(nReplicate)
    error('pairedBootstrapCI: nReplicate must be a positive integer.');
end

a=a(:); b=b(:);
d=a-b;
usable=isfinite(d);
d=d(usable);
S.nRequested=nRequested;
S.nPairs=numel(d);
S.nDropped=numel(a)-S.nPairs;
S.complete=S.nPairs==nRequested;
S.nReplicate=nReplicate;
S.seed=seedValue;
S.meanD=mean(d);
if isempty(d)
    S.lo=NaN; S.hi=NaN; S.crossesZero=true;
    return;
end

stream=RandStream('mt19937ar','Seed',seedValue);
indices=randi(stream,S.nPairs,S.nPairs,nReplicate);
bootMean=mean(d(indices),1);
S.lo=localPercentile(bootMean,2.5);
S.hi=localPercentile(bootMean,97.5);
S.crossesZero=S.lo<=0 && S.hi>=0;

end


function y=localPercentile(x,p)

x=sort(x(isfinite(x)));
if isempty(x), y=NaN; return; end
if isscalar(x), y=x; return; end
r=1+(numel(x)-1)*p/100;
lo=floor(r); hi=ceil(r); w=r-lo;
y=(1-w)*x(lo)+w*x(hi);

end
