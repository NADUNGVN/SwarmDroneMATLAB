%% TEST_MULTI_ORIGIN_ROUTED_CONTROL_CONTRACTS Joint packet relay primitive.
startup;

% Two disconnected route branches can share slots while preserving the
% receive-before-forward dependency of packet A.
N=5; reach=false(N); reach(2,1)=true; reach(3,2)=true; reach(4,5)=true;
physical=false(N);
P1=buildSlottedManagementFloodPlan(reach,physical,1,3,4);
P2=buildSlottedManagementFloodPlan(reach,physical,5,4,4);
S=buildMultiOriginRoutedControlSchedule({P1;P2},[2;2], ...
    ["version-a";"version-b"]);
assert(S.admissible&&S.conflictFree&&S.precedenceExact&& ...
    S.serialSlotCount==6&&S.reservedSlotCount==4&& ...
    S.compactionSlotSavings==2&&S.maximumConcurrentTasks==2);
taskA2=find(S.taskPacket==1&S.taskSender==2);
taskA1=find(S.taskPacket==1&S.taskSender==1);
assert(S.taskStartSlot(taskA2)>S.taskEndSlot(taskA1));

U={ones(N,N,2);ones(N,N,2)};
O=simulateMultiOriginRoutedControl(S,U,.2,[40;72],250e3,.001,96);
assert(O.allPacketsDelivered&&all(O.packetDelivered)&&O.attempts==6&& ...
    isequal(O.packetAttempts,[4;2])&& ...
    O.physicalBytes==4*40+2*72&& ...
    O.offeredAirtimeSec==8*O.physicalBytes/250e3&& ...
    O.reservedDurationSec==4*(8*96/250e3+.001)&& ...
    O.collisionRecipients==0&&O.crossPacketStateWrites==0&& ...
    O.attemptBoundSatisfied);
B=multiOriginRoutedReliabilityCertificate(S,.2);
C1=repeatedHopManagementFloodReliabilityCertificate(P1,.2,2);
C2=repeatedHopManagementFloodReliabilityCertificate(P2,.2,2);
assert(abs(B.jointSuccessExact- ...
    C1.multicastSuccessExact*C2.multicastSuccessExact)<1e-15&& ...
    B.jointFailureExact<=B.jointFailureUnionUpperBound&& ...
    B.maximumPhysicalAttemptBound==6);

% Packet-A first-hop loss suppresses only its descendant relay. Packet B is
% delivered and never writes packet A's state.
U{1}(2,1,:)=0;
L=simulateMultiOriginRoutedControl(S,U,.2,[40;72],250e3,.001,96);
assert(~L.packetDelivered(1)&&L.packetDelivered(2)&& ...
    ~L.knownPacketNode(1,2)&&~L.knownPacketNode(1,3)&& ...
    L.knownPacketNode(2,4)&&L.attempts==4&& ...
    isequal(L.packetAttempts,[2;2])&&L.crossPacketStateWrites==0);

% Two packets sharing one source cannot overlap at that radio.
Q1=buildSlottedManagementFloodPlan(reach,physical,1,2,4);
Q2=buildSlottedManagementFloodPlan(reach,physical,1,3,4);
Q=buildMultiOriginRoutedControlSchedule({Q1;Q2},[2;2],["q1";"q2"]);
sourceTasks=find(Q.taskSender==1);
assert(Q.taskConflictGraph(sourceTasks(1),sourceTasks(2))&& ...
    Q.taskEndSlot(sourceTasks(1))<Q.taskStartSlot(sourceTasks(2)));
bad=Q; second=sourceTasks(2);
bad.slotTaskMask(:,second)=false;
bad.taskStartSlot(second)=bad.taskStartSlot(sourceTasks(1));
bad.taskEndSlot(second)=bad.taskEndSlot(sourceTasks(1));
bad.slotTaskMask(bad.taskStartSlot(second):bad.taskEndSlot(second), ...
    second)=true;
bad.conflictFree=1; bad.precedenceExact=1; bad.admissible=1;
BO=simulateMultiOriginRoutedControl( ...
    bad,{ones(N,N,2);ones(N,N,2)},.2,[40;40],250e3,.001,96);
assert(BO.collisionRecipients>=1&&~BO.allPacketsDelivered);

fprintf('test_multi_origin_routed_control_contracts: PASS\n');
