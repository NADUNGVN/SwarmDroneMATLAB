function [cfg,method,label] = applyExp14FrontierPoint(cfg,familyId,value)
%APPLYEXP14FRONTIERPOINT Apply one frozen equal-budget EXP14 frontier point.

familyId = lower(strtrim(char(familyId)));
switch familyId
    case 'periodic'
        method = 'periodic';
        label = 'Periodic';
        cfg.net.commPeriod = 1/value;
    case 'state'
        method = 'state-event';
        label = 'State-event';
        cfg.event.posThreshold = 0.05*value;
        cfg.event.velThreshold = 0.10*value;
    case 'aoi'
        method = 'causal-aoi-only';
        label = 'Causal AoI-only';
        cfg.aoiEvent.aoiThreshold = value;
    case 'aoci'
        method = 'causal-aoci';
        label = 'AoCI-inspired';
        cfg.shared.aociRiskThreshold = value;
    case 'belief'
        method = 'delayed-ack-belief';
        label = 'Delayed-ACK belief';
        cfg.shared.beliefAgeThreshold = value;
    case 'proposed'
        method = 'causal-broadcast';
        label = 'Causal-Broadcast';
        cfg.aoiEvent.posThreshold = 0.05*value;
        cfg.aoiEvent.velThreshold = 0.10*value;
    otherwise
        error('applyExp14FrontierPoint: unknown family "%s".',familyId);
end

end
