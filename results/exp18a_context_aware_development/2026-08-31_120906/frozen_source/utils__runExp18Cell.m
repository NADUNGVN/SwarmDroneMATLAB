function row=runExp18Cell(cfg,method,label,meta,trace,details)
%RUNEXP18CELL Execute and flatten one EXP18 development arm.

[base,out]=runExp14Cell(cfg,method,label,meta,trace);
row=base;
row.route=details.route;
row.accessDesign=details.accessDesign;
row.ackDesign=details.ackDesign;
row.coreFlag=double(strcmp(meta.role,'core'));
row.channelRegime=meta.channel;
row.contextModifier=meta.modifier;
row.basePAccess=meta.basePAccess;
row.dataFrameSlots=max(1,ceil((8*cfg.mac.dataBytes/ ...
    cfg.mac.phyRateBps)/cfg.mac.slotTime));

policy=out.contextAwareConfig;
if policy.enabled
    row.calibratedAckSuccessMean=mean(policy.ackSuccessEstimate(:));
    row.calibrationSource=policy.calibrationSource;
end
s=out.netStats;
row.CONTEXT_ACK_EVALUATED=s.contextAckEvaluated;
row.CONTEXT_ACK_PERMITTED=s.contextAckPermitted;
row.CONTEXT_ACK_BLOCKED_FEASIBILITY= ...
    s.contextAckBlockedFeasibility;
row.CONTEXT_ACK_BLOCKED_VALUE=s.contextAckBlockedValue;

end
