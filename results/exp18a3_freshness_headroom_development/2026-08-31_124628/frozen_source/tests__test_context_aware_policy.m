%% TEST_CONTEXT_AWARE_POLICY Deterministic EXP18 method contracts.

startup;

fprintf('\n============================================================\n');
fprintf('test_context_aware_policy\n');
fprintf('============================================================\n\n');

checks=cell(0,2);


%% Inert default and frame-aware access geometry

base=study2Exp14Config(16024999,'moderate');
inert=contextAwarePolicyConfig(base);
checks(end+1,:)={~inert.enabled, ...
    'context-aware extension is inert for every legacy configuration'};

csma=enableContext(base,'csma',0.90);
[pCsma,iCsma]=contextAwareAccessProbability(csma);
aloha=enableContext(base,'aloha',0.90);
[pAloha,iAloha]=contextAwareAccessProbability(aloha);
checks(end+1,:)={abs(pCsma-1/5)<1e-12 && iCsma.dataSlots==4 && ...
    abs(pAloha-1/35)<1e-12 && iAloha.denominator==35, ...
    'N5 access uses 1/N CSMA and the seven-slot ALOHA vulnerable period'};

n10=applyTopologyConfig(aloha,10,'ring2');
n10.mac.interferenceMatrix=true(10);
n10.mac.carrierSenseMatrix=true(10);
n10.shared.contextAware.ackSuccessEstimate=0.90;
n10.shared.contextAware.dataSuccessEstimate=0.90;
pN10=contextAwareAccessProbability(n10);
checks(end+1,:)={abs(pN10-1/70)<1e-12, ...
    'frame-aware ALOHA scaling includes both N and DATA-frame length'};

certN5=contextAwareServiceCertificate(aloha);
certN10=contextAwareServiceCertificate(n10);
loaded=aloha; loaded.mac.backgroundLoad=0.30;
certLoaded=contextAwareServiceCertificate(loaded);
n10Csma=applyTopologyConfig(csma,10,'ring2');
n10Csma.mac.interferenceMatrix=true(10);
n10Csma.mac.carrierSenseMatrix=true(10);
n10Csma.shared.contextAware.ackSuccessEstimate=0.90;
n10Csma.shared.contextAware.dataSuccessEstimate=0.90;
certN10Csma=contextAwareServiceCertificate(n10Csma);
checks(end+1,:)={certN5.feasible && ~certN10.feasible && ...
    ~certLoaded.feasible && certN10Csma.feasible && ...
    certN5.requiredUpdateRateHz==1/aloha.aoiEvent.aoiThreshold, ...
    'capacity screen separates feasible N5/CSMA from N10 or loaded ALOHA'};


%% Causal feasibility/value decision

A=logical(base.swarm.A);
net=initSharedMediumState(aloha,A);
entry=localAck(2,1,1,0);
net=enqueueAckSummary(net,2,entry,0,aloha);
net.Vij(2,1,:)=[0 0 0];
[allow,~,positive]=contextAwareStandaloneAckDecision(net,2,0.02,aloha);
checks(end+1,:)={allow && positive.feasible && positive.valuePositive && ...
    positive.estimatedBenefit>positive.estimatedCost && ...
    positive.semanticDriftMax<aloha.aoiEvent.posThreshold, ...
    'fresh low-drift ACK passes both service and marginal-value gates'};

congested=net;
congested.localBusyEWMA(2)=0.99;
[allowCongested,~,busyInfo]=contextAwareStandaloneAckDecision( ...
    congested,2,0.02,aloha);
checks(end+1,:)={~allowCongested && ~busyInfo.feasible && ...
    strcmp(busyInfo.reason,'service-infeasible'), ...
    'nonpositive residual service slack blocks standalone ACK'};

drifted=net;
drifted.Vij(2,1,:)=[3 0 0];
[allowDrift,~,driftInfo]=contextAwareStandaloneAckDecision( ...
    drifted,2,0.02,aloha);
checks(end+1,:)={~allowDrift && driftInfo.feasible && ...
    ~driftInfo.valuePositive && driftInfo.redundancyScoreMean==0, ...
    'semantic drift removes credit for suppressing a potentially useful DATA'};

noReverse=aloha;
noReverse.shared.contextAware.ackSuccessEstimate=0;
[allowReverse,~,reverseInfo]=contextAwareStandaloneAckDecision( ...
    net,2,0.02,noReverse);
checks(end+1,:)={~allowReverse && reverseInfo.estimatedBenefit==0 && ...
    reverseInfo.valueMargin<0, ...
    'zero calibrated reverse success cannot produce positive ACK value'};


%% Legacy behavior and end-to-end method boundary

legacy=base;
legacy.swarm.T=0.4;
legacy.shared.evalStart=0;
legacy.sixdof.enable=false;
legacy.shared.feedbackMode='adaptive';
legacy.shared.macAware=macAwarePolicyConfig(legacy);
legacy.shared.macAware.loadGuardEnabled=false;
trace=generateSharedMediumTrace(legacy);
outA=simSwarmSharedMedium(legacy,'mac-aware-broadcast',trace);
explicit=legacy;
explicit.shared.contextAware.enabled=false;
outB=simSwarmSharedMedium(explicit,'mac-aware-broadcast',trace);
legacySame=isequaln(outA.P,outB.P) && ...
    isequaln(outA.trueAoI,outB.trueAoI) && ...
    isequaln(outA.netStats,outB.netStats) && ...
    outA.traceHashExact==outB.traceHashExact;
checks(end+1,:)={legacySame, ...
    'explicitly disabled context policy leaves legacy trajectories exact'};

trial=enableContext(legacy,'aloha',0.90);
trial.swarm.T=0.8;
trial.shared.evalStart=0;
trialTrace=generateSharedMediumTrace(trial);
out=simSwarmSharedMedium(trial,'context-aware-broadcast',trialTrace);
checks(end+1,:)={abs(out.pAccess-1/35)<1e-12 && ...
    out.invariantViolations==0 && all(isfinite(out.P(:))) && ...
    out.netStats.contextAckEvaluated== ...
    out.netStats.contextAckPermitted+ ...
    out.netStats.contextAckBlockedFeasibility+ ...
    out.netStats.contextAckBlockedValue, ...
    'context-aware method runs causally and closes its decision accounting'};

rejectDisabled=false;
try
    bad=legacy;
    bad.shared.contextAware.enabled=false;
    simSwarmSharedMedium(bad,'context-aware-broadcast',trace);
catch
    rejectDisabled=true;
end
checks(end+1,:)={rejectDisabled, ...
    'public context-aware method rejects a disabled policy contract'};


%% Verdict

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_context_aware_policy: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_context_aware_policy: PASS (%d checks)\n',numel(flags));


function cfg=enableContext(cfg,macType,ackSuccess)

cfg.mac.type=macType;
cfg.shared.feedbackMode='adaptive';
cfg.shared.macAware=macAwarePolicyConfig(cfg);
cfg.shared.macAware.loadGuardEnabled=false;
cfg.shared.contextAware=struct('enabled',true, ...
    'accessRule','frame-aware', ...
    'ackSuccessEstimate',ackSuccess, ...
    'calibrationSource','test-profile');
cfg.shared.contextAware=contextAwarePolicyConfig(cfg);

end


function a=localAck(source,target,seq,genTime)

a=struct('sourceReceiver',source,'targetSender',target, ...
    'seq',seq,'genTime',genTime);

end
