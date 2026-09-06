%% TEST_EXP23AD_CLOSURE_KERNEL_CONTRACTS

R=exp23adClosureKernelRegistry();
assert(R.expectedRuns==2400 && R.requiredValidationContracts==24);
assert(~R.closedLoopClaimPermitted && ~R.submissionClaimPermitted);
conditions={'nominal-zero','prepare-blackout','quiescent-blackout', ...
    'response-blackout','commit-blackout','revoke-blackout', ...
    'incomplete-union'};
rows=repmat(exp23adClosureKernelEmptyRow(),numel(conditions),1);
for k=1:numel(conditions)
    rows(k)=runExp23adClosureKernelCell(16091999,5,conditions{k},R);
end
normal=rows(1); prepare=rows(2); quiet=rows(3); response=rows(4);
commit=rows(5); revoke=rows(6); incomplete=rows(7);
assert(normal.allReactivated && normal.motionAuthorized && ...
    normal.collisionFrames==0 && normal.nonincidentSenderChangeCount>0);
assert(~prepare.motionAuthorized && ~quiet.motionAuthorized);
assert(response.motionAuthorized && ~response.commitReady && ...
    response.finalSuppressedCount==response.affectedCount);
assert(commit.commitReady && ~commit.allReactivated && ...
    commit.reactivatedCount==1 && commit.collisionFrames==0);
assert(normal.stateHash==revoke.stateHash);
assert(incomplete.actualSubsetUnion==0);

fprintf('test_exp23ad_closure_kernel_contracts: PASS\n');
