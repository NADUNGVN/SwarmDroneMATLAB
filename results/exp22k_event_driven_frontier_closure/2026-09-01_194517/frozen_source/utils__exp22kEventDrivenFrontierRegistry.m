function R=exp22kEventDrivenFrontierRegistry()
%EXP22KEVENTDRIVENFRONTIERREGISTRY Frozen event-driven frontier kill test.

R=exp22gTargetedFrontierRegistry();
R.version='EXP22K-EVENT-DRIVEN-PERIODIC-FRONTIER-CLOSURE-v1';
R.frozenDate='2026-09-01';
R.stage='event-driven-candidate-targeted-frontier-falsification';
R.seeds=(16052001:16052030)';
R.parentClosedLoopRun='2026-09-01_193812';
R.parentClosedLoopGates='20/20';
R.cells(1).parentElcsCost=0.293563733333331;
R.cells(2).parentElcsCost=0.318873599999998;
D=8*96/250e3;
for k=1:numel(R.cells)
    N=5;
    if contains(R.cells(k).id,'n10'), N=10; end
    R.cells(k).costMatchRateHz=R.cells(k).parentElcsCost/(N*D);
    R.cells(k).lowerCostRateHz=0.98*R.cells(k).costMatchRateHz;
end
R.eventDrivenContractRequired=true;
R.grantRequiresDecodedRequest=true;
R.analyticalControlBoundRequired=true;
R.acquisitionDeadlineFrames='N';
R.bootstrapSeedBase=16052900;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
