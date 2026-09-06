function R=exp23oBroadcastCoherenceRegistry()
%EXP23OBROADCASTCOHERENCEREGISTRY Frozen receiver-lift matrix.

R=exp23mCoherenceGeometryRegistry();
R.version='EXP23O-RECEIVER-LIFTED-BROADCAST-COHERENCE-v1';
R.frozenDate='2026-09-04';
R.stage='broadcast-coherence-kernel-falsification';
R.seeds=(16076001:16076100)';
R.parentGeometryRun='2026-09-04_170157';
R.parentGeometryStatus='COHERENCE_GEOMETRY_KERNEL_VALID';
R.dataNeighborRadius=1.5;
R.requiredValidationContracts=17;
R.expectedRuns=numel(R.seeds)*numel(R.nodeCounts)* ...
    numel(R.conditions);

end
