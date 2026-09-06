function [due,policy]=localUnionMigrationClaimSchedule(C)
%LOCALUNIONMIGRATIONCLAIMSCHEDULE Deterministic node-local CLAIM schedule.
%
% With backoff disabled, every frame from eligibleFrame is a CLAIM
% opportunity, preserving the LOCAL-UNION-MIGRATION-KERNEL-v1 behavior.
% With backoff enabled, the revoker sends a dense prefix, then doubles the
% inter-CLAIM interval up to a cap, and stops after a finite attempt budget.
% The schedule uses only the public configuration and the revoker's local
% eligibility epoch; packet outcomes and receiver-private state are absent.

required={'maxFrames','eligibleFrame'};
if ~isstruct(C) || ~isscalar(C) || ~all(isfield(C,required)) || ...
        any(~isfinite([C.maxFrames C.eligibleFrame])) || ...
        C.maxFrames<1 || C.maxFrames~=floor(C.maxFrames) || ...
        C.eligibleFrame<1 || C.eligibleFrame~=floor(C.eligibleFrame) || ...
        C.eligibleFrame>C.maxFrames
    error('localUnionMigrationClaimSchedule: invalid frame configuration.');
end

enabled=false;
if isfield(C,'claimBackoffEnabled'), enabled=C.claimBackoffEnabled; end
if ~isscalar(enabled) || ~(islogical(enabled) || ...
        (isnumeric(enabled) && isfinite(enabled) && any(enabled==[0 1])))
    error('localUnionMigrationClaimSchedule: invalid enable flag.');
end
enabled=logical(enabled);
due=false(C.maxFrames,1);

if ~enabled
    due(C.eligibleFrame:C.maxFrames)=true;
    policy=struct('version','LOCAL-CLAIM-RETRY-v1', ...
        'enabled',false,'denseRetryFrames',NaN, ...
        'maxBackoffFrames',1,'attemptLimit',inf, ...
        'opportunityCount',nnz(due),'lastOpportunityFrame',C.maxFrames, ...
        'scheduleHashExact',realizationHash(double(due)));
    return;
end

names={'claimDenseRetryFrames','claimMaxBackoffFrames', ...
    'claimRetryAttemptLimit'};
for k=1:numel(names)
    if ~isfield(C,names{k}) || ~isscalar(C.(names{k})) || ...
            ~isfinite(C.(names{k})) || C.(names{k})<1 || ...
            C.(names{k})~=floor(C.(names{k}))
        error('localUnionMigrationClaimSchedule: invalid C.%s.',names{k});
    end
end
dense=C.claimDenseRetryFrames;
cap=C.claimMaxBackoffFrames;
limit=C.claimRetryAttemptLimit;
if limit<dense
    error(['localUnionMigrationClaimSchedule: attempt limit must cover ' ...
        'the dense retry prefix.']);
end

frame=C.eligibleFrame;
attempt=0;
gap=1;
while frame<=C.maxFrames && attempt<limit
    due(frame)=true;
    attempt=attempt+1;
    if attempt<dense
        frame=frame+1;
    elseif attempt==dense
        gap=min(2,cap);
        frame=frame+gap;
    else
        gap=min(2*gap,cap);
        frame=frame+gap;
    end
end
last=find(due,1,'last');
policy=struct('version','LOCAL-CLAIM-RETRY-v1', ...
    'enabled',true,'denseRetryFrames',dense, ...
    'maxBackoffFrames',cap,'attemptLimit',limit, ...
    'opportunityCount',nnz(due),'lastOpportunityFrame',last, ...
    'scheduleHashExact',realizationHash(double(due)));

end
