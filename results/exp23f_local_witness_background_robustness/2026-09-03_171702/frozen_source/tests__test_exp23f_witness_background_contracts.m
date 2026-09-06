% TEST_EXP23F_WITNESS_BACKGROUND_CONTRACTS Frozen registry checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23f_witness_background_contracts\n');
fprintf('============================================================\n\n');

checks=0;
R=exp23fWitnessBackgroundRobustnessRegistry();
assert(numel(R.seeds)==30 && numel(R.cells)==2 && ...
    numel(R.conditions)==4 && numel(R.arms)==2 && ...
    R.expectedRuns==480 && ~ismember(R.pilotSeed,R.seeds));
assert(strcmp(R.parentIidDecision, ...
    'ELCS_W_IID5_ROBUSTNESS_SCREEN_SURVIVES'));
fprintf('    ok   registry freezes 480 fresh rows after the valid IID parent\n');
checks=checks+1;

ids=string({R.conditions.id});
assert(isequal(ids,["clean" "iid-load15" "markov-load15" ...
    "markov-load30"]));
assert(all([R.conditions(3:4).onToOff]==[0.02 0.02]));
for k=3:4
    pi=R.conditions(k).offToOn/( ...
        R.conditions(k).offToOn+R.conditions(k).onToOff);
    assert(abs(pi-R.conditions(k).targetLoad)<1e-12);
end
fprintf('    ok   IID and stationary 50 ms Markov-burst conditions close\n');
checks=checks+1;

F=exp23dWitnessFrontierRegistry();
assert(all(abs([R.cells.lowerCostRateHz]- ...
    [F.cells.lowerCostRateHz])<1e-12));
assert(~R.policyOptimizationAllowed && ...
    ~R.broadRobustnessClaimPermitted && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted);
fprintf('    ok   lower-cost baseline and non-promotion scope remain frozen\n');
checks=checks+1;

fprintf('\ntest_exp23f_witness_background_contracts: PASS (%d checks)\n',checks);
