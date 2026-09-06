function cfg=applyExp14FCell(cellId,seedValue)
%APPLYEXP14FCELL Build one EXP14F paired-shadow development cell.

cfg=applyExp14ECell(cellId,seedValue);
cfg.shared.ackValueLogging=struct( ...
    'enabled',true,'schema','ACK-VALUE-EVENT-v1');
cfg.exp14f.version='EXP14F-PAIRED-SHADOW-DEVELOPMENT-v1';
cfg.exp14f.cell=lower(strtrim(char(cellId)));
cfg.mac=sharedMediumConfig(cfg);

end
