%% TEST_EXP13_POLICY_CONTRACTS Deterministic EXP13 API and mechanism checks.

startup;

fprintf('\n============================================================\n');
fprintf('test_exp13_policy_contracts\n');
fprintf('============================================================\n\n');

checks = cell(0,2);


%% Closed feedback modes

c = study2SharedMediumConfig();
c.swarm.T = 0.10;
c.shared.feedbackMode = 'standalone';
checks(end+1,:) = {strcmp(sharedMediumFeedbackMode(c),'standalone'), ...
    'standalone feedback mode is explicit'};

c.shared.feedbackMode = 'piggyback';
checks(end+1,:) = {strcmp(sharedMediumFeedbackMode(c),'piggyback'), ...
    'piggyback feedback mode is explicit'};

c.shared.feedbackMode = 'not-a-mode';
badModeRejected = false;
try
    sharedMediumFeedbackMode(c);
catch
    badModeRejected = true;
end
checks(end+1,:) = {badModeRejected, ...
    'unknown feedback modes fail at the boundary'};


%% Standalone and piggyback semantics

A = false(2); A(2,1)=true; A(1,2)=true;
cs = localCfg(A,'standalone');
ns = initSharedMediumState(cs,A);
ns = enqueueAckSummary(ns,2,localAck(2,1,1,0),0,cs);
[ns,~] = enqueueBroadcastState(ns,2,[0 1 0],[0 0 0],0.001,cs);
checks(end+1,:) = {~isempty(ns.pendingAck{2}) && ...
    isempty(ns.queues{2}(1).ackEntries), ...
    'standalone-only never attaches pending ACKs to DATA'};

cp = localCfg(A,'piggyback');
np = initSharedMediumState(cp,A);
np = enqueueAckSummary(np,2,localAck(2,1,1,0),0,cp);
checks(end+1,:) = {isinf(np.pendingAckDue(2)), ...
    'piggyback-only never schedules a standalone deadline'};
[np,~] = enqueueBroadcastState(np,2,[0 1 0],[0 0 0],0.001,cp);
checks(end+1,:) = {isempty(np.pendingAck{2}) && ...
    isscalar(np.queues{2}(1).ackEntries), ...
    'piggyback-only attaches the obligation to the next DATA'};


%% One logical generation becomes separate unicast frames

Au = false(4); Au(2:4,1)=true;
cu = localCfg(Au,'standalone');
nu = initSharedMediumState(cu,Au);
[nu,nAdmit,seq] = enqueueUnicastState( ...
    nu,1,[1 2 3],[0 0 0],0,cu);
masks = vertcat(nu.queues{1}.dataReceiverMask);
checks(end+1,:) = {nAdmit==3 && seq==1 && size(masks,1)==3 && ...
    all(sum(masks,2)==1) && nu.stats.dataFramesGenerated==3, ...
    'unicast ablation materializes one physical frame per receiver'};
checks(end+1,:) = {all([nu.queues{1}.seq]==1), ...
    'unicast frames retain one logical generation sequence'};


%% External background occupancy

cb0 = localCfg(A,'standalone');
cb0.mac.type='tdma'; cb0.mac.backgroundLoad=0;
nb0 = initSharedMediumState(cb0,A);
nb0 = enqueueBroadcastState(nb0,1,[1 0 0],[0 0 0],0,cb0);
[nb0,~] = advanceSharedMedium( ...
    nb0,0,0.004,cb0,generateSharedMediumTrace(cb0));
checks(end+1,:) = {nb0.stats.backgroundBusyTime==0 && ...
    nb0.stats.dataRecipientSuccess==1, ...
    'zero background load is inert'};

cb1 = cb0; cb1.mac.backgroundLoad=1;
nb1 = initSharedMediumState(cb1,A);
nb1 = enqueueBroadcastState(nb1,1,[1 0 0],[0 0 0],0,cb1);
[nb1,~] = advanceSharedMedium( ...
    nb1,0,0.004,cb1,generateSharedMediumTrace(cb1));
checks(end+1,:) = {nb1.stats.backgroundBusyTime>0 && ...
    nb1.stats.dataFramesAttempted==0, ...
    'full external occupancy blocks carrier-sensing service'};


%% Baseline policy boundaries

c = study2SharedMediumConfig();
[sendAoI,ia] = causalAoIOnlyBroadcastPolicy([0.2 0.1],0.2,c);
[sendAoCI,ic] = causalAoCIBroadcastPolicy( ...
    [0.1 0 0],[0 0 0],[0 0 0],[0 0 0],[0.2 0.1],0.2,c);
[sendBelief,ib] = delayedAckBeliefBroadcastPolicy([0.2 0.1],0.2,c);
checks(end+1,:) = {sendAoI && ia.ageDue, ...
    'AoI-only baseline responds to confirmed age without state input'};
checks(end+1,:) = {sendAoCI && ic.scoreDue && ic.innovation>0, ...
    'AoCI-inspired baseline responds to age-times-change score'};
checks(end+1,:) = {sendBelief && ib.beliefDue, ...
    'delayed-ACK belief baseline responds to expected age'};


%% End-to-end method enum, feedback contract and CRN

methods = {'causal-aoi-only','causal-aoci', ...
    'delayed-ack-belief','causal-broadcast','causal-unicast'};
hashes = zeros(numel(methods),1);
methodChecks = cell(numel(methods),2);
for k = 1:numel(methods)
    c = study2SharedMediumConfig();
    c.swarm.T = 0.6;
    c.shared.evalStart = 0.2;
    c.net.seed = 13013999;
    if strcmp(methods{k},'causal-unicast')
        c.shared.feedbackMode = 'standalone';
    end
    o = simSwarmSharedMedium(c,methods{k});
    hashes(k) = o.traceHashExact;
    methodChecks(k,:) = {all(isfinite(o.P(:))) && ...
        o.invariantViolations==0, ...
        sprintf('%s runs end-to-end with finite causal state',methods{k})};
end
checks = [checks; methodChecks];
checks(end+1,:) = {isscalar(unique(hashes)), ...
    'all EXP13 causal methods consume the paired absolute MAC trace'};

c = study2SharedMediumConfig();
c.swarm.T=0.1;
unicastModeRejected = false;
try
    simSwarmSharedMedium(c,'causal-unicast');
catch
    unicastModeRejected = true;
end
checks(end+1,:) = {unicastModeRejected, ...
    'causal-unicast rejects hybrid feedback instead of silently changing it'};

[lhs,strata] = deterministicLatinHypercube(12,9,13013000);
lhsOk = all(sort(strata,1)==repmat((1:12)',1,9),'all') && ...
    all(lhs(:)>0 & lhs(:)<1);
checks(end+1,:) = {lhsOk, ...
    'deterministic LHS occupies every stratum once per parameter'};


%% Verdict

flags = cellfun(@logical,checks(:,1));
for k = 1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp13_policy_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp13_policy_contracts: PASS (%d checks)\n',numel(flags));


function cfg = localCfg(A,mode)

cfg.swarm.N=size(A,1); cfg.swarm.A=A; cfg.swarm.T=0.1;
cfg.net.seed=13013998;
cfg.mac.type='csma'; cfg.mac.slotTime=0.001;
cfg.mac.queueCapacity=4; cfg.mac.dataBytes=10;
cfg.mac.ackBaseBytes=8; cfg.mac.ackEntryBytes=4;
cfg.mac.phyRateBps=80000; cfg.mac.ackDeadline=0.002;
cfg.mac.pAccess=1; cfg.mac.historySize=8;
cfg.mac.residualLoss=0; cfg.mac.backgroundLoad=0;
cfg.shared.feedbackMode=mode;
cfg.shared.feedbackEnabled=~strcmp(mode,'none');

end


function a = localAck(source,target,seq,genTime)

a = struct('sourceReceiver',source,'targetSender',target, ...
    'seq',seq,'genTime',genTime);

end
