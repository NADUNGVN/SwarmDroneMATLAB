% TEST_EXP23G_BACKGROUND_GATE_REPAIR_CONTRACTS Gate-only repair checks.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23g_background_gate_repair_contracts\n');
fprintf('============================================================\n\n');

checks=0;
F=exp23fWitnessBackgroundRobustnessRegistry();
G=exp23gWitnessBackgroundGateRepairRegistry();
assert(isempty(intersect(F.seeds,G.seeds)) && numel(G.seeds)==30 && ...
    G.expectedRuns==480);
assert(strcmp(G.parentInvalidDecision, ...
    'ELCS_W_BACKGROUND_ROBUSTNESS_STUDY_INVALID'));
fprintf('    ok   repair rerun uses 30 disjoint fresh seeds\n');
checks=checks+1;

ignore={'version','frozenDate','stage','seeds','parentInvalidRun', ...
    'parentInvalidDecision','repairScope','realizedFractionPairTolerance', ...
    'bootstrapSeedBase'};
f=F; g=G;
for k=1:numel(ignore)
    if isfield(f,ignore{k}), f=rmfield(f,ignore{k}); end
    if isfield(g,ignore{k}), g=rmfield(g,ignore{k}); end
end
assert(isequaln(f,g));
assert(G.realizedFractionPairTolerance==1e-12);
fprintf('    ok   only metadata, seeds, bootstrap and pairing tolerance change\n');
checks=checks+1;

assert(~G.policyOptimizationAllowed && ...
    ~G.broadRobustnessClaimPermitted && ...
    ~G.newMethodPromotionAllowed && ~G.submissionClaimPermitted);
fprintf('    ok   invalid parent cannot authorize tuning or promotion\n');
checks=checks+1;

fprintf('\ntest_exp23g_background_gate_repair_contracts: PASS (%d checks)\n',checks);
