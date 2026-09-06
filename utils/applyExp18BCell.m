function cfg=applyExp18BCell(cellId,seedValue)
%APPLYEXP18BCELL Build one frozen EXP18B context without changing EXP18A4.

cfg=applyExp18Cell(cellId,seedValue);
R=exp18bRegistry();
cfg.exp18.version=R.version;
cfg.exp18b.version=R.version;
cfg.exp18b.cell=lower(strtrim(char(cellId)));
cfg.exp18b.confirmatory=true;

end
