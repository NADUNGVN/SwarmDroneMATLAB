function R=exp18bRegistry()
%EXP18BREGISTRY Frozen capacity-screen and abstention holdout contract.

D=exp18a4Registry();
R.version='EXP18B-CAPACITY-SCREEN-HOLDOUT-v1';
R.frozenDate='2026-08-31';
R.seedStatus='unopened when registry was written';
R.seeds=(16025001:16025100)';
R.developmentSeed=16024999;
R.bootstrapReplicates=10000;
R.bootstrapSeed=18218218;
R.familywiseAlpha=0.05;
R.cells=D.cells;
R.macTypes={'csma','aloha'};
R.arms=struct( ...
    'id',{'capacity-gated-selector','frame-piggyback', ...
        'frame-adaptive','legacy-selector'}, ...
    'label',{'Capacity-gated selector','Frame-aware piggyback', ...
        'Frame-aware adaptive','Legacy MAC-only selector'}, ...
    'accessDesign',{'frame-aware','frame-aware','frame-aware','legacy-n'}, ...
    'ackDesign',{'capacity-gated-mac','piggyback','legacy-adaptive', ...
        'mac-selector'});
R.candidate='capacity-gated-selector';
R.aliasFields=D.aliasFields;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.macTypes)* ...
    numel(R.arms);

R.feasibleTests=struct( ...
    'id',{'H1','H2','H3','H4','H5'}, ...
    'cell',{'n5-moderate-bg0','n5-moderate-bg0', ...
        'n5-stressed-bg0','n10-moderate-bg0','n10-stressed-bg0'}, ...
    'macType',{'csma','aloha','csma','csma','csma'}, ...
    'developmentRatio',{2.942,1.156,2.313,1.421,1.117});
R.abstentionCell='n5-stressed-bg0';
R.abstentionMac='aloha';
R.abstentionComparator='frame-adaptive';
R.abstentionDevelopmentRatio=0.909;
R.n10CollisionCells={'n10-moderate-bg0','n10-moderate-bg30', ...
    'n10-stressed-bg0','n10-stressed-bg30'};
R.accessComparator='legacy-selector';
R.primaryFamilySize=9;
R.primaryMetrics={'RMSE','OFFERED_UTIL','COLLISION_FRAMES'};
R.confirmatory=true;
R.universalOptimalityClaimPermitted=false;
R.populationSafetyClaimPermitted=false;
R.hardwareClaimPermitted=false;
R.flightClaimPermitted=false;

end
