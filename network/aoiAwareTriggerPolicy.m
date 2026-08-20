function [sendPacket, reason, triggerInfo] = aoiAwareTriggerPolicy( ...
    currentPos, ...
    currentVel, ...
    lastTxPos, ...
    lastTxVel, ...
    receiverAoI, ...
    timeSinceLastTx, ...
    cfg)

% ============================================================
% AOIAWARETRIGGERPOLICY
%
% Adaptive coupled AoI-aware event-trigger.
%
% Main principle:
%
%   AoI alone does NOT trigger communication.
%
% Instead, increasing AoI progressively reduces the
% state-change threshold required for transmission.
%
%
% Hard state trigger:
%
%   ||dp|| >= epsP
%
%   OR
%
%   ||dv|| >= epsV
%
%
% AoI-assisted trigger:
%
%   AoI >= AoI_threshold
%
%   AND
%
%   (
%       ||dp|| >= adaptiveScale(AoI)*epsP
%
%       OR
%
%       ||dv|| >= adaptiveScale(AoI)*epsV
%   )
%
%
% adaptiveScale:
%
%   AoI near threshold
%       -> scale ~= scaleBase
%
%   AoI increasingly stale
%       -> scale decreases
%
%   very stale
%       -> scale = scaleMin
%
%
% Example defaults:
%
%   scaleBase = 0.50
%   scaleMin  = 0.20
%
%
% reason:
%
%   0 = no transmission
%   1 = hard position trigger
%   2 = hard velocity trigger
%   3 = AoI-assisted adaptive trigger
%   4 = maximum-silence timeout
%
%
% Reporting priority:
%
%   hard position
%   hard velocity
%   AoI-assisted
%   timeout
%
% ============================================================


%% ============================================================
% Configuration
% ============================================================

epsPos = ...
    cfg.aoiEvent.posThreshold;


epsVel = ...
    cfg.aoiEvent.velThreshold;


aoiThreshold = ...
    cfg.aoiEvent.aoiThreshold;


maxSilence = ...
    cfg.aoiEvent.maxSilence;


minInterTx = ...
    cfg.aoiEvent.minInterTx;


scaleBase = ...
    cfg.aoiEvent.aoiStateScaleBase;


scaleMin = ...
    cfg.aoiEvent.aoiStateScaleMin;


adaptRange = ...
    cfg.aoiEvent.aoiAdaptRange;


aoiMinInterTx = ...
    cfg.aoiEvent.aoiMinInterTx;


%% ============================================================
% Normalize inputs
% ============================================================

currentPos = ...
    currentPos(:);


currentVel = ...
    currentVel(:);


lastTxPos = ...
    lastTxPos(:);


lastTxVel = ...
    lastTxVel(:);


%% ============================================================
% Trigger-information structure
% ============================================================

triggerInfo.positionChange = NaN;

triggerInfo.velocityChange = NaN;

triggerInfo.receiverAoI = ...
    receiverAoI;

triggerInfo.timeSinceLastTx = ...
    timeSinceLastTx;


triggerInfo.adaptiveScale = ...
    scaleBase;


triggerInfo.adaptivePosThreshold = ...
    scaleBase * epsPos;


triggerInfo.adaptiveVelThreshold = ...
    scaleBase * epsVel;


triggerInfo.positionTrigger = false;

triggerInfo.velocityTrigger = false;

triggerInfo.aoiTrigger = false;

triggerInfo.timeoutTrigger = false;


triggerInfo.aoiPositionEligible = false;

triggerInfo.aoiVelocityEligible = false;


triggerInfo.refractoryBlocked = false;

triggerInfo.aoiCooldownBlocked = false;


%% ============================================================
% Invalid transmitter memory
%
% Force initialization transmission.
% ============================================================

if ...
        isempty(lastTxPos) || ...
        isempty(lastTxVel) || ...
        any(~isfinite(lastTxPos)) || ...
        any(~isfinite(lastTxVel))

    sendPacket = true;

    reason = 4;

    triggerInfo.timeoutTrigger = true;

    return;

end


%% ============================================================
% State change since latest attempted transmission
% ============================================================

positionChange = ...
    norm( ...
    currentPos ...
    - lastTxPos);


velocityChange = ...
    norm( ...
    currentVel ...
    - lastTxVel);


triggerInfo.positionChange = ...
    positionChange;


triggerInfo.velocityChange = ...
    velocityChange;


%% ============================================================
% Conventional hard state triggers
% ============================================================

positionTrigger = ...
    positionChange ...
    >= epsPos;


velocityTrigger = ...
    velocityChange ...
    >= epsVel;


triggerInfo.positionTrigger = ...
    positionTrigger;


triggerInfo.velocityTrigger = ...
    velocityTrigger;


%% ============================================================
% Adaptive AoI-dependent sensitivity
%
% normalizedExcess:
%
%   AoI = threshold
%       -> 0
%
%   AoI = threshold*(1 + adaptRange)
%       -> 1
%
%
% With default adaptRange = 1:
%
%   AoI = threshold
%       -> scale = 0.50
%
%   AoI = 2*threshold
%       -> scale = 0.20
%
% Values are saturated to [0,1].
% ============================================================

if receiverAoI <= aoiThreshold

    normalizedExcess = 0;

else

    normalizedExcess = ...
        ( ...
        receiverAoI ...
        / max(aoiThreshold,eps) ...
        - 1 ...
        ) ...
        / max(adaptRange,eps);

end


normalizedExcess = ...
    min( ...
    max(normalizedExcess,0), ...
    1);


adaptiveScale = ...
    scaleBase ...
    - ...
    (scaleBase - scaleMin) ...
    * normalizedExcess;


adaptiveScale = ...
    min( ...
    max(adaptiveScale,scaleMin), ...
    scaleBase);


adaptivePosThreshold = ...
    adaptiveScale ...
    * epsPos;


adaptiveVelThreshold = ...
    adaptiveScale ...
    * epsVel;


triggerInfo.adaptiveScale = ...
    adaptiveScale;


triggerInfo.adaptivePosThreshold = ...
    adaptivePosThreshold;


triggerInfo.adaptiveVelThreshold = ...
    adaptiveVelThreshold;


%% ============================================================
% AoI-assisted state relevance
% ============================================================

aoiPositionEligible = ...
    positionChange ...
    >= adaptivePosThreshold;


aoiVelocityEligible = ...
    velocityChange ...
    >= adaptiveVelThreshold;


triggerInfo.aoiPositionEligible = ...
    aoiPositionEligible;


triggerInfo.aoiVelocityEligible = ...
    aoiVelocityEligible;


%% ============================================================
% AoI condition
% ============================================================

aoiHigh = ...
    receiverAoI ...
    >= aoiThreshold;


aoiStateRelevant = ...
    aoiPositionEligible ...
    || aoiVelocityEligible;


%% ============================================================
% AoI-assisted cooldown
% ============================================================

aoiCooldownSatisfied = ...
    timeSinceLastTx ...
    >= aoiMinInterTx;


aoiTrigger = ...
    aoiHigh ...
    && aoiStateRelevant ...
    && aoiCooldownSatisfied;


triggerInfo.aoiTrigger = ...
    aoiTrigger;


if ...
        aoiHigh ...
        && aoiStateRelevant ...
        && ~aoiCooldownSatisfied

    triggerInfo.aoiCooldownBlocked = true;

end


%% ============================================================
% Maximum-silence fallback
% ============================================================

timeoutTrigger = ...
    timeSinceLastTx ...
    >= maxSilence;


triggerInfo.timeoutTrigger = ...
    timeoutTrigger;


%% ============================================================
% Global minimum inter-transmission interval
% ============================================================

if timeSinceLastTx < minInterTx

    sendPacket = false;

    reason = 0;

    triggerInfo.refractoryBlocked = true;

    return;

end


%% ============================================================
% Final transmission decision
% ============================================================

sendPacket = ...
    positionTrigger ...
    || velocityTrigger ...
    || aoiTrigger ...
    || timeoutTrigger;


%% ============================================================
% Trigger reason
% ============================================================

if positionTrigger

    reason = 1;


elseif velocityTrigger

    reason = 2;


elseif aoiTrigger

    reason = 3;


elseif timeoutTrigger

    reason = 4;


else

    reason = 0;

end

end