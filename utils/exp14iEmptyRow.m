function row=exp14iEmptyRow()
%EXP14IEMPTYROW EXP14 row contract plus MAC-selector metadata.

row=exp14EmptyRow();
row.candidateFlag=NaN;
row.route='';
row.macType='';
row.basePAccess=NaN;

end
