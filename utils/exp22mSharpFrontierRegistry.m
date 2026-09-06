function R=exp22mSharpFrontierRegistry()
%EXP22MSHARPFRONTIERREGISTRY Exact 1%-cost periodic boundary closure.

R=exp22kEventDrivenFrontierRegistry();
R.version='EXP22M-SHARP-ONE-PERCENT-FRONTIER-CLOSURE-v1';
R.stage='event-driven-candidate-sharp-frontier-falsification';
R.seeds=(16054001:16054030)';
R.parentValidRun='2026-09-01_195423';
R.parentValidDecision='ELCS_TARGETED_FRONTIER_SURVIVES';
R.boundaryReason=['the most favorable periodic reference satisfying the ' ...
    'required 1% cost reduction lies at the 0.99-cost boundary'];
for k=1:numel(R.cells)
    R.cells(k).lowerCostRateHz=0.99*R.cells(k).costMatchRateHz;
end
R.arms(2).id='periodic-cost-minus1pct';
R.arms(2).label='Periodic static TDMA / 1% below ELCS parent cost';
R.arms(2).rateRule='cost-minus1pct';
R.lowerCostArm=R.arms(2).id;
R.bootstrapSeedBase=16054900;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);

end
