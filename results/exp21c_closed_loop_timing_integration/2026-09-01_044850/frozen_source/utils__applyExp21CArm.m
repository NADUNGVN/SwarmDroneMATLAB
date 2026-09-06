function [cfg,method,label,details]=applyExp21CArm(base,arm)
%APPLYEXP21CARM Apply one frozen timing-integration arm.

R=exp21cRegistry();
required={'id','label','kind','schedulerMode','clockEnabled','guardFactor'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp21CArm: arm does not satisfy the registry.');
end
id=char(arm.id);
originalMacType=lower(strtrim(char(base.mac.type)));
if strcmp(id,R.idealArm)
    old=exp21aRegistry();
    oldArm=old.arms(strcmp({old.arms.id},R.idealArm));
    [cfg,method,label,details]=applyExp21AArm(base,oldArm);
else
    cfg=base;
    method='periodic';
    label=char(arm.label);
    cfg.net.commPeriod=1/R.periodicRateHz;
    cfg.mac.type='tdma';
    cfg.mac.pAccess=1;
    cfg.shared.feedbackMode='none';
    offset=0; drift=0;
    if arm.clockEnabled
        offset=R.maxOffsetSec; drift=R.maxDriftPpm;
    end
    guard=arm.guardFactor*R.safeGuardSec;
    cfg.shared.serviceScheduler=struct( ...
        'mode','continuous-local-static-tdma','logDecisions',true, ...
        'tieBreak','fifo-node','reservationFrameSlots',cfg.swarm.N, ...
        'clockOffsetMaxSec',offset,'clockDriftMaxPpm',drift, ...
        'continuousGuardTime',guard, ...
        'continuousSyncPeriod',R.syncPeriodSec, ...
        'continuousEpochLeadTime',0,'continuousExactAirtime',true);
    cfg.mac=sharedMediumConfig(cfg);
    cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
    details=struct('kind',char(arm.kind),'route','none', ...
        'ackDesign','none','accessDesign','continuous-local-clock', ...
        'schedulerMode',char(arm.schedulerMode), ...
        'periodicRateHz',R.periodicRateHz,'distributedFlag',0, ...
        'idealFlag',0);
end
cfg.exp20a.originalMacType=originalMacType;
cfg.exp21c.arm=id;
cfg.exp21c.kind=char(arm.kind);
cfg.exp21c.guardFactor=arm.guardFactor;
cfg.exp21c.clockEnabled=logical(arm.clockEnabled);

end
