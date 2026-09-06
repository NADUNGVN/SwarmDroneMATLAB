function R=exp18Registry()
%EXP18REGISTRY Development-only feasibility/value policy matrix.

R.version='EXP18A-CONTEXT-AWARE-DEVELOPMENT-v1';
R.stage='development';
R.seedStatus='development outcomes may be inspected';
R.seeds=(16024001:16024020)';
R.futureHoldoutSeedsPermitted=false;
R.futureHoldoutMinimumSeed=16025001;
R.materialReductionFraction=0.10;
R.maxJointlyWorseCoreCells=2;

E=exp17Registry();
R.cells=E.cells;
R.coreCells={R.cells(strcmp({R.cells.role},'core')).id};
R.boundaryCells={R.cells(strcmp({R.cells.role},'boundary')).id};
R.macTypes={'csma','aloha'};
R.arms=struct( ...
    'id',{'legacy-selector','frame-piggyback','frame-adaptive', ...
        'context-aware'}, ...
    'label',{'Legacy MAC-only selector','Frame-aware piggyback', ...
        'Frame-aware legacy adaptive','Context-aware feasibility/value'}, ...
    'accessDesign',{'legacy-n','frame-aware','frame-aware','frame-aware'}, ...
    'ackDesign',{'mac-selector','piggyback','legacy-adaptive', ...
        'feasibility-value'});
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.macTypes)* ...
    numel(R.arms);
R.confirmatory=false;
R.multiplicityAdjusted=false;
R.hardwareClaimPermitted=false;
R.superiorityClaimPermitted=false;
R.namedMacClaimPermitted=false;

end
