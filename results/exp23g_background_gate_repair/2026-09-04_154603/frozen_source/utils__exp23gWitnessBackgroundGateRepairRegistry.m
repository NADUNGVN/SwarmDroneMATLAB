function R=exp23gWitnessBackgroundGateRepairRegistry()
%EXP23GWITNESSBACKGROUNDGATEREPAIRREGISTRY Fresh gate-only repair rerun.

R=exp23fWitnessBackgroundRobustnessRegistry();
R.version='EXP23G-ELCS-W-BACKGROUND-GATE-REPAIR-v1';
R.frozenDate='2026-09-03';
R.stage='local-witness-background-gate-repair-falsification';
R.seeds=(16069001:16069030)';
R.parentInvalidRun='2026-09-03_171702';
R.parentInvalidDecision='ELCS_W_BACKGROUND_ROBUSTNESS_STUDY_INVALID';
R.repairScope=[ ...
    'replace exact equality of derived realized-background fractions by ' ...
    'absolute tolerance 1e-12; no condition, arm, policy or decision ' ...
    'threshold changes'];
R.realizedFractionPairTolerance=1e-12;
R.bootstrapSeedBase=16069900;
R.expectedRuns=numel(R.seeds)*numel(R.cells)* ...
    numel(R.conditions)*numel(R.arms);

end
