function R=exp22eElcsClosedLoopRegistry()
%EXP22EELCSCLOSEDLOOPREGISTRY Fresh-seed repaired ELCS-F integration.

R=exp22dElcsClosedLoopRegistry();
R.version='EXP22E-ELCS-F-CLOSED-LOOP-REPAIR-VALIDATION-v1';
R.stage='candidate-fallback-repair-closed-loop-validation';
R.seeds=(16046001:16046030)';
R.parentInvalidRun='2026-09-01_173320';
R.parentInvalidGates='14/17';
R.parentKernelRun='2026-09-01_174154';
R.parentKernelGates='17/17';
R.fallbackAttemptCapPerNodeFrame=1;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
