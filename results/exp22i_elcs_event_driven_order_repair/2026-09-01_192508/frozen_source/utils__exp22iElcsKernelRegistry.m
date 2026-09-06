function R=exp22iElcsKernelRegistry()
%EXP22IELCSKERNELREGISTRY Emission-order repair validation.

R=exp22hElcsKernelRegistry();
R.version='EXP22I-ELCS-EVENT-DRIVEN-ORDER-REPAIR-v4';
R.stage='candidate-event-driven-order-repair-validation';
R.seeds=(16050001:16050100)';
R.requiredDeterministicContracts=18;
R.parentInvalidRun='2026-09-01_191307';
R.parentInvalidGates='19/20';
R.orderRepair=[ ...
    'exclude fenced nodes before emission accounting and preserve ' ...
    'post-reconfiguration forced request'];
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);

end
