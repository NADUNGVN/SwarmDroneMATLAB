function [sendPacket,branch,info] = controlAwareFreshnessPolicy( ...
    setContribution,latestSentContribution,localBudget, ...
    timeSinceLastTx,nOutstanding,policy)
%CONTROLAWAREFRESHNESSPOLICY Gate-4 causal control-budget event rule.
%
% Inputs are transmitter-local scalars in command-disturbance units. The
% sender transmits only while its causal possible-receiver-set contribution
% violates the allocated control budget. If the latest payload on the wire
% would already satisfy the budget, transmission is suppressed until a
% conditional retry interval expires. A retry is necessary because a sender
% cannot observe a DATA loss before receiving feedback.
%
% branch: 0 no send, 1 new information, 2 recovery with no outstanding
%         payload, 3 conditional retry while feedback is outstanding.
%
% This policy does not claim that sending instantly restores the theorem
% premise: only an ACK can contract the sender's possible receiver set.

validateattributes(setContribution,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'setContribution',1);
validateattributes(latestSentContribution,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'}, ...
    mfilename,'latestSentContribution',2);
validateattributes(localBudget,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'localBudget',3);
validateattributes(timeSinceLastTx,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'timeSinceLastTx',4);
validateattributes(nOutstanding,{'numeric'}, ...
    {'real','finite','integer','nonnegative','scalar'}, ...
    mfilename,'nOutstanding',5);

required = {'minInterTx','retryInterval'};
for q = 1:numel(required)
    if ~isfield(policy,required{q})
        error('controlAwareFreshnessPolicy:MissingConfig', ...
            'policy.%s is required.',required{q});
    end
end
validateattributes(policy.minInterTx,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'policy.minInterTx');
validateattributes(policy.retryInterval,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'policy.retryInterval');
if policy.retryInterval<policy.minInterTx
    error('controlAwareFreshnessPolicy:RetryBeforeRefractory', ...
        'retryInterval must be at least minInterTx.');
end

info.normalizedContribution = setContribution/localBudget;
info.budgetViolated = setContribution>localBudget;
info.latestSentWouldSatisfy = latestSentContribution<=localBudget;
info.refractoryBlocked = false;
info.usefulInFlightSuppressed = false;
info.retryWaiting = false;
info.branch = 0;

sendPacket = false;
branch = 0;

if ~info.budgetViolated
    return;
end

if timeSinceLastTx<policy.minInterTx
    info.refractoryBlocked = true;
    return;
end

if ~info.latestSentWouldSatisfy
    sendPacket = true;
    branch = 1;
    info.branch = branch;
    return;
end

if nOutstanding==0
    sendPacket = true;
    branch = 2;
    info.branch = branch;
    return;
end

if timeSinceLastTx>=policy.retryInterval
    sendPacket = true;
    branch = 3;
    info.branch = branch;
    return;
end

info.usefulInFlightSuppressed = true;
info.retryWaiting = true;

end
