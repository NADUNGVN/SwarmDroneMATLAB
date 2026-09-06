function [row,out]=runExp23dWitnessFrontierCell( ...
    cfg,method,label,meta,trace,details,family)
%RUNEXP23DWITNESSFRONTIERCELL Execute and flatten one frontier row.

if strcmp(family,'candidate-elcs-w')
    [src,out]=runExp23cWitnessClosedLoopCell( ...
        cfg,method,label,meta,trace,details);
else
    [src,out]=runExp21CCell(cfg,method,label,meta,trace,details);
end
row=exp23dWitnessFrontierEmptyRow();
names=fieldnames(src);
for k=1:numel(names), row.(names{k})=src.(names{k}); end
row.ENGINE_FAMILY=char(family);
row.REPLAY_FLAG=double(strcmp(family,'candidate-elcs-w'));
row.TOTAL_MANAGEMENT_ATTEMPTS=0;
row.TOTAL_MANAGEMENT_AIRTIME=0;
if row.REPLAY_FLAG
    row.TOTAL_MANAGEMENT_ATTEMPTS=row.ELCSW_MANAGEMENT_ATTEMPTS;
    row.TOTAL_MANAGEMENT_AIRTIME=row.ELCSW_MANAGEMENT_AIRTIME;
end
row.TOTAL_MANAGEMENT_UTIL=row.TOTAL_MANAGEMENT_AIRTIME/cfg.swarm.T;
row.TOTAL_OFFERED_UTIL=(row.DATA_AIRTIME+row.ACK_AIRTIME+ ...
    row.TOTAL_MANAGEMENT_AIRTIME)/cfg.swarm.T;

end
