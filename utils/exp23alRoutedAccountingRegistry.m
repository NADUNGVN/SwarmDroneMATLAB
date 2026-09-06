function R=exp23alRoutedAccountingRegistry()
%EXP23ALROUTEDACCOUNTINGREGISTRY Fresh rerun after pre-trace abort.

R=exp23akRoutedAccountingRegistry();
R.version='EXP23AL-ROUTED-INTEGER-ACCOUNTING-v1';
R.frozenDate='2026-09-06';
R.stage='routed-management-integer-accounting-fresh-confirmation';
R.experimentName='exp23al_routed_accounting_confirmation';
R.testScript='test_exp23al_routed_accounting_contracts';
R.planFile='docs/EXP23AL_ROUTED_INTEGER_ACCOUNTING_PLAN.md';
R.registryFile='utils/exp23alRoutedAccountingRegistry.m';
R.testFile='tests/test_exp23al_routed_accounting_contracts.m';
R.entryFile='experiments/exp23al_routed_accounting_confirmation.m';
R.abortedPredecessorRun='2026-09-06_071357';
R.abortedPredecessorStatus= ...
    'ABORTED_BEFORE_REGISTERED_RANDOM_TRACE_ACCEPTANCE';
R.abortedPredecessorRecord=[ ...
    'results/exp23ak_routed_accounting_confirmation/' ...
    '2026-09-06_071357/aborted_verdict.json'];
R.randomReplaySeeds=(16094701:16094718)';

end
