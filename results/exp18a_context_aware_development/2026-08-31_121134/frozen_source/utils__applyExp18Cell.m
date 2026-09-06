function cfg=applyExp18Cell(cellId,seedValue)
%APPLYEXP18CELL Reuse EXP17 contexts as declared development conditions.

cfg=applyExp17Cell(cellId,seedValue);
if isfield(cfg,'exp17')
    cfg=rmfield(cfg,'exp17');
end
cfg.exp18.version='EXP18A-CONTEXT-AWARE-DEVELOPMENT-v1';
cfg.exp18.cell=lower(strtrim(char(cellId)));

end
