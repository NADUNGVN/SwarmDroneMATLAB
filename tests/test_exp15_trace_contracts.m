%% TEST_EXP15_TRACE_CONTRACTS Measured absolute-time replay boundary.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp15_trace_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

cfg=study2SharedMediumConfig();
cfg.swarm.T=0.30;
cfg.shared.evalStart=0;
cfg.mac.type='tdma';
cfg.mac=sharedMediumConfig(cfg);
M=validMeasurement(cfg,0.25,0.40,false);
t1=buildMeasuredSharedMediumTrace(cfg,M,15015001);
t2=buildMeasuredSharedMediumTrace(cfg,M,15015001);
r=validateMeasuredSharedMediumTrace(t1,cfg);
checks(end+1,:)={r.valid && ...
    strcmp(r.schemaVersion,'MEASURED-SHARED-MEDIUM-v1') && ...
    t1.hashExact==t2.hashExact && ...
    isequal(t1.lossU,t2.lossU) && isequal(t1.ackLossU,t2.ackLossU), ...
    'same measurement and replay seed are bit-identical'};

t3=buildMeasuredSharedMediumTrace(cfg,M,15015002);
checks(end+1,:)={t1.measurementHash==t3.measurementHash && ...
    t1.hashExact~=t3.hashExact, ...
    'measurement identity is separate from replay randomization'};

% DATA loss probability overrides the configured generated channel.
lossAll=validMeasurement(cfg,1,0,false);
traceLoss=buildMeasuredSharedMediumTrace(cfg,lossAll,15015003);
outLoss=simSwarmSharedMedium(cfg,'periodic',traceLoss);
mLoss=computeSharedMediumMetrics(outLoss,cfg);
goodAll=validMeasurement(cfg,0,0,false);
traceGood=buildMeasuredSharedMediumTrace(cfg,goodAll,15015003);
outGood=simSwarmSharedMedium(cfg,'periodic',traceGood);
mGood=computeSharedMediumMetrics(outGood,cfg);
checks(end+1,:)={mLoss.dataRecipientAttempts>0 && ...
    mLoss.dataRecipientSuccess==0 && ...
    mLoss.dataRecipientLoss==mLoss.dataRecipientAttempts && ...
    mGood.dataRecipientSuccess>0, ...
    'absolute measured DATA probabilities drive attempted receptions'};

% Standalone ACK uses the reverse tensor.
ackLoss=validMeasurement(cfg,0,1,false);
traceAckLoss=buildMeasuredSharedMediumTrace(cfg,ackLoss,15015004);
cfgStandalone=cfg;
cfgStandalone.shared.feedbackMode='standalone';
outAckLoss=simSwarmSharedMedium(cfgStandalone,'causal-broadcast',traceAckLoss);
mAckLoss=computeSharedMediumMetrics(outAckLoss,cfgStandalone);
checks(end+1,:)={mAckLoss.ackRecipientAttempts>0 && ...
    mAckLoss.ackRecipientSuccess==0 && ...
    mAckLoss.ackRecipientLoss==mAckLoss.ackRecipientAttempts, ...
    'standalone ACK uses the measured reverse probability tensor'};

% Piggyback feedback remains on the DATA physical path.
cfgPiggy=cfg;
cfgPiggy.shared.feedbackMode='piggyback';
outPiggy=simSwarmSharedMedium(cfgPiggy,'causal-broadcast',traceAckLoss);
mPiggy=computeSharedMediumMetrics(outPiggy,cfgPiggy);
checks(end+1,:)={mPiggy.ackFramesAttempted==0 && ...
    mPiggy.ackEntriesPiggybacked>0 && mPiggy.ackEntriesDelivered>0, ...
    'piggyback ignores standalone-ACK loss and follows its DATA frame'};

% Measured external occupancy overrides scalar backgroundLoad.
cfgBusy=cfg;
cfgBusy.mac.type='csma';
cfgBusy.mac.backgroundLoad=0;
cfgBusy.mac=sharedMediumConfig(cfgBusy);
busyAll=validMeasurement(cfgBusy,0,0,true);
traceBusy=buildMeasuredSharedMediumTrace(cfgBusy,busyAll,15015005);
outBusy=simSwarmSharedMedium(cfgBusy,'periodic',traceBusy);
mBusy=computeSharedMediumMetrics(outBusy,cfgBusy);
checks(end+1,:)={mBusy.dataFramesAttempted==0 && ...
    mBusy.backgroundBusyTime>=cfgBusy.swarm.T-2*cfgBusy.mac.slotTime, ...
    'measured external occupancy blocks CSMA independently of config load'};

% Generated traces remain on the original branch and are reproducible.
legacy=generateSharedMediumTrace(cfg);
legacyA=simSwarmSharedMedium(cfg,'periodic',legacy);
legacyB=simSwarmSharedMedium(cfg,'periodic',legacy);
checks(end+1,:)={~isfield(legacy,'sourceMode') && ...
    isequaln(legacyA.P,legacyB.P) && ...
    legacyA.traceHashExact==legacyB.traceHashExact, ...
    'legacy generated-trace behavior remains additive and unchanged'};

badProbability=false;
try
    X=M; X.dataLossProbability(2,1,2)=1.1;
    buildMeasuredSharedMediumTrace(cfg,X,15015006);
catch err
    badProbability=strcmp(err.identifier,'measuredTrace:InvalidProbability');
end
checks(end+1,:)={badProbability, ...
    'out-of-range probability fails with the stable validation identifier'};

badGrid=false;
try
    X=M; X.timeSec(3)=X.timeSec(3)+0.25*X.slotTime;
    buildMeasuredSharedMediumTrace(cfg,X,15015006);
catch err
    badGrid=strcmp(err.identifier,'measuredTrace:InvalidTimeGrid');
end
checks(end+1,:)={badGrid,'nonuniform absolute time grid fails at the boundary'};

badDiagonal=false;
try
    X=M; X.ackLossProbability(1,2,2)=0.5;
    buildMeasuredSharedMediumTrace(cfg,X,15015006);
catch err
    badDiagonal=strcmp(err.identifier,'measuredTrace:NonzeroDiagonal');
end
checks(end+1,:)={badDiagonal,'nonzero self-link measurements are rejected'};

badHash=false;
try
    X=t1; X.measuredDataLossProbability(2,1,2)=0.9;
    validateMeasuredSharedMediumTrace(X,cfg);
catch err
    badHash=strcmp(err.identifier,'measuredTrace:HashMismatch');
end
checks(end+1,:)={badHash,'post-build semantic mutation is caught by the hash'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp15_trace_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp15_trace_contracts: PASS (%d checks)\n',numel(flags));


function M=validMeasurement(cfg,pData,pAck,busy)

mac=sharedMediumConfig(cfg);
K=ceil(cfg.swarm.T/mac.slotTime)+2;
N=cfg.swarm.N;
M=struct();
M.schemaVersion='MEASURED-SHARED-MEDIUM-v1';
M.sourceId='synthetic-contract-test';
M.slotTime=mac.slotTime;
M.N=N;
M.timeSec=(0:K-1)'*mac.slotTime;
M.dataLossProbability=repmat(pData,K,N,N);
M.ackLossProbability=repmat(pAck,K,N,N);
M.dataBadState=M.dataLossProbability>=0.5;
M.ackBadState=M.ackLossProbability>=0.5;
M.backgroundActive=repmat(logical(busy),K,1);
for n=1:N
    M.dataLossProbability(:,n,n)=0;
    M.ackLossProbability(:,n,n)=0;
    M.dataBadState(:,n,n)=false;
    M.ackBadState(:,n,n)=false;
end

end
