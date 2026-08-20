function cfg = defaultConfig()
%DEFAULTCONFIG Central configuration for the starter project.

cfg.seed = 1;

% ---------- Single quadrotor ----------
cfg.quad.m = 0.060;                         % kg
cfg.quad.g = 9.81;                          % m/s^2
cfg.quad.J = diag([2.5e-5 2.5e-5 4.5e-5]); % kg*m^2
cfg.quad.linearDrag = 0.10;                 % N/(m/s)
cfg.quad.angularDrag = 1.0e-4;              % N*m/(rad/s)
cfg.quad.maxThrust = 2.5 * cfg.quad.m * cfg.quad.g;
cfg.quad.maxTorque = [0.018; 0.018; 0.010]; % N*m

cfg.ctrl.KpPos = [3.0; 3.0; 6.0];
cfg.ctrl.KdPos = [2.8; 2.8; 4.0];
cfg.ctrl.Kr = [0.0100; 0.0100; 0.0065];
cfg.ctrl.Kw = [0.0009; 0.0009; 0.0008];

cfg.single.dt = 0.002;
cfg.single.T = 8.0;
cfg.single.hoverPosition = [0; 0; 1.0];
cfg.single.yaw = 0;

% ---------- Swarm ----------
cfg.swarm.N = 5;
cfg.swarm.dt = 0.02;           % dynamics rate: 50 Hz
cfg.swarm.T = 25.0;
cfg.swarm.kp = 1.6;
cfg.swarm.kv = 1.2;
cfg.swarm.leaderKp = 1.8;
cfg.swarm.leaderKv = 1.5;
cfg.swarm.maxAccel = 2.5;      % m/s^2
cfg.swarm.maxSpeed = 2.0;      % m/s
cfg.swarm.safetyRadius = 0.20; % m
cfg.swarm.connectivityRange = 5.0;

% Desired offsets around leader in world frame, columns = agents.
cfg.swarm.offsets = [ ...
     0.0, -0.8,  0.8, -0.8,  0.8;
     0.0, -0.8, -0.8,  0.8,  0.8;
     0.0,  0.0,  0.0,  0.0,  0.0];

% Undirected ring + leader links. Agent 1 is leader/pinned agent.
A = zeros(cfg.swarm.N);
for i = 1:cfg.swarm.N
    j = mod(i, cfg.swarm.N) + 1;
    A(i,j) = 1;
    A(j,i) = 1;
end
for j = 2:cfg.swarm.N
    A(1,j) = 1;
    A(j,1) = 1;
end
cfg.swarm.adjacency = A;

% ---------- Communication ----------
cfg.net.rateHz = 10;
cfg.net.packetLoss = 0.10;
cfg.net.delaySec = 0.10;
cfg.net.maxAoI = 5.0;

%% ============================================================
% Swarm configuration
% ============================================================

cfg.swarm.N = 5;

cfg.swarm.dt = 0.02;
cfg.swarm.T  = 30.0;

% Formation controller gains
cfg.swarm.Kp = 1.8;
cfg.swarm.Kv = 2.2;

% Leader pinning gains
cfg.swarm.KpLeader = 1.5;
cfg.swarm.KvLeader = 1.8;

% Maximum commanded acceleration
cfg.swarm.maxAccel = 2.0;     % m/s^2

% Desired formation offsets relative to leader
% Agent 1 is leader
cfg.swarm.offsets = [
     0.0   0.0   0.0
     0.6   0.0   0.0
     0.0   0.6   0.0
    -0.6   0.0   0.0
     0.0  -0.6   0.0
];

% Undirected ring graph
cfg.swarm.A = [
    0 1 0 0 1
    1 0 1 0 0
    0 1 0 1 0
    0 0 1 0 1
    1 0 0 1 0
];

% Which followers receive leader state directly
cfg.swarm.pin = [
    0
    1
    0
    1
    0
];

% Fixed initial positions
cfg.swarm.initialPositions = [
     0.0   0.0   0.0
    -0.2  -0.4   0.1
     0.4   0.1   0.0
    -0.5   0.4  -0.1
     0.3  -0.5   0.15
];

cfg.swarm.initialVelocities = zeros(cfg.swarm.N,3);

%% ============================================================
% Network configuration
% ============================================================

cfg.net.commPeriod = 0.10;    % [s] 10 Hz communication

cfg.net.packetLoss = 0.0;

cfg.net.seed = 1001;

cfg.net.delay = 0.0;          % [s]

cfg.net.jitterStd = 0.0;      % [s]

end


