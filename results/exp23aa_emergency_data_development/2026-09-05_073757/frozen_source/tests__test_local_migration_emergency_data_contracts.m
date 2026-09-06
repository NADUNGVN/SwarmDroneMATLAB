%% TEST_LOCAL_MIGRATION_EMERGENCY_DATA_CONTRACTS

N=10;
A=false(N);
edges=[1 2;1 4;1 6;1 8;1 10;2 3;3 4;4 5;5 6;6 7;7 8;8 9;9 10];
for k=1:size(edges,1)
    A(edges(k,1),edges(k,2))=true;
    A(edges(k,2),edges(k,1))=true;
end
management=logical((double(A)+eye(N))^2);
management(1:N+1:end)=false;
p0=[0 0;.6 0;0 .6;-.6 0;0 -.6;1.2 0;.6 .6;0 1.2;-.6 .6;-1.2 0];
v=zeros(N,2); v(10,:)=[.05 .1];
p1=p0; p1(10,:)=p1(10,:)+6*v(10,:);
state0=struct('p',p0,'v',v,'positionError',.05*ones(N,1), ...
    'velocityError',.01*ones(N,1),'accelerationBound',zeros(N,1));
state1=state0; state1.p=p1;
packet=struct('maxDataSlots',10,'claimBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'maxControlPacketBytes',96,'revokeBytes',24);
G=buildCausalLocalUnionGeometryMigration(state0,state1,6,.585,A, ...
    management,10,packet);
assert(G.migration.admissible && G.migration.newSlot==9);
C=struct('maxFrames',90,'transitionFrame',47,'eligibleFrame',50, ...
    'newGraphActivationFrame',48,'lockProofRepeatFrames',20, ...
    'phyRateBps',250e3,'claimErasureProbability',.2, ...
    'lockProofErasureProbability',.2,'responseErasureProbability',.2, ...
    'revokeErasureProbability',.2);
T=generateLocalUnionMigrationTrace(16087001,G.migration,C);
T.responseDeliveryU(C.eligibleFrame:end,10,:)=0;
T.hashExact=localUnionMigrationTraceHash(T);
slot=8*96/250e3+.0015;
P=struct('guardSec',.0015,'dataBytes',96, ...
    'horizonSec',C.maxFrames*(2*N+packet.maxDataSlots)*slot+.01);
Q=buildLocalUnionMigrationContinuousSchedule(G.migration,C,T,P);
Q=addLocalMigrationEmergencyData(Q,G.migration,C,10);
suppressed=find(Q.kernel.debug.suppressed(:,10));
emergency=Q.dataKind=="emergency";
assert(Q.emergencyData.opportunities==numel(suppressed));
assert(isequal(Q.dataFrame(emergency),suppressed));
assert(all(Q.dataNode(emergency)==10) && all(Q.dataSlot(emergency)==10));
physical=repmat(reshape(G.oldPhysicalGraph|A,1,N,N),C.maxFrames,1,1);
physical(C.transitionFrame:end,:,:)=repmat(reshape( ...
    G.unionPhysicalGraph|A,1,N,N),C.maxFrames-C.transitionFrame+1,1,1);
Q=bindReplayDataOutcomes(Q,A,physical);
assert(Q.expectedDataCollisionFrames==0);
assert(all(sum(Q.dataSuccessMask(emergency,:),2)>0));

fprintf('test_local_migration_emergency_data_contracts: PASS\n');
