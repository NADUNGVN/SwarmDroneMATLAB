function value=localUnionMigrationTraceHash(T)
%LOCALUNIONMIGRATIONTRACEHASH Exact hash of all migration trace fields.

required={'claimDeliveryU','lockProofDeliveryU','responseDeliveryU', ...
    'revokeDeliveryU','selfRevoke','actualGraph','responseVersion', ...
    'responseClaimSeq'};
for k=1:numel(required)
    if ~isfield(T,required{k})
        error('localUnionMigrationTraceHash: missing T.%s.',required{k});
    end
end
value=realizationHash([T.claimDeliveryU(:);T.lockProofDeliveryU(:); ...
    T.responseDeliveryU(:);T.revokeDeliveryU(:); ...
    double(T.selfRevoke(:));double(T.actualGraph(:)); ...
    T.responseVersion(:);T.responseClaimSeq(:)]);

end
