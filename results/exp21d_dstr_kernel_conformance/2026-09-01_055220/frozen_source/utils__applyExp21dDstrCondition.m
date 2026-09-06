function [C,details]=applyExp21dDstrCondition(N,condition,R)
%APPLYEXP21DDSTRCONDITION Build one frozen D-STR kernel condition.

C=struct();
C.N=N;
C.maxFrames=R.maxFrames;
C.initialDataSlots=R.initialDataSlots;
C.maxDataSlots=R.maxDataSlots;
C.collisionThreshold=R.collisionThreshold;
C.growthMargin=R.growthMargin;
C.shrinkThreshold=R.shrinkThreshold;
C.failedShrinkTimeout=R.failedShrinkTimeout;
C.retentionProbability=R.retentionProbability;
C.frameBytes=R.frameBytes;
C.phyRateBps=R.phyRateBps;
C.guardSec=R.guardSec;
C.enableShrink=true;
C.churnEnabled=false;
C.churnFrame=R.churnFrame;
C.churnNode=min(R.churnNode,N);
C.dataErasureProbability=0;
C.managementErasureProbability=R.managementLossProbability;

clique=true(N)-eye(N)>0;
hex=compactHexSafetyGraph(N,R.formationSpacingM,R.safetyRadiusM);
C.neighborGraph=hex;
C.managementReach=clique;
C.interferenceMatrix=hex;
topology='compact-hex-safety-graph';

switch char(condition)
    case 'native'
        % Source-native static, synchronized, formation-wide reach.
    case 'beacon-loss'
        C.dataErasureProbability=R.beaconLossProbability;
    case 'restricted-management'
        C.managementReach=hex;
        topology='compact-hex-local-management';
    case 'churn-rejoin'
        C.churnEnabled=true;
    otherwise
        error('applyExp21dDstrCondition: unknown condition %s.',condition);
end

details=struct('condition',char(condition),'topology',topology, ...
    'logicalSlotAlignment',true, ...
    'continuousClockDynamicsIncluded',false);

end


function A=compactHexSafetyGraph(N,spacing,radius)

columns=ceil(sqrt(N));
position=zeros(N,2);
for node=1:N
    row=floor((node-1)/columns);
    column=mod(node-1,columns);
    position(node,:)=[spacing*(column+0.5*mod(row,2)), ...
        spacing*sqrt(3)*row/2];
end
dx=position(:,1)-position(:,1)';
dy=position(:,2)-position(:,2)';
distance=sqrt(dx.^2+dy.^2);
A=distance<=radius+1e-9 & distance>0;

end
