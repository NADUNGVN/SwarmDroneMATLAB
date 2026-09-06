function row=exp14dEmptyRow()
%EXP14DEMPTYROW EXP14 row schema plus explicit factorial metadata.

row=exp14EmptyRow();
row.factorAdaptiveAck=NaN;
row.factorLoadGuard=NaN;
row.factorAccessScaling=NaN;
row.basePAccess=NaN;

end
