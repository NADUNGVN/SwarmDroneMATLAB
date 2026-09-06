function row=exp18EmptyRow()
%EXP18EMPTYROW EXP14 metrics plus feasibility/value development metadata.

row=exp14EmptyRow();
row.route='';
row.accessDesign='';
row.ackDesign='';
row.coreFlag=NaN;
row.channelRegime='';
row.contextModifier='';
row.basePAccess=NaN;
row.dataFrameSlots=NaN;
row.calibratedAckSuccessMean=NaN;
row.calibrationSource='';
row.CONTEXT_ACK_EVALUATED=NaN;
row.CONTEXT_ACK_PERMITTED=NaN;
row.CONTEXT_ACK_BLOCKED_FEASIBILITY=NaN;
row.CONTEXT_ACK_BLOCKED_VALUE=NaN;

end
