% TEST_EXP23T_STATIC_COHERENCE_CLOSED_LOOP_CONTRACTS Matrix preflight.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23t_static_coherence_closed_loop_contracts\n');
fprintf('============================================================\n\n');

checks=0; R=exp23tStaticCoherenceClosedLoopRegistry();
S=exp23sDynamicRevocationRegistry();
assert(R.expectedRuns==300 && numel(R.seeds)==100 && ...
    all(~ismember(R.seeds,S.seeds)) && R.requiredValidationContracts==17);
fprintf('    ok   300-row common-PHY matrix uses fresh disjoint seeds\n');
checks=checks+1;

base=applyExp21dClosedLoopCell(R.cells(1).id,R.seeds(1)); N=base.swarm.N;
C=elcsWitnessKernelConfig(N,R.elcsMaxFrames);
C.guardSec=R.missionSafeGuardSec; C.dataBytes=base.mac.dataBytes;
C.phyRateBps=base.mac.phyRateBps;
C.neighborGraph=logical(base.swarm.A);
C.managementReach=C.neighborGraph;
C.interferenceMatrix=logical(base.mac.interferenceMatrix);
spec=struct('maxDataSlots',N,'claimBytes',R.claimBytes, ...
    'certificateHeaderBytes',R.certificateHeaderBytes, ...
    'certificateEntryBytes',R.certificateEntryBytes, ...
    'maxControlPacketBytes',R.maxControlPacketBytes);
selector=buildStaticBroadcastCoherenceSelector(C.neighborGraph, ...
    C.interferenceMatrix,C.managementReach,6.8,spec);
[C,binding]=applyCoherenceLeaseConfig(C,selector);
assert(binding.admissible && C.cumulativeReceiptRetry && ...
    C.claimBytes==28 && C.certificateEntryBytes==10 && ...
    C.coherenceRevokeBytes==24 && C.leaseFrames>20);
fprintf('    ok   target static certificate binds exact metadata and long lease\n');
checks=checks+1;

assert(~R.policyOptimizationAllowed && ~R.broadRobustnessClaimPermitted && ...
    ~R.newMethodPromotionAllowed && ~R.submissionClaimPermitted);
fprintf('    ok   confirmation cannot tune or promote the method\n'); checks=checks+1;

fprintf('\ntest_exp23t_static_coherence_closed_loop_contracts: PASS (%d checks)\n',checks);
