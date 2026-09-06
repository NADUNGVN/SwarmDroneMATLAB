%% TEST_EXP23AL_ROUTED_ACCOUNTING_CONTRACTS Fresh post-abort registry.
startup;

R=exp23alRoutedAccountingRegistry();
P0=exp23akRoutedAccountingRegistry();
assert(strcmp(R.version,'EXP23AL-ROUTED-INTEGER-ACCOUNTING-v1')&& ...
    strcmp(R.abortedPredecessorStatus, ...
    'ABORTED_BEFORE_REGISTERED_RANDOM_TRACE_ACCEPTANCE'));
assert(isempty(intersect(R.randomReplaySeeds,P0.randomReplaySeeds))&& ...
    isequal(R.randomReplaySeeds,(16094701:16094718)'));
assert(isfile(fullfile(projectRoot(),R.abortedPredecessorRecord))&& ...
    R.expectedRandomRows==36000&&R.requiredValidationContracts==10);

N=4; reach=false(N); reach(2,1)=true; reach(3,2)=true; reach(4,3)=true;
P=buildSlottedManagementFloodPlan(reach,reach|reach',1,2:4,3);
O=simulateRepeatedHopManagementFlood(P,ones(N),.2,1,72, ...
    R.phyRateBps,R.safeGuardSec);
assert(strcmp(O.version,R.repairedSimulatorVersion)&&O.attempts==3&& ...
    O.offeredAirtimeSec==8*O.bytes/R.phyRateBps);

fprintf('test_exp23al_routed_accounting_contracts: PASS\n');
