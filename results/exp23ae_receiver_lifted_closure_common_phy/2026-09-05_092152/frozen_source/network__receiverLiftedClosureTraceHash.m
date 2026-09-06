function h=receiverLiftedClosureTraceHash(T)
%RECEIVERLIFTEDCLOSURETRACEHASH Exact hash of closure-migration exogenous data.

fields={'prepareDeliveryU','quietDeliveryU','claimDeliveryU', ...
    'lockProofDeliveryU','responseDeliveryU','commitDeliveryU', ...
    'revokeDeliveryU','actualGraphAfter','prepareVersion', ...
    'prepareDigest','quietVersion','quietDigest','claimVersion', ...
    'claimDigest','responseVersion','responseDigest','commitVersion', ...
    'commitDigest'};
values=zeros(0,1);
for k=1:numel(fields)
    if ~isfield(T,fields{k})
        error('receiverLiftedClosureTraceHash: missing T.%s.',fields{k});
    end
    value=T.(fields{k});
    if islogical(value), value=double(value); end
    values=[values;double(value(:))]; %#ok<AGROW>
end
h=realizationHash(values);

end
