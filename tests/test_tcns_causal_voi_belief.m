%% TEST_TCNS_CAUSAL_VOI_BELIEF Exact narrow-scope posterior/value contracts.

startup;

fprintf('\n=== TCNS causal one-shot VoI belief checks ===\n\n');

[cfg,~] = tcnsGate6Scenario(27020001,'S1');
h = cfg.swarm.dt;
assert(cfg.net.delay==4*h && cfg.ack.delay==4*h && ...
    cfg.net.packetLoss==0.2 && cfg.ack.loss==0, ...
    'CausalVoI: the exact-belief fixture channel changed.');

ack = struct('seq',0,'genTime',0,'pos',[0 0 0], ...
    'vel',[0 0 0],'acc',[NaN NaN NaN]);
records = repmat(struct('seq',0,'genTime',0,'pos',[0 0 0], ...
    'vel',[0 0 0],'acc',[NaN NaN NaN],'dropped',false),3,1);
records(1).seq = 1;
records(1).genTime = 0.00; % round-trip deadline has passed: known failure
records(1).pos = [1 0 0];
records(2).seq = 2;
records(2).genTime = 0.10; % ACK cannot yet have returned
records(2).pos = [2 0 0];
records(3).seq = 3;
records(3).genTime = 0.18; % DATA not yet arrived at current time
records(3).pos = [3 0 0];

currentTime = 0.20;
targetTime = 0.28;
B = tcnsCausalReceiverBelief(ack,records,currentTime,targetTime,cfg);
assert(isequal(B.candidateSeq,[0;2;3]), ...
    'CausalVoI: posterior candidate support is incorrect.');
assert(max(abs(B.probability-[0.04;0.16;0.80]))<1e-14, ...
    'CausalVoI: newest-success posterior probabilities are incorrect.');
assert(isequal(B.knownFailedSeq,1) && isempty(B.notYetArrivableSeq), ...
    'CausalVoI: ACK-deadline classification is incorrect.');
assert(B.normalizationResidual<1e-14 && B.exactWithinScope && ...
    ~B.usesReceiverTruth && ~B.usesDropOutcome, ...
    'CausalVoI: belief metadata or normalization is invalid.');

recordsFlipped = records;
for q = 1:numel(recordsFlipped)
    recordsFlipped(q).dropped = ~recordsFlipped(q).dropped;
end
Bflipped = tcnsCausalReceiverBelief( ...
    ack,recordsFlipped,currentTime,targetTime,cfg);
assert(isequaln(B,Bflipped), ...
    'CausalVoI: hidden simulator delivery outcomes changed the belief.');

source = fileread(fullfile(projectRoot(),'utils', ...
    'tcnsCausalReceiverBelief.m'));
assert(isempty(regexp(source,'\.dropped','once')), ...
    'CausalVoI: belief implementation reads the hidden dropped field.');

receiverId = 2;
H = 25;
emptyRecords = records([]);
currentPos = [1 0.2 -0.1];
currentVel = [0.4 -0.2 0.1];
positionGain = cfg.swarm.Kp;
velocityGain = cfg.swarm.Kv;
Vempty = tcnsCausalOneShotLinkValue( ...
    currentPos,currentVel,[],ack,emptyRecords,currentTime, ...
    positionGain,velocityGain,0,receiverId,cfg,H);

fresh = records(1);
fresh.seq = 1;
fresh.genTime = 0.18;
fresh.pos = currentPos;
fresh.vel = currentVel;
fresh.dropped = false;
VinFlight = tcnsCausalOneShotLinkValue( ...
    currentPos,currentVel,[],ack,fresh,currentTime, ...
    positionGain,velocityGain,0,receiverId,cfg,H);
assert(Vempty.score>0 && abs(VinFlight.score/Vempty.score-0.2)<1e-13, ...
    'CausalVoI: useful in-flight value was not credited exactly.');

fresh.dropped = true;
VinFlightFlipped = tcnsCausalOneShotLinkValue( ...
    currentPos,currentVel,[],ack,fresh,currentTime, ...
    positionGain,velocityGain,0,receiverId,cfg,H);
assert(isequaln(VinFlight,VinFlightFlipped), ...
    'CausalVoI: one-shot score used a hidden delivery outcome.');

cfgAckLoss = cfg;
cfgAckLoss.ack.loss = 0.1;
rejectedAckLoss = false;
try
    tcnsCausalReceiverBelief( ...
        ack,emptyRecords,currentTime,targetTime,cfgAckLoss);
catch err
    rejectedAckLoss = strcmp(err.identifier, ...
        'tcnsCausalReceiverBelief:AckLossOutOfScope');
end
assert(rejectedAckLoss, ...
    'CausalVoI: lossy ACKs were silently admitted to the exact posterior.');

fprintf('  posterior P[ACK,seq2,seq3]                [%.2f %.2f %.2f]\n', ...
    B.probability);
fprintf('  useful in-flight value / no-flight value  %.3f\n', ...
    VinFlight.score/Vempty.score);
fprintf('  hidden-outcome invariance                 PASS\n');
fprintf('test_tcns_causal_voi_belief: PASS\n');

