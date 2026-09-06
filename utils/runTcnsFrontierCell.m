function row = runTcnsFrontierCell(cfg,arm,scenario)
%RUNTCNSFRONTIERCELL Run one method/seed/scenario with a stable output row.
%
% Errors are returned as structured failed rows so a campaign preserves its
% complete schedule. The driver decides whether failures stop the gate.

requiredArm = {'id','family','label','kind','parameterName', ...
    'parameterValue','period_s','epsilon_m','retry_s'};
for q = 1:numel(requiredArm)
    if ~isfield(arm,requiredArm{q})
        error('runTcnsFrontierCell:InvalidArm', ...
            'arm.%s is required.',requiredArm{q});
    end
end
requiredScenario = {'id','name','evaluationStart_s','eventWindows_s', ...
    'performanceWindows_s'};
for q = 1:numel(requiredScenario)
    if ~isfield(scenario,requiredScenario{q})
        error('runTcnsFrontierCell:InvalidScenario', ...
            'scenario.%s is required.',requiredScenario{q});
    end
end

row = tcnsFrontierRow();
row.armId = arm.id;
row.methodFamily = arm.family;
row.method = arm.label;
row.parameterName = arm.parameterName;
row.parameterValue = arm.parameterValue;
row.period_s = arm.period_s;
row.epsilonPosition_m = arm.epsilon_m;
row.retryInterval_s = arm.retry_s;
row.seed = cfg.net.seed;
row.scenarioId = string(scenario.id);
row.scenario = string(scenario.name);
t0 = tic;

try
    switch arm.kind
        case "periodic"
            cfg.net.commPeriod = arm.period_s;
            out = simSwarmNetworkQueued(cfg);
        case "control-aware"
            cfg.causal.policyMode = 'control-aware';
            cfg.controlAware.epsilonPosition = arm.epsilon_m;
            cfg.controlAware.retryInterval = arm.retry_s;
            out = simSwarmAoICausal(cfg);
        case "legacy"
            cfg.causal.policyMode = 'legacy-v3';
            out = simSwarmAoICausal(cfg);
        otherwise
            error('runTcnsFrontierCell:UnknownArmKind', ...
                'Unknown arm kind "%s".',arm.kind);
    end

    metrics = computeSwarmMetrics(out,cfg);
    t = out.t;
    missionTime = t(end)-t(1);
    nChannels = nnz(cfg.swarm.A)+nnz(cfg.swarm.pin);
    dataEvents = localEvents(out.txCountLog);
    if isfield(out,'ackCountLog')
        ackEvents = localEvents(out.ackCountLog);
    else
        ackEvents = zeros(size(dataEvents));
    end
    evalMask = t>=scenario.evaluationStart_s & t<t(end)-1e-12;
    evalDuration = t(end)-scenario.evaluationStart_s;
    eventMask = localWindowMask(t,scenario.eventWindows_s);
    performanceMask = localWindowMask(t,scenario.performanceWindows_s);
    if ~any(performanceMask)
        performanceMask = evalMask;
    end

    formationError = localFormationError(out,cfg);
    primaryError = formationError(performanceMask,2:end);
    evalAcceleration = vecnorm(reshape( ...
        out.A(t>=scenario.evaluationStart_s,2:end,:),[],3),2,2);
    ackCount = sum(ackEvents);
    dataRate = out.txCount/max(missionTime,eps);
    ackRate = ackCount/max(missionTime,eps);

    row.formationRMSE_m = metrics.formationRMSE;
    row.primaryFormationRMSE_m = sqrt(mean(primaryError.^2,'all'));
    row.maxFormationError_m = metrics.maxFormationError;
    row.primaryMaxFormationError_m = max(primaryError,[],'all');
    row.txCount = out.txCount;
    row.ackCount = ackCount;
    row.dataRatePerChannel_Hz = dataRate/nChannels;
    row.cost025PerChannel_Hz = (dataRate+0.25*ackRate)/nChannels;
    row.evaluationCost025PerChannel_Hz = ...
        localCost(dataEvents,ackEvents,evalMask,evalDuration,nChannels);
    row.broadcastRate_Hz = out.broadcastCount/max(missionTime,eps);
    row.maxEvaluationAcceleration_mps2 = max(evalAcceleration);
    row.saturationFraction = mean( ...
        evalAcceleration>=cfg.swarm.maxAccel-1e-10);
    row.diverged = any(~isfinite(out.P),'all') || ...
        max(abs(out.P),[],'all')>100;
    row.traceHashExact = out.traceHashExact;

    if any(eventMask)
        eventDuration = localWindowDuration( ...
            scenario.eventWindows_s,scenario.evaluationStart_s,t(end));
        quietMask = evalMask & ~eventMask;
        quietDuration = evalDuration-eventDuration;
        row.eventCost025PerChannel_Hz = localCost( ...
            dataEvents,ackEvents,eventMask,eventDuration,nChannels);
        if quietDuration>0 && any(quietMask)
            row.quietCost025PerChannel_Hz = localCost( ...
                dataEvents,ackEvents,quietMask,quietDuration,nChannels);
        end
        weightedEvents = dataEvents+0.25*ackEvents;
        evaluationTraffic = sum(weightedEvents(evalMask));
        row.eventTrafficConcentration = ...
            sum(weightedEvents(eventMask))/max(evaluationTraffic,eps);
        row.eventDurationFraction = eventDuration/evalDuration;
        row.eventAllocationRatio = row.eventTrafficConcentration / ...
            max(row.eventDurationFraction,eps);
    end

    if isfield(out,'invariantViolations')
        row.invariantViolations = out.invariantViolations;
    else
        row.invariantViolations = 0;
    end
    if isfield(out,'controlAwareActive') && out.controlAwareActive
        row.controlViolationRatio = out.controlAwareViolationRatio;
        row.controlMaxNormalizedRisk = out.controlAwareMaxNormalizedRisk;
    end
catch err
    row.failed = true;
    row.errorIdentifier = string(err.identifier);
    row.errorMessage = string(err.message);
end

row.runtime_s = toc(t0);

end


function events = localEvents(cumulative)

cumulative = double(cumulative(:));
events = [cumulative(1);diff(cumulative)];
if any(events<0)
    error('runTcnsFrontierCell:NonmonotoneCounter', ...
        'A cumulative communication counter decreased.');
end

end


function mask = localWindowMask(t,windows)

mask = false(size(t));
if isempty(windows)
    return;
end
if size(windows,2)~=2 || any(~isfinite(windows),'all') || ...
        any(windows(:,2)<=windows(:,1))
    error('runTcnsFrontierCell:InvalidWindows', ...
        'Evaluation windows must be finite increasing [start,end] rows.');
end
for q = 1:size(windows,1)
    mask = mask | (t>=windows(q,1)-1e-12 & t<windows(q,2)-1e-12);
end

end


function duration = localWindowDuration(windows,evaluationStart,missionEnd)

duration = 0;
for q = 1:size(windows,1)
    a = max(windows(q,1),evaluationStart);
    b = min(windows(q,2),missionEnd);
    duration = duration+max(b-a,0);
end

end


function cost = localCost(dataEvents,ackEvents,mask,duration,nChannels)

if duration<=0
    cost = NaN;
else
    cost = (sum(dataEvents(mask))+0.25*sum(ackEvents(mask))) / ...
        (duration*nChannels);
end

end


function errorNorm = localFormationError(out,cfg)

K = numel(out.t);
N = cfg.swarm.N;
leader = out.P(:,1,:);
if isfield(out,'desiredOffsets')
    offsets = out.desiredOffsets;
else
    offsets = repmat(reshape(cfg.swarm.offsets,1,N,3),K,1,1);
end
errorNorm = sqrt(sum((out.P-(leader+offsets)).^2,3));
errorNorm(:,1) = 0;

end
