function row=runExp18A3Cell(cfg,method,label,meta,trace,details,certificate)
%RUNEXP18A3CELL Execute one freshness-headroom development trajectory.

base=runExp18A2Cell(cfg,method,label,meta,trace,details,certificate);
row=base;
row.freshnessHeadroomEnabled= ...
    double(cfg.shared.contextAware.freshnessHeadroomEnabled);

end
