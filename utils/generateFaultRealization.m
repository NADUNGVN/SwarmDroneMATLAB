function fault = generateFaultRealization(cfg, faultType, faultLevel)
%GENERATEFAULTREALIZATION Pre-draw which links fail and when.
%
%   fault = generateFaultRealization(cfg, faultType, faultLevel)
%
% Link failures are modelled EXCLUSIVELY at the network-delivery layer.
% cfg.swarm.A is never touched, so:
%
%   - the controller keeps trying to use a dead link, exactly as a real one
%     would, because nothing tells it the radio is gone
%   - the channel count stays fixed, so communication cost remains
%     comparable across fault levels
%   - a transmitter still transmits into a dead link; the packet is counted
%     as sent and then dropped
%
% Removing edges from A instead would quietly change the control problem and
% the cost denominator at the same time, and the two effects could not be
% separated afterwards.
%
% The realization depends only on the seed, the nominal graph and the fault
% specification. It does NOT depend on the method, so every policy meets the
% same failures at the same instants. Without that, a difference between
% methods would mix the policy with the luck of which links died.
%
% faultType:
%   'none'       no failures
%   'permanent'  faultLevel is the fraction of links down for the whole run
%   'burst'      faultLevel is the outage duration in seconds; a fixed
%                fraction of links drops out for that window and returns
%
% Returns:
%   down        N x N logical, links affected
%   tStart      outage start  (0 for permanent)
%   tEnd        outage end    (inf for permanent)
%   activeA     the nominal graph minus the affected links, for
%               connectivity classification only. It is NEVER fed back
%               into cfg.swarm.A.

A = cfg.swarm.A;

N = size(A,1);


%% ============================================================
% Burst outage severity
%
% Fixed so that duration is the only thing varying along the burst
% axis; otherwise a longer outage would also be a wider one and the
% two could not be told apart.
% ============================================================

burstFraction = 0.30;


fault.type  = faultType;
fault.level = faultLevel;

fault.down = false(N,N);

fault.tStart = 0;
fault.tEnd   = inf;


if strcmpi(faultType, 'none')

    fault.activeA = A;
    fault.nDown   = 0;

    % Same fields as the fault branches, so downstream code never has
    % to special-case the nominal condition.
    inDeg = sum(A(2:N,:) ~= 0, 2);

    fault.isolatedFollowers  = nnz(inDeg == 0);
    fault.activeInDegreeMean = mean(inDeg);
    fault.activeInDegreeMin  = min(inDeg);

    return;

end


%% ============================================================
% Dedicated stream
%
% Independent of the forward and reverse channel traces, and of the
% simulator's own rng, so adding or removing faults perturbs nothing
% else.
% ============================================================

stream = RandStream('mt19937ar', ...
    'Seed', mod(cfg.net.seed + 50240001, 2^32));


%% ============================================================
% Choose the affected links
% ============================================================

linkIdx = find(A ~= 0);

nLink = numel(linkIdx);

switch lower(faultType)

    case 'permanent'
        frac = faultLevel;

    case 'burst'
        frac = burstFraction;

    otherwise
        error('generateFaultRealization: unknown faultType "%s".', faultType);

end

nDown = round(frac * nLink);

perm = randperm(stream, nLink);

chosen = linkIdx(perm(1:nDown));

fault.down(chosen) = true;

fault.nDown = nDown;


%% ============================================================
% Timing
% ============================================================

if strcmpi(faultType, 'burst')

    % Starts inside the evaluation window (t >= 8 s) and ends with
    % enough of the run left for recovery to be measurable.
    fault.tStart = 12.0;
    fault.tEnd   = 12.0 + faultLevel;

end


%% ============================================================
% Active graph, for classification only
% ============================================================

activeA = A;

activeA(fault.down) = 0;

fault.activeA = activeA;


%% ============================================================
% Isolated followers
%
% lambda2 is computed on the SYMMETRISED graph including leader-pin
% edges, so a follower can retain lambda2 > 0 through its pin alone
% while having lost every consensus in-link. Such a follower still
% tracks the leader but has no relative information at all, which is
% a materially different situation from a merely sparser graph.
%
% Reported separately so that "connected" is never read as "every
% follower still has neighbours".
% ============================================================

activeInDeg = sum(activeA(2:N,:) ~= 0, 2);

fault.isolatedFollowers = nnz(activeInDeg == 0);

fault.activeInDegreeMean = mean(activeInDeg);
fault.activeInDegreeMin  = min(activeInDeg);

end
