%% TEST_SERVICE_SCHEDULER_CONTRACTS Deterministic EXP19 scheduler gates.

startup;
fprintf('\n============================================================\n');
fprintf('test_service_scheduler_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

%% Default is inert and preserves legacy service.
c=localCfg(3);
native=serviceSchedulerConfig(c);
checks(end+1,:)={strcmp(native.mode,'native') && ~native.enabled && ...
    ~native.oracle,'default scheduler is inert'};

%% Deficit max-weight selects accumulated semantic deficit over FIFO.
c.shared.serviceScheduler=struct('mode','deficit-maxweight');
n=initSharedMediumState(c,c.swarm.A);
n=enqueueBroadcastState(n,1,[0.1 0 0],[0 0 0],0,c);
n=enqueueBroadcastState(n,2,[1 0 0],[0 0 0],0.001,c);
n=enqueueBroadcastState(n,2,[2 0 0],[0 0 0],0.002,c);
n=enqueueBroadcastState(n,2,[3 0 0],[0 0 0],0.003,c);
[n,~]=advanceSharedMedium(n,0.003,0.005,c,generateSharedMediumTrace(c));
d=n.logs.serviceDecisions(1);
checks(end+1,:)={d.selectedNode==2 && d.fifoNode==1 && ...
    d.differsFromFifo && d.weights(d.eligibleNodes==2)> ...
    d.weights(d.eligibleNodes==1), ...
    'deficit max-weight acts on virtual demand and differs from FIFO'};
checks(end+1,:)={sum(n.serviceScheduler.admitted)==4 && ...
    sum(n.serviceScheduler.completed)==2 && ...
    sum(n.serviceScheduler.virtualDeficit)==2, ...
    'virtual deficit equals admissions minus successful service'};

%% Urgency oracle reads present receiver truth and selects innovation.
u=localCfg(3);
u.shared.serviceScheduler=struct('mode','urgency-maxweight');
nu=initSharedMediumState(u,u.swarm.A);
nu=enqueueBroadcastState(nu,1,[0.01 0 0],[0 0 0],0, u);
nu=enqueueBroadcastState(nu,2,[2.00 0 0],[0 0 0],0.001,u);
[nu,~]=advanceSharedMedium(nu,0.001,0.002,u,generateSharedMediumTrace(u));
du=nu.logs.serviceDecisions(1);
checks(end+1,:)={du.selectedNode==2 && du.fifoNode==1 && ...
    nu.serviceScheduler.receiverTruthReadCount==2 && ...
    nu.serviceScheduler.futureRandomReadCount==0 && ...
    ~du.futureRandomRead, ...
    'urgency max-weight uses present receiver state and no future draw'};

%% Round-robin cursor remains fair for four-slot frames at N=10.
r=localCfg(10);
r.mac.dataBytes=96;
r.mac.phyRateBps=250e3;
r.shared.serviceScheduler=struct('mode','round-robin');
nr=initSharedMediumState(r,r.swarm.A);
for sender=1:10
    nr=enqueueBroadcastState(nr,sender,[sender 0 0],[0 0 0],0,r);
end
[nr,~]=advanceSharedMedium(nr,0,0.060,r,generateSharedMediumTrace(r));
selected=[nr.logs.serviceDecisions.selectedNode];
checks(end+1,:)={numel(selected)>=10 && isequal(selected(1:10),1:10), ...
    'round-robin cursor serves all N=10 nodes despite four-slot frames'};
checks(end+1,:)={nr.stats.collisionFrames==0 && ...
    nr.stats.ackFramesStandalone==0, ...
    'scheduled piggyback service is collision-free without standalone ACK'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_service_scheduler_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_service_scheduler_contracts: PASS (%d checks)\n',numel(flags));


function cfg=localCfg(N)

cfg.swarm.N=N;
cfg.swarm.A=false(N);
for sender=1:N
    cfg.swarm.A(mod(sender,N)+1,sender)=true;
end
cfg.swarm.T=0.1;
cfg.net.seed=16025999;
cfg.mac.type='tdma';
cfg.mac.slotTime=0.001;
cfg.mac.queueCapacity=4;
cfg.mac.dataBytes=10;
cfg.mac.ackBaseBytes=8;
cfg.mac.ackEntryBytes=4;
cfg.mac.phyRateBps=80000;
cfg.mac.ackDeadline=0.002;
cfg.mac.pAccess=1;
cfg.mac.historySize=16;
cfg.mac.residualLoss=0;
cfg.aoiEvent=struct('posThreshold',0.05,'velThreshold',0.10, ...
    'aoiThreshold',0.12,'maxSilence',0.50);
cfg.shared.feedbackMode='piggyback';

end
