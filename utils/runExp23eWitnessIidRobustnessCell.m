function [row,out]=runExp23eWitnessIidRobustnessCell( ...
    cfg,method,label,meta,trace,details,family,condition)
%RUNEXP23EWITNESSIIDROBUSTNESSCELL Execute and label one robustness row.

[src,out]=runExp23dWitnessFrontierCell( ...
    cfg,method,label,meta,trace,details,family);
row=exp23eWitnessIidRobustnessEmptyRow();
names=fieldnames(src);
for k=1:numel(names), row.(names{k})=src.(names{k}); end
row.lossCondition=char(condition.id);
row.lossConditionLabel=char(condition.label);
row.CLAIM_LOSS_PROB=condition.claimLoss;
row.RESPONSE_LOSS_PROB=condition.responseLoss;
row.DATA_LOSS_PROB=condition.dataLoss;

end
