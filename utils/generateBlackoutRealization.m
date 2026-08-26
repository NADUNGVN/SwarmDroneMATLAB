function blackout = generateBlackoutRealization(cfg, nNodes, duration)
%GENERATEBLACKOUTREALIZATION Pre-draw which followers go dark, and when.
%
%   blackout = generateBlackoutRealization(cfg, nNodes, duration)
%
% A blackout is a COMMUNICATION-LAYER fault on a node. While it lasts the
% chosen follower cannot send DATA, cannot receive DATA, cannot send ACK and
% cannot receive ACK. Its dynamics and controller keep running normally on
% whatever state it already holds, and cfg.swarm.A is never modified.
%
% This differs from the EXP08B link failure in one respect that matters for
% traffic accounting: there the sender could not know a link was dead, so it
% transmitted and the packet was counted and then dropped. Here the node's
% own radio is off, so it does not transmit at all and nothing is counted.
% Both are physical; they are simply different faults.
%
% The leader is never selected. Blacking out the leader removes the only
% absolute reference in the formation, which is a different experiment.
%
% The realization depends only on the seed, N and the fault specification,
% never on the method, so every policy meets the same nodes going dark at
% the same instants.
%
% nNodes    number of followers to black out (0 for the nominal condition)
% duration  outage length in seconds
%
% Returns:
%   node        N x 1 logical, true for a blacked-out node
%   nodes       indices of the blacked-out followers
%   tStart      12.0, inside the evaluation window
%   tEnd        tStart + duration
%   activeA     nominal graph restricted to the nodes still radiating,
%               for classification only. NEVER fed back into cfg.swarm.A.
%   connected   whether the REMAINING swarm stays connected (see below)
%
% Connectivity is judged on the subgraph induced by the nodes that are still
% radiating. A dark node is cut off by construction; that is the
% intervention, not an impossibility. Including it would drive lambda2 to
% zero in every single condition and the classification would carry no
% information at all. The question worth asking is whether the rest of the
% swarm stays connected once the dark node is taken out.

N = cfg.swarm.N;

blackout.nNodes   = nNodes;
blackout.duration = duration;

blackout.node = false(N,1);

blackout.tStart = 0;
blackout.tEnd   = -1;      % empty interval: never active


if nNodes <= 0

    blackout.nodes = [];

    blackout.activeA = cfg.swarm.A;

    g = graphConnectivity(cfg.swarm.A, cfg.swarm.pin);

    blackout.lambda2   = g.lambda2;
    blackout.connected = g.connected;

    inDeg = sum(cfg.swarm.A(2:N,:) ~= 0, 2);

    blackout.isolatedFollowers  = nnz(inDeg == 0);
    blackout.activeInDegreeMean = mean(inDeg);
    blackout.activeInDegreeMin  = min(inDeg);

    blackout.disconnectedDuration = 0;

    return;

end


%% ============================================================
% Dedicated stream
%
% Independent of the forward trace, the reverse trace, the link-failure
% stream of EXP08B and the simulator's own rng, so adding or removing a
% blackout perturbs nothing else.
% ============================================================

stream = RandStream('mt19937ar', ...
    'Seed', mod(cfg.net.seed + 60240001, 2^32));


%% ============================================================
% Choose the followers
% ============================================================

candidates = 2:N;

perm = randperm(stream, numel(candidates));

chosen = candidates(perm(1:min(nNodes, numel(candidates))));

blackout.nodes = sort(chosen);

blackout.node(blackout.nodes) = true;


%% ============================================================
% Timing
% ============================================================

blackout.tStart = 12.0;
blackout.tEnd   = 12.0 + duration;


%% ============================================================
% Induced subgraph over the nodes still radiating
% ============================================================

keep = ~blackout.node;

activeA = cfg.swarm.A;

activeA(blackout.node, :) = 0;
activeA(:, blackout.node) = 0;

blackout.activeA = activeA;

subA   = cfg.swarm.A(keep, keep);
subPin = cfg.swarm.pin(keep);

g = graphConnectivity(subA, subPin);

blackout.lambda2   = g.lambda2;
blackout.connected = g.connected;

blackout.disconnectedDuration = duration * (~g.connected);


%% ============================================================
% Consensus in-degree among the remaining followers
%
% Reported separately from lambda2, per section 2.4. A follower can
% keep lambda2 > 0 through its leader pin while every one of its
% neighbours has gone dark, leaving it with no relative information.
% ============================================================

remaining = find(keep);
remaining = remaining(remaining >= 2);

if isempty(remaining)

    blackout.isolatedFollowers  = 0;
    blackout.activeInDegreeMean = 0;
    blackout.activeInDegreeMin  = 0;

else

    d = sum(activeA(remaining, :) ~= 0, 2);

    blackout.isolatedFollowers  = nnz(d == 0);
    blackout.activeInDegreeMean = mean(d);
    blackout.activeInDegreeMin  = min(d);

end

end
