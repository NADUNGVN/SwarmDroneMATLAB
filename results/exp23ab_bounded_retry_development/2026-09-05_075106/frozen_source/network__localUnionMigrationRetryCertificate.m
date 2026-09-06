function B=localUnionMigrationRetryCertificate(C,incidentEntryCount)
%LOCALUNIONMIGRATIONRETRYCERTIFICATE Finite-horizon receipt bound.
%
% For one conservative incidence entry, a usable round requires: (i) at
% least one neighbor LOCK-PROOF by that frame, (ii) delivery of the current
% CLAIM to its witness, and (iii) delivery of the witness RESPONSE to the
% revoker. Under the independent erasure model used by the migration trace,
% this function sums over the first successful proof frame and applies a
% union bound over incidence entries. Self-witness cases can only improve
% on this conservative bound.

if ~isscalar(incidentEntryCount) || ~isfinite(incidentEntryCount) || ...
        incidentEntryCount<1 || incidentEntryCount~=floor(incidentEntryCount)
    error('localUnionMigrationRetryCertificate: invalid entry count.');
end
[due,policy]=localUnionMigrationClaimSchedule(C);
pClaim=probability(C,'claimErasureProbability');
pProof=probability(C,'lockProofErasureProbability');
pResponse=probability(C,'responseErasureProbability');
proofLast=min(C.maxFrames,C.eligibleFrame+C.lockProofRepeatFrames-1);
proofFrames=(C.eligibleFrame:proofLast)';
q=(1-pClaim)*(1-pResponse);

entryFailure=pProof^numel(proofFrames);
for k=1:numel(proofFrames)
    firstProof=proofFrames(k);
    laterClaims=nnz(due(firstProof:end));
    entryFailure=entryFailure+pProof^(k-1)*(1-pProof)* ...
        (1-q)^laterClaims;
end
unionFailure=min(1,incidentEntryCount*entryFailure);
B=struct('version','LOCAL-MIGRATION-RETRY-CERTIFICATE-v1', ...
    'assumption','independent-control-erasures', ...
    'incidentEntryCount',incidentEntryCount, ...
    'proofOpportunityCount',numel(proofFrames), ...
    'claimOpportunityCount',policy.opportunityCount, ...
    'perRoundReceiptLowerBound',q, ...
    'entryFailureUpperBound',entryFailure, ...
    'unionFailureUpperBound',unionFailure, ...
    'allEntriesSuccessLowerBound',1-unionFailure, ...
    'scheduleHashExact',policy.scheduleHashExact);

end


function p=probability(C,name)

p=0;
if isfield(C,name), p=C.(name); end
if ~isscalar(p) || ~isfinite(p) || p<0 || p>1
    error('localUnionMigrationRetryCertificate: invalid C.%s.',name);
end

end
