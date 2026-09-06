function cfg=applyExp16Cell(seedValue)
%APPLYEXP16CELL Build the matched N5 Moderate EXP16 base cell.

if ~isscalar(seedValue) || ~isfinite(seedValue) || ...
        seedValue<0 || seedValue~=floor(seedValue)
    error('applyExp16Cell: seedValue must be a nonnegative integer.');
end
cfg=study2Exp14Config(seedValue,'moderate');
cfg.exp16.version='EXP16-FACTORIAL-INTERACTION-HOLDOUT-v1';
cfg.exp16.cell='n5-moderate';
cfg.exp16.matchedMacFactor=true;
cfg.mac.type='csma';
cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
cfg.mac=sharedMediumConfig(cfg);

end

