function R=exp22jElcsClosedLoopRegistry()
%EXP22JELCSCLOSEDLOOPREGISTRY Event-driven ELCS integration matrix.

R=exp22eElcsClosedLoopRegistry();
R.version='EXP22J-ELCS-EVENT-DRIVEN-CLOSED-LOOP-v1';
R.stage='candidate-event-driven-closed-loop-integration';
R.seeds=(16051001:16051030)';
R.parentKernelRun='2026-09-01_192508';
R.parentKernelGates='20/20';
R.grantRequiresDecodedRequest=true;
R.analyticalControlBoundRequired=true;
R.requiredIntegrationContracts=15;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
