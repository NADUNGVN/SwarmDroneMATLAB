function R=exp23tStaticCoherenceClosedLoopRegistry()
%EXP23TSTATICCOHERENCECLOSEDLOOPREGISTRY Frozen static confirmation.

I=exp23iCumulativeClosedLoopRegistry();
R.version='EXP23T-STATIC-COHERENCE-CLOSED-LOOP-v1';
R.frozenDate='2026-09-04';
R.stage='static-coherence-common-phy-closed-loop-confirmation';
R.parentDynamicRun='2026-09-04_180028';
R.parentDynamicStatus='DYNAMIC_COHERENCE_REVOCATION_KERNEL_VALID';
R.policyOptimizationAllowed=false;
R.broadRobustnessClaimPermitted=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16081001:16081100)';
R.cells=I.cells;
R.conditions=I.conditions;
R.arms=struct( ...
    'id',{'periodic-exp23d-lower','coherence-static-short', ...
        'coherence-static-target'}, ...
    'label',{'Periodic static TDMA / EXP23D lower-cost boundary', ...
        'Coherence ELCS-W / static 1 s lease target', ...
        'Coherence ELCS-W / static 6.8 s lease target'}, ...
    'family',{'periodic-static','candidate-elcs-w','candidate-elcs-w'}, ...
    'kind',{'periodic-frontier','coherence-static-short', ...
        'coherence-static-target'}, ...
    'clockEnabled',{false,true,true}, ...
    'horizonSec',{NaN,1,6.8});
R.periodicArm=R.arms(1).id;
R.shortArm=R.arms(2).id;
R.targetArm=R.arms(3).id;
R.maxOffsetSec=I.maxOffsetSec;
R.maxDriftPpm=I.maxDriftPpm;
R.clockLeadTimeSec=I.clockLeadTimeSec;
R.missionSafeGuardSec=I.missionSafeGuardSec;
R.elcsMaxFrames=I.elcsMaxFrames;
R.claimBytes=28;
R.certificateHeaderBytes=16;
R.certificateEntryBytes=10;
R.revokeBytes=24;
R.maxControlPacketBytes=96;
R.requiredManagementReduction=0.75;
R.requiredPeriodicCostAdvantage=0.01;
R.allowedRmseInflationVsShort=0.01;
R.epsilonRmse=0.01;
R.requiredCostImprovement=0.01;
R.bootstrapReplicates=10000;
R.bootstrapSeedBase=16081900;
R.requiredValidationContracts=17;
R.expectedRuns=numel(R.seeds)*numel(R.cells)* ...
    numel(R.conditions)*numel(R.arms);

end
