function R=exp23bWitnessRetryRegistry()
%EXP23BWITNESSRETRYREGISTRY Fresh validation after causal retry repair.

R=exp23aWitnessKernelRegistry();
R.version='EXP23B-LOCAL-WITNESS-CAUSAL-RETRY-v1';
R.stage='local-witness-causal-retry-validation';
R.seeds=(16058001:16058100)';
R.parentInvalidRun='2026-09-01_203031';
R.parentInvalidGates='12/14';
R.receiptRetryRequired=true;
R.repair=['each CLAIM increments a sequence; exact witness receipts and ' ...
    'certificate refresh state causally trigger next-frame retries'];
R.boundSemantics=['nominal bound covers scheduled renewal epochs; absolute ' ...
    'bound permits at most one CLAIM/node and one RESPONSE/witness/frame'];
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);

end
