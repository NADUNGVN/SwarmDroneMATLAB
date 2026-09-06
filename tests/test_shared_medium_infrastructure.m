%% TEST_SHARED_MEDIUM_INFRASTRUCTURE Deterministic EXP12 protocol/MAC gates.

startup;

fprintf('\n============================================================\n');
fprintf('test_shared_medium_infrastructure\n');
fprintf('============================================================\n\n');

checks = cell(0,2);


%% 1. One frame serves three receivers

A = false(4); A(2:4,1) = true;
c = localCfg(4,A,'csma');
n = initSharedMediumState(c,A);
[n,ok] = enqueueBroadcastState(n,1,[1 2 3],[0 0 0],0,c);
tr = generateSharedMediumTrace(c);
[n,e] = advanceSharedMedium(n,0,0.002,c,tr);

checks(end+1,:) = {ok && numel(e)==3 && all([e.success]), ...
    'one broadcast frame reaches all three intended receivers'};
checks(end+1,:) = {n.stats.dataFramesAttempted==1 && ...
    n.stats.recipientSuccess==3, ...
    'frame and recipient accounting remain distinct'};


%% 2. Partial broadcast reception

c2 = c;
c2.mac.residualLoss = zeros(4); c2.mac.residualLoss(3,1)=1;
n2 = initSharedMediumState(c2,A);
n2 = enqueueBroadcastState(n2,1,[1 2 3],[0 0 0],0,c2);
[n2,e2] = advanceSharedMedium(n2,0,0.002,c2,generateSharedMediumTrace(c2));
successReceivers = [e2([e2.success]).receiver];
checks(end+1,:) = {isequal(successReceivers,[2 4]) && ...
    n2.stats.recipientLoss==1, ...
    'one broadcast can succeed at a strict subset of receivers'};


%% 3. Collision at a common receiver

Ac = false(3); Ac(3,1)=true; Ac(3,2)=true;
cc = localCfg(3,Ac,'csma');
nc = initSharedMediumState(cc,Ac);
nc = enqueueBroadcastState(nc,1,[1 0 0],[0 0 0],0,cc);
nc = enqueueBroadcastState(nc,2,[2 0 0],[0 0 0],0,cc);
[nc,ec] = advanceSharedMedium(nc,0,0.002,cc,generateSharedMediumTrace(cc));
checks(end+1,:) = {numel(ec)==2 && all([ec.collision]) && ...
    ~any([ec.success]) && nc.stats.collisionFrames==2, ...
    'simultaneous senders collide at their shared receiver'};


%% 4. TDMA serialization removes that collision

ct = localCfg(3,Ac,'tdma');
nt = initSharedMediumState(ct,Ac);
nt = enqueueBroadcastState(nt,1,[1 0 0],[0 0 0],0,ct);
nt = enqueueBroadcastState(nt,2,[2 0 0],[0 0 0],0,ct);
[nt,et] = advanceSharedMedium(nt,0,0.003,ct,generateSharedMediumTrace(ct));
checks(end+1,:) = {numel(et)==2 && all([et.success]) && ...
    ~any([et.collision]), ...
    'serialized TDMA service delivers the same two frames without collision'};


%% 5. Latest-generated-wins before service

cq = c; cq.mac.pAccess=0;
nq = initSharedMediumState(cq,A);
nq = enqueueBroadcastState(nq,1,[1 0 0],[0 0 0],0.000,cq);
nq = enqueueBroadcastState(nq,1,[2 0 0],[0 0 0],0.001,cq);
nq = enqueueBroadcastState(nq,1,[3 0 0],[0 0 0],0.002,cq);
checks(end+1,:) = {isscalar(nq.queues{1}) && ...
    nq.queues{1}(1).seq==3 && nq.stats.supersededBeforeService==2, ...
    'queued state DATA uses latest-generated-wins replacement'};


%% 6. Finite queue and ACK priority

cf = c; cf.mac.pAccess=0; cf.mac.queueCapacity=1; cf.mac.ackDeadline=0.001;
nf = initSharedMediumState(cf,A);
ae = localAck(2,1,1,0);
nf = enqueueAckSummary(nf,2,ae,0,cf);
[nf,~] = advanceSharedMedium(nf,0,0.002,cf,generateSharedMediumTrace(cf));
[nf,admitted] = enqueueBroadcastState(nf,2,[0 0 0],[0 0 0],0.002,cf);
checks(end+1,:) = {~admitted && isscalar(nf.queues{2}) && ...
    strcmp(nf.queues{2}(1).type,'ack') && nf.stats.maxQueueDepth<=1, ...
    'finite queue preserves due feedback and rejects lower-priority DATA'};


%% 7. Cumulative ACK merge

nm = initSharedMediumState(c,A);
nm = enqueueAckSummary(nm,2,localAck(2,1,1,0.001),0,c);
nm = enqueueAckSummary(nm,2,localAck(2,1,3,0.003),0.001,c);
checks(end+1,:) = {isscalar(nm.pendingAck{2}) && ...
    nm.pendingAck{2}.seq==3 && nm.pendingAck{2}.genTime==0.003, ...
    'cumulative ACK merge retains only the newest sequence per sender'};


%% 8. Piggyback consumes pending ACK without a standalone frame

np = initSharedMediumState(c,A);
np = enqueueAckSummary(np,2,localAck(2,1,1,0),0,c);
[np,okp] = enqueueBroadcastState(np,2,[0 1 0],[0 0 0],0.001,c);
[np,ep] = advanceSharedMedium( ...
    np,0.001,0.003,c,generateSharedMediumTrace(c));
checks(end+1,:) = {okp && isempty(np.pendingAck{2}) && ...
    isscalar(ep) && ep.ackIntended && ...
    isscalar(ep.ackEntries) && ...
    np.stats.ackEntriesPiggybacked==1 && np.stats.ackFramesStandalone==0, ...
    'a pending ACK summary piggybacks on the next DATA frame'};


%% 8b. DATA supersession preserves an already-piggybacked obligation

nps = initSharedMediumState(c,A);
nps = enqueueAckSummary(nps,2,localAck(2,1,1,0),0,c);
nps = enqueueBroadcastState(nps,2,[0 1 0],[0 0 0],0.001,c);
nps = enqueueBroadcastState(nps,2,[0 2 0],[0 0 0],0.002,c);
checks(end+1,:) = {isscalar(nps.queues{2}) && ...
    nps.queues{2}.seq==2 && isscalar(nps.queues{2}.ackEntries) && ...
    nps.queues{2}.ackEntries.seq==1 && ...
    nps.stats.ackEntriesTransferred==1, ...
    'latest-generated-wins transfers piggyback ACKs to the newer DATA'};


%% 8c. ACK priority preserves piggyback entries from displaced DATA

cpp = c; cpp.mac.queueCapacity=1; cpp.mac.pAccess=0;
npp = initSharedMediumState(cpp,A);
npp = enqueueAckSummary(npp,2,localAck(2,1,1,0),0,cpp);
npp = enqueueBroadcastState(npp,2,[0 1 0],[0 0 0],0.001,cpp);
fa = npp.frameTemplate;
fa.type='ack'; fa.sender=2; fa.ackEntries=localAck(2,3,1,0);
fa.ackReceiverMask(3)=true; fa.receiverMask=fa.ackReceiverMask;
fa.bytes=cpp.mac.ackBaseBytes+cpp.mac.ackEntryBytes;
[npp,app] = sharedMediumAdmitFrame(npp,2,fa);
checks(end+1,:) = {app && isscalar(npp.queues{2}) && ...
    strcmp(npp.queues{2}.type,'ack') && ...
    isequal([npp.queues{2}.ackEntries.targetSender],[1 3]) && ...
    npp.stats.ackEntriesTransferred==1, ...
    'ACK priority transfers feedback from a displaced piggyback DATA frame'};


%% 9. ACK deadline creates one standalone summary

cd = c; cd.mac.pAccess=0; cd.mac.ackDeadline=0.001;
nd = initSharedMediumState(cd,A);
nd = enqueueAckSummary(nd,2,localAck(2,1,1,0),0,cd);
[nd,~] = advanceSharedMedium(nd,0,0.004,cd,generateSharedMediumTrace(cd));
checks(end+1,:) = {isempty(nd.pendingAck{2}) && ...
    isscalar(nd.queues{2}) && strcmp(nd.queues{2}(1).type,'ack') && ...
    nd.stats.ackFramesStandalone==1, ...
    'ACK deadline materializes exactly one standalone cumulative summary'};


%% 10. Dropped DATA creates no ACK obligation

cl = c; cl.mac.residualLoss=1;
nl = initSharedMediumState(cl,A);
nl = enqueueBroadcastState(nl,1,[1 0 0],[0 0 0],0,cl);
[nl,el] = advanceSharedMedium(nl,0,0.002,cl,generateSharedMediumTrace(cl));
nl = applySharedMediumDeliveries(nl,el,0.002,cl);
checks(end+1,:) = {all(cellfun(@isempty,nl.pendingAck)) && ...
    all(nl.acceptedSeq(:)==0), ...
    'a DATA loss neither advances receiver state nor creates an ACK'};


%% 11. Delivered cumulative ACK advances only the named sender belief

ca = localCfg(4,A,'tdma'); ca.mac.ackDeadline=0.001;
na = initSharedMediumState(ca,A);
na = enqueueBroadcastState(na,1,[1 0 0],[0 0 0],0,ca);
tra = generateSharedMediumTrace(ca);
[na,eda] = advanceSharedMedium(na,0,0.002,ca,tra);
na = applySharedMediumDeliveries(na,eda,0.002,ca);
[na,eaa] = advanceSharedMedium(na,0.002,0.014,ca,tra);
na = applySharedMediumDeliveries(na,eaa,0.014,ca);
checks(end+1,:) = {all(na.ackedSeq(2:4,1)==1) && ...
    nnz(na.ackedSeq)==3 && na.stats.ackEntriesDelivered==3, ...
    'delivered ACK summaries advance exactly the confirmed receiver beliefs'};


%% 12. Bounded history under prolonged no-service

cb = c; cb.mac.pAccess=0; cb.mac.historySize=4;
nb = initSharedMediumState(cb,A);
for k = 1:11
    nb = enqueueBroadcastState(nb,1,[k 0 0],[0 0 0],k*0.001,cb);
end
checks(end+1,:) = {nb.historyCount(1)==4 && ...
    nnz(nb.historySeq(1,:))==4 && nb.stats.maxHistoryDepth==4, ...
    'sender history remains bounded during prolonged missing feedback'};


%% 13. Trace determinism

cr = c; trr=generateSharedMediumTrace(cr);
nr1=initSharedMediumState(cr,A); nr2=initSharedMediumState(cr,A);
nr1=enqueueBroadcastState(nr1,1,[1 2 3],[0 0 0],0,cr);
nr2=enqueueBroadcastState(nr2,1,[1 2 3],[0 0 0],0,cr);
[nr1,er1]=advanceSharedMedium(nr1,0,0.002,cr,trr);
[nr2,er2]=advanceSharedMedium(nr2,0,0.002,cr,trr);
checks(end+1,:) = {isequaln(er1,er2) && isequaln(nr1.stats,nr2.stats), ...
    'identical actions on one pre-drawn trace are bit-identical'};


%% 14. Busy-time union is not the sum of colliding frame airtimes

checks(end+1,:) = {abs(nc.stats.busyTime-0.001)<1e-12 && ...
    abs(nc.stats.dataAirtime-0.002)<1e-12, ...
    'busy-time union and offered frame airtime are separately accounted'};


%% 15. Fully-conflicting interference also corrupts disjoint destinations

Ai = false(4); Ai(3,1)=true; Ai(4,2)=true;
ci = localCfg(4,Ai,'csma');
ni = initSharedMediumState(ci,Ai);
ni = enqueueBroadcastState(ni,1,[1 0 0],[0 0 0],0,ci);
ni = enqueueBroadcastState(ni,2,[2 0 0],[0 0 0],0,ci);
[ni,ei] = advanceSharedMedium(ni,0,0.002,ci,generateSharedMediumTrace(ci));
checks(end+1,:) = {numel(ei)==2 && all([ei.collision]) && ...
    ni.stats.collisionFrames==2, ...
    'fully-conflicting interference corrupts disjoint intended receivers'};


%% 16. Sparse interference can serialize those spatially reusable links

cis = ci;
cis.mac.interferenceMatrix = false(4);
nis = initSharedMediumState(cis,Ai);
nis = enqueueBroadcastState(nis,1,[1 0 0],[0 0 0],0,cis);
nis = enqueueBroadcastState(nis,2,[2 0 0],[0 0 0],0,cis);
[nis,eis] = advanceSharedMedium( ...
    nis,0,0.002,cis,generateSharedMediumTrace(cis));
checks(end+1,:) = {numel(eis)==2 && all([eis.success]) && ...
    ~any([eis.collision]), ...
    'a declared sparse interference matrix permits spatial reuse'};


%% 17. Collision retries are bounded and retain frame identities

cir = ci; cir.mac.maxRetries=1;
nir = initSharedMediumState(cir,Ai);
nir = enqueueBroadcastState(nir,1,[1 0 0],[0 0 0],0,cir);
nir = enqueueBroadcastState(nir,2,[2 0 0],[0 0 0],0,cir);
[nir,eir] = advanceSharedMedium( ...
    nir,0,0.003,cir,generateSharedMediumTrace(cir));
checks(end+1,:) = {nir.stats.retryFrames==2 && ...
    nir.stats.dataFramesAttempted==4 && ...
    numel(unique([eir.frameId]))==2 && isempty(nir.active), ...
    'collision retries are bounded and preserve logical frame identity'};


%% 18. Inline delivery applies DATA and its causal ACK at event time

Ain = false(2); Ain(2,1)=true;
cin = localCfg(2,Ain,'tdma');
cin.mac.ackDeadline=0.001;
cin.mac.applyDeliveriesInline=true;
nin = initSharedMediumState(cin,Ain);
nin = enqueueBroadcastState(nin,1,[7 8 9],[1 2 3],0,cin);
[nin,~] = advanceSharedMedium( ...
    nin,0,0.006,cin,generateSharedMediumTrace(cin));
checks(end+1,:) = {nin.acceptedSeq(2,1)==1 && nin.ackedSeq(2,1)==1 && ...
    isequal(reshape(nin.Pij(2,1,:),1,3),[7 8 9]) && ...
    nin.stats.ackEntriesDelivered==1, ...
    'inline mode applies DATA and causal ACK at their MAC event times'};


%% 19. An ACK older than bounded history is rejected, not trusted

cex = c; cex.mac.pAccess=0; cex.mac.historySize=2;
nex = initSharedMediumState(cex,A);
for q = 1:3
    nex = enqueueBroadcastState(nex,1,[q 0 0],[0 0 0],q*0.001,cex);
end
nex.acceptedSeq(2,1)=1; nex.acceptedGenTime(2,1)=0.001;
ex = nex.eventTemplate;
ex.success=true; ex.ackIntended=true; ex.receiver=1; ex.sender=2;
ex.ackEntries=localAck(2,1,1,0.001);
nex = applySharedMediumDeliveries(nex,ex,0.01,cex);
checks(end+1,:) = {nex.ackedSeq(2,1)==0 && ...
    nex.stats.expiredHistoryAckCount==1, ...
    'an ACK outside bounded history is counted and rejected'};


%% 20. Zero-load ordering is common across all three MAC variants

Az = false(2); Az(2,1)=true;
types = {'csma','aloha','tdma'};
seqs = cell(3,1); successes = false(3,1);
for q = 1:3
    cz = localCfg(2,Az,types{q});
    nz = initSharedMediumState(cz,Az);
    nz = enqueueBroadcastState(nz,1,[1 0 0],[0 0 0],0,cz);
    [~,ez] = advanceSharedMedium(nz,0,0.003,cz,generateSharedMediumTrace(cz));
    seqs{q} = [ez.seq];
    successes(q) = isscalar(ez) && ez.success;
end
checks(end+1,:) = {all(successes) && ...
    isequal(seqs{1},seqs{2}) && isequal(seqs{2},seqs{3}), ...
    'zero-load CSMA, ALOHA and TDMA preserve payload/sequence order'};


%% 21. Hidden terminals are distinct from receiver interference

Ah = false(4); Ah(4,1)=true; Ah(4,3)=true;
ch = localCfg(4,Ah,'csma');
ch.mac.dataBytes=125; ch.mac.phyRateBps=250e3;

nhFull = initSharedMediumState(ch,Ah);
nhFull = enqueueBroadcastState(nhFull,1,[1 0 0],[0 0 0],0,ch);
thFull = generateSharedMediumTrace(ch);
[nhFull,~] = advanceSharedMedium(nhFull,0,0.001,ch,thFull);
nhFull = enqueueBroadcastState(nhFull,3,[3 0 0],[0 0 0],0.001,ch);
[nhFull,ef] = advanceSharedMedium(nhFull,0.001,0.010,ch,thFull);

chHidden = ch;
chHidden.mac.carrierSenseMatrix=true(4);
chHidden.mac.carrierSenseMatrix(3,1)=false;
nhHidden = initSharedMediumState(chHidden,Ah);
nhHidden = enqueueBroadcastState(nhHidden,1,[1 0 0],[0 0 0],0,chHidden);
thHidden = generateSharedMediumTrace(chHidden);
[nhHidden,~] = advanceSharedMedium(nhHidden,0,0.001,chHidden,thHidden);
nhHidden = enqueueBroadcastState( ...
    nhHidden,3,[3 0 0],[0 0 0],0.001,chHidden);
[nhHidden,eh] = advanceSharedMedium( ...
    nhHidden,0.001,0.010,chHidden,thHidden);

checks(end+1,:) = {~any([ef.collision]) && all([ef.success]) && ...
    any([eh.collision]) && nhHidden.stats.collisionFrames==2, ...
    'a nonsensing interferer produces a genuine hidden-terminal collision'};


%% 22. A multi-slot frame at the horizon is right-censored, not lost

At = false(3); At(2,1)=true; At(3,1)=true;
ct = localCfg(3,At,'csma');
ct.mac.dataBytes=125; ct.mac.phyRateBps=250e3;
nt = initSharedMediumState(ct,At);
nt = enqueueBroadcastState(nt,1,[1 0 0],[0 0 0],0,ct);
[nt,et] = advanceSharedMedium( ...
    nt,0,0.001,ct,generateSharedMediumTrace(ct));
terminal = sharedMediumTerminalCounts(nt);
checks(end+1,:) = {isempty(et) && terminal.frames==1 && ...
    terminal.dataRecipientAttempts==2 && ...
    terminal.ackRecipientAttempts==0 && ...
    nt.stats.dataRecipientAttempts==2 && ...
    nt.stats.dataRecipientSuccess==0 && nt.stats.dataRecipientLoss==0, ...
    'terminal multi-slot work is exposed as in-flight rather than synthetic loss'};


%% Verdict

flags = cellfun(@logical,checks(:,1));
for k = 1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end

if ~all(flags)
    error('test_shared_medium_infrastructure: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_shared_medium_infrastructure: PASS (%d checks)\n',numel(flags));


function cfg = localCfg(N,A,type)

cfg.swarm.N = N;
cfg.swarm.A = A;
cfg.swarm.T = 0.1;
cfg.net.seed = 42012001;
cfg.mac.type = type;
cfg.mac.slotTime = 0.001;
cfg.mac.queueCapacity = 4;
cfg.mac.dataBytes = 10;
cfg.mac.ackBaseBytes = 8;
cfg.mac.ackEntryBytes = 4;
cfg.mac.phyRateBps = 80000; % 10 B occupies exactly one 1-ms slot.
cfg.mac.ackDeadline = 0.002;
cfg.mac.pAccess = 1;
cfg.mac.historySize = 8;
cfg.mac.residualLoss = 0;

end


function a = localAck(source,target,seq,genTime)

a = struct('sourceReceiver',source,'targetSender',target, ...
    'seq',seq,'genTime',genTime);

end
