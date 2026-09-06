function row=exp14eEmptyRow()
%EXP14EEMPTYROW EXP14 row contract plus frozen holdout metadata.

row=exp14EmptyRow();
row.candidateFlag=NaN;
row.scaledAccess=NaN;
row.historicalReference=NaN;
row.basePAccess=NaN;

end
