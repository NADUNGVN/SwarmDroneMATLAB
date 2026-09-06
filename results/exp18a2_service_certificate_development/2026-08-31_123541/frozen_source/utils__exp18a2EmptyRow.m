function row=exp18a2EmptyRow()
%EXP18A2EMPTYROW EXP18 row plus analytical service certificate.

row=exp18EmptyRow();
row.serviceCertificateEnabled=NaN;
row.serviceCertificateFeasible=NaN;
row.serviceModel='';
row.successfulUpdateRateHz=NaN;
row.requiredUpdateRateHz=NaN;
row.serviceRatio=NaN;
row.backgroundSurvival=NaN;
row.dataSuccessEstimate=NaN;

end
