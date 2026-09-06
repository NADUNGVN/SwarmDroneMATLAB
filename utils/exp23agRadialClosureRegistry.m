function R=exp23agRadialClosureRegistry()
%EXP23AGRADIALCLOSUREREGISTRY Frozen fresh radial-contract matrix.

R=exp23afOnlineClosureRegistry();
R.version='EXP23AG-ONLINE-RADIAL-RECEIVER-CLOSURE-v1';
R.frozenDate='2026-09-05';
R.stage='fresh-online-radial-contraction-validation';
R.parentOnlineRun='2026-09-05_135215';
R.parentOnlineStatus='ONLINE_SWEPT_RECEIVER_CLOSURE_INVALID';
R.parentOnlineGatesPassed=23;
R.parentRadialDiagnosticRun='2026-09-05_142004';
R.parentRadialDiagnosticStatus='RADIAL_CONTRACT_REPAIR_SUPPORTED';
R.calibrationSeeds=(16094101:16094120)';
R.diagnosticWitnessSeed=16094113;
R.seeds=(16094201:16094250)';
R.radialContractVersion='SWEPT-RADIAL-CONTRACTION-CONTRACT-v1';
R.vectorTubeRequired=false;
R.radialConstructionPremiseRequired=true;
R.requiredValidationContracts=25;
R.expectedRuns=numel(R.seeds)*numel(R.arms);
R.registeredFreshRadialSeeds=true;
R.freshRadialContractEvidence=false;
R.repeatedOnlineRenewalValidated=false;
R.managementRelayingValidated=false;
R.freshSeedEvidence=false;
R.robustnessClaimPermitted=false;
R.submissionClaimPermitted=false;

end
