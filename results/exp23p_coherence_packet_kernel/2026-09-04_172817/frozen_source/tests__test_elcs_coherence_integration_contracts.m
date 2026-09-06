% TEST_ELCS_COHERENCE_INTEGRATION_CONTRACTS Geometry-to-kernel binding.
startup;
fprintf('\n============================================================\n');
fprintf('test_elcs_coherence_integration_contracts\n');
fprintf('============================================================\n\n');

checks=0;
N=5;
C=elcsWitnessKernelConfig(N,200);
C.neighborGraph=true(N)-eye(N)>0;
C.managementReach=C.neighborGraph;
C.interferenceMatrix=C.neighborGraph;
C.conflictGraph=C.neighborGraph;
state=struct('p',[(0:N-1)' zeros(N,1)],'v',zeros(N,2), ...
    'positionError',0.01,'velocityError',0.01, ...
    'accelerationBound',0.05);
selectorConfig=struct('interferenceRadius',1.1, ...
    'managementReach',C.managementReach,'maxDataSlots',N, ...
    'claimBytes',28,'certificateHeaderBytes',16, ...
    'certificateEntryBytes',10,'maxControlPacketBytes',96, ...
    'mandatoryConflictGraph',false(N), ...
    'dataNeighborGraph',C.neighborGraph);
S=selectCoherenceLeaseHorizon(state,[0.25 1 6.8],selectorConfig);
[C,A]=applyCoherenceLeaseConfig(C,S);
assert(A.admissible && C.coherenceLeaseEnabled && ...
    C.coherenceLeaseAdmissible && C.cumulativeReceiptRetry && ...
    C.claimBytes==28 && C.certificateEntryBytes==10 && ...
    C.leaseFrames==C.coherenceHorizonFrames);
T=generateElcsWitnessTrace(16076001,C);
K=simulateElcsWitnessScheduling(C,T);
assert(K.coherenceLeaseEnabled==1 && K.coherenceLeaseAdmissible==1 && ...
    K.finalAllCertified && K.falseValidEdgeFrames==0 && ...
    K.scheduledCollisionFrames==0 && K.revokeAttempts==0);
fprintf('    ok   admissible horizon binds charged metadata and certifies safely\n');
checks=checks+1;

C0=elcsWitnessKernelConfig(N,80);
C0.neighborGraph=true(N)-eye(N)>0;
C0.managementReach=eye(N)>0;
C0.interferenceMatrix=true(N)-eye(N)>0;
C0.conflictGraph=C0.interferenceMatrix;
selectorConfig.managementReach=C0.managementReach;
S0=selectCoherenceLeaseHorizon(state,[0.25 1 6.8],selectorConfig);
assert(S0.selectedIndex==0);
[C0,A0]=applyCoherenceLeaseConfig(C0,S0);
T0=generateElcsWitnessTrace(16076002,C0);
K0=simulateElcsWitnessScheduling(C0,T0);
assert(~A0.admissible && K0.coherenceLeaseAdmissible==0 && ...
    K0.controlAttempts==0 && K0.scheduledAttempts==0 && ...
    K0.fallbackAttempts>0 && ~K0.finalAllCertified && ...
    K0.falseValidEdgeFrames==0);
fprintf('    ok   no certifiable horizon produces fallback-only fail-silent state\n');
checks=checks+1;

C1=elcsWitnessKernelConfig(N,40);
C1.neighborGraph=true(N)-eye(N)>0;
C1.managementReach=C1.neighborGraph;
C1.interferenceMatrix=C1.neighborGraph;
C1.conflictGraph=C1.neighborGraph;
selectorConfig.managementReach=C1.managementReach;
S1=selectCoherenceLeaseHorizon(state,0.001,selectorConfig);
[C1,A1]=applyCoherenceLeaseConfig(C1,S1);
assert(~A1.admissible && strcmp(A1.reason, ...
    'horizon-shorter-than-renewal-slack'));
fprintf('    ok   horizon below refresh/fence slack cannot issue validity\n');
checks=checks+1;

Cbad=C; Cbad.cumulativeReceiptRetry=false;
failed=false;
try
    simulateElcsWitnessScheduling(Cbad,generateElcsWitnessTrace(16076003,Cbad));
catch
    failed=true;
end
assert(failed);
fprintf('    ok   coherence leases reject non-cumulative receipt state\n');
checks=checks+1;

fprintf('\ntest_elcs_coherence_integration_contracts: PASS (%d checks)\n',checks);
