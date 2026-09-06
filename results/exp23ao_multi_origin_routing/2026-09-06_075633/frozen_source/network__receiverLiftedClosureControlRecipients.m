function recipientMask=receiverLiftedClosureControlRecipients( ...
    migration,kind,sender)
%RECEIVERLIFTEDCLOSURECONTROLRECIPIENTS Minimal semantic destinations.
%
% Routing should deliver a logical closure packet only to nodes whose
% protocol state can consume it.  Incidental overhearing is allowed but is
% not required for correctness and is not used by this selector.

base={'N','initiator','affectedNodes','incidentEdgeA','incidentEdgeB', ...
    'incidentEdgeWitness'};
if ~isstruct(migration)||~isscalar(migration)|| ...
        ~all(isfield(migration,base))
    error(['receiverLiftedClosureControlRecipients: invalid ' ...
        'migration.']);
end
N=migration.N;
if ~isscalar(sender)||~isfinite(sender)||sender<1||sender>N|| ...
        sender~=floor(sender)
    error('receiverLiftedClosureControlRecipients: invalid sender.');
end
kind=lower(strrep(strtrim(char(kind)),'_','-'));
recipientMask=false(N,1);
affected=reshape(migration.affectedNodes,[],1);

switch kind
    case 'prepare'
        requireSender(migration.initiator);
        recipientMask(affected)=true;

    case {'quiet','quiescent'}
        requireAffected();
        recipientMask(migration.initiator)=true;

    case {'claim','lock-proof','lockproof'}
        edge=(migration.incidentEdgeA==sender)| ...
            (migration.incidentEdgeB==sender);
        witnesses=unique(migration.incidentEdgeWitness(edge));
        recipientMask(witnesses)=true;

    case 'response'
        recipientMask(migration.initiator)=true;

    case 'commit'
        requireSender(migration.initiator);
        recipientMask(affected)=true;

    case 'revoke'
        if ~isfield(migration,'oldGraph')
            error(['receiverLiftedClosureControlRecipients: oldGraph ' ...
                'required for revoke.']);
        end
        recipientMask=logical(migration.oldGraph(:,sender));

    otherwise
        error(['receiverLiftedClosureControlRecipients: unknown kind ' ...
            '"%s".'],kind);
end
recipientMask(sender)=false;

    function requireSender(expected)
        if sender~=expected
            error(['receiverLiftedClosureControlRecipients: sender-kind ' ...
                'mismatch.']);
        end
    end

    function requireAffected()
        if ~ismember(sender,affected)
            error(['receiverLiftedClosureControlRecipients: sender is ' ...
                'outside affected set.']);
        end
    end

end
