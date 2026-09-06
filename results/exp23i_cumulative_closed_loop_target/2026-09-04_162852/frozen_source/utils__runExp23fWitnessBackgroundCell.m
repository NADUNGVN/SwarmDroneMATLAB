function [row,out]=runExp23fWitnessBackgroundCell( ...
    cfg,method,label,meta,trace,details,family,condition)
%RUNEXP23FWITNESSBACKGROUNDCELL Execute and label one occupancy row.

[src,out]=runExp23dWitnessFrontierCell( ...
    cfg,method,label,meta,trace,details,family);
row=exp23fWitnessBackgroundEmptyRow();
names=fieldnames(src);
for k=1:numel(names), row.(names{k})=src.(names{k}); end
row.loadCondition=char(condition.id);
row.loadConditionLabel=char(condition.label);
row.backgroundModel=char(condition.model);
row.TARGET_BACKGROUND_LOAD=condition.targetLoad;
row.BACKGROUND_OFF_TO_ON=condition.offToOn;
row.BACKGROUND_ON_TO_OFF=condition.onToOff;
row.BACKGROUND_RANDOM_FIELD_HASH_EXACT= ...
    realizationHash(trace.backgroundU(:));
row.REALIZED_BACKGROUND_FRACTION= ...
    row.BACKGROUND_BUSY_TIME/cfg.swarm.T;
K=floor(cfg.swarm.T/cfg.mac.slotTime);
if isfield(trace,'measuredBackgroundActive')
    active=logical(trace.measuredBackgroundActive(1:K));
else
    active=trace.backgroundU(1:K)<condition.targetLoad;
end
row.BACKGROUND_TRANSITION_COUNT=nnz(diff(active)~=0);
starts=find(active & [true;~active(1:end-1)]);
ends=find(active & [~active(2:end);true]);
if isempty(starts)
    row.BACKGROUND_MEAN_ON_RUN_SEC=0;
else
    row.BACKGROUND_MEAN_ON_RUN_SEC=mean(ends-starts+1)*cfg.mac.slotTime;
end

end
