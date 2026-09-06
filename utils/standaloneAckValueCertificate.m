function cert=standaloneAckValueCertificate(accounting,predictive)
%STANDALONEACKVALUECERTIFICATE Marginal-value accounting for standalone ACK.
%
% cert=standaloneAckValueCertificate(accounting)
% cert=standaloneAckValueCertificate(accounting,predictive)
%
% accounting fields (all scalar):
%   standaloneAckAirtimeSeconds  direct standalone-ACK airtime, >= 0
%   dataAirtimeSavedSeconds      piggyback-only DATA airtime minus ACK-assisted
%                                DATA airtime; signed and inclusive of any
%                                piggyback-entry bytes carried in DATA frames
%   controlLossSaved             piggyback control loss minus ACK-assisted loss
%   collisionEventsSaved         piggyback collisions minus ACK-assisted ones
%   weights                      struct with nonnegative fields
%       airtimeCostPerSecond, controlCostPerUnit, collisionCostPerEvent
%
% The exact offered-airtime margin is dataAirtimeSavedSeconds minus
% standaloneAckAirtimeSeconds. Positive means standalone ACK uses less total
% offered airtime. Piggyback overhead must not be added separately because it
% is already included in DATA frame airtime.
%
% Optional predictive fields:
%   expectedUniqueLeadSeconds
%   informationValueRateLower, informationValueRateUpper
%   externalityCostLower, externalityCostUpper
% The rates and externalities are already expressed in the weighted objective
% units used by accounting.weights. Bounds certify TRANSMIT or DISCARD only
% when they separate; otherwise the result is INCONCLUSIVE.

if nargin<2, predictive=[]; end
required={'standaloneAckAirtimeSeconds','dataAirtimeSavedSeconds', ...
    'controlLossSaved','collisionEventsSaved','weights'};
requireFields(accounting,required,'accounting');
requireFiniteScalar(accounting.standaloneAckAirtimeSeconds, ...
    'accounting.standaloneAckAirtimeSeconds',true);
requireFiniteScalar(accounting.dataAirtimeSavedSeconds, ...
    'accounting.dataAirtimeSavedSeconds',false);
requireFiniteScalar(accounting.controlLossSaved, ...
    'accounting.controlLossSaved',false);
requireFiniteScalar(accounting.collisionEventsSaved, ...
    'accounting.collisionEventsSaved',false);

weightNames={'airtimeCostPerSecond','controlCostPerUnit', ...
    'collisionCostPerEvent'};
requireFields(accounting.weights,weightNames,'accounting.weights');
for k=1:numel(weightNames)
    requireFiniteScalar(accounting.weights.(weightNames{k}), ...
        ['accounting.weights.' weightNames{k}],true);
end
weightValues=zeros(numel(weightNames),1);
for k=1:numel(weightNames)
    weightValues(k)=accounting.weights.(weightNames{k});
end
if all(weightValues==0)
    error('standaloneAckValueCertificate: at least one weight must be positive.');
end

ackCost=accounting.standaloneAckAirtimeSeconds;
dataSaving=accounting.dataAirtimeSavedSeconds;
airtimeMargin=dataSaving-ackCost;
w=accounting.weights;
airtimeValue=w.airtimeCostPerSecond*airtimeMargin;
controlValue=w.controlCostPerUnit*accounting.controlLossSaved;
collisionValue=w.collisionCostPerEvent*accounting.collisionEventsSaved;
netValue=airtimeValue+controlValue+collisionValue;

cert=struct();
cert.version='STANDALONE-ACK-VALUE-v1';
cert.standaloneAckAirtimeSeconds=ackCost;
cert.dataAirtimeSavedSeconds=dataSaving;
cert.controlLossSaved=accounting.controlLossSaved;
cert.collisionEventsSaved=accounting.collisionEventsSaved;
cert.weights=w;
cert.offeredAirtimeMarginSeconds=airtimeMargin;
cert.weightedAirtimeValue=airtimeValue;
cert.weightedControlValue=controlValue;
cert.weightedCollisionValue=collisionValue;
cert.weightedNetValue=netValue;
cert.isAirtimeBeneficial=airtimeMargin>0;
cert.isControlBeneficial=accounting.controlLossSaved>0;
cert.realizedContinuousStatus=continuousStatus( ...
    airtimeMargin,accounting.controlLossSaved);
cert.piggybackOverheadAlreadyInDataAirtime=true;

if isempty(predictive)
    cert.predictiveStatus='NOT_EVALUATED';
    cert.predictiveLowerNetValue=NaN;
    cert.predictiveUpperNetValue=NaN;
    cert.certifiedTransmit=false;
    cert.certifiedDiscard=false;
    return;
end
if ~isstruct(predictive) || ~isscalar(predictive)
    error('standaloneAckValueCertificate: predictive must be a scalar struct.');
end
predictionNames={'expectedUniqueLeadSeconds','informationValueRateLower', ...
    'informationValueRateUpper','externalityCostLower', ...
    'externalityCostUpper'};
requireFields(predictive,predictionNames,'predictive');
for k=1:numel(predictionNames)
    requireFiniteScalar(predictive.(predictionNames{k}), ...
        ['predictive.' predictionNames{k}],true);
end
if predictive.informationValueRateLower> ...
        predictive.informationValueRateUpper
    error(['standaloneAckValueCertificate: information-value lower bound ' ...
        'exceeds upper bound.']);
end
if predictive.externalityCostLower>predictive.externalityCostUpper
    error(['standaloneAckValueCertificate: externality-cost lower bound ' ...
        'exceeds upper bound.']);
end

directWeightedCost=w.airtimeCostPerSecond*ackCost;
benefitLower=predictive.expectedUniqueLeadSeconds* ...
    predictive.informationValueRateLower;
benefitUpper=predictive.expectedUniqueLeadSeconds* ...
    predictive.informationValueRateUpper;
costLower=directWeightedCost+predictive.externalityCostLower;
costUpper=directWeightedCost+predictive.externalityCostUpper;
lowerNet=benefitLower-costUpper;
upperNet=benefitUpper-costLower;
cert.predictiveLowerNetValue=lowerNet;
cert.predictiveUpperNetValue=upperNet;
cert.certifiedTransmit=lowerNet>0;
cert.certifiedDiscard=upperNet<=0;
if cert.certifiedTransmit
    cert.predictiveStatus='CERTIFIED_TRANSMIT';
elseif cert.certifiedDiscard
    cert.predictiveStatus='CERTIFIED_DISCARD';
else
    cert.predictiveStatus='INCONCLUSIVE';
end

end


function status=continuousStatus(airtimeMargin,controlMargin)

if airtimeMargin>0 && controlMargin>0
    status='ACK_ASSISTED_PARETO_CONTINUOUS';
elseif airtimeMargin<0 && controlMargin<0
    status='PIGGYBACK_PARETO_CONTINUOUS';
elseif airtimeMargin==0 && controlMargin==0
    status='EXACTLY_NEUTRAL_CONTINUOUS';
else
    status='TRADEOFF_OR_BOUNDARY';
end

end


function requireFields(value,names,parent)

if ~isstruct(value) || ~isscalar(value)
    error('standaloneAckValueCertificate: %s must be a scalar struct.',parent);
end
for k=1:numel(names)
    if ~isfield(value,names{k})
        error('standaloneAckValueCertificate: missing %s.%s.', ...
            parent,names{k});
    end
end

end


function requireFiniteScalar(value,name,nonnegative)

if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        (nonnegative && value<0)
    qualifier='finite scalar';
    if nonnegative, qualifier='finite nonnegative scalar'; end
    error('standaloneAckValueCertificate: %s must be a %s.',name,qualifier);
end

end
