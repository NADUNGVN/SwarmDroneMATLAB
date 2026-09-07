function [sendPacket,info] = predictiveVoiPolicy( ...
    score,price,timeSinceLastTx,minInterTx)
%PREDICTIVEVOIPOLICY Threshold a causal expected isolated-action value.
%
% PRICE is a frontier parameter in the same units as SCORE. No retry or AoI
% threshold is added: failed/outstanding packets alter the causal belief and
% hence the next score directly.

validateattributes(score,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'score',1);
validateattributes(price,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'price',2);
validateattributes(timeSinceLastTx,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'}, ...
    mfilename,'timeSinceLastTx',3);
validateattributes(minInterTx,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'minInterTx',4);

info.score = score;
info.price = price;
info.abovePrice = score>price;
info.refractoryBlocked = false;
sendPacket = false;

if ~info.abovePrice
    return;
end
if timeSinceLastTx<minInterTx
    info.refractoryBlocked = true;
    return;
end
sendPacket = true;

end
