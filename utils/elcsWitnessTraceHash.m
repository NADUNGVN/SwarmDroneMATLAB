function value=elcsWitnessTraceHash(T)
%ELCSWITNESSTRACEHASH Exact hash of all ELCS-W exogenous arrays.

required={'claimSlotU','certificateSlotU','claimDeliveryU', ...
    'certificateDeliveryU','scheduledDeliveryU','fallbackAccessU', ...
    'fallbackDeliveryU'};
if ~isstruct(T) || ~all(isfield(T,required))
    error('elcsWitnessTraceHash: incomplete trace.');
end
value=realizationHash([T.claimSlotU(:);T.certificateSlotU(:); ...
    T.claimDeliveryU(:);T.certificateDeliveryU(:); ...
    T.scheduledDeliveryU(:);T.fallbackAccessU(:); ...
    T.fallbackDeliveryU(:)]);
optional={'revokeDeliveryU','selfRevoke','reacquireEligible', ...
    'actualInterference'};
payload=[];
for k=1:numel(optional)
    if isfield(T,optional{k})
        values=T.(optional{k});
        payload=[payload;double(values(:))]; %#ok<AGROW>
    end
end
if ~isempty(payload), value=realizationHash([value;payload]); end

end
