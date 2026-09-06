function R=exp23aiIntegerAccountingRegistry()
%EXP23AIINTEGERACCOUNTINGREGISTRY Frozen exact-accounting confirmation.

R=exp23ahPhaseReservedClosureRegistry();
R.version='EXP23AI-INTEGER-PHY-ACCOUNTING-v1';
R.frozenDate='2026-09-06';
R.stage='integer-phy-accounting-fresh-confirmation';
R.parentPhaseRun='2026-09-06_001301';
R.parentPhaseStatus='PHASE_RESERVED_RADIAL_CLOSURE_FRESH_INVALID';
R.parentPhaseGatesPassed=26;
R.parentPhaseGatesTotal=27;
R.phaseValidationSeeds=(16094301:16094350)';
R.seeds=(16094401:16094450)';
R.integerAccountingVersion='DSTR-MANAGEMENT-INTEGER-BYTES-v1';
R.requiredValidationContracts=28;
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.registeredPhaseReservedSeeds=false;
R.registeredIntegerAccountingSeeds=true;
R.integerPhyAccountingValidated=false;
R.freshPhaseReservedEvidence=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
