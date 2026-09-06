function [cfg,method,label,details]=applyExp21dClosedLoopArm(base,arm)
%APPLYEXP21DCLOSEDLOOPARM Apply one frozen D-STR integration arm.

R=exp21dClosedLoopRegistry();
required={'id','label','kind','schedulerMode','periodicRateHz','idealFlag'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp21dClosedLoopArm: arm does not satisfy the registry.');
end
cfg=base;
id=char(arm.id);
method='periodic';
label=char(arm.label);
cfg.net.commPeriod=1/arm.periodicRateHz;
cfg.mac.type='tdma';
cfg.mac.pAccess=1;
cfg.mac.maxRetries=0;
cfg.shared.feedbackMode='none';

scheduleHash=NaN;
kernelTraceHash=NaN;
kernelConfigHash=NaN;
if strcmp(id,R.periodicArm)
    cfg.shared.serviceScheduler=struct( ...
        'mode','continuous-local-static-tdma','logDecisions',true, ...
        'tieBreak','fifo-node','reservationFrameSlots',cfg.swarm.N, ...
        'clockOffsetMaxSec',0,'clockDriftMaxPpm',0, ...
        'continuousGuardTime',R.safeGuardSec, ...
        'continuousSyncPeriod',inf,'continuousEpochLeadTime',0, ...
        'continuousExactAirtime',true);
else
    C=buildExp21dClosedLoopKernelConfig(cfg,R);
    T=generateExp21dDstrTrace(cfg.net.seed,C.N,R);
    Q=buildDstrContinuousSchedule(C,T,cfg.swarm.T);
    if strcmp(id,R.warmArm)
        Q=buildDstrWarmContinuousSchedule(Q,cfg.swarm.T);
    elseif ~strcmp(id,R.nativeArm)
        error('applyExp21dClosedLoopArm: unsupported arm "%s".',id);
    end
    scheduleHash=Q.hashExact;
    kernelTraceHash=Q.kernelTraceHash;
    kernelConfigHash=Q.kernelConfigHash;
    cfg.shared.serviceScheduler=struct( ...
        'mode','continuous-dstr-replay','logDecisions',true, ...
        'tieBreak','fifo-node','continuousExactAirtime',true, ...
        'dstrSchedule',Q);
end
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
cfg.exp20a.originalMacType='tdma';
cfg.exp21dcl.arm=id;
cfg.exp21dcl.kind=char(arm.kind);
cfg.exp21dcl.scheduleHash=scheduleHash;
cfg.exp21dcl.kernelTraceHash=kernelTraceHash;
cfg.exp21dcl.kernelConfigHash=kernelConfigHash;
details=struct('kind',char(arm.kind),'route','none', ...
    'ackDesign','none','accessDesign',char(arm.schedulerMode), ...
    'schedulerMode',char(arm.schedulerMode), ...
    'periodicRateHz',arm.periodicRateHz,'distributedFlag', ...
    double(strcmp(id,R.nativeArm)),'idealFlag',arm.idealFlag);

end
