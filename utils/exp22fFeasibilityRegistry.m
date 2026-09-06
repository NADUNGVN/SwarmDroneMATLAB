function R=exp22fFeasibilityRegistry()
%EXP22FFEASIBILITYREGISTRY Frozen direct-baseline kill-test matrix.

base=exp21dClosedLoopRegistry();
R.version='EXP22F-DIRECT-FEASIBILITY-KILL-TEST-v1';
R.frozenDate='2026-09-01';
R.stage='candidate-feasibility-falsification';
R.policyOptimizationAllowed=false;
R.confirmationAllowed=false;
R.robustnessContinuationPermitted=false;
R.submissionClaimPermitted=false;
R.seeds=(16047001:16047030)';
R.cells=base.cells;
R.periodicRates=[5 25/3 10 12.5 15 17.5 20 25];
R.maxOffsetSec=0.25e-3;
R.maxDriftPpm=40;
R.clockHorizonSec=12;
B=continuousTdmaGuardBound( ...
    R.maxOffsetSec,R.maxDriftPpm,R.clockHorizonSec);
R.clockLeadTimeSec=B.maxBoundaryErrorSec;
R.missionSafeGuardSec=B.safeGuardSec;
R.elcsMaxFrames=400;
R.dominanceMargin=0.01;
R.arms=repmat(struct('id','','label','','family','', ...
    'periodicRateHz',NaN),numel(R.periodicRates)+2,1);
for k=1:numel(R.periodicRates)
    rate=R.periodicRates(k);
    R.arms(k).id=sprintf('periodic-static-p%s',rateToken(rate));
    R.arms(k).label=sprintf('Periodic static TDMA %.6g Hz',rate);
    R.arms(k).family='periodic-static';
    R.arms(k).periodicRateHz=rate;
end
R.arms(end-1)=struct('id','dstr-native-mission-affine', ...
    'label','D-STR native / mission affine clock', ...
    'family','prior-art-dstr','periodicRateHz',50);
R.arms(end)=struct('id','elcs-f-mission-affine', ...
    'label','ELCS-F / mission affine clock', ...
    'family','candidate-elcs','periodicRateHz',50);
R.dstrArm=R.arms(end-1).id;
R.elcsArm=R.arms(end).id;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end


function token=rateToken(rate)

token=strrep(sprintf('%.6g',rate),'.','p');

end
