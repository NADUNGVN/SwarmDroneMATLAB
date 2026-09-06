%% TEST_MAC_AWARE_POLICY Deterministic contract checks for EXP14C v2.

startup;

fprintf('\n============================================================\n');
fprintf('test_mac_aware_policy\n');
fprintf('============================================================\n\n');

checks=cell(0,2);


%% Closed configuration and feedback interfaces

c=localCfg('adaptive','csma');
a=macAwarePolicyConfig(c);
checks(end+1,:)={a.csmaMinAckDelay==0.10 && ...
    a.alohaMinAckDelay==0.02 && a.maxAckDeferral==0.50 && ...
    a.ackForceBusyCeiling>=a.ackBusyCeiling, ...
    'MAC-aware defaults reproduce the frozen EXP14C contract'};
checks(end+1,:)={strcmp(sharedMediumFeedbackMode(c),'adaptive'), ...
    'adaptive is an explicit feedback enum'};

bad=c; bad.shared.macAware.ackBusyCeiling=0.95;
bad.shared.macAware.ackForceBusyCeiling=0.80;
rejected=false;
try
    macAwarePolicyConfig(bad);
catch
    rejected=true;
end
checks(end+1,:)={rejected, ...
    'invalid ordinary/forced busy ceilings fail at the boundary'};


%% Branch-aware causal load guard

[hard,ih]=macAwareLoadGuard(true,1,1,3,c);
[fresh,ifresh]=macAwareLoadGuard(true,3,0.90,0,c);
[queued,iq]=macAwareLoadGuard(true,3,0.10,1,c);
[refresh,ir]=macAwareLoadGuard(true,4,0.70,0,c);
[recovery,im]=macAwareLoadGuard(true,5,1,3,c);
checks(end+1,:)={hard && recovery && ih.protectedBranch && ...
    im.protectedBranch,'hard innovation and max-silence remain protected'};
checks(end+1,:)={~fresh && ifresh.blockedByBusy && ...
    ~queued && iq.blockedByQueue && ~refresh && ir.blockedByBusy, ...
    'adaptive-new and refresh branches obey local busy/queue guards'};

off=c; off.shared.macAware.loadGuardEnabled=false;
checks(end+1,:)={macAwareLoadGuard(true,4,1,3,off), ...
    'disabled load guard is behaviorally inert'};


%% Adaptive standalone ACK timing and busy decision

A=[0 1;1 0];
n=initSharedMediumState(c,A);
n=enqueueAckSummary(n,2,localAck(2,1,1,0),0,c);
checks(end+1,:)={abs(n.pendingAckDue(2)-0.10)<1e-12 && ...
    n.pendingAckSince(2)==0, ...
    'CSMA adaptive feedback waits for the piggyback-first delay'};
[allowEarly,dueEarly]=adaptiveStandaloneAckDecision(n,2,0.02,c);
[allowLow,~,lowInfo]=adaptiveStandaloneAckDecision(n,2,0.10,c);
checks(end+1,:)={~allowEarly && abs(dueEarly-0.10)<1e-12 && ...
    allowLow && ~lowInfo.forced, ...
    'low-busy CSMA ACK is admitted exactly after its minimum delay'};

n.localBusyEWMA(2)=0.80;
[allowBusy,dueBusy]=adaptiveStandaloneAckDecision(n,2,0.10,c);
[allowForced,~,forcedInfo]=adaptiveStandaloneAckDecision(n,2,0.50,c);
checks(end+1,:)={~allowBusy && abs(dueBusy-0.12)<1e-12 && ...
    allowForced && forcedInfo.forced, ...
    'busy ACK defers and then uses the bounded max-deferral recovery rule'};
n.localBusyEWMA(2)=0.95;
[allowOver,dueOver]=adaptiveStandaloneAckDecision(n,2,0.50,c);
checks(end+1,:)={~allowOver && abs(dueOver-0.52)<1e-12, ...
    'hard busy ceiling prevents a recovery ACK from worsening overload'};

ca=localCfg('adaptive','aloha');
na=initSharedMediumState(ca,A);
na=enqueueAckSummary(na,2,localAck(2,1,1,0),0,ca);
[allowAloha,~,alohaInfo]=adaptiveStandaloneAckDecision(na,2,0.02,ca);
checks(end+1,:)={abs(na.pendingAckDue(2)-0.02)<1e-12 && ...
    allowAloha && alohaInfo.minimumDelay==0.02, ...
    'ALOHA retains the short standalone-confirmation path'};


%% Piggyback and pending-age state remain atomic

np=initSharedMediumState(c,A);
[np,admitted]=enqueueBroadcastState(np,2,[0 0 0],[0 0 0],0,c);
np=enqueueAckSummary(np,2,localAck(2,1,1,0),0,c);
q=np.queues{2};
checks(end+1,:)={admitted && numel(q(end).ackEntries)==1 && ...
    isempty(np.pendingAck{2}) && isinf(np.pendingAckDue(2)) && ...
    isinf(np.pendingAckSince(2)), ...
    'piggyback clears pending entries, due time and obligation age atomically'};


%% Carrier-sensed busy estimator is causal and active

idle=localCfg('hybrid','csma'); idle.mac.pAccess=0;
ni=initSharedMediumState(idle,A);
ti=generateSharedMediumTrace(idle);
ni=advanceSharedMedium(ni,0,0.02,idle,ti);
busy=idle; busy.mac.backgroundLoad=1;
nb=initSharedMediumState(busy,A);
tb=generateSharedMediumTrace(busy);
nb=advanceSharedMedium(nb,0,0.02,busy,tb);
checks(end+1,:)={all(ni.localBusyEWMA==0) && ...
    all(nb.localBusyEWMA>0 & nb.localBusyEWMA<1), ...
    'local busy EWMA responds to sensed occupancy without frame outcomes'};


%% End-to-end method boundary and access scaling

rejectLegacy=false;
try
    x=study2Exp14Config(16016001,'moderate');
    x.swarm.T=0.1; x.shared.feedbackMode='adaptive';
    simSwarmSharedMedium(x,'causal-broadcast');
catch
    rejectLegacy=true;
end
rejectV2=false;
try
    x=study2Exp14Config(16016001,'moderate');
    x.swarm.T=0.1; x.shared.feedbackMode='hybrid';
    simSwarmSharedMedium(x,'mac-aware-broadcast');
catch
    rejectV2=true;
end
checks(end+1,:)={rejectLegacy && rejectV2, ...
    'legacy and MAC-aware methods reject each other''s feedback contract'};

x=applyExp14OODPoint('n10-ring2',16016001);
x.swarm.T=0.4; x.shared.evalStart=0;
x.shared.feedbackMode='adaptive';
o=simSwarmSharedMedium(x,'mac-aware-broadcast');
m=computeSharedMediumMetrics(o,x);
checks(end+1,:)={abs(o.pAccess-0.10)<1e-12 && ...
    all(isfinite(o.P(:))) && o.invariantViolations==0 && ...
    isfinite(m.meanLocalBusyEstimate) && m.meanLocalBusyEstimate>=0 && ...
    m.meanLocalBusyEstimate<=1, ...
    'N10 v2 scales access to 1/N and runs with finite causal state'};


%% Verdict

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_mac_aware_policy: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_mac_aware_policy: PASS (%d checks)\n',numel(flags));


function cfg=localCfg(mode,macType)

cfg.swarm.N=2;
cfg.swarm.A=[0 1;1 0];
cfg.swarm.T=0.6;
cfg.net.seed=16016999;
cfg.mac.type=macType;
cfg.mac.slotTime=0.001;
cfg.mac.queueCapacity=4;
cfg.mac.dataBytes=96;
cfg.mac.ackBaseBytes=16;
cfg.mac.ackEntryBytes=8;
cfg.mac.phyRateBps=250e3;
cfg.mac.ackDeadline=0.02;
cfg.mac.pAccess=0.2;
cfg.mac.historySize=32;
cfg.mac.residualLoss=0;
cfg.mac.backgroundLoad=0;
cfg.shared.feedbackMode=mode;

end


function a=localAck(source,target,seq,genTime)

a=struct('sourceReceiver',source,'targetSender',target, ...
    'seq',seq,'genTime',genTime);

end
