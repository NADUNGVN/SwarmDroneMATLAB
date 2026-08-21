function cfg = applyTopologyConfig(cfg, N, topology)
%APPLYTOPOLOGYCONFIG Build one of four communication topologies at size N.
%
%   cfg = applyTopologyConfig(cfg, N, topology)
%
% EXP06A used a single degree-2 ring, which makes the channel count exactly
% 2.5N and therefore makes near-linear scaling a property of the topology
% rather than of the method. EXP08A tests whether the conclusions survive
% when the graph changes.
%
% topology:
%
%   'ring2'      degree 2 ring. Identical to applyScalableSwarmConfig, so
%                EXP06A and EXP07 remain reproducible through this path.
%   'sparse4'    degree 4: ring neighbours plus the two at distance 2.
%   'sparse6'    degree 6: adds the two at distance 3.
%   'geometric'  random geometric graph on the formation lattice: every
%                pair within a radius is connected.
%
% All four are DETERMINISTIC given N. That matters more than it looks: if
% the topology moved with the network seed, two methods at the same seed
% would be solving different problems and the paired comparison would be
% meaningless. The geometric graph therefore takes its radius from a
% deterministic sweep rather than from a random draw.
%
% Positions, formation offsets, initial conditions and leader pinning are
% inherited unchanged from applyScalableSwarmConfig, so topology is the only
% thing that varies between arms.

if N < 5
    error('applyTopologyConfig requires N >= 5.');
end


%% ============================================================
% Baseline geometry: offsets, initial conditions, pinning
% ============================================================

cfg = applyScalableSwarmConfig(cfg, N);

offsets = cfg.swarm.offsets;


%% ============================================================
% Topology
% ============================================================

A = zeros(N,N);

switch lower(topology)

    case 'ring2'

        % Left as produced by applyScalableSwarmConfig.
        A = cfg.swarm.A;

    case 'sparse4'

        A = ringWithSkips(N, [1 2]);

    case 'sparse6'

        A = ringWithSkips(N, [1 2 3]);

    case 'geometric'

        A = geometricGraph(offsets);

    otherwise

        error('applyTopologyConfig: unknown topology "%s".', topology);

end

cfg.swarm.A = A;

cfg.swarm.topology = lower(topology);


%% ============================================================
% The leader receives nothing it uses
%
% The controller drives agent 1 straight from the reference, so any
% in-link to it is counted but never read. Removing it keeps the
% channel count honest across topologies of differing degree, where
% the wasted fraction would otherwise vary by arm.
% ============================================================

cfg.swarm.A(1,:) = 0;

end


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function A = ringWithSkips(N, skips)
%RINGWITHSKIPS Circulant graph: connect each node to the given offsets.

A = zeros(N,N);

for i = 1:N
    for s = skips

        left  = mod(i-1-s, N) + 1;
        right = mod(i-1+s, N) + 1;

        A(i,left)  = 1;
        A(i,right) = 1;

    end
end

A = A & ~eye(N);

A = double(A);

end


function A = geometricGraph(offsets)
%GEOMETRICGRAPH Connect every pair within a radius on the formation lattice.
%
% The radius is the smallest lattice multiple that leaves the graph
% connected. Sweeping deterministically rather than drawing at random keeps
% the topology fixed for a given N, which is what lets methods share a seed
% and still be comparable.

N = size(offsets,1);

D = zeros(N,N);

for i = 1:N
    for j = 1:N
        D(i,j) = norm(offsets(i,:) - offsets(j,:));
    end
end

spacing = 0.60;

radius = spacing;

A = zeros(N,N);

for step = 1:40

    A = double(D <= radius + 1e-9) - eye(N);

    A(A < 0) = 0;

    info = graphConnectivity(A, zeros(N,1));

    if info.connected
        return;
    end

    radius = radius + 0.25*spacing;

end

error(['geometricGraph: no radius up to %.2f m connects all %d agents. ' ...
       'The lattice is disconnected, which is a configuration error ' ...
       'rather than a network condition.'], radius, N);

end
