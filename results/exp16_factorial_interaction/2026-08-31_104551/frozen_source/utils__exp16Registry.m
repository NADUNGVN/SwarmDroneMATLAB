function R=exp16Registry()
%EXP16REGISTRY Frozen feedback-route-by-MAC interaction contract.

R.version='EXP16-FACTORIAL-INTERACTION-HOLDOUT-v1';
R.frozenDate='2026-08-31';
R.seedStatus='unopened when this registry was written';
R.seeds=(16022001:16022100)';
R.developmentSeed=16021999;
R.bootstrapReplicates=10000;
R.bootstrapSeed=16216216;
R.familywiseAlpha=0.05;
R.primaryMetrics={'RMSE','OFFERED_UTIL'};
R.primaryTestTypes={'csma-simple','aloha-simple','interaction'};
R.baseCell=struct('id','n5-moderate','label','N5 Moderate matched');
R.arms=struct( ...
    'id',{'csma-adaptive','csma-piggyback','csma-fixed-hybrid', ...
        'aloha-adaptive','aloha-piggyback','aloha-fixed-hybrid'}, ...
    'label',{'CSMA adaptive','CSMA piggyback-only', ...
        'CSMA fixed-deadline hybrid','ALOHA adaptive', ...
        'ALOHA piggyback-only','ALOHA fixed-deadline hybrid'}, ...
    'macType',{'csma','csma','csma','aloha','aloha','aloha'}, ...
    'route',{'adaptive','piggyback','fixed-hybrid', ...
        'adaptive','piggyback','fixed-hybrid'}, ...
    'primaryFactorial',{true,true,false,true,true,false});
R.primaryArms={'csma-adaptive','csma-piggyback', ...
    'aloha-adaptive','aloha-piggyback'};
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.primaryFamilySize=numel(R.primaryMetrics)*numel(R.primaryTestTypes);
R.confirmatoryInteractionPermitted=true;
R.generalMacSelectorClaimPermitted=false;
R.namedMacClaimPermitted=false;
R.hardwareClaimPermitted=false;
R.populationSafetyClaimPermitted=false;

end

