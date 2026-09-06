function [cfg,method,label,details,Q]=applyExp21dClockArm( ...
    base,arm,nativeQ,trace,R)
%APPLYEXP21DCLOCKARM Apply one frozen clock-composition arm.

if nargin<5 || isempty(R), R=exp21dClockRegistry(); end
required={'id','label','kind','guardKind','clockEnabled'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp21dClockArm: arm does not satisfy the registry.');
end
if ~isfield(trace,'exp21cClockOffsetU') || ...
        ~isfield(trace,'exp21cClockDriftU')
    error('applyExp21dClockArm: shared trace lacks clock draws.');
end

N=base.swarm.N;
offset=zeros(N,1);
drift=zeros(N,1);
if arm.clockEnabled
    offset=(2*reshape(trace.exp21cClockOffsetU(1,:),[],1)-1)* ...
        R.maxOffsetSec;
    drift=(2*reshape(trace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
end
spec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'maxOffsetSec',R.maxOffsetSec,'maxDriftPpm',R.maxDriftPpm, ...
    'leadTimeSec',R.clockLeadTimeSec, ...
    'safeGuardSec',R.missionSafeGuardSec);
Q=applyDstrAffineClockSchedule(nativeQ,spec);

cfg=base;
method='periodic';
label=char(arm.label);
cfg.net.commPeriod=1/50;
cfg.mac.type='tdma';
cfg.mac.pAccess=1;
cfg.mac.maxRetries=0;
cfg.shared.feedbackMode='none';
clockOffsetBound=0;
clockDriftBound=0;
if arm.clockEnabled
    clockOffsetBound=R.maxOffsetSec;
    clockDriftBound=R.maxDriftPpm;
end
cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-dstr-replay','logDecisions',true, ...
    'tieBreak','fifo-node','clockOffsetMaxSec',clockOffsetBound, ...
    'clockDriftMaxPpm',clockDriftBound, ...
    'continuousGuardTime',Q.guardSec,'continuousSyncPeriod',inf, ...
    'continuousEpochLeadTime',R.clockLeadTimeSec, ...
    'continuousExactAirtime',true,'dstrSchedule',Q);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
cfg.exp20a.originalMacType='tdma';
cfg.exp21dc=struct('version',R.version,'arm',char(arm.id), ...
    'kind',char(arm.kind),'clockEnabled',logical(arm.clockEnabled), ...
    'candidateDesignPermitted',false);
details=struct('kind',char(arm.kind),'route','none', ...
    'ackDesign','none','accessDesign','continuous-dstr-affine-clock', ...
    'schedulerMode','continuous-dstr-replay', ...
    'periodicRateHz',50,'distributedFlag',1,'idealFlag',0);

end
