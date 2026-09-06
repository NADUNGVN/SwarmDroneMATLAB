function cfg=applyExp14ICell(cellId,seedValue)
%APPLYEXP14ICELL Build one frozen EXP14I validation cell.

if ~isscalar(seedValue) || ~isfinite(seedValue) || ...
        seedValue<0 || seedValue~=floor(seedValue)
    error('applyExp14ICell: seedValue must be a nonnegative integer.');
end
cellId=lower(strtrim(char(cellId)));
switch cellId
    case 'n5-csma'
        cfg=study2Exp14Config(seedValue,'moderate');
    case 'n10-ring2'
        cfg=applyExp14OODPoint('n10-ring2',seedValue);
    case 'n20-ring2'
        cfg=applyExp14OODPoint('n20-ring2',seedValue);
    case 'n5-aloha'
        cfg=applyExp14OODPoint('aloha-p020',seedValue);
    otherwise
        error('applyExp14ICell: unknown cell "%s".',cellId);
end
cfg.exp14i.version='EXP14I-MAC-SELECTIVE-HOLDOUT-v1';
cfg.exp14i.cell=cellId;
cfg.mac=sharedMediumConfig(cfg);

end
