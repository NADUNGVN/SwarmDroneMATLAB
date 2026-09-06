function [cfg,method,label,details,Q]=applyExp23cWitnessClockArm( ...
    base,arm,nativeQ,trace,R)
%APPLYEXP23CWITNESSCLOCKARM Apply one frozen ELCS-W clock arm.

if nargin<5 || isempty(R), R=exp23cWitnessClosedLoopRegistry(); end
required={'id','label','kind','clockEnabled'};
if ~isstruct(arm) || ~all(isfield(arm,required)) || ...
        ~any(strcmp({R.arms.id},char(arm.id)))
    error('applyExp23cWitnessClockArm: arm violates the registry.');
end
if ~isfield(trace,'exp21cClockOffsetU') || ...
        ~isfield(trace,'exp21cClockDriftU')
    error('applyExp23cWitnessClockArm: shared trace lacks clock draws.');
end

N=base.swarm.N;
offset=zeros(N,1); drift=zeros(N,1);
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
offsetBound=0; driftBound=0;
if arm.clockEnabled
    offsetBound=R.maxOffsetSec;
    driftBound=R.maxDriftPpm;
end
cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-elcs-replay','logDecisions',true, ...
    'tieBreak','fifo-node','clockOffsetMaxSec',offsetBound, ...
    'clockDriftMaxPpm',driftBound, ...
    'continuousGuardTime',Q.guardSec,'continuousSyncPeriod',inf, ...
    'continuousEpochLeadTime',R.clockLeadTimeSec, ...
    'continuousExactAirtime',true,'dstrSchedule',Q);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);
cfg.exp20a.originalMacType='tdma';
cfg.exp23c=struct('version',R.version,'arm',char(arm.id), ...
    'kind',char(arm.kind),'clockEnabled',logical(arm.clockEnabled), ...
    'policyOptimizationAllowed',false,'submissionClaimPermitted',false);
details=struct('kind',char(arm.kind),'route','none', ...
    'ackDesign','none','accessDesign','local-conflict-witness-leases', ...
    'schedulerMode','continuous-elcs-replay', ...
    'periodicRateHz',50,'distributedFlag',1,'idealFlag',0);

end
