function B=continuousTdmaGuardBound(maxOffsetSec,maxDriftPpm,resetHorizonSec)
%CONTINUOUSTDMAGUARDBOUND Finite-horizon sufficient TDMA guard bound.
%
% B.maxBoundaryErrorSec = (Theta + Delta*H)/(1-Delta)
% B.safeGuardSec        = 2*B.maxBoundaryErrorSec

validateNonnegative(maxOffsetSec,'maxOffsetSec');
validateNonnegative(maxDriftPpm,'maxDriftPpm');
if ~isscalar(resetHorizonSec) || ~isfinite(resetHorizonSec) || ...
        resetHorizonSec<=0
    error(['continuousTdmaGuardBound: resetHorizonSec must be a ' ...
        'positive finite scalar.']);
end
delta=maxDriftPpm*1e-6;
if delta>=1
    error('continuousTdmaGuardBound: fractional drift must be below one.');
end
B.maxOffsetSec=maxOffsetSec;
B.maxDriftPpm=maxDriftPpm;
B.resetHorizonSec=resetHorizonSec;
B.maxBoundaryErrorSec=(maxOffsetSec+delta*resetHorizonSec)/(1-delta);
B.safeGuardSec=2*B.maxBoundaryErrorSec;
B.assumption='half-open DATA intervals; nominal boundary b in [0,H]';

end


function validateNonnegative(x,name)

if ~isscalar(x) || ~isfinite(x) || x<0
    error('continuousTdmaGuardBound: %s must be nonnegative finite.',name);
end

end
