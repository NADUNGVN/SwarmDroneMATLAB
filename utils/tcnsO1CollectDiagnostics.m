function [actions,links,traces] = tcnsO1CollectDiagnostics( ...
    outputs,raw,arms,taskArm,taskScenario,scenarioIds)
%TCNSO1COLLECTDIAGNOSTICS Machine-readable action/link/event O1 logs.

actionCells = cell(numel(outputs),1);
linkCells = cell(numel(outputs),1);
traceCells = cell(numel(outputs),1);
for q = 1:numel(outputs)
    if arms(taskArm(q)).kind~="centralized-state-oracle"
        continue;
    end
    out = outputs{q};
    if isempty(out) || ~isfield(out,'centralizedStateOracleActive')
        continue;
    end
    sid = scenarioIds(taskScenario(q));
    seed = raw.seed(q);
    lambda = arms(taskArm(q)).oracleLambda;
    [cfg,scenario] = tcnsGate6Scenario(seed,sid);

    a = out.oracleActions;
    n = height(a);
    a = addvars(a,repmat(sid,n,1),repmat(seed,n,1), ...
        repmat(lambda,n,1),'Before',1, ...
        'NewVariableNames',{'scenarioId','seed','lambda'});
    actionCells{q} = a;

    [ordinaryReceiver,ordinarySender] = find(cfg.swarm.A>0);
    leaderReceiver = find(cfg.swarm.pin>0);
    receiver = [ordinaryReceiver;leaderReceiver];
    sender = [ordinarySender;ones(size(leaderReceiver))];
    linkClass = [repmat("ordinary",numel(ordinaryReceiver),1); ...
        repmat("pinned-leader",numel(leaderReceiver),1)];
    linkRows = repmat(struct('scenarioId',"",'seed',NaN, ...
        'lambda',NaN,'linkClass',"",'receiver',NaN,'sender',NaN, ...
        'scheduledCount',NaN,'evaluationCount',NaN,'eventCount',NaN, ...
        'acceptedCount',NaN,'failedCount',NaN),numel(receiver),1);
    for z = 1:numel(receiver)
        select = a.linkClass==linkClass(z) & ...
            a.receiver==receiver(z) & a.sender==sender(z);
        evalSelect = select & a.time_s>=scenario.evaluationStart_s & ...
            a.time_s<scenario.horizon_s-1e-12;
        eventSelect = evalSelect & ...
            localWindowMask(a.time_s,scenario.eventWindows_s);
        linkRows(z) = struct('scenarioId',sid,'seed',seed, ...
            'lambda',lambda,'linkClass',linkClass(z), ...
            'receiver',receiver(z),'sender',sender(z), ...
            'scheduledCount',nnz(select),'evaluationCount',nnz(evalSelect), ...
            'eventCount',nnz(eventSelect), ...
            'acceptedCount',nnz(select & a.accepted), ...
            'failedCount',nnz(select & a.dropped));
    end
    linkCells{q} = struct2table(linkRows);

    t = out.t;
    event = localWindowMask(t,scenario.eventWindows_s);
    around = localExpandedWindowMask(t,scenario.eventWindows_s,1.0);
    dataEvents = [out.txCountLog(1);diff(out.txCountLog)];
    sendEvents = [out.oracleSendCountLog(1); ...
        diff(out.oracleSendCountLog)];
    traceCells{q} = table(repmat(sid,nnz(around),1), ...
        repmat(seed,nnz(around),1),repmat(lambda,nnz(around),1), ...
        t(around),event(around),dataEvents(around),sendEvents(around), ...
        out.oracleSendCountLog(around), ...
        out.oracleStepMaxValueLog(around), ...
        out.oraclePredictedSaturationFractionLog(around), ...
        'VariableNames',{'scenarioId','seed','lambda','time_s', ...
        'inEventWindow','dataAttempts','scheduledActions', ...
        'cumulativeScheduledActions','stepMaxValue', ...
        'predictedSaturationFraction'});
end

actionKeep = ~cellfun(@isempty,actionCells);
linkKeep = ~cellfun(@isempty,linkCells);
traceKeep = ~cellfun(@isempty,traceCells);
if any(actionKeep)
    actions = vertcat(actionCells{actionKeep});
else
    actions = table();
end
links = vertcat(linkCells{linkKeep});
traces = vertcat(traceCells{traceKeep});

end


function mask = localWindowMask(t,windows)

mask = false(size(t));
for q = 1:size(windows,1)
    mask = mask | (t>=windows(q,1)-1e-12 & t<windows(q,2)-1e-12);
end

end


function mask = localExpandedWindowMask(t,windows,padding)

mask = false(size(t));
for q = 1:size(windows,1)
    mask = mask | (t>=windows(q,1)-padding-1e-12 & ...
        t<windows(q,2)+padding-1e-12);
end

end
