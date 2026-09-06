function R=exp22eElcsKernelRegistry()
%EXP22EELCSKERNELREGISTRY Queue-compatible fallback repair validation.

R=exp22cElcsKernelRegistry();
R.version='EXP22E-ELCS-F-QUEUE-COMPATIBLE-FALLBACK-v3';
R.stage='candidate-kernel-queue-compatible-fallback-validation';
R.seeds=(16045001:16045100)';
R.requiredDeterministicContracts=15;
R.parentInvalidRun='2026-09-01_173320';
R.parentInvalidGates='14/17';
R.fallbackAttemptCapPerNodeFrame=1;
R.repairRationale=[ ...
    'first eligible fallback minislot only; preserves per-frame access ' ...
    'probability and removes duplicate latest-state attempts'];
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);

end
