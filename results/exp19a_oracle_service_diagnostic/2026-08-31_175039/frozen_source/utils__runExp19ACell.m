function row=runExp19ACell(cfg,method,label,meta,trace,details)
%RUNEXP19ACELL Execute and flatten one EXP19A trajectory.

[base,out]=runExp14Cell(cfg,method,label,meta,trace);
row=base;
row.originalMacType=details.originalMacType;
row.armKind=details.kind;
row.route=details.route;
row.accessDesign=details.accessDesign;
row.ackDesign=details.ackDesign;
row.schedulerMode=details.schedulerMode;
row.oracleFlag=details.oracleFlag;
row.PERIODIC_RATE_HZ=details.periodicRateHz;

R=exp19aRegistry();
row.TARGET_RATE_HZ=R.targetRateHz;
active=any(out.topology,1)';
nodeGoodput=out.netStats.perNodeDataFramesDeliveredAny(active)/ ...
    max(cfg.swarm.T,eps);
row.MEAN_NODE_GOODPUT_HZ=mean(nodeGoodput);
row.MIN_NODE_GOODPUT_HZ=min(nodeGoodput);
row.MEAN_GOODPUT_MARGIN_HZ=row.MEAN_NODE_GOODPUT_HZ-R.targetRateHz;
row.MIN_GOODPUT_MARGIN_HZ=row.MIN_NODE_GOODPUT_HZ-R.targetRateHz;

S=out.serviceScheduler;
row.SERVICE_ADMISSIONS=sum(S.admitted);
row.SERVICE_COMPLETIONS=sum(S.completed);
row.SERVICE_REPLACEMENTS=out.netStats.supersededBeforeService;
row.VIRTUAL_DEFICIT_MAX=max(S.maxVirtualDeficit(active));
row.VIRTUAL_DEFICIT_TERMINAL=sum(S.virtualDeficit(active));
row.MAX_STARVATION_SEC=max(S.maxStarvationInterval(active));
row.SERVICE_DECISIONS=S.decisionCount;
row.FIFO_COMPARABLE_DECISIONS=S.fifoComparableDecisionCount;
row.PRIORITY_DIFFERS_FIFO=S.priorityDiffersFifoCount;
row.PRIORITY_DIFFERS_FIFO_FRACTION=S.priorityDiffersFifoCount/ ...
    max(S.fifoComparableDecisionCount,1);
row.RECEIVER_TRUTH_READS=S.receiverTruthReadCount;
row.FUTURE_RANDOM_READS=S.futureRandomReadCount;
row.SERVICE_DECISION_LOG_VALID=double(validateDecisionLog( ...
    out.netLogs.serviceDecisions,S));
row.ENDOGENOUS_COLLISION_FRAMES=max(0, ...
    row.COLLISION_FRAMES-row.BACKGROUND_COLLISION_FRAMES);

end


function ok=validateDecisionLog(logs,S)

if ~S.config.enabled
    ok=isempty(logs) && S.decisionCount==0;
    return;
end
ok=numel(logs)==S.decisionCount;
for k=1:numel(logs)
    d=logs(k);
    eligible=reshape(d.eligibleNodes,[],1);
    weights=reshape(d.weights,[],1);
    ok=ok && d.ordinal==k && any(eligible==d.selectedNode) && ...
        d.selectedFrameGenTime<=d.time+1e-12 && ...
        ~d.futureRandomRead && strcmp(d.mode,S.config.mode);
    if S.config.oracle
        idx=find(eligible==d.selectedNode,1);
        ok=ok && numel(weights)==numel(eligible) && ...
            all(isfinite(weights)) && ...
            weights(idx)>=max(weights)-1e-12;
    else
        ok=ok && all(isnan(weights));
    end
end

end
