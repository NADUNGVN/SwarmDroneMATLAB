function B = tcnsCausalReceiverBelief( ...
    ackPayload,outstanding,currentTime,targetTime,cfg)
%TCNSCAUSALRECEIVERBELIEF Exact ACK-conditioned belief in a narrow channel scope.
%
%   B = tcnsCausalReceiverBelief(ackPayload,outstanding,t,target,cfg)
%
% Under static IID forward loss, deterministic sampled DATA/ACK delays and
% reliable ACK delivery, compute the exact conditional distribution of the
% receiver-held payload at TARGET using transmitter information at time t.
% The receiver accepts the newest successfully delivered sequence.
%
% An outstanding record whose deterministic round-trip deadline is no later
% than t is known to have failed: if it had been accepted, its reliable ACK
% would already have retired it. A younger outstanding record remains an
% independent Bernoulli candidate once its DATA arrival is due by TARGET.
%
% This deliberately narrow result is the algebraic checkpoint before any
% online VoI policy. Time-varying channels, jitter, ACK loss, topology faults
% and blackouts are rejected rather than silently approximated.

requiredAck = {'seq','genTime','pos','vel'};
for q = 1:numel(requiredAck)
    if ~isfield(ackPayload,requiredAck{q})
        error('tcnsCausalReceiverBelief:InvalidAckPayload', ...
            'ackPayload.%s is required.',requiredAck{q});
    end
end
validateattributes(currentTime,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'currentTime',3);
validateattributes(targetTime,{'numeric'}, ...
    {'real','finite','scalar','>=',currentTime},mfilename,'targetTime',4);
localValidateScope(cfg);

h = cfg.swarm.dt;
np = netParamsAt(cfg,currentTime);
ap = ackParamsAt(cfg,currentTime);
dataDelaySteps = localDelaySteps(np.delay,h);
ackDelaySteps = localDelaySteps(max(ap.delay,h),h);
roundTripSteps = dataDelaySteps+ackDelaySteps;
forwardSuccess = 1-np.packetLoss;

ackSeq = double(ackPayload.seq);
ackGenTime = double(ackPayload.genTime);
validateattributes(ackSeq,{'numeric'}, ...
    {'real','finite','integer','nonnegative','scalar'}, ...
    mfilename,'ackPayload.seq');
validateattributes(ackGenTime,{'numeric'}, ...
    {'real','finite','nonnegative','scalar','<=',currentTime}, ...
    mfilename,'ackPayload.genTime');
ackPos = localVector(ackPayload.pos,'ackPayload.pos');
ackVel = localVector(ackPayload.vel,'ackPayload.vel');
ackAcc = localAcceleration(ackPayload);

if isempty(outstanding)
    records = outstanding;
else
    requiredRecord = {'seq','genTime','pos','vel'};
    for q = 1:numel(requiredRecord)
        if ~isfield(outstanding,requiredRecord{q})
            error('tcnsCausalReceiverBelief:InvalidOutstanding', ...
                'Outstanding records require field %s.',requiredRecord{q});
        end
    end
    seq = double([outstanding.seq]);
    gen = double([outstanding.genTime]);
    if any(~isfinite(seq)) || any(seq~=floor(seq)) || ...
            any(seq<=ackSeq) || numel(unique(seq))~=numel(seq)
        error('tcnsCausalReceiverBelief:OutstandingSequence', ...
            'Outstanding sequences must be unique integers above ACK seq.');
    end
    [seq,order] = sort(seq);
    records = outstanding(order);
    gen = gen(order);
    if any(~isfinite(gen)) || any(diff(gen)<-1e-12) || ...
            any(gen>currentTime+1e-12)
        error('tcnsCausalReceiverBelief:OutstandingTime', ...
            'Outstanding generation times must be ordered and not future.');
    end
end

candidateSeq = ackSeq;
candidateGen = ackGenTime;
candidatePos = ackPos;
candidateVel = ackVel;
candidateAcc = ackAcc;
arrivalProbability = zeros(0,1);
knownFailedSeq = zeros(0,1);
notYetArrivableSeq = zeros(0,1);

for q = 1:numel(records)
    rec = records(q);
    sendStepAge = localGridSteps(currentTime-rec.genTime,h, ...
        'currentTime-outstanding.genTime');
    targetStepAge = localGridSteps(targetTime-rec.genTime,h, ...
        'targetTime-outstanding.genTime');

    if sendStepAge>=roundTripSteps
        knownFailedSeq(end+1,1) = rec.seq; %#ok<AGROW>
        continue;
    end
    if targetStepAge<dataDelaySteps
        notYetArrivableSeq(end+1,1) = rec.seq; %#ok<AGROW>
        continue;
    end

    candidateSeq(end+1,1) = rec.seq; %#ok<AGROW>
    candidateGen(end+1,1) = rec.genTime; %#ok<AGROW>
    candidatePos(end+1,:) = localVector(rec.pos,'outstanding.pos'); %#ok<AGROW>
    candidateVel(end+1,:) = localVector(rec.vel,'outstanding.vel'); %#ok<AGROW>
    candidateAcc(end+1,:) = localAcceleration(rec); %#ok<AGROW>
    arrivalProbability(end+1,1) = forwardSuccess; %#ok<AGROW>
end

nUncertain = numel(arrivalProbability);
probability = zeros(nUncertain+1,1);
probability(1) = prod(1-arrivalProbability);
for q = 1:nUncertain
    probability(q+1) = arrivalProbability(q) * ...
        prod(1-arrivalProbability(q+1:end));
end
normalizationResidual = abs(sum(probability)-1);
if normalizationResidual>1e-12
    error('tcnsCausalReceiverBelief:Normalization', ...
        'Candidate probabilities do not sum to one.');
end

B.candidateSeq = candidateSeq;
B.candidateGenTime = candidateGen;
B.candidatePos = candidatePos;
B.candidateVel = candidateVel;
B.candidateAcc = candidateAcc;
B.probability = probability;
B.ackProbability = probability(1);
B.uncertainArrivalProbability = arrivalProbability;
B.knownFailedSeq = knownFailedSeq;
B.notYetArrivableSeq = notYetArrivableSeq;
B.expectedGenTime = sum(probability.*candidateGen);
B.expectedAgeAtTarget_s = targetTime-B.expectedGenTime;
B.currentTime_s = currentTime;
B.targetTime_s = targetTime;
B.dataDelaySamples = dataDelaySteps;
B.ackDelaySamples = ackDelaySteps;
B.roundTripSamples = roundTripSteps;
B.forwardSuccessProbability = forwardSuccess;
B.normalizationResidual = normalizationResidual;
B.exactWithinScope = true;
B.usesReceiverTruth = false;
B.usesDropOutcome = false;
B.scope = [ ...
    'static IID forward loss; deterministic sampled DATA/ACK delay; ' ...
    'reliable ACK; newest-sequence receiver acceptance'];

end


function localValidateScope(cfg)

if isfield(cfg.net,'regime') && ~isempty(cfg.net.regime)
    error('tcnsCausalReceiverBelief:TimeVaryingForwardChannel', ...
        'A time-varying forward channel is outside the exact first belief.');
end
if isfield(cfg.ack,'regime') && ~isempty(cfg.ack.regime)
    error('tcnsCausalReceiverBelief:TimeVaryingAckChannel', ...
        'A time-varying ACK channel is outside the exact first belief.');
end
if isfield(cfg.net,'lossModel') && ~isempty(cfg.net.lossModel) && ...
        isfield(cfg.net.lossModel,'type') && ...
        ~strcmpi(cfg.net.lossModel.type,'iid')
    error('tcnsCausalReceiverBelief:NonIidLoss', ...
        'The exact first belief requires IID forward loss.');
end
if cfg.net.jitterStd~=0 || cfg.ack.jitterStd~=0
    error('tcnsCausalReceiverBelief:JitterOutOfScope', ...
        'The exact first belief requires deterministic delays.');
end
if cfg.ack.loss~=0
    error('tcnsCausalReceiverBelief:AckLossOutOfScope', ...
        'Absence of an ACK identifies failure only when ACK loss is zero.');
end
if (isfield(cfg,'fault') && ~isempty(cfg.fault)) || ...
        (isfield(cfg,'blackout') && ~isempty(cfg.blackout))
    error('tcnsCausalReceiverBelief:AvailabilityFaultOutOfScope', ...
        'Link/node availability faults require a separate hidden-state belief.');
end

end


function steps = localDelaySteps(delay,h)

validateattributes(delay,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'});
steps = max(0,ceil((delay-1e-12)/h));

end


function steps = localGridSteps(duration,h,label)

raw = duration/h;
steps = round(raw);
if duration<-1e-12 || abs(raw-steps)>1e-8
    error('tcnsCausalReceiverBelief:OffGridTime', ...
        '%s must be a nonnegative integer number of samples.',label);
end

end


function x = localVector(x,label)

x = double(x(:)');
if numel(x)~=3 || any(~isfinite(x))
    error('tcnsCausalReceiverBelief:InvalidVector', ...
        '%s must be a finite three-vector.',label);
end

end


function a = localAcceleration(payload)

if isfield(payload,'acc') && ~isempty(payload.acc)
    a = double(payload.acc(:)');
    if numel(a)~=3 || any(~isfinite(a) & ~isnan(a))
        error('tcnsCausalReceiverBelief:InvalidAcceleration', ...
            'Payload acceleration must be a finite/NaN three-vector.');
    end
else
    a = nan(1,3);
end

end
