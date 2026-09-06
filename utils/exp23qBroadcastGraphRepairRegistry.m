function R=exp23qBroadcastGraphRepairRegistry()
%EXP23QBROADCASTGRAPHREPAIRREGISTRY Frozen graph-repair validation matrix.

R=exp23oBroadcastCoherenceRegistry();
R.version='EXP23Q-BROADCAST-DETECTABILITY-GRAPH-REPAIR-v1';
R.frozenDate='2026-09-04';
R.stage='broadcast-detectability-graph-repair-falsification';
R.seeds=(16078001:16078100)';
R.parentInvalidRun='2026-09-04_172817';
R.parentInvalidStatus='COHERENCE_ELCS_W_PACKET_KERNEL_INVALID';
R.graphDefinition='receiver lift of physical interference OR DATA reach';
R.oracleImplementation='independent receiver/pair enumeration';
R.requiredValidationContracts=19;
R.expectedRuns=numel(R.seeds)*numel(R.nodeCounts)*numel(R.conditions);

end
