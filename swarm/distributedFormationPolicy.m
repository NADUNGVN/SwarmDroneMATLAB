function accCmd = distributedFormationPolicy( ...
    P, V, leader, cfg, net)

useNetwork = nargin >= 5 && ~isempty(net);
N = cfg.swarm.N;

A       = cfg.swarm.A;
offsets = cfg.swarm.offsets;
pin     = cfg.swarm.pin;

Kp  = cfg.swarm.Kp;
Kv  = cfg.swarm.Kv;


% ============================================================
% Optional consensus degree normalisation (EXP08A-D)
%
% The neighbour consensus terms are SUMS, so effective loop gain
% scales with a follower's CONSENSUS IN-DEGREE d_i = nnz(A(i,:)).
% On sparse6 that is exactly 6, so the gain is 3.0x what Kp/Kv were
% tuned for at degree 2.
%
% Not to be confused with the structural degree reported by
% graphConnectivity, which is 6.84 on the same graph because it
% symmetrises and folds in leader-pin edges. The controller sees
% neither, so 6.84 is the wrong number to reason about here.
%
% When enabled, the neighbour sums are scaled by 2/d_i. The factor is
% exactly 1 at d_i = 2, so ring behaviour is unchanged; that is why
% 2/d_i and not 1/d_i. Leader pinning is deliberately untouched.
%
% Default off, so every locked experiment reproduces unchanged.
% ============================================================

if isfield(cfg.swarm,'normalizeConsensusDegree')
    normalizeDegree = cfg.swarm.normalizeConsensusDegree;
else
    normalizeDegree = false;
end

KpL = cfg.swarm.KpLeader;
KvL = cfg.swarm.KvLeader;

accCmd = zeros(N,3);

% ============================================================
% Agent 1 = leader
% ============================================================

accCmd(1,:) = leader.acc';


% ============================================================
% Followers
% ============================================================

for i = 2:N

    formationTerm = zeros(1,3);
    velocityTerm  = zeros(1,3);

    for j = 1:N

        if A(i,j) == 0
            continue;
        end

        desiredRelative = ...
            offsets(i,:) - offsets(j,:);

        if useNetwork

            Pj = squeeze(net.Pij(i,j,:))';
            Vj = squeeze(net.Vij(i,j,:))';
        
        else
        
            Pj = P(j,:);
            Vj = V(j,:);
        
        end
        
        
        actualRelative = ...
            P(i,:) - Pj;
        
        formationTerm = formationTerm + ...
            (actualRelative - desiredRelative);
        
        velocityTerm = velocityTerm + ...
            (V(i,:) - Vj);
    end

    if normalizeDegree

        di = nnz(A(i,:));

        if di > 0
            degreeScale = 2 / di;
        else
            degreeScale = 1;
        end

    else

        degreeScale = 1;

    end


    ai = ...
        -Kp * degreeScale * formationTerm ...
        -Kv * degreeScale * velocityTerm;


    % ========================================================
    % Leader pinning
    % ========================================================

    if pin(i) > 0

        desiredFromLeader = offsets(i,:);

        if useNetwork

            leaderPos = net.leaderPos(i,:);
            leaderVel = net.leaderVel(i,:);
            leaderAcc = net.leaderAcc(i,:);
        
        else
        
            leaderPos = leader.pos';
            leaderVel = leader.vel';
            leaderAcc = leader.acc';
        
        end
        
        
        positionLeaderError = ...
            (P(i,:) - leaderPos) ...
            - desiredFromLeader;
        
        velocityLeaderError = ...
            V(i,:) - leaderVel;
        
        
        ai = ai ...
            - KpL * positionLeaderError ...
            - KvL * velocityLeaderError ...
            + leaderAcc;

    end


    % ========================================================
    % Acceleration saturation
    % ========================================================

    mag = norm(ai);

    if mag > cfg.swarm.maxAccel
        ai = ai / mag * cfg.swarm.maxAccel;
    end

    accCmd(i,:) = ai;

end

end