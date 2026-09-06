function R=exp23lCoherenceGeometryRegistry()
%EXP23LCOHERENCEGEOMETRYREGISTRY Frozen motion-tube kernel matrix.

R.version='EXP23L-COHERENCE-GEOMETRY-KERNEL-v1';
R.frozenDate='2026-09-04';
R.stage='coherence-geometry-kernel-falsification';
R.policyOptimizationAllowed=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16074001:16074100)';
R.nodeCounts=[5 10];
R.conditions=struct( ...
    'id',{'low-uncertainty','high-uncertainty'}, ...
    'positionError',{0.02,0.30}, ...
    'velocityError',{0.02,0.10});
R.horizonsSec=[0.25 0.5 1 2 4 6.8];
R.timeSamplesPerHorizon=41;
R.dimension=2;
R.areaSide=8;
R.nominalSpeedBound=0.6;
R.accelerationBound=0.2;
R.interferenceRadius=1;
R.managementRadius=1.5;
R.maxDataSlotRule='N';
R.claimBytes=24;
R.certificateHeaderBytes=16;
R.certificateEntryBytes=8;
R.maxControlPacketBytes=96;
R.monitorStepSec=0.02;
R.violationAccelerationFactor=1.25;
R.requiredValidationContracts=15;
R.expectedRuns=numel(R.seeds)*numel(R.nodeCounts)* ...
    numel(R.conditions);

end
