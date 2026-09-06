% TEST_STATIC_BROADCAST_COHERENCE_SELECTOR_CONTRACTS Fixed-graph fixtures.
startup;
fprintf('\n============================================================\n');
fprintf('test_static_broadcast_coherence_selector_contracts\n');
fprintf('============================================================\n\n');

checks=0; N=4;
neighbor=false(N); neighbor(2,1)=true; neighbor(4,3)=true;
physical=false(N); physical(2,4)=true; physical(4,2)=true;
management=true(N)-eye(N)>0;
C=struct('maxDataSlots',N,'claimBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'maxControlPacketBytes',96);
S=buildStaticBroadcastCoherenceSelector( ...
    neighbor,physical,management,6.8,C);
assert(S.selectedIndex==1 && S.selectedHorizonSec==6.8 && ...
    S.selectedWitnessMap.allCovered && ...
    S.futureRandomReads==0 && S.receiverTruthDecisionReads==0);
fprintf('    ok   feasible fixed topology issues a causal positive horizon\n');
checks=checks+1;

management=false(N);
S=buildStaticBroadcastCoherenceSelector( ...
    neighbor,physical,management,6.8,C);
assert(S.selectedIndex==0 && S.selectedHorizonSec==0);
fprintf('    ok   uncovered fixed topology fails silent\n'); checks=checks+1;

fprintf('\ntest_static_broadcast_coherence_selector_contracts: PASS (%d checks)\n',checks);
