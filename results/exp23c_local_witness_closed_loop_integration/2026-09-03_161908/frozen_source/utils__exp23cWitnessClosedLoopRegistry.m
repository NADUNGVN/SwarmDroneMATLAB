function R=exp23cWitnessClosedLoopRegistry()
%EXP23CWITNESSCLOSEDLOOPREGISTRY Frozen ELCS-W closed-loop matrix.

base=exp21dClosedLoopRegistry();
R.version='EXP23C-ELCS-W-CLOSED-LOOP-INTEGRATION-v1';
R.frozenDate='2026-09-03';
R.stage='local-witness-closed-loop-integration-falsification';
R.policyOptimizationAllowed=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.frontierComparisonPermitted=false;
R.seeds=(16059001:16059030)';
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
    'id',{'elcs-w-zero-clock','elcs-w-affine-clock'}, ...
    'label',{'ELCS-W local witness / zero clock', ...
        'ELCS-W local witness / affine clock'}, ...
    'kind',{'clock-paired-reference','candidate-clock-composition'}, ...
    'clockEnabled',{false,true});
R.zeroArm=R.arms(1).id;
R.clockArm=R.arms(2).id;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);
R.requiredIntegrationContracts=18;

end
