function R=exp22hElcsKernelRegistry()
%EXP22HELCSKERNELREGISTRY Event-driven renewal kernel validation.

R=exp22eElcsKernelRegistry();
R.version='EXP22H-ELCS-EVENT-DRIVEN-RENEWAL-v4';
R.stage='candidate-event-driven-control-redesign';
R.seeds=(16049001:16049100)';
R.requiredDeterministicContracts=17;
R.parentNegativeRun='2026-09-01_182938';
R.parentNegativeVerdict='ELCS_EPSILON_DOMINATED_RETURN_TO_DESIGN';
R.discoveryPeriodRule='leaseFrames';
R.grantRequiresDecodedRequest=true;
R.zeroLossCertificationDeadlineRule='N';
R.analyticalControlBoundRequired=true;
R.repairRationale=[ ...
    'sparse discovery advertises tuples; explicit event-driven renewal ' ...
    'requests alone create owner GRANT traffic'];
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);

end
