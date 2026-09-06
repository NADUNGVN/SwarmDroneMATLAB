%% TEST_EXP23Z_LOCAL_MIGRATION_CLOSED_LOOP_CONTRACTS

R=exp23zLocalMigrationClosedLoopRegistry();
assert(R.expectedRuns==120 && numel(R.arms)==6);
assert(~R.geometryCoupledToPlant && ~R.submissionClaimPermitted);
assert(strcmp(R.parentCommonPhyStatus,'LOCAL_MIGRATION_COMMON_PHY_VALID'));

smoke=R;
smoke.arms=R.arms(1:2);
rows=runExp23zLocalMigrationClosedLoopSeed(R.seeds(1),smoke);
assert(numel(rows)==2 && all([rows.SAFEFAIL]==0));
candidate=rows(2);
assert(candidate.graphAdmissible==1 && candidate.graphLocalOnly==1);
assert(candidate.graphAddedEdges==1 && candidate.graphRemovedEdges==0);
assert(candidate.oldSlot==7 && candidate.newSlot==9);
assert(candidate.reacquired==1 && candidate.finalSuppressed==0);
assert(candidate.dataOutcomeMismatches==0 && ...
    candidate.dataSkippedNoQueue==0 && candidate.crossPlaneOverlaps==0);
assert(candidate.expectedDataSuccess==candidate.observedDataSuccess);
assert(candidate.expectedDataErasure==candidate.observedDataErasure);
assert(candidate.expectedDataCollision==candidate.observedDataCollision);
assert(candidate.COLLISION_FRAMES==0 && candidate.clockConflictFree==1);
assert(candidate.futureRandomReads==0 && candidate.receiverTruthReads==0);

fprintf('test_exp23z_local_migration_closed_loop_contracts: PASS\n');
