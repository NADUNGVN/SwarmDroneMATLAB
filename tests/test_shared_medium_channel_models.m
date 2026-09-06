%% TEST_SHARED_MEDIUM_CHANNEL_MODELS Deterministic EXP14 channel contracts.

startup;

fprintf('\n============================================================\n');
fprintf('test_shared_medium_channel_models\n');
fprintf('============================================================\n\n');

checks = cell(0,2);


%% 1. Legacy iid behavior and trace hash remain additive

c0 = localCfg();
t0 = generateSharedMediumTrace(c0);
legacyHash = realizationHash([ ...
    t0.accessU(:); t0.lossU(:); t0.backgroundU(:)]);
checks(end+1,:) = {t0.hashExact==legacyHash && ...
    isequal(t0.lossU,t0.ackLossU) && t0.channelStateHash==0, ...
    'legacy iid mode preserves the original trace, ACK draw and hash'};


%% 2. Independent reverse loss cannot corrupt accepted DATA truth

ca = localCfg();
ca.mac.separateAckTrace=true;
ca.mac.dataResidualLoss=0;
ca.mac.ackResidualLoss=1;
na = initSharedMediumState(ca,ca.swarm.A);
na = initializeControl(na,ca);
na = enqueueBroadcastState(na,1,[1 0 0],[0 0 0],0,ca);
[na,~] = advanceSharedMedium( ...
    na,0,0.006,ca,generateSharedMediumTrace(ca));
checks(end+1,:) = {na.acceptedSeq(2,1)==1 && na.ackedSeq(2,1)==0 && ...
    na.stats.ackRecipientLoss>0, ...
    'reverse-only loss preserves DATA reception but blocks confirmation'};

cas = ca; cas.mac.ackResidualLoss=0;
nas = initSharedMediumState(cas,cas.swarm.A);
nas = initializeControl(nas,cas);
nas = enqueueBroadcastState(nas,1,[1 0 0],[0 0 0],0,cas);
[nas,~] = advanceSharedMedium( ...
    nas,0,0.006,cas,generateSharedMediumTrace(cas));
checks(end+1,:) = {nas.acceptedSeq(2,1)==1 && nas.ackedSeq(2,1)==1, ...
    'a reliable independent reverse trace confirms the accepted DATA'};


%% 3. Piggyback ACK follows the enclosing DATA physical channel

cp = localCfg();
cp.swarm.A = logical([0 1;1 0]);
cp.shared.feedbackMode='piggyback';
cp.mac.separateAckTrace=true;
cp.mac.dataResidualLoss=0;
cp.mac.ackResidualLoss=1;
np = initSharedMediumState(cp,cp.swarm.A);
np = initializeControl(np,cp);
np = enqueueBroadcastState(np,1,[1 0 0],[0 0 0],0,cp);
tp = generateSharedMediumTrace(cp);
[np,~] = advanceSharedMedium(np,0,0.002,cp,tp);
np = enqueueBroadcastState(np,2,[2 0 0],[0 0 0],0.002,cp);
[np,~] = advanceSharedMedium(np,0.002,0.006,cp,tp);
checks(end+1,:) = {np.ackedSeq(2,1)==1 && ...
    np.stats.ackFramesAttempted==0 && np.stats.ackEntriesPiggybacked>0, ...
    'piggyback feedback uses DATA loss, not standalone reverse-ACK loss'};


%% 4. Gilbert-Elliott state is absolute, reproducible and exercised

cg = localCfg();
cg.mac.lossModel='gilbert-elliott';
cg.mac.separateAckTrace=true;
cg.mac.burst.dataGoodToBad=0.10;
cg.mac.burst.dataBadToGood=0.10;
cg.mac.burst.ackGoodToBad=0.20;
cg.mac.burst.ackBadToGood=0.05;
tg1 = generateSharedMediumTrace(cg);
tg2 = generateSharedMediumTrace(cg);
linkState = tg1.dataBadState(:,2,1);
checks(end+1,:) = {isequaln(tg1,tg2) && ...
    tg1.channelStateHash~=0 && tg1.dataBadFraction>0 && ...
    tg1.dataBadFraction<1 && any(linkState(1:end-1) & linkState(2:end)), ...
    'Gilbert-Elliott bad-state runs are reproducible and temporally persistent'};

cgAllBad = cg;
cgAllBad.mac.burst.dataGoodToBad=1;
cgAllBad.mac.burst.dataBadToGood=0;
cgAllBad.mac.burst.dataGoodLoss=0;
cgAllBad.mac.burst.dataBadLoss=1;
tBad = generateSharedMediumTrace(cgAllBad);
checks(end+1,:) = {all(tBad.dataBadState(:)) && ...
    tBad.dataBadFraction==1, ...
    'declared absorbing bad state produces an all-bad DATA trace'};


%% 5. Same uniforms pair channel cells; state realizations remain auditable

cg2 = cg;
cg2.mac.burst.dataGoodToBad=0.02;
cg2.mac.burst.dataBadToGood=0.30;
tg3 = generateSharedMediumTrace(cg2);
checks(end+1,:) = {tg1.hashExact==tg3.hashExact && ...
    tg1.channelStateHash~=tg3.channelStateHash, ...
    'channel cells share underlying uniforms but expose distinct state hashes'};


%% 6. Model/trace mismatches and invalid enums fail at the boundary

signatureRejected = false;
try
    nm = initSharedMediumState(cg2,cg2.swarm.A);
    advanceSharedMedium(nm,0,0.001,cg2,tg1);
catch err
    signatureRejected = contains(err.message,'signature');
end
checks(end+1,:) = {signatureRejected, ...
    'a supplied trace from another channel model is rejected'};

bad = c0; bad.mac.lossModel='oracle-magic';
badEnumRejected = false;
try
    sharedMediumConfig(bad);
catch
    badEnumRejected = true;
end
checks(end+1,:) = {badEnumRejected, ...
    'unknown loss-model enums fail validation'};


%% 7. End-to-end burst and reverse asymmetry remain causal

ce = study2SharedMediumConfig();
ce.swarm.T=0.8; ce.shared.evalStart=0.2;
ce.mac.lossModel='gilbert-elliott';
ce.mac.separateAckTrace=true;
ce.mac.burst.dataGoodLoss=0;
ce.mac.burst.dataBadLoss=0.5;
ce.mac.burst.dataGoodToBad=0.02;
ce.mac.burst.dataBadToGood=0.08;
ce.mac.burst.ackGoodLoss=0.2;
ce.mac.burst.ackBadLoss=0.9;
ce.mac.burst.ackGoodToBad=0.05;
ce.mac.burst.ackBadToGood=0.03;
oe = simSwarmSharedMedium(ce,'causal-broadcast');
checks(end+1,:) = {oe.invariantViolations==0 && ...
    oe.channelStateHash~=0 && all(isfinite(oe.P(:))) && ...
    oe.netStats.dataChannelBadStateAttempts>0 && ...
    oe.netStats.ackChannelBadStateAttempts>0, ...
    'burst/asymmetric end-to-end run remains finite and causally conservative'};


%% Verdict

flags = cellfun(@logical,checks(:,1));
for k = 1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_shared_medium_channel_models: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_shared_medium_channel_models: PASS (%d checks)\n',numel(flags));


function cfg = localCfg()

cfg.swarm.N=2;
cfg.swarm.A=logical([0 0;1 0]);
cfg.swarm.pin=zeros(2,1);
cfg.swarm.T=0.1;
cfg.swarm.initialPositions=zeros(2,3);
cfg.swarm.initialVelocities=zeros(2,3);
cfg.net.seed=14014999;
cfg.mac.type='tdma';
cfg.mac.slotTime=0.001;
cfg.mac.queueCapacity=4;
cfg.mac.dataBytes=10;
cfg.mac.ackBaseBytes=8;
cfg.mac.ackEntryBytes=4;
cfg.mac.phyRateBps=80000;
cfg.mac.ackDeadline=0.001;
cfg.mac.pAccess=1;
cfg.mac.historySize=8;
cfg.mac.maxRetries=0;
cfg.mac.residualLoss=0;
cfg.mac.backgroundLoad=0;
cfg.mac.applyDeliveriesInline=true;
cfg.shared.feedbackMode='standalone';
cfg.shared.feedbackEnabled=true;

end


function net = initializeControl(net,cfg)

leader=struct('pos',zeros(3,1),'vel',zeros(3,1),'acc',zeros(3,1));
net=initializeSharedMediumControlState(net, ...
    cfg.swarm.initialPositions,cfg.swarm.initialVelocities,leader,cfg);

end
