function h=receiverLiftedRoutedClosureTraceHash(T)
%RECEIVERLIFTEDROUTEDCLOSURETRACEHASH Hash exogenous routed transaction data.

if ~isstruct(T)||~isscalar(T)||~isfield(T,'linkUniform')
    error('receiverLiftedRoutedClosureTraceHash: invalid trace.');
end
kinds={'prepare','quiescent','claim','lockproof','response','commit'};
values=zeros(0,1);
for k=1:numel(kinds)
    if ~isfield(T.linkUniform,kinds{k})
        error('receiverLiftedRoutedClosureTraceHash: missing routed draws.');
    end
    values=[values;T.linkUniform.(kinds{k})(:)]; %#ok<AGROW>
end
fields={'actualGraphAfter','prepareVersion','prepareDigest', ...
    'quietVersion','quietDigest','claimVersion','claimDigest', ...
    'lockProofVersion','lockProofDigest','responseVersion', ...
    'responseDigest','commitVersion','commitDigest', ...
    'repetitionsPerHop'};
for k=1:numel(fields)
    if ~isfield(T,fields{k})
        error('receiverLiftedRoutedClosureTraceHash: missing T.%s.',fields{k});
    end
    values=[values;double(T.(fields{k})(:))]; %#ok<AGROW>
end
h=realizationHash(values);

end
