function row=exp23fWitnessBackgroundEmptyRow()
%EXP23FWITNESSBACKGROUNDEMPTYROW Stable load-robustness schema.

row=exp23dWitnessFrontierEmptyRow();
row.loadCondition='';
row.loadConditionLabel='';
row.backgroundModel='';
row.TARGET_BACKGROUND_LOAD=NaN;
row.BACKGROUND_OFF_TO_ON=NaN;
row.BACKGROUND_ON_TO_OFF=NaN;
row.BACKGROUND_RANDOM_FIELD_HASH_EXACT=NaN;
row.REALIZED_BACKGROUND_FRACTION=NaN;
row.BACKGROUND_TRANSITION_COUNT=NaN;
row.BACKGROUND_MEAN_ON_RUN_SEC=NaN;

end
