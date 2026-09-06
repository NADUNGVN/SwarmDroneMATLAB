function row=exp17EmptyRow()
%EXP17EMPTYROW EXP14 row contract plus operating-envelope metadata.

row=exp14EmptyRow();
row.route='';
row.factorMacAloha=NaN;
row.factorAdaptive=NaN;
row.coreFlag=NaN;
row.channelRegime='';
row.contextModifier='';
row.basePAccess=NaN;

end
