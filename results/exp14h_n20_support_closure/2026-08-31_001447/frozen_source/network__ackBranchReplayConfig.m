function replay=ackBranchReplayConfig(cfg)
%ACKBRANCHREPLAYCONFIG Validate additive ACK branch-replay instrumentation.

replay=struct( ...
    'enabled',false, ...
    'schema','ACK-BRANCH-REPLAY-v1', ...
    'mode','off', ...
    'targetOrdinal',0, ...
    'localHorizon',0.75);
if isfield(cfg,'shared') && isfield(cfg.shared,'ackBranchReplay') && ...
        ~isempty(cfg.shared.ackBranchReplay)
    supplied=cfg.shared.ackBranchReplay;
    if ~isstruct(supplied) || ~isscalar(supplied)
        error(['ackBranchReplayConfig: cfg.shared.ackBranchReplay ' ...
            'must be a scalar struct.']);
    end
    fields=fieldnames(supplied);
    allowed=fieldnames(replay);
    if ~all(ismember(fields,allowed))
        error('ackBranchReplayConfig: unknown replay field.');
    end
    for k=1:numel(fields)
        replay.(fields{k})=supplied.(fields{k});
    end
end

replay.enabled=logicalScalar(replay.enabled,'enabled');
if ~strcmp(char(string(replay.schema)),'ACK-BRANCH-REPLAY-v1')
    error('ackBranchReplayConfig: unsupported replay schema.');
end
replay.schema='ACK-BRANCH-REPLAY-v1';
replay.mode=lower(strtrim(char(string(replay.mode))));
valid={'off','observe','admit-target','suppress-target'};
if ~ismember(replay.mode,valid)
    error('ackBranchReplayConfig: unsupported replay mode.');
end
if ~isscalar(replay.targetOrdinal) || ~isfinite(replay.targetOrdinal) || ...
        replay.targetOrdinal<0 || replay.targetOrdinal~=floor(replay.targetOrdinal)
    error('ackBranchReplayConfig: targetOrdinal must be a nonnegative integer.');
end
if ~isscalar(replay.localHorizon) || ~isfinite(replay.localHorizon) || ...
        replay.localHorizon<=0
    error('ackBranchReplayConfig: localHorizon must be positive.');
end

if ~replay.enabled
    if ~strcmp(replay.mode,'off') || replay.targetOrdinal~=0
        error(['ackBranchReplayConfig: disabled replay requires mode=off ' ...
            'and targetOrdinal=0.']);
    end
elseif strcmp(replay.mode,'off')
    error('ackBranchReplayConfig: enabled replay cannot use mode=off.');
elseif strcmp(replay.mode,'observe')
    if replay.targetOrdinal~=0
        error('ackBranchReplayConfig: observe mode requires targetOrdinal=0.');
    end
elseif replay.targetOrdinal<1
    error('ackBranchReplayConfig: target modes require targetOrdinal>=1.');
end

end


function value=logicalScalar(value,name)

if ~isscalar(value) || ...
        ~(islogical(value) || (isnumeric(value) && any(value==[0 1])))
    error('ackBranchReplayConfig: %s must be scalar logical.',name);
end
value=logical(value);

end
