% TEST_COHERENCE_CERTIFIED_LEASE_CONTRACTS Motion-tube safety fixtures.
startup;
fprintf('\n============================================================\n');
fprintf('test_coherence_certified_lease_contracts\n');
fprintf('============================================================\n\n');

checks=0;
state=struct('p',[0 0;10 0],'v',[0 0;-1 0], ...
    'positionError',0,'velocityError',0,'accelerationBound',0);
short=buildReachableConflictSupergraph(state,2,1,false(2));
long=buildReachableConflictSupergraph(state,10,1,false(2));
assert(~short.potentialGraph(1,2) && long.potentialGraph(1,2));
fprintf('    ok   approaching non-edge enters only the longer-horizon supergraph\n');
checks=checks+1;

horizons=[0.5 1 2 4 8];
previous=false(2);
for h=horizons
    G=buildReachableConflictSupergraph(state,h,1,false(2));
    assert(all(~previous(:) | G.potentialGraph(:)));
    previous=G.potentialGraph;
end
fprintf('    ok   potential-conflict graph grows monotonically with horizon\n');
checks=checks+1;

fresh=state; stale=state;
fresh.positionError=0; stale.positionError=5;
Gfresh=buildReachableConflictSupergraph(fresh,2,1,false(2));
Gstale=buildReachableConflictSupergraph(stale,2,1,false(2));
assert(~Gfresh.potentialGraph(1,2) && Gstale.potentialGraph(1,2));
fprintf('    ok   larger causal state uncertainty can only add an edge\n');
checks=checks+1;

state=struct('p',[0 0;5 0;12 0],'v',[0 0;0.2 0;-1 0], ...
    'positionError',[0.1;0.1;0.1], ...
    'velocityError',[0.05;0.05;0.05], ...
    'accelerationBound',[0.1;0.1;0.1]);
G=buildReachableConflictSupergraph(state,5,1,false(3));
color=elcsWitnessPriorityColor(G.potentialGraph);
for tau=linspace(0,5,101)
    actual=state.p+state.v*tau;
    for i=1:3
        for j=i+1:3
            if norm(actual(i,:)-actual(j,:))<=1
                assert(G.potentialGraph(i,j) && color(i)~=color(j));
            end
        end
    end
end
fprintf('    ok   every fixture conflict is covered by a differently colored edge\n');
checks=checks+1;

selectorState=struct('p',[0 0;0.8 0;4 0],'v',[0 0;0 0;-0.5 0], ...
    'positionError',0,'velocityError',0,'accelerationBound',0);
C=struct('interferenceRadius',1,'managementReach',true(3), ...
    'maxDataSlots',2,'claimBytes',24,'certificateHeaderBytes',16, ...
    'certificateEntryBytes',8,'maxControlPacketBytes',96, ...
    'mandatoryConflictGraph',false(3));
S=selectCoherenceLeaseHorizon(selectorState,[1 2 4 8],C);
assert(S.selectedHorizonSec<8 && S.selectedHorizonSec>0 && ...
    S.futureRandomReads==0 && S.receiverTruthDecisionReads==0);
assert(all(diff(S.edgeCount)>=0));
fprintf('    ok   selector contracts horizon when the supergraph exceeds slots\n');
checks=checks+1;

C.managementReach=eye(3)>0;
S=selectCoherenceLeaseHorizon(selectorState,[1 2 4 8],C);
assert(S.selectedHorizonSec==0 && ~any(S.feasible));
fprintf('    ok   uncovered potential edges fail silent with no issued horizon\n');
checks=checks+1;

A=struct('p',[0 0],'v',[1 0],'positionError',0.1, ...
    'velocityError',0.05,'accelerationBound',0.5, ...
    'issuedAt',0,'expiryTime',10,'tupleVersion',3);
current=struct('p',[2 0],'v',[1 0],'a',[0.1 0],'time',2);
D=coherenceSelfRevocationDecision(A,current,0.1);
assert(~D.selfRevokeRequired && D.scheduledUsePermitted && ...
    ~D.revokeDeliveryRequiredForSafety);
current.a=[1 0];
D=coherenceSelfRevocationDecision(A,current,0.1);
assert(D.selfRevokeRequired && ~D.scheduledUsePermitted && ...
    D.accelerationViolation);
fprintf('    ok   excessive planned acceleration triggers local fail-silent revoke\n');
checks=checks+1;

current=struct('p',[20 0],'v',[1 0],'a',[0 0],'time',2);
D=coherenceSelfRevocationDecision(A,current,0.1);
assert(D.selfRevokeRequired && D.currentOutsideTube);
current=struct('p',[10 0],'v',[1 0],'a',[0 0],'time',10);
D=coherenceSelfRevocationDecision(A,current,0.1);
assert(~D.selfRevokeRequired && ~D.scheduledUsePermitted && ...
    ~D.leaseUnexpired);
fprintf('    ok   tube violation revokes while natural expiry simply disables lease\n');
checks=checks+1;

hiddenState=struct('p',[-2 0;2 0;0 0],'v',zeros(3,2), ...
    'positionError',0,'velocityError',0,'accelerationBound',0);
neighbor=false(3); neighbor(3,1)=true; neighbor(3,2)=true;
B=buildReachableBroadcastConflictSupergraph( ...
    hiddenState,1,2.1,neighbor,false(3));
assert(~B.potentialInterferenceGraph(1,2) && ...
    B.senderConflictGraph(1,2));
fprintf('    ok   receiver-lift exposes conflict between distant hidden senders\n');
checks=checks+1;

reachOnlyState=struct('p',[-1.4 0;1.4 0;0 0],'v',zeros(3,2), ...
    'positionError',0,'velocityError',0,'accelerationBound',0);
reachOnly=false(3); reachOnly(3,1)=true; reachOnly(3,2)=true;
B=buildReachableBroadcastConflictSupergraph( ...
    reachOnlyState,1,1,reachOnly,false(3));
assert(~B.potentialInterferenceGraph(3,1) && ...
    ~B.potentialInterferenceGraph(3,2) && ...
    B.senderConflictGraph(1,2));
fprintf(['    ok   common intended receiver conflicts survive when DATA reach ' ...
    'extends beyond interference graph\n']);
checks=checks+1;

fprintf('\ntest_coherence_certified_lease_contracts: PASS (%d checks)\n',checks);
