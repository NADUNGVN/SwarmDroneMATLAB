function cfg = applyScalableSwarmConfig(cfg,N)

% ============================================================
% APPLYSCALABLESWARMCONFIG
%
% Generate a scalable swarm configuration while preserving
% the main structural properties of the N = 5 baseline.
%
%
% Design:
%
%   - sparse ring communication topology
%   - degree = 2 independent of N
%   - approximately 50% leader pinning
%   - 0.60 m lattice formation spacing
%   - deterministic initialization
%
%
% IMPORTANT:
%
% For the first five agents:
%
%   formation offsets are exactly:
%
%       [ 0.0  0.0  0]
%       [ 0.6  0.0  0]
%       [ 0.0  0.6  0]
%       [-0.6  0.0  0]
%       [ 0.0 -0.6  0]
%
% matching the locked N = 5 configuration.
%
% ============================================================


if N < 5

    error('EXP06A requires N >= 5.');

end


%% ============================================================
% Save original N=5 initialization
% ============================================================

baseInitialPositions = ...
    cfg.swarm.initialPositions;


%% ============================================================
% Number of agents
% ============================================================

cfg.swarm.N = N;


%% ============================================================
% Sparse ring topology
%
% Each receiver obtains data from two neighbors.
%
% Directed channel count:
%
%   nnz(A) = 2N
%
% Hence communication topology remains O(N).
% ============================================================

A = zeros(N,N);


for i = 1:N

    leftNeighbor = ...
        mod(i-2,N) + 1;


    rightNeighbor = ...
        mod(i,N) + 1;


    A(i,leftNeighbor) = 1;

    A(i,rightNeighbor) = 1;

end


cfg.swarm.A = A;


%% ============================================================
% Leader pinning
%
% Preserve N=5 pattern:
%
%   [0 1 0 1 0]
%
% and extend it to larger swarms:
%
%   every second follower receives leader information.
% ============================================================

pin = zeros(N,1);


for i = 2:2:N

    pin(i) = 1;

end


cfg.swarm.pin = pin;


%% ============================================================
% Formation offsets
%
% Expand over a 2-D Manhattan lattice.
%
% Ordering begins:
%
%   center
%   east
%   north
%   west
%   south
%
% therefore reproducing the original five-agent cross.
% ============================================================

spacing = 0.60;


lattice = generateLatticePoints(N);


offsets = zeros(N,3);


offsets(:,1:2) = ...
    spacing * lattice;


cfg.swarm.offsets = offsets;


%% ============================================================
% Initial positions
%
% First five agents preserve the original baseline exactly.
%
% Additional agents begin near their desired formation
% locations with small deterministic perturbations.
%
% No random numbers are used here so network RNG experiments
% remain reproducible.
% ============================================================

P0 = offsets;


P0(1:5,:) = ...
    baseInitialPositions(1:5,:);


for i = 6:N

    perturbation = [
        0.10*sin(1.37*i), ...
        0.10*cos(1.11*i), ...
        0.04*sin(0.83*i)
    ];


    P0(i,:) = ...
        offsets(i,:) ...
        + perturbation;

end


cfg.swarm.initialPositions = ...
    P0;


%% ============================================================
% Initial velocities
% ============================================================

cfg.swarm.initialVelocities = ...
    zeros(N,3);


end


%% ============================================================
% LOCAL FUNCTION
%
% Generate lattice points ordered by Manhattan radius.
%
% For radius 1:
%
%   [ 1  0]
%   [ 0  1]
%   [-1  0]
%   [ 0 -1]
%
% ============================================================

function points = generateLatticePoints(N)

points = [
    0 0
];


radius = 1;


while size(points,1) < N


    candidates = [];


    for x = -radius:radius

        yAbs = ...
            radius ...
            - abs(x);


        candidates(end+1,:) = ...
            [x yAbs]; %#ok<AGROW>


        if yAbs > 0

            candidates(end+1,:) = ...
                [x -yAbs]; %#ok<AGROW>

        end

    end


    %% --------------------------------------------------------
    % Sort counter-clockwise starting from +x axis
    % ---------------------------------------------------------

    theta = ...
        mod( ...
        atan2( ...
        candidates(:,2), ...
        candidates(:,1)), ...
        2*pi);


    [~,order] = ...
        sort(theta);


    candidates = ...
        candidates(order,:);


    %% --------------------------------------------------------
    % Append this shell
    % ---------------------------------------------------------

    for k = 1:size(candidates,1)

        points(end+1,:) = ...
            candidates(k,:); %#ok<AGROW>


        if size(points,1) >= N
            break;
        end

    end


    radius = ...
        radius + 1;

end


points = ...
    points(1:N,:);

end