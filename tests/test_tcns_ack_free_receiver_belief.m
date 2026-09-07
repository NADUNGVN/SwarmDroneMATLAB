%% TEST_TCNS_ACK_FREE_RECEIVER_BELIEF AF0--AF1 exact no-feedback contracts.

startup;

fprintf('\n=== TCNS ACK-free receiver-memory belief checks ===\n\n');

[cfg,~] = tcnsGate6Scenario(27020001,'S2');
h = cfg.swarm.dt;
assert(h==0.02 && cfg.net.delay==4*h && cfg.net.packetLoss==0.2 && ...
    cfg.net.jitterStd==0, ...
    'AckFreeBelief: S2/S6 frozen communication scope changed.');

initial = localPacket(0,0,0,[0 0 0]);
records = repmat(localPacket(0,0,0,[0 0 0]),3,1);
recordTimes = [0.02 0.10 0.20];
for q = 1:3
    records(q) = localPacket(q,recordTimes(q),recordTimes(q),[q 0 0]);
end

% At t=0.22 and target 0.22, records at 0 and 0.10 have matured, while
% the record at 0.20 remains in flight until 0.28.
B = tcnsAckFreeReceiverBelief(initial,records,0.22,0.22,cfg);
assert(isequal(B.candidateSeq,[0;1;2]) && isequal(B.inFlightSeq,3), ...
    'AckFreeBelief: matured/in-flight support is incorrect.');
assert(max(abs(B.probability-[0.04;0.16;0.80]))<1e-14, ...
    'AckFreeBelief: newest-success probabilities are incorrect.');
assert(abs(sum(B.probability)-1)<1e-14 && all(B.probability>=0), ...
    'AckFreeBelief: probability mass is invalid.');

% Closed form must match exhaustive Bernoulli enumeration.
expected = localExhaustiveNewest(2,cfg.net.packetLoss);
assert(max(abs(expected-B.probability))<1e-14, ...
    'AckFreeBelief: exhaustive enumeration disagrees with recursion.');

cfgNoLoss = cfg;
cfgNoLoss.net.packetLoss = 0;
B0 = tcnsAckFreeReceiverBelief(initial,records,0.22,0.22,cfgNoLoss);
assert(B0.probability(end)==1 && B0.candidateSeq(end)==2, ...
    'AckFreeBelief: deterministic no-loss limit did not collapse.');

cfgAllLoss = cfg;
cfgAllLoss.net.packetLoss = 1;
B1 = tcnsAckFreeReceiverBelief(initial,records,0.22,0.22,cfgAllLoss);
assert(B1.probability(1)==1 && B1.candidateSeq(1)==0, ...
    'AckFreeBelief: all-loss limit did not collapse.');

% Hidden realization annotations are outside the function's interface.
recordsHidden = records;
for q = 1:numel(recordsHidden)
    recordsHidden(q).hiddenErasure = mod(q,2)==0;
    recordsHidden(q).hiddenReceiverGeneration = 100+q;
end
Bhidden = tcnsAckFreeReceiverBelief( ...
    initial,recordsHidden,0.22,0.22,cfg);
assert(isequaln(B,Bhidden), ...
    'AckFreeBelief: simulator-private annotations changed the PMF.');

% A sequence/generation disagreement would violate the implemented
% newest-generation receiver rule and must be rejected.
invalid = records;
invalid(3).genTime = 0.04;
rejected = false;
try
    tcnsAckFreeReceiverBelief(initial,invalid,0.22,0.22,cfg);
catch err
    rejected = strcmp(err.identifier, ...
        'tcnsAckFreeReceiverBelief:HistoryOrder');
end
assert(rejected, ...
    'AckFreeBelief: an inconsistent packet history was admitted.');

% Matched-simulator support test: no policy action reads the belief. Run a
% short passive P10 trace in each authorized scenario and reconstruct only
% the sender-visible attempted packet history.
supportChecks = 0;
minTrueProbability = 1;
for scenarioId = ["S2" "S6"]
    [cfgRun,~] = tcnsGate6Scenario(27020001,char(scenarioId));
    cfgRun.swarm.T = 2;
    cfgRun.net.commPeriod = 0.10;
    cfgRun.tcns.logReceiverState = true;
    cfgRun.tcns.logPeriodicSenderFire = true;
    out = simSwarmNetworkQueued(cfgRun);
    for i = 2:cfgRun.swarm.N
        for j = 1:cfgRun.swarm.N
            if ~cfgRun.swarm.A(i,j), continue; end
            linkInitial = localPacket(0,0,0, ...
                reshape(out.P(1,j,:),1,3));
            history = records([]);
            seq = 0;
            for k = 1:numel(out.t)
                if out.periodicSenderFireLog(k,j)
                    seq = seq+1;
                    payload = localPacket(seq,out.t(k),out.t(k), ...
                        reshape(out.P(k,j,:),1,3));
                    payload.vel = reshape(out.V(k,j,:),1,3);
                    history(end+1,1) = payload; %#ok<AGROW>
                end
                belief = tcnsAckFreeReceiverBelief( ...
                    linkInitial,history,out.t(k),out.t(k),cfgRun);
                realized = out.receiverNeighborGenTime(k,i,j);
                idx = find(abs(belief.candidateGenTime-realized)<1e-12,1);
                assert(~isempty(idx) && belief.probability(idx)>0, ...
                    ['AckFreeBelief: realized receiver state left positive ' ...
                     'support under the matched simulator.']);
                minTrueProbability = min( ...
                    minTrueProbability,belief.probability(idx));
                supportChecks = supportChecks+1;
            end
        end
    end
end

assert(B.exactWithinCommunicationFiltration && ...
    ~B.conditionsOnPlantObservationHistory && ~B.usesAck && ...
    ~B.usesReceiverState && ~B.usesRealizedChannelOutcome && ...
    ~B.usesFutureInformation, ...
    'AckFreeBelief: information-scope metadata is invalid.');

fprintf('  P[initial, seq1, seq2]                   [%.2f %.2f %.2f]\n', ...
    B.probability);
fprintf('  matched simulator support checks        %d\n',supportChecks);
fprintf('  minimum realized-state support mass     %.3g\n',minTrueProbability);
fprintf('  hidden-realization invariance            PASS\n');
fprintf('test_tcns_ack_free_receiver_belief: PASS\n');


function packet = localPacket(seq,sendTime,genTime,pos)

packet = struct('seq',seq,'sendTime',sendTime,'genTime',genTime, ...
    'pos',pos,'vel',[0 0 0],'acc',[NaN NaN NaN]);

end


function probability = localExhaustiveNewest(n,lossProbability)

probability = zeros(n+1,1);
for mask = 0:(2^n-1)
    success = logical(bitget(mask,1:n));
    weight = prod((1-lossProbability).^success.* ...
        lossProbability.^(~success));
    newest = find(success,1,'last');
    if isempty(newest), newest = 0; end
    probability(newest+1) = probability(newest+1)+weight;
end

end
