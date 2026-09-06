function R=exp23rCoherencePacketRepairRegistry()
%EXP23RCOHERENCEPACKETREPAIRREGISTRY Frozen packet graph-repair matrix.

R=exp23pCoherencePacketRegistry();
R.version='EXP23R-COHERENCE-PACKET-GRAPH-REPAIR-v1';
R.frozenDate='2026-09-04';
R.stage='coherence-packet-graph-repair-falsification';
R.seeds=(16079001:16079050)';
R.parentGraphRun='2026-09-04_173841';
R.parentGraphStatus='BROADCAST_DETECTABILITY_GRAPH_REPAIR_VALID';
R.parentPacketInvalidRun='2026-09-04_172817';
R.parentPacketInvalidStatus='COHERENCE_ELCS_W_PACKET_KERNEL_INVALID';
R.parentBroadcastStatus='SUPERSEDED_BY_EXP23Q';
R.graphDefinition='receiver lift of physical interference OR DATA reach';
R.requiredValidationContracts=20;
R.expectedRuns=numel(R.seeds)*numel(R.nodeCounts)* ...
    numel(R.conditions)*numel(R.conditionsNetwork);

end
