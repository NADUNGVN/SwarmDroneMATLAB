function [cfg,method,label,details]=applyExp20AArm(base,arm)
%APPLYEXP20AARM Apply one frozen formation baseline/projection.

R=exp20aRegistry();
required={'id','label','kind','schedulerMode','periodicRateHz'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.formationArms.id},char(arm.id)))
    error('applyExp20AArm: arm does not satisfy the frozen registry.');
end

id=char(arm.id);
originalMacType=lower(strtrim(char(base.mac.type)));
oldIds={exp19aRegistry().arms.id};
oldIndex=find(strcmp(oldIds,id),1);
if ~isempty(oldIndex)
    oldRegistry=exp19aRegistry();
    [cfg,method,label,old]=applyExp19AArm(base,oldRegistry.arms(oldIndex));
    route=old.route;
    accessDesign=old.accessDesign;
    ackDesign=old.ackDesign;
else
    cfg=base;
    label=char(arm.label);
    route='none';
    ackDesign='none';
    accessDesign=char(arm.schedulerMode);

    switch id
        case 'collision-free-rr-piggyback'
            method='causal-broadcast';
            route='piggyback';
            ackDesign='piggyback';
            cfg.mac.type='tdma';
            cfg.mac.pAccess=1;
            cfg.shared.feedbackMode='piggyback';

        case {'dtsa-common-view','dtsa-private-view'}
            method='periodic';
            cfg.net.commPeriod=cfg.swarm.dt;
            cfg.mac.type='tdma';
            cfg.mac.pAccess=1;
            cfg.shared.feedbackMode='none';

        case 'chen-age-gain-private'
            method='periodic-feedback';
            cfg.net.commPeriod=cfg.swarm.dt;
            cfg.shared.feedbackMode='piggyback';
            route='private-cumulative-piggyback';
            ackDesign='private-delayed';

        case 'zmac-like-hybrid'
            method='state-event';
            cfg.mac.type='aloha';
            cfg.mac.pAccess=min(0.20,1/cfg.swarm.N);
            cfg.shared.feedbackMode='none';

        case 'delta-public-projection'
            method='state-event';
            cfg.mac.type='aloha';
            cfg.mac.pAccess=min(0.20,1/cfg.swarm.N);
            cfg.shared.feedbackMode='none';
            route='public-slot-feedback';
            ackDesign='charged-public-minislot';

        case 'delta-private-projection'
            method='periodic-feedback';
            cfg.net.commPeriod=cfg.swarm.dt;
            cfg.mac.type='aloha';
            cfg.mac.pAccess=min(0.20,1/cfg.swarm.N);
            cfg.shared.feedbackMode='piggyback';
            route='private-cumulative-piggyback';
            ackDesign='private-delayed';

        otherwise
            error('applyExp20AArm: unsupported arm "%s".',id);
    end

    cfg.shared.serviceScheduler=struct( ...
        'mode',char(arm.schedulerMode),'logDecisions',true, ...
        'targetRateHz',R.targetRateHz,'tieBreak','fifo-node');
    cfg.mac=sharedMediumConfig(cfg);
    cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
end

cfg.exp20a.version=R.version;
cfg.exp20a.arm=id;
cfg.exp20a.kind=char(arm.kind);
cfg.exp20a.schedulerMode=char(arm.schedulerMode);
cfg.exp20a.originalMacType=originalMacType;
details=struct('route',route,'accessDesign',accessDesign, ...
    'ackDesign',ackDesign,'kind',char(arm.kind), ...
    'schedulerMode',char(arm.schedulerMode), ...
    'originalMacType',originalMacType, ...
    'oracleFlag',double(strcmp(arm.kind,'oracle')), ...
    'periodicRateHz',arm.periodicRateHz, ...
    'projectionFlag',double(contains(arm.kind,'projection')));

end

