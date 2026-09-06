function trace = generateNetworkTrace(cfg)
%GENERATENETWORKTRACE Pre-draw one network realisation, shared by all methods.
%
%   trace = generateNetworkTrace(cfg)
%
% Sharing a seed is NOT the same as sharing a realisation. Each policy calls
% rand a different number of times, so identical seeds desynchronise on the
% first transmission and the runs stop being paired. Seeds buy
% reproducibility; they do not buy common random numbers.
%
% This draws the channel outcome for every (link, timestep) IN ADVANCE, as a
% pure function of the seed, the swarm size and the horizon. Nothing about
% any policy enters. A method then consumes trace(i,j,k) at the instant it
% transmits, so two methods transmitting on the same link at the same
% timestep meet exactly the same channel, and a method that stays silent
% consumes nothing and disturbs nothing.
%
% The trace is regenerated inside each worker from the seed rather than
% broadcast, so parfor pays no communication cost even at N = 50.
%
% Fields (all K x N x N, or K x N for the leader links):
%
%   lossU        uniform draw; the packet is dropped when lossU < packetLoss
%   jitterZ      standard normal draw for delay jitter
%   leaderLossU  same, for the pinned leader links
%   leaderJitterZ
%
% Indexing convention matches the rest of the project: (i, j) is the link
% carrying data from transmitter j to receiver i.

N = cfg.swarm.N;

% Trace length. By default one slot per outer step, exactly as every
% locked experiment has used it. With cfg.net.traceBaseDt set, the trace
% lives on a master physical-time grid instead, so runs at different
% outer dt meet the same channel realization at the same instant.
if isfield(cfg,'net') && isfield(cfg.net,'traceBaseDt') ...
        && ~isempty(cfg.net.traceBaseDt) && cfg.net.traceBaseDt > 0
    K = numel(0:cfg.net.traceBaseDt:cfg.swarm.T) + 1;
else
    K = numel(0:cfg.swarm.dt:cfg.swarm.T);
end


%% ============================================================
% Dedicated stream
%
% Separate from the simulation's own rng() so that adding or removing
% a trace never perturbs anything else that draws randomness.
% ============================================================

seed = mod(cfg.net.seed + 20240001, 2^32);

stream = RandStream('mt19937ar', 'Seed', seed);


trace.lossU   = rand(stream, K, N, N);
trace.jitterZ = randn(stream, K, N, N);

trace.leaderLossU   = rand(stream, K, N);
trace.leaderJitterZ = randn(stream, K, N);


%% ============================================================
% Optional Gate-6 burst-loss trace
%
% Default/explicit IID leaves every historical field and draw untouched.
% Gilbert-Elliott uses a second dedicated stream, so adding it cannot shift
% delay jitter or the frozen IID realization. Channel state evolves on the
% physical outer-tick trace independently of whether a policy transmits.
% ============================================================

trace.lossModel = 'iid';
if isfield(cfg.net,'lossModel') && ~isempty(cfg.net.lossModel)
    model = cfg.net.lossModel;
    if ~isfield(model,'type')
        error('generateNetworkTrace:MissingLossModelType', ...
            'cfg.net.lossModel.type is required.');
    end
    switch lower(char(model.type))
        case 'iid'
            % Explicit IID is exactly the historical trace.
        case 'gilbert-elliott'
            [trace.dropMask,trace.badState, ...
                trace.leaderDropMask,trace.leaderBadState] = ...
                localGilbertElliott(K,N,cfg.net.seed,model);
            trace.lossModel = 'gilbert-elliott';
        otherwise
            error('generateNetworkTrace:UnknownLossModel', ...
                'Unknown loss model "%s".',model.type);
    end
end


%% ============================================================
% Provenance
%
% The hash lets an experiment prove every method ran on the same
% realisation rather than merely asserting it.
% ============================================================

trace.seed = cfg.net.seed;
trace.N    = N;
trace.K    = K;

% The realisation, flattened once and hashed twice.
flat = [ ...
    trace.lossU(:); ...
    trace.jitterZ(:); ...
    trace.leaderLossU(:); ...
    trace.leaderJitterZ(:)];

if strcmp(trace.lossModel,'gilbert-elliott')
    flat = [flat; double(trace.dropMask(:)); double(trace.badState(:)); ...
        double(trace.leaderDropMask(:)); double(trace.leaderBadState(:))]; %#ok<AGROW>
end

% LOCKED hash. Its values appear in EXP07-EXP09 result tables, so the
% formula must not change. It is NOT thread-stable: it sums millions of
% floats whose partial sums exceed 2^53, and MATLAB's sum() groups
% differently depending on thread count, so the same realisation hashes
% differently in the multithreaded client than on a single-threaded pool
% worker. Kept for continuity, reported rather than gated.
trace.hash = localHash(flat);

% EXACT hash, added for EXP10. Integer arithmetic below 2^53 throughout,
% so summation order cannot move it, and it round-trips through the CSV.
% This is the one EXP10 gates on. See utils/realizationHash.m.
trace.hashExact = realizationHash(flat);

end


%% ============================================================
% LOCAL FUNCTION
%
% Cheap order-sensitive checksum. Not cryptographic; it only has to
% detect that two runs used different realisations.
%
% NOT thread-stable, and deliberately unchanged: see the note at the
% call site.
% ============================================================

function h = localHash(v)

n = numel(v);

idx = (1:n)';

h = mod(sum(mod(floor(abs(v)*1e12), 1e9) .* mod(idx,9973)), 2^53 - 1);

end


function [drop,bad,leaderDrop,leaderBad] = ...
    localGilbertElliott(K,N,seedValue,model)

required = {'pGoodToBad','pBadToGood','lossGood','lossBad'};
for q = 1:numel(required)
    if ~isfield(model,required{q})
        error('generateNetworkTrace:MissingGilbertElliottParameter', ...
            'lossModel.%s is required.',required{q});
    end
    validateattributes(model.(required{q}),{'numeric'}, ...
        {'real','finite','scalar','>=',0,'<=',1}, ...
        mfilename,['lossModel.' required{q}]);
end

burstStream = RandStream('mt19937ar', ...
    'Seed',mod(seedValue+30340001,2^32));
transitionU = rand(burstStream,K,N,N);
dropU = rand(burstStream,K,N,N);
leaderTransitionU = rand(burstStream,K,N);
leaderDropU = rand(burstStream,K,N);

bad = false(K,N,N);
leaderBad = false(K,N);
for k = 2:K
    previous = reshape(bad(k-1,:,:),N,N);
    u = reshape(transitionU(k,:,:),N,N);
    next = previous;
    next(~previous) = u(~previous)<model.pGoodToBad;
    next(previous) = ~(u(previous)<model.pBadToGood);
    bad(k,:,:) = reshape(next,1,N,N);

    previousLeader = leaderBad(k-1,:);
    uLeader = leaderTransitionU(k,:);
    nextLeader = previousLeader;
    nextLeader(~previousLeader) = ...
        uLeader(~previousLeader)<model.pGoodToBad;
    nextLeader(previousLeader) = ...
        ~(uLeader(previousLeader)<model.pBadToGood);
    leaderBad(k,:) = nextLeader;
end

lossProbability = model.lossGood*ones(K,N,N);
lossProbability(bad) = model.lossBad;
drop = dropU<lossProbability;
leaderLossProbability = model.lossGood*ones(K,N);
leaderLossProbability(leaderBad) = model.lossBad;
leaderDrop = leaderDropU<leaderLossProbability;

end
