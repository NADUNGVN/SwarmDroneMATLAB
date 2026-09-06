% TEST_EXP23S_DYNAMIC_REVOCATION_STUDY_CONTRACTS Matrix preflight.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23s_dynamic_revocation_study_contracts\n');
fprintf('============================================================\n\n');

checks=0; R=exp23sDynamicRevocationRegistry();
P=exp23rCoherencePacketRepairRegistry();
assert(R.expectedRuns==800 && R.requiredValidationContracts==25 && ...
    all(~ismember(R.seeds,P.seeds)));
fprintf('    ok   800-row dynamic matrix uses fresh disjoint seeds\n'); checks=checks+1;

z=runExp23sDynamicRevocationCell( ...
    R.seeds(1),R.nodeCounts(1),R.conditions(1),1,R);
l=runExp23sDynamicRevocationCell( ...
    R.seeds(1),R.nodeCounts(1),R.conditions(2),2,R);
assert(z.PRE_EVENT_ACTIVE==1 && z.EVENT_FRAME_SUPPRESSED==1 && ...
    z.UNSAFE_WINDOW_SUPPRESSED==1 && z.SCHEDULED_COLLISION_FRAMES==0 && ...
    z.REACQUISITIONS==1 && z.FIRST_REACQUIRED_FRAME>z.CAPTURED_FENCE_FRAME);
assert(l.REVOKE_RECIPIENT_ERASURE>0 && ...
    l.SUPPRESSION_HASH_EXACT==z.SUPPRESSION_HASH_EXACT && ...
    l.REACQUIRED_HASH_EXACT==z.REACQUIRED_HASH_EXACT);
fprintf('    ok   delivered/lost REVOKE branches preserve mandatory silence\n');
checks=checks+1;

b=runExp23sDynamicRevocationCell( ...
    R.seeds(1),R.nodeCounts(1),R.conditions(4),4,R);
assert(b.FINAL_SUPPRESSED==1 && b.REACQUISITIONS==0 && ...
    b.SCHEDULED_COLLISION_FRAMES==0);
fprintf('    ok   permanent reacquisition RESPONSE blackout fails silent\n');
checks=checks+1;

fprintf('\ntest_exp23s_dynamic_revocation_study_contracts: PASS (%d checks)\n',checks);
