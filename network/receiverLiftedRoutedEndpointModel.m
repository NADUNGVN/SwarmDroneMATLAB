function E=receiverLiftedRoutedEndpointModel(certificate)
%RECEIVERLIFTEDROUTEDENDPOINTMODEL Cache unique routed obligation paths.

required={'endpointKind','endpointSender','endpointReceiver', ...
    'endpointDepth','endpointErasureProbability','endpointRouteHash'};
if ~isstruct(certificate)||~isscalar(certificate)|| ...
        ~all(isfield(certificate,required))
    error('receiverLiftedRoutedEndpointModel: invalid certificate.');
end
kind=reshape(string(certificate.endpointKind),[],1);
sender=reshape(certificate.endpointSender,[],1);
receiver=reshape(certificate.endpointReceiver,[],1);
depth=reshape(certificate.endpointDepth,[],1);
failure=reshape(certificate.endpointErasureProbability,[],1);
routeHash=reshape(certificate.endpointRouteHash,[],1);
key=kind+'|'+string(sender)+'|'+string(receiver);
[~,index]=unique(key,'stable');
kind=kind(index); sender=sender(index); receiver=receiver(index);
depth=depth(index); failure=failure(index); routeHash=routeHash(index);
E=struct('version','RECEIVER-LIFTED-ROUTED-ENDPOINT-MODEL-v1', ...
    'kind',kind,'sender',sender,'receiver',receiver,'depth',depth, ...
    'erasureProbability',failure,'routeHash',routeHash, ...
    'entryCount',numel(index),'hashExact',realizationHash([ ...
    sender;receiver;depth;failure;routeHash]));

end
