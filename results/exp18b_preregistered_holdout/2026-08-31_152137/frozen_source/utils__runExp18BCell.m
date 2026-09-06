function row=runExp18BCell(cfg,method,label,meta,trace,details,certificate)
%RUNEXP18BCELL Execute and flatten one frozen EXP18B trajectory.

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
row.routeRule=details.routeRule;
row.candidateFlag=details.candidateFlag;
row.routedReference=details.routedReference;

end
