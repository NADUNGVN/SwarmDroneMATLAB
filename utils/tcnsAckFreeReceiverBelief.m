function B = tcnsAckFreeReceiverBelief( ...
    initialPayload,sentHistory,currentTime,targetTime,cfg)
%TCNSACKFREERECEIVERBELIEF Exact no-feedback packet-memory PMF in S2/S6 scope.
%
% B = tcnsAckFreeReceiverBelief(initialPayload,sentHistory,t,tau,cfg)
%
% The information set is intentionally limited to the common initial
% receiver payload, sender-side attempted-packet history, time, and the
% static IID channel law. There is no observation update. Successfully
% delivered packets arrive after a deterministic sampled delay, and the
% receiver retains the newest generation.
%
% This function does not accept a network state or trace. Extra fields on a
% history record are ignored, so simulator-private realization annotations
% cannot affect the result.

requiredInitial = {'seq','genTime','pos','vel'};
localRequireFields(initialPayload,requiredInitial,'initialPayload');
validateattributes(currentTime,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,'currentTime',3);
validateattributes(targetTime,{'numeric'}, ...
    {'real','finite','scalar','>=',currentTime},mfilename,'targetTime',4);
localValidateScope(cfg);

h = cfg.swarm.dt;
np = netParamsAt(cfg,currentTime);
delaySamples = localDelaySamples(np.delay,h);
lossProbability = double(np.packetLoss);
validateattributes(lossProbability,{'numeric'}, ...
    {'real','finite','scalar','>=',0,'<=',1},mfilename,'packetLoss');

initialSeq = localSequence(initialPayload.seq,'initialPayload.seq');
initialGen = localGridTime(initialPayload.genTime,h, ...
    'initialPayload.genTime');
if initialGen>currentTime+1e-12
    error('tcnsAckFreeReceiverBelief:FutureInitialPayload', ...
        'The common initial receiver payload cannot be from the future.');
end
initialPos = localVector(initialPayload.pos,'initialPayload.pos');
initialVel = localVector(initialPayload.vel,'initialPayload.vel');
initialAcc = localAcceleration(initialPayload);

if isempty(sentHistory)
    records = sentHistory;
else
    requiredRecord = {'seq','sendTime','genTime','pos','vel'};
    localRequireFields(sentHistory,requiredRecord,'sentHistory');
    seq = arrayfun(@(x)localSequence(x.seq,'sentHistory.seq'),sentHistory);
    sendTime = arrayfun(@(x)localGridTime( ...
        x.sendTime,h,'sentHistory.sendTime'),sentHistory);
    genTime = arrayfun(@(x)localGridTime( ...
        x.genTime,h,'sentHistory.genTime'),sentHistory);
    if any(seq<=initialSeq) || numel(unique(seq))~=numel(seq)
        error('tcnsAckFreeReceiverBelief:SequenceOrder', ...
            'Packet sequences must be unique and newer than the initial state.');
    end
    [seq,order] = sort(seq);
    records = sentHistory(order);
    sendTime = sendTime(order);
    genTime = genTime(order);
    if any(genTime<=initialGen+1e-12) || ...
            any(diff(sendTime)<-1e-12) || any(diff(genTime)<=1e-12) || ...
            any(sendTime>currentTime+1e-12) || any(genTime>sendTime+1e-12)
        error('tcnsAckFreeReceiverBelief:HistoryOrder', ...
            ['Generation/send times must agree with sequence order, be ' ...
             'strictly newer by generation, and not be future.']);
    end
end

nRecords = numel(records);
recordSeq = zeros(nRecords,1);
recordGen = zeros(nRecords,1);
recordSend = zeros(nRecords,1);
recordPos = zeros(nRecords,3);
recordVel = zeros(nRecords,3);
recordAcc = nan(nRecords,3);
for q = 1:nRecords
    recordSeq(q) = double(records(q).seq);
    recordGen(q) = double(records(q).genTime);
    recordSend(q) = double(records(q).sendTime);
    recordPos(q,:) = localVector(records(q).pos,'sentHistory.pos');
    recordVel(q,:) = localVector(records(q).vel,'sentHistory.vel');
    recordAcc(q,:) = localAcceleration(records(q));
end

arrivalTime = recordSend+delaySamples*h;
maturedMask = arrivalTime<=targetTime+1e-12;
maturedIndex = find(maturedMask);
inFlightIndex = find(~maturedMask);
M = numel(maturedIndex);

candidateSeq = [initialSeq;recordSeq(maturedIndex)];
candidateGen = [initialGen;recordGen(maturedIndex)];
candidatePos = [initialPos;recordPos(maturedIndex,:)];
candidateVel = [initialVel;recordVel(maturedIndex,:)];
candidateAcc = [initialAcc;recordAcc(maturedIndex,:)];

probability = zeros(M+1,1);
if M==0
    probability(1) = 1;
else
    newestCount = (M:-1:1)';
    probability(1) = lossProbability^M;
    probability(2:end) = ...
        (1-lossProbability).*lossProbability.^(newestCount-1);
end
normalizationResidual = abs(sum(probability)-1);
if any(probability<0) || normalizationResidual>1e-12
    error('tcnsAckFreeReceiverBelief:Normalization', ...
        'The exact packet-memory probabilities are invalid.');
end

B.candidateSeq = candidateSeq;
B.candidateGenTime = candidateGen;
B.candidatePos = candidatePos;
B.candidateVel = candidateVel;
B.candidateAcc = candidateAcc;
B.probability = probability;
B.maturedSeq = recordSeq(maturedIndex);
B.inFlightSeq = recordSeq(inFlightIndex);
B.maturedArrivalTime_s = arrivalTime(maturedIndex);
B.inFlightArrivalTime_s = arrivalTime(inFlightIndex);
B.expectedGenTime = sum(probability.*candidateGen);
B.expectedAgeAtTarget_s = targetTime-B.expectedGenTime;
B.currentTime_s = currentTime;
B.targetTime_s = targetTime;
B.dataDelaySamples = delaySamples;
B.lossProbability = lossProbability;
B.normalizationResidual = normalizationResidual;
B.supportSize = numel(probability);
B.exactWithinCommunicationFiltration = true;
B.conditionsOnPlantObservationHistory = false;
B.usesAck = false;
B.usesReceiverState = false;
B.usesRealizedChannelOutcome = false;
B.usesFutureInformation = false;
B.constructionTimeComplexity = 'O(number of attempted records)';
B.storageComplexity = 'O(number of attempted records)';
B.scope = [ ...
    'common initial memory; sender attempted-packet history; static IID ' ...
    'DATA erasure; deterministic sampled delay; newest-generation receiver'];

end


function localValidateScope(cfg)

if ~isfield(cfg,'swarm') || ~isfield(cfg.swarm,'dt') || ...
        ~isfield(cfg,'net')
    error('tcnsAckFreeReceiverBelief:InvalidConfig', ...
        'cfg.swarm.dt and cfg.net are required.');
end
validateattributes(cfg.swarm.dt,{'numeric'}, ...
    {'real','finite','positive','scalar'},mfilename,'cfg.swarm.dt');
requiredNet = {'packetLoss','delay','jitterStd'};
localRequireFields(cfg.net,requiredNet,'cfg.net');
if isfield(cfg.net,'regime') && ~isempty(cfg.net.regime)
    error('tcnsAckFreeReceiverBelief:TimeVaryingChannel', ...
        'The exact AF0 belief excludes time-varying channels.');
end
if isfield(cfg.net,'lossModel') && ~isempty(cfg.net.lossModel) && ...
        isfield(cfg.net.lossModel,'type') && ...
        ~strcmpi(cfg.net.lossModel.type,'iid')
    error('tcnsAckFreeReceiverBelief:NonIidLoss', ...
        'The exact AF0 belief requires static IID DATA erasures.');
end
if cfg.net.jitterStd~=0
    error('tcnsAckFreeReceiverBelief:JitterOutOfScope', ...
        'The exact AF0 belief requires deterministic DATA delay.');
end
if (isfield(cfg,'fault') && ~isempty(cfg.fault)) || ...
        (isfield(cfg,'blackout') && ~isempty(cfg.blackout))
    error('tcnsAckFreeReceiverBelief:AvailabilityOutOfScope', ...
        'Faults and blackouts require an augmented hidden-state belief.');
end

end


function localRequireFields(value,names,label)

for q = 1:numel(names)
    if ~isfield(value,names{q})
        error('tcnsAckFreeReceiverBelief:MissingField', ...
            '%s.%s is required.',label,names{q});
    end
end

end


function seq = localSequence(seq,label)

seq = double(seq);
validateattributes(seq,{'numeric'}, ...
    {'real','finite','integer','nonnegative','scalar'},mfilename,label);

end


function value = localGridTime(value,h,label)

value = double(value);
validateattributes(value,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'},mfilename,label);
sample = round(value/h);
if abs(value/h-sample)>1e-8
    error('tcnsAckFreeReceiverBelief:OffGridTime', ...
        '%s must lie on the outer sample grid.',label);
end

end


function delaySamples = localDelaySamples(delay,h)

validateattributes(delay,{'numeric'}, ...
    {'real','finite','nonnegative','scalar'});
delaySamples = max(0,ceil((delay-1e-12)/h));

end


function value = localVector(value,label)

value = double(value(:)');
if numel(value)~=3 || any(~isfinite(value))
    error('tcnsAckFreeReceiverBelief:InvalidVector', ...
        '%s must be a finite three-vector.',label);
end

end


function value = localAcceleration(payload)

if isfield(payload,'acc') && ~isempty(payload.acc)
    value = double(payload.acc(:)');
    if numel(value)~=3 || any(~isfinite(value) & ~isnan(value))
        error('tcnsAckFreeReceiverBelief:InvalidAcceleration', ...
            'Payload acceleration must be a finite/NaN three-vector.');
    end
else
    value = nan(1,3);
end

end
