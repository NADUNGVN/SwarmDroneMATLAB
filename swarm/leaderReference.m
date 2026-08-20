function ref = leaderReference(t)

% ============================================================
% Leader trajectory
%
% Smooth vertical takeoff: 0 -> 1.2 m during first 3 s
% Then circular XY trajectory.
% ============================================================

zTarget = 1.2;

if t < 3.0

    s = t / 3.0;

    h   = 3*s^2 - 2*s^3;
    hd  = (6*s - 6*s^2) / 3.0;
    hdd = (6 - 12*s) / (3.0^2);

    ref.pos = [0; 0; zTarget*h];
    ref.vel = [0; 0; zTarget*hd];
    ref.acc = [0; 0; zTarget*hdd];

else

    tau = t - 3.0;

    R = 1.0;
    w = 0.20;

    theta = w*tau;

    % Start circle from origin
    ref.pos = [
        R*sin(theta);
        R*(1-cos(theta));
        zTarget
    ];

    ref.vel = [
         R*w*cos(theta);
         R*w*sin(theta);
         0
    ];

    ref.acc = [
        -R*w^2*sin(theta);
         R*w^2*cos(theta);
         0
    ];

end

end