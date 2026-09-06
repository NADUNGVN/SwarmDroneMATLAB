function R=exp23kHorizonScaledRegistry()
%EXP23KHORIZONSCALEDREGISTRY Frozen renewal-horizon development probe.

I=exp23iCumulativeClosedLoopRegistry();
B=elcsWitnessKernelConfig(5,I.elcsMaxFrames);
R.version='EXP23K-ELCS-W-HORIZON-SCALED-DEVELOPMENT-v1';
R.frozenDate='2026-09-04';
R.stage='horizon-scaled-renewal-development';
R.policyOptimizationAllowed=false;
R.newMethodPromotionAllowed=false;
R.broadRobustnessClaimPermitted=false;
R.submissionClaimPermitted=false;
R.sourceRun='2026-09-04_162852';
R.sourceDecision='ELCS_W_CUMULATIVE_TARGET_SURVIVES';
R.sourceRelativePeriodicRmse=0.010076223;
R.seeds=I.seeds;
R.cells=I.cells;
R.conditions=I.conditions;
R.arm=struct('id','elcs-w-cumulative-horizon9', ...
    'label','ELCS-W cumulative receipts / 9x renewal horizon', ...
    'family','candidate-elcs-w','cumulativeReceiptRetry',true);
R.baselineRenewalPeriodFrames=B.renewalPeriodFrames;
R.baselineLeaseFrames=B.leaseFrames;
R.refreshLeadFrames=B.refreshLeadFrames;
R.leaseFenceFrames=B.leaseFenceFrames;
R.renewalScaleFactor=9;
R.renewalPeriodFrames=R.renewalScaleFactor* ...
    R.baselineRenewalPeriodFrames;
R.leaseFrames=R.renewalPeriodFrames+ ...
    R.refreshLeadFrames+R.leaseFenceFrames;
R.maxOffsetSec=I.maxOffsetSec;
R.maxDriftPpm=I.maxDriftPpm;
R.clockLeadTimeSec=I.clockLeadTimeSec;
R.missionSafeGuardSec=I.missionSafeGuardSec;
R.elcsMaxFrames=I.elcsMaxFrames;
R.requiredManagementReduction=0.75;
R.requiredPeriodicCostAdvantage=0.01;
R.allowedRmseInflation=0.01;
R.bootstrapReplicates=10000;
R.bootstrapSeedBase=16073900;
R.realizedFractionPairTolerance=1e-12;
R.requiredValidationContracts=16;
R.expectedRuns=numel(R.seeds);

end
