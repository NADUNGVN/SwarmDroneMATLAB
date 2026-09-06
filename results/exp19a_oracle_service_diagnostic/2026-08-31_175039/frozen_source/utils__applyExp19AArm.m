function [cfg,method,label,details]=applyExp19AArm(base,arm)
%APPLYEXP19AARM Apply a frozen EXP19A baseline or service reference.

R=exp19aRegistry();
required={'id','label','kind','schedulerMode','periodicRateHz'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp19AArm: arm does not satisfy the registry.');
end
originalMacType=lower(strtrim(char(base.mac.type)));

switch char(arm.id)
    case 'frame-piggyback'
        E=exp18Registry();
        idx=find(strcmp({E.arms.id},'frame-piggyback'),1);
        [cfg,method,label,old]=applyExp18Arm(base,E.arms(idx));
        route=old.route; accessDesign=old.accessDesign;
        ackDesign=old.ackDesign;
        cfg.shared.serviceScheduler=struct('mode','native');

    case 'capacity-gated-selector'
        [cfg,method,label,old]=applyExp18A4Arm(base);
        route=old.route; accessDesign=old.accessDesign;
        ackDesign=old.ackDesign;
        cfg.shared.serviceScheduler=struct('mode','native');

    otherwise
        cfg=base;
        cfg.mac.type='tdma';
        cfg.mac.pAccess=1;
        cfg.shared.serviceScheduler=struct( ...
            'mode',char(arm.schedulerMode),'logDecisions',true, ...
            'targetRateHz',R.targetRateHz,'tieBreak','fifo-node');
        if strcmp(arm.kind,'periodic-frontier')
            method='periodic';
            cfg.net.commPeriod=1/arm.periodicRateHz;
            cfg.shared.feedbackMode='none';
            route='none';
            ackDesign='none';
        else
            method='causal-broadcast';
            cfg.shared.feedbackMode='piggyback';
            route='piggyback';
            ackDesign='piggyback';
        end
        label=char(arm.label);
        accessDesign='collision-free-scheduled';
        cfg.mac=sharedMediumConfig(cfg);
        cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
end

cfg.exp19a.version=R.version;
cfg.exp19a.arm=char(arm.id);
cfg.exp19a.kind=char(arm.kind);
cfg.exp19a.schedulerMode=char(arm.schedulerMode);
cfg.exp19a.originalMacType=originalMacType;
details=struct('route',route,'accessDesign',accessDesign, ...
    'ackDesign',ackDesign,'kind',char(arm.kind), ...
    'schedulerMode',char(arm.schedulerMode), ...
    'originalMacType',originalMacType, ...
    'oracleFlag',double(strcmp(arm.kind,'oracle')), ...
    'periodicRateHz',arm.periodicRateHz);

end
