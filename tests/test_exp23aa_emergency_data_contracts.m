%% TEST_EXP23AA_EMERGENCY_DATA_CONTRACTS

R=exp23aaEmergencyDataRegistry();
assert(R.expectedRuns==120 && R.maxDataSlots==10 && R.emergencySlot==10);
assert(~R.freshSeedEvidence && ~R.submissionClaimPermitted);
smoke=R;
smoke.arms=R.arms([1 5 6]);
rows=runExp23zLocalMigrationClosedLoopSeed(R.seeds(1),smoke);
periodic=rows(1); protected=rows(2); silent=rows(3);
assert(periodic.SAFEFAIL==0);
assert(protected.responseBlackout==1 && protected.finalSuppressed==1);
assert(protected.emergencyEnabled==1 && ...
    protected.emergencyOpportunities>0 && protected.emergencySlot==10);
assert(protected.emergencyExpectedSuccess>0 && ...
    protected.emergencyExpectedCollision==0);
assert(protected.SAFEFAIL==0 && protected.COLLISION_FRAMES==0);
assert(silent.emergencyEnabled==0 && silent.SAFEFAIL==1);
assert(protected.dataOutcomeMismatches==0 && ...
    protected.dataSkippedNoQueue==0 && protected.crossPlaneOverlaps==0);

fprintf('test_exp23aa_emergency_data_contracts: PASS\n');
