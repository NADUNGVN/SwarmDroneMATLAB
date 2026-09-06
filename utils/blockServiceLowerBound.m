function bound = blockServiceLowerBound(model)
%BLOCKSERVICELOWERBOUND Conditional minorization bound for one recovery block.
%
% The result is analytical and deliberately conservative. Each declared
% opportunity must satisfy the stated admission, contention and residual-loss
% lower bounds conditional on the entire past. Repeated conditioning, rather
% than independence, then gives the block bound.
%
% Required model fields:
%   pAccess             common p-persistent access probability
%   dataCompetitors     max other nodes conflicting with tagged DATA
%   ackCompetitors      max other nodes conflicting with tagged ACK
%   dataOpportunities   guaranteed fresh DATA opportunities per block
%   ackOpportunities    guaranteed ACK opportunities after DATA success
%   dataResidualLoss    upper bound on residual DATA loss probability
%   ackResidualLoss     upper bound on residual ACK loss probability
%
% Optional fields (default one):
%   dataAdmissionLowerBound, ackAdmissionLowerBound
% Optional pData/pAck override the common pAccess.

required = {'pAccess','dataCompetitors','ackCompetitors', ...
    'dataOpportunities','ackOpportunities', ...
    'dataResidualLoss','ackResidualLoss'};
for k = 1:numel(required)
    if ~isfield(model,required{k})
        error('blockServiceLowerBound: missing model.%s.',required{k});
    end
end

pData = model.pAccess;
pAck = model.pAccess;
if isfield(model,'pData')
    pData = model.pData;
end
if isfield(model,'pAck')
    pAck = model.pAck;
end

qAdmissionData = getDefault(model,'dataAdmissionLowerBound',1);
qAdmissionAck = getDefault(model,'ackAdmissionLowerBound',1);

validateProbability(pData,'pData');
validateProbability(pAck,'pAck');
validateProbability(qAdmissionData,'dataAdmissionLowerBound');
validateProbability(qAdmissionAck,'ackAdmissionLowerBound');
validateProbability(model.dataResidualLoss,'dataResidualLoss');
validateProbability(model.ackResidualLoss,'ackResidualLoss');
validateCount(model.dataCompetitors,'dataCompetitors');
validateCount(model.ackCompetitors,'ackCompetitors');
validateCount(model.dataOpportunities,'dataOpportunities');
validateCount(model.ackOpportunities,'ackOpportunities');

cData = model.dataCompetitors;
cAck = model.ackCompetitors;
rData = model.dataOpportunities;
rAck = model.ackOpportunities;

accessData = pData*(1-pData)^cData;
accessAck = pAck*(1-pAck)^cAck;

qDataOne = qAdmissionData*accessData*(1-model.dataResidualLoss);
qAckOne = qAdmissionAck*accessAck*(1-model.ackResidualLoss);

qDataBlock = 1-(1-qDataOne)^rData;
qAckGivenDataBlock = 1-(1-qAckOne)^rAck;
qConfirmedBlock = qDataBlock*qAckGivenDataBlock;

bound = struct();
bound.pData = pData;
bound.pAck = pAck;
bound.recommendedPData = 1/(cData+1);
bound.recommendedPAck = 1/(cAck+1);
bound.dataAccessTerm = accessData;
bound.ackAccessTerm = accessAck;
bound.qDataOneOpportunity = qDataOne;
bound.qAckOneOpportunity = qAckOne;
bound.qDataBlock = qDataBlock;
bound.qAckGivenDataBlock = qAckGivenDataBlock;
bound.qConfirmedBlock = qConfirmedBlock;
bound.assumption = ['Every counted opportunity obeys the declared ' ...
    'conditional lower bounds; a fresh obligation persists or is renewed.'];

end


function value = getDefault(s,name,defaultValue)

if isfield(s,name)
    value = s.(name);
else
    value = defaultValue;
end

end


function validateProbability(x,name)

if ~isscalar(x) || ~isfinite(x) || x < 0 || x > 1
    error('blockServiceLowerBound: %s must lie in [0,1].',name);
end

end


function validateCount(x,name)

if ~isscalar(x) || ~isfinite(x) || x < 0 || x ~= floor(x)
    error('blockServiceLowerBound: %s must be a nonnegative integer.',name);
end

end

