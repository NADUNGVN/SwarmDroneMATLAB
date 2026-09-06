function trace=buildMeasuredSharedMediumTrace(cfg,measurement,replaySeed)
%BUILDMEASUREDSHAREDMEDIUMTRACE Build a policy-independent measured trace.
%
% trace = buildMeasuredSharedMediumTrace(cfg,measurement,replaySeed)
%
% measurement follows docs/EXP15_TRACE_REPLAY_CONTRACT.md. This boundary
% treats measurement as untrusted external data and fails before simulation.

if nargin~=3
    error('measuredTrace:Arity', ...
        'cfg, measurement and replaySeed are required.');
end
if ~isstruct(cfg) || ~isscalar(cfg) || ~isfield(cfg,'swarm') || ...
        ~isfield(cfg.swarm,'N') || ~isfield(cfg.swarm,'T')
    error('measuredTrace:InvalidConfig', ...
        'cfg must expose scalar swarm.N and swarm.T.');
end
if ~isscalar(replaySeed) || ~isfinite(replaySeed) || replaySeed<0 || ...
        replaySeed~=floor(replaySeed) || replaySeed>=2^32
    error('measuredTrace:InvalidReplaySeed', ...
        'replaySeed must be an integer in [0,2^32).');
end

mac=sharedMediumConfig(cfg);
M=validateMeasurement(measurement,cfg,mac);
K=numel(M.timeSec); N=M.N;

stream=RandStream('mt19937ar','Seed',double(replaySeed));
trace.accessU=rand(stream,K,N);
trace.lossU=rand(stream,K,N,N);
trace.dataLossU=trace.lossU;
trace.ackLossU=rand(stream,K,N,N);
trace.backgroundU=zeros(K,1);
trace.dataTransitionU=zeros(0,1);
trace.ackTransitionU=zeros(0,1);

trace.slotTime=M.slotTime;
trace.K=K;
trace.N=N;
trace.seed=double(replaySeed);
trace.modelSignature=sharedMediumChannelSignature(mac,N);
trace.sourceMode='measured-probability-v1';
trace.schemaVersion=M.schemaVersion;
trace.sourceId=M.sourceId;
trace.measuredDataLossProbability=M.dataLossProbability;
trace.measuredAckLossProbability=M.ackLossProbability;
trace.measuredBackgroundActive=logical(M.backgroundActive);
trace.dataBadState=logical(M.dataBadState);
trace.ackBadState=logical(M.ackBadState);
trace.dataBadFraction=mean(trace.dataBadState(:));
trace.ackBadFraction=mean(trace.ackBadState(:));
trace.measurementHash=realizationHash([M.timeSec(:); ...
    M.dataLossProbability(:); M.ackLossProbability(:); ...
    double(M.dataBadState(:)); double(M.ackBadState(:)); ...
    double(M.backgroundActive(:))]);
trace.channelStateHash=realizationHash([trace.dataBadState(:); ...
    trace.ackBadState(:)]);
trace.hashExact=realizationHash([trace.accessU(:);trace.lossU(:); ...
    trace.ackLossU(:);double(trace.measuredBackgroundActive(:)); ...
    trace.measuredDataLossProbability(:); ...
    trace.measuredAckLossProbability(:); ...
    double(trace.dataBadState(:));double(trace.ackBadState(:))]);

validateMeasuredSharedMediumTrace(trace,cfg);

end


function M=validateMeasurement(M,cfg,mac)

required={'schemaVersion','sourceId','slotTime','N','timeSec', ...
    'dataLossProbability','ackLossProbability','dataBadState', ...
    'ackBadState','backgroundActive'};
if ~isstruct(M) || ~isscalar(M)
    error('measuredTrace:InvalidMeasurement', ...
        'measurement must be a scalar struct.');
end
for k=1:numel(required)
    if ~isfield(M,required{k})
        error('measuredTrace:MissingField', ...
            'measurement lacks required field %s.',required{k});
    end
end
M.schemaVersion=char(string(M.schemaVersion));
if ~strcmp(M.schemaVersion,'MEASURED-SHARED-MEDIUM-v1')
    error('measuredTrace:UnsupportedSchema', ...
        'schemaVersion must be MEASURED-SHARED-MEDIUM-v1.');
end
M.sourceId=char(string(M.sourceId));
if isempty(strtrim(M.sourceId))
    error('measuredTrace:InvalidSourceId','sourceId must be nonempty.');
end
if ~isscalar(M.slotTime) || ~isfinite(M.slotTime) || M.slotTime<=0 || ...
        abs(M.slotTime-mac.slotTime)>1e-12
    error('measuredTrace:SlotTimeMismatch', ...
        'measurement.slotTime must equal cfg.mac.slotTime.');
end
if ~isscalar(M.N) || ~isfinite(M.N) || M.N<1 || M.N~=floor(M.N) || ...
        M.N~=cfg.swarm.N
    error('measuredTrace:NodeCountMismatch', ...
        'measurement.N must equal cfg.swarm.N.');
end
if ~isnumeric(M.timeSec) || ~iscolumn(M.timeSec) || ...
        any(~isfinite(M.timeSec)) || isempty(M.timeSec) || ...
        abs(M.timeSec(1))>1e-12 || ...
        any(abs(diff(M.timeSec)-M.slotTime)>1e-10)
    error('measuredTrace:InvalidTimeGrid', ...
        'timeSec must start at zero on a uniform slotTime grid.');
end
minimumK=ceil(cfg.swarm.T/mac.slotTime)+2;
if numel(M.timeSec)<minimumK
    error('measuredTrace:InsufficientHorizon', ...
        'measurement does not cover the configured simulation horizon.');
end
expected=[numel(M.timeSec) M.N M.N];
validateProbabilityTensor(M.dataLossProbability,expected, ...
    'dataLossProbability');
validateProbabilityTensor(M.ackLossProbability,expected, ...
    'ackLossProbability');
validateBinaryTensor(M.dataBadState,expected,'dataBadState');
validateBinaryTensor(M.ackBadState,expected,'ackBadState');
validateBinaryTensor(M.backgroundActive,[numel(M.timeSec) 1 1], ...
    'backgroundActive');
diagonal=false(numel(M.timeSec),1);
for n=1:M.N
    diagonal=diagonal | M.dataLossProbability(:,n,n)~=0 | ...
        M.ackLossProbability(:,n,n)~=0 | ...
        M.dataBadState(:,n,n)~=0 | M.ackBadState(:,n,n)~=0;
end
if any(diagonal)
    error('measuredTrace:NonzeroDiagonal', ...
        'self-link probability and state entries must be zero.');
end

end


function validateProbabilityTensor(x,expected,name)

if ~isnumeric(x) || ~isequal(size3(x),expected) || ...
        any(~isfinite(x(:)) | x(:)<0 | x(:)>1)
    error('measuredTrace:InvalidProbability', ...
        '%s must be a finite K-by-N-by-N tensor in [0,1].',name);
end

end


function validateBinaryTensor(x,expected,name)

if ~(isnumeric(x) || islogical(x)) || ~isequal(size3(x),expected) || ...
        any(~isfinite(double(x(:))) | (x(:)~=0 & x(:)~=1))
    error('measuredTrace:InvalidBinaryField', ...
        '%s must be a finite binary tensor with the declared shape.',name);
end

end


function value=size3(x)

value=[size(x,1) size(x,2) size(x,3)];

end
