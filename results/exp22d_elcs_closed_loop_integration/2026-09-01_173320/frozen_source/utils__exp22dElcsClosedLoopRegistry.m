function R=exp22dElcsClosedLoopRegistry()
%EXP22DELCSCLOSEDLOOPREGISTRY Frozen ELCS-F integration matrix.

base=exp21dClosedLoopRegistry();
R.version='EXP22D-ELCS-F-CLOSED-LOOP-INTEGRATION-v1';
R.frozenDate='2026-09-01';
R.stage='candidate-model-integration-falsification';
R.policyOptimizationAllowed=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.robustnessContinuationPermitted=false;
R.seeds=(16044001:16044030)';
R.cells=base.cells;
R.maxFrames=400;
R.maxOffsetSec=0.25e-3;
R.maxDriftPpm=40;
R.clockResetHorizonSec=12;
B=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.clockResetHorizonSec);
R.clockLeadTimeSec=B.maxBoundaryErrorSec;
R.missionSafeGuardSec=B.safeGuardSec;
R.arms=struct( ...
    'id',{'elcs-mission-zero-clock','elcs-mission-affine-clock'}, ...
    'label',{'ELCS-F mission guard / zero clock', ...
        'ELCS-F mission guard / affine clock'}, ...
    'kind',{'clock-paired-reference','candidate-clock-composition'}, ...
    'clockEnabled',{false,true});
R.zeroArm=R.arms(1).id;
R.clockArm=R.arms(2).id;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);
R.requiredIntegrationContracts=12;

end
