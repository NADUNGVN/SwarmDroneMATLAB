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
valid={'native','round-robin','deficit-maxweight','urgency-maxweight'};
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
S.enabled=~strcmp(S.mode,'native');
S.oracle=any(strcmp(S.mode,{'deficit-maxweight','urgency-maxweight'}));
S.receiverTruthOracle=strcmp(S.mode,'urgency-maxweight');

if ~strcmp(S.tieBreak,'fifo-node')
    error('serviceSchedulerConfig: tieBreak must be fifo-node.');
end
logicalScalar(S.logDecisions,'logDecisions');
positiveScalar(S.targetRateHz,'targetRateHz');
positiveScalar(S.posThreshold,'posThreshold');
positiveScalar(S.velThreshold,'velThreshold');
positiveScalar(S.aoiThreshold,'aoiThreshold');
positiveScalar(S.maxSilence,'maxSilence');
S.logDecisions=logical(S.logDecisions);

if S.enabled && ~strcmpi(cfg.mac.type,'tdma')
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


function logicalScalar(x,name)

if ~isscalar(x) || ~(islogical(x) || any(x==[0 1]))
    error('serviceSchedulerConfig: %s must be scalar logical.',name);
end

end
