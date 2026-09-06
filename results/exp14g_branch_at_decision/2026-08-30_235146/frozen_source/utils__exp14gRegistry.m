function R=exp14gRegistry()
%EXP14GREGISTRY Frozen branch-at-decision development design.

R.version='EXP14G-BRANCH-AT-DECISION-DEVELOPMENT-v1';
R.designDate='2026-08-30';
R.designStatus='development; no confirmatory claim or tuning';
R.seeds=(16019001:16019060)';
R.cells=struct( ...
    'id',{'n5-csma','n10-ring2','n20-ring2','n5-aloha'}, ...
    'label',{'N5 CSMA','N10 ring2','N20 ring2','N5 ALOHA'});
R.pilotArm='selected-adaptive-scaled';
R.replayModes={'admit-target','suppress-target'};
R.eventSchema='ACK-BRANCH-REPLAY-v1';
R.localHorizon=0.75;
R.endRule='first-outer-control-tick-at-or-after-local-horizon';
R.eligibleStart=8.0;
R.targetEventsPerCell=20;
R.minimumEventsPerCell=12;
R.oneEventPerSeedCell=true;
R.busyBinEdges=[0 0.25 0.50 0.75 inf];
R.ageBinEdges=[0 0.05 0.15 0.35 inf];
R.selectionSalt=14017001;
R.selectionUsesOutcome=false;
R.expectedPilotRuns=numel(R.seeds)*numel(R.cells);
R.maximumReplayPairs=R.targetEventsPerCell*numel(R.cells);
R.confirmatoryClaimPermitted=false;
R.thresholdTuningPermitted=false;
R.predictorFittingPermitted=false;

end
