function S = causalReceiverStateSetBound(currentPos,currentVel, ...
    ackPos,ackVel,outstanding,currentAcc,ackAcc)
%CAUSALRECEIVERSTATESETBOUND Causal uncertainty from ACK + outstanding set.
%
%   S = causalReceiverStateSetBound(p,v,pAck,vAck,outstanding)
%   S = causalReceiverStateSetBound(...,a,aAck)
%
% The latest receiver payload must be either the cumulatively ACK-confirmed
% payload or one of the subsequently transmitted outstanding payloads. The
% sender knows this finite information set without knowing which packet was
% delivered. The maximum current-to-candidate error is therefore a pathwise
% upper bound on receiver staleness error. The packet's internal `dropped`
% diagnostic is deliberately ignored because a physical sender does not know
% a forward-channel loss outcome without feedback.

if nargin < 6
    currentAcc = [];
end
if nargin < 7
    ackAcc = [];
end

currentPos = localVector(currentPos,'currentPos');
currentVel = localVector(currentVel,'currentVel');
ackPos = localVector(ackPos,'ackPos');
ackVel = localVector(ackVel,'ackVel');

candidatePos = ackPos;
candidateVel = ackVel;

if ~isempty(outstanding)
    candidatePos = [candidatePos; vertcat(outstanding.pos)]; %#ok<AGROW>
    candidateVel = [candidateVel; vertcat(outstanding.vel)]; %#ok<AGROW>
end

S.position = max(vecnorm(candidatePos-currentPos,2,2));
S.velocity = max(vecnorm(candidateVel-currentVel,2,2));
S.candidateCount = size(candidatePos,1);
S.usesDropOutcome = false;

if ~isempty(currentAcc) || ~isempty(ackAcc)
    currentAcc = localVector(currentAcc,'currentAcc');
    ackAcc = localVector(ackAcc,'ackAcc');
    candidateAcc = ackAcc;
    if ~isempty(outstanding)
        if ~isfield(outstanding,'acc')
            error('causalReceiverStateSetBound:MissingAcceleration', ...
                'Leader outstanding records must retain their sent acceleration.');
        end
        outAcc = vertcat(outstanding.acc);
        if any(~isfinite(outAcc(:)))
            error('causalReceiverStateSetBound:InvalidAcceleration', ...
                'Leader outstanding acceleration candidates must be finite.');
        end
        candidateAcc = [candidateAcc; outAcc]; %#ok<AGROW>
    end
    S.acceleration = max(vecnorm(candidateAcc-currentAcc,2,2));
else
    S.acceleration = NaN;
end

end


function x = localVector(x,name)

validateattributes(x,{'numeric'}, ...
    {'real','finite','vector','numel',3},mfilename,name);
x = reshape(double(x),1,3);

end
