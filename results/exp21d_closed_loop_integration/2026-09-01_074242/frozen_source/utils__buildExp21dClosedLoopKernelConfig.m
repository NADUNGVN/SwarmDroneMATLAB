function C=buildExp21dClosedLoopKernelConfig(cfg,R)
%BUILDEXP21DCLOSEDLOOPKERNELCONFIG Match D-STR to the common closed-loop PHY.

N=cfg.swarm.N;
graph=logical(cfg.swarm.A) | logical(cfg.swarm.A');
graph(1:N+1:end)=false;
C=struct();
C.N=N;
C.maxFrames=R.maxFrames;
C.initialDataSlots=R.initialDataSlots;
C.maxDataSlots=R.maxDataSlots;
C.collisionThreshold=R.collisionThreshold;
C.growthMargin=R.growthMargin;
C.shrinkThreshold=R.shrinkThreshold;
C.failedShrinkTimeout=R.failedShrinkTimeout;
C.shrinkBackoffExponentCap=R.shrinkBackoffExponentCap;
C.shrinkInitialOrder=(1:N)';
C.retentionProbability=R.retentionProbability;
C.frameBytes=cfg.mac.dataBytes;
C.phyRateBps=cfg.mac.phyRateBps;
C.guardSec=R.safeGuardSec;
C.enableShrink=true;
C.churnEnabled=false;
C.churnFrame=min(60,R.maxFrames);
C.churnNode=min(2,N);
C.dataErasureProbability=0;
C.managementErasureProbability=0;
C.neighborGraph=graph;
C.managementReach=true(N)-eye(N)>0;
C.interferenceMatrix=graph;

end
