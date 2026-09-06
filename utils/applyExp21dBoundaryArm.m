function [cfg,method,label,details,Q]=applyExp21dBoundaryArm( ...
    base,arm,dstrTrace,nativeQ)
%APPLYEXP21DBOUNDARYARM Apply one frozen prior-art boundary arm.

R=exp21dBoundaryRegistry();
if nargin<4, nativeQ=[]; end
required={'id','label','condition','kind','warm'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp21dBoundaryArm: arm does not satisfy the registry.');
end
cfg=base;
C=buildExp21dBoundaryKernelConfig(cfg,R,arm.condition);
if isempty(nativeQ)
    Q=buildDstrContinuousSchedule(C,dstrTrace,cfg.swarm.T);
else
    Q=nativeQ;
end
if arm.warm
    Q=buildDstrWarmContinuousSchedule(Q,cfg.swarm.T, ...
        dstrTrace.dataDeliveryU,C.dataErasureProbability);
end

cfg.net.commPeriod=1/R.periodicRateHz;
cfg.mac.type='tdma';
cfg.mac.pAccess=1;
cfg.mac.maxRetries=0;
cfg.shared.feedbackMode='none';
cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-dstr-replay','logDecisions',true, ...
    'tieBreak','fifo-node','continuousExactAirtime',true, ...
    'dstrSchedule',Q);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
cfg.exp20a.originalMacType='tdma';
cfg.exp21db.arm=char(arm.id);
cfg.exp21db.condition=char(arm.condition);
cfg.exp21db.warm=logical(arm.warm);
cfg.exp21db.physicalReplayValid= ...
    Q.prefixFrameAgreement;
method='periodic';
label=char(arm.label);
details=struct('kind',char(arm.kind),'route','none', ...
    'ackDesign','none','accessDesign','continuous-dstr-replay', ...
    'schedulerMode','continuous-dstr-replay', ...
    'periodicRateHz',R.periodicRateHz,'distributedFlag', ...
    double(~arm.warm),'idealFlag',double(arm.warm));

end
