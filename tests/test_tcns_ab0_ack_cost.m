%% TEST_TCNS_AB0_ACK_COST Exact two-phase offline ACK accounting.

startup;

fprintf('\n=== TCNS AB0 ACK-cost accounting checks ===\n\n');

[cfg,scenario] = tcnsGate6Scenario(27020001,'S2');
scenario.evaluationStart_s = 0;
scenario.horizon_s = 1;
prototype = struct('time_s',NaN,'arrivalTime_s',NaN,'accepted',true, ...
    'receiver',3,'sender',2,'linkClass',"ordinary");
actions = repmat(prototype,3,1);
actions(1).time_s = 0;
actions(1).arrivalTime_s = 0.02;       % pre-scheduling at tick 1
actions(2).time_s = 0.02;
actions(2).arrivalTime_s = 0.02;       % post-scheduling at same tick
actions(3).time_s = 0;
actions(3).arrivalTime_s = 0.02;       % same pre phase/link: cumulative
A = tcnsO1OfflineAckCounts(struct2table(actions),cfg,scenario);
assert(A.c1Count==3 && A.c2Count==2 && A.c2AtMostC1, ...
    'AB0AckCost: two-phase cumulative ACK count is incorrect.');
assert(A.deliveryPhase(1)=="pre-scheduling" && ...
    A.deliveryPhase(2)=="post-scheduling" && ...
    A.deliveryPhase(3)=="pre-scheduling", ...
    'AB0AckCost: delivery-phase classification is incorrect.');

actions(3).receiver = 4;
B = tcnsO1OfflineAckCounts(struct2table(actions),cfg,scenario);
assert(B.c1Count==3 && B.c2Count==3, ...
    'AB0AckCost: distinct links were incorrectly aggregated.');

fprintf('  C1 actions / C2 phase-link summaries          %d / %d\n', ...
    A.c1Count,A.c2Count);
fprintf('  distinct-link preservation                    PASS\n');
fprintf('test_tcns_ab0_ack_cost: PASS\n');
