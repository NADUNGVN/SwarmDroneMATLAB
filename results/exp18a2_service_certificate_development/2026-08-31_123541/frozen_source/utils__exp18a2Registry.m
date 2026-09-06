function R=exp18a2Registry()
%EXP18A2REGISTRY Development-only service-certificate amendment.

E=exp18Registry();
R.version='EXP18A2-SERVICE-CERTIFICATE-DEVELOPMENT-v1';
R.stage='development-amendment';
R.seeds=E.seeds;
R.cells=E.cells;
R.coreCells=E.coreCells;
R.boundaryCells=E.boundaryCells;
R.macTypes=E.macTypes;
R.referenceRun=fullfile(projectRoot(),'results', ...
    'exp18a_context_aware_development','2026-08-31_121134');
R.referenceArms={'legacy-selector','frame-piggyback','frame-adaptive'};
R.arm=struct('id','context-aware-v2', ...
    'label','Context-aware service certificate plus marginal value', ...
    'accessDesign','frame-aware','ackDesign','service-certificate-value');
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.macTypes);
R.minimumFeasibleCoreMacCells=5;
R.maxJointlyWorseFeasibleCells=2;
R.minimumCollisionFrameReduction=0.10;
R.futureHoldoutMinimumSeed=16025001;
R.confirmatory=false;
R.futureHoldoutOpened=false;
R.hardwareClaimPermitted=false;
R.superiorityClaimPermitted=false;

end
