function R=exp23mCoherenceGeometryRegistry()
%EXP23MCOHERENCEGEOMETRYREGISTRY Fresh stimulus-repair matrix.

L=exp23lCoherenceGeometryRegistry();
R=L;
R.version='EXP23M-COHERENCE-GEOMETRY-STIMULUS-REPAIR-v1';
R.frozenDate='2026-09-04';
R.stage='coherence-geometry-stimulus-repair';
R.seeds=(16075001:16075100)';
R.parentInvalidRun='2026-09-04_165837';
R.parentInvalidStatus='COHERENCE_GEOMETRY_KERNEL_INVALID';
R.conditions=struct( ...
    'id',{'static-wide-low','mobile-limited-low', ...
        'mobile-limited-high'}, ...
    'positionError',{0.02,0.02,0.30}, ...
    'velocityError',{0.02,0.02,0.10}, ...
    'speedScale',{0,1,1},'accelerationScale',{0,1,1}, ...
    'managementRadius',{inf,1.5,1.5});
R.mobileLowCondition='mobile-limited-low';
R.mobileHighCondition='mobile-limited-high';
R.staticCondition='static-wide-low';
R.requiredValidationContracts=16;
R.expectedRuns=numel(R.seeds)*numel(R.nodeCounts)* ...
    numel(R.conditions);

end
