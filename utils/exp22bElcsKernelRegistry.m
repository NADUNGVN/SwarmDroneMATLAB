function R=exp22bElcsKernelRegistry()
%EXP22BELCSKERNELREGISTRY Fresh-seed structural-repair validation.

R=exp22ElcsKernelRegistry();
R.version='EXP22B-ELCS-F-KERNEL-REPAIR-v2';
R.stage='candidate-kernel-structural-repair-validation';
R.seeds=(16041001:16041100)';
R.requiredDeterministicContracts=13;
R.deterministicControlSlots=true;
R.automaticRecolor=true;
R.requireReconfigurationRecovery=true;
R.parentInvalidRun='2026-09-01_122201';
R.parentInvalidGates='13/15';
R.repairRationale={ ...
    'node-indexed control minislots remove zero-loss refresh collision'; ...
    'lease-horizon revoke fence permits cascading priority recolor'};
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);

end
