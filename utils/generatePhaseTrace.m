function trace = generatePhaseTrace(cfg)
%GENERATEPHASETRACE Pre-draw the periodic transmission phase realization.
%
%   trace = generatePhaseTrace(cfg)
%
% Every locked experiment ran periodic communication on ONE global clock:
% every node in the swarm transmitted on the same tick, forever. That is
% not how independent radios behave, and it flatters no method in
% particular but it does make the periodic baselines artificially
% synchronised. EXP10 turns phase on (cfg.net.phaseOffsetEnabled).
%
% WHAT IS DRAWN, AND WHAT DELIBERATELY IS NOT
%
% One uniform per (physical sender, payload class):
%
%   u(1 : N)   neighbour-state payload from physical sender j
%   u(N + 1)   leader payload (physical sender is node 1, but the payload
%              also carries acceleration, so it is a separate payload
%              class on the same radio)
%
% and the offset a simulator applies is
%
%   phaseOffset = u * cfg.net.commPeriod
%
% Three properties this shape buys, each of which a per-LINK draw would
% have destroyed:
%
%   1  One sender transmits to every receiver at the same instant. A
%      per-directed-link phase would break the broadcast synchronisation
%      that is the physical meaning of a periodic radio, and would
%      manufacture an advantage for the event-triggered methods out of
%      nothing but an accounting artefact.
%   2  u does NOT depend on cfg.net.commPeriod, so P10 and P20 share one
%      phase realization and differ only by the period it is scaled by.
%      tests/test_exp10_infrastructure checks the hashes are equal.
%   3  u does not depend on the method, on how much traffic a policy
%      generates, or on the outer step, so it cannot be consumed at
%      different rates by different policies.
%
% State-event and Causal-v3 have no periodic clock and never read this.
%
% The offsets are continuous, but a transmission still happens on an
% outer step, so the REALIZED phase is quantised to cfg.swarm.dt. At
% dt = 0.02 s against a 0.05 s period that is a coarse grid, and it is
% reported rather than hidden: the point of the change is that senders
% stop firing in lockstep, not that phase is resolved to arbitrary
% precision.

N = cfg.swarm.N;

% Dedicated stream. The offset is distinct from the forward trace
% (20240001), reverse trace (30240001), link fault (50240001), blackout
% (60240001), external force (70240001) and estimator noise (80240001),
% so adding phase perturbs no other realization.
seed = mod(cfg.net.seed + 90240001, 2^32);

stream = RandStream('mt19937ar', 'Seed', seed);

trace.u = rand(stream, N+1, 1);

trace.seed   = cfg.net.seed;
trace.N      = N;
trace.nClass = N + 1;

trace.hash = realizationHash(trace.u);

end
