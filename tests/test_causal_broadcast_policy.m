%% TEST_CAUSAL_BROADCAST_POLICY Unit gates for Causal-Broadcast-v1.

startup;

fprintf('\n============================================================\n');
fprintf('test_causal_broadcast_policy\n');
fprintf('============================================================\n\n');

cfg = defaultConfig();
cfg.aoiEvent.posThreshold      = 0.05;
cfg.aoiEvent.velThreshold      = 0.10;
cfg.aoiEvent.aoiThreshold      = 0.12;
cfg.aoiEvent.maxSilence        = 0.50;
cfg.aoiEvent.minInterTx        = 0.02;
cfg.aoiEvent.aoiMinInterTx     = 0.10;
cfg.aoiEvent.aoiStateScaleBase = 0.50;
cfg.aoiEvent.aoiStateScaleMin  = 0.20;
cfg.aoiEvent.aoiAdaptRange     = 1.00;

p0=[0 0 0]; v0=[0 0 0];
checks=cell(0,2);

% A single receiver must be exactly the frozen v3 decision.
[s1,b1] = causalBroadcastTriggerPolicy( ...
    [0.03 0 0],v0,p0,v0,0.20,false,0.20,cfg);
[s2,b2] = causalInnovationTriggerPolicy( ...
    [0.03 0 0],v0,p0,v0,0.20,0.20,0,cfg);
checks(end+1,:)={s1==s2 && b1==b2, ...
    'one-receiver Causal-Broadcast is decision-equivalent to Causal-v3'};

% Receiver ordering cannot change a broadcast decision.
[sa,ba,ia] = causalBroadcastTriggerPolicy( ...
    [0.03 0 0],v0,p0,v0,[0.05 0.25 0.10],[0 1 0],0.20,cfg);
[sb,bb,ib] = causalBroadcastTriggerPolicy( ...
    [0.03 0 0],v0,p0,v0,[0.10 0.05 0.25],[0 0 1],0.20,cfg);
checks(end+1,:)={sa==sb && ba==bb && ...
    ia.worstEstimatedAge==ib.worstEstimatedAge, ...
    'receiver permutation leaves the aggregate decision invariant'};

% A stale receiver sharpens the threshold enough to send new information.
[ss,bs,is] = causalBroadcastTriggerPolicy( ...
    [0.03 0 0],v0,p0,v0,[0.02 0.30 0.04],[0 0 0],0.20,cfg);
checks(end+1,:)={ss && bs==3 && is.criticalReceiver==2 && ...
    is.staleReceiverCount==1, ...
    'worst confirmed receiver age drives adaptive new information'};

% Genuine new information bypasses outstanding-feedback suppression.
[sn,bn] = causalBroadcastTriggerPolicy( ...
    [0.06 0 0],v0,p0,v0,[0.20 0.30],[1 1],0.02,cfg);
checks(end+1,:)={sn && bn==1, ...
    'hard new information is not blocked by unconfirmed receivers'};

% Pure refresh is blocked while the latest broadcast is unconfirmed.
[sr,br,ir] = causalBroadcastTriggerPolicy( ...
    p0,v0,p0,v0,[0.20 0.30],[0 1],0.20,cfg);
checks(end+1,:)={~sr && br==0 && ir.refreshInFlightBlocked, ...
    'pure refresh is suppressed while useful broadcast information is pending'};

% Max silence remains the recovery backstop.
[sm,bm] = causalBroadcastTriggerPolicy( ...
    p0,v0,p0,v0,[0.60 0.70],[1 1],0.50,cfg);
checks(end+1,:)={sm && bm==5, ...
    'max silence recovers from prolonged missing confirmation'};

% No out-neighbour means no communication action.
[sz,bz,iz] = causalBroadcastTriggerPolicy( ...
    p0,v0,p0,v0,[],[],1.0,cfg);
checks(end+1,:)={~sz && bz==0 && iz.receiverCount==0, ...
    'a sender with no out-neighbour never generates a frame'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_causal_broadcast_policy: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_causal_broadcast_policy: PASS (%d checks)\n',numel(flags));

