%% TEST_LOCAL_UNION_GEOMETRY_BINDING_CONTRACTS

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
p1=p0; p1(10,:)=[-.6 1.2];
state0=struct('p',p0,'v',zeros(N,2), ...
    'positionError',.01*ones(N,1),'velocityError',zeros(N,1), ...
    'accelerationBound',zeros(N,1));
state1=state0; state1.p=p1;
packet=struct('maxDataSlots',9,'claimBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'maxControlPacketBytes',96,'revokeBytes',24);
G=buildCausalLocalUnionGeometryMigration(state0,state1,1,.6,A, ...
    management,10,packet);
assert(G.migration.admissible==1 && G.migration.localOnly==1);
assert(G.migration.addedEdgeCount==1 && G.migration.removedEdgeCount==0);
assert(G.migration.slotChanged==1 && G.migration.oldSlot(10)==7 && ...
    G.migration.newSlot==9);
assert(G.futureRandomReads==0 && G.receiverTruthDecisionReads==0);

oldExact=independentConflict(A,pairDistance(p0)<=.6);
newExact=independentConflict(A,pairDistance(p1)<=.6);
assert(~any(oldExact & ~G.oldBroadcastGraph.senderConflictGraph,'all'));
assert(~any(newExact & ~G.newBroadcastGraph.senderConflictGraph,'all'));

C=struct('maxFrames',80,'transitionFrame',19,'eligibleFrame',22, ...
    'newGraphActivationFrame',20,'lockProofRepeatFrames',20, ...
    'phyRateBps',250e3,'claimErasureProbability',0, ...
    'lockProofErasureProbability',0,'responseErasureProbability',0, ...
    'revokeErasureProbability',0);
T=generateLocalUnionMigrationTrace(16086001,G.migration,C);
slot=8*96/250e3+.003;
dataSlot=8*64/250e3+.003;
P=struct('guardSec',.003,'dataBytes',64, ...
    'horizonSec',80*(2*N*slot+packet.maxDataSlots*dataSlot)+.1);
Q=buildLocalUnionMigrationContinuousSchedule(G.migration,C,T,P);
I=repmat(reshape(G.oldPhysicalGraph|A,1,N,N),C.maxFrames,1,1);
I(C.newGraphActivationFrame:end,:,:)=repmat( ...
    reshape(G.newPhysicalGraph|A,1,N,N), ...
    C.maxFrames-C.newGraphActivationFrame+1,1,1);
Q=bindReplayDataOutcomes(Q,A,I);
assert(Q.expectedDataRecipientSuccess>0);
assert(Q.expectedDataCollisionFrames==0);
assert(Q.expectedDataRecipientCollision==0);
for group=reshape(unique(Q.dataGroup),1,[])
    rows=find(Q.dataGroup==group); tx=Q.dataNode(rows);
    for q=1:numel(rows)
        expected=A(:,Q.dataNode(rows(q)));
        expected(tx)=false;
        actual=Q.dataSuccessMask(rows(q),:)' | ...
            Q.dataErasureMask(rows(q),:)' | Q.dataCollisionMask(rows(q),:)';
        assert(isequal(actual,expected));
    end
end

baseOffsets=zeros(3,3);
changes=struct('timeSec',{1,2},'node',{2,3}, ...
    'newOffset',{[1 0 0],[0 2 0]});
assert(isequal(formationOffsetsAtTime(baseOffsets,changes,.5),baseOffsets));
x=formationOffsetsAtTime(baseOffsets,changes,1.5);
assert(isequal(x(2,:),[1 0 0]) && isequal(x(3,:),[0 0 0]));
x=formationOffsetsAtTime(baseOffsets,changes,2);
assert(isequal(x(3,:),[0 2 0]));

ramp=struct('timeSec',0,'endTimeSec',2,'node',2, ...
    'newOffset',[2 0 0]);
x=formationOffsetsAtTime(baseOffsets,ramp,1);
assert(isequal(x(2,:),[1 0 0]));
x=formationOffsetsAtTime(baseOffsets,ramp,3);
assert(isequal(x(2,:),[2 0 0]));

I0=false(3); I1=logical(eye(3));
events=struct('timeSec',1,'newMatrix',I1);
assert(isequal(interferenceMatrixAtTime(I0,events,.5),I0));
assert(isequal(interferenceMatrixAtTime(I0,events,1),I1));

fprintf('test_local_union_geometry_binding_contracts: PASS\n');

function C=independentConflict(A,I)
N=size(A,1); C=false(N); D=logical(A)|logical(I);
for a=1:N
    for b=a+1:N
        edge=A(b,a)||A(a,b);
        for r=1:N
            edge=edge||(A(r,a)&&D(r,b))||(A(r,b)&&D(r,a));
        end
        C(a,b)=edge; C(b,a)=edge;
    end
end
end

function D=pairDistance(p)
N=size(p,1); D=zeros(N);
for a=1:N
    for b=a+1:N
        D(a,b)=norm(p(a,:)-p(b,:)); D(b,a)=D(a,b);
    end
end
end
