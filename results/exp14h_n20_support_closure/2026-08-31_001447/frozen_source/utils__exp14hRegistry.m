function R=exp14hRegistry()
%EXP14HREGISTRY Frozen N20-only support-closure development design.

R.version='EXP14H-N20-BRANCH-SUPPORT-CLOSURE-v1';
R.designDate='2026-08-31';
R.designStatus='development support closure; no confirmatory claim';
R.seeds=(16020001:16020240)';
R.cells=struct('id','n20-ring2','label','N20 ring2');
R.pilotArm='selected-adaptive-scaled';
R.replayModes={'admit-target','suppress-target'};
R.eventSchema='ACK-BRANCH-REPLAY-v1';
R.localHorizon=0.75;
R.endRule='full-mission-grid; first outer tick at or after local horizon';
R.eligibleStart=8.0;
R.targetEventsPerCell=20;
R.minimumEventsPerCell=12;
R.oneEventPerSeedCell=true;
R.busyBinEdges=[0 0.25 0.50 0.75 inf];
R.ageBinEdges=[0 0.05 0.15 0.35 inf];
R.selectionSalt=14018001;
R.selectionUsesOutcome=false;
R.expectedPilotRuns=numel(R.seeds);
R.maximumReplayPairs=R.targetEventsPerCell;
R.confirmatoryClaimPermitted=false;
R.thresholdTuningPermitted=false;
R.predictorFittingPermitted=false;

end
