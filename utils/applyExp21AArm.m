function [cfg,method,label,details]=applyExp21AArm(base,arm)
%APPLYEXP21AARM Apply one frozen EXP21A access arm.

R=exp21aRegistry();
required={'id','label','kind','schedulerMode','periodicRateHz'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp21AArm: arm does not satisfy the frozen registry.');
end
id=char(arm.id);
label=char(arm.label);
originalMacType=lower(strtrim(char(base.mac.type)));
route='none';
ackDesign='none';
accessDesign=char(arm.schedulerMode);

switch id
    case {'frame-piggyback','zmac-like-hybrid'}
        old=exp20aRegistry();
        oldIndex=find(strcmp({old.formationArms.id},id),1);
        [cfg,method,label,prior]=applyExp20AArm( ...
            base,old.formationArms(oldIndex));
        route=prior.route;
        ackDesign=prior.ackDesign;
        accessDesign=prior.accessDesign;

    case {'ideal-tdma-p8p333','ideal-tdma-p10'}
        cfg=base;
        method='periodic';
        cfg.net.commPeriod=1/arm.periodicRateHz;
        cfg.mac.type='tdma';
        cfg.mac.pAccess=1;
        cfg.shared.feedbackMode='none';
        cfg.shared.serviceScheduler=struct('mode','round-robin', ...
            'logDecisions',true,'tieBreak','fifo-node');
        accessDesign='ideal-centralized-tdma';

    case 'local-static-p8p333'
        cfg=base;
        method='periodic';
        cfg.net.commPeriod=1/arm.periodicRateHz;
        cfg.mac.type='tdma';
        cfg.mac.pAccess=1;
        cfg.shared.feedbackMode='none';
        cfg.shared.serviceScheduler=schedulerFields( ...
            base,'local-static-tdma',R);
        accessDesign='fixed-map-local-clock';

    case {'distributed-reservation-p8p333', ...
            'distributed-reservation-p10'}
        cfg=base;
        method='periodic';
        cfg.net.commPeriod=1/arm.periodicRateHz;
        cfg.mac.type='tdma';
        cfg.mac.pAccess=1;
        cfg.shared.feedbackMode='none';
        cfg.shared.serviceScheduler=schedulerFields( ...
            base,'distributed-reservation',R);
        accessDesign='aydin-inspired-two-hop-reservation-projection';

    otherwise
        error('applyExp21AArm: unsupported arm "%s".',id);
end

cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
cfg.exp20a.originalMacType=originalMacType;
cfg.exp21a.arm=id;
cfg.exp21a.kind=char(arm.kind);
cfg.exp21a.schedulerMode=char(arm.schedulerMode);
details=struct('kind',char(arm.kind),'route',route, ...
    'ackDesign',ackDesign,'accessDesign',accessDesign, ...
    'schedulerMode',char(arm.schedulerMode), ...
    'periodicRateHz',arm.periodicRateHz, ...
    'distributedFlag',double(contains(arm.kind,'distributed')), ...
    'idealFlag',double(strcmp(arm.kind,'ideal-reference')));

end


function S=schedulerFields(base,mode,R)

E=base.exp21a;
S=struct('mode',mode,'logDecisions',true,'tieBreak','fifo-node', ...
    'reservationFrameSlots',base.swarm.N, ...
    'reservationPeriod',R.reservation.periodSec, ...
    'reservationLease',R.reservation.leaseSec, ...
    'requestBytes',R.reservation.requestBytes, ...
    'responseBaseBytes',R.reservation.responseBaseBytes, ...
    'responseEntryBytes',R.reservation.responseEntryBytes, ...
    'commitBytes',R.reservation.commitBytes, ...
    'controlLoss',E.controlLoss,'controlReach',E.controlReach, ...
    'clockOffsetMaxSec',E.clockOffsetMaxSec, ...
    'clockDriftMaxPpm',E.clockDriftMaxPpm, ...
    'churnEnabled',E.churnEnabled,'churnTimeSec',E.churnTimeSec, ...
    'churnNode',E.churnNode);

end
