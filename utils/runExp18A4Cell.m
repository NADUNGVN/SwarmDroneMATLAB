function row=runExp18A4Cell(cfg,method,label,meta,trace,details,certificate)
%RUNEXP18A4CELL Execute one capacity-gated-selector development trajectory.

base=runExp18A2Cell(cfg,method,label,meta,trace,details,certificate);
row=base;
row.routeRule=cfg.shared.contextAware.routeRule;

end
