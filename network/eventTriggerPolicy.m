function [sendPacket, reason] = eventTriggerPolicy( ...
    currentPos, ...
    currentVel, ...
    lastTxPos, ...
    lastTxVel, ...
    timeSinceLastTx, ...
    cfg)

% ============================================================
% EVENTTRIGGERPOLICY
%
% Baseline event-triggered communication policy.
%
% A packet is transmitted when at least one condition is true:
%
%   1. Position change exceeds threshold
%   2. Velocity change exceeds threshold
%   3. Maximum silence time is reached
%
% reason:
%
%   0 = no transmission
%   1 = position trigger
%   2 = velocity trigger
%   3 = timeout / maximum-silence trigger
%
% Priority:
%
%   position > velocity > timeout
%
% ============================================================


%% ============================================================
% Read thresholds
% ============================================================

epsPos = ...
    cfg.event.posThreshold;

epsVel = ...
    cfg.event.velThreshold;

maxSilence = ...
    cfg.event.maxSilence;


%% ============================================================
% Safety checks
% ============================================================

currentPos = currentPos(:);
currentVel = currentVel(:);

lastTxPos = lastTxPos(:);
lastTxVel = lastTxVel(:);


% If no valid previous transmitted state exists,
% force one transmission.
if ...
        isempty(lastTxPos) || ...
        isempty(lastTxVel) || ...
        any(~isfinite(lastTxPos)) || ...
        any(~isfinite(lastTxVel))

    sendPacket = true;
    reason = 3;

    return;

end


%% ============================================================
% State changes since latest transmission
% ============================================================

positionChange = ...
    norm(currentPos - lastTxPos);

velocityChange = ...
    norm(currentVel - lastTxVel);


%% ============================================================
% Trigger decisions
% ============================================================

positionTrigger = ...
    positionChange >= epsPos;

velocityTrigger = ...
    velocityChange >= epsVel;

timeoutTrigger = ...
    timeSinceLastTx >= maxSilence;


sendPacket = ...
    positionTrigger || ...
    velocityTrigger || ...
    timeoutTrigger;


%% ============================================================
% Trigger reason
% ============================================================

if positionTrigger

    reason = 1;

elseif velocityTrigger

    reason = 2;

elseif timeoutTrigger

    reason = 3;

else

    reason = 0;

end

end