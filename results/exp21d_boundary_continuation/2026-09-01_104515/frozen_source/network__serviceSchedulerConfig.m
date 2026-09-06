function S=serviceSchedulerConfig(cfg)
%SERVICESCHEDULERCONFIG Validate the EXP19 service-discipline contract.

if ~isfield(cfg,'aoiEvent') || isempty(cfg.aoiEvent)
    cfg.aoiEvent=struct();
end
cfg.aoiEvent=setDefault(cfg.aoiEvent,'posThreshold',0.05);
cfg.aoiEvent=setDefault(cfg.aoiEvent,'velThreshold',0.10);
cfg.aoiEvent=setDefault(cfg.aoiEvent,'aoiThreshold',0.12);
cfg.aoiEvent=setDefault(cfg.aoiEvent,'maxSilence',0.50);
if ~isfield(cfg,'shared') || ~isfield(cfg.shared,'serviceScheduler') || ...
        isempty(cfg.shared.serviceScheduler)
    S=struct();
else
    S=cfg.shared.serviceScheduler;
end

S=setDefault(S,'mode','native');
S.mode=lower(strtrim(char(S.mode)));
valid={'native','round-robin','deficit-maxweight','urgency-maxweight', ...
    'dtsa-common','dtsa-private','age-gain-thinning','zmac-like', ...
    'delta-public','delta-private','local-static-tdma', ...
    'distributed-reservation','continuous-local-static-tdma', ...
    'continuous-dstr-replay'};
if ~any(strcmp(S.mode,valid))
    error('serviceSchedulerConfig: unknown mode "%s".',S.mode);
end
S=setDefault(S,'logDecisions',true);
S=setDefault(S,'tieBreak','fifo-node');
S=setDefault(S,'targetRateHz',1/cfg.aoiEvent.aoiThreshold);
S=setDefault(S,'posThreshold',cfg.aoiEvent.posThreshold);
S=setDefault(S,'velThreshold',cfg.aoiEvent.velThreshold);
S=setDefault(S,'aoiThreshold',cfg.aoiEvent.aoiThreshold);
S=setDefault(S,'maxSilence',cfg.aoiEvent.maxSilence);
S=setDefault(S,'dtsaTieMargin',0.50);
S=setDefault(S,'ageGainThreshold',cfg.aoiEvent.aoiThreshold);
S=setDefault(S,'zmacHighContentionThreshold',0.35);
S=setDefault(S,'deltaRiskThreshold',1.0);
S=setDefault(S,'publicFeedbackSlots',1);
S=setDefault(S,'reservationFrameSlots',cfg.swarm.N);
S=setDefault(S,'reservationPeriod',0.50);
S=setDefault(S,'reservationLease',1.50);
S=setDefault(S,'requestBytes',24);
S=setDefault(S,'responseBaseBytes',12);
S=setDefault(S,'responseEntryBytes',4);
S=setDefault(S,'commitBytes',16);
S=setDefault(S,'controlLoss',0.05);
S=setDefault(S,'controlReach',true(cfg.swarm.N));
S=setDefault(S,'clockOffsetMaxSec',0);
S=setDefault(S,'clockDriftMaxPpm',0);
S=setDefault(S,'churnEnabled',false);
S=setDefault(S,'churnTimeSec',inf);
S=setDefault(S,'churnNode',1);
S=setDefault(S,'continuousGuardTime',0);
S=setDefault(S,'continuousSyncPeriod',inf);
S=setDefault(S,'continuousEpochLeadTime',0);
S=setDefault(S,'continuousExactAirtime',false);
S=setDefault(S,'dstrSchedule',struct());
S.enabled=~strcmp(S.mode,'native');
S.oracle=any(strcmp(S.mode,{'deficit-maxweight','urgency-maxweight'}));
S.receiverTruthOracle=strcmp(S.mode,'urgency-maxweight');
S.publicTruthReference=any(strcmp(S.mode, ...
    {'urgency-maxweight','dtsa-common','delta-public'}));
S.distributedProjection=any(strcmp(S.mode, ...
    {'dtsa-private','age-gain-thinning','zmac-like','delta-private', ...
    'distributed-reservation'}));
S.scheduled=any(strcmp(S.mode,{'round-robin','deficit-maxweight', ...
    'urgency-maxweight','dtsa-common','dtsa-private', ...
    'local-static-tdma','distributed-reservation'}));
S.continuousScheduled=any(strcmp(S.mode, ...
    {'continuous-local-static-tdma','continuous-dstr-replay'}));
S.scheduled=S.scheduled || S.continuousScheduled;

if ~strcmp(S.tieBreak,'fifo-node')
    error('serviceSchedulerConfig: tieBreak must be fifo-node.');
end
logicalScalar(S.logDecisions,'logDecisions');
positiveScalar(S.targetRateHz,'targetRateHz');
positiveScalar(S.posThreshold,'posThreshold');
positiveScalar(S.velThreshold,'velThreshold');
positiveScalar(S.aoiThreshold,'aoiThreshold');
positiveScalar(S.maxSilence,'maxSilence');
nonnegativeScalar(S.dtsaTieMargin,'dtsaTieMargin');
positiveScalar(S.ageGainThreshold,'ageGainThreshold');
nonnegativeScalar(S.zmacHighContentionThreshold, ...
    'zmacHighContentionThreshold');
positiveScalar(S.deltaRiskThreshold,'deltaRiskThreshold');
positiveInteger(S.publicFeedbackSlots,'publicFeedbackSlots');
positiveInteger(S.reservationFrameSlots,'reservationFrameSlots');
positiveScalar(S.reservationPeriod,'reservationPeriod');
positiveScalar(S.reservationLease,'reservationLease');
positiveScalar(S.requestBytes,'requestBytes');
positiveScalar(S.responseBaseBytes,'responseBaseBytes');
positiveScalar(S.responseEntryBytes,'responseEntryBytes');
positiveScalar(S.commitBytes,'commitBytes');
probabilityScalar(S.controlLoss,'controlLoss');
nonnegativeScalar(S.clockOffsetMaxSec,'clockOffsetMaxSec');
nonnegativeScalar(S.clockDriftMaxPpm,'clockDriftMaxPpm');
logicalScalar(S.churnEnabled,'churnEnabled');
if S.churnEnabled
    nonnegativeScalar(S.churnTimeSec,'churnTimeSec');
end
positiveInteger(S.churnNode,'churnNode');
if S.churnNode>cfg.swarm.N
    error('serviceSchedulerConfig: churnNode exceeds swarm size.');
end
if ~isequal(size(S.controlReach),[cfg.swarm.N cfg.swarm.N]) || ...
        any(~isfinite(S.controlReach(:))) || ...
        any(S.controlReach(:)~=0 & S.controlReach(:)~=1)
    error(['serviceSchedulerConfig: controlReach must be a finite binary ' ...
        'N-by-N matrix.']);
end
S.controlReach=logical(S.controlReach);
S.controlReach(1:cfg.swarm.N+1:end)=true;
S.logDecisions=logical(S.logDecisions);
S.churnEnabled=logical(S.churnEnabled);
nonnegativeScalar(S.continuousGuardTime,'continuousGuardTime');
if ~(isscalar(S.continuousSyncPeriod) && ...
        ((isfinite(S.continuousSyncPeriod) && S.continuousSyncPeriod>0) || ...
        isinf(S.continuousSyncPeriod)))
    error(['serviceSchedulerConfig: continuousSyncPeriod must be ' ...
        'positive or inf.']);
end
nonnegativeScalar(S.continuousEpochLeadTime,'continuousEpochLeadTime');
logicalScalar(S.continuousExactAirtime,'continuousExactAirtime');
S.continuousExactAirtime=logical(S.continuousExactAirtime);
if strcmp(S.mode,'continuous-dstr-replay')
    validateDstrSchedule(S.dstrSchedule,cfg);
    if ~S.continuousExactAirtime
        error(['serviceSchedulerConfig: continuous-dstr-replay requires ' ...
            'continuousExactAirtime=true.']);
    end
    if cfg.mac.backgroundLoad>0
        error(['serviceSchedulerConfig: continuous-dstr-replay v1 requires ' ...
            'backgroundLoad=0; background/control composition is not yet ' ...
            'validated.']);
    end
end

if S.scheduled && ~strcmpi(cfg.mac.type,'tdma')
    error(['serviceSchedulerConfig: scheduled service modes require ' ...
        'cfg.mac.type=tdma.']);
end


function validateDstrSchedule(Q,cfg)

required={'version','horizonSec','airtimeSec','guardSec', ...
    'slotDurationSec','dataStartTime','dataNode','dataFrame', ...
    'dataSuccessMask','dataErasureMask','dataCollisionMask', ...
    'dataCompletesByHorizon', ...
    'expectedCompletedDataCollisionFrames', ...
    'expectedCompletedDataRecipientSuccess', ...
    'expectedCompletedDataRecipientErasure', ...
    'expectedCompletedDataRecipientCollision', ...
    'controlGroupStartTime','controlGroupAttempts', ...
    'controlGroupRecipientAttempts','controlGroupRecipientSuccess', ...
    'controlGroupRecipientErasure','controlGroupRecipientCollision', ...
    'controlGroupCollision','kernelConfigHash','kernelTraceHash', ...
    'hashExact','futureRandomReads','receiverTruthDecisionReads'};
if ~isstruct(Q) || ~isscalar(Q) || ~all(isfield(Q,required))
    error(['serviceSchedulerConfig: dstrSchedule does not satisfy the ' ...
        'continuous replay schema.']);
end
if abs(Q.horizonSec-cfg.swarm.T)>1e-12
    error('serviceSchedulerConfig: D-STR schedule horizon differs from T.');
end
expected=8*cfg.mac.dataBytes/cfg.mac.phyRateBps;
if abs(Q.airtimeSec-expected)>1e-12
    error(['serviceSchedulerConfig: D-STR schedule airtime differs from ' ...
        'the common DATA PHY.']);
end
if any(Q.dataNode<1 | Q.dataNode>cfg.swarm.N) || ...
        numel(Q.dataStartTime)~=numel(Q.dataNode) || ...
        numel(Q.dataStartTime)~=numel(Q.dataFrame)
    error('serviceSchedulerConfig: malformed D-STR DATA schedule.');
end
if ~isequal(size(Q.dataSuccessMask), ...
        [numel(Q.dataStartTime) cfg.swarm.N]) || ...
        ~isequal(size(Q.dataErasureMask), ...
        [numel(Q.dataStartTime) cfg.swarm.N]) || ...
        ~isequal(size(Q.dataCollisionMask), ...
        [numel(Q.dataStartTime) cfg.swarm.N])
    error('serviceSchedulerConfig: malformed D-STR DATA outcome masks.');
end
n=numel(Q.controlGroupStartTime);
fields={'controlGroupAttempts','controlGroupRecipientAttempts', ...
    'controlGroupRecipientSuccess','controlGroupRecipientErasure', ...
    'controlGroupRecipientCollision','controlGroupCollision'};
if any(cellfun(@(name) numel(Q.(name))~=n,fields))
    error('serviceSchedulerConfig: malformed D-STR management schedule.');
end
if Q.futureRandomReads~=0 || Q.receiverTruthDecisionReads~=0
    error(['serviceSchedulerConfig: D-STR schedule reports forbidden ' ...
        'future-random or receiver-truth reads.']);
end

end

end


function s=setDefault(s,name,value)

if ~isfield(s,name) || isempty(s.(name)), s.(name)=value; end

end


function positiveScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x<=0
    error('serviceSchedulerConfig: %s must be positive and finite.',name);
end

end


function nonnegativeScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x<0
    error('serviceSchedulerConfig: %s must be nonnegative and finite.',name);
end

end


function probabilityScalar(x,name)

if ~isscalar(x) || ~isfinite(x) || x<0 || x>1
    error('serviceSchedulerConfig: %s must lie in [0,1].',name);
end

end


function positiveInteger(x,name)

if ~isscalar(x) || ~isfinite(x) || x<1 || x~=round(x)
    error('serviceSchedulerConfig: %s must be a positive integer.',name);
end

end


function logicalScalar(x,name)

if ~isscalar(x) || ~(islogical(x) || any(x==[0 1]))
    error('serviceSchedulerConfig: %s must be scalar logical.',name);
end

end
