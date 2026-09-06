function row=runExp18A2Cell(cfg,method,label,meta,trace,details,certificate)
%RUNEXP18A2CELL Execute one development-amendment trajectory.

base=runExp18Cell(cfg,method,label,meta,trace,details);
row=base;
row.serviceCertificateEnabled=double(certificate.enabled);
row.serviceCertificateFeasible=double(certificate.feasible);
row.serviceModel=certificate.model;
row.successfulUpdateRateHz=certificate.successfulUpdateRateHz;
row.requiredUpdateRateHz=certificate.requiredUpdateRateHz;
row.serviceRatio=certificate.serviceRatio;
row.backgroundSurvival=certificate.backgroundSurvival;
row.dataSuccessEstimate=certificate.dataSuccessEstimate;

end
