function base=generateExp23mCoherenceBase(seedValue,N,R)
%GENERATEEXP23MCOHERENCEBASE Shared absolute geometry realization.

stream=RandStream('mrg32k3a','Seed',mod(seedValue+701*N,2^32));
stream.Substream=1; p=R.areaSide*rand(stream,N,R.dimension);
stream.Substream=2;
v=(2*rand(stream,N,R.dimension)-1)*R.nominalSpeedBound;
stream.Substream=3; pDirection=normalizeRows(randn(stream,N,R.dimension));
stream.Substream=4; vDirection=normalizeRows(randn(stream,N,R.dimension));
stream.Substream=5; aDirection=normalizeRows(randn(stream,N,R.dimension));
stream.Substream=6; pFraction=rand(stream,N,1).^(1/R.dimension);
stream.Substream=7; vFraction=rand(stream,N,1).^(1/R.dimension);
stream.Substream=8; aFraction=rand(stream,N,1).^(1/R.dimension);
base=struct('seed',seedValue,'N',N,'p',p,'v',v, ...
    'pDirection',pDirection,'vDirection',vDirection, ...
    'aDirection',aDirection,'pFraction',pFraction, ...
    'vFraction',vFraction,'aFraction',aFraction);
base.hashExact=realizationHash([seedValue;N;p(:);v(:);pDirection(:); ...
    vDirection(:);aDirection(:);pFraction;vFraction;aFraction]);

end


function x=normalizeRows(x)
n=sqrt(sum(x.^2,2)); n(n==0)=1; x=x./n;
end
