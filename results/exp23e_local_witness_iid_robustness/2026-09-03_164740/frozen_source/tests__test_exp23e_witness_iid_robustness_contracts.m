% TEST_EXP23E_WITNESS_IID_ROBUSTNESS_CONTRACTS Frozen registry checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23e_witness_iid_robustness_contracts\n');
fprintf('============================================================\n\n');

checks=0;
R=exp23eWitnessIidRobustnessRegistry();
assert(numel(R.seeds)==30 && numel(R.cells)==2 && ...
    numel(R.conditions)==5 && numel(R.arms)==2 && ...
    R.expectedRuns==600);
assert(strcmp(R.parentFrontierDecision, ...
    'ELCS_W_SHARP_PERIODIC_FRONTIER_SURVIVES'));
fprintf('    ok   registry freezes 600 fresh paired robustness rows\n');
checks=checks+1;

ids=string({R.conditions.id});
assert(isequal(ids,["clean" "claim-iid5" "response-iid5" ...
    "data-iid5" "joint-iid5"]));
P=[[R.conditions.claimLoss]' [R.conditions.responseLoss]' ...
    [R.conditions.dataLoss]'];
assert(isequal(P,[0 0 0;.05 0 0;0 .05 0;0 0 .05;.05 .05 .05]));
fprintf('    ok   separated and joint 5%% packet-class losses are exact\n');
checks=checks+1;

F=exp23dWitnessFrontierRegistry();
assert(all(abs([R.cells.lowerCostRateHz]- ...
    [F.cells.lowerCostRateHz])<1e-12));
assert(R.requiredCostImprovement==0.01 && R.epsilonRmse==0.01);
assert(~R.policyOptimizationAllowed && ~R.robustnessClaimPermitted && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted);
fprintf('    ok   periodic boundary, kill margins and non-promotion scope persist\n');
checks=checks+1;

fprintf('\ntest_exp23e_witness_iid_robustness_contracts: PASS (%d checks)\n',checks);
