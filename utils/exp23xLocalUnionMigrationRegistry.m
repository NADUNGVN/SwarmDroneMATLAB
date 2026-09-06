function R=exp23xLocalUnionMigrationRegistry()
%EXP23XLOCALUNIONMIGRATIONREGISTRY Randomized kernel falsification matrix.

R=struct();
R.version='EXP23X-LOCAL-UNION-MIGRATION-KERNEL-v1';
R.frozenDate='2026-09-04';
R.stage='local-union-graph-migration-randomized-falsification';
R.parentHoldoutRun='2026-09-04_225232';
R.parentHoldoutStatus='FAST_REACTIVATION_FIXED_GRAPH_CONFIRMED';
R.seeds=(16084001:16084100)';
R.swarmSizes=[5 10 20];
R.cases=struct( ...
    'id',{'zero-loss-valid','iid20-valid','iid40-valid', ...
        'response-blackout','revoke-blackout','stale-response', ...
        'incomplete-union','concurrent-migration', ...
        'missing-witness','over-mtu'}, ...
    'kind',{'valid','valid','valid','response-blackout', ...
        'revoke-blackout','stale-response','incomplete-union', ...
        'concurrent','missing-witness','over-mtu'}, ...
    'erasureProbability',{0,0.2,0.4,0.2,0.2,0.2,0.2,0.2,0.2,0.2});
R.maxFrames=60;
R.transitionFrame=8;
R.newGraphActivationFrame=9;
R.eligibleFrame=12;
R.lockProofRepeatFrames=20;
R.phyRateBps=250e3;
R.claimBytes=28;
R.certificateHeaderBytes=16;
R.certificateEntryBytes=10;
R.revokeBytes=24;
R.maxControlPacketBytes=96;
R.requiredValidationContracts=21;
R.freshSeedEvidence=false;
R.policyOptimizationAllowed=false;
R.closedLoopClaimPermitted=false;
R.submissionClaimPermitted=false;
R.expectedRuns=numel(R.seeds)*numel(R.swarmSizes)*numel(R.cases);

end
