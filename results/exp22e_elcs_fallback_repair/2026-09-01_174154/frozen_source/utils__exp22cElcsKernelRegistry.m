function R=exp22cElcsKernelRegistry()
%EXP22CELCSKERNELREGISTRY Activation-corrected fresh-seed v2 validation.

R=exp22bElcsKernelRegistry();
R.version='EXP22C-ELCS-F-KERNEL-ACTIVATION-v2';
R.stage='candidate-kernel-activation-corrected-validation';
R.seeds=(16042001:16042100)';
R.requiredDeterministicContracts=14;
R.parentInvalidRun='2026-09-01_165537';
R.parentInvalidGates='15/16';
R.reconfigurationSlotRule='first-feasible-higher-conflict-color';
R.activationCorrection=[ ...
    'choose a feasible slot already occupied by a higher-ID conflict ' ...
    'client in each topology'];
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);

end
