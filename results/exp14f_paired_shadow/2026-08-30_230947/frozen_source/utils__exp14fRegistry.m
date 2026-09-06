function R=exp14fRegistry()
%EXP14FREGISTRY Paired-shadow ACK-value development design.

R.version='EXP14F-PAIRED-SHADOW-DEVELOPMENT-v1';
R.designDate='2026-08-30';
R.designStatus='development; no confirmatory claim';
R.seeds=(16018001:16018020)';
R.cells=struct( ...
    'id',{'n5-csma','n10-ring2','n20-ring2','n5-aloha'}, ...
    'label',{'N5 CSMA','N10 ring2','N20 ring2','N5 ALOHA'});
R.arms=struct( ...
    'id',{'selected-adaptive-scaled','piggyback-scaled'}, ...
    'label',{'Selected adaptive + scaled','Piggyback-only + scaled'});
R.actualArm='selected-adaptive-scaled';
R.shadowArm='piggyback-scaled';
R.eventSchema='ACK-VALUE-EVENT-v1';
R.matchRule='same-link-first-shadow-genTime-ge-actual-genTime';
R.censorRule='right-censor-at-simulation-horizon';
R.expectedGroups=numel(R.seeds)*numel(R.cells);
R.expectedRuns=R.expectedGroups*numel(R.arms);
R.confirmatoryClaimPermitted=false;
R.newDesignPermitted=false;

end
