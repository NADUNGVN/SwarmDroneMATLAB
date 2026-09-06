function T=generateLocalUnionMigrationTrace(seedValue,M,C)
%GENERATELOCALUNIONMIGRATIONTRACE Policy-independent migration draws.

if ~isscalar(seedValue) || ~isfinite(seedValue) || seedValue<0
    error('generateLocalUnionMigrationTrace: seed must be nonnegative.');
end
required={'maxFrames','transitionFrame','eligibleFrame', ...
    'newGraphActivationFrame'};
for k=1:numel(required)
    if ~isfield(C,required{k}) || ~isscalar(C.(required{k})) || ...
            ~isfinite(C.(required{k})) || C.(required{k})<1 || ...
            C.(required{k})~=floor(C.(required{k}))
        error('generateLocalUnionMigrationTrace: invalid C.%s.',required{k});
    end
end
N=M.N; F=C.maxFrames;
if C.transitionFrame>C.eligibleFrame || ...
        C.transitionFrame>C.newGraphActivationFrame || ...
        max([C.eligibleFrame C.newGraphActivationFrame])>F
    error('generateLocalUnionMigrationTrace: invalid transition ordering.');
end
stream=RandStream('mrg32k3a','Seed',mod(seedValue+51293+1000*N,2^32));
stream.Substream=11;
T=struct();
T.claimDeliveryU=rand(stream,F,N,N);
T.lockProofDeliveryU=rand(stream,F,N,N);
T.responseDeliveryU=rand(stream,F,N,N);
T.revokeDeliveryU=rand(stream,F,N,N);
T.selfRevoke=false(F,N);
T.selfRevoke(C.transitionFrame,M.transitionNode)=true;
T.actualGraph=false(F,N,N);
for frame=1:F
    if frame<C.newGraphActivationFrame
        T.actualGraph(frame,:,:)=M.oldGraph;
    else
        T.actualGraph(frame,:,:)=M.newGraph;
    end
end
T.responseVersion=2*ones(F,N);
T.responseClaimSeq=ones(F,N);
T.hashExact=localUnionMigrationTraceHash(T);

end
