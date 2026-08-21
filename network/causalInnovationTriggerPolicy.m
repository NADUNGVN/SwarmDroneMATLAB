function [sendPacket, branch, info] = causalInnovationTriggerPolicy( ...
    currentPos, currentVel, ...
    lastSentPos, lastSentVel, ...
    estimatedAoI, timeSinceLastTx, ...
    hasOutstanding, cfg)
%CAUSALINNOVATIONTRIGGERPOLICY Innovation-priority causal trigger (v3).
%
%   [sendPacket, branch, info] = causalInnovationTriggerPolicy( ...
%       currentPos, currentVel, lastSentPos, lastSentVel, ...
%       estimatedAoI, timeSinceLastTx, hasOutstanding, cfg)
%
% v2 failed because aoiMinInterTx became a ceiling on NEW INFORMATION rather
% than on repetition. Once in-flight suppression removed nearly all hard
% triggers, essentially all traffic ran through the AoI branch, and that
% branch's 0.10 s cooldown pinned the rate at ~9 Hz in every network.
%
% v3 changes no parameter. It separates two things that v2 conflated:
%
%     new information  is not  retransmission
%
% Four branches:
%
%   1 HARD NEW INFORMATION      dp >= epsP or dv >= epsV
%                               subject only to minInterTx
%
%   2 FRESHNESS-ADAPTIVE NEW    stale AND state moved past the adaptive
%     INFORMATION               threshold since the LAST SENT packet
%                               subject only to minInterTx, NOT aoiMinInterTx
%
%   3 REFRESH / RETRANSMISSION  stale but no genuine innovation
%                               subject to aoiMinInterTx, AND forbidden
%                               while any packet is still outstanding
%
%   4 MAX-SILENCE               final recovery backstop
%
% Branch 3 is the only one that repeats information the receiver may already
% be about to get, so it is the only one the cooldown should govern.
%
% Loss recovery uses no new timer. A lost packet is never acknowledged, so it
% stays outstanding and blocks refresh; maxSilence then fires. This is why v3
% adds no RTO, no RTT multiplier and no window size: the question it exists
% to answer is whether the semantic correction alone is sufficient.
%
% CAUSALITY: hasOutstanding is a count of unacknowledged packets. It must not
% depend on whether the channel dropped them -- a real sender cannot know
% that. The drop flag is used only by verification counters.
%
% branch: 0 none, 1 hard position, 2 hard velocity, 3 adaptive new info,
%         4 refresh, 5 max-silence

epsP          = cfg.aoiEvent.posThreshold;
epsV          = cfg.aoiEvent.velThreshold;
aoiThreshold  = cfg.aoiEvent.aoiThreshold;
aoiMinInterTx = cfg.aoiEvent.aoiMinInterTx;
minInterTx    = cfg.aoiEvent.minInterTx;
maxSilence    = cfg.aoiEvent.maxSilence;


%% ============================================================
% Reuse the existing adaptive-scale maths
%
% aoiAwareTriggerPolicy is called purely to obtain the innovation
% magnitudes, the adaptive scale and the eligibility flags. Its own
% send decision is deliberately discarded; v3 applies different branch
% semantics to the same quantities.
%
% Calling it rather than re-deriving the formula is deliberate: this
% project already carries one drifted copy of that maths, and a second
% would be a second chance to disagree silently.
% ============================================================

[~, ~, base] = aoiAwareTriggerPolicy( ...
    currentPos, currentVel, ...
    lastSentPos, lastSentVel, ...
    estimatedAoI, timeSinceLastTx, cfg);


dp = base.positionChange;
dv = base.velocityChange;

scale = base.adaptiveScale;


info = base;

info.branch = 0;

info.hardInnovation      = false;
info.adaptiveInnovation  = false;
info.refreshEligible     = false;
info.refreshCooldownBlocked = false;
info.refreshInFlightBlocked = false;


%% ============================================================
% Global refractory
%
% Applies to every branch. Unchanged from v1 and v2.
% ============================================================

if timeSinceLastTx < minInterTx

    sendPacket = false;
    branch     = 0;

    info.refractoryBlocked = true;

    return;

end


aoiStale = estimatedAoI >= aoiThreshold;

hardInnovation = base.positionTrigger || base.velocityTrigger;

adaptiveInnovation = aoiStale && ...
    (base.aoiPositionEligible || base.aoiVelocityEligible);

info.hardInnovation     = hardInnovation;
info.adaptiveInnovation = adaptiveInnovation;


%% ============================================================
% BRANCH 1: hard new information
% ============================================================

if hardInnovation

    sendPacket = true;

    if base.positionTrigger
        branch = 1;
    else
        branch = 2;
    end

    info.branch = branch;

    return;

end


%% ============================================================
% BRANCH 2: freshness-adaptive new information
%
% The receiver is stale AND the state has moved far enough from what
% was last put on the wire. That is new information, so the refresh
% cooldown does not apply.
% ============================================================

if adaptiveInnovation

    sendPacket = true;
    branch     = 3;

    info.branch = branch;

    return;

end


%% ============================================================
% BRANCH 3: refresh / retransmission
%
% Stale, but nothing materially new to say. This is the only branch
% that repeats information, so it is the only one aoiMinInterTx
% governs, and it must not add a duplicate to a packet already in
% flight.
% ============================================================

if aoiStale

    info.refreshEligible = true;

    cooldownOk = timeSinceLastTx >= aoiMinInterTx;

    if ~cooldownOk
        info.refreshCooldownBlocked = true;
    end

    if hasOutstanding > 0
        info.refreshInFlightBlocked = true;
    end

    if cooldownOk && hasOutstanding == 0

        sendPacket = true;
        branch     = 4;

        info.branch = branch;

        return;

    end

end


%% ============================================================
% BRANCH 4: max-silence backstop
%
% The recovery path when a packet was lost and will never be
% acknowledged. No separate retransmission timeout exists.
% ============================================================

if timeSinceLastTx >= maxSilence

    sendPacket = true;
    branch     = 5;

    info.branch = branch;

    return;

end


sendPacket = false;
branch     = 0;

end
