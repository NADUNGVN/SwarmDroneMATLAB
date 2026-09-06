function trace = generateSharedMediumTrace(cfg)
%GENERATESHAREDMEDIUMTRACE Pre-draw policy-independent shared-medium outcomes.
%
% Legacy iid configurations retain the original access/loss/background draw
% order and hash. Extended configurations add an independent ACK loss trace
% and absolute per-link Gilbert-Elliott state transitions. Policy actions never
% advance an RNG or a channel-state machine.

mac = sharedMediumConfig(cfg);
N   = cfg.swarm.N;
K   = ceil(cfg.swarm.T/mac.slotTime) + 2;

if isfield(cfg,'net') && isfield(cfg.net,'seed')
    baseSeed = cfg.net.seed;
else
    baseSeed = 1;
end

seed = mod(baseSeed + mac.seedOffset, 2^32);
stream = RandStream('mt19937ar','Seed',seed);

% Absolute (slot,node) and (slot,receiver,sender) indexing preserves common
% random numbers even when policies generate different numbers of frames.
trace.accessU = rand(stream,K,N);
trace.lossU   = rand(stream,K,N,N);
trace.backgroundU = rand(stream,K,1);
trace.dataLossU = trace.lossU;
trace.slotTime = mac.slotTime;
trace.K = K;
trace.N = N;
trace.seed = baseSeed;
trace.modelSignature = sharedMediumChannelSignature(mac,N);

extended = mac.separateAckTrace || strcmp(mac.lossModel,'gilbert-elliott');
if ~extended
    % Preserve EXP12/EXP13 stochastic behavior and hash exactly when none of
    % the new channel features is requested.
    trace.ackLossU = trace.lossU;
    trace.dataTransitionU = zeros(0,1);
    trace.ackTransitionU = zeros(0,1);
    trace.dataBadState = false(0,1);
    trace.ackBadState = false(0,1);
    trace.channelStateHash = 0;
    trace.hashExact = realizationHash([ ...
        trace.accessU(:); trace.lossU(:); trace.backgroundU(:)]);
else
    trace.ackLossU = rand(stream,K,N,N);
    trace.dataTransitionU = rand(stream,K,N,N);
    trace.ackTransitionU = rand(stream,K,N,N);

    if strcmp(mac.lossModel,'gilbert-elliott')
        trace.dataBadState = buildBadStateTrace( ...
            trace.dataTransitionU,mac.burst.dataGoodToBad, ...
            mac.burst.dataBadToGood,N);
        trace.ackBadState = buildBadStateTrace( ...
            trace.ackTransitionU,mac.burst.ackGoodToBad, ...
            mac.burst.ackBadToGood,N);
        trace.channelStateHash = realizationHash([ ...
            trace.dataBadState(:); trace.ackBadState(:)]);
    else
        trace.dataBadState = false(0,1);
        trace.ackBadState = false(0,1);
        trace.channelStateHash = 0;
    end

    trace.hashExact = realizationHash([trace.accessU(:); ...
        trace.lossU(:); trace.backgroundU(:); trace.ackLossU(:); ...
        trace.dataTransitionU(:); trace.ackTransitionU(:)]);
end

if isempty(trace.dataBadState)
    trace.dataBadFraction = 0;
    trace.ackBadFraction = 0;
else
    trace.dataBadFraction = mean(trace.dataBadState(:));
    trace.ackBadFraction = mean(trace.ackBadState(:));
end

% EXP21 scheduling draws are appended only when its frozen context is
% present.  Older studies therefore retain their exact RNG order and hash.
if isfield(cfg,'exp21a')
    trace.exp21ControlChoiceU=rand(stream,K,N);
    trace.exp21RequestLossU=rand(stream,K,N,N);
    trace.exp21ResponseLossU=rand(stream,K,N,N);
    trace.exp21CommitLossU=rand(stream,K,N,N);
    trace.exp21ClockOffsetU=rand(stream,N,1);
    trace.exp21ClockDriftU=rand(stream,N,1);
    trace.exp21HashExact=realizationHash([ ...
        trace.exp21ControlChoiceU(:);trace.exp21RequestLossU(:); ...
        trace.exp21ResponseLossU(:);trace.exp21CommitLossU(:); ...
        trace.exp21ClockOffsetU(:);trace.exp21ClockDriftU(:)]);
    trace.hashExact=realizationHash([trace.hashExact;trace.exp21HashExact]);
end

if isfield(cfg,'exp21c')
    trace.exp21cClockOffsetU=rand(stream,K,N);
    trace.exp21cClockDriftU=rand(stream,N,1);
    trace.exp21cSyncLossU=rand(stream,K,N,N);
    trace.exp21cHashExact=realizationHash([ ...
        trace.exp21cClockOffsetU(:);trace.exp21cClockDriftU(:); ...
        trace.exp21cSyncLossU(:)]);
    trace.hashExact=realizationHash([trace.hashExact;trace.exp21cHashExact]);
end

end


function state = buildBadStateTrace(u,pGoodToBad,pBadToGood,N)

K = size(u,1);
pGB = expandMap(pGoodToBad,N);
pBG = expandMap(pBadToGood,N);
denominator = pGB+pBG;
pInitialBad = zeros(N);
positive = denominator>0;
pInitialBad(positive)=pGB(positive)./denominator(positive);

state = false(K,N,N);
state(1,:,:) = u(1,:,:) < reshape(pInitialBad,1,N,N);
for k = 2:K
    previous = reshape(state(k-1,:,:),N,N);
    draw = reshape(u(k,:,:),N,N);
    next = (~previous & draw<pGB) | (previous & draw>=pBG);
    state(k,:,:) = reshape(next,1,N,N);
end

end


function y = expandMap(x,N)

if isscalar(x)
    y = repmat(x,N,N);
else
    y = x;
end

end
