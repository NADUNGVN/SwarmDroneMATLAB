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
    'delta-public','delta-private'};
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
S.enabled=~strcmp(S.mode,'native');
S.oracle=any(strcmp(S.mode,{'deficit-maxweight','urgency-maxweight'}));
S.receiverTruthOracle=strcmp(S.mode,'urgency-maxweight');
S.publicTruthReference=any(strcmp(S.mode, ...
    {'urgency-maxweight','dtsa-common','delta-public'}));
S.distributedProjection=any(strcmp(S.mode, ...
    {'dtsa-private','age-gain-thinning','zmac-like','delta-private'}));
S.scheduled=any(strcmp(S.mode,{'round-robin','deficit-maxweight', ...
    'urgency-maxweight','dtsa-common','dtsa-private'}));

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
S.logDecisions=logical(S.logDecisions);

if S.scheduled && ~strcmpi(cfg.mac.type,'tdma')
    error(['serviceSchedulerConfig: scheduled service modes require ' ...
        'cfg.mac.type=tdma.']);
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
