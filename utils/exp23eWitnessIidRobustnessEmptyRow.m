function row=exp23eWitnessIidRobustnessEmptyRow()
%EXP23EWITNESSIIDROBUSTNESSEMPTYROW Stable IID robustness schema.

row=exp23dWitnessFrontierEmptyRow();
row.lossCondition='';
row.lossConditionLabel='';
row.CLAIM_LOSS_PROB=NaN;
row.RESPONSE_LOSS_PROB=NaN;
row.DATA_LOSS_PROB=NaN;

end
