function row=exp23dWitnessFrontierEmptyRow()
%EXP23DWITNESSFRONTIEREMPTYROW Stable ELCS-W frontier schema.

row=exp23cWitnessClosedLoopEmptyRow();
row.ENGINE_FAMILY='';
row.TOTAL_MANAGEMENT_ATTEMPTS=NaN;
row.TOTAL_MANAGEMENT_AIRTIME=NaN;
row.TOTAL_MANAGEMENT_UTIL=NaN;
row.TOTAL_OFFERED_UTIL=NaN;
row.REPLAY_FLAG=NaN;

end
