function R=exp22lEventDrivenFrontierRepairRegistry()
%EXP22LEVENTDRIVENFRONTIERREPAIRREGISTRY Fresh gate-repair rerun matrix.

R=exp22kEventDrivenFrontierRegistry();
R.version='EXP22L-EVENT-DRIVEN-FRONTIER-GATE-REPAIR-v1';
R.stage='event-driven-candidate-frontier-gate-repair-rerun';
R.seeds=(16053001:16053030)';
R.parentInvalidRun='2026-09-01_194517';
R.parentInvalidGate='event_driven_request_discipline';
R.repair=['separate full-kernel logical request discipline from ' ...
    'mission-horizon physical management replay accounting'];
R.bootstrapSeedBase=16053900;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
